extends CharacterBody2D

## Nini - Player Controller
## Walk left/right + jump. Climb ladders/ropes. Enter portals with UP.

const SPEED = 240.0
const JUMP_VELOCITY = -150.0
const GRAVITY = 500.0
const CLIMB_SPEED = 80.0
const DROP_THROUGH_TIME = 0.2  # Seconds with floor collision disabled when dropping through
const DEBUG_DRAW = true  # Show collision shapes at runtime

# Attack config
const ATTACK_FRAMES = 8
const ATTACK_FPS = 20
const HITBOX_START = 2
const HITBOX_END = 6

# Sword hand-tracking — per-frame position at Nini's hand (pixel-measured from attack sheet).
# Positions are relative to the AnimatedSprite2D center (right-facing).
# Angles are the direction from body center to the hand (0°=right, -90°=up, +90°=down).
const SWORD_POS_R: Array[Vector2] = [
	Vector2(6, -3),   # Frame 0: sword raised high (wind-up)
	Vector2(12, 0),   # Frame 1: sword forward-up (swing start)
	Vector2(15, 5),   # Frame 2: sword fully extended (strike peak)
	Vector2(12, 11),  # Frame 3: sword past horizontal (impact)
	Vector2(8, 14),   # Frame 4: follow-through low
	Vector2(5, 12),   # Frame 5: recovery
	Vector2(2, 11),   # Frame 6: returning to side
	Vector2(2, 9),    # Frame 7: at rest (idle)
]
const SWORD_ANGLE_R: Array[float] = [-70.0, -45.0, -10.0, 25.0, 50.0, 40.0, 20.0, 78.0]
# Sword sprite points UP at 0°; +90° rotates the tip to point outward along the arm.
const SWORD_TIP_OFFSET = 90.0

# Cast config (Falling Forks — continuous rain)
const CAST_FRAMES = 6
const CAST_FPS = 15
const CAST_COOLDOWN = 1.5
const RAIN_DURATION = 1.5       # how long the fork rain lasts (seconds)
const RAIN_SPAWN_INTERVAL = 0.08 # seconds between each fork spawn
const RAIN_ZONE_WIDTH = 50.0    # horizontal width of the rain zone
const RAIN_ZONE_OFFSET = 35.0   # center of rain zone ahead of Nini
const RAIN_SPAWN_HEIGHT = -80.0  # spawn height above Nini

# Big Bite config
const BITE_DAMAGE_MULT = 1.8    # multiplier on attack power
const BITE_COOLDOWN = 2.0       # seconds between bites
const BITE_RANGE = 24.0         # radius to detect enemy hitbox during dash
const BITE_DASH_DIST = 64.0     # pixels to dash forward
const BITE_DASH_TIME = 0.4      # seconds for the dash
const BITE_CHOMP_TIME = 0.7     # seconds the chomp visual stays
const BITE_RETURN_TIME = 0.4    # seconds to snap back
const BITE_ICON_SCALE = 1.3     # scale of the chomp icon

const HUD_SCENE = preload("res://source/scenes/ui/hud.tscn")
const FORK_SCENE = preload("res://source/scenes/objects/fork.tscn")
const BITE_TEXTURE = preload("res://skills/big_bite/big_bite_skill.png")

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_sprite: Sprite2D = $Sword
@onready var sword_hitbox: Area2D = $Sword/SwordHitbox

var _on_ladder: bool = false
var _ladder_count: int = 0
var _attacking: bool = false
var _attack_frame: int = 0
var _attack_timer: float = 0.0
var _hit_this_swing: Array = []

var _casting: bool = false
var _cast_frame: int = 0
var _cast_timer: float = 0.0
var _cast_cooldown_timer: float = 0.0

# Fork rain state (persists after cast animation ends)
var _raining: bool = false
var _rain_timer: float = 0.0
var _rain_spawn_timer: float = 0.0
var _rain_origin_x: float = 0.0  # world X where rain was cast
var _rain_dir: float = 1.0       # +1 right, -1 left

# Big Bite state
var _biting: bool = false
var _bite_timer: float = 0.0
var _bite_cooldown_timer: float = 0.0
var _bite_sprite: Sprite2D = null
var _bite_hit_targets: Array = []
var _bite_phase: int = 0          # 0=dash forward, 1=chomp, 2=return
var _bite_origin: Vector2 = Vector2.ZERO
var _bite_target_x: float = 0.0
var _bite_dir: float = 1.0

