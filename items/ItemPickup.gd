class_name ItemPickup
extends Node2D
## A pickup lying in the world. Offers a "Pick Up" interaction that moves the
## item into the actor's inventory. Reuses InteractableComponent — no special
## casing in the interaction UI.

@export var item_id: StringName = &""
@export var count: int = 1

@onready var _interactable: InteractableComponent = $InteractableComponent


func _ready() -> void:
	var item := ItemDatabase.get_item(item_id)
	if item != null:
		_interactable.display_name = item.display_name
	_interactable.prompt_verb = "Pick up"
	_interactable.actions = [&"Pick Up"]
	_interactable.interaction_requested.connect(_on_interaction_requested)
	queue_redraw()


func _on_interaction_requested(actor: Node, _action: StringName) -> void:
	var item := ItemDatabase.get_item(item_id)
	if item == null or not (actor is Player):
		return
	var inv := (actor as Player).get_inventory()
	var leftover := inv.add(item, count)
	if leftover <= 0:
		queue_free()
	elif leftover < count:
		count = leftover
		queue_redraw()


func _draw() -> void:
	var item := ItemDatabase.get_item(item_id)
	var color := item.icon_color if item != null else Color.WHITE
	draw_rect(Rect2(-8, -8, 16, 16), Color(0.05, 0.05, 0.06))
	draw_rect(Rect2(-6, -6, 12, 12), color)
