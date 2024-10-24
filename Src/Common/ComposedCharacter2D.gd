class_name ComposedCharacter2D extends ComposedEntity

const DEFAULT_INVULNERABILITY_DURATION = 0.5

class CharacterStats:
	var hp: float																= 100.0
	var max_hp: float															= 100.0
	
	signal death()
	
	func take_hit(effect: HitEffect):
		hp = 0.0 if effect.fatal else max(0.0, hp - effect.physic_dammage)
		if hp == 0.0:
			self.death.emit()

class HitEffect:
	var ignore_invulnerability: bool											= false
	var fatal: bool																= false
	var physic_dammage: float													= 10.0
	var magic_dammage: float													= 0.0
	var poise_duration: float													= 0.0
	var poise_velocity: Vector2 												= Vector2.ZERO
	var hit_duration: float														= 0.2
	var cause_invulnerability: float											= DEFAULT_INVULNERABILITY_DURATION
	# Will cancel all actions made by the target (I.e casting spell)
	var cancel_actions															= true

	static func kill() -> HitEffect:
		var ret = HitEffect.new()
		ret.fatal = true
		ret.ignore_invulnerability = true
		return ret

class AttackCaster:
	var attack_duration: float
	var hit_temporal_range: Vector2
	var hitbox: Area2D
	var hitbox_shape: CollisionPolygon2D
	var sprite: AnimatedSprite2D
	var hit_effect = HitEffect
	
	var since = 0.0
	var attack_hit = {}
	var ready = false
	var with_animation = false;
	var frames: float

	func _init(attack_duration: float, hit_temporal_range: Vector2, hitbox: Area2D, sprite: AnimatedSprite2D, shape_index = 0):
		self.attack_duration = attack_duration
		self.hit_temporal_range = hit_temporal_range
		self.hitbox = hitbox
		self.hitbox_shape = hitbox.get_child(shape_index)
		self.sprite = sprite
	
	func prepare(hitbox_direction: Vector2, hit_effect: HitEffect, animation = null, frames = 1):
		self.frames = frames
		self.attack_hit = {}
		self.since = 0.0
		
		if animation != null:
			self.sprite.animation = animation
			self.sprite.frame = 0
			self.with_animation = true
			self.frames = frames
		else:
			self.with_animation = false

		self.hitbox_shape.scale = TargetableEntity.scale_direction_quad(hitbox_direction)
		self.hit_effect = hit_effect
		self.ready = true
	
	func step(delta: float) -> bool:
		self.since += delta
		
		if is_over() || !self.ready:
			self.ready = false
			return false
			
		if self.with_animation:
			self.sprite.frame = int(lerp(0.0, self.frames, min(self.frames, inverse_lerp(0.0, self.attack_duration, self.since))))
	
		if self.since >= self.hit_temporal_range.x && self.since <= self.hit_temporal_range.y:
			var hits = self.hitbox.get_overlapping_bodies()
			for hit_target in hits:
				if !attack_hit.find_key(hit_target) || attack_hit[hit_target] == false:
					if is_instance_of(hit_target, typeof(ComposedCharacter2D)) && hit_target.hit(self.hit_effect):
						attack_hit[hit_target] = true
		
		return true

	func is_over() -> bool:
		return self.since >= self.attack_duration

var stats: CharacterStats = CharacterStats.new()

# Called by the other entity when an attack from other hit self
# This function return false if the hit was ignored for some reason
func hit(effect: HitEffect) -> bool:
	print("Got unhandled hit")
	print(effect)
	return true

func get_component(kind):
	var results = get_children().filter(func(x): return is_instance_of(x, kind))
	
	if results.size() == 0:
		return null
	elif results.size() > 1:
		printerr("get_component() returned more than one component");
		return null
	return results[0]
