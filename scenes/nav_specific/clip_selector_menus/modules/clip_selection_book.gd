class_name ClipSelectionBook extends Control


signal start(package: ClipBookPackage)
signal finished_errors(errors: PackedStringArray)
signal dub_rewatch(folder_name: String)


enum FUNCTIONALITY{DEFAULT, DUB, ALL_PACKS}


const PAGE_SIZE: int = 63
const GAME_SHOW_ROUND_LIMIT: int = 50
const BUTTON_CV = preload("res://scene/module/button/button_cv.tscn")
const WAUKEGAN_LDO = preload("res://graphic/font/Waukegan LDO.ttf")

const CLIP_BOOK_ALL_VOICE_PACKS = preload("res://scenes/nav_specific/clip_selector_menus/modules/clip_book_all_voice_packs.tscn")


@onready var spin_wheel_animator: AnimationPlayer = %SpinWheelAnimator
@onready var spin_wheel: TextureRect = %SpinWheel
@onready var loaded_screen: VBoxContainer = %LoadedScreen
@onready var loading_screen: Control = %LoadingScreen


@onready var btn_start: ButtonCV = %BtnStart
@onready var btn_book_left: ButtonCV = %BtnBookLeft
@onready var btn_book_right: ButtonCV = %BtnBookRight
@onready var btn_open_folder: ButtonCV = %BtnOpenFolder
@onready var btn_minus: ButtonCV = %BtnMinus
@onready var btn_plus: ButtonCV = %BtnPlus


@onready var lbl_voices_selected: Label = %LblVoicesSelected
@onready var lbl_on_page_of: Label = %LblOnPageOf
@onready var lbl_rounds: Label = %LblRounds
@onready var lbl_scanning: Label = %LblScanning
@onready var lbl_tags_or_characters: Label = %LblTagsOrCharacters
@onready var lbl_dub_info: Label = %LblDubInfo


@onready var clip_audio_preview_player: AudioStreamPlayer = %ClipAudioPreviewPlayer
@onready var tags_list: VBoxContainer = %TagsList
@onready var thumbnails_list: HFlowContainer = %ThumbnailsList
@onready var start_bar: HBoxContainer = %StartBar
@onready var tags_section: VBoxContainer = %TagsSection
@onready var v_bar: VSeparator = %VBar
@onready var round_selection: HBoxContainer = %RoundSelection
@onready var clips_list: VBoxContainer = %ClipsList
@onready var dub_records_list: VBoxContainer = %DubRecordsList
@onready var saved_recordings_list: VBoxContainer = %SavedRecordingsList
@onready var clip_book: HBoxContainer = %ClipBook
@onready var book_capsule: Control = %BookCapsule
@onready var icon_dub_mode: TextureRect = %IconDubMode


@export var full_collection: OmniClipCollection: set = _set_full_collection
@export var working_collection: OmniClipCollection: set = _set_working_collection


@export var voice_pack_tree_node: VoicePackTree


var page_index: int: set = _set_page_index
var folder_path_from_pack: String
var internal_rounds: int: set = _set_internal_rounds
var actual_rounds: int: set = _set_actual_rounds
var start_bar_visible: bool = true:
	set(value):
		start_bar_visible = value
		start_bar.visible = start_bar_visible

var functionality: = FUNCTIONALITY.DEFAULT



var input_tree: VoicePackTree
var selector: PackWeightedSelector




func _change_to_dub() -> void :
	lbl_tags_or_characters.text = "Filter Characters:"
	round_selection.hide()
	lbl_dub_info.visible = M.session_type == M.SESSION_TYPE.VIDEO_DUB
	clips_list.hide();dub_records_list.show()
func _generate_dub_recordings_list() -> void :
	var child_packs_names: PackedStringArray
	var child_packs_location: String = FileManager.MODPACKS_VOICE + folder_path_from_pack
	var target_location: String = FileManager.RECORDINGS_DUBS + folder_path_from_pack
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

		btn_dub_archive.button_clicked.connect(dub_rewatch.emit.bind(folder_name))

		btn_dub_archive.add_child(btn_label)
		saved_recordings_list.add_child(btn_dub_archive)




