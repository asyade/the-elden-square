class_name ComponentPlayerAim extends Component2D

const DEFAULT_TARGET_ENTITY_GROUP 												= "entity_mob_1"

@export var cursor: Sprite2D;

var current_focus: ComposedEntity
var current_lock: ComposedEntity

# Aim direction vector desired (the joystick)
var input_aim_direction: Vector2 = Vector2(0.0, 0.0)

# Desired aim direction
# based on lock and manual aim this vector reflect imediatly the desired direction without any smoothing
var desired_aim_direction: Vector2 = Vector2.RIGHT

# Actual aim direction, smoothly updated to follow `desired_location`
var aim_direction: Vector2 = Vector2.RIGHT
var quarter_aim_direction: Vector2 = Vector2(0.0, 0.0)

signal on_focus_changed(target: Node2D)

func _ready() -> void:
	cursor.visible = false;
	pass


func _process(delta: float) -> void:
	var want_lock = Input.is_action_just_pressed("lock_target")
	var input_direction = Input.get_vector("left", "right", "up", "down")

	input_aim_direction = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	
	if abs(input_aim_direction.x) + abs(input_aim_direction.y) > 0.0:
		if !cursor.visible:
			cursor.visible = true;
		
		# TODO: optimise entities loading (maybe skip frames betwen refresh or find more optmized system)
		var targetable_entities = get_tree().get_nodes_in_group("entity_mob_1")
		
		# Calculate dot product betwen aim vector and character to ennemy vector 
		for entity in targetable_entities:
			if is_instance_of(entity, ComposedEntity):
				var entity_2d: ComposedEntity = entity;
				var entity_direction = global_position - entity_2d.global_position
				var distance = input_aim_direction.dot(entity_direction)
				entity_2d.aim_distance = distance
		
		# Find the nearest ennemy from the aim vector based on the previously calculated distance
		var min_distance: float
		var min_entity: ComposedEntity
		for entity in targetable_entities.filter(func(x): return !x.is_locked):
			if min_distance == null || min_distance > entity.aim_distance:
				min_distance = entity.aim_distance
				min_entity = entity
				
		# If an entity is aimed put the cursor around it
		# TODO: lot of things around
		if min_entity != null &&  current_focus != min_entity:
			release_focus()
			current_focus = min_entity
			current_focus.is_highlighted = true
							
			on_focus_changed.emit(current_focus)
		elif min_entity == null:
			release_focus()
			on_focus_changed.emit(null)
			
		if want_lock:
			lock_entity(current_focus)

		cursor.position = input_aim_direction * 128.0;
	else:
		cursor.visible = false
		release_focus()
		
		if input_direction.x > 0.0:
			desired_aim_direction = Vector2.RIGHT
		elif input_direction.x < 0.0:
			desired_aim_direction = Vector2.LEFT
		
		if want_lock:
			lock_entity(null)
			
	
	if cursor.visible:
		desired_aim_direction = input_aim_direction;
	elif current_lock != null:
		desired_aim_direction = (current_lock.global_position - global_position).normalized()
		
	aim_direction = desired_aim_direction
	
	var left_dot = aim_direction.dot(Vector2.LEFT)
	var right_dot = aim_direction.dot(Vector2.RIGHT)
	var up_dot = aim_direction.dot(Vector2.UP)
	var down_dot = aim_direction.dot(Vector2.DOWN)
	
	if left_dot < right_dot && left_dot < up_dot && left_dot < down_dot:
		quarter_aim_direction = Vector2.LEFT
		
	if right_dot < left_dot && right_dot < up_dot && right_dot < down_dot:
		quarter_aim_direction = Vector2.RIGHT
	
	if up_dot < left_dot && up_dot < right_dot && up_dot < down_dot:
		quarter_aim_direction = Vector2.UP
	
	if down_dot < left_dot && down_dot < right_dot && down_dot < up_dot:
		quarter_aim_direction = Vector2.DOWN
	
	pass

func release_focus():
	if current_focus != null:
		current_focus.is_highlighted = false;
		current_focus = null;

func lock_entity(entity):
	if current_lock != null:
		current_lock.is_locked = false
	current_lock = entity
	if current_lock != null:
		current_lock.is_locked = true
	pass
