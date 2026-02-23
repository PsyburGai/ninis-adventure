extends Control

var _buttons: Array = []
var _selected: int = 0

func _ready():
	$VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

	var any_save = SaveManager.has_save(1) or SaveManager.has_save(2) or SaveManager.has_save(3)
	$VBoxContainer/ContinueButton.visible = any_save

	# Build list of visible buttons only
	_build_button_list()
	_highlight(_selected)

func _build_button_list() -> void:
	_buttons.clear()
	for child in $VBoxContainer.get_children():
		if child is Button and child.visible:
			_buttons.append(child)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		_selected = (_selected + 1) % _buttons.size()
		_highlight(_selected)

	elif event.is_action_pressed("ui_up"):
		_selected = (_selected - 1 + _buttons.size()) % _buttons.size()
		_highlight(_selected)

	elif event.is_action_pressed("ui_accept"):
		_buttons[_selected].emit_signal("pressed")

	# Backspace has no action on the root menu but is caught so it
	# doesn't bubble up and cause unintended behaviour
	elif event.is_action_pressed("ui_cancel"):
		pass

func _highlight(index: int) -> void:
	for i in _buttons.size():
		# Use modulate to show selection — swap for a cursor sprite later if desired
		if i == index:
			_buttons[i].modulate = Color(1.4, 1.4, 0.3)  # Yellow tint = selected
		else:
			_buttons[i].modulate = Color(1, 1, 1)

func _on_new_game_pressed() -> void:
	SceneTransition.menu_mode = "new_game"
	get_tree().change_scene_to_file("res://source/scenes/ui/slot_select.tscn")

func _on_continue_pressed() -> void:
	SceneTransition.menu_mode = "load_game"
	get_tree().change_scene_to_file("res://source/scenes/ui/slot_select.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
