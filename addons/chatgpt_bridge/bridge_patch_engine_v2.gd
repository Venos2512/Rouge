@tool
extends RefCounted


const PROTOCOL_HEADER := "CHATGPT_BRIDGE_PATCH_V1"
const BACKUP_FILE := "user://chatgpt_bridge/last_backup.json"

# Quan trọng:
# Không viết literal marker protocol hoàn chỉnh trong source file này.
# Bridge V1 cũ quét text thô và có thể hiểu marker nằm trong source
# là operation thật.
const OPEN_MARKER := "<<" + "<"
const CLOSE_MARKER := ">" + ">>"

const REPLACE_PREFIX := OPEN_MARKER + "REPLACE_IN_FILE "
const CREATE_PREFIX := OPEN_MARKER + "CREATE_FILE "
const MOVE_PREFIX := OPEN_MARKER + "MOVE_FILE "
const DELETE_PREFIX := OPEN_MARKER + "DELETE_FILE "

const SEARCH_MARKER := OPEN_MARKER + "SEARCH" + CLOSE_MARKER
const WITH_MARKER := OPEN_MARKER + "WITH" + CLOSE_MARKER
const TO_MARKER := OPEN_MARKER + "TO" + CLOSE_MARKER
const END_MARKER := OPEN_MARKER + "END" + CLOSE_MARKER
const END_FILE_MARKER := OPEN_MARKER + "END_FILE" + CLOSE_MARKER

const TEXT_EXTENSIONS: Array[String] = [
	"gd",
	"tscn",
	"tres",
	"gdshader",
	"shader",
	"cfg",
	"json",
	"txt",
	"md",
]


static func protocol_help() -> String:
	var open_marker: String = "<<" + "<"
	var close_marker: String = ">" + ">>"

	return (
		"## PATCH PROTOCOL V1+\n\n"
		+ "Bridge vẫn dùng header CHATGPT_BRIDGE_PATCH_V1.\n\n"
		+ "Supported operations:\n\n"
		+ open_marker
		+ "CREATE_FILE res://path/file.gd"
		+ close_marker
		+ "\n"
		+ "content\n"
		+ open_marker
		+ "END_FILE"
		+ close_marker
		+ "\n\n"
		+ open_marker
		+ "REPLACE_IN_FILE res://path/file.gd"
		+ close_marker
		+ "\n"
		+ open_marker
		+ "SEARCH"
		+ close_marker
		+ "\nold\n"
		+ open_marker
		+ "WITH"
		+ close_marker
		+ "\nnew\n"
		+ open_marker
		+ "END"
		+ close_marker
		+ "\n\n"
		+ open_marker
		+ "MOVE_FILE res://old/file.gd"
		+ close_marker
		+ "\n"
		+ open_marker
		+ "TO"
		+ close_marker
		+ "\nres://new/file.gd\n"
		+ open_marker
		+ "END"
		+ close_marker
		+ "\n\n"
		+ open_marker
		+ "DELETE_FILE res://path/file.gd"
		+ close_marker
		+ "\n"
		+ open_marker
		+ "END"
		+ close_marker
		+ "\n\n"
		+ "Rules:\n"
		+ "- res:// only\n"
		+ "- không cho phép ..\n"
		+ "- SEARCH phải match đúng 1 lần\n"
		+ "- CREATE destination không được tồn tại\n"
		+ "- MOVE source phải tồn tại\n"
		+ "- MOVE destination không được tồn tại\n"
		+ "- DELETE target phải tồn tại\n"
		+ "- MOVE/DELETE tự backup\n"
		+ "- MOVE/DELETE không được tác động addon ChatGPT Bridge\n"
		+ "- MOVE tự chuyển sidecar .uid nếu có\n"
	)


