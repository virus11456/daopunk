class_name InteractableComponent
extends Area2D

signal interaction_requested(actor: Node, action_id: StringName)

@export var action_id: StringName = &"talk"
@export var action_label: String = "Talk"

func get_interactions(_actor: Node) -> Array[Dictionary]:
	return [{"id": action_id, "label": action_label}]

func interact(actor: Node, requested_action: StringName = action_id) -> void:
	if requested_action != action_id:
		return
	interaction_requested.emit(actor, requested_action)
