extends RefCounted


const SELF_PATH := (
	"res://gungeon_proto/scripts/debug/"
	+ "reference_path_migrator.gd"
)


const PATH_MAP := {
	"res://gungeon_proto/dungeon_main_m5.gd":
		"res://gungeon_proto/scripts/core/dungeon_main_m5.gd",

	"res://gungeon_proto/game_input.gd":
		"res://gungeon_proto/scripts/core/game_input.gd",

	"res://gungeon_proto/game_input_v2.gd":
		"res://gungeon_proto/scripts/core/game_input_v2.gd",

	"res://gungeon_proto/game_input_bootstrap.gd":
		"res://gungeon_proto/scripts/core/game_input_bootstrap.gd",

	"res://gungeon_proto/controller_gameplay_bridge.gd":
		"res://gungeon_proto/scripts/core/controller_gameplay_bridge.gd",

	"res://gungeon_proto/runtime_validator.gd":
		"res://gungeon_proto/scripts/core/runtime_validator.gd",

	"res://gungeon_proto/player.gd":
		"res://gungeon_proto/scripts/player/player.gd",

	"res://gungeon_proto/upgrade_system.gd":
		"res://gungeon_proto/scripts/player/upgrade_system.gd",

	"res://gungeon_proto/currency_system.gd":
		"res://gungeon_proto/scripts/player/currency_system.gd",

	"res://gungeon_proto/weapon_system.gd":
		"res://gungeon_proto/scripts/weapons/weapon_system.gd",

	"res://gungeon_proto/weapon_pickup.gd":
		"res://gungeon_proto/scripts/weapons/weapon_pickup.gd",

	"res://gungeon_proto/weapon_special_controller.gd":
		"res://gungeon_proto/scripts/weapons/weapon_special_controller.gd",

	"res://gungeon_proto/bullet.gd":
		"res://gungeon_proto/scripts/weapons/projectiles/bullet.gd",

	"res://gungeon_proto/enemy_bullet.gd":
		"res://gungeon_proto/scripts/weapons/projectiles/enemy_bullet.gd",

	"res://gungeon_proto/parry_counter_projectile.gd":
		"res://gungeon_proto/scripts/weapons/projectiles/parry_counter_projectile.gd",

	"res://gungeon_proto/spear_special_projectile.gd":
		"res://gungeon_proto/scripts/weapons/projectiles/spear_special_projectile.gd",

	"res://gungeon_proto/melee_attack_system.gd":
		"res://gungeon_proto/scripts/weapons/melee/melee_attack_system.gd",

	"res://gungeon_proto/melee_attack_fx.gd":
		"res://gungeon_proto/scripts/weapons/melee/melee_attack_fx.gd",

	"res://gungeon_proto/hammer_airborne_actor.gd":
		"res://gungeon_proto/scripts/weapons/melee/hammer_airborne_actor.gd",

	"res://gungeon_proto/hammer_spin_fx.gd":
		"res://gungeon_proto/scripts/weapons/melee/hammer_spin_fx.gd",

	"res://gungeon_proto/milestone14_combat.gd":
		"res://gungeon_proto/scripts/weapons/melee/milestone14_combat.gd",

	"res://gungeon_proto/milestone14_fx.gd":
		"res://gungeon_proto/scripts/weapons/melee/milestone14_fx.gd",

	"res://gungeon_proto/enemy_m5.gd":
		"res://gungeon_proto/scripts/enemies/base/enemy_actor_base.gd",

	"res://gungeon_proto/boss_m5.gd":
		"res://gungeon_proto/scripts/enemies/boss_m5.gd",

	"res://gungeon_proto/room_navigation.gd":
		"res://gungeon_proto/scripts/dungeon/room_navigation.gd",

	"res://gungeon_proto/encounter_director.gd":
		"res://gungeon_proto/scripts/dungeon/encounter_director.gd",

	"res://gungeon_proto/room_boundary_blocker.gd":
		"res://gungeon_proto/scripts/dungeon/room_boundary_blocker.gd",

	"res://gungeon_proto/room_wall.gd":
		"res://gungeon_proto/scripts/dungeon/room_wall.gd",

	"res://gungeon_proto/room_flow_director.gd":
		"res://gungeon_proto/scripts/dungeon/room_flow_director.gd",

	"res://gungeon_proto/dungeon_generator.gd":
		"res://gungeon_proto/scripts/dungeon/dungeon_generator.gd",

	"res://gungeon_proto/room_director.gd":
		"res://gungeon_proto/scripts/dungeon/room_director.gd",

	"res://gungeon_proto/room_visual_scene_controller.gd":
		"res://gungeon_proto/scripts/dungeon/room_visual_scene_controller.gd",

	"res://gungeon_proto/relic_system.gd":
		"res://gungeon_proto/scripts/gameplay/relic_system.gd",

	"res://gungeon_proto/gameplay_spawner.gd":
		"res://gungeon_proto/scripts/gameplay/gameplay_spawner.gd",

	"res://gungeon_proto/floor_exit.gd":
		"res://gungeon_proto/scripts/gameplay/floor_exit.gd",

	"res://gungeon_proto/upgrade_chest.gd":
		"res://gungeon_proto/scripts/gameplay/upgrade_chest.gd",

	"res://gungeon_proto/coin_pickup.gd":
		"res://gungeon_proto/scripts/gameplay/coin_pickup.gd",

	"res://gungeon_proto/shop_item.gd":
		"res://gungeon_proto/scripts/gameplay/shop_item.gd",

	"res://gungeon_proto/room_fx.gd":
		"res://gungeon_proto/scripts/gameplay/room_fx.gd",

	"res://gungeon_proto/damage_number.gd":
		"res://gungeon_proto/scripts/gameplay/damage_number.gd",

	"res://gungeon_proto/spike_trap.gd":
		"res://gungeon_proto/scripts/gameplay/spike_trap.gd",

	"res://gungeon_proto/saw_trap.gd":
		"res://gungeon_proto/scripts/gameplay/saw_trap.gd",

	"res://gungeon_proto/shop_director.gd":
		"res://gungeon_proto/scripts/dungeon/shop_director.gd",

	"res://gungeon_proto/reward_director.gd":
		"res://gungeon_proto/scripts/dungeon/reward_director.gd",

	"res://gungeon_proto/room_prop.gd":
		"res://gungeon_proto/scripts/props/room_prop.gd",

	"res://gungeon_proto/explosive_barrel.gd":
		"res://gungeon_proto/scripts/props/explosive_barrel_legacy.gd",

	"res://gungeon_proto/carryable_prop_v3.gd":
		"res://gungeon_proto/scripts/props/carryable_prop_v3.gd",

	"res://gungeon_proto/carryable_explosive_barrel_v3.gd":
		"res://gungeon_proto/scripts/props/carryable_explosive_barrel_v3.gd",

	"res://gungeon_proto/dungeon_minimap_m5.gd":
		"res://gungeon_proto/scripts/ui/dungeon_minimap_m5.gd",

	"res://gungeon_proto/upgrade_choice_ui.gd":
		"res://gungeon_proto/scripts/ui/upgrade_choice_ui.gd",

	"res://gungeon_proto/dungeon_hud_controller.gd":
		"res://gungeon_proto/scripts/ui/dungeon_hud_controller.gd",

	"res://gungeon_proto/weapon_stack_hud_v2.gd":
		"res://gungeon_proto/scripts/ui/weapon_stack_hud_v2.gd",

	"res://gungeon_proto/reload_progress_world.gd":
		"res://gungeon_proto/scripts/ui/reload_progress_world.gd",

	"res://gungeon_proto/game_hud_icon.gd":
		"res://gungeon_proto/scripts/ui/game_hud_icon.gd",

	"res://gungeon_proto/main_menu_overlay.gd":
		"res://gungeon_proto/scripts/ui/main_menu_overlay.gd",

	"res://gungeon_proto/minimap_top_right_anchor.gd":
		"res://gungeon_proto/scripts/ui/minimap_top_right_anchor.gd",

	"res://gungeon_proto/weapon_special_progress.gd":
		"res://gungeon_proto/scripts/ui/weapon_special_progress.gd",

	"res://gungeon_proto/pause_settings_menu.gd":
		"res://gungeon_proto/scripts/ui/pause_settings_menu.gd",

	"res://gungeon_proto/dev_tools.gd":
		"res://gungeon_proto/scripts/debug/dev_tools.gd",

	"res://gungeon_proto/training_arena_v2.gd":
		"res://gungeon_proto/scripts/debug/training/training_arena_v2.gd",

	"res://gungeon_proto/training_camera.gd":
		"res://gungeon_proto/scripts/debug/training/training_camera.gd",

	"res://gungeon_proto/training_dummy.gd":
		"res://gungeon_proto/scripts/debug/training/training_dummy.gd",

	"res://gungeon_proto/training_dummy_v2.gd":
		"res://gungeon_proto/scripts/debug/training/training_dummy_v2.gd",

	"res://gungeon_proto/training_editor_label.gd":
		"res://gungeon_proto/scripts/debug/training/training_editor_label.gd",

	"res://gungeon_proto/training_room_controller.gd":
		"res://gungeon_proto/scripts/debug/training/training_room_controller.gd",

	"res://gungeon_proto/training_room_controller_v2.gd":
		"res://gungeon_proto/scripts/debug/training/training_room_controller_v2.gd",

	"res://gungeon_proto/training_room_editor_floor.gd":
		"res://gungeon_proto/scripts/debug/training/training_room_editor_floor.gd",

	"res://gungeon_proto/training_room_layout.gd":
		"res://gungeon_proto/scripts/debug/training/training_room_layout.gd",

	"res://gungeon_proto/training_test_bullet.gd":
		"res://gungeon_proto/scripts/debug/training/training_test_bullet.gd",

	"res://gungeon_proto/training_turret.gd":
		"res://gungeon_proto/scripts/debug/training/training_turret.gd"
}


