class_name InteractableComponent
extends Area2D
## Unified interaction surface for any world object (NPC, door, chest, item...).
##
## The UI never asks "is this an NPC?". It asks the component for a list of
## actions via `get_interactions()` and later invokes one via `interact()`.
## The owner object supplies the concrete behaviour by connecting to the
## `interaction_requested` signal (or overriding a handler).
##
## For Milestone 1 this only needs to advertise a single "Talk" action, but the
## API is shaped so doors, corpses, chests and workbenches slot in unchanged.

## Emitted when an actor triggers a specific action on this interactable.
signal interaction_requested(actor: Node, action: StringName)

## Emitted when this interactable becomes / stops being the player's focus,
## so it can show a highlight or prompt.
signal focus_changed(focused: bool)

## Human-readable label shown in prompts ("Mara", "Wooden Door").
@export var display_name: String = "Object"

## Actions this object offers, in menu order. Milestone 1 uses ["Talk"].
@export var actions: Array[StringName] = [&"Talk"]

## Prompt verb shown for the primary (first) action, e.g. "Talk to".
@export var prompt_verb: String = "Talk to"

var _focused: bool = false


func _ready() -> void:
	add_to_group(&"interactable")
	monitoring = true
	monitorable = true


## Returns the actions currently available to `actor`. Owners can override the
## default by filtering (e.g. no "Talk" for a corpse). Kept trivial for now.
func get_interactions(_actor: Node) -> Array[StringName]:
	return actions.duplicate()


## Runs `action` on behalf of `actor`. Behaviour is delegated to the owner via
## the signal, so the component itself stays logic-free.
func interact(actor: Node, action: StringName = &"") -> void:
	var chosen: StringName = action
	if chosen == &"" and not actions.is_empty():
		chosen = actions[0]
	interaction_requested.emit(actor, chosen)


func get_primary_prompt() -> String:
	return "%s %s" % [prompt_verb, display_name]


func set_focused(value: bool) -> void:
	if _focused == value:
		return
	_focused = value
	focus_changed.emit(value)


func is_focused() -> bool:
	return _focused
