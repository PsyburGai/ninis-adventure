extends Control

var mode: String = "new_game"
var _buttons: Array = []
var _selected: int = 0

func _ready():
	mode = SceneTransition.menu_mode
	var title = "New Game" if mode == "new_game" else "Continue"
	$VBoxContainer/Title.text = title
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	for i in range(1, 4):
		$VBoxContainer.get_node("Slot" + str(i) + "Button").pressed.connect(_on_slot_pressed.bind(i))
		$VBoxContainer.get_node("Slot" + str(i) + "Delete").pressed.connect(_on_delete_pressed.bind(i))
	_refresh_slots()
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

	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _highlight(index: int) -> void:
	for i in _buttons.size():
		if i == index:
			_buttons[i].modulate = Color(1.4, 1.4, 0.3)
		else:
			_buttons[i].modulate = Color(1, 1, 1)

func set_mode(m: String) -> void:
	mode = m
	var title = "New Game" if mode == "new_game" else "Continue"
	$VBoxContainer/Title.text = title
	_refresh_slots()

func _refresh_slots() -> void:
	for i in range(1, 4):
		var slot_btn = $VBoxContainer.get_node_or_null("Slot" + str(i) + "Button")
		var delete_btn = $VBoxContainer.get_node_or_null("Slot" + str(i) + "Delete")
		if not slot_btn:
			continue
		var summary = SaveManager.get_slot_summary(i)
		if summary["empty"]:
			slot_btn.text = "Slot " + str(i) + " — Empty"
			if delete_btn:
				delete_btn.visible = false
		else:
			slot_btn.text = "Slot " + str(i) + " — " + summary["scene"] + "  [" + summary["timestamp"] + "]"
			if delete_btn:
				delete_btn.visible = true

func _on_slot_pressed(slot: int) -> void:
	if mode == "new_game":
		SaveManager.new_game(slot)
	else:
		if SaveManager.has_save(slot):
			SaveManager.load_game(slot)

func _on_delete_pressed(slot: int) -> void:
	SaveManager.delete_save(slot)
	_refresh_slots()
	_build_button_list()
	_selected = clamp(_selected, 0, _buttons.size() - 1)
	_highlight(_selected)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://source/scenes/levels/main_menu.tscn")
