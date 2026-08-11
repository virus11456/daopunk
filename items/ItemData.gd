class_name ItemData
extends Resource
## Base definition for any item. Concrete items are .tres files; weapons and
## consumables extend this. Item *definitions* are shared/immutable — how many
## you carry lives in an InventoryComponent, not here.

enum Kind { MISC, CONSUMABLE, WEAPON, TOOL }

@export var id: StringName = &""
@export var display_name: String = "Item"
@export_multiline var description: String = ""
@export var kind: Kind = Kind.MISC
@export var max_stack: int = 99
@export var base_value: int = 1
## Placeholder icon tint until real art exists.
@export var icon_color: Color = Color(0.8, 0.8, 0.8)


func is_stackable() -> bool:
	return max_stack > 1


func is_equippable() -> bool:
	return kind == Kind.WEAPON or kind == Kind.TOOL


func is_usable() -> bool:
	return kind == Kind.CONSUMABLE
