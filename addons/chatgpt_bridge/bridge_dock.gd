@tool
extends VBoxContainer


const PROTOCOL_HEADER := "CHATGPT_BRIDGE_PATCH_V1"

const MAX_CONTEXT_CHARS := 180000
const MAX_FILE_CHARS := 30000
const MAX_SCENE_SCRIPTS := 10

const PatchEngineV2 = preload(
	"res://addons/chatgpt_bridge/bridge_patch_engine_v2.gd"
)


var editor_interface: EditorInterface

var context_box: TextEdit
var patch_box: TextEdit
var preview_box: TextEdit
var status_label: Label

var include_scene_file: CheckButton
var include_scene_scripts: CheckButton
var include_selected_files: CheckButton

var patch_engine = PatchEngineV2.new()


func configure(
	value: EditorInterface
) -> void:
	editor_interface = value


func _ready() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	custom_minimum_size = Vector2(390, 500)

	_build_ui()

	_set_status(
		"Sẵn sàng. Tạo context rồi gửi sang ChatGPT."
	)


# =========================================================
# UI
# =========================================================

func _build_ui() -> void:
	var title := Label.new()
	title.text = "ChatGPT Bridge"
	title.add_theme_font_size_override(
		"font_size",
		18
	)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = (
		"Context → ChatGPT → Patch → Preview → Apply"
	)
	subtitle.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	add_child(subtitle)

	add_child(HSeparator.new())

	_build_context_section()

	add_child(HSeparator.new())

	_build_patch_section()

	add_child(HSeparator.new())

	_build_undo_section()

	status_label = Label.new()
	status_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)
	add_child(status_label)


func _build_context_section() -> void:
	var options := HFlowContainer.new()
	add_child(options)

	include_scene_file = CheckButton.new()
	include_scene_file.text = "Scene"
	include_scene_file.button_pressed = true
	options.add_child(
		include_scene_file
	)

	include_scene_scripts = CheckButton.new()
	include_scene_scripts.text = "Scripts"
	include_scene_scripts.button_pressed = true
	options.add_child(
		include_scene_scripts
	)

	include_selected_files = CheckButton.new()
	include_selected_files.text = "File đã chọn"
	include_selected_files.button_pressed = true
	options.add_child(
		include_selected_files
	)

	var buttons := HBoxContainer.new()
	add_child(buttons)

	var build_btn := Button.new()
	build_btn.text = "Tạo context"
	build_btn.pressed.connect(
		_on_build_context
	)
	buttons.add_child(build_btn)

	var copy_btn := Button.new()
	copy_btn.text = "Copy context"
	copy_btn.pressed.connect(
		_on_copy_context
	)
	buttons.add_child(copy_btn)

	var clear_context_btn := Button.new()
	clear_context_btn.text = "Xoá context"
	clear_context_btn.pressed.connect(_on_clear_context)
	buttons.add_child(clear_context_btn)

	var copy_paths_btn := Button.new()
	copy_paths_btn.text = "Copy paths"
	copy_paths_btn.tooltip_text = (
		"Copy toàn bộ path từ file/folder đang chọn"
	)
	copy_paths_btn.pressed.connect(
		_on_copy_selected_paths
	)
	buttons.add_child(copy_paths_btn)

	var copy_search_btn := Button.new()
	copy_search_btn.text = "Copy SEARCH"
	copy_search_btn.tooltip_text = (
		"Copy path + nội dung chính xác của file đang chọn"
	)
	copy_search_btn.pressed.connect(
		_on_copy_exact_search_context
	)
	buttons.add_child(copy_search_btn)

	var run_btn := Button.new()
	run_btn.text = "▶ Run"
	run_btn.pressed.connect(
		_on_run_current_scene
	)
	buttons.add_child(run_btn)

	var stop_btn := Button.new()
	stop_btn.text = "■ Stop"
	stop_btn.pressed.connect(
		_on_stop_scene
	)
	buttons.add_child(stop_btn)

	context_box = TextEdit.new()
	context_box.placeholder_text = (
		"Context gửi sang ChatGPT..."
	)

	context_box.custom_minimum_size = Vector2(
		0,
		135
	)

	context_box.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	context_box.wrap_mode = (
		TextEdit.LINE_WRAPPING_BOUNDARY
	)

	add_child(context_box)


