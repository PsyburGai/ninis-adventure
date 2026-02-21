extends Area2D
class_name EnemyEncounter

@export var enemy_name: String = "Cupcake"
@export var enemy_max_hp: int = 25
@export var enemy_attack: int = 6
@export var enemy_defense: int = 3
@export var enemy_speed: int = 5
@export var enemy_xp_reward: int = 15
@export var respawn_time: float = 10.0
@export var respawn_on_defeat: bool = false

# Walking animation settings
@export var can_walk: bool = false
@export var walk_speed: float = 20.0
var walk_min_x: float = -999999.0
var walk_max_x: float = 999999.0

var is_active: bool = true
var battle_result: String = ""

# Walking animation variables
var is_walking: bool = false
var walk_direction: int = 1  # 1 = right, -1 = left
var sprite: Sprite2D = null
var animated_sprite: AnimatedSprite2D = null

func _ready():
	body_entered.connect(_on_body_entered)

	# Find sprite child if it exists (prefer AnimatedSprite2D)
	for child in get_children():
		if child is AnimatedSprite2D:
			animated_sprite = child
			break
		elif child is Sprite2D:
			sprite = child

	if can_walk and (animated_sprite or sprite):
		_start_walking_cycle()

func _on_body_entered(body):
	if body is CharacterBody2D and is_active:
		is_active = false
		visible = false
		battle_result = ""

		var stats = EnemyStats.new()
		stats.enemy_name = enemy_name
		stats.max_hp = enemy_max_hp
		stats.current_hp = enemy_max_hp
		stats.attack = enemy_attack
		stats.defense = enemy_defense
		stats.speed = enemy_speed
		stats.xp_reward = enemy_xp_reward

		# Wait for battle to actually start and get the battle scene
		GameManager.start_battle(stats)

		# Connect to battle end signals
		if GameManager.current_battle_scene:
			GameManager.current_battle_scene.battle_manager.battle_won.connect(_on_battle_won)
			GameManager.current_battle_scene.battle_manager.battle_lost.connect(_on_battle_lost)
			GameManager.current_battle_scene.battle_manager.battle_fled.connect(_on_battle_fled)

func _on_battle_won(_xp):
	battle_result = "won"
	_handle_battle_end()

func _on_battle_lost():
	battle_result = "lost"
	_handle_battle_end()

func _on_battle_fled():
	battle_result = "fled"
	_handle_battle_end()

func _handle_battle_end():
	# Wait a moment for battle scene cleanup
	await get_tree().create_timer(0.2).timeout

	if battle_result == "won" and not respawn_on_defeat:
		# Permanently remove defeated enemy
		queue_free()
	elif battle_result == "fled" or battle_result == "lost":
		# Respawn after timer for fled/lost battles
		await get_tree().create_timer(respawn_time).timeout
		is_active = true
		visible = true

func _start_walking_cycle():
	while true:
		var strides_remaining = randi_range(3, 10)
		is_walking = true

		# Start walking animation
		if animated_sprite:
			animated_sprite.play("Walking")

		# Walk for the random number of strides
		for stride in range(strides_remaining):
			await _walk_one_stride()

		# Stop walking (idle)
		is_walking = false
		if animated_sprite:
			animated_sprite.stop()
			animated_sprite.frame = 0  # Idle frame
		elif sprite:
			sprite.frame = 0  # Idle frame

		# Random pause (50% chance of 1 second pause, otherwise 0.3 seconds)
		var pause_time = 1.0 if randf() > 0.5 else 0.3
		await get_tree().create_timer(pause_time).timeout

		# Change direction randomly
		if randf() > 0.5:
			walk_direction *= -1
			if animated_sprite:
				animated_sprite.flip_h = walk_direction < 0
			elif sprite:
				sprite.flip_h = walk_direction < 0

func _walk_one_stride():
	for step in range(4):
		if not is_walking:
			break
		var new_x = position.x + (walk_direction * walk_speed * 0.1)
		if new_x > walk_min_x and new_x < walk_max_x:
			position.x = new_x
		else:
			walk_direction *= -1
			if animated_sprite:
				animated_sprite.flip_h = walk_direction < 0
			elif sprite:
				sprite.flip_h = walk_direction < 0
		await get_tree().create_timer(0.1).timeout
