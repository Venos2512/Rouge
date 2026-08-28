extends SceneTree


const OUTPUT_DIR := "res://gungeon_proto/assets/sample"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(OUTPUT_DIR)
	)
	_save_player()
	_save_floor()
	_save_background()
	print("SAMPLE_ART_OK")
	quit(0)


func _save_player() -> void:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	_fill_rect(image, Rect2i(8, 23, 16, 5), Color8(10, 10, 14, 150))
	_fill_rect(image, Rect2i(9, 8, 14, 15), Color8(61, 157, 210))
	_fill_rect(image, Rect2i(11, 9, 10, 5), Color8(110, 206, 238))
	_fill_rect(image, Rect2i(12, 15, 2, 2), Color8(15, 22, 28))
	_fill_rect(image, Rect2i(18, 15, 2, 2), Color8(15, 22, 28))
	_fill_circle(image, Vector2i(16, 19), 2, Color8(45, 112, 158))
	image.save_png(OUTPUT_DIR + "/player_sample.png")


func _save_floor() -> void:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color8(255, 255, 255))
	_fill_rect(image, Rect2i(0, 0, 32, 1), Color8(210, 210, 210))
	_fill_rect(image, Rect2i(0, 0, 1, 32), Color8(210, 210, 210))
	_fill_rect(image, Rect2i(8, 8, 3, 3), Color8(235, 235, 235))
	_fill_circle(image, Vector2i(24, 23), 2, Color8(220, 220, 220))
	image.save_png(OUTPUT_DIR + "/room_floor_sample.png")


func _save_background() -> void:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color8(255, 255, 255))
	_fill_rect(image, Rect2i(3, 4, 4, 4), Color8(220, 220, 220))
	_fill_rect(image, Rect2i(20, 15, 6, 6), Color8(190, 190, 190))
	_fill_circle(image, Vector2i(12, 25), 2, Color8(230, 230, 230))
	image.save_png(OUTPUT_DIR + "/world_background_sample.png")


func _fill_rect(
	image: Image,
	rect: Rect2i,
	color: Color
) -> void:
	image.fill_rect(rect, color)


func _fill_circle(
	image: Image,
	center: Vector2i,
	radius: int,
	color: Color
) -> void:
	for y: int in range(center.y - radius, center.y + radius + 1):
		for x: int in range(center.x - radius, center.x + radius + 1):
			if Vector2i(x, y).distance_squared_to(center) <= radius * radius:
				image.set_pixel(x, y, color)
