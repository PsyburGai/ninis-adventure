extends Control

func _ready():
	$VBoxContainer/StartButton.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

	# Only show Continue if a save file exists
	$VBoxContainer/ContinueButton.visible = SaveManager.has_save()

func _on_new_game_pressed():
	SaveManager.new_game()

func _on_continue_pressed():
	SaveManager.load_game()

func _on_quit_pressed():
	get_tree().quit()
