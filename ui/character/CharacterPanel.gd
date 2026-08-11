class_name CharacterPanel
extends MenuPanel
## Shows the player's money, stamina, equipped weapon and use-based skills.

const SKILL_LABELS := {
	"shooting": "Shooting", "melee": "Melee", "medicine": "Medicine",
	"survival": "Survival", "mechanics": "Mechanics", "cooking": "Cooking",
	"trading": "Trading", "stealth": "Stealth", "persuasion": "Persuasion",
}

var _summary: RichTextLabel
var _skill_list: VBoxContainer
var _skills: SkillComponent


func _build_content() -> void:
	_make_header("Character  (Tab)")

	_summary = RichTextLabel.new()
	_summary.bbcode_enabled = true
	_summary.fit_content = true
	_summary.scroll_active = false
	_summary.custom_minimum_size = Vector2(0, 96)
	_content_parent.add_child(_summary)

	_content_parent.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_parent.add_child(scroll)

	_skill_list = VBoxContainer.new()
	_skill_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skill_list.add_theme_constant_override("separation", 3)
	scroll.add_child(_skill_list)


func open() -> void:
	_bind_player()
	super.open()


func _bind_player() -> void:
	if _skills != null:
		return
	var player := GameState.player as Player
	if player != null:
		_skills = player.get_skills()
		_skills.skill_changed.connect(_on_skill_changed)


func _on_skill_changed(_skill: StringName, _level: int) -> void:
	if is_open():
		_refresh()


func _refresh() -> void:
	_bind_player()
	var player := GameState.player as Player
	if player == null:
		return

	var weapon := player.get_equipment().get_weapon()
	var weapon_name := weapon.display_name if weapon != null else "Unarmed"
	_summary.text = "[b]Credits:[/b] %d\n[b]Stamina:[/b] %d%%\n[b]Weapon:[/b] %s" % [
		player.get_wallet().get_money(),
		int(round(player.get_stamina_ratio() * 100.0)),
		weapon_name,
	]

	for child in _skill_list.get_children():
		child.queue_free()
	for skill in SkillComponent.SKILLS:
		_skill_list.add_child(_make_skill_row(skill))


func _make_skill_row(skill: StringName) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_label := Label.new()
	name_label.text = SKILL_LABELS.get(String(skill), String(skill))
	name_label.custom_minimum_size = Vector2(110, 0)
	row.add_child(name_label)

	var level := _skills.get_level(skill)
	var bar := Label.new()
	bar.text = _bar_text(level)
	bar.add_theme_color_override("font_color", Color(0.55, 0.8, 0.55))
	row.add_child(bar)

	var lvl := Label.new()
	lvl.text = "%d/%d" % [level, SkillComponent.MAX_LEVEL]
	row.add_child(lvl)

	return row


func _bar_text(level: int) -> String:
	var filled := level
	var empty := SkillComponent.MAX_LEVEL - level
	return "█".repeat(filled) + "·".repeat(empty)