func _build_patch_section() -> void:
	var title := Label.new()
	title.text = "Patch từ ChatGPT"
	title.add_theme_font_size_override(
		"font_size",
		14
	)
	add_child(title)

	var buttons := HBoxContainer.new()
	add_child(buttons)

	var receive_btn := Button.new()
	receive_btn.text = "Nhận patch"
	receive_btn.tooltip_text = (
		"Copy câu trả lời ChatGPT rồi bấm đây"
	)
	receive_btn.pressed.connect(
		_on_paste_patch
	)
	buttons.add_child(receive_btn)

	var preview_btn := Button.new()
	preview_btn.text = "Preview"
	preview_btn.pressed.connect(
		_on_preview_patch
	)
	buttons.add_child(preview_btn)

	var apply_btn := Button.new()
	apply_btn.text = "Apply"
	apply_btn.pressed.connect(
		_on_apply_patch
	)
	buttons.add_child(apply_btn)

	var clear_btn := Button.new()
	clear_btn.text = "Xoá"
	clear_btn.pressed.connect(
		_on_clear_patch
	)
	buttons.add_child(clear_btn)

	var debug_btn := Button.new()
	debug_btn.text = "Copy debug"
	debug_btn.pressed.connect(
		_on_copy_patch_debug
	)
	buttons.add_child(debug_btn)

	patch_box = TextEdit.new()

	patch_box.placeholder_text = (
		PROTOCOL_HEADER
		+ "\n\nDán patch từ ChatGPT vào đây..."
	)

	# Ưu tiên nhiều diện tích cho patch.
	patch_box.custom_minimum_size = Vector2(
		0,
		300
	)

	patch_box.size_flags_vertical = (
		Control.SIZE_EXPAND_FILL
	)

	patch_box.size_flags_stretch_ratio = 2.0

	patch_box.wrap_mode = (
		TextEdit.LINE_WRAPPING_BOUNDARY
	)

	add_child(patch_box)

	var preview_title := Label.new()
	preview_title.text = "Preview"
	add_child(preview_title)

	preview_box = TextEdit.new()
	preview_box.editable = false
	preview_box.placeholder_text = (
		"Kết quả kiểm tra patch..."
	)

	preview_box.custom_minimum_size = Vector2(
		0,
		115
	)

	preview_box.wrap_mode = (
		TextEdit.LINE_WRAPPING_BOUNDARY
	)

	add_child(preview_box)


func _build_undo_section() -> void:
	var row := HBoxContainer.new()
	add_child(row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)
	row.add_child(spacer)

	var undo_btn := Button.new()
	undo_btn.text = "↶ Undo lần cuối"
	undo_btn.pressed.connect(
		_on_undo_last
	)
	row.add_child(undo_btn)


# =========================================================
# CONTEXT
# =========================================================

func _on_build_context() -> void:
	context_box.text = _build_context()

	DisplayServer.clipboard_set(
		context_box.text
	)

	_set_status(
		"Đã tạo và copy context vào clipboard."
	)


func _on_clear_context() -> void:
	if context_box != null:
		context_box.clear()

	_set_status("Đã xoá context hiện tại.")


