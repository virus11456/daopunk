class_name Hud
extends Control
## Minimal heads-up display: day/clock (top-right) and the contextual
## interaction prompt (bottom-centre). Keeps >80% of the screen clear for the
## world, as the layout brief requires. HP / weapon widgets are stubbed as
## placeholders for the combat phase.

var _clock_label: Label
var _prompt_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	if is_instance_valid(GameState.player):
		_connect_player(GameState.player)
	else:
		GameState.player_registered.connect(_connect_player)


func _build_ui() -> void:
	_clock_label = Label.new()
	_clock_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_clock_label.offset_left = -180.0
	_clock_label.offset_top = 12.0
	_clock_label.offset_right = -16.0
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clock_label.add_theme_font_size_override("font_size", 18)
	_clock_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.85))
	add_child(_clock_label)

	_prompt_label = Label.new()
	_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_label.offset_left = -220.0
	_prompt_label.offset_right = 220.0
	_prompt_label.offset_top = -96.0
	_prompt_label.offset_bottom = -68.0
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 16)
	_prompt_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_prompt_label.add_theme_constant_override("outline_size", 4)
	_prompt_label.text = ""
	add_child(_prompt_label)


func _connect_player(player: Node) -> void:
	if player is Player:
		(player as Player).focus_changed.connect(_on_focus_changed)


func _process(_delta: float) -> void:
	_clock_label.text = "%s   %s" % [TimeManager.get_day_string(), TimeManager.get_clock_string()]


func _on_focus_changed(interactable: InteractableComponent) -> void:
	if is_instance_valid(interactable):
		_prompt_label.text = "[E] %s" % interactable.get_primary_prompt()
	else:
		_prompt_label.text = ""
