class_name ArmWithBow extends BaseArm

const BowArmAmoScene = preload("res://Src/Entities/Player/Arms/ArmWithBow/Arrow.tscn")

enum BowStatus {
	IDLE,
	AIM,
	TENSION,
	SHOOTING,
}

var status = BowStatus.IDLE
var player: ComposedPlayer = null
var aim: ComponentPlayerAim = null


var bow_sprite: AnimatedSprite2D
@export var bow_sprite_aimed_idx = 3;
@export var bow_sprite_shooted_idx = 7;

@export var aiming_duration_min = 0.4;
@export var aiming_duration_end = 1.0;
@export var shooting_duration = 0.4;


# Initialize the arm
# * Arguments
# - Determinate the arm position, 0 = left, 1 = right
func _ready() -> void:
	arms = get_parent()
	player = arms.get_parent()
	aim = player.get_component(ComponentPlayerAim)
	bow_sprite = get_node("bow_sprite")
	bow_sprite.visible = false

	if side == ArmSide.LEFT:
		get_parent().on_left_hand_action.connect(_on_hand_action)
	else:
		get_parent().on_right_hand_action.connect(_on_hand_action)
	
	get_parent().on_hand_action_canceled.connect(_on_hand_action_canceled)
	pass

func _on_hand_action(primary: bool, secondary: bool, primary_released: bool, secondary_released: bool):
	print("Action")
	print(primary)
	print(primary_released)
	if status == BowStatus.IDLE && primary:
		if take_arms_lock():
			status = BowStatus.TENSION
	elif status == BowStatus.TENSION && primary_released:
		status = BowStatus.SHOOTING
	pass

func _on_hand_action_canceled():
	pass

var amo_loaded = false;
var amo_loaded_since = 0.0;

var shooting = false;
var shooting_since = 0.0;

func _process(delta: float) -> void:
	if status == BowStatus.TENSION && !amo_loaded:
		amo_loaded = true
		amo_loaded_since = 0.0
		bow_sprite.frame = 0
		bow_sprite.visible = true
	elif status == BowStatus.TENSION && amo_loaded:
		amo_loaded_since += delta;
		bow_sprite.frame = lerp(0, bow_sprite_aimed_idx, min(1.0, inverse_lerp(0.0, aiming_duration_min, amo_loaded_since)))
		
	elif status == BowStatus.SHOOTING && !shooting:
		amo_loaded = false;
		if amo_loaded_since < aiming_duration_min:
			release();
		else:
			shooting = true;
			shooting_since = 0.0;
			print("SHOOT WITH TENSION OF")
			print(amo_loaded_since)
	elif status == BowStatus.SHOOTING && shooting:
		shooting_since += delta;
		bow_sprite.frame = lerp(bow_sprite_aimed_idx, bow_sprite_shooted_idx, min(1.0, inverse_lerp(0.0, aiming_duration_end, shooting_since)))
		
		if shooting_since >= shooting_duration:
			shooting = false;
			release()
			
			var instance = BowArmAmoScene.instantiate();
			instance.initial_position = global_position
			instance.initial_angle = aim.aim_direction
			add_child(instance)
			bow_sprite.visible = false
			print("SHOOT DONE !")
			
	
	if aim.aim_direction.x < 0.0:
		bow_sprite.flip_v = true
	else:
		bow_sprite.flip_v = false
		
	rotation = aim.aim_direction.angle();
	update_visibility()

	
	pass

func release():
	status = BowStatus.IDLE
	bow_sprite.visible = false
	release_arms_lock()