func _on_copy_selected_paths() -> void:
	if editor_interface == null:
		_set_status(
			"EditorInterface chưa sẵn sàng."
		)
		return

	var selected_paths := (
		editor_interface.get_selected_paths()
	)

	if selected_paths.is_empty():
		_set_status(
			"Hãy chọn file hoặc folder trong FileSystem."
		)
		return

	var all_paths := PackedStringArray()

	for path_value in selected_paths:
		var path: String = str(
			path_value
		)

		_collect_paths_recursive(
			path,
			all_paths
		)

	all_paths.sort()

	var output := PackedStringArray()

	output.append(
		"# GODOT PROJECT PATH INDEX"
	)
	output.append("")

	for path: String in all_paths:
		output.append(
			path
		)

	DisplayServer.clipboard_set(
		"\n".join(
			output
		)
	)

	_set_status(
		"Đã copy "
		+ str(all_paths.size())
		+ " path."
	)


func _on_copy_exact_search_context() -> void:
	if editor_interface == null:
		_set_status(
			"EditorInterface chưa sẵn sàng."
		)
		return

	var selected_paths := (
		editor_interface.get_selected_paths()
	)

	if selected_paths.is_empty():
		_set_status(
			"Hãy chọn ít nhất 1 file trong FileSystem."
		)
		return

	var output := PackedStringArray()

	output.append(
		"# GODOT CHATGPT EXACT SEARCH CONTEXT"
	)
	output.append("")

	output.append(
		"QUY TẮC BẮT BUỘC:"
	)

	output.append(
		"- Nếu tạo REPLACE_IN_FILE, SEARCH chỉ được copy "
		+ "nguyên văn từ EXACT FILE SNAPSHOT bên dưới."
	)

	output.append(
		"- Không dựng SEARCH từ trí nhớ, context cũ "
		+ "hoặc phiên bản file trước."
	)

	output.append(
		"- Giữ nguyên tab, khoảng trắng và xuống dòng."
	)

	output.append(
		"- Ưu tiên SEARCH đủ đặc trưng để match đúng 1 lần."
	)

	output.append(
		"- Nếu file cần sửa không có snapshot bên dưới, "
		+ "không được đoán nội dung file."
	)

	output.append("")

	output.append(
		_patch_protocol_help()
	)

	output.append("")

	output.append(
		"## EXACT FILE SNAPSHOTS"
	)

	var file_count: int = 0

	for path_value in selected_paths:
		var path: String = str(
			path_value
		)

		if not FileAccess.file_exists(
			path
		):
			output.append("")
			output.append(
				"### SELECTED PATH"
			)
			output.append(
				path
			)
			output.append(
				"(Folder hoặc không phải file trực tiếp)"
			)
			continue

		if not _is_context_text_file(
			path
		):
			continue

		file_count += 1

		output.append("")
		output.append(
			"### PATH"
		)
		output.append(
			path
		)

		output.append("")
		output.append(
			"### EXACT FILE SNAPSHOT"
		)

		output.append(
			"```text"
		)

		output.append(
			_read_text_file(
				path
			)
		)

		output.append(
			"```"
		)

	if file_count <= 0:
		_set_status(
			"Bạn đang chọn folder. "
			+ "Hãy chọn file .gd/.tscn/.tres cần sửa rồi Copy SEARCH."
		)
		return

	var result: String = "\n".join(
		output
	)

	DisplayServer.clipboard_set(
		result
	)

	_set_status(
		"Đã copy EXACT SEARCH context cho "
		+ str(file_count)
		+ " file."
	)


func _on_copy_context() -> void:
	if context_box.text.strip_edges().is_empty():
		context_box.text = _build_context()

	DisplayServer.clipboard_set(
		context_box.text
	)

	_set_status(
		"Đã copy context."
	)


