extends Control

func _ready():
	$VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	# Show Continue only if at least one save exists
	var any_save = SaveManager.has_save(1) or SaveManager.has_save(2) or SaveManager.has_save(3)
	$VBoxContainer/ContinueButton.visible = any_save

func _on_new_game_pressed() -> void:
	var slot_scene = load("res://source/scenes/ui/slot_select.tscn").instantiate()
	slot_scene.set_mode("new_game")
	get_tree().root.add_child(slot_scene)
	queue_free()

func _on_continue_pressed() -> void:
	var slot_scene = load("res://source/scenes/ui/slot_select.tscn").instantiate()
	slot_scene.set_mode("load_game")
	get_tree().root.add_child(slot_scene)
	queue_free()

func _on_quit_pressed() -> void:
	get_tree().quit()
