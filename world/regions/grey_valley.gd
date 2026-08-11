extends Node2D

@onready var npc: NonPlayerCharacter = $NPC
@onready var dialogue_panel: DialoguePanel = $Interface/DialoguePanel

func _ready() -> void:
	npc.dialogue_requested.connect(dialogue_panel.show_dialogue)
