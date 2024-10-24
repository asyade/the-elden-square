class_name Skeleton extends ComposedCharacter2D

enum Status {
	IDLE,
	PLACEMENT,
	RUSH,
	ATTACK_1,
	HIT,
	DEAD,
}

@export var region: NavigationRegion2D
@onready var navigation_agent: NavigationAgent2D 								= $Navigation/NavigationAgent
@onready var navigation_timer: Timer 											= $Navigation/Timer
@onready var attack_hitbox: CollisionPolygon2D 									= $hitbox/Attack1_polygon
@onready var hitbox_area: Area2D 												= $hitbox

@export var debug_target: bool 													= false
@export var aim: ComponentMobAim

var attack_1: AttackCaster

var default_speed = 70
var rush_speed = 120
var rush_distance = 160
var acceleration = 20
var rush_max_duration = 0.7

var status: Status:
	set(value):
		status = value
		status_processed = false
		status_since = 0.0

var status_since = 0.0
var status_processed = false

var previous_cell = null

var last_effect: HitEffect
var invulnerability: float = 0.0

func attack_1_effect(direction: Vector2):
	var effect = ComposedCharacter2D.HitEffect.new()
	effect.hit_duration = 0.6
	effect.physic_dammage = 10.0
	effect.poise_duration = 0.6
	effect.poise_velocity = direction * 100.0
	return effect


func _ready() -> void:
	aim = get_component(ComponentMobAim)
	sprite = get_node("MainSprite")
	sprite.speed_scale = 2
	attack_1 = AttackCaster.new(
		0.6,
		Vector2(0.2, 0.4),
		self.hitbox_area,
		self.sprite
	)
	stats.death.connect(on_death)

func on_death():
	status = Status.DEAD
	
func on_death_finished():
	queue_free()

func _physics_process(delta: float) -> void:
	status_since += delta
	
	aim.focus_step(delta)

	if debug_target:
		queue_redraw()
	if status == Status.IDLE:
		if !status_processed:
			sprite.animation = "idle"
			sprite.play()
		if aim.current_focus != null:
			status = Status.PLACEMENT
	elif status == Status.PLACEMENT:
		if !status_processed:
			sprite.animation = "walk"
			sprite.play()
			status_processed = true
		
		if aim.current_focus == null:
			status = Status.IDLE
		elif aim.distance_to_current_focus < rush_distance && status_since > 2.0:
			status = Status.RUSH
		else:
			impulse_to(navigation_agent.get_next_path_position(), default_speed)
		
	elif status == Status.RUSH:
		if !status_processed:
			sprite.animation = "walk"
			sprite.play()
			status_processed = true
			
		if aim.current_focus == null:
			status = Status.IDLE;
		elif status_since >= rush_max_duration:
			status = Status.PLACEMENT
		elif aim.distance_to_current_focus < 40.0:
			velocity = Vector2.ZERO
			direction = (aim.current_focus.global_position - global_position).normalized()
			var animation = "attack_1" if aim.current_focus.global_position.y < global_position.y else "attack_2"
			attack_1.prepare(direction, attack_1_effect(direction), animation, 12)
			status = Status.ATTACK_1
		else:
			impulse_to(aim.current_focus.global_position, rush_speed)

	elif status == Status.ATTACK_1:
		if aim.current_focus == null:
			status = Status.IDLE
		if !attack_1.step(delta):
			status = Status.PLACEMENT

	elif status == Status.HIT:
		if !status_processed:
			sprite.animation = "hit"
			sprite.play()
			status_processed = true
		velocity = Vector2.ZERO if status_since >= last_effect.poise_duration else lerp(last_effect.poise_velocity, Vector2.ZERO, inverse_lerp(0.0, last_effect.poise_duration, status_since))
		if status_since >= last_effect.hit_duration:
			status = Status.PLACEMENT
	elif status == Status.DEAD:
		sprite.animation = "dead"
		sprite.play()
		sprite.animation_finished.connect(on_death_finished)
		velocity = Vector2.ZERO

	apply_sprite_mutation()
	move_and_slide()

func hit(effect: HitEffect) -> bool:
	last_effect = effect
	status = Status.HIT
	stats.take_hit(effect)
	return true


func _on_timer_timeout() -> void:
	if aim.current_focus == null:
		return
	
	var target_gliph = TargetableEntity.Gliph.new(TargetableEntity.GliphShape.Circle)
	target_gliph.radius = 6
	target_gliph.circle_hole = true
	target_gliph.circle_hole_radius = 4
	target_gliph.compute()
	
	previous_cell = aim.current_target.gliph.warn_cell(target_gliph, TargetableEntity.world_to_cell(aim.current_target.global_position - global_position), .6, previous_cell, 1.0)
	
	if previous_cell == null:
		return
	var pos = aim.current_target.global_position + (TargetableEntity.cell_to_world(previous_cell.position))
	navigation_agent.target_position = pos;
	pass

func _draw() -> void:
	if !debug_target || previous_cell == null:
		return
	var offset = (navigation_agent.target_position - global_position)
	draw_rect(Rect2(offset - Vector2(TargetableEntity.CELL_WIDTH / 2.0, TargetableEntity.CELL_HEIGHT / 2.0), Vector2(TargetableEntity.CELL_WIDTH, TargetableEntity.CELL_HEIGHT)), Color.PERU)
	pass

func impulse_to(next_pos, speed):
	if next_pos.distance_to(global_position) > 4.0:
		direction = (next_pos - global_position).normalized()
	velocity = velocity.lerp(direction * speed, 1.0)
