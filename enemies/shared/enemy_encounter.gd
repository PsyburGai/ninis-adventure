extends CharacterBody2D
class_name EnemyEncounter

## Real-time overworld enemy.
## Takes damage from the player's SwordHitbox.
## Deals contact damage to the player when touching them.
## No battle screen — all combat happens here in the level.

@export var enemy_name: String = "Cupcake"
@export var enemy_max_hp: int = 25
@export var enemy_attack: int = 6        # Contact damage dealt to player per hit
@export var enemy_defense: int = 3       # Damage reduction (flat)
@export var enemy_xp_reward: int = 15
@export var respawn_time: float = 30.0
@export var respawn_on_defeat: bool = true

# Contact damage cooldown — prevents player getting hit every frame
@export var contact_damage_cooldown: float = 1.0

# Walking
@export var can_walk: bool = false
@export var walk_speed: float = 20.0
@export var walk_min_x: float = -999999.0
@export var walk_max_x: float = 999999.0

# Knockback applied to player on contact
@export var knockback_force: float = 180.0

const GRAVITY = 500.0

# Flash effect on hit
const HIT_FLASH_DURATION: float = 0.12
const HIT_FLASHES: int = 3

var current_hp: int
var is_active: bool = true
var _contact_timer: float = 0.0
var _is_flashing: bool = false
var _spawn_position: Vector2

# Walking state
var is_walking: bool = false
var walk_direction: int = 1
var sprite: Sprite2D = null
var animated_sprite: AnimatedSprite2D = null

# Hitbox for receiving sword hits
var sword_receiver: Area2D = null

# Health bar UI (created at runtime)
var _name_label: Label = null
var _hp_bar_bg: ColorRect = null
var _hp_bar_fill: ColorRect = null
const HP_BAR_WIDTH = 28.0
const HP_BAR_HEIGHT = 3.0
const HP_BAR_Y_OFFSET = -28.0  # Above the sprite

@export var auto_detect_edges: bool = true

func _ready() -> void:
	current_hp = enemy_max_hp
	_spawn_position = global_position
	add_to_group("enemies")

	# Locate sprite child
	for child in get_children():
		if child is AnimatedSprite2D:
			animated_sprite = child
			break
		elif child is Sprite2D:
			sprite = child

	# Build the hitbox that receives sword hits
	sword_receiver = Area2D.new()
	sword_receiver.name = "SwordReceiver"
	sword_receiver.collision_layer = 0
	sword_receiver.collision_mask = 4  # Layer 3 — must match SwordHitbox layer in Nini
	var recv_shape = CollisionShape2D.new()
	# Reuse the enemy's own collision shape size if present, otherwise use a default
	var existing = _find_collision_shape()
	if existing:
		recv_shape.shape = existing.shape
		recv_shape.position = existing.position
	else:
		var rect = RectangleShape2D.new()
		rect.size = Vector2(20, 22)
		recv_shape.shape = rect
	sword_receiver.add_child(recv_shape)
	add_child(sword_receiver)
	sword_receiver.area_entered.connect(_on_sword_hit)

	_build_health_bar()

	if can_walk:
		if auto_detect_edges:
			# Wait until the enemy has landed on the floor before detecting patrol bounds
			await _wait_until_on_floor()
			_detect_patrol_bounds()
		if animated_sprite or sprite:
			_start_walking_cycle()

func _find_collision_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child
	return null

# ── Health bar ────────────────────────────────────────────────────────────────

