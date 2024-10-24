class_name World

var params: Params
var rng: RandomNumberGenerator

# All section determinated by the BSP algorythme
# Some of thoses sections may never be used
var sections: Array[Section]													= []

# World boundaries
# > This value is determinated by the generated `WorldNode` tree
var size: Vector2i																= Vector2.ZERO

# The root node of the "meta" representation of the dungon
# Each node represent a "checkpoint" in the game and each node can got multiple connection with other nodes
var root_node: SpawnNode

# All nodes (flatten)
# Note > This value is set late in the initialization
var all_nodes: Dictionary = {}

# All the sections used (whitin a path or assignated to a node)
var all_used_sections: Dictionary = {}

# All the sections's coridors (flatten)
# Note > This value is set late in the initialization
var all_coridors: Array = []

# All the world entities
# Note > This value is set late in the initialization
var entities: Array[WorldEntity] = []

var layers: Array[Grid]															= []

signal before_rendering_layer(renderer: WorldRenderer, layer: WorldRenderer.Layer, phase: int)
signal after_rendering_layer(renderer: WorldRenderer, layer: WorldRenderer.Layer, phase: int)
signal projecting_entities_layer(layer: WorldProjection.EntitiesProjectionLayer)

func _init(init_params: Params) -> void:
	self.params = init_params
	self.rng = RandomNumberGenerator.new()
	rng.seed = self.params.seed

func solve_coridors():
	for node: WorldNode in all_nodes.values():
		all_used_sections[node.section.index] = node.section
		for connection in node.children:
			var section_prev = null
			for section_current in connection.path:
				all_used_sections[section_current.index] = section_current
				if section_prev != null:
					section_current.place_coridor(section_prev)
					all_coridors.append_array(section_current.coridors)
				section_prev = section_current

func generate_blockers():
	generate_doors_blocker_placeholder()
	
	instanciate_corridor_blockers()

func instanciate_corridor_blockers():
	for coridor: Coridor in all_coridors:
		for blocker in coridor.blocker_place_holder:
			if blocker == Coridor.CoridorBlockerPlaceHolder.DOOR_LEVER_ACTIVATION:
				var where = coridor.get_entrance_center_point(false, false, false, true)
				if where.size() == 0:
					printerr("Failed to place entrance, unable to locate corridor entrance !")
				
				var generated = WorldEntity.DoorBlocker.new(self, Vector2i(where[0], where[1]), where[2])

func generate_doors_blocker_placeholder():
	var max_cycles = 10
	var min_doors_count = rng.randi_range(self.all_nodes.size() / 2,  self.all_nodes.size())
	print("[World] Trying to generate %d door blocker" % min_doors_count)
	var doors_count = 0
	# Place doors
	
	var base_proba = 0.2
	
	while doors_count < min_doors_count && max_cycles > 0:
		max_cycles -= 1
		for corridor: Coridor in all_coridors:
			if corridor.is_horizontal():
				continue;
			if corridor.blocker_place_holder.find(Coridor.CoridorBlockerPlaceHolder.DOOR_LEVER_ACTIVATION) != -1:
				continue
			
			if rng.randf() < base_proba:
				corridor.blocker_place_holder.push_back(Coridor.CoridorBlockerPlaceHolder.DOOR_LEVER_ACTIVATION)
				doors_count += 1

class Params:
	var seed: int
	var sub_grid_size: Vector2i													= Vector2i(4, 4)
	var section_min_size: Vector2i
	var section_max_size: Vector2i
	var room_min_size: Vector2i
	var room_max_size: Vector2i
	var room_min_padding: int													= 2
	var section_min_contact: int												= 16
	var gstar_avoidance: float													= 1.0

class NodeGenerationParams:
	var termination_node: WorldNode
	var alt_path_probability: float = 0.1
	var alt_path_min: int = 1
	var alt_path_max_extra_node: int = 1
	var path_length: Vector2i = Vector2i(2, 3)
	
	func _init(termination_node: WorldNode):
		self.termination_node = termination_node
		
	func clone() -> NodeGenerationParams:
		var ret = NodeGenerationParams.new(termination_node)
		ret.termination_node = termination_node
		ret.alt_path_probability = alt_path_probability
		ret.alt_path_min = alt_path_min
		ret.alt_path_max_extra_node = alt_path_max_extra_node
		ret.path_length = path_length
		return ret