func full_collection_from_pack(pack: PackInfo) -> OmniClipCollection:
	var output: = OmniClipCollection.new()
	if functionality == FUNCTIONALITY.DUB: output.generate_from_pack_info(pack, false)
	else: output.generate_from_pack_info(pack)
	return output
func load_pack(pack: PackInfo) -> void :
	if pack.unique_all_voice_packs:
		functionality = FUNCTIONALITY.ALL_PACKS
		_change_connections_AVP()
		spin_wheel_animator.stop();loading_screen.hide();loaded_screen.show()
		load_all_voice_packs_variant()
		selector.clip_validated.connect(_check_update_rounds_AVP)
		internal_rounds = Profile.default_rounds
		return
	folder_path_from_pack = pack.path_from_pack
	lbl_scanning.text = "\n\n\n\n\n\nScanning %s voices..." % pack.audio_files.size()
	btn_open_folder.enable(pack.has_recordings_folder())
	var thread: = Thread.new()
	thread.start(full_collection_from_pack.bind(pack))
	while thread.is_alive(): await get_tree().process_frame
	full_collection = thread.wait_to_finish()
	if functionality == FUNCTIONALITY.DUB and pack.folder_name:
		var target_video: VideoStream = VD.get_video_agnostic(pack.global_folder_path + "dub_video")
		if !pack.audio_files:
			btn_start.set_first_label_text("no dub\n audio found");btn_start.call_deferred("enable", false)
		elif !(target_video == null):
			if !M.THISISDEMO: btn_start.set_first_label_text("Start!");btn_start.call_deferred("enable", !M.THISISDEMO)
			else: btn_start.set_first_label_text("Demo Only");btn_start.call_deferred("enable", false)
		else:
			btn_start.set_first_label_text("missing\n`dub_video.ogv`");btn_start.call_deferred("enable", false)
	if functionality == FUNCTIONALITY.DEFAULT and pack.has_dub_video_file: icon_dub_mode.show()
	for tag: String in full_collection.get_tags():
		var chk: = CheckBox.new()
		chk.add_theme_font_size_override("font_size", 14);chk.add_theme_color_override("font_color", Color.BLACK);chk.add_theme_color_override("font_pressed_color", Color.BLACK)
		if M.session_type == M.SESSION_TYPE.VIDEO_DUB and !pack.preselected_dub_characters.is_empty(): chk.button_pressed = pack.preselected_dub_characters.has(tag)
		elif pack.preselected_voice_tags.is_empty(): chk.button_pressed = true
		else: chk.button_pressed = pack.preselected_voice_tags.has(tag)
		chk.text = tag
		chk.set_meta("tag", tag)
		tags_list.add_child(chk)
		chk.pressed.connect(update_working_collection_from_tags)
	if tags_list.get_child_count() == 0 or M.session_type == M.SESSION_TYPE.DUB_FREESTYLE: tags_section.hide();v_bar.hide()
	if full_collection.size() <= PAGE_SIZE: btn_book_left.hide();btn_book_right.hide()
	spin_wheel_animator.stop();loading_screen.hide();loaded_screen.show()
	finished_errors.emit(full_collection.error_reports)
	if functionality == FUNCTIONALITY.DUB and folder_path_from_pack: _generate_dub_recordings_list()
	update_working_collection_from_tags(false)
func update_working_collection_from_tags(run_avp: bool = true) -> void :
	match functionality:
		FUNCTIONALITY.DEFAULT, FUNCTIONALITY.DUB:
			page_index = 0
			var tags: PackedStringArray = []
			for chk: CheckBox in tags_list.get_children():
				if chk.button_pressed: tags.append(chk.get_meta("tag", ""))
			if tags.is_empty(): working_collection = full_collection
			else: working_collection = full_collection.get_clips_with_tags(tags)
			if Profile.clip_range_on and functionality != FUNCTIONALITY.DUB:
				update_working_collection_from_length()
			else: update_page_from_working_collection()
		FUNCTIONALITY.ALL_PACKS: if run_avp: load_all_voice_packs_variant()