const SHIM_CANDIDATES := [
	"res://gungeon_proto/bullet.gd",
	"res://gungeon_proto/enemy_bullet.gd",
	"res://gungeon_proto/explosive_barrel.gd",
	"res://gungeon_proto/game_input.gd",
	"res://gungeon_proto/game_input_v2.gd",
	"res://gungeon_proto/hammer_airborne_actor.gd",
	"res://gungeon_proto/hammer_spin_fx.gd",
	"res://gungeon_proto/melee_attack_fx.gd",
	"res://gungeon_proto/melee_attack_system.gd",
	"res://gungeon_proto/milestone14_combat.gd",
	"res://gungeon_proto/milestone14_fx.gd",
	"res://gungeon_proto/parry_counter_projectile.gd",
	"res://gungeon_proto/pause_settings_menu.gd",
	"res://gungeon_proto/room_prop.gd",
	"res://gungeon_proto/spear_special_projectile.gd",
	"res://gungeon_proto/training_arena_v2.gd",
	"res://gungeon_proto/training_camera.gd",
	"res://gungeon_proto/training_dummy.gd",
	"res://gungeon_proto/training_dummy_v2.gd",
	"res://gungeon_proto/training_editor_label.gd",
	"res://gungeon_proto/training_room_controller.gd",
	"res://gungeon_proto/training_room_controller_v2.gd",
	"res://gungeon_proto/training_room_editor_floor.gd",
	"res://gungeon_proto/training_room_layout.gd",
	"res://gungeon_proto/training_test_bullet.gd",
	"res://gungeon_proto/training_turret.gd",
	"res://gungeon_proto/weapon_special_progress.gd",
	"res://gungeon_proto/dungeon_minimap_m5.gd",
	"res://gungeon_proto/upgrade_choice_ui.gd"
]


