extends CanvasLayer

const GameHudIconScript = preload("res://gungeon_proto/scripts/ui/game_hud_icon.gd")

@onready var health_bar: ProgressBar = $TopLeft/Content/HealthBar
@onready var health_label: Label = $TopLeft/Content/HealthLabel
@onready var gold_label: Label = $TopRight/GoldLabel
@onready var weapon_slots: Array[Label] = [$BottomRight/Content/Weapon1, $BottomRight/Content/Weapon2, $BottomRight/Content/Weapon3, $BottomRight/Content/Weapon4, $BottomRight/Content/Weapon5, $BottomRight/Content/Weapon6, $BottomRight/Content/Weapon7, $BottomRight/Content/Weapon8, $BottomRight/Content/Weapon9]
@onready var relic_slots: Array[Label] = [$TopLeft/Content/Relics/Relic1, $TopLeft/Content/Relics/Relic2, $TopLeft/Content/Relics/Relic3, $TopLeft/Content/Relics/Relic4, $TopLeft/Content/Relics/Relic5, $TopLeft/Content/Relics/Relic6]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for slot in weapon_slots:
		_add_icon(slot, "weapon")
	for slot in relic_slots:
		_add_icon(slot, "relic")
		slot.tooltip_text = ""

func _add_icon(slot: Label, category: String) -> void:
	var icon := GameHudIconScript.new() as Control
	icon.name = "Icon"
	icon.position = Vector2(0, 0)
	icon.size = Vector2(28, 28)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(icon)

func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node
	if not is_instance_valid(player):
		return
	var hp := int(player.get("health"))
	var max_hp := maxi(1, int(player.get("max_health")))
	health_bar.max_value = max_hp
	health_bar.value = hp
	health_label.text = "HP  %d / %d" % [hp, max_hp]
	gold_label.text = "GOLD  %d" % int(player.call("get_gold"))
	_update_weapons(player)
	_update_relics()

func _update_weapons(player: Node) -> void:
	var system := player.get("weapon_system") as Node
	for slot in weapon_slots:
		slot.text = ""
		slot.visible = false
		(slot.get_node_or_null("Icon") as Control).visible = false
	if not is_instance_valid(system):
		return
	var order: Array[String] = system.call("get_weapon_order")
	for index in mini(order.size(), weapon_slots.size()):
		var id := order[index]
		weapon_slots[index].text = "     %d  %s" % [index + 1, id.replace("_", " ").to_upper()]
		var weapon_icon := weapon_slots[index].get_node("Icon") as Control
		weapon_icon.call("configure", "weapon", id)
		weapon_icon.visible = true
		weapon_slots[index].visible = true
		if id == str(system.get("current_weapon")):
			weapon_slots[index].text = "▶ " + weapon_slots[index].text

func _update_relics() -> void:
	var system := get_tree().get_first_node_in_group("relic_system") as Node
	for slot in relic_slots:
		slot.text = ""
		slot.visible = false
		(slot.get_node_or_null("Icon") as Control).visible = false
	if not is_instance_valid(system):
		return
	var acquired: Dictionary = system.get("acquired_relics")
	var catalog: Dictionary = system.call("get_catalog")
	var index := 0
	for key in acquired.keys():
		if index >= relic_slots.size():
			break
		var data: Dictionary = catalog.get(str(key), {})
		var relic_icon := relic_slots[index].get_node("Icon") as Control
		relic_icon.call("configure", "relic", str(key), str(data.get("rarity", "COMMON")))
		relic_icon.visible = true
		relic_slots[index].visible = true
		index += 1