class NodeConnection:
	var from: WorldNode
	var node: WorldNode
	var path: Array[Section]


	func _init(from, node):
		self.from = from
		self.node = node
		self.path = []

class WorldNode:
	var world: World
	var name: StringName
	var children: Array[NodeConnection]
	var parents: Array[WorldNode]
	var owner: WorldNode
	var distance_to_target: int = 0
	var spot_position: Vector2i
	var room_min_size: Vector2i
	var section_min_size: Vector2i
	var section_max_size: Vector2i
	
	var biom: Biom
	
	var color: Color															= Color.DARK_BLUE
	var section: Section

	func _init(world: World, name: StringName, owner = null):
		self.world = world
		self.name = name
		self.room_min_size = world.params.room_min_size

	func generate(params: NodeGenerationParams):
		var nbr_checkpoint = world.rng.randi_range(params.path_length.x, params.path_length.y)
		self.generate_line_path(nbr_checkpoint, params.termination_node)
		
		var max_iter = 100
		var nbr_alt_paths = 0
		while nbr_alt_paths < params.alt_path_min && max_iter > 0:
			max_iter -= 1
			if self.generate_alt_path_recursive(params):
				nbr_alt_paths += 1 
			else:
				params.alt_path_probability *= 1.1;

	func generate_line_path(checkpoint_count: int, terminaison_node: WorldNode = null):
		var current_check_point_count = 0
		var current_node = self
		while current_check_point_count < checkpoint_count:
			var check_point_node = CheckPointNode.new(self.world, "%s_checkpoint_%d" % [self.name, current_check_point_count] )
			current_node.add_child(check_point_node)
			current_node = current_node.children[0].node
			check_point_node.distance_to_target = checkpoint_count - current_check_point_count
			current_check_point_count += 1
			
		if terminaison_node != null:
			current_node.add_child(terminaison_node)

	func generate_alt_path_recursive(params:  NodeGenerationParams, probability: float = -1, depth = 0) -> bool:
		probability = probability if probability != -1 else params.alt_path_probability
		
		if depth > 50:
			printerr("Max depth reached")
			return false
		
		for child in self.children:
			if is_instance_of(child.node, BossNode):
				probability = 0.0

		if world.rng.randf() < probability:
			var alt_path = AltNode.new(self.world, "%s_alt_%d" % [self.name, self.children.size()])
			var alt_path_params = params.clone()
			alt_path_params.path_length = Vector2i(0, max(0, self.distance_to_target - 1) + params.alt_path_max_extra_node)
			alt_path_params.termination_node = choose_alt_path_termination_node(alt_path_params.path_length)
			alt_path_params.alt_path_min = 0
			alt_path.generate(alt_path_params)
			self.add_child(alt_path)
			return true
		
		for child in self.children:
			if child.node.generate_alt_path_recursive(params, probability / float(self.children.size()), depth + 1):
				return true

		return false
	
	# Choose a node in the children (recursively) that has a length distance from self in the range of `path_len`
	# Used to determinate end of alternative path
	# This function can return null in some case
	# TODO: allow connecting with parent alt path recursively to make more intricate dungon
	func choose_alt_path_termination_node(path_len: Vector2i, current_len: int = 0) -> WorldNode:
		if path_len.y <= 0:
			return null

		var probability = 0.0 if current_len <= path_len.x else inverse_lerp(path_len.x, path_len.y, current_len + 1)
		#print(probability)
		if world.rng.randf() < probability:
			return self
		
		for child in self.children:
			var choice = child.node.choose_alt_path_termination_node(path_len, current_len  + 1)
			if choice != null:
				return choice
		return null

	func relocate_children_recursive(offset: Vector2i = Vector2i.ZERO):
		self.spot_position = offset
		print("Apply offset to main path's node: node=%s x=%d y=%d" % [ self.name, self.spot_position.x, self.spot_position.y ])
		
		if self.children.size() > 0:
			# > Note: index[0] is always the main road to boss
			for idx in self.children.size():
				if idx == 0:
					self.children[idx].node.relocate_children_recursive(self.spot_position + Vector2i(0, -(self.section_max_size.y + 128)))
				elif idx % 2 == 0:
					self.children[idx].node.relocate_aux_recursive(1, self.spot_position + Vector2i(world.params.section_max_size.x * 2, -(self.section_max_size.y + 128)))
				else:
					self.children[idx].node.relocate_aux_recursive(-1, self.spot_position + Vector2i(-(self.section_max_size.x * 2), -(self.section_max_size.y + 128)))

	func relocate_aux_recursive(side: int, offset: Vector2i = Vector2i.ZERO):
		self.spot_position = offset
		print("Apply offset to aux path's node: node=%s x=%d y=%d" % [ self.name, self.spot_position.x, self.spot_position.y ])
			
		
		if self.children.size() > 1:
			printerr("Multiple aux path are not implemented !")
		elif self.children.size() == 1:
			var lookup: WorldNode = self.children[0].node
			if lookup.owner == self:
				lookup.relocate_aux_recursive(side, self.spot_position + Vector2i(0, self.section_max_size.y + 128))
	
	func choose_biom_recursive(explored: Dictionary = {}):
		if explored.has(self.name):
			return
		explored[self.name] = true
		
		for child: NodeConnection in self.children:
			child.node.choose_biom_recursive(explored)
		
		if is_instance_of(self, SpawnNode):
			biom = Biom.PEACE
		elif is_instance_of(self, BossNode):
			biom = Biom.BOSS
		else:
			if self.children.size() > 0:
				if self.children.filter(func(x: NodeConnection): x.node.biom == Biom.BOSS).size() > 0:
					biom = Biom.BLOOD_LAKE
				else:
					biom = Biom.GRAVEYARD
	
	func offset_recursive(offset: Vector2i, explored: Dictionary = {}):
		if !explored.has(self.name):
			explored[self.name] = true
			self.spot_position += offset
		
		for child: NodeConnection in self.children:
			child.node.offset_recursive(offset, explored)

	func resize_recursive(explored: Dictionary = {}):
		var parent_count = max(1.0, 0.5 * (self.parents.size() + 1))
		room_min_size = room_min_size * parent_count
		section_min_size = room_min_size + Vector2i(world.params.room_min_padding, world.params.room_min_padding)
		section_max_size = section_min_size +  Vector2i(2*world.params.room_min_padding, 2*world.params.room_min_padding)
		section_max_size = section_max_size.max(world.params.section_max_size)
		
		for child: NodeConnection in self.children:
			if !explored.has(child.node.name):
				explored[child.node.name] = true
				child.node.resize_recursive(explored)

	func flatten(explored: Dictionary = {}) -> Dictionary:
		if !explored.has(self.name):
			explored[self.name] = self
		for child: NodeConnection in self.children:
			child.node.flatten(explored)
		return explored

	func add_child(node: WorldNode):
		self.children.push_back(NodeConnection.new(self, node))
		node.parents.push_back(self)
		
		if node.owner == null:
			node.owner = self

	func indent(n) -> String:
		var s = ""
		while n > 0:
			n -= 1
			s += ' '
		return s

	func debug(indent: int = 0):
		# Print the current node and its memory address as a unique identifier
		print(indent(indent)  + " (%s) x=%d y=%d CH=%d PA=%d" % [self.name, self.spot_position.x, self.spot_position.y, self.children.size(), self.parents.size()])
		# Print each connection to children
		for child in children:
			child.node.debug(indent + 2)  # Recursively debug children

