extends CanvasLayerControl

var is_inventory_open = false
var inventory_hud: GUIInventory

@export var player: ComposedPlayer

@onready var progress_health													= $progress_health

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#var inventory_hud_scene = load("res://Scenes/GUI/UILayoutInventory.tscn")
	#inventory_hud = inventory_hud_scene.instantiate()
	#add_child(inventory_hud)
	#inventory_hud.visible = false;
	#inventory_hud.inventory = player.get_component(ComponentPlayerInventory)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("inventory"):
		toggle_inventory()
	
	if player:
		progress_health.max_value = player.stats.max_hp
		progress_health.value = player.stats.hp

	pass


func toggle_inventory():
	is_inventory_open = !is_inventory_open
	if is_inventory_open:
		inventory_hud.visible = true
		inventory_hud.status = GUIInventory.Status.OPEN
	else:
		inventory_hud.visible = false
		inventory_hud.status = GUIInventory.Status.CLOSE
	pass
