class_name CombatComponent
extends Node
## Resolves attacks with the owner's equipped weapon (or fists), shared by
## Player and NPC.
##
## Damage = weapon damage × 五行相剋 × arm condition, with a hit roll from weapon
## accuracy × arm condition. Attacks train 山術 (the body/combat art). The schema
## leaves room for armour, cover, ammo and criticals without a rewrite.

signal attack_performed(target: Node, hit: bool, is_ranged: bool)

@export var unarmed_damage: float = 4.0
@export var unarmed_range: float = 28.0
@export var unarmed_speed: float = 1.2

var _body: Node2D
var _equipment: EquipmentComponent
var _health: HealthComponent
var _arts: FiveArtsComponent
var _cooldown: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	_body = get_parent() as Node2D
	_equipment = get_parent().get_node_or_null("Equipment") as EquipmentComponent
	_health = get_parent().get_node_or_null("Health") as HealthComponent
	_arts = get_parent().get_node_or_null("Arts") as FiveArtsComponent


func _physics_process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta


func get_range() -> float:
	var weapon := _weapon()
	return weapon.attack_range if weapon != null else unarmed_range


func can_attack() -> bool:
	if _cooldown > 0.0:
		return false
	if _health != null and (not _health.is_alive() or _health.is_downed()):
		return false
	return true


func in_range(target: Node2D) -> bool:
	return is_instance_valid(target) and _body.global_position.distance_to(target.global_position) <= get_range()


## Attempts an attack on `target`. Returns true if an attack was made (hit or
## miss), false if it could not (cooldown, out of range, invalid target).
func attack(target: Node) -> bool:
	if not can_attack() or not is_instance_valid(target):
		return false
	var target_health := target.get_node_or_null("Health") as HealthComponent
	if target_health == null or not target_health.is_alive():
		return false
	if not in_range(target as Node2D):
		return false

	var weapon := _weapon()
	_cooldown = 1.0 / (weapon.attack_speed if weapon != null else unarmed_speed)

	var accuracy := (weapon.accuracy if weapon != null else 0.85)
	if _health != null:
		accuracy *= _health.get_manipulation_multiplier()
	var hit := _rng.randf() <= clampf(accuracy, 0.05, 0.99)

	var ranged := weapon != null and weapon.is_ranged()
	attack_performed.emit(target, hit, ranged)
	if _arts != null:
		_arts.add_proficiency(&"mountain", 2)
	if not hit:
		return true

	var dmg := (weapon.damage if weapon != null else unarmed_damage)
	if _health != null:
		dmg *= 0.6 + 0.4 * _health.get_manipulation_multiplier()
	if _arts != null:
		dmg *= 1.0 + float(_arts.get_proficiency(&"mountain")) / 8000.0

	var my_element := _health.element if _health != null else -1
	target_health.apply_damage(dmg, _damage_type(weapon), my_element)
	return true


func _weapon() -> WeaponData:
	return _equipment.get_weapon() if _equipment != null else null


func _damage_type(weapon: WeaponData) -> int:
	if weapon == null:
		return HealthComponent.DamageType.BLUNT
	match weapon.weapon_class:
		WeaponData.WeaponClass.MELEE:
			return HealthComponent.DamageType.CUT
		_:
			return HealthComponent.DamageType.GUNSHOT
