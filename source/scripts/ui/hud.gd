extends CanvasLayer

## In-game HUD — shows Character stats (HP, MP, EXP) and enemy info.
## Attached to the HUD CanvasLayer scene. Reads from SaveManager every frame.

@onready var character_label: Label = $Panel/VBox/CharacterLabel
@onready var hp_bar: ProgressBar = $Panel/VBox/HPRow/HPBar
@onready var mp_bar: ProgressBar = $Panel/VBox/MPRow/MPBar
@onready var exp_bar: ProgressBar = $Panel/VBox/EXPRow/EXPBarContainer/EXPBar
@onready var exp_text: Label = $Panel/VBox/EXPRow/EXPBarContainer/EXPText

func _ready() -> void:
	_refresh()

func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	character_label.text = "Nini  Lv." + str(SaveManager.level)

	hp_bar.max_value = SaveManager.max_health
	hp_bar.value = SaveManager.health

	mp_bar.max_value = SaveManager.max_mp
	mp_bar.value = SaveManager.mp

	var xp_needed = SaveManager.xp_for_next_level()
	exp_bar.max_value = xp_needed
	exp_bar.value = SaveManager.xp
	exp_text.text = str(SaveManager.xp) + " / " + str(xp_needed)
