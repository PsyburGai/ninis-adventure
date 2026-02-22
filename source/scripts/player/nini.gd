extends CharacterBody2D

## Nini - Player Controller
## Walk left/right + jump. Climb ladders/ropes. Enter portals with UP.

const SPEED = 240.0
const JUMP_VELOCITY = -200.0
const GRAVITY = 500.0
const CLIMB_SPEED = 80.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _on_ladder: bool = false
var _ladder_count: int = 0  # track overlapping ladders

func _ready() -> void:
	add_to_group("player")
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

func enter_ladder() -> void:
	_ladder_count += 1

func exit_ladder() -> void:
	_ladder_count -= 1
	if _ladder_count <= 0:
		_ladder_count = 0
		_on_ladder = false
