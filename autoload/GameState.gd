extends Node
## Global, lightweight game-flow state.
##
## Deliberately small: it only tracks references and flags that many systems
## need to reach. Heavy simulation data lives in dedicated managers/components,
## not here. This keeps us away from a monolithic GameManager.

signal player_registered(player: Node)

## Lightweight event bus for dialogue. NPCs emit `dialogue_requested`; the
## DialoguePanel listens. When the panel closes it emits `dialogue_closed` so
## the requesting NPC can resume its routine. This keeps gameplay entities from
## depending directly on UI nodes.
signal dialogue_requested(speaker: String, dialogue: Dictionary, start_id: String, source: Node)
signal dialogue_closed(source: Node)

## The active player node, registered by Player._ready(). May be null before
## the world finishes loading.
var player: Node = null

## Name of the region the player is currently in (for HUD / debug).
var current_region: String = "Unknown"

## True while a modal UI (e.g. dialogue) owns input and world control should
## pause its non-essential updates.
var in_dialogue: bool = false


func register_player(node: Node) -> void:
	player = node
	player_registered.emit(node)


func request_dialogue(speaker: String, dialogue: Dictionary, start_id: String, source: Node) -> void:
	dialogue_requested.emit(speaker, dialogue, start_id, source)


func close_dialogue(source: Node) -> void:
	in_dialogue = false
	dialogue_closed.emit(source)


func get_player_position() -> Vector2:
	if is_instance_valid(player):
		return player.global_position
	return Vector2.ZERO
