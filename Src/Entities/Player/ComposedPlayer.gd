class_name ComposedPlayer extends ComposedCharacter2D

enum State {
	IDLE,
	WALK,
	RUN,
	HIT,
}

var state: State:
	set(value):
		last_state = state
		state = value
		state_since = 0.0
		current_state_processed = false

signal game_over(sender: ComposedPlayer)

var current_state_processed = false
var last_state: State = State.IDLE
var state_since: float = 0

var last_effect: HitEffect = null

@export_category("Movement & Accelerations")
@export var walk_accel_curve: Curve
@export var walk_accel_duration: float = 0.4
@export var walk_accel_range: Vector2 = Vector2(0.0, 100)
@export var run_accel_curve2: Curve
@export var run_accel_duration: float = 0.3
@export var run_accel_range: Vector2 = Vector2(0.0, 300)

@export_category("Sprites & Animations")
@export var main_animation: AnimatedSprite2D

var default_speed = 120
var current_acceleration = 0;
var aim_component: ComponentPlayerAim
var feet_component: ComponentHumanoidFeet

# Represent for how long effects are ignored
var invulnerability: float = 0.0


func _ready():
	stats.death.connect(on_death)
	aim_component = get_component(ComponentPlayerAim)
	feet_component = get_component(ComponentHumanoidFeet)
	if feet_component:
		feet_component.contact_with_ground_updated.connect(on_contact_with_ground_updated)
	pass

func on_death():
	print("I'm DEAD !")
	game_over.emit(self)
	
func on_contact_with_ground_updated(contact):
	if !contact:
		stats.take_hit(HitEffect.kill())

func _physics_process(delta):
	var input_direction = Input.get_vector("left", "right", "up", "down")
	var want_run = Input.is_action_pressed("run");

	state_since += delta;
	invulnerability = max(0.0, invulnerability - delta)
	
	if state != State.HIT:
		# Update state based on inputs
		if absf(input_direction.x) + absf(input_direction.y) > 0.0:
			if want_run:
				state = State.RUN
			else:
				state = State.WALK
		else:
			state = State.IDLE
	
	# Perform movement physics
	if state == State.IDLE:
		current_acceleration = 0
		velocity = Vector2.ZERO
	elif state == State.WALK:
		var accel_advance = inverse_lerp(0, walk_accel_duration, min(state_since, walk_accel_duration))
		current_acceleration = lerpf(self.walk_accel_range.x, self.walk_accel_range.y, walk_accel_curve.sample(accel_advance))
		velocity = input_direction * (default_speed + current_acceleration)

	elif state == State.RUN:
		var accel_advance = inverse_lerp(0, run_accel_duration, min(state_since, run_accel_duration))
		current_acceleration = lerpf(self.run_accel_range.x, self.run_accel_range.y, run_accel_curve2.sample(accel_advance))
		velocity = input_direction * (default_speed + current_acceleration)

	elif state == State.HIT:
		if !current_state_processed:
			print(velocity)
			current_state_processed = true
	
		velocity = Vector2.ZERO if state_since >= last_effect.poise_duration else lerp(last_effect.poise_velocity, Vector2.ZERO, inverse_lerp(0.0, last_effect.poise_duration, state_since))
		
		if state_since >= last_effect.hit_duration:
			state = State.IDLE
			
		
		#if last_effect == null:
			#state = State.IDLE
	apply_animation()
	move_and_slide()
	pass
	
func hit(effect: HitEffect) -> bool:
	if invulnerability > 0.0 && !effect.ignore_invulnerability:
		return false

	last_effect = effect
	state = State.HIT
	
	if effect.cause_invulnerability > 0.0:
		invulnerability = effect.cause_invulnerability
	
	stats.take_hit(effect)
	print(stats.hp)

	return true


func apply_animation():
	match state:
		State.IDLE:
			if main_animation.animation != "idle":
				main_animation.animation = "idle"
				main_animation.play()
		State.WALK:
			if main_animation.animation != "walk":
				main_animation.animation = "walk"
				main_animation.play()
		State.RUN:
			if main_animation.animation != "walk":
				main_animation.animation = "walk"
				main_animation.play()
	main_animation.flip_h = aim_component.aim_direction.x < 0.0
	pass
