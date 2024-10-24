class_name WorldProjection extends Node

const tile_set: TileSet = preload("res://Assets/Sprites/Tilesets/OldPrison.tres")

var world: World
var host: Node2D
var projections = []
# Called when the node enters the scene tree for the first time.
func _init(world: World, host: Node2D) -> void:
	self.world = world
	self.host = host
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func project() -> void:
	print("Project current world ...")
	
	for layer in world.layers:
		var layer_node_name = "layer_" + layer.name
		var layer_node = null
		for child in host.get_children():
			if child.name == layer_node_name:
				layer_node = child
			
		if layer_node == null:
			printerr("Unable to find node `%s` in representation host" % layer_node_name)
		else:
			project_layer(layer, layer_node as TileMapLayer)
	
	pass

func project_layer(grid: World.Grid, node: TileMapLayer):
	var source_id = node.tile_set.get_source_id(0)
	var projection: ProjectionLayer
	if grid.name == "GROUND":
		projection = TerrainProjectionLayer.new(world, grid, node)
	elif grid.name == "WALLS":
		projection = WallProjectionLayer.new(world, grid, node)
	elif grid.name == "ENTITIES":
		projection = EntitiesProjectionLayer.new(world, grid, node)
	else:
		printerr("Unknown projection kind for layer `%s`" % grid.name)
		return

	projection.project()
	

func cleanup() -> void:
	pass

class ProjectionLayer:
	var erase: bool
	var grid: World.Grid
	var layer: TileMapLayer
	var tile_set: ProjectionTileset
	var world: World
	
	func _init(world, grid, layer, erase = true) -> void:
		self.world = world
		self.grid = grid
		self.layer = layer
		self.erase = erase
		self.tile_set = ProjectionTileset.new(layer.tile_set)

	func project_atlas_pattern(position: Vector2i, atlas_coords: Array[Vector2i]):
		var x_min = INF
		var y_min = INF
		for cell in atlas_coords:
			x_min = min(x_min, cell.x)
			y_min = min(y_min, cell.y)
		for cell in atlas_coords:
			var offset = cell - Vector2i(x_min, y_min)
			self.layer.set_cell(position + offset, tile_set.default_source_id, cell)
		pass

class ProjectionTileset:
	var tile_set: TileSet
	var default_terrain_set_id: int
	var default_source_id: int

	func _init(tile_set: TileSet):
		self.tile_set = tile_set
		self.default_source_id = tile_set.get_source_id(0)
	
	func terrain_indexes(terrain: WorldRenderer.Terrain) -> Vector2i:
		match terrain:
			WorldRenderer.Terrain.GROUND_1:
				return Vector2i(0, 0)
			WorldRenderer.Terrain.GROUND_1_LAVA:
				return Vector2i(0, 1)
			WorldRenderer.Terrain.GROUND_1_SPIKES:
				return Vector2i(0, 2)
		return Vector2i(-1, -1)

