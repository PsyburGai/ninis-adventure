extends HBoxContainer

## Skill cooldown bar — 4 slots at the bottom center of the screen.
## Reads cooldown timers directly from the Nini player node each frame.

const SKILLS = [
	{
		"icon": "res://assets/sprites/sword.png",
		"max_cooldown": 0.0,
		"cooldown_var": "",
		"key": "Z"
	},
	{
		"icon": "res://assets/sprites/objects/fork.png",
		"max_cooldown": 1.5,
		"cooldown_var": "_cast_cooldown_timer",
		"key": "X"
	},
	{
		"icon": "res://skills/big_bite/big_bite_skill.png",
		"max_cooldown": 2.0,
		"cooldown_var": "_bite_cooldown_timer",
		"key": "C"
	},
	{
		"icon": "",
		"max_cooldown": 0.0,
		"cooldown_var": "",
		"key": ""
	}
]

const SLOT_SIZE = 16
const ICON_ALPHA = 0.7
const OVERLAY_COLOR = Color(0.3, 0.3, 0.3, 0.55)

var _nini: CharacterBody2D = null
var _overlay_rects: Array = []

func _ready() -> void:
	# SkillBar -> HUD (CanvasLayer) -> Nini (CharacterBody2D)
	_nini = get_parent().get_parent()

	for i in range(SKILLS.size()):
		_create_slot(SKILLS[i])

func _create_slot(skill: Dictionary) -> void:
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot.clip_contents = true

	# Dark background
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.15, 0.6)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(bg)

	# Skill icon
	if skill["icon"] != "":
		var icon = TextureRect.new()
		icon.texture = load(skill["icon"])
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.modulate = Color(1, 1, 1, ICON_ALPHA)
		slot.add_child(icon)

	# Cooldown overlay — fills from top, shrinks downward as cooldown expires
	var overlay = ColorRect.new()
	overlay.color = OVERLAY_COLOR
	overlay.offset_left = 0
	overlay.offset_right = SLOT_SIZE
	overlay.offset_top = 0
	overlay.offset_bottom = SLOT_SIZE
	overlay.visible = false
	slot.add_child(overlay)
	_overlay_rects.append(overlay)

	# Key label
	if skill["key"] != "":
		var label = Label.new()
		label.text = skill["key"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.add_theme_font_size_override("font_size", 6)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
		slot.add_child(label)

	add_child(slot)

func _process(_delta: float) -> void:
	if not is_instance_valid(_nini):
		return

	for i in range(SKILLS.size()):
		var skill = SKILLS[i]
		var overlay = _overlay_rects[i]

		if skill["cooldown_var"] == "" or skill["max_cooldown"] <= 0.0:
			overlay.visible = false
			continue

		var remaining: float = _nini.get(skill["cooldown_var"])
		if remaining <= 0.0:
			overlay.visible = false
			continue

		var ratio = clampf(remaining / skill["max_cooldown"], 0.0, 1.0)
		overlay.visible = true
		overlay.offset_top = 0
		overlay.offset_bottom = ratio * SLOT_SIZE