func parse_and_simulate(
	text: String
) -> Dictionary:
	var parsed: Dictionary = _parse_patch(
		text
	)

	if not bool(
		parsed.get(
			"ok",
			false
		)
	):
		return parsed

	var operations: Array = parsed.get(
		"ops",
		[]
	)

	var virtual_files: Dictionary = {}
	var report: PackedStringArray = []

	report.append(
		"PATCH V1+ PREVIEW"
	)

	report.append(
		"Operations: %d"
		% operations.size()
	)

	report.append("")

	for operation_value: Variant in operations:
		if typeof(
			operation_value
		) != TYPE_DICTIONARY:
			return _error(
				"Operation không phải Dictionary."
			)

		var operation: Dictionary = (
			operation_value
		)

		var result: Dictionary = (
			_simulate_operation(
				operation,
				virtual_files
			)
		)

		if not bool(
			result.get(
				"ok",
				false
			)
		):
			return result

		report.append(
			str(
				result.get(
					"report",
					""
				)
			)
		)

	report.append("")
	report.append(
		"Sẵn sàng Apply."
	)

	return {
		"ok": true,
		"ops": operations,
		"report": "\n".join(
			report
		),
	}


func apply_patch(
	text: String
) -> Dictionary:
	var simulation: Dictionary = (
		parse_and_simulate(
			text
		)
	)

	if not bool(
		simulation.get(
			"ok",
			false
		)
	):
		return simulation

	var operations: Array = simulation.get(
		"ops",
		[]
	)

	if operations.is_empty():
		return _error(
			"Không có operation để Apply."
		)

	var backup_result: Dictionary = (
		_build_backup(
			operations
		)
	)

	if not bool(
		backup_result.get(
			"ok",
			false
		)
	):
		return backup_result

	var backup: Dictionary = (
		backup_result.get(
			"backup",
			{}
		)
	)

	if not _save_backup(
		backup
	):
		return _error(
			"Không thể lưu backup. Apply đã bị hủy."
		)

	var result: Dictionary = (
		_apply_operations(
			operations
		)
	)

	if not bool(
		result.get(
			"ok",
			false
		)
	):
		var rollback_ok: bool = (
			_restore_backup(
				backup
			)
		)

		var rollback_message: String = (
			"Rollback thành công."
			if rollback_ok
			else "Rollback gặp lỗi."
		)

		return _error(
			str(
				result.get(
					"report",
					"Apply thất bại."
				)
			)
			+ "\n"
			+ rollback_message
		)

	return {
		"ok": true,
		"applied_count": operations.size(),
		"report": (
			str(
				simulation.get(
					"report",
					""
				)
			)
			+ "\n\nĐã Apply thành công."
		),
	}


func undo_last() -> Dictionary:
	var backup: Dictionary = (
		_load_backup()
	)

	if backup.is_empty():
		return _error(
			"Chưa có backup để Undo."
		)

	if not _restore_backup(
		backup
	):
		return _error(
			"Undo gặp lỗi khi khôi phục file."
		)

	_remove_backup_file()

	return {
		"ok": true,
		"report": "Đã Undo thay đổi gần nhất."
	}


func _parse_patch(
	text: String
) -> Dictionary:
	var normalized: String = text.replace(
		"\r\n",
		"\n"
	)

	var header_position: int = (
		normalized.find(
			PROTOCOL_HEADER
		)
	)

	if header_position < 0:
		return _error(
			"Không thấy "
			+ PROTOCOL_HEADER
		)

	var cursor: int = (
		header_position
		+ PROTOCOL_HEADER.length()
	)

	var operations: Array = []

	while true:
		var next_operation: Dictionary = (
			_find_next_operation(
				normalized,
				cursor
			)
		)

		var position: int = int(
			next_operation.get(
				"position",
				-1
			)
		)

		if position < 0:
			break

		var operation_type: String = str(
			next_operation.get(
				"type",
				""
			)
		)

		var parsed: Dictionary

		match operation_type:
			"replace":
				parsed = _parse_replace(
					normalized,
					position
				)

			"create":
				parsed = _parse_create(
					normalized,
					position
				)

			"move":
				parsed = _parse_move(
					normalized,
					position
				)

			"delete":
				parsed = _parse_delete(
					normalized,
					position
				)

			_:
				return _error(
					"Operation marker không hợp lệ."
				)

		if not bool(
			parsed.get(
				"ok",
				false
			)
		):
			return parsed

		operations.append(
			parsed.get(
				"op",
				{}
			)
		)

		cursor = int(
			parsed.get(
				"cursor",
				normalized.length()
			)
		)

	if operations.is_empty():
		return _error(
			"Không tìm thấy operation nào."
		)

	return {
		"ok": true,
		"ops": operations,
	}