# Drop-through state (for falling through platforms)
var _dropping_through: bool = false
var _drop_timer: float = 0.0

# Death state
var _dead: bool = false

func _ready() -> void:
	add_to_group("player")
	sword_sprite.visible = false
	sword_hitbox.monitoring = false

	# Handle both Area2D enemies (CakeMonster) and CharacterBody2D enemies (SconeMonster)
	sword_hitbox.area_entered.connect(_on_sword_hit_area)
	sword_hitbox.body_entered.connect(_on_sword_hit_body)

	# Spawn HUD (CanvasLayer — stays on screen regardless of camera)
	var hud = HUD_SCENE.instantiate()
	add_child(hud)

	_apply_spawn()

# ── Sword hit detection (driven from Nini so it works for any enemy type) ─────

func _on_sword_hit_area(area: Area2D) -> void:
	var target = _find_damageable(area)
	if target:
		_deal_sword_damage(target)

func _on_sword_hit_body(body: Node) -> void:
	var target = _find_damageable(body)
	if target:
		_deal_sword_damage(target)

func _find_damageable(node: Node) -> Node:
	var current = node
	while current and current != get_tree().root:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null

func _deal_sword_damage(target: Node) -> void:
	if target == self:
		return
	if target in _hit_this_swing:
		return
	_hit_this_swing.append(target)
	target.take_damage(get_attack_power(), self)

func _apply_spawn() -> void:
	var side = SceneTransition.next_spawn
	if side != "":
		SceneTransition.next_spawn = ""
		# Wait one frame for YATI portals to be fully instantiated
		await get_tree().process_frame
		# Find the portal on the arrival side and spawn next to it
		var portal_name = "portal_enter" if side == "left" else "portal_exit"
		var portal = _find_portal(portal_name)
		if portal:
			# Spawn Nini just inside the portal, offset so she's not inside the collision
			var offset_x = 16 if side == "left" else -16
			global_position = Vector2(portal.global_position.x + offset_x, portal.global_position.y + 36)
		else:
			# Fallback if portal not found
			global_position = Vector2(40, 384) if side == "left" else Vector2(1240, 384)
	else:
		global_position = SaveManager.position

func _find_portal(portal_name: String) -> Node:
	# Search entire scene tree for the portal by name
	return _search_node(get_tree().root, portal_name)

func _search_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result = _search_node(child, target_name)
		if result:
			return result
	return null