static func run() -> void:
	var files: Array[String] = []

	_collect_text_files(
		"res://gungeon_proto",
		files
	)

	if FileAccess.file_exists(
		"res://project.godot"
	):
		files.append(
			"res://project.godot"
		)

	var changed_files: int = 0
	var replaced_references: int = 0

	for file_path: String in files:
		if file_path == SELF_PATH:
			continue

		var result: Dictionary = (
			_migrate_file(
				file_path
			)
		)

		if bool(
			result.get(
				"changed",
				false
			)
		):
			changed_files += 1

		replaced_references += int(
			result.get(
				"count",
				0
			)
		)

	# Không xóa shim trong lúc game đang chạy.
	# ResourceLoader có thể vẫn giữ resource cũ trong cache
	# của chính frame/lần chạy migration này.
	var deleted_shims: int = 0

	_delete_file_if_exists(
		"res://gungeon_proto/bridge_move_test_moved.txt"
	)

	var unresolved: Dictionary = (
		_find_remaining_root_script_references(
			files
		)
	)

	print(
		"[ReferencePathMigrator] changed files: ",
		changed_files,
		", replaced refs: ",
		replaced_references,
		", deleted shims: ",
		deleted_shims
	)

	if unresolved.is_empty():
		print(
			"[ReferencePathMigrator] "
			+ "ROOT SCRIPT REFERENCES CLEAN."
		)

	else:
		push_warning(
			"[ReferencePathMigrator] "
			+ "Còn root script reference chưa map:"
		)

		for reference_value in unresolved.keys():
			var reference: String = str(
				reference_value
			)

			var owners: Array = (
				unresolved[
					reference_value
				]
			)

			push_warning(
				reference
				+ " <- "
				+ ", ".join(
					owners
				)
			)


static func _collect_text_files(
	directory_path: String,
	result: Array[String]
) -> void:
	var directory := DirAccess.open(
		directory_path
	)

	if directory == null:
		push_error(
			"[ReferencePathMigrator] "
			+ "Không mở được: "
			+ directory_path
		)

		return

	directory.list_dir_begin()

	var entry_name: String = (
		directory.get_next()
	)

	while not entry_name.is_empty():
		if (
			entry_name == "."
			or entry_name == ".."
		):
			entry_name = (
				directory.get_next()
			)

			continue

		var full_path: String = (
			directory_path.path_join(
				entry_name
			)
		)

		if directory.current_is_dir():
			if not entry_name.begins_with(
				"."
			):
				_collect_text_files(
					full_path,
					result
				)

		else:
			var extension: String = (
				entry_name
				.get_extension()
				.to_lower()
			)

			if extension in [
				"gd",
				"tscn",
				"tres"
			]:
				result.append(
					full_path
				)

		entry_name = (
			directory.get_next()
		)

	directory.list_dir_end()


