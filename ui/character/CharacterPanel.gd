class_name CharacterPanel
extends MenuPanel
## Shows the player's 功德 (karma), stamina, equipped weapon and the Five Arts
## (五術) with their proficiency and unlocked techniques.

var _summary: RichTextLabel
var _arts_list: VBoxContainer
var _arts: FiveArtsComponent


func _build_content() -> void:
	_make_header("角色 · 五術  (Tab)")

	_summary = RichTextLabel.new()
	_summary.bbcode_enabled = true
	_summary.fit_content = true
	_summary.scroll_active = false
	_summary.custom_minimum_size = Vector2(0, 84)
	_content_parent.add_child(_summary)

	_content_parent.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_parent.add_child(scroll)

	_arts_list = VBoxContainer.new()
	_arts_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_arts_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_arts_list)


func open() -> void:
	_bind_player()
	super.open()


func _bind_player() -> void:
	if _arts != null:
		return
	var player := GameState.player as Player
	if player != null:
		_arts = player.get_arts()
		_arts.proficiency_changed.connect(_on_arts_changed)
	GameState.karma_changed.connect(_on_karma_changed)


func _on_arts_changed(_art: StringName, _value: int) -> void:
	if is_open():
		_refresh()


func _on_karma_changed(_value: int) -> void:
	if is_open():
		_refresh()


func _refresh() -> void:
	_bind_player()
	var player := GameState.player as Player
	if player == null:
		return

	var weapon := player.get_equipment().get_weapon()
	var weapon_name := weapon.display_name if weapon != null else "空手"
	_summary.text = "[b]功德:[/b] %d    [b]體力:[/b] %d%%\n[b]武器:[/b] %s    [b]世界變動率:[/b] %.0f%%" % [
		GameState.karma,
		int(round(player.get_stamina_ratio() * 100.0)),
		weapon_name,
		GameState.world_variance,
	]

	for child in _arts_list.get_children():
		child.queue_free()
	for art in FiveArtsComponent.ARTS:
		_arts_list.add_child(_make_art_block(art))


func _make_art_block(art: StringName) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var unlocked := _arts.get_unlocked_count(art)
	var total := _arts.get_techniques(art).size()
	var header := Label.new()
	header.text = "%s  ·  熟練度 %d  ·  已通 %d/%d" % [
		_arts.get_art_name(art), _arts.get_proficiency(art), unlocked, total]
	header.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	box.add_child(header)

	for tech in _arts.get_techniques(art):
		var open_tech := _arts.is_unlocked(art, tech)
		var line := Label.new()
		var mark := "◆" if open_tech else "◇"
		line.text = "   %s Lv.%s %s — %s" % [mark, tech.get("level", "?"), tech.get("name", "?"), tech.get("effect", "")]
		line.add_theme_font_size_override("font_size", 12)
		line.add_theme_color_override("font_color",
			Color(0.8, 0.85, 0.8) if open_tech else Color(0.45, 0.45, 0.45))
		box.add_child(line)

	return box
