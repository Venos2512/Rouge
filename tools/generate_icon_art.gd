extends SceneTree

const ROOT := "res://gungeon_proto/assets/icons"
const SIZE := 64

func _init() -> void:
	for folder: String in ["relics", "weapons", "enemies", "upgrades"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ROOT + "/" + folder))
	_save_relic("iron_seed", Color("#d5a93b"), "seed")
	_save_relic("fleet_feather", Color("#74c8e8"), "feather")
	_save_relic("broken_hourglass", Color("#8f9be8"), "hourglass")
	_save_relic("brass_trigger", Color("#d88b42"), "trigger")
	_save_relic("lead_eye", Color("#c8d0d8"), "eye")
	_save_relic("long_fang", Color("#e6e0c5"), "fang")
	_save_relic("titan_knuckle", Color("#cf6b55"), "knuckle")
	_save_relic("powder_idol", Color("#d267d8"), "idol")
	_save_relic("deep_pockets", Color("#9b704e"), "pocket")
	_save_weapon("pistol", Color("#d7dde5"), 28, 10)
	_save_weapon("sword", Color("#b7d8e8"), 40, 4)
	_save_weapon("spear", Color("#d9b56d"), 48, 3)
	_save_weapon("hammer", Color("#cf7860"), 24, 15)
	_save_weapon("shotgun", Color("#a9c47f"), 34, 13)
	_save_weapon("machine_gun", Color("#c0a6d8"), 38, 9)
	_save_bot()
	for upgrade_id: String in ["lightweight_boots", "iron_heart", "rapid_fire", "high_velocity", "ammo_bag", "tactical_roll", "long_blade", "fast_reload", "heavy_rounds", "extended_mag", "shotgun_master", "pistol_master", "machine_master", "vital_core", "blade_master"]:
		_save_upgrade(upgrade_id)
	print("ICON_ART_OK")
	quit(0)

func _new_image() -> Image:
	var image := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	return image

func _save_relic(id: String, color: Color, shape: String) -> void:
	var image := _new_image()
	image.fill_rect(Rect2i(5, 5, 54, 54), Color("#171923"))
	match shape:
		"seed": _fill_circle(image, Vector2i(32, 34), 13, color)
		"feather":
			_fill_polygon(image, PackedVector2Array([Vector2(14, 48), Vector2(48, 12), Vector2(43, 39), Vector2(22, 53)]), color)
		"hourglass":
			_fill_polygon(image, PackedVector2Array([Vector2(14, 14), Vector2(50, 14), Vector2(32, 32)]), color)
			_fill_polygon(image, PackedVector2Array([Vector2(32, 32), Vector2(14, 50), Vector2(50, 50)]), color)
		"trigger": image.fill_rect(Rect2i(16, 20, 28, 28), color)
		"eye":
			_fill_circle(image, Vector2i(32, 32), 19, color)
			_fill_circle(image, Vector2i(32, 32), 7, Color("#171923"))
		"fang": _fill_polygon(image, PackedVector2Array([Vector2(17, 13), Vector2(48, 18), Vector2(32, 52)]), color)
		"knuckle": image.fill_rect(Rect2i(13, 26, 38, 22), color)
		"idol": _fill_circle(image, Vector2i(32, 35), 15, color)
		"pocket": image.fill_rect(Rect2i(14, 21, 36, 29), color)
	image.save_png(ROOT + "/relics/" + id + ".png")

func _fill_circle(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y: int in range(center.y - radius, center.y + radius + 1):
		for x: int in range(center.x - radius, center.x + radius + 1):
			if Vector2i(x, y).distance_squared_to(center) <= radius * radius:
				image.set_pixel(x, y, color)

func _fill_polygon(image: Image, points: PackedVector2Array, color: Color) -> void:
	var min_y := SIZE
	var max_y := 0
	for point: Vector2 in points:
		min_y = mini(min_y, int(point.y))
		max_y = maxi(max_y, int(point.y))
	for y: int in range(min_y, max_y + 1):
		var intersections: Array[float] = []
		for index: int in points.size():
			var a: Vector2 = points[index]
			var b: Vector2 = points[(index + 1) % points.size()]
			if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
				intersections.append(a.x + (y - a.y) * (b.x - a.x) / (b.y - a.y))
		intersections.sort()
		for index: int in range(0, intersections.size() - 1, 2):
			for x: int in range(int(ceil(intersections[index])), int(floor(intersections[index + 1])) + 1):
				image.set_pixel(x, y, color)

func _save_weapon(id: String, color: Color, length: int, thickness: int) -> void:
	var image := _new_image()
	image.fill_rect(Rect2i(5, 5, 54, 54), Color("#171923"))
	image.fill_rect(Rect2i(32 - length / 2, 29, length, thickness), color)
	image.fill_rect(Rect2i(25, 38, 9, 16), color.darkened(0.25))
	image.save_png(ROOT + "/weapons/weapon_" + id + ".png")

func _save_bot() -> void:
	var image := _new_image()
	image.fill_rect(Rect2i(5, 5, 54, 54), Color("#171923"))
	image.fill_rect(Rect2i(15, 18, 34, 29), Color("#d4574f"))
	image.fill_rect(Rect2i(21, 25, 7, 7), Color("#ffe27a"))
	image.fill_rect(Rect2i(36, 25, 7, 7), Color("#ffe27a"))
	image.fill_rect(Rect2i(28, 47, 8, 7), Color("#8e313d"))
	image.save_png(ROOT + "/enemies/suicide_bot.png")

func _save_upgrade(id: String) -> void:
	var image := _new_image()
	image.fill_rect(Rect2i(5, 5, 54, 54), Color("#171923"))
	var color := Color.from_hsv(float(abs(id.hash()) % 360) / 360.0, 0.55, 0.9)
	image.fill_rect(Rect2i(17, 17, 30, 30), color)
	image.fill_rect(Rect2i(27, 11, 10, 42), color.lightened(0.2))
	image.fill_rect(Rect2i(11, 27, 42, 10), color.lightened(0.2))
	image.save_png(ROOT + "/upgrades/" + id + ".png")
