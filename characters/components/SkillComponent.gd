class_name SkillComponent
extends Node
## Use-based skills, shared by Player and NPC.
##
## Nine skills in the 0–20 range. Skills grow by *using* them — combat, healing,
## trading, sneaking all call `add_xp()`. There are no character classes; ability
## comes from skills + equipment.

signal skill_changed(skill: StringName, level: int)

const MAX_LEVEL := 20

const SKILLS: Array[StringName] = [
	&"shooting", &"melee", &"medicine", &"survival",
	&"mechanics", &"cooking", &"trading", &"stealth", &"persuasion",
]

## Optional starting levels, e.g. {"melee": 3}. Everything else starts at 0.
@export var starting_levels: Dictionary = {}

var _levels: Dictionary = {}
var _xp: Dictionary = {}


func _ready() -> void:
	for skill in SKILLS:
		_levels[skill] = int(starting_levels.get(String(skill), 0))
		_xp[skill] = 0.0


func get_level(skill: StringName) -> int:
	return int(_levels.get(skill, 0))


func get_xp(skill: StringName) -> float:
	return float(_xp.get(skill, 0.0))


## XP required to advance from `level` to `level + 1`.
func xp_to_next(level: int) -> float:
	return 100.0 + float(level) * 40.0


## Adds experience and levels up as thresholds are crossed (capped at MAX_LEVEL).
func add_xp(skill: StringName, amount: float) -> void:
	if not _levels.has(skill) or amount <= 0.0:
		return
	if get_level(skill) >= MAX_LEVEL:
		return
	_xp[skill] = get_xp(skill) + amount
	var leveled := false
	while get_level(skill) < MAX_LEVEL and _xp[skill] >= xp_to_next(get_level(skill)):
		_xp[skill] -= xp_to_next(get_level(skill))
		_levels[skill] = get_level(skill) + 1
		leveled = true
	if leveled:
		skill_changed.emit(skill, get_level(skill))


func to_save() -> Dictionary:
	return {"levels": _levels.duplicate(), "xp": _xp.duplicate()}


func from_save(data: Dictionary) -> void:
	_levels = (data.get("levels", {}) as Dictionary).duplicate()
	_xp = (data.get("xp", {}) as Dictionary).duplicate()
	for skill in SKILLS:
		if not _levels.has(skill):
			_levels[skill] = 0
		if not _xp.has(skill):
			_xp[skill] = 0.0
