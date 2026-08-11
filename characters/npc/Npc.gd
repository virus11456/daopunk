class_name Npc
extends CharacterBody2D
## A non-player character that lives in the world.
##
## Milestone 1 scope: wander around a home point using NavigationAgent2D, and
## offer a "Talk" interaction that opens a branching dialogue. This is a
## deliberately small AI (Idle / Wander / Talk). The full schedule, needs and
## memory systems arrive in Phase 4 and will feed Goals into this same state
## machine — the movement layer here stays.

enum State { IDLE, WANDER, TALK, COMBAT, FLEE, DEAD }

@export var display_name: String = "Villager"
@export_group("Combat")
@export var is_hostile: bool = false
@export var aggro_range: float = 220.0
@export var flee_health_ratio: float = 0.3
## 五行 element (FiveElements.Element) applied to this NPC's health on spawn.
@export var element: int = FiveElements.Element.EARTH
## Weapon id equipped on spawn (from ItemDatabase), e.g. &"wooden_club".
@export var starting_weapon: StringName = &""
@export_group("")
@export var body_color: Color = Color(0.75, 0.62, 0.35)
@export_file("*.json") var dialogue_file: String = "res://data/dialogue/scavenger.json"
@export var wander_radius: float = 150.0
@export var move_speed: float = 60.0

## AI think cadence. NPCs never re-decide every frame (perf rule); they only
## pick a new destination when idle and their timer elapses.
@export var think_interval_min: float = 1.5
@export var think_interval_max: float = 4.0

@export_group("Merchant")
@export var is_merchant: bool = false
## Wares to stock on spawn as [{"id": StringName, "count": int}].
@export var shop_stock: Array[Dictionary] = []
## Cash a merchant carries to buy goods from the player.
@export var merchant_float: int = 500

@onready var _agent: NavigationAgent2D = $NavigationAgent2D
@onready var _interactable: InteractableComponent = $InteractableComponent
@onready var _inventory: InventoryComponent = $Inventory
@onready var _wallet: WalletComponent = $Wallet
@onready var _health: HealthComponent = $Health
@onready var _combat: CombatComponent = $Combat
@onready var _equipment: EquipmentComponent = $Equipment

var _state: State = State.IDLE
var _home: Vector2 = Vector2.ZERO
var _wait_timer: float = 0.0
var _facing: Vector2 = Vector2.DOWN
var _dialogue: Dictionary = {}
var _nav_ready: bool = false
var _fortune_cd_until: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(&"npc")
	_rng.randomize()
	_home = global_position
	_wait_timer = _rng.randf_range(0.2, think_interval_max)

	_interactable.display_name = display_name
	_interactable.prompt_verb = "接觸"
	var actions: Array[StringName] = []
	if not is_hostile:
		actions = [&"Talk", &"算命"]
	_interactable.actions = actions
	_interactable.interaction_requested.connect(_on_interaction_requested)
	_health.died.connect(_on_died)
	_health.damaged.connect(_on_damaged)

	_agent.path_desired_distance = 8.0
	_agent.target_desired_distance = 10.0

	_dialogue = _load_dialogue(dialogue_file)
	_health.element = element
	_equip_starting_weapon()
	_stock_shop()

	GameState.dialogue_closed.connect(_on_dialogue_closed)

	# The navigation map is not synced on the first frame; wait one physics
	# frame before issuing path queries so waypoints are valid.
	call_deferred("_enable_navigation")


func _enable_navigation() -> void:
	await get_tree().physics_frame
	_nav_ready = true


func _equip_starting_weapon() -> void:
	if starting_weapon == &"":
		return
	var weapon := ItemDatabase.get_item(starting_weapon)
	if weapon is WeaponData:
		_inventory.add(weapon, 1)
		_equipment.equip_weapon(weapon)