func _physics_process(delta: float) -> void:
	if _dead:
		return
	SaveManager.update_position(global_position)

	# ── Attack input ──────────────────────────────────────────
	if Input.is_action_just_pressed("attack") and not _attacking and not _casting:
		_start_attack()

	if _attacking:
		_tick_attack(delta)

	# ── Cast input (Falling Forks) ────────────────────────────
	if Input.is_action_just_pressed("cast") and not _attacking and not _casting and not _raining and _cast_cooldown_timer <= 0.0:
		_start_cast()

	if _casting:
		_tick_cast(delta)

	if _raining:
		_tick_rain(delta)

	if _cast_cooldown_timer > 0.0:
		_cast_cooldown_timer -= delta

	# ── Big Bite input ────────────────────────────────────────
	if Input.is_action_just_pressed("big_bite") and not _attacking and not _casting and not _biting and _bite_cooldown_timer <= 0.0:
		_start_big_bite()

	if _biting:
		_tick_big_bite(delta)

	if _bite_cooldown_timer > 0.0:
		_bite_cooldown_timer -= delta

	# ── Drop-through timer ────────────────────────────────────
	if _dropping_through:
		_drop_timer -= delta
		if _drop_timer <= 0.0:
			_dropping_through = false
			_drop_timer = 0.0
			# Re-enable floor collision (unless currently on a ladder)
			if _ladder_count <= 0:
				set_collision_mask_value(1, true)

	# ── Ladder / movement (locked during attack) ──────────────
	var up = Input.is_action_pressed("move_up")
	var down = Input.is_action_pressed("move_down")

	if _on_ladder:
		# Floor collision OFF while on ladder — lets Nini climb through platforms
		set_collision_mask_value(1, false)

		# On ladder: disable gravity, allow vertical movement
		velocity.x = 0.0
		sprite.flip_h = false  # Back view is not flipped
		if up:
			velocity.y = -CLIMB_SPEED
			if not _attacking and not _casting:
				sprite.play("climb")
		elif down:
			velocity.y = CLIMB_SPEED
			if not _attacking and not _casting:
				sprite.play("climb")
		else:
			velocity.y = 0.0
			if not _attacking and not _casting:
				sprite.stop()

		# Jump off ladder (SPACE without DOWN) or drop through (DOWN + SPACE)
		if Input.is_action_just_pressed("jump"):
			if down:
				# Drop through platform below while on ladder
				_on_ladder = false
				_dropping_through = true
				_drop_timer = DROP_THROUGH_TIME
				velocity.y = CLIMB_SPEED  # Small downward push
			else:
				# Normal jump off ladder
				_on_ladder = false
				velocity.y = JUMP_VELOCITY
	else:
		# Floor collision ON when not on ladder (unless dropping through a platform)
		if not _dropping_through:
			set_collision_mask_value(1, true)

		# Normal movement
		if not is_on_floor():
			velocity.y += GRAVITY * delta

		if Input.is_action_just_pressed("jump") and is_on_floor():
			if down:
				# Drop through platform: disable floor collision briefly
				_dropping_through = true
				_drop_timer = DROP_THROUGH_TIME
				set_collision_mask_value(1, false)
				velocity.y = 10.0  # Small downward nudge to start falling
			else:
				velocity.y = JUMP_VELOCITY

		var direction = Input.get_axis("move_left", "move_right")
		if direction != 0:
			velocity.x = direction * SPEED
			sprite.flip_h = direction < 0
			if not _attacking and not _casting:
				if not is_on_floor():
					sprite.play("jump")
				else:
					sprite.play("walk")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			if not _attacking and not _casting:
				if not is_on_floor():
					sprite.play("jump")
				else:
					sprite.play("idle")

		# Grab ladder: holding UP or DOWN while overlapping a ladder
		if _ladder_count > 0 and (up or down):
			_on_ladder = true

	move_and_slide()
	global_position.x = clamp(global_position.x, 0, 1280)

	if DEBUG_DRAW:
		queue_redraw()

# ── Debug draw ───────────────────────────────────────────────────────────────

func _draw() -> void:
	if not DEBUG_DRAW:
		return

	# Determine if floor collision is active (layer-1 mask bit)
	var floor_active: bool = get_collision_mask_value(1)
	var body_color = Color(0, 1, 0, 0.3) if floor_active else Color(1, 0, 0, 0.3)
	var outline_color = Color(0, 1, 0, 0.8) if floor_active else Color(1, 0, 0, 0.8)

	# ── Draw character capsule collision shape ────────────────
	var col_shape = $CollisionShape2D
	if col_shape and col_shape.shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = col_shape.shape
		var r: float = capsule.radius
		var h: float = capsule.height
		var half_straight: float = (h - 2.0 * r) / 2.0  # half the straight section
		var pos: Vector2 = col_shape.position

		# Draw the straight rectangle section
		var rect = Rect2(pos.x - r, pos.y - half_straight, r * 2.0, half_straight * 2.0)
		draw_rect(rect, body_color, true)
		draw_rect(rect, outline_color, false)

		# Draw top semicircle (arc approximation with polygon)
		var top_center = Vector2(pos.x, pos.y - half_straight)
		_draw_semicircle(top_center, r, true, body_color, outline_color)

		# Draw bottom semicircle
		var bot_center = Vector2(pos.x, pos.y + half_straight)
		_draw_semicircle(bot_center, r, false, body_color, outline_color)

	# ── Draw floor detection line at the very bottom ──────────
	if col_shape and col_shape.shape is CapsuleShape2D:
		var capsule: CapsuleShape2D = col_shape.shape
		var foot_y: float = col_shape.position.y + capsule.height / 2.0
		var foot_color = Color(1, 1, 0, 0.9) if is_on_floor() else Color(1, 1, 0, 0.3)
		# Bright yellow line at feet — solid when grounded, faded when airborne
		draw_line(
			Vector2(-capsule.radius - 2, foot_y + 1),
			Vector2(capsule.radius + 2, foot_y + 1),
			foot_color, 1.0
		)
		# Small label indicator
		if is_on_floor():
			draw_line(
				Vector2(-capsule.radius - 4, foot_y + 1),
				Vector2(-capsule.radius - 4, foot_y - 3),
				foot_color, 1.0
			)
			draw_line(
				Vector2(capsule.radius + 4, foot_y + 1),
				Vector2(capsule.radius + 4, foot_y - 3),
				foot_color, 1.0
			)

