class_name DialoguePanel
extends Control
## Simple data-driven branching dialogue box.
##
## Listens on the GameState event bus for `dialogue_requested`. Dialogue data is
## a plain dictionary (loaded from JSON) shaped as:
##   {
##     "start_id": "start",
##     "nodes": {
##       "start": { "text": "...", "choices": [ {"text": "...", "next": "id"} ] }
##     }
##   }
## A choice whose "next" is "end" (or missing) closes the conversation.
## The Phase-2 dialogue system will add conditions/effects to nodes and choices;
## the traversal here is written to ignore unknown keys so that extension is
## additive.

const END_NODE := "end"

var _speaker_label: Label
var _text_label: RichTextLabel
var _choice_box: VBoxContainer

var _dialogue: Dictionary = {}
var _source: Node = null
var _active: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	hide()
	GameState.dialogue_requested.connect(_on_dialogue_requested)


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.name = "Box"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 32.0
	panel.offset_right = -32.0
	panel.offset_top = -220.0
	panel.offset_bottom = -24.0
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_speaker_label = Label.new()
	_speaker_label.add_theme_font_size_override("font_size", 20)
	_speaker_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	vbox.add_child(_speaker_label)

	_text_label = RichTextLabel.new()
	_text_label.fit_content = true
	_text_label.scroll_active = false
	_text_label.custom_minimum_size = Vector2(0, 60)
	_text_label.bbcode_enabled = false
	vbox.add_child(_text_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_choice_box)


func _on_dialogue_requested(speaker: String, dialogue: Dictionary, start_id: String, source: Node) -> void:
	_dialogue = dialogue
	_source = source
	_active = true
	_speaker_label.text = speaker
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()
	_show_node(start_id)


func _show_node(node_id: String) -> void:
	if node_id == END_NODE:
		_close()
		return
	var nodes: Dictionary = _dialogue.get("nodes", {})
	if not nodes.has(node_id):
		_close()
		return

	var node: Dictionary = nodes[node_id]
	# Node-level effects run on entry. Authors guard one-shots with flags.
	_apply_effects(node.get("effects", []))
	_text_label.text = String(node.get("text", "..."))
	_clear_choices()

	var visible_index := 0
	for choice in node.get("choices", []):
		if typeof(choice) != TYPE_DICTIONARY:
			continue
		if not _passes_conditions(choice.get("conditions", {})):
			continue
		var label := String(choice.get("text", "..."))
		_add_choice_button("%d. %s" % [visible_index + 1, label], choice, visible_index)
		visible_index += 1

	if visible_index == 0:
		_add_choice_button("(Continue)", {"next": END_NODE}, 0)


func _add_choice_button(label: String, choice: Dictionary, index: int) -> void:
	var button := Button.new()
	button.text = label
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(_choose.bind(choice))
	_choice_box.add_child(button)
	if index == 0:
		button.grab_focus()


func _choose(choice: Dictionary) -> void:
	_apply_effects(choice.get("effects", []))
	# An effect (e.g. open_shop) may have already closed the panel.
	if not _active:
		return
	_show_node(String(choice.get("next", END_NODE)))


func _passes_conditions(cond: Dictionary) -> bool:
	if cond.is_empty():
		return true
	if cond.has("require_flag") and not GameState.get_flag(StringName(cond["require_flag"])):
		return false
	if cond.has("forbid_flag") and GameState.get_flag(StringName(cond["forbid_flag"])):
		return false
	var player := _get_player()
	if cond.has("min_money"):
		if player == null or player.get_wallet().get_money() < int(cond["min_money"]):
			return false
	if cond.has("require_item"):
		var req: Dictionary = cond["require_item"]
		var need := int(req.get("count", 1))
		if player == null or player.get_inventory().count_of_id(StringName(req.get("id", ""))) < need:
			return false
	if cond.has("min_skill"):
		var ms: Dictionary = cond["min_skill"]
		if player == null or player.get_skills().get_level(StringName(ms.get("skill", ""))) < int(ms.get("level", 0)):
			return false
	return true


func _apply_effects(effects: Array) -> void:
	for effect in effects:
		if typeof(effect) == TYPE_DICTIONARY:
			_apply_effect(effect)


func _apply_effect(effect: Dictionary) -> void:
	var type := String(effect.get("type", ""))
	var player := _get_player()
	match type:
		"set_flag":
			GameState.set_flag(StringName(effect.get("flag", "")), bool(effect.get("value", true)))
		"give_item":
			if player != null:
				var item := ItemDatabase.get_item(StringName(effect.get("id", "")))
				if item != null:
					player.get_inventory().add(item, int(effect.get("count", 1)))
		"remove_item":
			if player != null:
				player.get_inventory().remove_by_id(StringName(effect.get("id", "")), int(effect.get("count", 1)))
		"add_money":
			if player != null:
				player.get_wallet().add(int(effect.get("amount", 0)))
		"add_skill_xp":
			if player != null:
				player.get_skills().add_xp(StringName(effect.get("skill", "")), float(effect.get("amount", 0)))
		"open_shop":
			if _source != null:
				# Defer so the dialogue closes before the shop opens.
				GameState.close_dialogue(_source)
				_active = false
				hide()
				mouse_filter = Control.MOUSE_FILTER_IGNORE
				GameState.request_shop(_source)
		_:
			push_warning("DialoguePanel: unknown effect type '%s'" % type)


func _get_player() -> Player:
	if GameState.player is Player:
		return GameState.player as Player
	return null


func _clear_choices() -> void:
	for child in _choice_box.get_children():
		child.queue_free()


func _close() -> void:
	if not _active:
		return
	_active = false
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clear_choices()
	GameState.close_dialogue(_source)
	_source = null


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"interact"):
		_close()
		get_viewport().set_input_as_handled()
