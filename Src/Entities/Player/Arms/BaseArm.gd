class_name BaseArm extends Node2D

enum ArmSide {
	LEFT = 0,
	RIGHT = 1
}

@export var side: ArmSide = ArmSide.LEFT;

var arms_lock_id = -1;
var arms: ComposedPlayerArms = null

func _init() -> void:
	arms = get_parent()

func update_visibility() -> void:
	if side == ArmSide.LEFT:
		visible = arms.status != ComposedPlayerArms.TorsoState.HIDDEN_BY_RIGHT
	else:
		visible = arms.status != ComposedPlayerArms.TorsoState.HIDDEN_BY_LEFT

func take_arms_lock(cancelable = false, hide_other = true):
	var required_status;
	if side == ArmSide.LEFT:
		required_status = ComposedPlayerArms.TorsoState.HIDDEN_BY_LEFT if hide_other else ComposedPlayerArms.TorsoState.USED_BY_LEFT
	else:
		required_status = ComposedPlayerArms.TorsoState.HIDDEN_BY_RIGHT if hide_other else ComposedPlayerArms.TorsoState.USED_BY_RIGHT

	arms_lock_id = arms.take_lock(required_status, cancelable)
	return arms_lock_id != -1

func release_arms_lock():
	if arms_lock_id != -1:
		arms.release_lock(arms_lock_id)
		arms_lock_id = -1;
	pass