func _find_next_operation(
	text: String,
	cursor: int
) -> Dictionary:
	var candidates: Array[Dictionary] = [
		{
			"type": "replace",
			"position": text.find(
				REPLACE_PREFIX,
				cursor
			)
		},
		{
			"type": "create",
			"position": text.find(
				CREATE_PREFIX,
				cursor
			)
		},
		{
			"type": "move",
			"position": text.find(
				MOVE_PREFIX,
				cursor
			)
		},
		{
			"type": "delete",
			"position": text.find(
				DELETE_PREFIX,
				cursor
			)
		},
	]

	var best_position: int = -1
	var best_type: String = ""

	for candidate: Dictionary in candidates:
		var position: int = int(
			candidate.get(
				"position",
				-1
			)
		)

		if position < 0:
			continue

		if (
			best_position < 0
			or position < best_position
		):
			best_position = position
			best_type = str(
				candidate.get(
					"type",
					""
				)
			)

	return {
		"type": best_type,
		"position": best_position,
	}


func _parse_replace(
	text: String,
	start_position: int
) -> Dictionary:
	var path_result: Dictionary = (
		_parse_header_path(
			text,
			start_position,
			REPLACE_PREFIX
		)
	)

	if not bool(
		path_result.get(
			"ok",
			false
		)
	):
		return path_result

	var path: String = str(
		path_result.get(
			"path",
			""
		)
	)

	var header_end: int = int(
		path_result.get(
			"cursor",
			0
		)
	)

	var search_position: int = text.find(
		SEARCH_MARKER,
		header_end
	)

	if search_position < 0:
		return _error(
			"REPLACE thiếu SEARCH: "
			+ path
		)

	var with_position: int = text.find(
		WITH_MARKER,
		search_position
		+ SEARCH_MARKER.length()
	)

	if with_position < 0:
		return _error(
			"REPLACE thiếu WITH: "
			+ path
		)

	var end_position: int = text.find(
		END_MARKER,
		with_position
		+ WITH_MARKER.length()
	)

	if end_position < 0:
		return _error(
			"REPLACE thiếu END: "
			+ path
		)

	var search_start: int = (
		search_position
		+ SEARCH_MARKER.length()
	)

	search_start = _skip_one_newline(
		text,
		search_start
	)

	var with_start: int = (
		with_position
		+ WITH_MARKER.length()
	)

	with_start = _skip_one_newline(
		text,
		with_start
	)

	var search_text: String = text.substr(
		search_start,
		with_position - search_start
	)

	search_text = _remove_one_trailing_newline(
		search_text
	)

	var replacement_text: String = text.substr(
		with_start,
		end_position - with_start
	)

	replacement_text = (
		_remove_one_trailing_newline(
			replacement_text
		)
	)

	return {
		"ok": true,
		"op": {
			"type": "replace",
			"path": path,
			"search": search_text,
			"with": replacement_text,
		},
		"cursor": (
			end_position
			+ END_MARKER.length()
		),
	}


func _parse_create(
	text: String,
	start_position: int
) -> Dictionary:
	var path_result: Dictionary = (
		_parse_header_path(
			text,
			start_position,
			CREATE_PREFIX
		)
	)

	if not bool(
		path_result.get(
			"ok",
			false
		)
	):
		return path_result

	var path: String = str(
		path_result.get(
			"path",
			""
		)
	)

	var content_start: int = int(
		path_result.get(
			"cursor",
			0
		)
	)

	content_start = _skip_one_newline(
		text,
		content_start
	)

	var end_position: int = text.find(
		END_FILE_MARKER,
		content_start
	)

	if end_position < 0:
		return _error(
			"CREATE_FILE thiếu END_FILE: "
			+ path
		)

	var content: String = text.substr(
		content_start,
		end_position - content_start
	)

	content = _remove_one_trailing_newline(
		content
	)

	return {
		"ok": true,
		"op": {
			"type": "create",
			"path": path,
			"content": content,
		},
		"cursor": (
			end_position
			+ END_FILE_MARKER.length()
		),
	}