static func _migrate_file(
	file_path: String
) -> Dictionary:
	var original: String = (
		_read_text(
			file_path
		)
	)

	if original.is_empty():
		return {
			"changed": false,
			"count": 0
		}

	var updated: String = original
	var replace_count: int = 0

	for old_value in PATH_MAP.keys():
		var old_path: String = str(
			old_value
		)

		if not updated.contains(
			old_path
		):
			continue

		var new_path: String = str(
			PATH_MAP[
				old_value
			]
		)

		replace_count += (
			updated.count(
				old_path
			)
		)

		updated = updated.replace(
			old_path,
			new_path
		)

	if updated == original:
		return {
			"changed": false,
			"count": 0
		}

	var output := FileAccess.open(
		file_path,
		FileAccess.WRITE
	)

	if output == null:
		push_error(
			"[ReferencePathMigrator] "
			+ "Không ghi được: "
			+ file_path
		)

		return {
			"changed": false,
			"count": 0
		}

	output.store_string(
		updated
	)

	output.close()

	print(
		"[ReferencePathMigrator] fixed: ",
		file_path
	)

	return {
		"changed": true,
		"count": replace_count
	}


static func _delete_unused_shims(
	files: Array[String]
) -> int:
	var deleted_count: int = 0

	for shim_value in SHIM_CANDIDATES:
		var shim_path: String = str(
			shim_value
		)

		if not FileAccess.file_exists(
			shim_path
		):
			continue

		if not PATH_MAP.has(
			shim_path
		):
			continue

		if _count_reference(
			files,
			shim_path
		) > 0:
			continue

		var target_path: String = str(
			PATH_MAP[
				shim_path
			]
		)

		if not _is_compatibility_shim(
			shim_path,
			target_path
		):
			push_warning(
				"[ReferencePathMigrator] "
				+ "Không xóa vì không phải shim: "
				+ shim_path
			)

			continue

		if _delete_file_if_exists(
			shim_path
		):
			deleted_count += 1

			_delete_file_if_exists(
				shim_path + ".uid"
			)

	return deleted_count


static func _is_compatibility_shim(
	shim_path: String,
	target_path: String
) -> bool:
	var content: String = (
		_read_text(
			shim_path
		)
		.strip_edges()
	)

	var expected: String = (
		"extends \""
		+ target_path
		+ "\""
	)

	return content == expected


static func _count_reference(
	files: Array[String],
	reference_path: String
) -> int:
	var count: int = 0

	for file_path: String in files:
		if file_path == SELF_PATH:
			continue

		if file_path == reference_path:
			continue

		if not FileAccess.file_exists(
			file_path
		):
			continue

		var content: String = (
			_read_text(
				file_path
			)
		)

		if content.is_empty():
			continue

		count += content.count(
			reference_path
		)

	return count


static func _find_remaining_root_script_references(
	files: Array[String]
) -> Dictionary:
	var result: Dictionary = {}

	var regex := RegEx.new()

	var regex_error: Error = regex.compile(
		"res://gungeon_proto/[A-Za-z0-9_]+\\.gd"
	)

	if regex_error != OK:
		return result

	for file_path: String in files:
		if file_path == SELF_PATH:
			continue

		if not FileAccess.file_exists(
			file_path
		):
			continue

		var content: String = (
			_read_text(
				file_path
			)
		)

		if content.is_empty():
			continue

		for match_value in regex.search_all(
			content
		):
			var reference: String = (
				match_value.get_string()
			)

			if not result.has(
				reference
			):
				result[
					reference
				] = []

			var owners: Array = (
				result[
					reference
				]
			)

			if not owners.has(
				file_path
			):
				owners.append(
					file_path
				)

	return result


static func _read_text(
	file_path: String
) -> String:
	var input := FileAccess.open(
		file_path,
		FileAccess.READ
	)

	if input == null:
		return ""

	var content: String = (
		input.get_as_text()
	)

	input.close()

	return content


static func _delete_file_if_exists(
	file_path: String
) -> bool:
	if not FileAccess.file_exists(
		file_path
	):
		return false

	var absolute_path: String = (
		ProjectSettings.globalize_path(
			file_path
		)
	)

	var error: Error = (
		DirAccess.remove_absolute(
			absolute_path
		)
	)

	if error != OK:
		push_warning(
			"[ReferencePathMigrator] "
			+ "Không xóa được: "
			+ file_path
		)

		return false

	print(
		"[ReferencePathMigrator] removed: ",
		file_path
	)

	return true
