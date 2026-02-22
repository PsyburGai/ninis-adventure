extends Control

var mode: String = "new_game"

func _ready():
	mode = SceneTransition.menu_mode
	var title = "New Game" if mode == "new_game" else "Continue"
	$VBoxContainer/Title.text = title
	$VBoxContainer/BackButton.pressed.connect(_on_back_pressed)
	for i in range(1, 4):
		$VBoxContainer.get_node("Slot" + str(i) + "Button").pressed.connect(_on_slot_pressed.bind(i))
		$VBoxContainer.get_node("Slot" + str(i) + "Delete").pressed.connect(_on_delete_pressed.bind(i))
	_refresh_slots()

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

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://source/scenes/levels/main_menu.tscn")
