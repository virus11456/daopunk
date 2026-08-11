class_name Npc
extends CharacterBody2D
## A non-player character that lives in the world.
##
## Milestone 1 scope: wander around a home point using NavigationAgent2D, and
## offer a "Talk" interaction that opens a branching dialogue. This is a
## deliberately small AI (Idle / Wander / Talk). The full schedule, needs and
## memory systems arrive in Phase 4 and will feed Goals into this same state
## machine — the movement layer here stays.

enum State { IDLE, WANDER, TALK }

@export var display_name: String = "Villager"
@export var body_color: Color = Color(0.75, 0.62, 0.35)
@export_file("*.json") var dialogue_file: String = "res://data/dialogue/villager.json"
@export var wander_radius: float = 150.0
@export var move_speed: float = 60.0

## AI think cadence. NPCs never re-decide every frame (perf rule); they only
## pick a new destination when idle and their timer elapses.
@export var think_interval_min: float = 1.5
@export var think_interval_max: float = 4.0

@onready var _agent: NavigationAgent2D = $NavigationAgent2D
@onready var _interactable: InteractableComponent = $InteractableComponent

var _state: State = State.IDLE
var _home: Vector2 = Vector2.ZERO
var _wait_timer: float = 0.0
var _facing: Vector2 = Vector2.DOWN
var _dialogue: Dictionary = {}
var _nav_ready: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(&"npc")
	_rng.randomize()
	_home = global_position
	_wait_timer = _rng.randf_range(0.2, think_interval_max)

	_interactable.display_name = display_name
	_interactable.prompt_verb = "Talk to"
	_interactable.interaction_requested.connect(_on_interaction_requested)

	_agent.path_desired_distance = 8.0
	_agent.target_desired_distance = 10.0

	_dialogue = _load_dialogue(dialogue_file)

	GameState.dialogue_closed.connect(_on_dialogue_closed)

	# The navigation map is not synced on the first frame; wait one physics
	# frame before issuing path queries so waypoints are valid.
	call_deferred("_enable_navigation")


func _enable_navigation() -> void:
	await get_tree().physics_frame
	_nav_ready = true


func _physics_process(delta: float) -> void:
	match _state:
		State.IDLE:
			_tick_idle(delta)
		State.WANDER:
			_tick_wander(delta)
		State.TALK:
			_tick_halt(delta)


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
	if action != &"Talk":
		return
	_state = State.TALK
	velocity = Vector2.ZERO
	if is_instance_valid(actor) and actor is Node2D:
		_set_facing((actor as Node2D).global_position - global_position)
	GameState.in_dialogue = true
	var start_id: String = _dialogue.get("start_id", "start")
	GameState.request_dialogue(display_name, _dialogue, start_id, self)


func _on_dialogue_closed(source: Node) -> void:
	if source != self:
		return
	_enter_idle()


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
	return "?"


func get_destination() -> Vector2:
	return _agent.target_position


func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.5, Color(0.05, 0.05, 0.06))
	draw_circle(Vector2.ZERO, 9.0, body_color)
	var nose := _facing * 13.0
	draw_line(Vector2.ZERO, nose, Color(0.1, 0.1, 0.12), 2.0)
