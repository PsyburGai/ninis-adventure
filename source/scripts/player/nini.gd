extends CharacterBody2D

## Nini - Player Controller
## Walk left/right + jump. Position loaded from SaveManager on scene start.

const SPEED = 80.0
const JUMP_VELOCITY = -200.0
const GRAVITY = 500.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	_apply_spawn()

func _apply_spawn() -> void:
	# If coming from a portal, use SceneTransition side
	# Otherwise use SaveManager position (new game or continue)
	var side = SceneTransition.next_spawn
	if side != "":
		# Coming through a portal - use left/right side of map
		if side == "right":
			global_position = Vector2(2480, SaveManager.position.y)
		else:
			global_position = Vector2(16, SaveManager.position.y)
		# Clear so next load uses SaveManager
		SceneTransition.next_spawn = ""
	else:
		# New game or Continue - use saved position
		global_position = SaveManager.position

func _physics_process(delta: float) -> void:
	# Save position periodically
	SaveManager.update_position(global_position)

	# Apply gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Horizontal movement
	var direction = Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
		sprite.play("walk")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		sprite.play("walk")

	move_and_slide()
