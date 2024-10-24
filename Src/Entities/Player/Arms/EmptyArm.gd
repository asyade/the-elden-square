class_name EmptyArm extends BaseArm

var player: ComposedPlayer = null

# Initialize the arm
# * Arguments
# - Determinate the arm position, 0 = left, 1 = right
func _ready() -> void:
	player = get_parent().get_parent() 

	if side == ArmSide.LEFT:
		get_parent().on_left_hand_action.connect(_on_hand_action)
	else:
		get_parent().on_right_hand_action.connect(_on_hand_action)
	pass # Replace with function body.


func _on_hand_action(primary: bool, secondary: bool, primary_released: bool, secondary_released: bool):
	print("Hand action !!!!")
	pass