func _stock_shop() -> void:
	if not is_merchant:
		return
	_wallet.add(merchant_float)
	for entry in shop_stock:
		var item := ItemDatabase.get_item(entry.get("id", &""))
		if item != null:
			_inventory.add(item, int(entry.get("count", 1)))


func get_inventory() -> InventoryComponent:
	return _inventory


func get_wallet() -> WalletComponent:
	return _wallet


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	if is_hostile and _state != State.TALK:
		_evaluate_combat()

	match _state:
		State.IDLE:
			_tick_idle(delta)
		State.WANDER:
			_tick_wander(delta)
		State.TALK:
			_tick_halt(delta)
		State.COMBAT:
			_tick_combat(delta)
		State.FLEE:
			_tick_flee(delta)


func _evaluate_combat() -> void:
	var player := GameState.player
	if not is_instance_valid(player):
		return
	if _health.get_total_hp_ratio() <= flee_health_ratio:
		_state = State.FLEE
		return
	var dist := global_position.distance_to((player as Node2D).global_position)
	if dist <= aggro_range:
		_state = State.COMBAT
	elif _state == State.COMBAT:
		_state = State.IDLE


func _tick_combat(delta: float) -> void:
	var player := GameState.player as Node2D
	if not is_instance_valid(player):
		_enter_idle()
		return
	var to_player := player.global_position - global_position
	_set_facing(to_player)
	if _combat.in_range(player):
		velocity = velocity.move_toward(Vector2.ZERO, move_speed * 8.0 * delta)
		_combat.attack(player)
	else:
		velocity = to_player.normalized() * move_speed * _health.get_move_multiplier()
	move_and_slide()


func _tick_flee(delta: float) -> void:
	var player := GameState.player as Node2D
	if not is_instance_valid(player) or global_position.distance_to(player.global_position) > aggro_range * 1.6:
		_enter_idle()
		return
	var away := (global_position - player.global_position).normalized()
	velocity = away * move_speed * _health.get_move_multiplier()
	_set_facing(away)
	move_and_slide()


func _tick_idle(delta: float) -> void:
	_tick_halt(delta)
	if not _nav_ready:
		return
	_wait_timer -= delta
	if _wait_timer <= 0.0:
		_pick_new_destination()


func _tick_wander(delta: float) -> void:
	if _agent.is_navigation_finished():
		_enter_idle()
		return
	var next_point := _agent.get_next_path_position()
	var to_next := next_point - global_position
	if to_next.length() > 1.0:
		velocity = to_next.normalized() * move_speed
		_set_facing(to_next)
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _tick_halt(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, move_speed * 8.0 * delta)
	move_and_slide()


func _enter_idle() -> void:
	_state = State.IDLE
	_wait_timer = _rng.randf_range(think_interval_min, think_interval_max)


func _pick_new_destination() -> void:
	var angle := _rng.randf_range(0.0, TAU)
	var dist := _rng.randf_range(wander_radius * 0.3, wander_radius)
	var candidate := _home + Vector2.RIGHT.rotated(angle) * dist
	_agent.target_position = candidate
	if _agent.is_target_reachable():
		_state = State.WANDER
	else:
		# Unreachable pick — stay idle briefly and try again next tick.
		_wait_timer = _rng.randf_range(0.5, 1.0)


func _set_facing(dir: Vector2) -> void:
	var n := dir.normalized()
	if n != _facing:
		_facing = n
		queue_redraw()


func _on_interaction_requested(actor: Node, action: StringName) -> void:
	match action:
		&"Talk":
			_start_talk(actor)
		&"算命":
			_do_fortune(actor)
		&"搜刮":
			_loot(actor)


func _loot(actor: Node) -> void:
	if not (actor is Player):
		return
	var player_inv := (actor as Player).get_inventory()
	var weapon := _equipment.get_weapon()
	if weapon != null:
		player_inv.add(weapon, 1)
	for stack in _inventory.get_stacks().duplicate():
		player_inv.add(stack["item"], int(stack["count"]))
	var money := _wallet.get_money()
	if money > 0:
		(actor as Player).get_wallet().add(money)
		_wallet.spend(money)
	_interactable.display_name = "%s（已搜刮）" % display_name
	var empty: Array[StringName] = []
	_interactable.actions = empty