func _parse_move(
	text: String,
	start_position: int
) -> Dictionary:
	var path_result: Dictionary = (
		_parse_header_path(
			text,
			start_position,
			MOVE_PREFIX
		)
	)

	if not bool(
		path_result.get(
			"ok",
			false
		)
	):
		return path_result

	var source_path: String = str(
		path_result.get(
			"path",
			""
		)
	)

	var header_end: int = int(
		path_result.get(
			"cursor",
			0
		)
	)

	var to_position: int = text.find(
		TO_MARKER,
		header_end
	)

	if to_position < 0:
		return _error(
			"MOVE_FILE thiếu TO: "
			+ source_path
		)

	var end_position: int = text.find(
		END_MARKER,
		to_position
		+ TO_MARKER.length()
	)

	if end_position < 0:
		return _error(
			"MOVE_FILE thiếu END: "
			+ source_path
		)

	var destination_start: int = (
		to_position
		+ TO_MARKER.length()
	)

	destination_start = _skip_one_newline(
		text,
		destination_start
	)

	var destination_path: String = text.substr(
		destination_start,
		end_position - destination_start
	).strip_edges()

	return {
		"ok": true,
		"op": {
			"type": "move",
			"path": source_path,
			"to_path": destination_path,
		},
		"cursor": (
			end_position
			+ END_MARKER.length()
		),
	}


func _parse_delete(
	text: String,
	start_position: int
) -> Dictionary:
	var path_result: Dictionary = (
		_parse_header_path(
			text,
			start_position,
			DELETE_PREFIX
		)
	)

	if not bool(
		path_result.get(
			"ok",
			false
		)
	):
		return path_result

	var path: String = str(
		path_result.get(
			"path",
			""
		)
	)

	var header_end: int = int(
		path_result.get(
			"cursor",
			0
		)
	)

	var end_position: int = text.find(
		END_MARKER,
		header_end
	)

	if end_position < 0:
		return _error(
			"DELETE_FILE thiếu END: "
			+ path
		)

	return {
		"ok": true,
		"op": {
			"type": "delete",
			"path": path,
		},
		"cursor": (
			end_position
			+ END_MARKER.length()
		),
	}


func _parse_header_path(
	text: String,
	start_position: int,
	prefix: String
) -> Dictionary:
	var close_position: int = text.find(
		CLOSE_MARKER,
		start_position
	)

	if close_position < 0:
		return _error(
			"Operation header chưa đóng."
		)

	var path_start: int = (
		start_position
		+ prefix.length()
	)

	var path: String = text.substr(
		path_start,
		close_position - path_start
	).strip_edges()

	if path.is_empty():
		return _error(
			"Operation path rỗng."
		)

	return {
		"ok": true,
		"path": path,
		"cursor": (
			close_position
			+ CLOSE_MARKER.length()
		),
	}


