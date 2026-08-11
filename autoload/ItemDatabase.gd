extends Node
## Central registry mapping item ids to their shared ItemData resources.
##
## Dialogue effects and shop stock refer to items by id (a plain string in JSON),
## so they never hard-code resource paths. Definitions are shared and immutable;
## per-character counts live in InventoryComponent.

var _items: Dictionary = {}


func _ready() -> void:
	_register(preload("res://items/weapons/knife.tres"))
	_register(preload("res://items/weapons/wooden_club.tres"))
	_register(preload("res://items/weapons/revolver.tres"))
	_register(preload("res://items/weapons/shotgun.tres"))
	_register(preload("res://items/weapons/rifle.tres"))
	_register(preload("res://items/consumables/bandage.tres"))
	_register(preload("res://items/consumables/canned_food.tres"))
	_register(preload("res://items/consumables/water.tres"))
	_register(preload("res://items/equipment/worn_coat.tres"))
	_register(preload("res://items/equipment/work_pants.tres"))


func _register(item: ItemData) -> void:
	if item == null or item.id == &"":
		push_warning("ItemDatabase: skipped an item with no id.")
		return
	_items[item.id] = item


func get_item(item_id: StringName) -> ItemData:
	return _items.get(item_id, null)


func has_item(item_id: StringName) -> bool:
	return _items.has(item_id)


func all_ids() -> Array:
	return _items.keys()