func _start_talk(actor: Node) -> void:
	_face_and_halt(actor)
	GameState.in_dialogue = true
	var start_id: String = _dialogue.get("start_id", "start")
	GameState.request_dialogue(display_name, _dialogue, start_id, self)


func _do_fortune(actor: Node) -> void:
	if not (actor is Player):
		return
	_face_and_halt(actor)
	var now := Time.get_ticks_msec()
	if now < _fortune_cd_until:
		_open_reading("卦象", "（此人不久前才算過。）天機不可盡洩，改日再來吧。")
		return

	var player := actor as Player
	var r := FortuneService.divine(player)
	player.get_wallet().add(int(r["credits"]))
	player.get_arts().add_proficiency(&"divination", int(r["divination_gain"]))
	player.get_arts().add_proficiency(&"fate", int(r["fate_gain"]))
	GameState.add_karma(int(r["karma"]))
	_fortune_cd_until = now + 60000

	var text := "%s\n\n（為 %s 卜算完畢：獲得 %d Credits，卜術與命術皆有精進，功德 +%d。）" % [
		r["reading"], display_name, int(r["credits"]), int(r["karma"])]
	_open_reading("卦象 · 銅錢卜卦", text)


func _face_and_halt(actor: Node) -> void:
	_state = State.TALK
	velocity = Vector2.ZERO
	if is_instance_valid(actor) and actor is Node2D:
		_set_facing((actor as Node2D).global_position - global_position)


func _open_reading(speaker: String, text: String) -> void:
	GameState.in_dialogue = true
	var d := {
		"start_id": "start",
		"nodes": {"start": {"text": text, "choices": [{"text": "（收起銅錢）", "next": "end"}]}},
	}
	GameState.request_dialogue(speaker, d, "start", self)


func _on_dialogue_closed(source: Node) -> void:
	if source != self:
		return
	if _state != State.DEAD:
		_enter_idle()


func _on_damaged(_part: StringName, _amount: float) -> void:
	# A wounded non-combatant panics and runs.
	if not is_hostile and _state != State.DEAD and _health.is_alive():
		_state = State.FLEE


func _on_died() -> void:
	_state = State.DEAD
	velocity = Vector2.ZERO
	body_color = body_color.darkened(0.55)
	_interactable.display_name = "%s（屍體）" % display_name
	_interactable.prompt_verb = "搜刮"
	var loot_actions: Array[StringName] = [&"搜刮"]
	_interactable.actions = loot_actions
	remove_from_group(&"npc")
	queue_redraw()


func _load_dialogue(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("Npc '%s': dialogue file not found: %s" % [display_name, path])
		return _fallback_dialogue()
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Npc '%s': dialogue file is not a JSON object: %s" % [display_name, path])
		return _fallback_dialogue()
	return parsed


func _fallback_dialogue() -> Dictionary:
	return {
		"start_id": "start",
		"nodes": {
			"start": {
				"text": "...",
				"choices": [{"text": "Leave.", "next": "end"}]
			}
		}
	}


## Debug helpers used by the DebugOverlay.
func get_state_name() -> String:
	match _state:
		State.IDLE:
			return "Idle"
		State.WANDER:
			return "Wander"
		State.TALK:
			return "Talk"
		State.COMBAT:
			return "Combat"
		State.FLEE:
			return "Flee"
		State.DEAD:
			return "Dead"
	return "?"


func get_destination() -> Vector2:
	return _agent.target_position


func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.5, Color(0.05, 0.05, 0.06))
	draw_circle(Vector2.ZERO, 9.0, body_color)
	var nose := _facing * 13.0
	draw_line(Vector2.ZERO, nose, Color(0.1, 0.1, 0.12), 2.0)
