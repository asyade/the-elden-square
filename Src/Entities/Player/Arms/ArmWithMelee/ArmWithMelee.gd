class_name ArmWithMelee extends BaseArm

enum MeleeStatus {
	IDLE,
	SHORT_ATTACK,
	SHORT_ATTACK_VARIATION,
}

var status: MeleeStatus:
	set(value):
		status = value
		current_state_processed = false;
		current_state_since = 0;

var current_state_since = 0;
var current_state_processed = false;


var attack_1: ComposedCharacter2D.AttackCaster

var player: ComposedPlayer = null
var aim: ComponentPlayerAim = null

@onready var fx: AnimatedSprite2D												= $"Fx"
@onready var hitbox: Area2D													    = $"HitBox"
@onready var hitbox_shape: CollisionPolygon2D									= $"HitBox/polygon"

func attack_1_effect():
	var effect = ComposedCharacter2D.HitEffect.new()
	effect.physic_dammage = 100.0
	effect.poise_duration = 0.2
	effect.poise_velocity = aim.aim_direction * 100.0
	return effect

# Initialize the arm
# * Arguments
# - Determinate the arm position, 0 = left, 1 = right
func _ready() -> void:
	attack_1 = ComposedCharacter2D.AttackCaster.new(0.5, Vector2(0.2, 0.4), hitbox, fx, 0)
	
	player = get_parent().get_parent()
	aim = player.get_component(ComponentPlayerAim)
	arms = player.get_component(ComposedPlayerArms)

	if side == ArmSide.LEFT:
		get_parent().on_left_hand_action.connect(_on_hand_action)
	else:
		get_parent().on_right_hand_action.connect(_on_hand_action)
	
	get_parent().on_hand_action_canceled.connect(_on_hand_action_canceled)
	pass

func _on_hand_action(primary: bool, secondary: bool, primary_released: bool, secondary_released: bool):
	if status == MeleeStatus.IDLE && primary:
		if take_arms_lock(false, true):
			status = MeleeStatus.SHORT_ATTACK;
	pass

func _on_hand_action_canceled():
	pass
	
func _process(delta: float) -> void:
	current_state_since += delta;
	
	if status == MeleeStatus.IDLE:
		if !current_state_processed:
			current_state_processed = true
			fx.animation = "IDLE"
			fx.frame = 0
			fx.play()

		if arms_lock_id != -1:
			release_arms_lock()
		fx.flip_h = aim.aim_direction.x < 0 

	elif status == MeleeStatus.SHORT_ATTACK:
		if !current_state_processed:
			var animation;
			if aim.quarter_aim_direction == Vector2.LEFT || aim.quarter_aim_direction == Vector2.RIGHT:
				animation = "SHORT_ATTACK_SIDE"
			elif aim.quarter_aim_direction == Vector2.UP:
				animation = "SHORT_ATTACK_DOWN"
			elif aim.quarter_aim_direction == Vector2.DOWN:
				animation = "SHORT_ATTACK_UP"
			fx.flip_h = aim.aim_direction.x < 0 
			attack_1.prepare(aim.aim_direction, attack_1_effect(), animation, 11)
			current_state_processed = true
		else:
			if !attack_1.step(delta):
				release_arms_lock()
				status = MeleeStatus.IDLE

	update_visibility()
	
	pass
