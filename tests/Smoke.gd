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
	_check("region set", GameState.current_region == "歸墟 · 蔓哈頓深坑星")

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

	await _run_phase2(main, npc)

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


func _run_phase2(main: Node, _npc: Npc) -> void:
	var player := GameState.player as Player
	var inv := player.get_inventory()

	# Starting loadout.
	_check("item database loaded", ItemDatabase.get_item(&"knife") != null)
	_check("starting knife present", inv.has_id(&"knife", 1))
	_check("starting canned food x2", inv.count_of_id(&"canned_food") == 2)

	# Equip the knife.
	var knife := ItemDatabase.get_item(&"knife") as WeaponData
	var equipped := player.get_equipment().equip_weapon(knife)
	_check("knife equipped", equipped and player.get_equipment().get_weapon() == knife)
	_check("knife left inventory on equip", not inv.has_id(&"knife", 1))

	# Five Arts (五術) proficiency + technique unlock.
	var arts := player.get_arts()
	_check("five arts loaded", arts.get_art_name(&"mountain") == "山術")
	_check("base technique unlocked", arts.get_unlocked_count(&"mountain") >= 1)
	var before_prof := arts.get_proficiency(&"medical")
	arts.add_proficiency(&"medical", 600)
	_check("proficiency increased", arts.get_proficiency(&"medical") == before_prof + 600)
	_check("technique unlocked at threshold", arts.get_unlocked_count(&"medical") >= 2)

	# Kiro run resources: 功德 (karma) + 世界變動率 (world variance).
	GameState.add_karma(1000)
	_check("karma added", GameState.karma >= 1000)
	GameState.add_world_variance(15.0)
	_check("world variance tracked", GameState.world_variance >= 15.0)

	# World flag round-trip.
	GameState.set_flag(&"test_flag", true)
	_check("world flag persists", GameState.get_flag(&"test_flag") == true)

	# Dialogue effect: give_item.
	var dlg: DialoguePanel = main.get_node("UI/DialoguePanel")
	var bandages_before := inv.count_of_id(&"bandage")
	dlg._apply_effect({"type": "give_item", "id": "bandage", "count": 2})
	_check("dialogue give_item works", inv.count_of_id(&"bandage") == bandages_before + 2)

	# Shop: open on the merchant and buy an item.
	var merchant: Npc = null
	for n in get_tree().get_nodes_in_group(&"npc"):
		if (n as Npc).is_merchant:
			merchant = n
			break
	_check("merchant exists", merchant != null)

	if merchant != null:
		var shop: ShopPanel = main.get_node("UI/ShopPanel")
		GameState.request_shop(merchant)
		await get_tree().process_frame
		_check("shop opened", shop.is_open())

		var water := ItemDatabase.get_item(&"water")
		var money_before := player.get_wallet().get_money()
		var water_before := inv.count_of_id(&"water")
		var price := shop.buy_price(water)
		shop._buy(water, player)
		_check("shop buy added item", inv.count_of_id(&"water") == water_before + 1)
		_check("shop buy spent money", player.get_wallet().get_money() == money_before - price)
		shop.close()
		_check("menu flag cleared on close", GameState.in_menu == false)


func _check(label: String, condition: bool) -> void:
	if condition:
		print("PASS  %s" % label)
	else:
		print("FAIL  %s" % label)
		_failures += 1