func _simulate_operation(
	operation: Dictionary,
	virtual_files: Dictionary
) -> Dictionary:
	var operation_type: String = str(
		operation.get(
			"type",
			""
		)
	)

	var path: String = str(
		operation.get(
			"path",
			""
		)
	)

	var destructive: bool = (
		operation_type == "move"
		or operation_type == "delete"
	)

	var path_error: String = _validate_path(
		path,
		destructive
	)

	if not path_error.is_empty():
		return _error(
			path
			+ ": "
			+ path_error
		)

	match operation_type:
		"replace":
			if not _virtual_exists(
				path,
				virtual_files
			):
				return _error(
					"REPLACE file không tồn tại: "
					+ path
				)

			var current_text: String = (
				_virtual_read_text(
					path,
					virtual_files
				)
			)

			var search_text: String = str(
				operation.get(
					"search",
					""
				)
			)

			if search_text.is_empty():
				return _error(
					"SEARCH rỗng: "
					+ path
				)

			var first_match: int = (
				current_text.find(
					search_text
				)
			)

			if first_match < 0:
				return _error(
					"SEARCH không khớp tại "
					+ path
					+ "\n--- SEARCH ---\n"
					+ _clip(
						search_text,
						1200
					)
				)

			var second_match: int = current_text.find(
				search_text,
				first_match
				+ search_text.length()
			)

			if second_match >= 0:
				return _error(
					"SEARCH khớp nhiều hơn 1 vị trí tại "
					+ path
				)

			var replacement_text: String = str(
				operation.get(
					"with",
					""
				)
			)

			virtual_files[path] = (
				current_text.substr(
					0,
					first_match
				)
				+ replacement_text
				+ current_text.substr(
					first_match
					+ search_text.length()
				)
			)

			return _ok_report(
				"[MODIFY] "
				+ path
			)

		"create":
			if _virtual_exists(
				path,
				virtual_files
			):
				return _error(
					"CREATE destination đã tồn tại: "
					+ path
				)

			virtual_files[path] = str(
				operation.get(
					"content",
					""
				)
			)

			return _ok_report(
				"[CREATE] "
				+ path
			)

		"move":
			var source_guard: String = (
				_validate_destructive_path(
					path
				)
			)

			if not source_guard.is_empty():
				return _error(
					path
					+ ": "
					+ source_guard
				)

			var destination_path: String = str(
				operation.get(
					"to_path",
					""
				)
			)

			var destination_error: String = (
				_validate_path(
					destination_path,
					true
				)
			)

			if not destination_error.is_empty():
				return _error(
					destination_path
					+ ": "
					+ destination_error
				)

			var destination_guard: String = (
				_validate_destructive_path(
					destination_path
				)
			)

			if not destination_guard.is_empty():
				return _error(
					destination_path
					+ ": "
					+ destination_guard
				)

			if path == destination_path:
				return _error(
					"MOVE source và destination giống nhau."
				)

			if not _virtual_exists(
				path,
				virtual_files
			):
				return _error(
					"MOVE source không tồn tại: "
					+ path
				)

			if _virtual_exists(
				destination_path,
				virtual_files
			):
				return _error(
					"MOVE destination đã tồn tại: "
					+ destination_path
				)

			var source_text: String = (
				_virtual_read_text(
					path,
					virtual_files
				)
			)

			virtual_files[path] = null
			virtual_files[destination_path] = source_text

			return _ok_report(
				"[MOVE] "
				+ path
				+ " -> "
				+ destination_path
			)

		"delete":
			var delete_guard: String = (
				_validate_destructive_path(
					path
				)
			)

			if not delete_guard.is_empty():
				return _error(
					path
					+ ": "
					+ delete_guard
				)

			if not _virtual_exists(
				path,
				virtual_files
			):
				return _error(
					"DELETE file không tồn tại: "
					+ path
				)

			virtual_files[path] = null

			return _ok_report(
				"[DELETE] "
				+ path
			)

	return _error(
		"Operation không hỗ trợ: "
		+ operation_type
	)


func _apply_operations(
	operations: Array
) -> Dictionary:
	for operation_value: Variant in operations:
		if typeof(
			operation_value
		) != TYPE_DICTIONARY:
			return _error(
				"Operation Apply không hợp lệ."
			)

		var operation: Dictionary = (
			operation_value
		)

		var operation_type: String = str(
			operation.get(
				"type",
				""
			)
		)

		var path: String = str(
			operation.get(
				"path",
				""
			)
		)

		match operation_type:
			"replace":
				var current_text: String = (
					_read_text(
						path
					)
				)

				var search_text: String = str(
					operation.get(
						"search",
						""
					)
				)

				var match_position: int = (
					current_text.find(
						search_text
					)
				)

				if match_position < 0:
					return _error(
						"SEARCH thay đổi trước Apply: "
						+ path
					)

				if current_text.find(
					search_text,
					match_position
					+ search_text.length()
				) >= 0:
					return _error(
						"SEARCH không unique trước Apply: "
						+ path
					)

				var replacement_text: String = str(
					operation.get(
						"with",
						""
					)
				)

				var new_text: String = (
					current_text.substr(
						0,
						match_position
					)
					+ replacement_text
					+ current_text.substr(
						match_position
						+ search_text.length()
					)
				)

				if not _write_text(
					path,
					new_text
				):
					return _error(
						"Không ghi được "
						+ path
					)

			"create":
				if FileAccess.file_exists(
					path
				):
					return _error(
						"CREATE destination đã tồn tại: "
						+ path
					)

				if not _write_text(
					path,
					str(
						operation.get(
							"content",
							""
						)
					)
				):
					return _error(
						"Không tạo được "
						+ path
					)

			"move":
				var destination_path: String = str(
					operation.get(
						"to_path",
						""
					)
				)

				if not _move_file_with_uid(
					path,
					destination_path
				):
					return _error(
						"Không MOVE được "
						+ path
						+ " -> "
						+ destination_path
					)

			"delete":
				if not _delete_file_with_uid(
					path
				):
					return _error(
						"Không DELETE được "
						+ path
					)

			_:
				return _error(
					"Operation Apply không hỗ trợ: "
					+ operation_type
				)

	return {
		"ok": true
	}


