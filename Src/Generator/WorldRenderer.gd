class_name WorldRenderer extends Node

var world: World

var sections_used = {}
var sections_coridors = {}

enum Layer {
	# A layer made of a grid of `Terrain` enum
	GROUND = 0,
	# A layer made of a grid of `Wall` enum
	WALLS = 1,
	# A layer made of packed tileset coordinates
	ENTITIES = 2,
}

enum Wall {
	NONE																		= 0x0,
	REGULAR																		= 0x1 << 1,
}

enum Terrain {
	EMPTY																		= 0x0,
	GROUND_1 																	= 0x1 << 1,
	GROUND_1_LAVA 																= 0x1 << 2,
	GROUND_1_SPIKES 															= 0x1 << 3,
}

func _init(world: World) -> void:
	self.world = world

func render():
	create_layers()
	render_layer(Layer.GROUND)
	render_layer(Layer.WALLS)
	render_layer(Layer.ENTITIES)
	
	print("[Renderer] Begin renderer phase 2")
	render_layer(Layer.GROUND, 2)
	render_layer(Layer.ENTITIES, 2)
	
	

func render_layer(layer: Layer, phase = 1):
	world.before_rendering_layer.emit(self, layer, phase)
	match layer:
		Layer.GROUND:
			if phase == 1:
				render_ground_layer()
			elif phase == 2:
				arange_ground_layer()
			pass
		Layer.WALLS:
			if phase == 1:
				render_wall_layer()
			pass
	world.after_rendering_layer.emit(self, layer, phase)

func render_ground_layer():
	print("[Renderer] Rendering GROUND layer (pass 1)")
	var ground = world.layers[Layer.GROUND]
	
	for node: World.WorldNode in world.all_nodes.values():
		ground.fill_rect(node.section.rect, Terrain.GROUND_1)
		for connection in node.children:
			for section in connection.path:
				ground.fill_rect(section.rect, Terrain.GROUND_1)
				sections_used[section.index] = section

func arange_ground_layer():
	pass

func render_wall_layer():
	print("[Renderer] Rendering WALL layer (pass 1)")
	var walls = world.layers[Layer.WALLS]
	
	for section: World.Section in sections_used.values():
		walls.fill_rect(section.global_room, Wall.REGULAR, 1)
	
	for section: World.Section in sections_used.values():
		for coridor: World.Coridor in section.coridors:
			for segment: World.Coridor.CoridorSegment in coridor.path:
				# As segment are calculared with 1 cell of margin on each closed side apply the offset
				var r: Rect2i
				if segment.left_open || segment.right_open:
					r = Rect2i(segment.rect.position + Vector2i(0, 2), segment.rect.size + Vector2i(0, -4))
				else:
					r = Rect2i(segment.rect.position + Vector2i(2, 0), segment.rect.size + Vector2i(-4, 0))

				walls.fill_rect(r, Wall.REGULAR, 1)
				if segment.left_open:
					walls.fill_rect(Rect2i(r.position.x, r.position.y + 1, 1, r.size.y - 2), 0)
				if segment.right_open:
					walls.fill_rect(Rect2i(r.end.x - 1, r.position.y + 1, 1, r.size.y - 2), 0)
				if segment.top_open:
					walls.fill_rect(Rect2i(r.position.x + 1, r.position.y, r.size.x - 2, 1), 0)
				if segment.bottom_open:
					walls.fill_rect(Rect2i(r.position.x + 1, r.end.y - 1, r.size.x - 2, 1), 0)


func create_layers():
	world.layers = [
		World.Grid.new(world.size, "GROUND"),
		World.Grid.new(world.size, "WALLS"),
		World.Grid.new(world.size, "ENTITIES")
	]
