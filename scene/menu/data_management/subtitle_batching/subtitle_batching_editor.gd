class_name SubtitleBatchingEditor extends HBoxContainer

var uc: = UC.new()

@onready var clip_image: TextureRect = %ClipImage
@onready var lbl_local_name: Label = %LblLocalName
@onready var subtitle_text_edit: LineEdit = %SubtitleTextEdit
@onready var btn_play_stop: ButtonCV = %BtnPlayStop
@onready var btn_save: ButtonCV = %BtnSave
@onready var btn_reload: ButtonCV = %BtnReload
@onready var btn_open_folder: ButtonCV = %BtnOpenFolder
@onready var clip_audio_player: AudioStreamPlayer = %ClipAudioPlayer

var active_instance: SubtitleBatchingClipLine:
	set(value):
		if value != active_instance:
			active_instance = value
			assign()
var active_path: String:
	set(value):
		active_path = value
		btn_open_folder.enable(true) if DirAccess.dir_exists_absolute(active_path.get_base_dir()) else btn_open_folder.enable(false)


func _ready() -> void :
	add_child(uc)


func assign(instance: SubtitleBatchingClipLine = active_instance) -> void :
	_reset_save_button_text()
	subtitle_text_edit.editable = true
	subtitle_text_edit.text = instance.subtitle_text
	clip_image.texture = ImageTexture.create_from_image(instance.clip_image)
	clip_audio_player.stream = instance.clip_audio
	lbl_local_name.text = instance.file_name
	active_path = instance.upath
	btn_save.enable(false)
	btn_open_folder.enable(true)
	if instance.clip_audio:
		clip_audio_player.stream = instance.clip_audio
		btn_play_stop.enable(true)
		btn_save.enable(false)
		btn_reload.enable(true)
	else:
		btn_play_stop.enable(false)
		btn_reload.enable(false)
	btn_play_stop.get_child(0).text = "▶"
	if clip_audio_player.playing: clip_audio_player.stop()


func detach() -> void :
	_reset_save_button_text()
	subtitle_text_edit.editable = false
	subtitle_text_edit.text = ""
	clip_image.texture = load("res://game_default/packs_menu/The Choicer Voicer's Default Menu/no_image.png")
	clip_audio_player.stream = null
	btn_save.enable(false)
	btn_play_stop.enable(false)
	btn_reload.enable(false)
	btn_open_folder.enable(false)
	btn_play_stop.get_child(0).text = "▶"
	if clip_audio_player.playing: clip_audio_player.stop()


func _reset_save_button_text() -> void :
	btn_save.get_child(0).text = "Save"


func _on_btn_play_stop_button_clicked() -> void :
	if clip_audio_player.playing:
		clip_audio_player.stop()
		btn_play_stop.get_child(0).text = "▶"
	else:
		clip_audio_player.play()
		btn_play_stop.get_child(0).text = "■"


func _on_clip_audio_player_finished() -> void :
	btn_play_stop.get_child(0).text = "▶"


func _on_btn_open_folder_button_clicked() -> void :
	if DirAccess.dir_exists_absolute(active_path.get_base_dir()):
		OS.shell_open(ProjectSettings.globalize_path(active_path.get_base_dir()))


func _on_btn_save_button_clicked() -> void :
	var file: = FileAccess.open(active_path + ".txt", FileAccess.WRITE)
	if file:
		file.store_string(subtitle_text_edit.text.c_unescape())
		file.close()
		btn_save.get_child(0).text = "Saved!"
		active_instance.subtitle_text = subtitle_text_edit.text
		active_instance.lbl_subtitle.text = active_instance.subtitle_text
	else:
		btn_save.get_child(0).text = "ERROR"


func _on_btn_reload_button_clicked() -> void :
	subtitle_text_edit.text = FileAccess.get_file_as_string(active_path + ".txt").c_escape().replace("\\'", "'").replace("\\\"", "\"")
	_reset_save_button_text()


func _on_subtitle_text_edit_text_changed(new_text: String) -> void :
	btn_save.enable(new_text != active_instance.subtitle_text)
	btn_save.get_child(0).text = "Save"
