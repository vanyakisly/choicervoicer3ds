extends ClipSelectionMenuBase

const BUTTON_CV = preload("res://scene/module/button/button_cv.tscn")
const WAUKEGAN_LDO = preload("res://graphic/font/Waukegan LDO.ttf")

@onready var dub_toggles: VBoxContainer = %DubToggles
@onready var recordings_list: VBoxContainer = %RecordingsList
@onready var recordings_page: VBoxContainer = %RecordingsPage
@onready var btn_open_folder: ButtonCV = %BtnOpenFolder


func _update_pack_presentation(pack: PackInfo) -> void :
	if pack is PackInfo:
		if pack.icon: icon_viewer.texture = pack.icon
		pack_icon_area.visible = (pack.icon != null)
		lbl_pack_title.text = pack.display_name
		if pack.subtitle: lbl_subtitle.text = pack.subtitle
		lbl_subtitle.get_parent().visible = ( !pack.subtitle.is_empty())
		if pack.authors: lbl_authors.text = "by %s" % [", ".join(pack.authors)]
		authors_area.visible = ( !pack.authors.is_empty())
	else: pack_icon_area.hide();lbl_pack_title.text = "";lbl_subtitle.text = "";authors_area.hide()
func _update_pack_information(pack: PackInfo) -> void :
	if pack is PackInfo:
		btn_readme.enable( !pack.readme.is_empty())
		if pack.readme: lbl_readme.text = pack.readme
func _update_errors_report(report: PackedStringArray) -> void :
	for node: Node in error_list.get_children(): node.queue_free()
	if !report.is_empty(): btn_errors.enable(true);btn_errors.get_child(0).text = "⚠ Errors"
	else: btn_errors.enable(false)
	for line: String in report: var label: = Label.new();label.add_theme_color_override("font_color", Color.BLACK);label.text = line;error_list.add_child(label)
func _update_pack_book(pack: PackInfo) -> void :
	if M.session_type != M.SESSION_TYPE.DUB_FREESTYLE: return
	for child: Node in clip_book_container.get_children(): child.queue_free()

	if pack is PackInfo:
		var clip_book: ClipSelectionBook = CLIP_SELECTION_BOOK.instantiate()

		clip_book.functionality = ClipSelectionBook.FUNCTIONALITY.DUB
		clip_book.finished_errors.connect(_update_errors_report)
		clip_book.start.connect(attempt_game_from_clipbookpackage)
		clip_book.dub_rewatch.connect(watch_dub_recording)
		clip_book_container.add_child(clip_book)
		clip_book.load_pack(pack)


func initiate_session() -> void :
	match M.session_type:



		M.SESSION_TYPE.VIDEO_DUB: M.world.enter_dub_mode()
		M.SESSION_TYPE.DUB_FREESTYLE: M.world.enter_dub_freestyle()
func watch_dub_recording(folder_name: String) -> void :
	var interim_load_to_run_in_thread: Callable = func() -> GameplayResourceDubMode:

		var gameplay_resource: = GameplayResourceDubMode.new(tree.active_pack.global_folder_path)
		gameplay_resource.graft_dub_recording(FileManager.RECORDINGS_DUBS + gameplay_resource.pack_info.path_from_pack + folder_name)
		return gameplay_resource
	M.world.ActiveHint(true, "Checking")
	var thread: = Thread.new()
	thread.start(interim_load_to_run_in_thread)
	while thread.is_alive(): await get_tree().process_frame
	var dub_mode_resource: GameplayResourceDubMode = thread.wait_to_finish()
	if dub_mode_resource.failed_to_load or dub_mode_resource.no_video_file:
		M.world.ActiveHint(false, "Pack failed to load.")
		return

	Metro.cinema_came_from_dub_mode = true
	Metro.cinema_from_dub_mode = FileManager.RECORDINGS_DUBS + dub_mode_resource.pack_info.path_from_pack + folder_name
	Metro.cinema_name = [dub_mode_resource.pack_info.display_name, folder_name]
	M.world.ActiveHint(false)
	M.world.enter_dub_cinema()


func _dub_specific_visuals_setup() -> void :
	info_chunk.hide();options.hide()
	if M.session_type == M.SESSION_TYPE.DUB_FREESTYLE:
		dub_toggles.change_to_freestyle_variant()
		recordings_page.hide()
	else:
		btn_filtering.set_first_label_text("Recordings")
		dub_toggles.hide()
		var clip_controls_dub: Control = load("uid://ma2nx7223wpb").instantiate()
		clip_controls_dub.attempt_session.connect(attempt_game_from_clipbookpackage)
		tree.pack_selected.connect(clip_controls_dub.new_pack)
		page_clips.add_child(clip_controls_dub)


func _ready() -> void :
	_dub_specific_visuals_setup()
	if Profile.menu_slash != "Default/": _setup_bubble_color()
	menu_data.back_path = Metro.clip_selection_page_back_path



func attempt_game_from_clipbookpackage(package: ClipBookPackage) -> void :
	var interim_load_to_run_in_thread: Callable = func() -> GameplayResourceDubMode:
		var gameplay_resource: = GameplayResourceDubMode.new(tree.active_pack.global_folder_path)
		return gameplay_resource
	M.world.ActiveHint(true, "Checking")
	var thread: = Thread.new()
	thread.start(interim_load_to_run_in_thread)
	while thread.is_alive(): await get_tree().process_frame
	var dub_mode_resource: GameplayResourceDubMode = thread.wait_to_finish()
	if dub_mode_resource.failed_to_load or dub_mode_resource.no_video_file or !dub_mode_resource.pack_info.audio_files:
		M.world.ActiveHint(false, "Pack failed to load.")
		return
	M.world.ActiveHint(false)
	match Profile.dub_mode_clip_order_index:
		1:
			_sort_by_character(package, dub_mode_resource)
		2:
			_toggle_characters(package, dub_mode_resource)
			dub_mode_resource.omni_clip_array.data.shuffle()
		3:
			_toggle_characters(package, dub_mode_resource)
			dub_mode_resource.omni_clip_array.data.sort_custom(_sort_chronological)
		_: _toggle_characters(package, dub_mode_resource)
	Metro.gameplay_resource_dub_mode = dub_mode_resource
	initiate_session()


