class_name VoiceLinePreviewer
extends HBoxContainer

signal play_pressed

@onready var chk_include_clip = $ChkIncludeClip
@onready var texture_rect = $TextureRect
@onready var label = $VBoxContainer / Label
@onready var label_2 = $VBoxContainer / Label2
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

var path_nonignore: String
var path_ignore: String

func get_from_path(path: String) -> void :

	if Profile.ignored_packs_voice.has(path):
		path_ignore = path
		chk_include_clip.button_pressed = false
		label.text = path.get_file().right(path.get_file().length() - 8)
	else:
		path_nonignore = path
		path_ignore = path.get_base_dir() + "/_ignore_" + path.get_file()
		label.text = path.get_file()
	label_2.text = path
	var uc: = UC.new()
	add_child(uc)
	var img: Texture2D
	img = uc.get_image(M.OVEEP.VOICE, path, false, Vector2i(48, 48))
	if img == null:
		img = uc.get_image(M.OVEEP.VOICE, path.get_base_dir() + "/_pack_filler_image", false, Vector2i(48, 48))
		if img == null:
			img = uc.get_image(M.OVEEP.MENU, "no_image", true, Vector2i(48, 48))
	texture_rect.texture = img
	var audio: AudioStream
	audio = uc.get_audio(M.OVEEP.VOICE, path, false)
	audio_stream_player.stream = audio



func _on_chk_include_clip_toggled(toggled_on):
	if toggled_on:
		label_2.text = path_nonignore
		clip_toggle(path_ignore, toggled_on)
	else:
		label_2.text = path_ignore
		clip_toggle(path_nonignore, toggled_on)


func clip_toggle(path: String, toggled_on: bool):
	var base = path.get_base_dir()
	var file = path.get_file()
	var extension: String = ""
	var dir = DirAccess.open("user://game/packs_voice/" + base)
	if dir.file_exists(file + ".wav"):
		extension = ".wav"
	elif dir.file_exists(file + ".mp3"):
		extension = ".mp3"
	elif dir.file_exists(file + ".ogg"):
		extension = ".ogg"
	else: return
	if toggled_on:
		var new = "user://game/packs_voice/" + path + extension
		var err = DirAccess.rename_absolute("user://game/packs_voice/" + base + "/_ignore_" + file + extension, new)
		print(error_string(err))
	else:
		var new = "user://game/packs_voice/" + base + "/_ignore_" + file + extension
		var err = DirAccess.rename_absolute("user://game/packs_voice/" + path + extension, new)
		print(error_string(err))


func _on_btn_play_button_clicked():
	play_pressed.emit()
	audio_stream_player.play()
