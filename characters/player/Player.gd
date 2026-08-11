class_name Player
extends CharacterBody2D
## Player-controlled character.
##
## Movement (walk/run/sneak), camera zoom, interaction, and a small stamina stat
## that running spends and rest/food restores. Gameplay data lives in shared
## components (Inventory / Equipment / Skills / Wallet) also used by NPCs.

signal focus_changed(interactable: InteractableComponent)
signal stamina_changed(ratio: float)

const WALK_SPEED: float = 130.0
const RUN_MULTIPLIER: float = 1.7
const SNEAK_MULTIPLIER: float = 0.5
const ACCELERATION: float = 1400.0
const FRICTION: float = 1600.0
const BODY_RADIUS: float = 9.0

const ZOOM_MIN: float = 1.0
const ZOOM_MAX: float = 4.0
const ZOOM_STEP: float = 0.15

const STAMINA_MAX: float = 100.0
const STAMINA_DRAIN: float = 18.0
const STAMINA_REGEN: float = 12.0

## Starting items as [{"id": StringName, "count": int}]. Applied on spawn.
@export var starting_loadout: Array[Dictionary] = []

@onready var _detector: Area2D = $InteractionDetector
@onready var _camera: Camera2D = $Camera2D
@onready var _inventory: InventoryComponent = $Inventory
@onready var _equipment: EquipmentComponent = $Equipment
@onready var _arts: FiveArtsComponent = $Arts
@onready var _wallet: WalletComponent = $Wallet
@onready var _health: HealthComponent = $Health
@onready var _combat: CombatComponent = $Combat

const TARGET_ACQUIRE_RANGE: float = 400.0

var _facing: Vector2 = Vector2.DOWN
var _current_focus: InteractableComponent = null
var _is_running: bool = false
var _is_sneaking: bool = false
var _stamina: float = STAMINA_MAX
var _combat_target: Node = null


func _ready() -> void:
	add_to_group(&"player")
	GameState.register_player(self)
	Reincarnation.apply_to_player(self)
	_apply_starting_loadout()
	_health.died.connect(_on_died)


func _apply_starting_loadout() -> void:
	for entry in starting_loadout:
		var item := ItemDatabase.get_item(entry.get("id", &""))
		if item != null:
			_inventory.add(item, int(entry.get("count", 1)))


func _physics_process(delta: float) -> void:
	_prune_combat_target()
	_update_movement(delta)
	_update_stamina(delta)
	_update_focus()
	if _combat_target != null and _combat.in_range(_combat_target as Node2D):
		_combat.attack(_combat_target)


func _update_movement(delta: float) -> void:
	if GameState.is_ui_blocking() or not _health.is_alive() or _health.is_downed():
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		move_and_slide()
		return

	var input_dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_is_sneaking = Input.is_action_pressed(&"sneak")
	_is_running = Input.is_action_pressed(&"run") and not _is_sneaking and _stamina > 1.0

	var speed := WALK_SPEED * _health.get_move_multiplier()
	if _is_sneaking:
		speed *= SNEAK_MULTIPLIER
	elif _is_running:
		speed *= RUN_MULTIPLIER

	if input_dir != Vector2.ZERO:
		_combat_target = null
		velocity = velocity.move_toward(input_dir * speed, ACCELERATION * delta)
		_set_facing(input_dir)
	elif _combat_target != null:
		_move_toward_target(delta, speed)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move_and_slide()


## Auto-approaches a combat target until in weapon range, then holds and lets
## _physics_process fire. WASD overrides this (clears the target).
func _move_toward_target(delta: float, speed: float) -> void:
	var target := _combat_target as Node2D
	var to_target := target.global_position - global_position
	_set_facing(to_target)
	if to_target.length() > _combat.get_range() * 0.9:
		velocity = velocity.move_toward(to_target.normalized() * speed, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)


func _prune_combat_target() -> void:
	if _combat_target == null:
		return
	if not is_instance_valid(_combat_target):
		_combat_target = null
		return
	var th := _combat_target.get_node_or_null("Health") as HealthComponent
	if th == null or not th.is_alive():
		_combat_target = null


func _update_stamina(delta: float) -> void:
	var moving := velocity.length() > 5.0
	var before := _stamina
	if _is_running and moving:
		_stamina = maxf(0.0, _stamina - STAMINA_DRAIN * delta)
	else:
		_stamina = minf(STAMINA_MAX, _stamina + STAMINA_REGEN * delta)
	if not is_equal_approx(before, _stamina):
		stamina_changed.emit(get_stamina_ratio())


func _set_facing(dir: Vector2) -> void:
	var normalized := dir.normalized()
	if normalized != _facing:
		_facing = normalized
		queue_redraw()


