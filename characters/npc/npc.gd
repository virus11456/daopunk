class_name NonPlayerCharacter
extends CharacterBody2D

signal dialogue_requested(speaker: String, text: String)

@export var display_name: String = "Mara Vale"
@export_multiline var greeting: String = "Road's rough today. Stay near the lanterns after dark."
@export var movement_speed: float = 90.0
@export var destinations: Array[Vector2] = [Vector2(560, 260), Vector2(760, 450), Vector2(420, 520)]
@export var wait_duration: float = 2.0

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
@onready var interactable: InteractableComponent = $InteractableComponent
var ai_state: StringName = &"Idle"
var current_goal: String = "Walk the town route"
var _destination_index: int = 0
var _wait_remaining: float = 0.0

func _ready() -> void:
	interactable.interaction_requested.connect(_on_interaction_requested)
	navigation_agent.path_desired_distance = 6.0
	navigation_agent.target_desired_distance = 10.0
	call_deferred("_set_next_destination")

func _physics_process(delta: float) -> void:
	if _wait_remaining > 0.0:
		_wait_remaining -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		if _wait_remaining <= 0.0:
			_set_next_destination()
		return
	if navigation_agent.is_navigation_finished():
		ai_state = &"Idle"
		_wait_remaining = wait_duration
		return
	ai_state = &"MoveTo"
	var next_position := navigation_agent.get_next_path_position()
	velocity = global_position.direction_to(next_position) * movement_speed
	move_and_slide()

func _set_next_destination() -> void:
	if destinations.is_empty():
		return
	navigation_agent.target_position = destinations[_destination_index]
	_destination_index = (_destination_index + 1) % destinations.size()

func _on_interaction_requested(_actor: Node, _action_id: StringName) -> void:
	dialogue_requested.emit(display_name, greeting)

func get_debug_details() -> Dictionary:
	return {"name": display_name, "state": ai_state, "goal": current_goal,
		"destination": navigation_agent.target_position}
