class_name GStar extends Node

var cells: Array[Cell]
var world: World

var connection: World.NodeConnection
var start_idx: int
var end_idx: int

var open_list = []
var closed_list = []
var iter_remain = 0

func _init(world: World) -> void:
	self.world = world

	for i in world.sections.size():
		cells.push_back(Cell.new(world, i))


	#for spot: World.WorldNode in world.spots.values():
		#for connection in spot.connections.values():
			#for cell_idx in connection.path:
				#self.cells[cell_idx].path_mask += 1 # TODO: real mask
		
	for cell in self.cells:
		if cell.section.node != null:
			cell.path_mask += 1
	pass # Replace with function body.

func set_heuristic(to_solve: World.NodeConnection):
	connection = to_solve
	
	start_idx = to_solve.from.section.index
	end_idx = to_solve.node.section.index

	if start_idx < 0 || end_idx < 0 || start_idx >= self.cells.size()  || end_idx >= self.cells.size():
		printerr("[GSTAR] Invalide start/end position: start=%d end=%d" % [start_idx, end_idx])
		return false
	self.start_idx = start_idx
	self.end_idx = end_idx
	#print("[GSTAR] Update heuristic from cell %d to cell %d" % [start_idx, end_idx])
	var start_cell: Cell = cells[start_idx]
	var end_cell: Cell = cells[end_idx]
	var target_point = end_cell.section.rect.get_center()
	for idx in cells.size():
		var cell: Cell = cells[idx]
		cell.heuristic = cell.section.rect.get_center().distance_to(target_point)
		cell.f_score = INF
		cell.g_score = 0.0
		cell.parent = -1
	
	for cell in self.cells:
		cell.additional_weight = 0.0
		for neighbor in cell.neighbors:
			cell.additional_weight += cells[neighbor].heuristic / 2.0 if cells[neighbor].path_mask != 0 else 0

	
	open_list = [start_idx]
	closed_list = []
	cells[start_idx].g_score = 0.0
	cells[start_idx].f_score = cells[start_idx].heuristic
	iter_remain = 10240
	return true

func solve_step():
	if open_list.size() == 0 || iter_remain <= 0:
		return false
	iter_remain -= 1
	open_list.sort_custom(func(a, b):
		return cells[a].f_score < cells[b].f_score
	)
	var current = open_list[0]

	if current == end_idx:
		return false
		
	open_list.erase(current)
	closed_list.append(current)
	
	var move_cost = cells[current].g_score + 1
	#print("Explore %d (%d child)" % [ current, cells[current].neighbors.size()])
	for neighbor in cells[current].neighbors:
		
		var idx_in_open_list = open_list.find(neighbor)
		if cells[neighbor].path_mask != 0 && neighbor != end_idx && neighbor != start_idx && neighbor != end_idx:
			continue
		if closed_list.find(neighbor) != -1:
			continue

		if neighbor != cells[current].parent && idx_in_open_list == -1 || cells[neighbor].f_score < cells[current].f_score:
			cells[neighbor].g_score = move_cost + (cells[neighbor].additional_weight * world.params.gstar_avoidance)
			cells[neighbor].f_score = cells[neighbor].g_score + cells[neighbor].heuristic
			if idx_in_open_list == -1:
				cells[neighbor].parent = current
				open_list.push_back(neighbor)
			pass
	return true


func validate() -> bool:
	if cells[end_idx].parent != -1:
		var path: Array[World.Section] = [cells[end_idx].section]
		var current = end_idx
		var iter_remain = 50
		while current != start_idx && current != -1 && iter_remain > 0:
			path.push_front(cells[current].section)
			current = cells[current].parent
			iter_remain -= 1
		path.push_front(cells[start_idx].section)
		connection.path = path
		return true
	else:
		return false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
class Cell:
	var section: World.Section
	var neighbors: Array[int]
	var heuristic: float = INF
	var f_score: float = INF
	var g_score: float = 0
	var parent: int = -1
	var path_mask: int = 0
	
	var additional_weight = 0.0

	func _init(world: World, idx: int) -> void:
		var min_contact_len = world.params.section_min_contact
		section = world.sections[idx]
		for neighbor_idx in world.sections.size():
			if idx != neighbor_idx:
				var neighbor = world.sections[neighbor_idx]
				if neighbor.rect.end.y >= section.rect.position.y + min_contact_len && neighbor.rect.position.y + min_contact_len <= section.rect.end.y:
					if neighbor.rect.position.x == section.rect.end.x:
						neighbors.push_back(neighbor_idx)
					elif neighbor.rect.end.x == section.rect.position.x:
						neighbors.push_back(neighbor_idx)
				if neighbor.rect.end.x >= section.rect.position.x + min_contact_len && neighbor.rect.position.x + min_contact_len <= section.rect.end.x:
					if neighbor.rect.position.y == section.rect.end.y:
						neighbors.push_back(neighbor_idx)
					elif neighbor.rect.end.y == section.rect.position.y:
						neighbors.push_back(neighbor_idx)
		
