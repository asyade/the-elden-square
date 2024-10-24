extends Node

const player_scene = preload("res://Src/Entities/Player/player.tscn")

var player_spawned = false

@onready var timer: Timer														= $Timer
@export var player_container: Node2D
@export var player_offset: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer.timeout.connect(on_update)
	pass # Replace with function body.

func on_update() -> void:
	if !player_spawned:
		player_spawned = true
		
		var instance: ComposedPlayer = player_scene.instantiate()
		instance.game_over.connect(game_over)
		instance.add_to_group("entity_player_1")
		if player_container == null:
			add_child(instance)
		else:
			player_container.add_child(instance)

		if player_offset != null:
			instance.position = player_offset

func game_over(sender: ComposedPlayer):
	sender.queue_free()
	player_spawned = false
