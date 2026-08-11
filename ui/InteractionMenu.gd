class_name InteractionMenu
extends Control
## A small popup listing the actions an interactable offers, shown when the
## player interacts with something that has more than one action (e.g. an NPC
## you can both 對話 and 算命). Reuses InteractableComponent.get_interactions();
## the UI never hard-codes which actions exist.

const ACTION_LABELS := {
	"Talk": "對話",
	"算命": "算命",
	"Pick Up": "拾取",
	"Examine": "查看",
	"Trade": "交易",
}

var _list: VBoxContainer
var _actor: Node = null
var _interactable: InteractableComponent = null


func _ready() -> void:
	add_to_group(&"interaction_menu")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -110.0
	panel.offset_right = 110.0
	panel.offset_top = -120.0
	panel.offset_bottom = 120.0
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	margin.add_child(_list)

	hide()


func open_for(actor: Node, interactable: InteractableComponent, actions: Array) -> void:
	_actor = actor
	_interactable = interactable
	for child in _list.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = interactable.display_name
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	_list.add_child(title)
	_list.add_child(HSeparator.new())

	var first := true
	for action in actions:
		var button := Button.new()
		button.text = ACTION_LABELS.get(String(action), String(action))
		button.pressed.connect(_pick.bind(StringName(action)))
		_list.add_child(button)
		if first:
			button.grab_focus()
			first = false

	GameState.in_menu = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	show()


func _pick(action: StringName) -> void:
	var actor := _actor
	var interactable := _interactable
	_close()
	if is_instance_valid(interactable):
		interactable.interact(actor, action)


func _close() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.in_menu = false
	_actor = null
	_interactable = null


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
