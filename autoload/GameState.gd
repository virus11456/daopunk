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

## Emitted when a dialogue/interaction opens a shop. The ShopPanel listens.
signal shop_requested(merchant: Node)

## Persistent boolean world state set by dialogue/quests (e.g. quest flags).
signal world_flag_changed(flag: StringName, value: bool)

## Kiro run resources.
signal karma_changed(value: int)
signal world_variance_changed(value: float)

## The active player node, registered by Player._ready(). May be null before
## the world finishes loading.
var player: Node = null

## Name of the region the player is currently in (for HUD / debug).
var current_region: String = "Unknown"

## True while a modal UI (e.g. dialogue) owns input and world control should
## pause its non-essential updates.
var in_dialogue: bool = false

## True while any full-screen menu (inventory, character, shop) is open, so the
## player controller can suppress world movement.
var in_menu: bool = false

## Persistent world flags. Kept here so the (future) SaveManager has one place to
## serialise them from.
var world_flags: Dictionary = {}

## Kiro run resources. 功德 (karma) carries across 輪迴 (reincarnation); 世界變動率
## (world variance, 0–100) rises when the player defies fate and draws the
## Observers' attention.
var karma: int = 0
var world_variance: float = 0.0


func register_player(node: Node) -> void:
	player = node
	player_registered.emit(node)


func request_dialogue(speaker: String, dialogue: Dictionary, start_id: String, source: Node) -> void:
	dialogue_requested.emit(speaker, dialogue, start_id, source)


func close_dialogue(source: Node) -> void:
	in_dialogue = false
	dialogue_closed.emit(source)


func request_shop(merchant: Node) -> void:
	shop_requested.emit(merchant)


func set_flag(flag: StringName, value: bool = true) -> void:
	world_flags[flag] = value
	world_flag_changed.emit(flag, value)


func get_flag(flag: StringName) -> bool:
	return bool(world_flags.get(flag, false))


## True when neither dialogue nor a menu should let the world take input.
func is_ui_blocking() -> bool:
	return in_dialogue or in_menu


func add_karma(amount: int) -> void:
	if amount == 0:
		return
	karma = maxi(0, karma + amount)
	karma_changed.emit(karma)


func spend_karma(amount: int) -> bool:
	if amount < 0 or karma < amount:
		return false
	karma -= amount
	karma_changed.emit(karma)
	return true


## Raises 世界變動率, clamped to [0, 100]. Positive draws Observer attention.
func add_world_variance(amount: float) -> void:
	world_variance = clampf(world_variance + amount, 0.0, 100.0)
	world_variance_changed.emit(world_variance)


func get_player_position() -> Vector2:
	if is_instance_valid(player):
		return player.global_position
	return Vector2.ZERO