func _build_health_bar() -> void:
	# Name label above the enemy
	_name_label = Label.new()
	_name_label.text = enemy_name
	_name_label.add_theme_font_size_override("font_size", 6)
	_name_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.position = Vector2(-HP_BAR_WIDTH / 2.0 - 2, HP_BAR_Y_OFFSET - 10)
	_name_label.size = Vector2(HP_BAR_WIDTH + 4, 10)
	add_child(_name_label)

	# HP bar background (dark)
	_hp_bar_bg = ColorRect.new()
	_hp_bar_bg.color = Color(0.15, 0.15, 0.15, 0.8)
	_hp_bar_bg.position = Vector2(-HP_BAR_WIDTH / 2.0, HP_BAR_Y_OFFSET)
	_hp_bar_bg.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	add_child(_hp_bar_bg)

	# HP bar fill (blue like screenshot)
	_hp_bar_fill = ColorRect.new()
	_hp_bar_fill.color = Color(0.15, 0.3, 0.9, 1.0)
	_hp_bar_fill.position = Vector2(-HP_BAR_WIDTH / 2.0, HP_BAR_Y_OFFSET)
	_hp_bar_fill.size = Vector2(HP_BAR_WIDTH, HP_BAR_HEIGHT)
	add_child(_hp_bar_fill)

func _update_health_bar() -> void:
	if _hp_bar_fill:
		var ratio = clamp(float(current_hp) / float(enemy_max_hp), 0.0, 1.0)
		_hp_bar_fill.size.x = HP_BAR_WIDTH * ratio
	# Hide everything when dead
	if not is_active:
		if _name_label:
			_name_label.visible = false
		if _hp_bar_bg:
			_hp_bar_bg.visible = false
		if _hp_bar_fill:
			_hp_bar_fill.visible = false
	else:
		if _name_label:
			_name_label.visible = true
		if _hp_bar_bg:
			_hp_bar_bg.visible = true
		if _hp_bar_fill:
			_hp_bar_fill.visible = true

# ── Physics ───────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	move_and_slide()

	# Contact damage cooldown tick
	if _contact_timer > 0.0:
		_contact_timer -= delta

	# Check player contact for dealing damage
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.is_in_group("player") and _contact_timer <= 0.0:
			_deal_contact_damage(collider)

# ── Receiving sword hits ──────────────────────────────────────────────────────

func _on_sword_hit(_area: Area2D) -> void:
	# Damage is handled by Nini's _deal_sword_damage() via body_entered.
	# This callback is kept as a fallback but defers to avoid double hits.
	pass

# Public interface called by Nini's _deal_sword_damage()
func take_damage(amount: int, _source: Node = null) -> void:
	var damage = max(1, amount - enemy_defense)
	_take_damage(damage)

func _take_damage(amount: int) -> void:
	current_hp -= amount
	_update_health_bar()
	if not _is_flashing:
		_flash_hit()
	if current_hp <= 0:
		_die()

# ── Contact damage (enemy touches player) ────────────────────────────────────

func _deal_contact_damage(player: Node) -> void:
	_contact_timer = contact_damage_cooldown
	if player.has_method("take_damage"):
		player.take_damage(enemy_attack, _knockback_direction(player))

func _knockback_direction(player: Node) -> Vector2:
	var dir = (player.global_position - global_position).normalized()
	return Vector2(dir.x, -0.5).normalized() * knockback_force

# ── Death & respawn ───────────────────────────────────────────────────────────

func _die() -> void:
	is_active = false
	is_walking = false
	velocity = Vector2.ZERO

	# Grant XP to player
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_method("gain_xp"):
			p.gain_xp(enemy_xp_reward)

	if respawn_on_defeat:
		await _play_death_effect()
		# Hide and disable collision while waiting to respawn
		visible = false
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)

		await get_tree().create_timer(respawn_time).timeout

		# Teleport back to original spawn point
		global_position = _spawn_position
		scale = Vector2.ONE
		current_hp = enemy_max_hp
		is_active = true
		visible = true
		set_deferred("collision_layer", 2)
		set_deferred("collision_mask", 1)
		walk_direction = 1
		_update_health_bar()

		# Reset sprite appearance
		if animated_sprite:
			animated_sprite.modulate = Color.WHITE
			animated_sprite.flip_h = false
			animated_sprite.play("Idle")
		elif sprite:
			sprite.modulate = Color.WHITE
			sprite.flip_h = false

		# Restart walking AI
		if can_walk and (animated_sprite or sprite):
			_start_walking_cycle()
	else:
		# Simple pop-out effect then remove
		await _play_death_effect()
		queue_free()

