class_name ShopPanel
extends MenuPanel
## Buy/sell interface. Opened via GameState.shop_requested(merchant). Prices scale
## with the player's Trading skill, and trading trains it.

var _merchant: Node = null
var _merchant_inv: InventoryComponent
var _merchant_wallet: WalletComponent

var _title: Label
var _money_label: Label
var _buy_list: VBoxContainer
var _sell_list: VBoxContainer


func _build_content() -> void:
	_title = Label.new()
	_title.text = "Trade"
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	_content_parent.add_child(_title)

	_money_label = Label.new()
	_money_label.add_theme_font_size_override("font_size", 15)
	_content_parent.add_child(_money_label)
	_content_parent.add_child(HSeparator.new())

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 16)
	_content_parent.add_child(columns)

	_buy_list = _make_column(columns, "For sale (buy)")
	_sell_list = _make_column(columns, "Your goods (sell)")

	var hint := Label.new()
	hint.text = "Esc to leave"
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_content_parent.add_child(hint)


func _make_column(parent: HBoxContainer, title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(box)

	var header := Label.new()
	header.text = title
	header.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	box.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	scroll.add_child(list)
	return list


func _ready() -> void:
	super._ready()
	GameState.shop_requested.connect(_on_shop_requested)


func _on_shop_requested(merchant: Node) -> void:
	if merchant == null or not merchant.has_method("get_inventory"):
		return
	_merchant = merchant
	_merchant_inv = merchant.get_inventory()
	_merchant_wallet = merchant.get_wallet()
	var merchant_name: Variant = merchant.get("display_name")
	if merchant_name != null:
		_title.text = "Trade — %s" % merchant_name
	open()


## Bargaining power (0–20) derived from 命術 proficiency (fate reading lets you
## price fortunes and people).
func _bargain() -> int:
	var player := GameState.player as Player
	return clampi(player.get_arts().get_proficiency(&"fate") / 300, 0, 20) if player != null else 0


func buy_price(item: ItemData) -> int:
	var mult: float = clampf(1.30 - float(_bargain()) * 0.02, 0.90, 1.30)
	return maxi(1, int(ceil(float(item.base_value) * mult)))


func sell_price(item: ItemData) -> int:
	var mult: float = clampf(0.40 + float(_bargain()) * 0.015, 0.40, 0.70)
	return maxi(1, int(floor(float(item.base_value) * mult)))


func _refresh() -> void:
	var player := GameState.player as Player
	if player == null or _merchant_inv == null:
		return
	_money_label.text = "你: %dcr    商人: %dcr    (命術 Lv.%d)" % [
		player.get_wallet().get_money(), _merchant_wallet.get_money(), _bargain()]

	_fill_list(_buy_list, _merchant_inv, true, player)
	_fill_list(_sell_list, player.get_inventory(), false, player)


func _fill_list(list: VBoxContainer, inv: InventoryComponent, is_buy: bool, player: Player) -> void:
	for child in list.get_children():
		child.queue_free()
	if inv.get_stacks().is_empty():
		var empty := Label.new()
		empty.text = "(nothing)"
		empty.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		list.add_child(empty)
		return
	for stack in inv.get_stacks():
		list.add_child(_make_row(stack["item"], int(stack["count"]), is_buy, player))


func _make_row(item: ItemData, count: int, is_buy: bool, player: Player) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var price := buy_price(item) if is_buy else sell_price(item)
	label.text = "%s x%d — %dcr" % [item.display_name, count, price]
	row.add_child(label)

	var button := Button.new()
	button.text = "Buy" if is_buy else "Sell"
	if is_buy:
		button.pressed.connect(func() -> void: _buy(item, player))
	else:
		button.pressed.connect(func() -> void: _sell(item, player))
	row.add_child(button)
	return row


func _buy(item: ItemData, player: Player) -> void:
	var price := buy_price(item)
	if not player.get_wallet().can_afford(price):
		return
	if player.get_inventory().is_full():
		return
	if not _merchant_inv.has(item):
		return
	player.get_wallet().spend(price)
	_merchant_wallet.add(price)
	_merchant_inv.remove(item, 1)
	player.get_inventory().add(item, 1)
	player.get_arts().add_proficiency(&"fate", 3)
	_refresh()


func _sell(item: ItemData, player: Player) -> void:
	var price := sell_price(item)
	if not _merchant_wallet.can_afford(price):
		return
	if not player.get_inventory().has(item):
		return
	_merchant_wallet.spend(price)
	player.get_wallet().add(price)
	player.get_inventory().remove(item, 1)
	_merchant_inv.add(item, 1)
	player.get_arts().add_proficiency(&"fate", 2)
	_refresh()
