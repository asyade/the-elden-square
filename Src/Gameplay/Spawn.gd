class_name Spawn extends Node2D

const player_scene = preload("res://Src/Entities/Player/player.tscn")

var player_spawned = false

var spawn_interval = 1.0
var last_spawn = 0.0

@export var player_container: Node2D
@export var player_offset: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	last_spawn += delta
	if last_spawn > spawn_interval:
		last_spawn = 0.0
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
