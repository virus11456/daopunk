class_name Hud
extends Control
## Minimal heads-up display: day/clock (top-right), the contextual interaction
## prompt (bottom-centre), and lightweight status (credits + stamina bottom-left,
## equipped weapon bottom-right). Keeps >80% of the screen clear for the world.

var _clock_label: Label
var _prompt_label: Label
var _status_label: Label
var _weapon_label: Label
var _stamina_bar: ProgressBar


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	if is_instance_valid(GameState.player):
		_connect_player(GameState.player)
	else:
		GameState.player_registered.connect(_connect_player)


func _build_ui() -> void:
	_clock_label = _make_label(Control.PRESET_TOP_RIGHT, HORIZONTAL_ALIGNMENT_RIGHT, 18)
	_clock_label.offset_left = -200.0
	_clock_label.offset_top = 12.0
	_clock_label.offset_right = -16.0

	_prompt_label = _make_label(Control.PRESET_CENTER_BOTTOM, HORIZONTAL_ALIGNMENT_CENTER, 16)
	_prompt_label.offset_left = -220.0
	_prompt_label.offset_right = 220.0
	_prompt_label.offset_top = -100.0
	_prompt_label.offset_bottom = -72.0
	_prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_prompt_label.add_theme_constant_override("outline_size", 4)

	_status_label = _make_label(Control.PRESET_BOTTOM_LEFT, HORIZONTAL_ALIGNMENT_LEFT, 15)
	_status_label.offset_left = 16.0
	_status_label.offset_top = -52.0
	_status_label.offset_right = 260.0
	_status_label.offset_bottom = -32.0

	_stamina_bar = ProgressBar.new()
	_stamina_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stamina_bar.offset_left = 16.0
	_stamina_bar.offset_top = -28.0
	_stamina_bar.offset_right = 160.0
	_stamina_bar.offset_bottom = -16.0
	_stamina_bar.min_value = 0.0
	_stamina_bar.max_value = 100.0
	_stamina_bar.value = 100.0
	_stamina_bar.show_percentage = false
	add_child(_stamina_bar)

	_weapon_label = _make_label(Control.PRESET_BOTTOM_RIGHT, HORIZONTAL_ALIGNMENT_RIGHT, 15)
	_weapon_label.offset_left = -280.0
	_weapon_label.offset_top = -40.0
	_weapon_label.offset_right = -16.0
	_weapon_label.offset_bottom = -16.0


func _make_label(preset: int, align: int, font_size: int) -> Label:
	var label := Label.new()
	label.set_anchors_preset(preset)
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.92, 0.93, 0.88))
	add_child(label)
	return label


func _connect_player(player: Node) -> void:
	if not (player is Player):
		return
	var p := player as Player
	p.focus_changed.connect(_on_focus_changed)
	p.stamina_changed.connect(_on_stamina_changed)
	p.get_wallet().money_changed.connect(_on_money_changed)
	p.get_equipment().equipment_changed.connect(_on_equipment_changed)
	_on_money_changed(p.get_wallet().get_money())
	_on_equipment_changed()
	_on_stamina_changed(p.get_stamina_ratio())


func _process(_delta: float) -> void:
	_clock_label.text = "%s   %s" % [TimeManager.get_day_string(), TimeManager.get_clock_string()]


func _on_focus_changed(interactable: InteractableComponent) -> void:
	if is_instance_valid(interactable):
		_prompt_label.text = "[E] %s" % interactable.get_primary_prompt()
	else:
		_prompt_label.text = ""


func _on_money_changed(amount: int) -> void:
	_status_label.text = "Credits: %d" % amount


func _on_stamina_changed(ratio: float) -> void:
	_stamina_bar.value = ratio * 100.0


func _on_equipment_changed() -> void:
	var player := GameState.player as Player
	if player == null:
		return
	var weapon := player.get_equipment().get_weapon()
	_weapon_label.text = "Weapon: %s" % (weapon.display_name if weapon != null else "Unarmed")
