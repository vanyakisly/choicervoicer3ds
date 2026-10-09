class_name SubtitleBatchingClipLine extends ColorRect

signal selected(s: SubtitleBatchingClipLine)


@onready var btn_pick: ButtonCV = %BtnPick
@onready var tex_clip_image: TextureRect = %TexClipImage
@onready var lbl_local_name: Label = %LblLocalName
@onready var lbl_subtitle: Label = %LblSubtitle

var upath: String
var clip_image: Image
var clip_audio: AudioStream

var file_name: String
var subtitle_text: String

var _btn_pick_on: bool = false

func assign(_upath: String) -> void :
	var uc: = UC.new()
	upath = _upath
	clip_image = uc.get_image_direct(upath)
	if clip_image == null: clip_image = uc.get_image_direct(upath.get_base_dir() + "/_pack_filler_image")
	subtitle_text = FileAccess.get_file_as_string(upath + ".txt").c_escape().replace("\\'", "'").replace("\\\"", "\"")
	clip_audio = uc.get_audio_direct(upath)
	file_name = upath.get_file()

	if clip_audio == null:
		subtitle_text = "⚠ Clip audio failed to load."
	elif clip_audio.get_length() > 60.0:
		subtitle_text = "⚠ Clip is longer than 60 seconds and will not get loaded."
	else:
		_btn_pick_on = true
	uc.queue_free()


func _ready() -> void :
	btn_pick.enable(_btn_pick_on)
	tex_clip_image.texture = ImageTexture.create_from_image(clip_image)
	lbl_local_name.text = file_name
	lbl_subtitle.text = subtitle_text


func _on_btn_pick_button_clicked() -> void : selected.emit(self)
