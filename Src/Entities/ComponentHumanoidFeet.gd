# When used as a child of ComposedEntity, apply game physics to the entity

class_name ComponentHumanoidFeet extends Area2D

var shape: CollisionShape2D
var contact_with_ground_signaled = true

var is_init = .5

var contact_with_ground: bool:
	set(value):
		if value != contact_with_ground:
			contact_with_ground_signaled = false
		contact_with_ground = value
signal contact_with_ground_updated(contact_with_ground: bool)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contact_with_ground = true
	shape = get_child(0)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	is_init -= delta
	if is_init > 0.0:
		return
	
	contact_with_ground = has_overlapping_bodies()
	
	if !contact_with_ground_signaled:
		contact_with_ground_updated.emit(contact_with_ground)
		contact_with_ground_signaled = true
	pass