func _build_context() -> String:
	var out := PackedStringArray()

	out.append(
		"# GODOT CHATGPT BRIDGE CONTEXT"
	)

	out.append("")

	out.append(
		"Bạn đang hỗ trợ chỉnh trực tiếp một project Godot 4.x."
	)

	out.append(
		"Nếu cần sửa code/file, hãy xuất "
		+ "CHATGPT_BRIDGE_PATCH_V1 ở cuối câu trả lời."
	)

	out.append(
		"SEARCH phải khớp chính xác nội dung file hiện tại."
	)

	out.append(
		"Không dùng unified diff."
	)

	out.append("")

	out.append(
		_patch_protocol_help()
	)

	var root: Node = null

	if editor_interface != null:
		root = (
			editor_interface
			.get_edited_scene_root()
		)

	if root == null:
		out.append("")
		out.append(
			"## CURRENT SCENE"
		)
		out.append(
			"Không có scene đang mở."
		)

	else:
		out.append("")
		out.append(
			"## CURRENT SCENE"
		)

		out.append(
			"Path: %s"
			% root.scene_file_path
		)

		out.append(
			"Root: %s (%s)"
			% [
				root.name,
				root.get_class()
			]
		)

		out.append("")
		out.append(
			"### SCENE TREE"
		)

		out.append(
			_scene_tree_text(
				root
			)
		)

		var selected_nodes: Array[Node] = (
			_get_selected_nodes()
		)

		out.append("")
		out.append(
			"### SELECTED NODES"
		)

		if selected_nodes.is_empty():
			out.append(
				"(none)"
			)

		else:
			for node: Node in selected_nodes:
				out.append(
					_node_summary(
						node
					)
				)

		if (
			include_scene_file != null
			and include_scene_file.button_pressed
			and not root.scene_file_path.is_empty()
		):
			out.append("")

			out.append(
				_file_section(
					root.scene_file_path,
					"CURRENT SCENE FILE"
				)
			)

		if (
			include_scene_scripts != null
			and include_scene_scripts.button_pressed
		):
			var scripts := (
				_collect_scene_script_paths(
					root
				)
			)

			if not scripts.is_empty():
				out.append("")
				out.append(
					"## SCENE SCRIPTS"
				)

				for script_path: String in scripts:
					out.append(
						_file_section(
							script_path,
							script_path
						)
					)

	if (
		include_selected_files != null
		and include_selected_files.button_pressed
		and editor_interface != null
	):
		var selected_paths := (
			editor_interface.get_selected_paths()
		)

		if not selected_paths.is_empty():
			out.append("")
			out.append(
				"## FILESYSTEM SELECTION"
			)

			for path_value in selected_paths:
				var path := str(
					path_value
				)

				out.append(
					path
				)

				if (
					_is_context_text_file(
						path
					)
					and FileAccess.file_exists(
						path
					)
				):
					out.append(
						_file_section(
							path,
							path
						)
					)

	out.append("")
	out.append(
		"## REQUEST"
	)

	out.append(
		"Hãy xử lý yêu cầu tôi gửi cùng context này."
	)

	out.append(
		"Nếu sửa code/file, "
		+ "xuất CHATGPT_BRIDGE_PATCH_V1 ở cuối câu trả lời."
	)

	var result := "\n".join(
		out
	)

	if result.length() > MAX_CONTEXT_CHARS:
		result = (
			result.substr(
				0,
				MAX_CONTEXT_CHARS
			)
			+ "\n\n[CONTEXT TRUNCATED BY PLUGIN]"
		)

	return result


func _patch_protocol_help() -> String:
	return PatchEngineV2.protocol_help()


func _scene_tree_text(
	root: Node
) -> String:
	var lines := PackedStringArray()

	_append_tree_line(
		root,
		0,
		lines
	)

	return "\n".join(
		lines
	)


func _append_tree_line(
	node: Node,
	depth: int,
	lines: PackedStringArray
) -> void:
	if depth > 12:
		return

	var indent := (
		"  ".repeat(
			depth
		)
	)

	var script_suffix := ""

	var script = node.get_script()

	if (
		script != null
		and script is Script
		and not script.resource_path.is_empty()
	):
		script_suffix = (
			" [script=%s]"
			% script.resource_path
		)

	lines.append(
		"%s- %s (%s)%s"
		% [
			indent,
			node.name,
			node.get_class(),
			script_suffix
		]
	)

	for child in node.get_children():
		if child is Node:
			_append_tree_line(
				child,
				depth + 1,
				lines
			)