func _build_backup(
	operations: Array
) -> Dictionary:
	var paths: Dictionary = {}

	for operation_value: Variant in operations:
		if typeof(
			operation_value
		) != TYPE_DICTIONARY:
			continue

		var operation: Dictionary = (
			operation_value
		)

		var operation_type: String = str(
			operation.get(
				"type",
				""
			)
		)

		var path: String = str(
			operation.get(
				"path",
				""
			)
		)

		if not path.is_empty():
			paths[path] = true

		if operation_type == "move":
			var destination_path: String = str(
				operation.get(
					"to_path",
					""
				)
			)

			if not destination_path.is_empty():
				paths[destination_path] = true

		if (
			operation_type == "move"
			or operation_type == "delete"
		):
			if not path.ends_with(
				".uid"
			):
				paths[
					path + ".uid"
				] = true

		if operation_type == "move":
			var move_destination: String = str(
				operation.get(
					"to_path",
					""
				)
			)

			if (
				not move_destination.is_empty()
				and not move_destination.ends_with(
					".uid"
				)
			):
				paths[
					move_destination
					+ ".uid"
				] = true

	var snapshots: Dictionary = {}

	for path_value: Variant in paths.keys():
		var snapshot_path: String = str(
			path_value
		)

		var snapshot_result: Dictionary = (
			_snapshot_file(
				snapshot_path
			)
		)

		if not bool(
			snapshot_result.get(
				"ok",
				false
			)
		):
			return _error(
				"Không backup được "
				+ snapshot_path
			)

		snapshots[snapshot_path] = (
			snapshot_result.get(
				"snapshot",
				{}
			)
		)

	return {
		"ok": true,
		"backup": {
			"version": 2,
			"files": snapshots,
		},
	}


func _snapshot_file(
	path: String
) -> Dictionary:
	if not FileAccess.file_exists(
		path
	):
		return {
			"ok": true,
			"snapshot": {
				"existed": false
			},
		}

	var file: FileAccess = FileAccess.open(
		path,
		FileAccess.READ
	)

	if file == null:
		return {
			"ok": false
		}

	var size: int = int(
		file.get_length()
	)

	var bytes: PackedByteArray = (
		file.get_buffer(
			size
		)
	)

	return {
		"ok": true,
		"snapshot": {
			"existed": true,
			"base64": Marshalls.raw_to_base64(
				bytes
			),
		},
	}


func _restore_backup(
	backup: Dictionary
) -> bool:
	if backup.has(
		"files"
	):
		var files_value: Variant = backup[
			"files"
		]

		if typeof(
			files_value
		) == TYPE_DICTIONARY:
			return _restore_snapshot_dictionary(
				files_value
			)

		if typeof(
			files_value
		) == TYPE_ARRAY:
			return _restore_legacy_file_array(
				files_value
			)

	# Compatibility với dạng backup map cũ.
	return _restore_legacy_map(
		backup
	)


func _restore_snapshot_dictionary(
	snapshots: Dictionary
) -> bool:
	var success: bool = true

	for path_value: Variant in snapshots.keys():
		var path: String = str(
			path_value
		)

		var snapshot_value: Variant = (
			snapshots[path_value]
		)

		if typeof(
			snapshot_value
		) != TYPE_DICTIONARY:
			success = false
			continue

		var snapshot: Dictionary = (
			snapshot_value
		)

		var existed: bool = bool(
			snapshot.get(
				"existed",
				false
			)
		)

		if not existed:
			if FileAccess.file_exists(
				path
			):
				if not _remove_file(
					path
				):
					success = false

			continue

		var encoded: String = str(
			snapshot.get(
				"base64",
				""
			)
		)

		var bytes: PackedByteArray = (
			Marshalls.base64_to_raw(
				encoded
			)
		)

		if not _write_binary(
			path,
			bytes
		):
			success = false

	return success


