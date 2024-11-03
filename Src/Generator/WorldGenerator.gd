@tool
class_name WorldGenerator extends Node2D

enum Steps {
	NONE,
	INIT,
	SECTIONS,
	ROOMS,
	ROADS,
	CORIDORS,
	SUB_ROOMS,
	BLOCKERS,
	RENDERER,
	PROJECT,
	GENERATED,
	ABORTED,
}


var sub_step_interval = [
	0.0,
	0.0,
	0.0,
	0.0,
	0.01,
	0.01,
	0.01,
	0.01,
]

var world: World
var bsp: BSP;
var gstar: GStar
var renderer: WorldRenderer

var projection: WorldProjection

var state_processed = false
var state_since = 0.0
var state: Steps:
	set(value):
		#print("[WG] Step from %d to %d" % [ state, value] )
		state = value
		state_since = 0.0
		state_processed = false


@onready var font: Font = load("res://Assets/UI/GaramondPremrPro.otf")

@export var seed: int															= 42
@export var meta_seed: int														= 42
@export var grid_size: Vector2i													= Vector2i(1024, 1024)
@export var grid_sub_size: Vector2i												= Vector2i(4, 4)
@export var section_min_size: Vector2i 											= Vector2i(32, 32)
@export var section_max_size: Vector2i 											= Vector2i(96, 96)
@export var room_min_padding: int												= 2
@export var room_min_size: Vector2i												= Vector2i(16, 16)
@export var room_max_size: Vector2i												= Vector2i(64, 64)
@export var bsp_max_steps: int													= 20
@export var gstar_avoidance: float												= 1.0
@export var projection_host: Node2D

@export var draw_sub_grid: bool:
	set(value):
		draw_sub_grid = value
		queue_redraw()

@export var draw_section_grid: bool:
	set(value):
		draw_section_grid = value
		queue_redraw()
@export var draw_coridor: bool:
	set(value):
		draw_coridor = value
		queue_redraw()

@export var draw_section_spots: bool:
	set(value):
		draw_section_spots = value
		queue_redraw()


@export var generated: bool:
	set(value):
		generate()
		generated = !value

func generate():
	if state != Steps.NONE && state != Steps.ABORTED:
		printerr("[WG] Can't start generation: status isn't init")
		return
		
	var params: World.Params = World.Params.new()
	params.room_min_padding = self.room_min_padding
	params.room_max_size = self.room_max_size
	params.room_min_size = self.room_min_size
	params.section_max_size = self.section_max_size
	params.section_min_size = self.section_min_size
	params.gstar_avoidance = self.gstar_avoidance
	params.seed = self.seed
	params.sub_grid_size = self.grid_sub_size
	
	world = World.new(params)
	
	var boss_node = World.BossNode.new(self.world, "boss")
	var nparams = World.NodeGenerationParams.new(boss_node)
	
	world.root_node = World.SpawnNode.new(self.world)
	world.root_node.generate(nparams)

	world.root_node.resize_recursive()
	world.root_node.relocate_children_recursive()
	world.root_node.choose_biom_recursive()
	
	var explored_node = {}
	var to_be_explored = [world.root_node]
	
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	while to_be_explored.size() > 0:
		var explore: World.WorldNode = to_be_explored.pop_back()
		explored_node[explore.name] = true
		min_x = min(explore.spot_position.x - explore.section_min_size.x, min_x)
		min_y = min(explore.spot_position.y - explore.section_min_size.y, min_y)
		max_x = max(explore.spot_position.x + explore.section_min_size.x, max_x)
		max_y = max(explore.spot_position.y + explore.section_min_size.y, max_y)
		for child: World.NodeConnection in explore.children:
			if !explored_node.has(child.node.name):
				to_be_explored.push_back(child.node)
	var used_width = abs((max_x - min_x) + (5 * params.section_max_size.x))
	var used_height = abs((max_y - min_y) + (5 * params.section_max_size.y))
	world.root_node.offset_recursive(Vector2i(used_width / 2, used_height - ((2.5*params.section_max_size.y) + 1)))
	world.host = projection_host
	world.size = Vector2i(used_width, used_height)
	world.root_node.debug()
	world.all_nodes = world.root_node.flatten()
	state = Steps.INIT

var all_path_to_solve = []

