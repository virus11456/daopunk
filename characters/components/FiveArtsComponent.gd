class_name FiveArtsComponent
extends Node
## The Five Arts (五術) cultivation system — Kiro's ability layer, shared by
## Player and NPC. It replaces generic RimWorld-style skills.
##
## Each art (Mountain / Medical / Fate / Feng Shui / Divination) has a
## *proficiency* (熟練度) that grows through use. Individual techniques unlock
## when proficiency reaches their threshold (proficiency_required). Technique
## definitions are data (data/skills/five_arts.json); this component tracks
## per-art proficiency and answers what is unlocked.

signal proficiency_changed(art: StringName, value: int)
signal technique_unlocked(art: StringName, technique_id: StringName)

const ARTS: Array[StringName] = [&"mountain", &"medical", &"fate", &"feng_shui", &"divination"]

@export_file("*.json") var data_file: String = "res://data/skills/five_arts.json"
## Optional starting proficiency per art, e.g. {"mountain": 100}.
@export var starting_proficiency: Dictionary = {}

var _arts: Dictionary = {}          # art_id -> art definition dict
var _proficiency: Dictionary = {}   # art_id -> int
var _unlocked: Dictionary = {}      # art_id -> Array[StringName] already announced


func _ready() -> void:
	_load_data()
	for art in ARTS:
		_proficiency[art] = int(starting_proficiency.get(String(art), 0))
		_unlocked[art] = _compute_unlocked(art)


func _load_data() -> void:
	if not FileAccess.file_exists(data_file):
		push_warning("FiveArtsComponent: data file not found: %s" % data_file)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(data_file))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("FiveArtsComponent: invalid data file: %s" % data_file)
		return
	for art in parsed.get("arts", []):
		_arts[StringName(art.get("id", ""))] = art


func get_proficiency(art: StringName) -> int:
	return int(_proficiency.get(art, 0))


func get_art_name(art: StringName) -> String:
	return String((_arts.get(art, {}) as Dictionary).get("name", String(art)))


func get_branches(art: StringName) -> Array:
	return (_arts.get(art, {}) as Dictionary).get("branches", [])


func get_techniques(art: StringName) -> Array:
	return (_arts.get(art, {}) as Dictionary).get("skills", [])


func is_unlocked(art: StringName, technique: Dictionary) -> bool:
	return get_proficiency(art) >= int(technique.get("proficiency_required", 0))


func get_unlocked_count(art: StringName) -> int:
	var count := 0
	for tech in get_techniques(art):
		if is_unlocked(art, tech):
			count += 1
	return count


## Grants proficiency in an art and announces any techniques that just unlocked.
func add_proficiency(art: StringName, amount: int) -> void:
	if not _proficiency.has(art) or amount <= 0:
		return
	_proficiency[art] = get_proficiency(art) + amount
	proficiency_changed.emit(art, get_proficiency(art))

	var now_unlocked := _compute_unlocked(art)
	for tech_id in now_unlocked:
		if not (_unlocked[art] as Array).has(tech_id):
			technique_unlocked.emit(art, tech_id)
	_unlocked[art] = now_unlocked


func _compute_unlocked(art: StringName) -> Array:
	var ids: Array = []
	for tech in get_techniques(art):
		if is_unlocked(art, tech):
			ids.append(StringName(tech.get("id", "")))
	return ids


func to_save() -> Dictionary:
	return {"proficiency": _proficiency.duplicate()}


func from_save(data: Dictionary) -> void:
	var saved: Dictionary = data.get("proficiency", {})
	for art in ARTS:
		_proficiency[art] = int(saved.get(String(art), 0))
		_unlocked[art] = _compute_unlocked(art)
