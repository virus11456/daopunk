class_name MenuPanel
extends Control
## Base for full-screen menu panels (inventory, character, shop).
##
## Handles show/hide, its own toggle key, mutual exclusion (only one menu open),
## Esc-to-close, and keeping GameState.in_menu accurate so the player controller
## suppresses world input. Subclasses implement `_build_content()` and `_refresh()`.

## Input action that toggles this panel. Empty = opened programmatically only.
@export var toggle_action: StringName = &""

var _open: bool = false
var _content_parent: VBoxContainer


func _ready() -> void:
	add_to_group(&"menu_panel")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_frame()
	_build_content()
	hide()


func _build_frame() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(560, 460)
	panel.offset_left = -280.0
	panel.offset_right = 280.0
	panel.offset_top = -230.0
	panel.offset_bottom = 230.0
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	_content_parent = VBoxContainer.new()
	_content_parent.add_theme_constant_override("separation", 8)
	margin.add_child(_content_parent)


## Subclasses add their widgets under `_content_parent`.
func _build_content() -> void:
	pass


## Subclasses repopulate their dynamic widgets from current state.
func _refresh() -> void:
	pass


func is_open() -> bool:
	return _open


func open() -> void:
	for panel in get_tree().get_nodes_in_group(&"menu_panel"):
		if panel != self and (panel as MenuPanel).is_open():
			(panel as MenuPanel).close()
	_open = true
	GameState.in_menu = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	_refresh()


func close() -> void:
	if not _open:
		return
	_open = false
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_menu_flag()


func toggle() -> void:
	if _open:
		close()
	else:
		open()


func _sync_menu_flag() -> void:
	for panel in get_tree().get_nodes_in_group(&"menu_panel"):
		if (panel as MenuPanel).is_open():
			GameState.in_menu = true
			return
	GameState.in_menu = false


func _unhandled_input(event: InputEvent) -> void:
	if toggle_action != &"" and event.is_action_pressed(toggle_action):
		toggle()
		get_viewport().set_input_as_handled()
	elif _open and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _make_header(title: String) -> void:
	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	_content_parent.add_child(label)
	_content_parent.add_child(HSeparator.new())