func _get_selected_nodes() -> Array[Node]:
	var result: Array[Node] = []

	if editor_interface == null:
		return result

	var selection := (
		editor_interface.get_selection()
	)

	if selection == null:
		return result

	for item in selection.get_selected_nodes():
		if item is Node:
			result.append(
				item
			)

	return result


func _node_summary(
	node: Node
) -> String:
	var lines := PackedStringArray()

	lines.append(
		"- Path: %s"
		% String(
			node.get_path()
		)
	)

	lines.append(
		"  Type: %s"
		% node.get_class()
	)

	var script = node.get_script()

	if (
		script != null
		and script is Script
	):
		lines.append(
			"  Script: %s"
			% script.resource_path
		)

	return "\n".join(
		lines
	)


func _collect_scene_script_paths(
	root: Node
) -> PackedStringArray:
	var unique := {}

	var stack: Array[Node] = [
		root
	]

	while (
		not stack.is_empty()
		and unique.size() < MAX_SCENE_SCRIPTS
	):
		var node: Node = (
			stack.pop_back()
		)

		var script = node.get_script()

		if (
			script != null
			and script is Script
		):
			var path := String(
				script.resource_path
			)

			if (
				path.begins_with(
					"res://"
				)
				and FileAccess.file_exists(
					path
				)
			):
				unique[
					path
				] = true

		for child in node.get_children():
			if child is Node:
				stack.append(
					child
				)

	var paths := PackedStringArray()

	for path_value in unique.keys():
		paths.append(
			String(
				path_value
			)
		)

	paths.sort()

	return paths


func _file_section(
	path: String,
	heading: String
) -> String:
	var content := (
		_read_text_file(
			path
		)
	)

	if content.length() > MAX_FILE_CHARS:
		content = (
			content.substr(
				0,
				MAX_FILE_CHARS
			)
			+ "\n[FILE TRUNCATED]"
		)

	return (
		"### %s\n```text\n%s\n```"
		% [
			heading,
			content
		]
	)


func _is_context_text_file(
	path: String
) -> bool:
	var ext := (
		path.get_extension()
		.to_lower()
	)

	return ext in [
		"gd",
		"tscn",
		"tres",
		"gdshader",
		"cfg",
		"json",
		"txt",
		"md"
	]


func _collect_paths_recursive(
	path: String,
	output: PackedStringArray
) -> void:
	if FileAccess.file_exists(
		path
	):
		if _is_context_text_file(
			path
		):
			if not output.has(
				path
			):
				output.append(
					path
				)

		return

	var directory := DirAccess.open(
		path
	)

	if directory == null:
		return

	var files: PackedStringArray = (
		directory.get_files()
	)

	for file_name: String in files:
		var file_path: String = (
			path.path_join(
				file_name
			)
		)

		if not _is_context_text_file(
			file_path
		):
			continue

		if not output.has(
			file_path
		):
			output.append(
				file_path
			)

	var directories: PackedStringArray = (
		directory.get_directories()
	)

	for directory_name: String in directories:
		if directory_name.begins_with(
			"."
		):
			continue

		var child_path: String = (
			path.path_join(
				directory_name
			)
		)

		_collect_paths_recursive(
			child_path,
			output
		)


func _read_text_file(
	path: String
) -> String:
	var file := FileAccess.open(
		path,
		FileAccess.READ
	)

	if file == null:
		return ""

	return file.get_as_text()


# =========================================================
# PATCH
# =========================================================