func _restore_legacy_file_array(
	files_array: Array
) -> bool:
	var success: bool = true

	for entry_value: Variant in files_array:
		if typeof(
			entry_value
		) != TYPE_DICTIONARY:
			success = false
			continue

		var entry: Dictionary = entry_value

		var path: String = str(
			entry.get(
				"path",
				""
			)
		)

		if path.is_empty():
			success = false
			continue

		var existed: bool = bool(
			entry.get(
				"existed",
				true
			)
		)

		if not existed:
			if FileAccess.file_exists(
				path
			):
				if not _remove_file(
					path
				):
					success = false

			continue

		if not _write_text(
			path,
			str(
				entry.get(
					"content",
					""
				)
			)
		):
			success = false

	return success


func _restore_legacy_map(
	backup: Dictionary
) -> bool:
	var success: bool = true

	for path_value: Variant in backup.keys():
		var path: String = str(
			path_value
		)

		if (
			path == "version"
			or path == "files"
		):
			continue

		var value: Variant = backup[
			path_value
		]

		if value == null:
			if FileAccess.file_exists(
				path
			):
				if not _remove_file(
					path
				):
					success = false

			continue

		if not _write_text(
			path,
			str(
				value
			)
		):
			success = false

	return success


func _save_backup(
	backup: Dictionary
) -> bool:
	if not _ensure_directory(
		"user://chatgpt_bridge"
	):
		return false

	var file: FileAccess = FileAccess.open(
		BACKUP_FILE,
		FileAccess.WRITE
	)

	if file == null:
		return false

	file.store_string(
		JSON.stringify(
			backup,
			"  "
		)
	)

	file.flush()

	return true


func _load_backup() -> Dictionary:
	if not FileAccess.file_exists(
		BACKUP_FILE
	):
		return {}

	var file: FileAccess = FileAccess.open(
		BACKUP_FILE,
		FileAccess.READ
	)

	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(
		file.get_as_text()
	)

	if typeof(
		parsed
	) != TYPE_DICTIONARY:
		return {}

	return parsed


func _remove_backup_file() -> void:
	if FileAccess.file_exists(
		BACKUP_FILE
	):
		_remove_file(
			BACKUP_FILE
		)


func _move_file_with_uid(
	source_path: String,
	destination_path: String
) -> bool:
	if not FileAccess.file_exists(
		source_path
	):
		return false

	if FileAccess.file_exists(
		destination_path
	):
		return false

	if not _copy_binary(
		source_path,
		destination_path
	):
		return false

	if not _remove_file(
		source_path
	):
		return false

	if source_path.ends_with(
		".uid"
	):
		return true

	var source_uid: String = (
		source_path + ".uid"
	)

	if not FileAccess.file_exists(
		source_uid
	):
		return true

	var destination_uid: String = (
		destination_path + ".uid"
	)

	if FileAccess.file_exists(
		destination_uid
	):
		return false

	if not _copy_binary(
		source_uid,
		destination_uid
	):
		return false

	if not _remove_file(
		source_uid
	):
		return false

	return true


func _delete_file_with_uid(
	path: String
) -> bool:
	if not FileAccess.file_exists(
		path
	):
		return false

	if not _remove_file(
		path
	):
		return false

	if path.ends_with(
		".uid"
	):
		return true

	var uid_path: String = (
		path + ".uid"
	)

	if FileAccess.file_exists(
		uid_path
	):
		if not _remove_file(
			uid_path
		):
			return false

	return true


func _copy_binary(
	source_path: String,
	destination_path: String
) -> bool:
	var source: FileAccess = FileAccess.open(
		source_path,
		FileAccess.READ
	)

	if source == null:
		return false

	var size: int = int(
		source.get_length()
	)

	var bytes: PackedByteArray = (
		source.get_buffer(
			size
		)
	)

	return _write_binary(
		destination_path,
		bytes
	)


