class_name DialoguePanel
extends PanelContainer

@onready var speaker_label: Label = %SpeakerLabel
@onready var dialogue_label: Label = %DialogueLabel

func _ready() -> void:
	hide()

func show_dialogue(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	dialogue_label.text = text
	show()

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("close_dialogue") or event.is_action_pressed("interact")):
		hide()
		get_viewport().set_input_as_handled()
