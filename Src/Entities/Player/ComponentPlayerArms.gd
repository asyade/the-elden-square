# Arms base script is responsible of hosting two arm (left and right).
# The Arms is forwarding signals such as game input to the left and right arm
# He is also responsible of arm switching (based on inventory or son one

class_name ComposedPlayerArms extends Component2D

enum TorsoState {
	# Idle state
	IDLE,
	# The left hand is doing something (will right hand still visible)
	USED_BY_LEFT,
	# The left hand is doing something that hide the right hand
	HIDDEN_BY_LEFT,
	# The right hand is doing something that hide the left hand
	USED_BY_RIGHT,
	# The right hand is doing something that hide the left hand
	HIDDEN_BY_RIGHT,
}

var status: TorsoState:
	set(value):
		status = value
		if status == TorsoState.IDLE:
			current_status_cancelable = false

var current_status_cancelable = false
var focusCounter = 0

signal on_left_hand_action(primary_just_pressed: bool, secondary_just_pressed: bool, primary_just_released: bool, secondary_just_released: bool)
signal on_right_hand_action(primary_just_pressed: bool, secondary_just_pressed: bool, primary_just_released: bool, secondary_just_released: bool)
signal on_hand_action_canceled(lock_id)

var arms_lock_id = 1
func take_lock(required_state: TorsoState, cancelable: bool):
	if status != TorsoState.IDLE && !current_status_cancelable:
		return -1

	var previous_lock_id = arms_lock_id
	arms_lock_id += 1
	
	status = required_state
	current_status_cancelable = cancelable
	
	if status != TorsoState.IDLE:
		on_hand_action_canceled.emit(previous_lock_id)

	return arms_lock_id
	
func release_lock(id):
	if arms_lock_id == id:
		status = TorsoState.IDLE

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	var left_primary_just_pressed = 1 if Input.is_action_just_pressed("primary_attack_left") else 0
	var left_secondary_just_pressed = 1 if Input.is_action_just_pressed("secondary_attack_left") else 0
	var right_primary_just_pressed = 1 if Input.is_action_just_pressed("primary_attack_right") else 0
	var right_secondary_just_pressed = 1 if Input.is_action_just_pressed("secondary_attack_right") else 0

	var left_primary_just_releassed = 1 if Input.is_action_just_released("primary_attack_left") else 0
	var left_secondary_just_releassed = 1 if Input.is_action_just_released("secondary_attack_left") else 0
	var right_primary_just_releassed = 1 if Input.is_action_just_released("primary_attack_right") else 0
	var right_secondary_just_releassed = 1 if Input.is_action_just_released("secondary_attack_right") else 0

	if left_primary_just_pressed || left_secondary_just_pressed || left_secondary_just_releassed || left_primary_just_releassed:
		on_left_hand_action.emit(left_primary_just_pressed, left_secondary_just_pressed, left_primary_just_releassed, left_secondary_just_releassed)

	if right_primary_just_pressed || right_secondary_just_pressed || right_primary_just_releassed || right_secondary_just_releassed:
		on_right_hand_action.emit(right_primary_just_pressed, right_secondary_just_pressed, right_primary_just_releassed, right_secondary_just_releassed)

	pass
