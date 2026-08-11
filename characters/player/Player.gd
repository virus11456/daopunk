class_name Player
extends CharacterBody2D
## Player-controlled character.
##
## Milestone 1 responsibilities: 8-directional WASD movement, run (Shift),
## sneak (Ctrl), camera zoom (mouse wheel), and detecting / triggering the
## nearest InteractableComponent (E). Combat, inventory and skills are later
## phases and intentionally absent here.

signal focus_changed(interactable: InteractableComponent)

const WALK_SPEED: float = 130.0
const RUN_MULTIPLIER: float = 1.7
const SNEAK_MULTIPLIER: float = 0.5
const ACCELERATION: float = 1400.0
const FRICTION: float = 1600.0
const BODY_RADIUS: float = 9.0

const ZOOM_MIN: float = 1.0
const ZOOM_MAX: float = 4.0
const ZOOM_STEP: float = 0.15

@onready var _detector: Area2D = $InteractionDetector
@onready var _camera: Camera2D = $Camera2D

var _facing: Vector2 = Vector2.DOWN
var _current_focus: InteractableComponent = null
var _is_running: bool = false
var _is_sneaking: bool = false


func _ready() -> void:
	add_to_group(&"player")
	GameState.register_player(self)


func _physics_process(delta: float) -> void:
	_update_movement(delta)
	_update_focus()


func _update_movement(delta: float) -> void:
	if GameState.in_dialogue:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		move_and_slide()
		return

	var input_dir := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_is_running = Input.is_action_pressed(&"run")
	_is_sneaking = Input.is_action_pressed(&"sneak")

	var speed := WALK_SPEED
	if _is_sneaking:
		speed *= SNEAK_MULTIPLIER
	elif _is_running:
		speed *= RUN_MULTIPLIER

	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * speed, ACCELERATION * delta)
		_set_facing(input_dir)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move_and_slide()


func _set_facing(dir: Vector2) -> void:
	var normalized := dir.normalized()
	if normalized != _facing:
		_facing = normalized
		queue_redraw()


## Picks the closest overlapping interactable and keeps the HUD prompt in sync.
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
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(-ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(ZOOM_STEP)


func _try_interact() -> void:
	if GameState.in_dialogue:
		return
	if is_instance_valid(_current_focus):
		_current_focus.interact(self)


func _adjust_zoom(amount: float) -> void:
	var z: float = clampf(_camera.zoom.x + amount, ZOOM_MIN, ZOOM_MAX)
	_camera.zoom = Vector2(z, z)


func get_focus() -> InteractableComponent:
	return _current_focus


func is_running() -> bool:
	return _is_running


func is_sneaking() -> bool:
	return _is_sneaking


## Placeholder art: a round body with a facing wedge. Replaced by layered
## sprites in a later art pass.
func _draw() -> void:
	draw_circle(Vector2.ZERO, BODY_RADIUS + 1.5, Color(0.05, 0.05, 0.06))
	draw_circle(Vector2.ZERO, BODY_RADIUS, Color(0.36, 0.62, 0.86))
	var nose := _facing * (BODY_RADIUS + 4.0)
	draw_line(Vector2.ZERO, nose, Color(0.9, 0.95, 1.0), 2.5)