func _process(delta: float) -> void:
	state_since += delta
	
	if state == Steps.NONE:
		if !state_processed:
			state_processed = true
			queue_redraw()
			if !Engine.is_editor_hint():
				generate()
	if state == Steps.INIT:
		gstar = null
		bsp = null
		state = Steps.SECTIONS
	elif state == Steps.SECTIONS:
		if !state_processed:
			print("[WG] Generating sections ...")
			bsp = BSP.new(world)
			state_processed = true
		if !bsp.step() || bsp.steps >= bsp_max_steps:
			state = Steps.ROOMS
	elif state == Steps.ROOMS:
		print("[WG] Generating rooms ...")
		for i in world.sections.size():
			world.sections[i].place_room()
		for node in world.all_nodes.values():
			for connection in node.children:
				all_path_to_solve.push_back(connection)
		state = Steps.ROADS
	elif state == Steps.ROADS:
		if !state_processed:
			print("[WG] Solving nodes connections ...")
			var to_solve = all_path_to_solve.pop_back()
			if to_solve == null:
				state = Steps.CORIDORS
			else:
				#print("[WG] Solving node connection: from=%s to=%s" % [to_solve.from.name, to_solve.node.name])
				gstar = GStar.new(world)
				gstar.set_heuristic(to_solve)
				state_processed = true
		if state_processed && !gstar.solve_step():
			if gstar.validate():
				state = Steps.ROADS
			else:
				printerr("[WG] Failed to solve node connection !")
				state = Steps.ABORTED
	elif state == Steps.CORIDORS:
		print("[WG] Solving coridors ...")
		world.solve_coridors()
		state = Steps.SUB_ROOMS
	elif state == Steps.SUB_ROOMS:
		print("[WG] Generating sub rooms ...")
		world.generate_sub_rooms()
		#state = Steps.BLOCKERS
		state = Steps.NONE
	elif state == Steps.BLOCKERS:
		if !state_processed:
			state_processed = true
			print("[WG] Solving blockers ...")
			world.generate_blockers()
			state = Steps.RENDERER
	elif state == Steps.RENDERER:
		print("[WG] Rendering ...")
		if !state_processed:
			state_processed = true
			renderer = WorldRenderer.new(world)
			renderer.render()
			state = Steps.PROJECT
			
	elif state == Steps.PROJECT:
		if !state_processed:
			state_processed = true
			
			if projection != null:
				projection.cleanup()
			
			if projection_host == null:
				printerr("[WG] Unable to project current world, no projection host set !")
			else:
				projection = WorldProjection.new(world, projection_host)
				projection.project()
				
			if Engine.is_editor_hint():
				state = Steps.NONE
			else:
				state = Steps.GENERATED
			world.generation_done(Engine.is_editor_hint())
	queue_redraw()

func abort(reason):
	printerr("[WG] Abort: %s", reason)
	state = Steps.ABORTED

func  _draw() -> void:
	if world == null:
		return
	
	var len = world.sections.size()	
	var scale = 32.0


	if draw_section_grid:
		for section in world.sections:
			var room = Rect2(scale * section.rect.position, scale * section.rect.size)
			#draw_string(font, Vector2(room.position.x, room.position.y), "%d x %d" % [section.rect.size.x, section.rect.size.y], HORIZONTAL_ALIGNMENT_LEFT , room.size.x,  scale)
			draw_rect(room, Color.BLACK, false)

	if gstar != null:
		for section: World.Section in world.all_used_sections.values():
			var room = Rect2(scale * (section.room.rect.position + section.rect.position), scale * section.room.rect.size)
			var color = Color.CORNFLOWER_BLUE
			if section.node != null:
				color = section.node.color
			draw_rect(room, color)
			if section.room != null:
				for sub_room in section.room.partitions:
					var offseted = Rect2((sub_room.rect.position + section.global_room.position) * scale, sub_room.rect.size * scale) 
					draw_rect(offseted, Color.RED, false)

	if draw_coridor:
		for coridor: World.Coridor in world.all_coridors:
			var color = Color.CHARTREUSE
			if coridor.blocker_place_holder.size() > 0:
				color = Color.DARK_RED
			for rect in coridor.path:
				var room = Rect2i(scale * rect.rect.position, scale * rect.rect.size)
				draw_rect(room, color)

	if gstar != null:
		for cell_idx in gstar.cells.size():
			var cell = gstar.cells[cell_idx]
			var section = cell.section
			draw_string(font, section.rect.get_center() * scale, "%d" % cell.path_mask, HORIZONTAL_ALIGNMENT_CENTER, -1, 128)
#
	#if draw_section_spots:
		#for section in world.all_used_sections.values():
			#var room = Rect2((scale * (section.rect.position + section.room.rect.position)), (scale * section.room.rect.size))
			#draw_rect(room, Color.CADET_BLUE if section.node == null else section.node.color)
			#if section.node != null:
				#draw_string(font, Vector2(room.position.x, room.get_center().y), section.node.name, HORIZONTAL_ALIGNMENT_CENTER , room.size.x,  scale)

	if draw_sub_grid:
		for x in grid_size.x / grid_sub_size.x:
			var x_offset = x * grid_sub_size.x * scale;
			draw_line(Vector2(x_offset, 0.0), Vector2(x_offset, grid_size.y * scale), Color.RED)
		for y in grid_size.y / grid_sub_size.y:
			var y_offset = y * grid_sub_size.y * scale;
			draw_line(Vector2(0.0, y_offset), Vector2(grid_size.x * scale, y_offset), Color.RED)
