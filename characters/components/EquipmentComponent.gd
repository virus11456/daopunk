class_name EquipmentComponent
extends Node
## Holds what a character has equipped. Milestone 2 has a single weapon slot;
## apparel/armour slots are added in the combat phase. Equipping moves the item
## out of the inventory; unequipping returns it.

signal equipment_changed()

## Assigned in the scene so the component can pull/return items.
@export var inventory_path: NodePath

var _weapon: WeaponData = null
var _inventory: InventoryComponent = null


func _ready() -> void:
	if inventory_path != NodePath():
		_inventory = get_node_or_null(inventory_path) as InventoryComponent


func get_weapon() -> WeaponData:
	return _weapon


## Equips a weapon that is present in the inventory. Any previously equipped
## weapon is returned to the inventory first.
func equip_weapon(weapon: WeaponData) -> bool:
	if weapon == null or _inventory == null:
		return false
	if not _inventory.has(weapon):
		return false
	if _weapon != null:
		_inventory.add(_weapon, 1)
	_inventory.remove(weapon, 1)
	_weapon = weapon
	equipment_changed.emit()
	return true


func unequip_weapon() -> bool:
	if _weapon == null or _inventory == null:
		return false
	if _inventory.is_full():
		return false
	_inventory.add(_weapon, 1)
	_weapon = null
	equipment_changed.emit()
	return true


func to_save() -> Dictionary:
	return {"weapon_id": String(_weapon.id) if _weapon != null else ""}
