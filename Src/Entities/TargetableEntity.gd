class_name TargetableEntity extends Node2D

const CELL_HEIGHT = 16
const CELL_WIDTH = CELL_HEIGHT

var entity_radius: float = 8

var gliph = Gliph.new(GliphShape.Circle)

# A dictionary that represent how "hot" are the given cells
# Temperature is derivated from the number of other entities that target the given cell
# The more entity target a cell the more "hot" the cell is
var heat_map: Dictionary = {
}

enum GliphShape {
	Custom,
	Cross,
	Circle,
}

class Gliph:
	var shape: GliphShape
	
	var radius: float = 8
	
	# Circle specific
	var circle_hole = true
	var circle_hole_radius: float = 1


	# Once compute is called this dictionary contains all the cells of the shape
	var cells: Dictionary
	
	# Once compute is called this rect represent the smallest rect in whith the shape can fit
	# Usefull to determinate wheter or not the shape is pair
	var rect: Rect2i

	func _init(shape: GliphShape) -> void:
		self.shape = shape
		
	func compute(custom_cells = {}):
		match shape:
			GliphShape.Cross:
				cells = {}
				var pos = Vector2i(0, 0)
				for x in radius:
					cells[pos] = {}
					pos.x += 1;
				pos = Vector2i(0, 0)
				for x2 in radius:
					cells[pos] = {}
					pos.x -= 1;
				pos = Vector2i(0, 0)
				for y in radius:
					cells[pos] = {}
					pos.y += 1;
				pos = Vector2i(0, 0)
				for y2 in radius:
					cells[pos] = {}
					pos.y -= 1;
					
			GliphShape.Circle:
				cells = {}
				var center = Vector2.ZERO
				var min_x = int(floor(center.x - radius))
				var max_x = int(ceil(center.x + radius))
				var min_y = int(floor(center.y - radius))
				var max_y = int(ceil(center.y + radius))
				
				# Loop through the cells within the bounding box
				for x in range(min_x, max_x + 1):
					for y in range(min_y, max_y + 1):
						var cell_pos = Vector2(x, y)
						var distance = center.distance_to(cell_pos)
						if distance <= radius:
							if !circle_hole || (distance > circle_hole_radius):
								cells[Vector2i(x, y)] = {}
			GliphShape.Custom:
				cells = custom_cells
		
		var max = Vector2i.ZERO
		var min = Vector2i(4096, 4096)
		
		for cell in cells.keys():
			cells[cell].temperature = 0
			cells[cell].distance = Vector2i.ZERO.distance_to(cell)
			if cell.x < min.x:
				min.x = cell.x
			if cell.y < min.y:
				min.y = cell.y
			if cell.x > max.x:
				max.x = cell.x
			if cell.y > max.y:
				max.y = cell.y
		rect = Rect2(min, (max - min) + Vector2i(1, 1))
		pass
		
	func release_cell(pos):
		cells[pos].temperature -= 1
		

	func warn_cell(target_gliph, from_relative_pos, amount, previous_cell, temperature_tolerance = 2, distance_tolerance = 2):
				# Create a gliph to overlap on the current one as a mask
		var cells_in_mask = cells_in_mask(target_gliph)
		
		var min_temperature = 9999999.0

		var previous_cell_found = null
		for cell in cells_in_mask:
			cell.distance_to_warmer = from_relative_pos.distance_to(cell.position)
			if cell.temperature < min_temperature:
				min_temperature = cell.temperature
			if previous_cell != null && cell.position == previous_cell.position:
				previous_cell_found = cell
		
		var min_distance = 9999999.0
		var possible_cells = []
		for cell in cells_in_mask:
			if cell.temperature <= min_temperature:
				if cell.distance_to_warmer < min_distance:
					min_distance = cell.distance_to_warmer
				possible_cells.append(cell)

		possible_cells.sort_custom(func(x, y): return x.distance_to_warmer < y.distance_to_warmer)
		
		if previous_cell_found && previous_cell_found.temperature - min_temperature < temperature_tolerance && previous_cell_found.distance_to_warmer - min_distance <= distance_tolerance:
			cells[previous_cell_found.position].temperature += amount
			return previous_cell;
		
		var cell = possible_cells.pop_back()
		
		if cell:
			cell.temperature += amount
		
		return cell 

	func cells_in_mask(target_gliph):
		var possible_cells = []
		# Iterate over masked cells
		for pos in target_gliph.cells.keys():
			var cell = cells[pos]
			if cell == null:
				continue
			cell.position = pos
			possible_cells.push_back(cell)
		
		return possible_cells

# Return the best spot near by self based on parametters
func get_near_spot():
	var world = get_world_2d().direct_space_state
	#world.intersect_ray()
	
	var possible_dirs: Array
	var possible_spots: Array = []
	for dir in possible_dirs:
		var ray_to = (10 * dir)
		print(ray_to)
		var query = PhysicsRayQueryParameters2D.create(global_position, ray_to + global_position)
		query.collision_mask = 0x00000001
		var hits = world.intersect_ray(query)
		
		if hits.is_empty():
			possible_spots.append(ray_to + global_position)
		
	return possible_spots

func _ready() -> void:
	gliph.radius = 10
	gliph.compute()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var snaped_global_position = Vector2.ZERO

func _process(delta: float) -> void:
	for cell in gliph.cells.values():
		if cell.temperature > 0.0:
			cell.temperature = max(0.0, cell.temperature - delta)
	queue_redraw()
	pass

static func cell_to_world(cell_position: Vector2i, centered = true) -> Vector2:
	var pos = Vector2(float(cell_position.x * CELL_WIDTH), float(cell_position.y * CELL_HEIGHT))
	if centered:
		pos.x += float(CELL_HEIGHT) / 2.0
		pos.y += float(CELL_WIDTH) / 2.0
	return pos

static func world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(int(position.x / CELL_WIDTH), int(position.y / CELL_HEIGHT))

static func scale_direction_quad(direction: Vector2) -> Vector2:
	return Vector2(1 if direction.x >= 0.0 else -1, 1 if direction.y > 0.0 else -1)

#func _draw() -> void:
	#var rest_x = ((global_position.x / CELL_WIDTH) - int(global_position.x / CELL_WIDTH)) * CELL_WIDTH
	#var rest_y = ((global_position.y / CELL_HEIGHT) - int(global_position.y / CELL_HEIGHT)) * CELL_HEIGHT
	#var offset = Vector2(-rest_x, -rest_y)
	#
	#for cell in gliph.cells:
		#var color = Color.BLUE.lerp(Color.RED, min(1.0, gliph.cells[cell].temperature))
		#draw_rect(Rect2(offset.x + (cell.x * CELL_WIDTH), offset.y + (cell.y * CELL_HEIGHT), CELL_WIDTH, CELL_HEIGHT), color, false, 2.0)
