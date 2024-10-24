extends Node

var initial_angle: Vector2;
var initial_position: Vector2;
var initial_velocity: float = 600
var initial_offset = 10

@onready var amo: RigidBody2D													= $Node2D
@onready var area: Area2D														= $Node2D/Area2D

var hit_effect: ComposedCharacter2D.HitEffect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	amo.global_position = initial_position + (initial_angle * initial_offset)
	amo.rotation = initial_angle.angle()
	var velocity = initial_angle
	print(initial_angle)
	amo.apply_central_impulse(initial_angle * initial_velocity)

	hit_effect = ComposedCharacter2D.HitEffect.new()
	hit_effect.poise_duration = 0.5
	hit_effect.hit_duration = 0.5
	hit_effect.poise_velocity = initial_angle * 50.0
	hit_effect.physic_dammage = 50.0
	pass # Replace with function body.


var destroyed = false
func _physics_process(delta: float) -> void:
	if !destroyed:
	
		var bodies = area.get_overlapping_bodies()
		if !bodies.is_empty():
			for body in bodies:
				if is_instance_of(body, typeof(ComposedCharacter2D)):
					var other: ComposedCharacter2D = body
					other.hit(hit_effect)
			destroyed = true
			queue_free()
	pass
