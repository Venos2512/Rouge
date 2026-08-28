extends CanvasLayer

var panel_root: Control
var grid: GridContainer
var effects: VBoxContainer
var detail_title: Label
var detail_body: Label
var status: Label
var open := false
var tab_down := false
var esc_down := false

const TEXT := Color("e8e6dc")
const MUTED := Color("8990ae")
const GOLD := Color("e8b967")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	panel_root.visible = false

func _process(_delta: float) -> void:
	var tab := Input.is_key_pressed(KEY_TAB)
	var esc := Input.is_key_pressed(KEY_ESCAPE)
	if tab and not tab_down: _toggle()
	if open and esc and not esc_down: _close()
	tab_down = tab
	esc_down = esc
	if open: _refresh()

func _build_ui() -> void:
	panel_root = get_node("PanelRoot") as Control
	panel_root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.025, 0.05, 0.82)
	panel_root.add_child(dim)
	var shell := PanelContainer.new()
	shell.position = Vector2(72, 52)
	shell.size = Vector2(936, 536)
	shell.add_theme_stylebox_override("panel", _style(Color("111522"), GOLD, 3, 8))
	panel_root.add_child(shell)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	shell.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "INVENTORY"
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_font_size_override("font_size", 22)
	header.add_child(title)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(space)
	status = Label.new()
	status.add_theme_color_override("font_color", MUTED)
	header.add_child(status)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 10)
	root.add_child(columns)
	var left := PanelContainer.new()
	left.custom_minimum_size = Vector2(190, 0)
	left.add_theme_stylebox_override("panel", _style(Color("171a29"), Color("536080"), 2, 4))
	columns.add_child(left)
	effects = VBoxContainer.new()
	left.add_child(effects)
	var effect_title := Label.new()
	effect_title.text = "COMBO EFFECT"
	effect_title.add_theme_color_override("font_color", GOLD)
	effects.add_child(effect_title)
	var center := PanelContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_stylebox_override("panel", _style(Color("24283a"), Color("536080"), 2, 4))
	columns.add_child(center)
	var center_box := VBoxContainer.new()
	center.add_child(center_box)
	var bag_title := Label.new()
	bag_title.text = "BAG  •  WEAPONS / RELICS / UPGRADES"
	bag_title.add_theme_color_override("font_color", TEXT)
	center_box.add_child(bag_title)
	grid = GridContainer.new()
	grid.columns = 6
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	center_box.add_child(grid)
	var right := PanelContainer.new()
	right.custom_minimum_size = Vector2(238, 0)
	right.add_theme_stylebox_override("panel", _style(Color("171a29"), Color("d28b48"), 2, 4))
	columns.add_child(right)
	var details := VBoxContainer.new()
	right.add_child(details)
	detail_title = Label.new()
	detail_title.text = "SELECT AN ITEM"
	detail_title.add_theme_color_override("font_color", GOLD)
	detail_title.add_theme_font_size_override("font_size", 16)
	details.add_child(detail_title)
	detail_body = Label.new()
	detail_body.text = "Collected gear and upgrades\nwill appear in the bag."
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_body.add_theme_color_override("font_color", TEXT)
	details.add_child(detail_body)

func _refresh() -> void:
	for child in grid.get_children(): child.queue_free()
	for child in effects.get_children():
		if child != effects.get_child(0): child.queue_free()
	var player := get_tree().get_first_node_in_group("player") as Node
	if not is_instance_valid(player): return
	status.text = "HP %d/%d   GOLD %d   •   TAB / ESC" % [int(player.get("health")), int(player.get("max_health")), int(player.call("get_gold"))]
	var items: Array[Dictionary] = []
	var weapons := player.get("weapon_system") as Node
	if is_instance_valid(weapons):
		for id in weapons.call("get_weapon_order"):
			var weapon: Dictionary = weapons.call(
				"get_weapon",
				str(id)
			)
			var weapon_name: String = str(
				weapon.get(
					"name",
					str(id).replace("_", " ").to_upper()
				)
			)
			items.append({"kind":"WEAPON", "name":weapon_name, "desc":"Equipped weapon."})
	var relics := get_tree().get_first_node_in_group("relic_system") as Node
	if is_instance_valid(relics):
		var catalog: Dictionary = relics.call("get_catalog")
		for key in (relics.get("acquired_relics") as Dictionary).keys():
			var data: Dictionary = catalog.get(str(key), {})
			items.append({"kind":"RELIC", "name":str(data.get("name", key)), "desc":str(data.get("description", ""))})
	var upgrades := player.get("upgrade_system") as Node
	if is_instance_valid(upgrades):
		var all: Dictionary = upgrades.get("upgrades")
		for key in all.keys():
			var count := int(upgrades.call("get_stack_count", str(key)))
			if count > 0: items.append({"kind":"UPGRADE", "name":str(all[key].get("name", key)), "desc":"%s\nSTACK %d" % [all[key].get("description", ""), count]})
	for item in items:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(58, 58)
		slot.text = "%s\n%s" % [str(item.kind).substr(0, 1), str(item.name).substr(0, 8)]
		slot.add_theme_font_size_override("font_size", 9)
		slot.add_theme_stylebox_override("normal", _style(Color("292e49"), Color("63729d"), 1, 3))
		slot.pressed.connect(_show_detail.bind(item))
		grid.add_child(slot)
	for i in range(30 - items.size()):
		var empty := Label.new()
		empty.custom_minimum_size = Vector2(58, 58)
		empty.text = "+1" if i == 0 else ""
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", MUTED)
		empty.add_theme_stylebox_override("normal", _style(Color("1b1e30"), Color("343b5b"), 1, 3))
		grid.add_child(empty)
	for kind in ["WEAPON", "RELIC", "UPGRADE"]:
		var line := Label.new()
		var count := 0
		for item in items:
			if item.kind == kind: count += 1
		line.text = "%s   %d" % [kind, count]
		line.add_theme_color_override("font_color", TEXT)
		effects.add_child(line)

func _show_detail(item: Dictionary) -> void:
	detail_title.text = "%s\n%s" % [item.kind, item.name]
	detail_body.text = item.desc

func _toggle() -> void:
	if open: _close(); return
	open = true
	panel_root.visible = true
	get_tree().paused = true
	_refresh()

func _close() -> void:
	open = false
	panel_root.visible = false
	get_tree().paused = false

func _style(color: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_top = 7
	style.content_margin_right = 8
	style.content_margin_bottom = 7
	return style