class AltNode extends WorldNode:
	pass

class SpawnNode extends WorldNode:
	func _init(world: World):
		self.world = world
		self.name = "spawn"
		self.room_min_size = Vector2(32, 32)
	pass

class BossNode extends WorldNode:
	pass

class CheckPointNode extends WorldNode:
	pass

enum Biom {
	PEACE,
	GRAVEYARD,
	BLOOD_LAKE,
	TRAP,
	BOSS,
}

class Section:
	var rect: Rect2i
	var room: Rect2i
	var global_room: Rect2i
	var node: WorldNode
	var world: World
	var coridors: Array[Coridor] = []
	var index: int = -1
	
	func _init(rect: Rect2i, world: World) -> void:
		rect.get_area()
		self.rect = rect
		self.world = world
		self.assign_node()
		
	func match_end_criterias() -> bool:
		return self.rect.size < self.world.params.section_max_size

	func place_coridor(from: Section):
		var min_coridor_width = 10
		
		var from_x;
		var to_x;
		var to_y;
		var from_y;
		
		var found_connection = false
		var align = 0
		
		if global_room.position.x > from.global_room.end.x:
			to_x = global_room.position.x + 1
			from_x = from.global_room.end.x - 1
			align = 1
		elif from.global_room.position.x > global_room.end.x:
			from_x = global_room.end.x - 1
			to_x = from.global_room.position.x + 1
			align = 1
			
		if align == 1 && from.global_room.end.y - min_coridor_width >= global_room.position.y && from.global_room.end.y <= global_room.end.y:
			# Dig coridor from bottom left corner of other section
			from_y = from.global_room.end.y - min_coridor_width
			to_y = from.global_room.end.y
			found_connection = true
		elif align == 1 && global_room.end.y - min_coridor_width >= from.global_room.position.y && global_room.end.y <= from.global_room.end.y:
			# Dig coridor from bottom left corner of current section
			from_y = global_room.end.y - min_coridor_width
			to_y = global_room.end.y
			found_connection = true

		if found_connection == true:
			var segment = Coridor.CoridorSegment.new(Rect2i(from_x, from_y, to_x - from_x, to_y - from_y))
			segment.left_open = true
			segment.right_open = true
			self.coridors.push_back(Coridor.new(from, self, [segment]))
			return

		if global_room.position.y > from.global_room.end.y:
			to_y = global_room.position.y + 1
			from_y = from.global_room.end.y - 1
			align = 2
		elif from.global_room.position.y > global_room.end.y:
			from_y = global_room.end.y - 1
			to_y = from.global_room.position.y + 1
			align = 2

		if align == 2 && from.global_room.end.x - min_coridor_width >= global_room.position.x && from.global_room.end.x <= global_room.end.x:
			# Dig coridor from bottom left corner of other section
			from_x = from.global_room.end.x - min_coridor_width
			to_x = from.global_room.end.x
			found_connection = true
		elif align == 2 && global_room.end.x - min_coridor_width >= from.global_room.position.x && global_room.end.x <= from.global_room.end.x:
			# Dig coridor from bottom left corner of current section
			from_x = global_room.end.x - min_coridor_width
			to_x = global_room.end.x
			found_connection = true

		if found_connection == true:
			var segment = Coridor.CoridorSegment.new(Rect2i(from_x, from_y, to_x - from_x, to_y - from_y))
			segment.top_open = true
			segment.bottom_open = true
			self.coridors.push_back(Coridor.new(from, self, [segment]))
		

	func place_room():
		var min_padding = world.params.room_min_padding
		var max_padding = 2 * min_padding

		var max_size = self.rect.size
		var min_size = self.rect.size
		max_size -= Vector2i(2*min_padding, 2*min_padding)
		min_size -= Vector2i(6*min_padding, 6*min_padding)
		var size = Vector2i(world.rng.randi_range(min_size.x, max_size.x), world.rng.randi_range(min_size.y, max_size.y))
	
		var max_offset = Vector2i(self.rect.size.x - (size.x + min_padding), self.rect.size.y - (size.y + min_padding))
		var offset = Vector2i(world.rng.randi_range(min_padding, max_offset.x), world.rng.randi_range(min_padding, max_offset.y))
		
		self.room = Rect2i(offset, size)
		self.global_room = Rect2i(self.rect.position + offset, size)

	func assign_node():
		for check: World.WorldNode in world.all_nodes.values():
			if check.spot_position.x >= rect.position.x && check.spot_position.x < rect.end.x:
				if check.spot_position.y >= rect.position.y && check.spot_position.y < rect.end.y:
					self.node = check
					self.node.section = self

	func split_at(is_horizontal: bool, offset: int) -> Array[Section]:
		if self.node != null:
			self.node.section = null
		if is_horizontal:
			return [
				Section.new(Rect2i(self.rect.position, Vector2(offset, self.rect.size.y)), self.world),
				Section.new(Rect2i(self.rect.position.x + offset, self.rect.position.y, self.rect.size.x - offset, self.rect.size.y), self.world)
			]
		else:
			return [
				Section.new(Rect2i(self.rect.position, Vector2(self.rect.size.x, offset)), self.world),
				Section.new(Rect2i(self.rect.position.x, self.rect.position.y + offset, self.rect.size.x, self.rect.size.y - offset), self.world)
			]

	func room_min_size() -> Vector2i:
		if node != null:
			return node.room_min_size
		else:
			return world.params.room_min_size

	func section_min_size() -> Vector2i:
		if node != null:
			return node.section_min_size
		else:
			return world.params.section_min_size