class WallProjectionLayer extends ProjectionLayer:
	
	class WallCell:
		var kind: WorldRenderer.Wall
		var sub_index = 0
		
		func _init(kind: WorldRenderer.Wall, sub_index):
			self.kind = kind
			self.sub_index = sub_index
	
	class HorizontalWallCell extends WallCell:
		pass
	
	class VerticalWallCell extends WallCell:
		var side: int = 0
		
		func _init(kind: WorldRenderer.Wall, side, sub_index):
			self.kind = kind
			self.side = side
			self.sub_index = sub_index
		
	func project():
		if erase:
			self.layer.clear()

		var horizontal_wall_cells: Dictionary = {}
		var vertical_wall_cells: Dictionary = {}
		
		# Note: Exploration order (x -> y) is important, tile selection depend on it
		for y in grid.size.y:
			for x in grid.size.x:
				if x > 0 && x < grid.size.x - 1 && y > 0 && y < grid.size.y - 1:
					var cell_coords = Vector2i(x, y)
					
					var cell_index = grid.coord_index(cell_coords)
					var cell_value: WorldRenderer.Wall = grid.cells[cell_index]
					
					if cell_value != WorldRenderer.Wall.NONE:
						var left_value = grid.cells[grid.coord_index(cell_coords + Vector2i(-1, 0))]
						var right_value = grid.cells[grid.coord_index(cell_coords + Vector2i(1, 0))]
						var top_value = grid.cells[grid.coord_index(cell_coords + Vector2i(0, -1))]
						var bottom_value = grid.cells[grid.coord_index(cell_coords + Vector2i(0, 1))]
						
						if cell_value == left_value || cell_value == right_value:
							horizontal_wall_cells[cell_coords] = HorizontalWallCell.new(cell_value, 0)
							horizontal_wall_cells[cell_coords + Vector2i(0, -1)] = HorizontalWallCell.new(cell_value, 1)
							horizontal_wall_cells[cell_coords + Vector2i(0, -2)] = HorizontalWallCell.new(cell_value, 2)
		
						if cell_value == top_value || cell_value == bottom_value:
							if top_value != cell_value:
								vertical_wall_cells[cell_coords] = VerticalWallCell.new(cell_value, -1, 2)
								vertical_wall_cells[cell_coords + Vector2i(0, -1)] = VerticalWallCell.new(cell_value, -1, 1)
								vertical_wall_cells[cell_coords + Vector2i(0, -2)] = VerticalWallCell.new(cell_value, -1, 0)
							elif bottom_value != cell_value:
								vertical_wall_cells[cell_coords + Vector2i(0, -2)] = VerticalWallCell.new(cell_value, 1, 0)
								vertical_wall_cells[cell_coords + Vector2i(0, -1)] = VerticalWallCell.new(cell_value, 1, 1)
								vertical_wall_cells[cell_coords] = VerticalWallCell.new(cell_value, 1, 2)
							else:
								vertical_wall_cells[cell_coords] = VerticalWallCell.new(cell_value, 0, 0)
		
		for pos in horizontal_wall_cells.keys():
			var cell = horizontal_wall_cells[pos]
			layer.set_cell(pos, tile_set.default_source_id, Vector2i(24, 19 - cell.sub_index))

		for pos in vertical_wall_cells.keys():
			var cell = vertical_wall_cells[pos]
			
			if cell.side == 0:
				layer.set_cell(pos, tile_set.default_source_id, Vector2i(31, 17))
			elif cell.side == -1:
				layer.set_cell(pos, tile_set.default_source_id, Vector2i(31, 14 + cell.sub_index))
			elif cell.side == 1:
				layer.set_cell(pos, tile_set.default_source_id, Vector2i(31, 19 + cell.sub_index))

		print("Found %d horizontal walls" % horizontal_wall_cells.size())

		print("Projecting walls layer `%s`" % self.grid.name)

class TerrainProjectionLayer extends ProjectionLayer:
	
	func project():
		var new_cells = {}

		print("Projecting terrain layer `%s`" % self.grid.name)
		
		if self.erase:
			self.layer.clear()
		
		for x in grid.size.x:
			for y in grid.size.y:
				var cell_coords = Vector2i(x, y)
				var cell_idx = grid.coord_index(Vector2i(x, y))
				var cell_value = grid.cells[cell_idx] as WorldRenderer.Terrain
				
				if cell_value == WorldRenderer.Terrain.EMPTY:
					continue
				new_cells.get_or_add(cell_value, []).push_back(cell_coords)
		
		for key in new_cells:
			var cells = new_cells[key]
			var terrain_coords = self.tile_set.terrain_indexes(key as WorldRenderer.Terrain)
			if terrain_coords.x == -1:
				print("Unable to find terrain %d (%d cells skipped)" % [key, cells.size()])
				continue
			print("Projecting %d terrain cells: terrain = %d" % [cells.size(), key])
			layer.set_cells_terrain_connect(cells, terrain_coords.x, terrain_coords.y, false)



class EntitiesProjectionLayer extends ProjectionLayer:
	
	func project():
		print("Projecting terrain layer `%s`" % self.grid.name)
		self.layer.clear()
		self.world.projecting_entities_layer.emit(self)