func _play_death_effect() -> void:
	# Quick scale-down squish before disappearing
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 0.2), 0.08)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.08)
	await tween.finished

# ── Hit flash ────────────────────────────────────────────────────────────────

func _flash_hit() -> void:
	_is_flashing = true
	var target: CanvasItem = null
	if animated_sprite:
		target = animated_sprite
	elif sprite:
		target = sprite
	if not target:
		_is_flashing = false
		return
	for _i in range(HIT_FLASHES):
		target.modulate = Color(1, 0.2, 0.2)
		await get_tree().create_timer(HIT_FLASH_DURATION).timeout
		target.modulate = Color.WHITE
		await get_tree().create_timer(HIT_FLASH_DURATION).timeout
	_is_flashing = false

# ── Edge detection ────────────────────────────────────────────────────────────

func _wait_until_on_floor() -> void:
	# Give gravity time to pull the enemy down onto the platform (up to ~2 seconds)
	for _i in range(120):
		await get_tree().physics_frame
		if is_on_floor():
			return

func _detect_patrol_bounds() -> void:
	var space_state = get_world_2d().direct_space_state
	var spawn_pos = global_position
	var step = 8.0
	var max_dist = 400.0  # Don't patrol further than this from spawn
	var ray_depth = 48.0  # How far below to check for floor

	var min_x = spawn_pos.x
	var max_x = spawn_pos.x

	# Exclude self so rays don't hit our own collision shape
	var exclude_rids: Array[RID] = [get_rid()]

	# Cast right until no floor found
	while max_x - spawn_pos.x < max_dist:
		var query = PhysicsRayQueryParameters2D.create(
			Vector2(max_x + step, spawn_pos.y),
			Vector2(max_x + step, spawn_pos.y + ray_depth)
		)
		query.exclude = exclude_rids
		if space_state.intersect_ray(query):
			max_x += step
		else:
			break

	# Cast left until no floor found
	while spawn_pos.x - min_x < max_dist:
		var query = PhysicsRayQueryParameters2D.create(
			Vector2(min_x - step, spawn_pos.y),
			Vector2(min_x - step, spawn_pos.y + ray_depth)
		)
		query.exclude = exclude_rids
		if space_state.intersect_ray(query):
			min_x -= step
		else:
			break

	# Fallback: if bounds are too narrow, use a default patrol radius
	if max_x - min_x < 32.0:
		walk_min_x = spawn_pos.x - 80.0
		walk_max_x = spawn_pos.x + 80.0
	else:
		walk_min_x = min_x
		walk_max_x = max_x

# ── Walking AI ────────────────────────────────────────────────────────────────

func _start_walking_cycle() -> void:
	while is_instance_valid(self) and is_active:
		var strides_remaining = randi_range(3, 10)
		is_walking = true
		if animated_sprite:
			animated_sprite.play("Walking")

		for _stride in range(strides_remaining):
			await _walk_one_stride()

		is_walking = false
		if animated_sprite:
			animated_sprite.stop()
			animated_sprite.frame = 0
		elif sprite:
			sprite.frame = 0

		var pause_time = 1.0 if randf() > 0.5 else 0.3
		await get_tree().create_timer(pause_time).timeout

		if randf() > 0.5:
			walk_direction *= -1
			if animated_sprite:
				animated_sprite.flip_h = walk_direction < 0
			elif sprite:
				sprite.flip_h = walk_direction < 0

func _walk_one_stride() -> void:
	for _step in range(4):
		if not is_walking or not is_active:
			break
		var new_x = global_position.x + (walk_direction * walk_speed * 0.1)
		if new_x > walk_min_x and new_x < walk_max_x:
			velocity.x = walk_direction * walk_speed
		else:
			walk_direction *= -1
			if animated_sprite:
				animated_sprite.flip_h = walk_direction < 0
			elif sprite:
				sprite.flip_h = walk_direction < 0
		await get_tree().create_timer(0.1).timeout
	velocity.x = 0.0