func _toggle_characters(package: ClipBookPackage, dub_mode_resource: GameplayResourceDubMode) -> void :
	if package.all_tags_names.is_empty(): return

	var include_all_clips: bool = package.selected_tags_names.is_empty()
	if include_all_clips: return
	var toggled_tags: PackedStringArray
	if include_all_clips: toggled_tags = package.all_tags_names
	else: toggled_tags = package.selected_tags_names
	for clip: OmniClip in dub_mode_resource.omni_clip_array.data:
		var tag_match_found: bool = false
		for tag: String in toggled_tags:
			if !tag: continue
			for character_tag: String in clip.dub_characters:
				if tag == character_tag:

					tag_match_found = true
					break
			if tag_match_found: break
		if !include_all_clips and !tag_match_found: clip.dub_use_as_is = true


func _sort_chronological(a: OmniClip, b: OmniClip) -> bool:
	var a_earliest: float = 999999999
	var b_earliest: float = 999999999
	for dub_timestamp: float in a.dub_timestamps: a_earliest = minf(a_earliest, dub_timestamp)
	for dub_timestamp: float in b.dub_timestamps: b_earliest = minf(b_earliest, dub_timestamp)
	return a_earliest < b_earliest


func _sort_by_character(package: ClipBookPackage, dub_mode_resource: GameplayResourceDubMode) -> void :
	if package.all_tags_names.is_empty(): return
	var characters_assigned_clips: Dictionary[String, Array] = {"": []}

	var include_all_clips: bool = package.selected_tags_names.is_empty()
	if include_all_clips:
		for tag: String in package.all_tags_names: characters_assigned_clips[tag] = []
	else: for tag: String in package.selected_tags_names: characters_assigned_clips[tag] = []
	for clip: OmniClip in dub_mode_resource.omni_clip_array.data:
		var tag_match_found: bool = false
		for tag: String in characters_assigned_clips.keys():
			if !tag: continue
			for charater_tag: String in clip.dub_characters:
				if tag == charater_tag:
					characters_assigned_clips[tag].append(clip)
					tag_match_found = true
					break
			if tag_match_found: break
		if !tag_match_found: characters_assigned_clips[""].append(clip)
		if !include_all_clips and !tag_match_found: clip.dub_use_as_is = true

	var sorted_selection: Array[OmniClip] = []
	for tag: String in characters_assigned_clips.keys():
		if tag == "": continue
		var tag_clips_list: Array = characters_assigned_clips[tag]
		tag_clips_list.sort_custom( func(a: OmniClip, b: OmniClip) -> bool: return a.file_name < b.file_name)
		sorted_selection.append_array(tag_clips_list)

	var tag_clips_list: Array = characters_assigned_clips[""]
	tag_clips_list.sort_custom( func(a: OmniClip, b: OmniClip) -> bool: return a.file_name < b.file_name)
	sorted_selection.append_array(tag_clips_list)

	dub_mode_resource.omni_clip_array.data = sorted_selection


func _create_recordings_list(pack: PackInfo) -> void :
	for child: Control in recordings_list.get_children(): child.queue_free()
	if pack.has_recordings_folder():
		%BtnOpenFolder.enable(true)
		_generate_dub_recordings_list(pack)
	else:
		%BtnOpenFolder.enable(false)


func _generate_dub_recordings_list(pack: PackInfo) -> void :
	for child: Control in recordings_list.get_children(): child.queue_free()
	btn_open_folder.enable(pack.has_recordings_folder())
	var child_packs_names: PackedStringArray
	var child_packs_location: String = FileManager.MODPACKS_VOICE + pack.path_from_pack
	var target_location: String = FileManager.RECORDINGS_DUBS + pack.path_from_pack
	if DirAccess.dir_exists_absolute(child_packs_location): child_packs_names = DirAccess.get_directories_at(child_packs_location)
	if !DirAccess.dir_exists_absolute(target_location): return
	var what: PackedStringArray = DirAccess.get_directories_at(target_location)
	for folder_name: String in what:
		if child_packs_names.has(folder_name): continue
		var btn_dub_archive: ButtonCV = BUTTON_CV.instantiate()
		var btn_label: = Label.new();btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER;btn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		btn_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn_label.add_theme_font_override("font", WAUKEGAN_LDO)
		btn_label.add_theme_color_override("font_color", Color.BLACK)
		btn_label.add_theme_font_size_override("font_size", 24)
		btn_label.text = folder_name
		btn_label.set_anchors_preset(Control.PRESET_FULL_RECT)

		btn_dub_archive.show()
		btn_dub_archive.material = btn_dub_archive.material.duplicate(true)
		btn_dub_archive.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn_dub_archive.custom_minimum_size = Vector2i(320, 48)
		btn_dub_archive.material.set_shader_parameter("node_size", Vector2i(320, 84))

		btn_dub_archive.button_clicked.connect(watch_dub_recording.bind(folder_name))

		btn_dub_archive.add_child(btn_label)
		recordings_list.add_child(btn_dub_archive)

func _open_specific_dub_recordings_folder() -> void : OS.shell_open(ProjectSettings.globalize_path(FileManager.RECORDINGS_DUBS + tree.active_pack.path_from_pack))