class Room:
	var rect: Rect2i
	
	func _init(rect: Rect2i) -> void:
		self.rect = rect

class Coridor:	
	var blocker_place_holder: Array
	
	var from: Section
	var to: Section
	var path: Array[CoridorSegment]

	func _init(from_section, to_section, path: Array[CoridorSegment] = []):
		self.from = from_section
		self.to = to_section
		self.path = path
		pass
	
	func is_horizontal() -> bool:
		return path[0].left_open || path[0].right_open
	
	# Return an array containing x, y, is horizontal
	func get_entrance_center_point(allow_left = true, allow_right = true, allow_top = true, allow_bottom = true) -> Array:
		var r = self.path[0]
		if r.right_open && allow_right:
			return [r.rect.position.x, r.rect.get_center().y, true]
		elif r.left_open && allow_left:
			return [r.rect.end.x, r.rect.get_center().y, true]
		elif r.bottom_open && allow_bottom:
			return [r.rect.get_center().x, r.rect.end.y, true]
		elif r.top_open && allow_top:
			return [r.rect.get_center().x, r.rect.position.y, true]
		else:
			return []

	enum CoridorBlockerPlaceHolder {
		DOOR_LEVER_ACTIVATION,
		TRAP_1,
		SURPRISE_ATTACK,
	}

	class CoridorSegment:
		var rect: Rect2i
		var left_open: bool = false
		var right_open: bool = false
		var bottom_open: bool = false
		var top_open: bool = false
		
		func _init(rect):
			self.rect = rect
	