func _draw_semicircle(center: Vector2, radius: float, top: bool, fill_color: Color, line_color: Color) -> void:
	var segments: int = 12
	var points: PackedVector2Array = PackedVector2Array()
	var start_angle: float = PI if top else 0.0
	var end_angle: float = TAU if top else PI
	for i in range(segments + 1):
		var angle = start_angle + (end_angle - start_angle) * float(i) / float(segments)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	# Fill
	if points.size() >= 3:
		var fill_pts = PackedVector2Array()
		fill_pts.append(center)
		fill_pts.append_array(points)
		draw_colored_polygon(fill_pts, fill_color)
	# Outline arc
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], line_color, 1.0)

# ── Attack helpers ────────────────────────────────────────────────────────────

func _start_attack() -> void:
	_attacking = true
	_attack_frame = 0
	_attack_timer = 0.0
	_hit_this_swing.clear()
	sword_sprite.visible = true
	sword_hitbox.monitoring = false
	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
	_update_sword_rotation()

func _tick_attack(delta: float) -> void:
	_attack_timer += delta
	var frame_duration = 1.0 / ATTACK_FPS
	var new_frame = int(_attack_timer / frame_duration)

	if new_frame != _attack_frame:
		_attack_frame = new_frame
		_update_sword_rotation()

		if _attack_frame >= HITBOX_START and _attack_frame <= HITBOX_END:
			sword_hitbox.monitoring = true
		else:
			sword_hitbox.monitoring = false

	if _attack_frame >= ATTACK_FRAMES:
		_end_attack()

func _update_sword_rotation() -> void:
	var facing_left: bool = sprite.flip_h
	var fi: int = clamp(_attack_frame, 0, ATTACK_FRAMES - 1)

	var pos: Vector2 = SWORD_POS_R[fi]
	var angle_deg: float = SWORD_ANGLE_R[fi]

	if facing_left:
		pos.x = -pos.x
		angle_deg = 180.0 - angle_deg

	sword_sprite.position = pos
	sword_sprite.rotation_degrees = angle_deg + SWORD_TIP_OFFSET
	sword_sprite.flip_h = false

func _end_attack() -> void:
	_attacking = false
	sword_sprite.visible = false
	sword_hitbox.monitoring = false
	_attack_frame = 0
	_attack_timer = 0.0
	sprite.play("idle")

# ── Cast helpers (Falling Forks — continuous rain) ───────────────────────────

func _start_cast() -> void:
	_casting = true
	_cast_frame = 0
	_cast_timer = 0.0
	# Lock rain origin and direction at cast time
	_rain_dir = -1.0 if sprite.flip_h else 1.0
	_rain_origin_x = global_position.x
	if sprite.sprite_frames.has_animation("cast"):
		sprite.play("cast")

func _tick_cast(delta: float) -> void:
	_cast_timer += delta
	var frame_duration = 1.0 / CAST_FPS
	var new_frame = int(_cast_timer / frame_duration)

	if new_frame != _cast_frame:
		_cast_frame = new_frame

	# Start the rain at frame 3 (mid-cast)
	if _cast_frame >= 3 and not _raining:
		_raining = true
		_rain_timer = 0.0
		_rain_spawn_timer = 0.0

	# End cast animation after all frames complete
	if _cast_frame >= CAST_FRAMES:
		_casting = false
		_cast_frame = 0
		_cast_timer = 0.0
		if not _raining:
			sprite.play("idle")