func update_working_collection_from_length() -> void :
	var original_length: int = working_collection.size()
	working_collection = working_collection.get_clips_filtered_for_length(Profile.clip_range_minimum, Profile.clip_range_maximum)
	var amount_filtered: int = original_length - working_collection.size()
	update_page_from_working_collection(amount_filtered)
func update_page_from_working_collection(length_filtered_clip_count: int = 0) -> void :
	if (length_filtered_clip_count):
		lbl_voices_selected.text = "%s Voices | %s excluded due to length" % [working_collection.data.size(), length_filtered_clip_count]
	else: lbl_voices_selected.text = "%s Voices Selected" % working_collection.data.size()
	if !working_collection.data.size(): page_index = 0;lbl_on_page_of.text = ""
	else: lbl_on_page_of.text = "Page %s of %s" % [page_index + 1, ceili(working_collection.data.size() / float(PAGE_SIZE))]
	for thumbnail: Node in thumbnails_list.get_children(): thumbnail.queue_free()
	var starting_index: int = page_index * PAGE_SIZE
	var clip_page: Array[OmniClip] = working_collection.data.slice(starting_index, starting_index + PAGE_SIZE)
	var frame_buffer: int = 0
	var collective_clip_time: float = 0.0
	var estimated_total_time: float = 0.0
	for clip: OmniClip in clip_page:
		var thumbnail: = ClipPreviewThumbnail.new(clip)
		thumbnail.custom_minimum_size = Vector2i(64, 64)
		thumbnails_list.add_child(thumbnail)
		thumbnail.listen.connect(play_or_stop_audio)
		frame_buffer += 1
		var clip_length_time: float = clip.get_length()
		collective_clip_time += clip_length_time


		estimated_total_time += 4.0 + clip_length_time * (1.0 + minf(6.0, 2.5 / pow(clip_length_time, 2.0)))
		if frame_buffer % 14 == 0: await get_tree().process_frame
	var collective_time_string: String
	var estimated_time_string: String
	collective_time_string = "Collective length of selected clips: %2.0f:%02.0f" % [floori(collective_clip_time / 60.0), fmod(collective_clip_time, 60.0)]
	estimated_time_string = "Estimated playtime: %2.0f:%02.0f" % [floori(estimated_total_time / 60.0), fmod(estimated_total_time, 60.0)]
	lbl_dub_info.text = "%s\n%s" % [collective_time_string, estimated_time_string]

func play_or_stop_audio(audio: AudioStream) -> void :
	if clip_audio_preview_player.stream == audio and clip_audio_preview_player.playing: clip_audio_preview_player.stop()
	elif audio:
		clip_audio_preview_player.stream = audio
		clip_audio_preview_player.play()

func load_all_voice_packs_variant() -> void :
	if !voice_pack_tree_node: return
	if clip_book: clip_book.queue_free()
	var all_clip_book: Control = CLIP_BOOK_ALL_VOICE_PACKS.instantiate()
	for child: Node in book_capsule.get_children(): child.queue_free()
	book_capsule.add_child(all_clip_book)
	selector = PackWeightedSelector.new()
	Metro.coroutine_password_pack_weighted_selector = Time.get_ticks_usec()
	selector.coroutine_key = Metro.coroutine_password_pack_weighted_selector
	selector.finished.connect(all_clip_book.call_deferred.bind("clear_label", selector))
	var thread: = Thread.new()
	thread.start(selector.process_from_tree.bind(voice_pack_tree_node))

	while thread.is_alive(): await get_tree().process_frame
	thread.wait_to_finish()



