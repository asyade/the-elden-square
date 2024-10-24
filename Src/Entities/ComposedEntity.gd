class_name ComposedEntity extends CharacterBody2D

const focus_material = preload("res://Materials/outline.tres")

var sprite: AnimatedSprite2D
var aim_distance: float = 0.0
var is_highlighted: bool = false
var is_locked: bool = false

var direction = Vector2.ZERO

var last_h_flip = 0.0

func apply_sprite_mutation():
	# Aim lock highlight
	if is_locked:
		sprite.material = focus_material;
	elif is_highlighted:
		sprite.material = focus_material;
	else:
		sprite.material = null;

	if abs(direction.x) > 0.1:
		sprite.flip_h = direction.x < 0.0
