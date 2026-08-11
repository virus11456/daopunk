class_name WeaponData
extends ItemData
## A weapon definition. The combat resolver (Phase 3) will read these fields; for
## now they drive equipment display and a derived attack rating. The schema is
## deliberately full so armour/ammo/condition slot in later without a rewrite.

enum WeaponClass { MELEE, PISTOL, SHOTGUN, RIFLE }

@export_group("Combat")
@export var damage: float = 5.0
@export var attack_range: float = 32.0
@export var accuracy: float = 0.8
@export var attack_speed: float = 1.0
@export var reload_time: float = 0.0
@export var noise: float = 0.2
@export var weapon_class: WeaponClass = WeaponClass.MELEE
@export var ammo_type: StringName = &""


func _init() -> void:
	kind = Kind.WEAPON
	max_stack = 1


## The skill this weapon trains and scales with.
func governing_skill() -> StringName:
	if weapon_class == WeaponClass.MELEE:
		return &"melee"
	return &"shooting"


func is_ranged() -> bool:
	return weapon_class != WeaponClass.MELEE