func _page_left() -> void : page_index -= 1;update_page_from_working_collection()
func _page_right() -> void : page_index += 1;update_page_from_working_collection()
func _decrease_rounds() -> void : internal_rounds = wrapi(actual_rounds - 1, 1, mini(working_collection.size(), GAME_SHOW_ROUND_LIMIT) + 1)
func _increase_rounds() -> void : internal_rounds = wrapi(actual_rounds + 1, 1, mini(working_collection.size(), GAME_SHOW_ROUND_LIMIT) + 1)
func _open_specific_dub_recordings_folder() -> void : OS.shell_open(ProjectSettings.globalize_path(FileManager.RECORDINGS_DUBS + folder_path_from_pack))
func _start_a_game() -> void : start.emit(ClipBookPackage.new(working_collection, actual_rounds, full_collection, tags_list))


func _change_connections_AVP() -> void :
	btn_start.button_clicked.disconnect(_start_a_game)
	if !M.THISISDEMO: btn_start.button_clicked.connect(_start_a_game_AVP)
	btn_minus.button_clicked.disconnect(_decrease_rounds);btn_minus.button_clicked.connect(_decrease_rounds_AVP)
	btn_plus.button_clicked.disconnect(_increase_rounds);btn_plus.button_clicked.connect(_increase_rounds_AVP)
func _decrease_rounds_AVP() -> void : internal_rounds = wrapi(actual_rounds - 1, 1, mini(selector.validated_clips.size(), GAME_SHOW_ROUND_LIMIT) + 1)
func _increase_rounds_AVP() -> void : internal_rounds = wrapi(actual_rounds + 1, 1, mini(selector.validated_clips.size(), GAME_SHOW_ROUND_LIMIT) + 1)
func _start_a_game_AVP() -> void :
	var collection: = OmniClipCollection.new()
	collection.data = selector.validated_clips
	start.emit(ClipBookPackage.new(collection, actual_rounds))
func _update_availability_of_start() -> void :
	if !functionality == FUNCTIONALITY.ALL_PACKS: return
	if !selector: return
	btn_start.enable(actual_rounds <= selector.validated_clips.size() and !M.THISISDEMO)


func _ready() -> void :
	loaded_screen.hide();loading_screen.show()
	spin_wheel_animator.play("SpinWheel")
	match functionality:
		FUNCTIONALITY.DUB: _change_to_dub()

		_: lbl_dub_info.hide();round_selection.show();clips_list.show();dub_records_list.hide()
	if M.THISISDEMO: btn_start.set_first_label_text("Demo Only");btn_start.enable(false)




func _set_full_collection(value: OmniClipCollection) -> void :
	full_collection = value
	working_collection = full_collection
	internal_rounds = clampi(Profile.default_rounds, 1, mini(full_collection.size(), GAME_SHOW_ROUND_LIMIT))
func _set_working_collection(value: OmniClipCollection) -> void :
	working_collection = value
	internal_rounds = internal_rounds
	if working_collection.size() > 0: lbl_on_page_of.text = ""
func _set_internal_rounds(value: int) -> void :
	internal_rounds = value
	var target_size: int
	if functionality == FUNCTIONALITY.ALL_PACKS: target_size = selector.validated_clips.size()
	else: target_size = working_collection.size()
	if internal_rounds == 0: actual_rounds = 0
	else: actual_rounds = clampi(internal_rounds, 1, mini(target_size, GAME_SHOW_ROUND_LIMIT))
func _set_actual_rounds(value: int) -> void :
	actual_rounds = maxi(0, value)
	lbl_rounds.text = str(actual_rounds)
	btn_start.enable(actual_rounds > 0 and !M.THISISDEMO)
func _set_page_index(value: int) -> void :
	page_index = wrapi(value, 0, ceili(working_collection.data.size() / float(PAGE_SIZE)))
func _check_update_rounds_AVP(_clip: OmniClip) -> void :
	if !get_tree(): return
	await get_tree().process_frame
	internal_rounds = internal_rounds