func _read_text(
	path: String
) -> String:
	var file: FileAccess = FileAccess.open(
		path,
		FileAccess.READ
	)

	if file == null:
		return ""

	return file.get_as_text()


func _write_text(
	path: String,
	text: String
) -> bool:
	if not _ensure_directory(
		path.get_base_dir()
	):
		return false

	var file: FileAccess = FileAccess.open(
		path,
		FileAccess.WRITE
	)

	if file == null:
		return false

	file.store_string(
		text
	)

	file.flush()

	return true


func _write_binary(
	path: String,
	bytes: PackedByteArray
) -> bool:
	if not _ensure_directory(
		path.get_base_dir()
	):
		return false

	var file: FileAccess = FileAccess.open(
		path,
		FileAccess.WRITE
	)

	if file == null:
		return false

	file.store_buffer(
		bytes
	)

	file.flush()

	return true


func _remove_file(
	path: String
) -> bool:
	if not FileAccess.file_exists(
		path
	):
		return true

	var absolute_path: String = (
		ProjectSettings.globalize_path(
			path
		)
	)

	return (
		DirAccess.remove_absolute(
			absolute_path
		)
		== OK
	)


func _ensure_directory(
	path: String
) -> bool:
	var absolute_path: String = (
		ProjectSettings.globalize_path(
			path
		)
	)

	var error: Error = (
		DirAccess.make_dir_recursive_absolute(
			absolute_path
		)
	)

	return (
		error == OK
		or error == ERR_ALREADY_EXISTS
	)


func _validate_path(
	path: String,
	destructive: bool = false
) -> String:
	if not path.begins_with(
		"res://"
	):
		return (
			"chỉ cho phép path bắt đầu bằng res://"
		)

	if ".." in path:
		return (
			"không cho phép '..'"
		)

	if (
		path == "res://"
		or path.ends_with(
			"/"
		)
	):
		return "path phải trỏ tới file"

	var filename: String = path.get_file()

	if destructive:
		if filename.begins_with(
			"._"
		):
			return ""

		if filename == ".DS_Store":
			return ""

		if path.get_extension().to_lower() == "uid":
			return ""

	var extension: String = (
		path.get_extension().to_lower()
	)

	if extension not in TEXT_EXTENSIONS:
		return (
			"extension không nằm trong allow-list"
		)

	return ""


func _validate_destructive_path(
	path: String
) -> String:
	if path.begins_with(
		"res://addons/chatgpt_bridge/"
	):
		return (
			"không cho MOVE/DELETE core ChatGPT Bridge"
		)

	if path.begins_with(
		"res://.godot/"
	):
		return (
			"không cho MOVE/DELETE cache .godot"
		)

	return ""


func _virtual_exists(
	path: String,
	virtual_files: Dictionary
) -> bool:
	if virtual_files.has(
		path
	):
		return (
			virtual_files[path]
			!= null
		)

	return FileAccess.file_exists(
		path
	)


func _virtual_read_text(
	path: String,
	virtual_files: Dictionary
) -> String:
	if virtual_files.has(
		path
	):
		var value: Variant = (
			virtual_files[path]
		)

		if value == null:
			return ""

		return str(
			value
		)

	return _read_text(
		path
	)


func _skip_one_newline(
	text: String,
	position: int
) -> int:
	if (
		position < text.length()
		and text.substr(
			position,
			1
		) == "\n"
	):
		return position + 1

	return position


func _remove_one_trailing_newline(
	text: String
) -> String:
	if (
		not text.is_empty()
		and text.ends_with(
			"\n"
		)
	):
		return text.substr(
			0,
			text.length() - 1
		)

	return text


func _clip(
	text: String,
	maximum: int
) -> String:
	if text.length() <= maximum:
		return text

	return (
		text.substr(
			0,
			maximum
		)
		+ "\n[...]"
	)


func _ok_report(
	message: String
) -> Dictionary:
	return {
		"ok": true,
		"report": message,
	}


func _error(
	message: String
) -> Dictionary:
	return {
		"ok": false,
		"report": "ERROR: " + message,
	}
