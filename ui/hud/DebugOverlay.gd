class_name DebugOverlay
extends Control
## F1-toggled diagnostics panel.
##
## Shows engine + world state and a per-NPC AI readout. Left-clicking near an
## NPC (while the overlay is visible) selects it for a detailed block. This is
## the primary tool for debugging the AI/schedule work in later phases, so it is
## in from the start.

const SELECT_RADIUS := 24.0

var _label: Label
var _selected: Npc = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.offset_left = 8.0
	panel.offset_top = 8.0
	panel.modulate = Color(1, 1, 1, 0.92)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(0.7, 1.0, 0.7))
	margin.add_child(_label)

	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_debug"):
		visible = not visible
		get_viewport().set_input_as_handled()
		return
	if visible and event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_try_select_npc()


func _try_select_npc() -> void:
	if not is_instance_valid(GameState.player):
		return
	var mouse_world: Vector2 = (GameState.player as Node2D).get_global_mouse_position()
	var best: Npc = null
	var best_dist := SELECT_RADIUS
	for npc in get_tree().get_nodes_in_group(&"npc"):
		if npc is Npc:
			var d := (npc as Npc).global_position.distance_to(mouse_world)
			if d < best_dist:
				best_dist = d
				best = npc
	_selected = best


func _process(_delta: float) -> void:
	if not visible:
		return
	_label.text = _build_report()


func _build_report() -> String:
	var npcs := get_tree().get_nodes_in_group(&"npc")
	var lines: PackedStringArray = []
	lines.append("DEBUG (F1)   FPS %d" % Engine.get_frames_per_second())
	lines.append("Time: %s %s" % [TimeManager.get_day_string(), TimeManager.get_clock_string()])
	lines.append("Region: %s" % GameState.current_region)

	var ppos := GameState.get_player_position()
	lines.append("Player: (%d, %d)" % [ppos.x, ppos.y])
	if is_instance_valid(GameState.player) and GameState.player is Player:
		var p := GameState.player as Player
		var mode := "walk"
		if p.is_sneaking():
			mode = "sneak"
		elif p.is_running():
			mode = "run"
		lines.append("Move mode: %s" % mode)

	lines.append("NPC count: %d" % npcs.size())
	lines.append("--- NPCs ---")
	for npc in npcs:
		if npc is Npc:
			var n := npc as Npc
			var marker := ">" if n == _selected else " "
			lines.append("%s %-10s %-7s -> (%d,%d)" % [
				marker, n.display_name, n.get_state_name(),
				n.get_destination().x, n.get_destination().y])

	if is_instance_valid(_selected):
		lines.append("--- Selected ---")
		lines.append("Name: %s" % _selected.display_name)
		lines.append("State: %s" % _selected.get_state_name())
		lines.append("Pos: (%d, %d)" % [_selected.global_position.x, _selected.global_position.y])
		lines.append("Dest: (%d, %d)" % [_selected.get_destination().x, _selected.get_destination().y])
	else:
		lines.append("(left-click an NPC to inspect)")

	return "\n".join(lines)
