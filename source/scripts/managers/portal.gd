class_name portal
extends Area2D

## portal - teleports Nini to the target scene when player presses UP.
## Class "portal" (lowercase) matches Tiled object class.
## Object name "portal_r" = right side exit, "portal_l" = left side exit.
## Required Tiled properties: target_scene
## Optional Tiled properties: target_spawn, is_end_portal

@export var target_scene: String = ""
@export var target_spawn: String = ""
@export var is_end_portal: bool = false

var player_inside: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false

func _process(_delta: float) -> void:
	if not player_inside:
		return
	if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("move_up"):
		_enter_portal()

func _enter_portal() -> void:
	if target_scene == "":
		push_warning(name + " has no target_scene set!")
		return

	# Infer spawn side from portal name if target_spawn not set
	if target_spawn == "":
		if name == "portal_r":
			target_spawn = "left"
		elif name == "portal_l":
			target_spawn = "right"

	SceneTransition.next_spawn = target_spawn
	SaveManager.update_scene(target_scene)

	if is_end_portal:
		get_tree().change_scene_to_file("res://source/scenes/levels/main_menu.tscn")
	else:
		get_tree().change_scene_to_file(target_scene)
