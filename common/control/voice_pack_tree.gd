class_name VoicePackTree extends Tree





signal pack_selected(pack: PackInfo)
signal all_voice_packs_selected()
signal loading_finished


enum USE_CASE{STANDARD, DUB, TOGGLING, CINEMA}


const TREE_COLUMN: int = 0


const ICON_SIZE: int = 16


@export var use_case: USE_CASE
@export var include_all_packs_option: bool


var root: TreeItem
var section_all_voice_packs: TreeItem
var section_basegame: TreeItem
var section_custom: TreeItem
var top_level_cells: Array[TreeItem]


var active_pack: PackInfo
var has_finished_loading: bool = false:
	set(value): has_finished_loading = value; if has_finished_loading: loading_finished.emit()




func emit_selected_pack() -> void :
	if use_case == USE_CASE.TOGGLING and get_selected_column() == TREE_COLUMN: return
	var active_cell: TreeItem = get_selected()
	if include_all_packs_option and active_cell == section_all_voice_packs:
		active_pack = preload("res://assets_gd/resources/_unsorted/all_packs_filler.tres")
		all_voice_packs_selected.emit();return
	if active_cell is VoicePackTreeItem:

		if active_pack == active_cell.pack_info: return
		pack_selected.emit(active_cell.pack_info)
		active_pack = active_cell.pack_info


func _parent_default_overrides() -> void :
	hide_root = true
	auto_tooltip = false
func _onready_setup() -> void :
	root = create_item()
	var column_offset: int = 0
	if use_case == USE_CASE.TOGGLING:
		columns = 2
		set_column_expand(0, false)

		item_edited.connect(_toggle_pack_by_checkmark)
		column_offset = 1
	if include_all_packs_option:
		section_all_voice_packs = root.create_child()
		section_all_voice_packs.set_icon(TREE_COLUMN, preload("res://graphic/image/cv_temp_icon_infinite_sml.png"))
		section_all_voice_packs.set_text(TREE_COLUMN, "All Voice Packs")
	section_basegame = root.create_child()
	section_basegame.set_icon(TREE_COLUMN + column_offset, preload("res://assets/gd_icons/waveform_drawer.png"))
	section_basegame.set_text(TREE_COLUMN + column_offset, "Base Game Packs")
	section_custom = root.create_child()
	section_custom.set_icon(TREE_COLUMN + column_offset, preload("res://assets/gd_icons/state_machine.png"))
	section_custom.set_text(TREE_COLUMN + column_offset, "Custom Voice Packs")
	section_custom.set_expand_right(TREE_COLUMN, false)
	section_custom.set_selectable(TREE_COLUMN + column_offset, false)
	cell_selected.connect(emit_selected_pack)
	cell_selected.connect(fold_unrelated_parents)
	add_theme_constant_override("v_separation", -2)
	if use_case == USE_CASE.CINEMA:
		top_level_cells = [root]
	else:
		top_level_cells = [section_basegame, section_custom]
	section_basegame.visible = false


func generate_custom_list() -> void :
	var target_section: TreeItem
	target_section = root if use_case == USE_CASE.CINEMA else section_custom
	for child: TreeItem in target_section.get_children(): child.free()

	for folder: String in DirAccess.get_directories_at(FileManager.MODPACKS_VOICE):
		if use_case != USE_CASE.TOGGLING and Profile.ignored_packs_voice.has(folder + "/"): continue
		if use_case == USE_CASE.DUB:
			var global_dir: String = FileManager.MODPACKS_VOICE + folder
			if !at_least_one_dub_file(global_dir): continue
		elif use_case == USE_CASE.CINEMA:
			var global_dir: String = FileManager.MODPACKS_VOICE + folder
			if !at_least_one_dub_file(global_dir): continue
			if !at_least_one_dub_recording(global_dir): continue

		await get_tree().process_frame
		var child: TreeItem = target_section.create_child()
		child.collapsed = true
		child.set_script(VoicePackTreeItem)
		child.generate_from_path(use_case, folder)

	has_finished_loading = true
func at_least_one_dub_file(global_dir: String) -> bool:
	var output: bool = false
	for file: String in DirAccess.get_files_at(global_dir):
		if file.to_lower() == "dub_video.ogv": return true
	for dir: String in DirAccess.get_directories_at(global_dir):
		output = (output or at_least_one_dub_file(global_dir + "/" + dir))
		if output: return true
	return output
func at_least_one_dub_recording(global_dir: String) -> bool:
	var recordings_dir: String = "/recordings/dub_recordings/".join(global_dir.split("/packs_voice/", false, 1))
	return !DirAccess.get_directories_at(recordings_dir).is_empty()


func see_reset() -> void : for pack_area: TreeItem in top_level_cells: for item: VoicePackTreeItem in pack_area.get_children(): item.visibility_reset()
func see_title(text: String) -> void : for pack_area: TreeItem in top_level_cells: for item: VoicePackTreeItem in pack_area.get_children(): item.visibility_title(text)
func see_subtitle(text: String) -> void : for pack_area: TreeItem in top_level_cells: for item: VoicePackTreeItem in pack_area.get_children(): item.visibility_subtitle(text)
func see_readme(text: String) -> void : for pack_area: TreeItem in top_level_cells: for item: VoicePackTreeItem in pack_area.get_children(): item.visibility_readme(text)
func see_author(text: String) -> void : for pack_area: TreeItem in top_level_cells: for item: VoicePackTreeItem in pack_area.get_children(): item.visibility_author(text)


func _show_pack(pack: PackInfo) -> void :
	var temp_array: = Array(Profile.ignored_packs_voice)
	while temp_array.has(pack.path_from_pack): temp_array.erase(pack.path_from_pack)
	Profile.ignored_packs_voice = PackedStringArray(temp_array)
func _hide_pack(pack: PackInfo) -> void :
	if !Profile.ignored_packs_voice.has(pack.path_from_pack): Profile.ignored_packs_voice.append(pack.path_from_pack)
func toggle_pack_visibility(pack: PackInfo, toggle_on: bool) -> void :
	if toggle_on: _show_pack(pack)
	else: _hide_pack(pack)
func _toggle_pack_by_checkmark() -> void :
	await get_tree().process_frame
	var active_cell: TreeItem = get_selected()
	if active_cell is VoicePackTreeItem: toggle_pack_visibility(active_cell.pack_info, active_cell.is_checked(TREE_COLUMN))


func fold_unrelated_parents() -> void :

	if use_case == USE_CASE.TOGGLING and get_selected_column() == 0: return


	var crawler_cell: TreeItem = get_selected()
	if !crawler_cell or top_level_cells.has(crawler_cell): return
	var crawler_parent: TreeItem = crawler_cell.get_parent()
	while !top_level_cells.has(crawler_parent):
		crawler_parent = crawler_parent.get_parent()
		crawler_cell = crawler_cell.get_parent()
		if !crawler_parent: return
	for pack_area: TreeItem in top_level_cells: for cell: VoicePackTreeItem in pack_area.get_children(): cell.collapsed = (cell != crawler_cell)
	scroll_to_item(get_selected())
func fold_all_top_level_packs() -> void : for pack_area: TreeItem in top_level_cells: for cell: VoicePackTreeItem in pack_area.get_children(): cell.collapsed = true


func _init() -> void : _parent_default_overrides()
func _ready() -> void :
	_onready_setup()
	await generate_custom_list()