func _tick_rain(delta: float) -> void:
	_rain_timer += delta
	_rain_spawn_timer += delta

	# Spawn a fork each interval
	while _rain_spawn_timer >= RAIN_SPAWN_INTERVAL:
		_rain_spawn_timer -= RAIN_SPAWN_INTERVAL
		_spawn_one_fork()

	# End rain after duration
	if _rain_timer >= RAIN_DURATION:
		_raining = false
		_rain_timer = 0.0
		_rain_spawn_timer = 0.0
		_cast_cooldown_timer = CAST_COOLDOWN
		if not _casting:
			sprite.play("idle")

func _spawn_one_fork() -> void:
	var fork = FORK_SCENE.instantiate()
	# Random X within the rain zone, offset in facing direction
	var zone_center_x = _rain_origin_x + RAIN_ZONE_OFFSET * _rain_dir
	var rand_offset = (randf() - 0.5) * RAIN_ZONE_WIDTH
	fork.global_position = Vector2(
		zone_center_x + rand_offset,
		global_position.y + RAIN_SPAWN_HEIGHT
	)
	fork.set_drift(_rain_dir)
	get_parent().add_child(fork)

# ── Big Bite helpers (dash → chomp → return) ────────────────────────────────

func _start_big_bite() -> void:
	_biting = true
	_bite_timer = 0.0
	_bite_phase = 0  # start with dash forward
	_bite_hit_targets.clear()
	_bite_dir = -1.0 if sprite.flip_h else 1.0
	_bite_origin = global_position
	_bite_target_x = global_position.x + BITE_DASH_DIST * _bite_dir
	# Clamp target within level bounds
	_bite_target_x = clampf(_bite_target_x, 0, 1280)
	velocity = Vector2.ZERO
	# Play walk animation sped up for the dash
	sprite.flip_h = _bite_dir < 0
	sprite.play("walk")
	sprite.speed_scale = 1.6

func _tick_big_bite(delta: float) -> void:
	_bite_timer += delta

	match _bite_phase:
		0:  # ── Phase 0: Dash forward ────────────
			var progress = clampf(_bite_timer / BITE_DASH_TIME, 0.0, 1.0)
			global_position.x = lerpf(_bite_origin.x, _bite_target_x, progress)

			# Check for enemy collision continuously during dash
			_bite_scan_enemies()

			if progress >= 1.0:
				_bite_timer = 0.0
				_bite_phase = 1
				# Deal damage to anything we hit
				_bite_deal_damage()
				# Spawn chomp visual at current position
				_spawn_chomp_visual()

		1:  # ── Phase 1: Chomp effect ────────────
			if _bite_sprite and is_instance_valid(_bite_sprite):
				var progress = clampf(_bite_timer / BITE_CHOMP_TIME, 0.0, 1.0)
				# Jaws slam shut: scale.y shrinks, then fade out
				if progress < 0.4:
					_bite_sprite.scale.y = lerpf(BITE_ICON_SCALE, BITE_ICON_SCALE * 0.2, progress / 0.4)
				elif progress < 0.6:
					_bite_sprite.scale.y = BITE_ICON_SCALE * 0.2
				else:
					_bite_sprite.modulate.a = lerpf(1.0, 0.0, (progress - 0.6) / 0.4)

			if _bite_timer >= BITE_CHOMP_TIME:
				# Clean up chomp visual
				if _bite_sprite and is_instance_valid(_bite_sprite):
					_bite_sprite.queue_free()
					_bite_sprite = null
				_bite_timer = 0.0
				_bite_phase = 2
				# Walk back with sped-up animation, flip to face return direction
				sprite.flip_h = _bite_dir > 0
				sprite.play("walk")
				sprite.speed_scale = 1.6

		2:  # ── Phase 2: Dash back to origin ─────
			var progress = clampf(_bite_timer / BITE_RETURN_TIME, 0.0, 1.0)
			global_position.x = lerpf(_bite_target_x, _bite_origin.x, progress)

			if progress >= 1.0:
				global_position = _bite_origin
				_end_big_bite()

