extends Area2D
class_name BossEncounter

# Boss stats - much stronger than regular enemies
@export var boss_name: String = "Cake Monster"
@export var boss_max_hp: int = 100
@export var boss_attack: int = 12
@export var boss_defense: int = 8
@export var boss_speed: int = 6
@export var boss_xp_reward: int = 100

# Boss features
@export var boss_music: AudioStream = null  # Optional boss music
@export var is_defeated: bool = false  # Track if boss was defeated

var is_active: bool = true
var battle_result: String = ""

# Walking animation variables
var is_walking: bool = false
var walk_direction: int = 1  # 1 = right, -1 = left
var strides_remaining: int = 0
var current_frame: int = 0
var walk_speed: float = 20.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	body_entered.connect(_on_body_entered)
	# Check if boss already defeated - if so, remove it
	if is_defeated:
		queue_free()
		return

	print("Boss spawned at position: ", position)

	# Start walking animation (call without await so it runs in background)
	_start_walking_cycle()

func _start_walking_cycle():
	print("Boss walking cycle started!")
	while not is_defeated:
		# Random number of strides (3-10)
		strides_remaining = randi_range(3, 10)
		is_walking = true
		print("Boss starting to walk: %d strides" % strides_remaining)

		# Walk for the random number of strides
		for stride in range(strides_remaining):
			await _walk_one_stride()

		# Stop walking (idle)
		is_walking = false
		sprite.frame = 0  # Idle frame
		print("Boss stopped walking, pausing...")

		# Random pause (50% chance of 1 second pause, otherwise 0.3 seconds)
		var pause_time = 1.0 if randf() > 0.5 else 0.3
		await get_tree().create_timer(pause_time).timeout

		# Change direction randomly
		if randf() > 0.5:
			walk_direction *= -1
			sprite.flip_h = walk_direction < 0
			print("Boss changed direction to: ", "left" if walk_direction < 0 else "right")

func _walk_one_stride():
	# Animate through walk frames (frames 1-4)
	for frame in [1, 2, 3, 4]:
		if not is_walking:
			break
		sprite.frame = frame
		# Move position slightly
		var old_x = position.x
		position.x += walk_direction * walk_speed * 0.1
		print("Boss frame: %d, moved from %.1f to %.1f" % [frame, old_x, position.x])
		await get_tree().create_timer(0.1).timeout

func _on_body_entered(body):
	if body is CharacterBody2D and is_active and not is_defeated:
		is_active = false
		visible = false
		battle_result = ""

		var stats = EnemyStats.new()
		stats.enemy_name = boss_name
		stats.max_hp = boss_max_hp
		stats.current_hp = boss_max_hp
		stats.attack = boss_attack
		stats.defense = boss_defense
		stats.speed = boss_speed
		stats.xp_reward = boss_xp_reward

		# Add boss-specific attack patterns
		stats.attacks = [
			{"name": "Frosting Slam", "power": 1.2, "description": "A heavy attack!"},
			{"name": "Sugar Rush", "power": 0.8, "description": "Quick strike!"},
			{"name": "Candy Crush", "power": 1.5, "description": "Devastating blow!"},
		]

		# Start battle
		GameManager.start_battle(stats)

		# Connect to battle end signals
		if GameManager.current_battle_scene:
			GameManager.current_battle_scene.battle_manager.battle_won.connect(_on_battle_won)
			GameManager.current_battle_scene.battle_manager.battle_lost.connect(_on_battle_lost)
			GameManager.current_battle_scene.battle_manager.battle_fled.connect(_on_battle_fled)

func _on_battle_won(_xp):
	battle_result = "won"
	is_defeated = true
	_handle_battle_end()

func _on_battle_lost():
	battle_result = "lost"
	_handle_battle_end()

func _on_battle_fled():
	battle_result = "fled"
	_handle_battle_end()

func _handle_battle_end():
	await get_tree().create_timer(0.2).timeout

	if battle_result == "won":
		# Boss defeated - remove permanently
		print("Boss defeated! %s will not respawn." % boss_name)
		# TODO: Save defeat state to save file
		queue_free()
	elif battle_result == "fled":
		# Boss respawns if player fled
		await get_tree().create_timer(3.0).timeout
		is_active = true
		visible = true
	elif battle_result == "lost":
		# Boss respawns if player lost
		await get_tree().create_timer(5.0).timeout
		is_active = true
		visible = true
