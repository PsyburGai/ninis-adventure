extends CharacterBody2D

## Nini - Player Controller
## Walk left/right + jump, spawns on correct side via SceneTransition.next_spawn

const SPEED = 80.0
const JUMP_VELOCITY = -200.0
const GRAVITY = 500.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var spawn_left: Marker2D = get_parent().get_node_or_null("SpawnLeft")
@onready var spawn_right: Marker2D = get_parent().get_node_or_null("SpawnRight")

func _ready() -> void:
	add_to_group("player")
	_apply_spawn()

func _apply_spawn() -> void:
	var side = SceneTransition.next_spawn
	if side == "right" and spawn_right:
		global_position = spawn_right.global_position
	elif spawn_left:
		global_position = spawn_left.global_position

func _physics_process(delta: float) -> void:
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
