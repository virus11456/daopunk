class_name PlayerCharacter
extends CharacterBody2D

@export var walk_speed: float = 180.0
@export var run_speed: float = 300.0
@export var interaction_radius: float = 70.0
@export var zoom_step: float = 0.1
@export var minimum_zoom: float = 0.65
@export var maximum_zoom: float = 1.65

@onready var camera: Camera2D = $Camera2D

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed := run_speed if Input.is_action_pressed("run") else walk_speed
	velocity = direction * speed
	move_and_slide()
	if Input.is_action_just_pressed("interact"):
		_interact_with_nearest()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		_change_zoom(zoom_step)
	elif event.is_action_pressed("zoom_out"):
		_change_zoom(-zoom_step)

func _change_zoom(amount: float) -> void:
	var value: float = clampf(camera.zoom.x + amount, minimum_zoom, maximum_zoom)
	camera.zoom = Vector2(value, value)

func _interact_with_nearest() -> void:
	var nearest: InteractableComponent
	var nearest_distance := interaction_radius
	for candidate: Node in get_tree().get_nodes_in_group("interactables"):
		if not candidate is InteractableComponent:
			continue
		var distance := global_position.distance_to((candidate as InteractableComponent).global_position)
		if distance <= nearest_distance:
			nearest = candidate as InteractableComponent
			nearest_distance = distance
	if nearest != null:
		nearest.interact(self)
