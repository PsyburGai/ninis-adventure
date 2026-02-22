extends CharacterBody2D

## Nini - Player Controller
## Walk left/right + jump. Climb ladders/ropes. Enter portals with UP.
## Z key = overhead sword attack.

const SPEED = 240.0
const JUMP_VELOCITY = -200.0
const GRAVITY = 500.0
const CLIMB_SPEED = 80.0

# Attack config
const ATTACK_FRAMES = 8          # total frames in nini_attack spritesheet
const ATTACK_FPS    = 18         # playback speed
const HITBOX_START  = 3          # frame index when hitbox becomes active (0-based)
const HITBOX_END    = 6          # frame index when hitbox deactivates

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_sprite: Sprite2D = $Sword
@onready var sword_hitbox: Area2D = $Sword/SwordHitbox

var _on_ladder: bool = false
var _ladder_count: int = 0
var _attacking: bool = false
var _attack_frame: int = 0
var _attack_timer: float = 0.0

func _ready() -> void:
	add_to_group("player")
	sword_sprite.visible = false
	sword_hitbox.monitoring = false
	_apply_spawn()

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
	SaveManager.update_position(global_position)

	# ── Attack input ──────────────────────────────────────────
	if Input.is_action_just_pressed("attack") and not _attacking:
		_start_attack()

	if _attacking:
		_tick_attack(delta)

	# ── Ladder / movement (locked during attack) ──────────────
	var up = Input.is_action_pressed("move_up")
	var down = Input.is_action_pressed("move_down")

	if _on_ladder:
		# On ladder: disable gravity, allow vertical movement
		velocity.x = 0.0
		if up:
			velocity.y = -CLIMB_SPEED
			sprite.play("walk")
		elif down:
			velocity.y = CLIMB_SPEED
			sprite.play("walk")
		else:
			velocity.y = 0.0
			sprite.play("idle")

		# Allow jumping off ladder with spacebar
		if Input.is_action_just_pressed("jump"):
			_on_ladder = false
			velocity.y = JUMP_VELOCITY

		# Dismount at top when on floor
		if is_on_floor() and not down:
			pass  # stay mounted until moving down or leaving area
	else:
		# Normal movement
		if not is_on_floor():
			velocity.y += GRAVITY * delta

		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		var direction = Input.get_axis("move_left", "move_right")
		if direction != 0:
			velocity.x = direction * SPEED
			sprite.flip_h = direction < 0
			sprite.play("walk")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			sprite.play("idle")

		# Grab ladder when pressing up/down while overlapping one
		if _ladder_count > 0 and (up or down):
			_on_ladder = true

	move_and_slide()
	global_position.x = clamp(global_position.x, 0, 1280)

# ── Attack helpers ────────────────────────────────────────────────────────────

func _start_attack() -> void:
	_attacking = true
	_attack_frame = 0
	_attack_timer = 0.0
	sword_sprite.visible = true
	sword_hitbox.monitoring = false
	# Load the attack spritesheet into sprite (swap temporarily)
	var attack_tex = load("res://assets/sprites/nini_attack.png")
	sprite.sprite_frames.add_animation("attack") if not sprite.sprite_frames.has_animation("attack") else null
	# Position sword based on facing direction
	sword_sprite.flip_h = sprite.flip_h
	sword_sprite.position = Vector2(8 if not sprite.flip_h else -8, -12)

func _tick_attack(delta: float) -> void:
	_attack_timer += delta
	var frame_duration = 1.0 / ATTACK_FPS
	var new_frame = int(_attack_timer / frame_duration)

	if new_frame != _attack_frame:
		_attack_frame = new_frame
		_update_sword_rotation()

		# Toggle hitbox active window
		if _attack_frame >= HITBOX_START and _attack_frame <= HITBOX_END:
			sword_hitbox.monitoring = true
		else:
			sword_hitbox.monitoring = false

	# End attack after all frames complete
	if _attack_frame >= ATTACK_FRAMES:
		_end_attack()

func _update_sword_rotation() -> void:
	# Overhead slash arc: sword goes from raised-back (-110°) sweeping down to (40°)
	var t = float(_attack_frame) / float(ATTACK_FRAMES - 1)
	var angle_deg = lerp(-110.0, 40.0, t)
	if sprite.flip_h:
		angle_deg = -angle_deg
	sword_sprite.rotation_degrees = angle_deg
	# Also shift sword position along the arc
	var radius = 14.0
	sword_sprite.position = Vector2(
		cos(deg_to_rad(angle_deg)) * radius,
		sin(deg_to_rad(angle_deg)) * radius - 4.0
	)

func _end_attack() -> void:
	_attacking = false
	sword_sprite.visible = false
	sword_hitbox.monitoring = false
	_attack_frame = 0
	_attack_timer = 0.0

func enter_ladder() -> void:
	_ladder_count += 1

func exit_ladder() -> void:
	_ladder_count -= 1
	if _ladder_count <= 0:
		_ladder_count = 0
		_on_ladder = false
