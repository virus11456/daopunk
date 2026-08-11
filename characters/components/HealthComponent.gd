class_name HealthComponent
extends Node
## Simplified body-part health, shared by Player and NPC.
##
## Six parts each take damage and accumulate injuries (bleed + pain). Blood
## drains from bleeding; enough damage or blood loss downs then kills. Leg
## injuries slow movement, arm injuries weaken attacks — injuries have real
## gameplay consequences, as the brief requires. Full injury-type simulation
## (infection, fracture healing) is deliberately out of scope.

signal health_changed()
signal damaged(part: StringName, amount: float)
signal downed()
signal died()

enum DamageType { BLUNT, CUT, GUNSHOT }

const PARTS: Array[StringName] = [
	&"head", &"torso", &"left_arm", &"right_arm", &"left_leg", &"right_leg",
]
const PART_MAX := {
	&"head": 25.0, &"torso": 45.0,
	&"left_arm": 22.0, &"right_arm": 22.0,
	&"left_leg": 25.0, &"right_leg": 25.0,
}
const HIT_WEIGHTS := {
	&"head": 8, &"torso": 40,
	&"left_arm": 13, &"right_arm": 13,
	&"left_leg": 13, &"right_leg": 13,
}

## 五行 element (FiveElements.Element) used by 五行相剋.
@export var element: int = FiveElements.Element.EARTH
@export var blood_max: float = 100.0
@export var pain_downed_threshold: float = 0.85

var _hp: Dictionary = {}
var _bleed: Dictionary = {}
var _pain: Dictionary = {}
var _blood: float = 0.0
var _alive: bool = true
var _downed: bool = false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	for part in PARTS:
		_hp[part] = float(PART_MAX[part])
		_bleed[part] = 0.0
		_pain[part] = 0.0
	_blood = blood_max


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	var total_bleed := _total_bleed()
	if total_bleed > 0.0:
		_blood = maxf(0.0, _blood - total_bleed * delta)
		health_changed.emit()
		if _blood <= 0.0:
			_die()
		else:
			_update_downed()


## Applies damage, optionally through 五行相剋 (attacker_element -1 = neutral).
func apply_damage(amount: float, dtype: int = DamageType.BLUNT, attacker_element: int = -1, part: StringName = &"") -> void:
	if not _alive or amount <= 0.0:
		return
	var dmg := amount
	if attacker_element >= 0:
		dmg *= FiveElements.multiplier(attacker_element, element)

	var target_part := part if part != &"" else _random_part()
	_hp[target_part] = maxf(0.0, float(_hp[target_part]) - dmg)
	_bleed[target_part] = float(_bleed[target_part]) + _bleed_rate(dtype) * dmg
	_pain[target_part] = float(_pain[target_part]) + dmg * 0.012 + (0.1 if dtype == DamageType.GUNSHOT else 0.0)

	damaged.emit(target_part, dmg)
	health_changed.emit()

	if float(_hp[&"head"]) <= 0.0 or float(_hp[&"torso"]) <= 0.0:
		_die()
	elif _alive:
		_update_downed()


## Restores everything (基礎針灸 / a full heal).
func heal_full() -> void:
	for part in PARTS:
		_hp[part] = float(PART_MAX[part])
		_bleed[part] = 0.0
		_pain[part] = 0.0
	_blood = blood_max
	_alive = true
	_downed = false
	health_changed.emit()


func is_alive() -> bool:
	return _alive


func is_downed() -> bool:
	return _downed


func get_blood_ratio() -> float:
	return _blood / blood_max


func get_total_hp_ratio() -> float:
	var cur := 0.0
	var maximum := 0.0
	for part in PARTS:
		cur += float(_hp[part])
		maximum += float(PART_MAX[part])
	return cur / maximum if maximum > 0.0 else 0.0


## Leg condition + blood scale movement speed (0.15–1.0).
func get_move_multiplier() -> float:
	var legs := (_part_fraction(&"left_leg") + _part_fraction(&"right_leg")) * 0.5
	var blood := clampf(get_blood_ratio() + 0.3, 0.4, 1.0)
	return clampf(legs * blood, 0.15, 1.0)


## Arm condition scales attack accuracy/effectiveness (0.2–1.0).
func get_manipulation_multiplier() -> float:
	var arms := (_part_fraction(&"left_arm") + _part_fraction(&"right_arm")) * 0.5
	return clampf(arms, 0.2, 1.0)


func _part_fraction(part: StringName) -> float:
	return float(_hp[part]) / float(PART_MAX[part])


func _total_bleed() -> float:
	var total := 0.0
	for part in PARTS:
		total += float(_bleed[part])
	return total


func _total_pain() -> float:
	var total := 0.0
	for part in PARTS:
		total += float(_pain[part])
	return total


func _update_downed() -> void:
	var pain := _total_pain()
	var blood_factor := 1.0 - get_blood_ratio()
	var should_down := (pain + blood_factor * 0.5) >= pain_downed_threshold
	if should_down and not _downed:
		_downed = true
		downed.emit()
	elif not should_down and _downed:
		_downed = false


func _die() -> void:
	if not _alive:
		return
	_alive = false
	_downed = true
	for part in PARTS:
		_bleed[part] = 0.0
	died.emit()
	health_changed.emit()


func _bleed_rate(dtype: int) -> float:
	match dtype:
		DamageType.CUT:
			return 0.06
		DamageType.GUNSHOT:
			return 0.10
		_:
			return 0.02


func _random_part() -> StringName:
	var total := 0
	for part in PARTS:
		total += int(HIT_WEIGHTS[part])
	var roll := _rng.randi_range(1, total)
	for part in PARTS:
		roll -= int(HIT_WEIGHTS[part])
		if roll <= 0:
			return part
	return &"torso"
