@tool
class_name SlotBase extends Control

const WIDTH = 64.0
const HEIGHT= 64.0

enum UISlotStatus {
	DISABLED,
	ENABLED,
	FOCUSED
}

var default_background_texture_path = "res://Assets/UI/inventory_slot.png"
var slot_name: String
var icon: Texture2D:
	set(value):
		icon = value
		queue_redraw()

@export var status: UISlotStatus:
	set(value):
		status = value
		queue_redraw()

@export var background_texture : Texture2D:
	set(value):
		background_texture = value
		queue_redraw()
		
signal activated()

func _init() -> void:
	if background_texture == null:
		background_texture = load(default_background_texture_path)
	size = Vector2(WIDTH, HEIGHT)
	queue_redraw()
	pass


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return

	var global_mouse_position = get_global_mouse_position()
	
	if global_mouse_position.x >= global_position.x && global_mouse_position.x <= global_position.x + WIDTH && global_mouse_position.y >= global_position.y && global_mouse_position.y <= global_position.y + HEIGHT:
		if Input.is_action_just_pressed("mouse_click"):
			if status == UISlotStatus.ENABLED:
				activated.emit(slot_name)

	
	pass

func _draw() -> void:
	match status:
		UISlotStatus.DISABLED:
			draw_texture(background_texture, Vector2(0.0, 0.0), Color(1, 1, 1, 0.2))
		UISlotStatus.ENABLED:
			draw_texture(background_texture, Vector2(0.0, 0.0), Color(1, 1, 1, 1.0))
		UISlotStatus.FOCUSED:
			draw_texture(background_texture, Vector2(0.0, 0.0), Color(1, 1, 1, 1.0))
	if icon != null:
		draw_texture_rect(icon, Rect2(4, 4, 56, 56), false)
	pass
