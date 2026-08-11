class_name DebugOverlay
extends PanelContainer

@export var refresh_interval: float = 0.25
@onready var label: Label = $Margin/Label
var _elapsed: float = 0.0

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_debug"):
		visible = not visible
	if not visible:
		return
	_elapsed += delta
	if _elapsed >= refresh_interval:
		_elapsed = 0.0
		_refresh()

func _refresh() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var npc := get_tree().get_first_node_in_group("npcs") as NonPlayerCharacter
	var lines: Array[String] = ["DEBUG  [F1]", "FPS: %d" % Engine.get_frames_per_second(),
		"Region: Grey Valley Town", "NPC Count: %d" % get_tree().get_nodes_in_group("npcs").size()]
	if player != null:
		lines.append("Player: (%.0f, %.0f)" % [player.global_position.x, player.global_position.y])
	if npc != null:
		var details := npc.get_debug_details()
		lines.append("NPC: %s" % details.name)
		lines.append("AI State: %s" % details.state)
		lines.append("Goal: %s" % details.goal)
		var destination: Vector2 = details.destination
		lines.append("Navigation: (%.0f, %.0f)" % [destination.x, destination.y])
	label.text = "\n".join(lines)