func _update_focus() -> void:
	var closest: InteractableComponent = null
	var closest_dist := INF
	for area in _detector.get_overlapping_areas():
		if area is InteractableComponent:
			var d := global_position.distance_squared_to(area.global_position)
			if d < closest_dist:
				closest_dist = d
				closest = area

	if closest == _current_focus:
		return

	if is_instance_valid(_current_focus):
		_current_focus.set_focused(false)
	_current_focus = closest
	if is_instance_valid(_current_focus):
		_current_focus.set_focused(true)
	focus_changed.emit(_current_focus)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"interact"):
		_try_interact()
	elif event.is_action_pressed(&"attack"):
		_attack_nearest()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(-ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_open_context_menu()


func _try_interact() -> void:
	if GameState.is_ui_blocking():
		return
	if not is_instance_valid(_current_focus):
		return
	var actions := _current_focus.get_interactions(self)
	if actions.size() > 1 and _open_menu(actions):
		return
	_current_focus.interact(self)


## Right-click always opens the action menu for the focused interactable.
func _open_context_menu() -> void:
	if GameState.is_ui_blocking() or not is_instance_valid(_current_focus):
		return
	_open_menu(_current_focus.get_interactions(self))


func _open_menu(actions: Array) -> bool:
	var menu := get_tree().get_first_node_in_group(&"interaction_menu")
	if menu == null or actions.is_empty():
		return false
	(menu as InteractionMenu).open_for(self, _current_focus, actions)
	return true


func _adjust_zoom(amount: float) -> void:
	var z: float = clampf(_camera.zoom.x + amount, ZOOM_MIN, ZOOM_MAX)
	_camera.zoom = Vector2(z, z)


## Consumes a consumable's effects onto the player (stamina now; heal in Phase 3).
func consume(item: ConsumableData) -> bool:
	if item == null:
		return false
	if item.restore_stamina > 0.0:
		_stamina = minf(STAMINA_MAX, _stamina + STAMINA_MAX * item.restore_stamina)
		stamina_changed.emit(get_stamina_ratio())
	for art_id in item.art_proficiency:
		_arts.add_proficiency(StringName(art_id), int(item.art_proficiency[art_id]))
	if item.karma != 0:
		GameState.add_karma(item.karma)
	if item.soul_repair > 0.0:
		Reincarnation.repair_soul(item.soul_repair)
	return true


func _attack_nearest() -> void:
	if GameState.is_ui_blocking() or not _health.is_alive() or _health.is_downed():
		return
	if _combat_target == null:
		_combat_target = _find_nearest_hostile()
	if _combat_target != null and _combat.in_range(_combat_target as Node2D):
		_combat.attack(_combat_target)


func _find_nearest_hostile() -> Node:
	var best: Node = null
	var best_dist := TARGET_ACQUIRE_RANGE
	for npc in get_tree().get_nodes_in_group(&"npc"):
		if npc is Npc and (npc as Npc).is_hostile:
			var h := npc.get_node_or_null("Health") as HealthComponent
			if h != null and h.is_alive():
				var d := global_position.distance_to((npc as Node2D).global_position)
				if d < best_dist:
					best_dist = d
					best = npc
	return best


## Called by the tactical-pause overlay to order an attack on a specific target.
func set_combat_target(node: Node) -> void:
	_combat_target = node


func _on_died() -> void:
	# Player death is a 輪迴 — reincarnate into a fresh life next frame.
	call_deferred("_reincarnate_on_death")


func _reincarnate_on_death() -> void:
	Reincarnation.reincarnate()


func get_health() -> HealthComponent:
	return _health


func get_combat() -> CombatComponent:
	return _combat


func get_inventory() -> InventoryComponent:
	return _inventory


func get_equipment() -> EquipmentComponent:
	return _equipment


func get_arts() -> FiveArtsComponent:
	return _arts


func get_wallet() -> WalletComponent:
	return _wallet


func get_stamina_ratio() -> float:
	return _stamina / STAMINA_MAX


func get_focus() -> InteractableComponent:
	return _current_focus


func is_running() -> bool:
	return _is_running


func is_sneaking() -> bool:
	return _is_sneaking


func _draw() -> void:
	draw_circle(Vector2.ZERO, BODY_RADIUS + 1.5, Color(0.05, 0.05, 0.06))
	draw_circle(Vector2.ZERO, BODY_RADIUS, Color(0.36, 0.62, 0.86))
	var nose := _facing * (BODY_RADIUS + 4.0)
	draw_line(Vector2.ZERO, nose, Color(0.9, 0.95, 1.0), 2.5)
