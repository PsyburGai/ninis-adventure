extends CharacterBody2D
class_name BossEncounter

## Real-time overworld boss.
## Same combat model as EnemyEncounter but with higher stats,
## a phase system, and a persistent defeated state.
## No battle screen — all combat happens in the level.

@export var boss_name: String = "Cake Monster"
@export var boss_max_hp: int = 100
@export var boss_attack: int = 12
@export var boss_defense: int = 8
@export var boss_xp_reward: int = 100
@export var contact_damage_cooldown: float = 1.0
@export var knockback_force: float = 240.0

# Phase 2 triggers at this HP fraction (0.5 = 50%)
@export var phase2_threshold: float = 0.5
@export var phase2_walk_speed_multiplier: float = 1.6

# Walking
@export var walk_speed: float = 20.0
@export var walk_min_x: float = -999999.0
@export var walk_max_x: float = 999999.0

const GRAVITY = 500.0
const HIT_FLASH_DURATION: float = 0.1
const HIT_FLASHES: int = 4

var current_hp: int
var is_active: bool = true
var is_defeated: bool = false
var in_phase2: bool = false
var _contact_timer: float = 0.0
var _is_flashing: bool = false

var is_walking: bool = false
var walk_direction: int = 1
var _current_walk_speed: float

var sword_receiver: Area2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	current_hp = boss_max_hp
	_current_walk_speed = walk_speed
	add_to_group("enemies")

	if is_defeated:
		queue_free()
		return

	# Build sword-hit receiver
	sword_receiver = Area2D.new()
	sword_receiver.name = "SwordReceiver"
	sword_receiver.collision_layer = 0
	sword_receiver.collision_mask = 4  # Must match SwordHitbox layer in Nini
	var recv_shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(28, 28)
	recv_shape.shape = rect
	sword_receiver.add_child(recv_shape)
	add_child(sword_receiver)
	sword_receiver.area_entered.connect(_on_sword_hit)

	_start_walking_cycle()

# ── Physics ───────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	if not is_on_floor():
		velocity.y += GRAVITY * delta

	move_and_slide()

	if _contact_timer > 0.0:
		_contact_timer -= delta

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player") and _contact_timer <= 0.0:
			_deal_contact_damage(collider)

# ── Receiving sword hits ──────────────────────────────────────────────────────

func _on_sword_hit(area: Area2D) -> void:
	if not is_active or is_defeated:
		return
	if not area.name == "SwordHitbox":
		return

	var raw_damage: int = 10
	var player = area.get_parent()
	if player and player.has_method("get_attack_power"):
		raw_damage = player.get_attack_power()

	var damage = max(1, raw_damage - boss_defense)
	_take_damage(damage)

# Public interface called by Nini's _deal_sword_damage()
func take_damage(amount: int, _source: Node = null) -> void:
	var damage = max(1, amount - boss_defense)
	_take_damage(damage)

func _take_damage(amount: int) -> void:
	current_hp -= amount
	if not _is_flashing:
		_flash_hit()

	# Enter phase 2 when HP crosses threshold
	if not in_phase2 and current_hp <= int(boss_max_hp * phase2_threshold):
		_enter_phase2()

	if current_hp <= 0:
		_die()

# ── Phase 2 ───────────────────────────────────────────────────────────────────

func _enter_phase2() -> void:
	in_phase2 = true
	_current_walk_speed = walk_speed * phase2_walk_speed_multiplier
	# Visual cue — tint the boss slightly red
	if sprite:
		sprite.modulate = Color(1.0, 0.7, 0.7)

# ── Contact damage ────────────────────────────────────────────────────────────

func _deal_contact_damage(player: Node) -> void:
	_contact_timer = contact_damage_cooldown
	if player.has_method("take_damage"):
		player.take_damage(boss_attack, _knockback_direction(player))

func _knockback_direction(player: Node) -> Vector2:
	var dir = (player.global_position - global_position).normalized()
	return Vector2(dir.x, -0.5).normalized() * knockback_force

# ── Death ─────────────────────────────────────────────────────────────────────

func _die() -> void:
	is_active = false
	is_defeated = true

	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_method("gain_xp"):
			p.gain_xp(boss_xp_reward)

	await _play_death_effect()
	queue_free()

func _play_death_effect() -> void:
	# Dramatic multi-flash then scale down
	if sprite:
		for _i in range(6):
			sprite.modulate = Color(1, 1, 0.1)
			await get_tree().create_timer(0.07).timeout
			sprite.modulate = Color(1, 0.2, 0.2)
			await get_tree().create_timer(0.07).timeout
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.4, 0.1), 0.1)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
	await tween.finished

# ── Hit flash ─────────────────────────────────────────────────────────────────

func _flash_hit() -> void:
	_is_flashing = true
	if not sprite:
		_is_flashing = false
		return
	var original = sprite.modulate
	for _i in range(HIT_FLASHES):
		sprite.modulate = Color(1, 0.15, 0.15)
		await get_tree().create_timer(HIT_FLASH_DURATION).timeout
		sprite.modulate = original
		await get_tree().create_timer(HIT_FLASH_DURATION).timeout
	_is_flashing = false

# ── Walking AI ────────────────────────────────────────────────────────────────

func _start_walking_cycle() -> void:
	while is_instance_valid(self) and not is_defeated:
		var strides_remaining = randi_range(3, 10)
		is_walking = true
		if sprite:
			sprite.frame = 1

		for _stride in range(strides_remaining):
			await _walk_one_stride()

		is_walking = false
		if sprite:
			sprite.frame = 0

		var pause_time = 1.0 if randf() > 0.5 else 0.3
		await get_tree().create_timer(pause_time).timeout

		if randf() > 0.5:
			walk_direction *= -1
			if sprite:
				sprite.flip_h = walk_direction < 0

func _walk_one_stride() -> void:
	for _step in range(4):
		if not is_walking or is_defeated:
			break
		var new_x = global_position.x + (walk_direction * _current_walk_speed * 0.1)
		if new_x > walk_min_x and new_x < walk_max_x:
			velocity.x = walk_direction * _current_walk_speed
		else:
			walk_direction *= -1
			if sprite:
				sprite.flip_h = walk_direction < 0
		await get_tree().create_timer(0.1).timeout
	velocity.x = 0.0
