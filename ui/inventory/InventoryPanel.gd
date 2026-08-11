class_name InventoryPanel
extends MenuPanel
## Lists the player's inventory. Weapons can be equipped, consumables used, and
## any item dropped. Refreshes whenever the inventory changes while open.

var _money_label: Label
var _list: VBoxContainer
var _inventory: InventoryComponent


func _build_content() -> void:
	_make_header("Inventory  (I)")

	_money_label = Label.new()
	_money_label.add_theme_font_size_override("font_size", 15)
	_content_parent.add_child(_money_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_parent.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 4)
	scroll.add_child(_list)


func open() -> void:
	_bind_player()
	super.open()


func _bind_player() -> void:
	if _inventory != null:
		return
	var player := GameState.player as Player
	if player != null:
		_inventory = player.get_inventory()
		_inventory.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed() -> void:
	if is_open():
		_refresh()


func _refresh() -> void:
	_bind_player()
	var player := GameState.player as Player
	if player == null or _inventory == null:
		return
	_money_label.text = "Credits: %d" % player.get_wallet().get_money()

	for child in _list.get_children():
		child.queue_free()

	if _inventory.get_stacks().is_empty():
		var empty := Label.new()
		empty.text = "(empty)"
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		_list.add_child(empty)
		return

	for stack in _inventory.get_stacks():
		_list.add_child(_make_row(stack["item"], int(stack["count"]), player))


func _make_row(item: ItemData, count: int, player: Player) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var swatch := ColorRect.new()
	swatch.color = item.icon_color
	swatch.custom_minimum_size = Vector2(18, 18)
	row.add_child(swatch)

	var label := Label.new()
	label.text = "%s  x%d   (%dcr)" % [item.display_name, count, item.base_value]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	if item is WeaponData:
		var equip := Button.new()
		equip.text = "Equip"
		equip.pressed.connect(func() -> void: player.get_equipment().equip_weapon(item as WeaponData))
		row.add_child(equip)
	elif item is ConsumableData:
		var use := Button.new()
		use.text = "Use"
		use.pressed.connect(func() -> void: _use(item as ConsumableData, player))
		row.add_child(use)

	var drop := Button.new()
	drop.text = "Drop"
	drop.pressed.connect(func() -> void: _inventory.remove(item, 1))
	row.add_child(drop)

	return row


func _use(item: ConsumableData, player: Player) -> void:
	if player.consume(item):
		_inventory.remove(item, 1)
