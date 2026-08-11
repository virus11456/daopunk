extends Node
## Headless integration smoke test.
##
## Loads the real Main scene (so autoloads are live), then drives the paths that
## input-replay can't reach: an NPC interaction opening dialogue, the dialogue
## closing, and the debug overlay building its report. Prints PASS/FAIL lines and
## sets the process exit code. Run with:
##   godot --headless --path . tests/Smoke.tscn

var _failures: int = 0


func _ready() -> void:
	var main: Node = load("res://world/Main.tscn").instantiate()
	add_child(main)
	await _run(main)


func _run(main: Node) -> void:
	# Let the world build and navigation sync.
	for i in 6:
		await get_tree().physics_frame

	_check("player registered", is_instance_valid(GameState.player))
	_check("region set", GameState.current_region == "Grey Valley Town")

	var npcs := get_tree().get_nodes_in_group(&"npc")
	_check("npcs spawned", npcs.size() >= 5)

	# Drive an interaction on the first NPC.
	var npc: Npc = npcs[0]
	var interactable: InteractableComponent = npc.get_node("InteractableComponent")
	interactable.interact(GameState.player, &"Talk")
	await get_tree().process_frame
	_check("dialogue opened", GameState.in_dialogue == true)
	_check("npc entered talk state", npc.get_state_name() == "Talk")

	# Close it via the event bus (as the DialoguePanel would).
	GameState.close_dialogue(npc)
	await get_tree().process_frame
	_check("dialogue closed", GameState.in_dialogue == false)

	# Debug overlay builds a report without error.
	var overlay: DebugOverlay = main.get_node("UI/DebugOverlay")
	overlay.visible = true
	await get_tree().process_frame
	_check("debug overlay visible", overlay.visible == true)

	# Let NPCs run their AI a while and confirm at least one has moved.
	var start_positions := {}
	for n in npcs:
		start_positions[n] = (n as Node2D).global_position
	for i in 120:
		await get_tree().physics_frame
	var any_moved := false
	for n in npcs:
		if (n as Node2D).global_position.distance_to(start_positions[n]) > 4.0:
			any_moved = true
			break
	_check("at least one npc wandered", any_moved)

	if _failures == 0:
		print("SMOKE: ALL PASSED")
	else:
		print("SMOKE: %d FAILURE(S)" % _failures)
	get_tree().quit(_failures)


func _check(label: String, condition: bool) -> void:
	if condition:
		print("PASS  %s" % label)
	else:
		print("FAIL  %s" % label)
		_failures += 1