class Grid:
	var name: StringName
	var size: Vector2i
	var cells: PackedInt64Array

	func _init(size, name) -> void:
		self.name = name
		self.size = size
		self.cells = PackedInt64Array()
		self.cells.resize(self.size.x * self.size.y)
		self.cells.fill(0)


	# Return index of a cell in `self.cells` based on his position
	# > Warning: this functions does not check for coords validity (in grid bound, not negative)
	func coord_index(coord: Vector2i) -> int:
		return coord.x + (coord.y * self.size.x)

	# Return value of the cell at `coord`, -1 if the coordonates are out of grid bounds
	func cell(coord: Vector2i) -> int:
		if coord.x < 0 || coord.y < 0 || coord.x > self.size.x || coord.y > self.size.y:
			printerr("[Grid]Coords out of grid bounds: x=%d y=%d" % [ coord.x, coord.y ])
			return -1

		var index = self.coord_index(coord)
		if index == -1:
			return -1
		else:
			return self.cells[self.coord_index(coord)]
		
	# Fill a rect of cells with the given value
	# * `width` if equal to -1 the rect is filled, otherwise the rect is outline with a width of `width`
	func fill_rect(rect: Rect2i, value: int, width = -1) -> bool:
		rect.position.x = max(0, rect.position.x)
		rect.position.y = max(0, rect.position.y)
		rect.size.x = min(self.size.x - rect.position.x, rect.size.x)
		rect.size.y = min(self.size.y - rect.position.y, rect.size.y)
		
		#print("[Grid]Fill rect: value=%d x=%d y=%d x2=%d y2=%d" % [ value, rect.position.x, rect.position.y, rect.end.x, rect.end.y ])
		
		if width == -1:
			for x in rect.size.x:
				for y in rect.size.y:
					# TODO: optimize when stabilized
					self.cells[coord_index(Vector2i(x + rect.position.x, y + rect.position.y))] = value
		else:

			for x in rect.size.x:
				for y in rect.size.y:
					if x < width || y < width || x >= rect.size.x - width || y >= rect.size.y - width:
						self.cells[coord_index(Vector2i(x + rect.position.x, y + rect.position.y))] = value
		return true
