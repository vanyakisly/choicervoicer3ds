class_name MetadataEditorClip extends Control



enum AUDIO_PLAYER_STATE{OFF, PLAYING, PAUSED}


@onready var file_dialog: FileDialog = %FileDialog
@onready var btn_save: ButtonCV = %BtnSave
@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var lbl_clip_name: Label = %LblClipName
@onready var clip_texture: TextureRect = %ClipTexture
@onready var lbl_clip_image_name: Label = %LblClipImageName
@onready var line_caption_text: LineEdit = %LineCaptionText
@onready var section_tags: MetadataArrayEditorInstance = %SECTION_Tags
@onready var section_dub_timestamps: MetadataArrayEditorInstance = %SECTION_DubTimestamps
@onready var section_dub_characters: MetadataArrayEditorInstance = %SECTION_DubCharacters
@onready var lbl_length: Label = %LblLength
@onready var audio_interface_manager_bufferless: AudioInterfaceManagerBufferless = %AudioInterfaceManagerBufferless
@onready var btn_listen_stop: ButtonCV = %BtnListenStop
@onready var chk_dub_only_clip: CheckButton = %ChkDubOnlyClip


var clip: OmniClip: set = _set_clip
var played_fully_at_least_once: bool = false
var audio_player_state: AUDIO_PLAYER_STATE
var clip_image_name: String:
	set(value):
		clip_image_name = value
		if lbl_clip_image_name: lbl_clip_image_name.text = "Image: %s" % clip_image_name
		if clip.image_sibling_name: clip.image_sibling_name = clip_image_name




func _inject_path_to_clip(input: OmniClip, global_path: String) -> void :
	input.generate_from_audio_file_exact(global_path, false);clip = input
	file_dialog.root_subfolder = ProjectSettings.globalize_path(clip.global_containing_folder)
func load_stn_from_global_path(global_path: String) -> void :
	show()
	var new_clip: = OmniClip.new(M.CLIP_USES.EDITING)
	_inject_path_to_clip(new_clip, global_path)


func save_current() -> void :
	btn_save.enable(false);btn_save.set_first_label_text("Saving...")
	clip.image_sibling_name = clip_image_name
	clip.clip_caption = line_caption_text.text
	clip.tags = PackedStringArray(section_tags.get_array())
	clip.dub_timestamps = PackedFloat32Array(section_dub_timestamps.get_array())
	clip.dub_characters = PackedStringArray(section_dub_characters.get_array())
	clip.dub_only = chk_dub_only_clip.button_pressed
	clip.save_config()
	btn_save.set_first_label_text("Saved!"); await get_tree().create_timer(2.0).timeout
	btn_save.enable(true);btn_save.set_first_label_text("Save")


func _open_file_dialog() -> void : file_dialog.popup()
func _file_image_chosen(path: String) -> void :
	clip_image_name = path.get_file()
	var chosen: Texture2D = VD.get_texture(clip.global_containing_folder + path.get_file())
	clip_texture.texture = chosen
	lbl_clip_image_name.text = path.get_file()


func _play_clip() -> void :
	match audio_player_state:
		AUDIO_PLAYER_STATE.OFF:
			btn_listen_stop.set_first_label_text("Pause")
			if !played_fully_at_least_once: audio_interface_manager_bufferless.first()
			else: audio_interface_manager_bufferless.again()
			audio_player_state = AUDIO_PLAYER_STATE.PLAYING
			return
		AUDIO_PLAYER_STATE.PAUSED:
			btn_listen_stop.set_first_label_text("Pause")
			audio_interface_manager_bufferless.renew()
			audio_player_state = AUDIO_PLAYER_STATE.PLAYING
			return
		AUDIO_PLAYER_STATE.PLAYING:
			btn_listen_stop.set_first_label_text("Listen")
			audio_interface_manager_bufferless.pause()
			audio_player_state = AUDIO_PLAYER_STATE.PAUSED
			return
func _play_finished() -> void :
	audio_player_state = AUDIO_PLAYER_STATE.OFF
	played_fully_at_least_once = true
	btn_listen_stop.set_first_label_text("Listen")


func _autofill_timestamp() -> void :



	var clip_name: String = clip.file_name_agnostic
	var pieces: PackedStringArray = clip_name.split("_", false)
	if !pieces: return
	pieces = pieces[-1].split(" ", false)
	if !pieces: return
	var final_piece: String = pieces[-1]

	var final_split: PackedStringArray = final_piece.replacen("-", "/").replacen(".", "/").split("/", false)
	if ![2, 3].has(final_split.size()): return
	var seconds: int = final_split[-2].to_int()
	var millis: float = final_split[-1].to_float()
	var minutes: int = 0
	if final_split.size() == 3: minutes = final_split[-3].to_int()
	var timestamp: float = minutes * 60.0 + seconds + millis / 1000.0

	if section_dub_timestamps.get_array().has(timestamp): return
	var new_editor_cell: MetadataArrayEditorCell = section_dub_timestamps.new_cell()
	new_editor_cell.set_text(str(timestamp))




func _input(event: InputEvent) -> void : if event.is_action_pressed("F3"): _autofill_timestamp();M.sfx_select.play()


func _set_clip(value: OmniClip) -> void :

	clip = value
	if lbl_clip_name: lbl_clip_name.text = clip.file_name
	if clip.error_flags and btn_save:
		btn_save.enable(false);btn_save.set_first_label_text("Load Error")
		scroll_container.hide()
		return
	elif btn_save:
		btn_save.enable(true);btn_save.set_first_label_text("Save")
		scroll_container.show()
	if clip_texture: clip_texture.texture = clip.clip_texture
	clip_image_name = clip.image_sibling_name
	if line_caption_text: line_caption_text.text = clip.clip_caption
	if section_tags: section_tags.load_clip_data(clip.tags)
	if section_dub_timestamps: section_dub_timestamps.load_clip_data(clip.dub_timestamps)
	if section_dub_characters: section_dub_characters.load_clip_data(clip.dub_characters)
	if lbl_length: lbl_length.text = "Length: %1.2f seconds" % clip.clip_audio.get_length()
	if audio_interface_manager_bufferless: audio_interface_manager_bufferless.load_omniclip(clip)
	if chk_dub_only_clip: chk_dub_only_clip.button_pressed = clip.dub_only
