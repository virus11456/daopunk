class_name TacticalPause
extends Control
## Real-time-with-pause control. Space freezes the world (Engine.time_scale = 0)
## and shows a banner; while paused, left-clicking near a hostile orders the
## player to attack it. Space again resumes. A first, deliberately simple pass —
## richer order queues (move here, use item, command allies) build on this.

const SELECT_RADIUS := 44.0

var _paused: bool = false
var _banner: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_banner = Label.new()
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.offset_left = -260.0
	_banner.offset_right = 260.0
	_banner.offset_top = 20.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 18)
	_banner.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_banner.add_theme_constant_override("outline_size", 4)
	_banner.text = "⏸ 戰術暫停 · 左鍵點敵人下令攻擊 · Space 繼續"
	add_child(_banner)

	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"tactical_pause"):
		if not GameState.is_ui_blocking():
			_toggle()
			get_viewport().set_input_as_handled()
	elif _paused and event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_order_attack()


func _toggle() -> void:
	_paused = not _paused
	Engine.time_scale = 0.0 if _paused else 1.0
	visible = _paused


func _order_attack() -> void:
	var player := GameState.player
	if not is_instance_valid(player):
		return
	var world := (player as Node2D).get_global_mouse_position()
	var best: Node = null
	var best_dist := SELECT_RADIUS
	for npc in get_tree().get_nodes_in_group(&"npc"):
		if npc is Npc and (npc as Npc).is_hostile:
			var d := (npc as Node2D).global_position.distance_to(world)
			if d < best_dist:
				best_dist = d
				best = npc
	if best != null and player.has_method("set_combat_target"):
		player.set_combat_target(best)
		_banner.text = "⏹ 已下令攻擊 %s · Space 繼續" % (best as Npc).display_name
