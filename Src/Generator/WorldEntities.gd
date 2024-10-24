class_name WorldEntity

var position: Vector2i

class DoorBlocker extends WorldEntity:
	
	
	var is_horizontal: bool
	var activator: LeverActivator
	var coridor: World.Coridor
	var world: World
	
	func _init(world: World, position: Vector2i, is_horizontal: bool) -> void:
		print("[WorldEntity] Instanciate DoorBlocker: x=%d y=%d" % [position.x, position.y])
		self.position = position
		self.is_horizontal = is_horizontal
		self.world = world
		self.world.entities.push_back(self)
		self.world.projecting_entities_layer.connect(_projecting_entities_layer)
		
	func _projecting_entities_layer(project: WorldProjection.EntitiesProjectionLayer):
		var tiles: Array[Vector2i] = [
			Vector2i(42, 23),
			Vector2i(43, 23),
			Vector2i(44, 23),
			Vector2i(45, 23),
			Vector2i(42, 24),
			Vector2i(43, 24),
			Vector2i(44, 24),
			Vector2i(45, 24),
			Vector2i(42, 25),
			#Vector2i(43, 25),
			#Vector2i(44, 25),
			Vector2i(45, 25)
		]
		project.project_atlas_pattern(self.position + Vector2i(-2, -3), tiles)
		pass

class LeverActivator:
	var target: Object