func _bite_scan_enemies() -> void:
	## Check for enemies along the dash path — stop dash early on first hit
	var damage = int(SaveManager.get_attack_power() * BITE_DAMAGE_MULT)
	for node in get_tree().get_nodes_in_group("enemies"):
		if not node.has_method("take_damage"):
			continue
		if node in _bite_hit_targets:
			continue
		var dist = global_position.distance_to(node.global_position)
		if dist <= BITE_RANGE:
			_bite_hit_targets.append(node)
			node.take_damage(damage, self)
			# Snap to enemy position for the chomp
			_bite_target_x = node.global_position.x
			global_position.x = _bite_target_x
			sprite.visible = true
			_bite_timer = 0.0
			_bite_phase = 1
			_spawn_chomp_visual()
			return  # stop scanning, we hit something

func _bite_deal_damage() -> void:
	## Final damage check at end of dash (if nothing was hit during travel)
	var damage = int(SaveManager.get_attack_power() * BITE_DAMAGE_MULT)
	for node in get_tree().get_nodes_in_group("enemies"):
		if not node.has_method("take_damage"):
			continue
		if node in _bite_hit_targets:
			continue
		var dist = global_position.distance_to(node.global_position)
		if dist <= BITE_RANGE:
			_bite_hit_targets.append(node)
			node.take_damage(damage, self)

func _spawn_chomp_visual() -> void:
	if _bite_sprite and is_instance_valid(_bite_sprite):
		_bite_sprite.queue_free()
	_bite_sprite = Sprite2D.new()
	_bite_sprite.texture = BITE_TEXTURE
	_bite_sprite.z_index = 10
	# Position the chomp sprite out in front of Nini (in her facing direction)
	_bite_sprite.position = Vector2(28 * _bite_dir, -10)
	_bite_sprite.scale = Vector2(BITE_ICON_SCALE, BITE_ICON_SCALE)
	add_child(_bite_sprite)
	# Play attack anim for the chomp
	if sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")

func _end_big_bite() -> void:
	_biting = false
	_bite_timer = 0.0
	_bite_phase = 0
	_bite_cooldown_timer = BITE_COOLDOWN
	if _bite_sprite and is_instance_valid(_bite_sprite):
		_bite_sprite.queue_free()
		_bite_sprite = null
	sprite.visible = true
	sprite.speed_scale = 1.0
	sprite.flip_h = _bite_dir < 0  # restore original facing direction
	sprite.play("idle")

func enter_ladder() -> void:
	_ladder_count += 1

func exit_ladder() -> void:
	_ladder_count -= 1
	if _ladder_count <= 0:
		_ladder_count = 0
		_on_ladder = false
		# Collision will be re-enabled next frame by _physics_process()

# ── Combat interface (called by enemies) ──────────────────────────────────────

## Returns Nini's attack power for sword hits (scales with level).
func get_attack_power() -> int:
	return SaveManager.get_attack_power()

## Called by enemies when they deal contact damage to Nini.
## knockback_vec is a world-space impulse applied to velocity.
func take_damage(amount: int, knockback_vec: Vector2 = Vector2.ZERO) -> void:
	if _dead or _biting:
		return
	SaveManager.health = max(0, SaveManager.health - amount)
	velocity += knockback_vec
	_flash_damage()
	if SaveManager.health <= 0:
		_die()

## Called when an enemy dies; grant XP to Nini.
func gain_xp(amount: int) -> void:
	SaveManager.xp += amount
	if SaveManager.try_level_up():
		_flash_level_up()

# ── Death ────────────────────────────────────────────────────────────────────

func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	sword_sprite.visible = false
	sword_hitbox.monitoring = false
	# Disable collision so enemies stop interacting
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	# Death effect: flash red, shrink, then go to main menu
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.2, 0.2, 1), 0.15)
	tween.tween_property(self, "scale", Vector2(1.2, 0.3), 0.12)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_return_to_menu)

func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://source/scenes/levels/main_menu.tscn")

# ── Visual effects ───────────────────────────────────────────────────────────

func _flash_damage() -> void:
	for _i in range(3):
		$AnimatedSprite2D.modulate = Color(1, 0.3, 0.3, 0.5)
		await get_tree().create_timer(0.08).timeout
		$AnimatedSprite2D.modulate = Color.WHITE
		await get_tree().create_timer(0.08).timeout

func _flash_level_up() -> void:
	for _i in range(4):
		$AnimatedSprite2D.modulate = Color(1, 1, 0.4, 1)
		await get_tree().create_timer(0.1).timeout
		$AnimatedSprite2D.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