func _extract_bridge_patch(
	source_text: String
) -> String:
	var header_position := (
		source_text.find(
			PROTOCOL_HEADER
		)
	)

	if header_position < 0:
		return ""

	var patch_text := (
		source_text.substr(
			header_position
		)
	)

	var fence_position := (
		patch_text.find(
			"\n```"
		)
	)

	if fence_position >= 0:
		patch_text = patch_text.left(
			fence_position
		)

	return patch_text.strip_edges()


func _on_paste_patch() -> void:
	var clipboard_text := (
		DisplayServer.clipboard_get()
	)

	var patch_text := (
		_extract_bridge_patch(
			clipboard_text
		)
	)

	if patch_text.is_empty():
		_set_status(
			"Không tìm thấy CHATGPT_BRIDGE_PATCH_V1 "
			+ "trong clipboard."
		)
		return

	patch_box.text = patch_text

	_on_preview_patch()


func _on_preview_patch() -> void:
	var result: Dictionary = (
		patch_engine.parse_and_simulate(
			patch_box.text
		)
	)

	preview_box.text = str(
		result.get(
			"report",
			""
		)
	)

	if bool(
		result.get(
			"ok",
			false
		)
	):
		_set_status(
			"Patch hợp lệ. Có thể Apply."
		)

	else:
		_set_status(
			"Patch chưa hợp lệ. "
			+ "Không có file nào bị thay đổi."
		)


func _on_apply_patch() -> void:
	var result: Dictionary = (
		patch_engine.apply_patch(
			patch_box.text
		)
	)

	preview_box.text = str(
		result.get(
			"report",
			""
		)
	)

	if not bool(
		result.get(
			"ok",
			false
		)
	):
		_set_status(
			"Không Apply: patch không hợp lệ."
		)
		return

	if editor_interface != null:
		editor_interface.get_resource_filesystem().scan()

	_set_status(
		"Đã Apply %d operation(s). Có thể Undo."
		% int(
			result.get(
				"applied_count",
				0
			)
		)
	)


func _on_clear_patch() -> void:
	if patch_box != null:
		patch_box.clear()

	if preview_box != null:
		preview_box.clear()

	_set_status(
		"Đã xoá patch."
	)


func _on_copy_patch_debug() -> void:
	if preview_box == null:
		return

	var debug_text := (
		preview_box.text.strip_edges()
	)

	if debug_text.is_empty():
		_set_status(
			"Chưa có Preview để copy."
		)
		return

	var output := PackedStringArray()

	output.append(
		"# CHATGPT BRIDGE PATCH DEBUG"
	)

	output.append("")
	output.append(
		debug_text
	)

	if status_label != null:
		output.append("")
		output.append(
			"Status:"
		)
		output.append(
			status_label.text
		)

	DisplayServer.clipboard_set(
		"\n".join(
			output
		)
	)

	_set_status(
		"Đã copy patch debug."
	)


func _on_undo_last() -> void:
	var result: Dictionary = (
		patch_engine.undo_last()
	)

	preview_box.text = str(
		result.get(
			"report",
			""
		)
	)

	if not bool(
		result.get(
			"ok",
			false
		)
	):
		_set_status(
			str(
				result.get(
					"report",
					"Undo thất bại."
				)
			)
		)
		return

	if editor_interface != null:
		editor_interface.get_resource_filesystem().scan()

	_set_status(
		"Đã Undo thay đổi gần nhất."
	)


# =========================================================
# RUN / STOP
# =========================================================

func _on_run_current_scene() -> void:
	if editor_interface == null:
		return

	if editor_interface.is_playing_scene():
		editor_interface.stop_playing_scene()

	editor_interface.play_current_scene()

	_set_status(
		"Đang chạy scene hiện tại."
	)


func _on_stop_scene() -> void:
	if editor_interface == null:
		return

	if editor_interface.is_playing_scene():
		editor_interface.stop_playing_scene()

	_set_status(
		"Đã dừng game."
	)


# =========================================================
# STATUS
# =========================================================

func _set_status(
	text: String
) -> void:
	if status_label != null:
		status_label.text = text
