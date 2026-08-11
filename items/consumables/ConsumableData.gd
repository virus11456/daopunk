class_name ConsumableData
extends ItemData
## A consumable definition. Effects are declared as data so the same "use" flow
## works for food, drink and medicine. Whether a given effect does anything yet
## depends on the systems that exist: `heal` is honoured once the HealthComponent
## lands in Phase 3, while `restore_stamina` applies to the player's stamina now.

@export_group("Effects")
## Fraction of max HP restored on use (0–1). Wired to health in the combat phase.
@export var heal: float = 0.0
## Fraction of max stamina restored on use (0–1).
@export var restore_stamina: float = 0.0
## Five Arts proficiency granted on use, e.g. {"medical": 5}.
@export var art_proficiency: Dictionary = {}
## 功德 (karma) granted on use — e.g. the 功德珠 grants 1000.
@export var karma: int = 0


func _init() -> void:
	kind = Kind.CONSUMABLE
