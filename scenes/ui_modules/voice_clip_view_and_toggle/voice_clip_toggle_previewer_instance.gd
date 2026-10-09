class_name VoiceClipTogglePreviewerInstance extends MarginContainer



signal playing_clip(playing_clip: OmniClip)


@onready var clip_audio_player: AudioStreamPlayer = %ClipAudioPlayer
@onready var btn_play: ButtonCV = %BtnPlay
@onready var clip_thumbnail: TextureRect = %ClipThumbnail
@onready var label: Label = %Label
@onready var check_button: CheckButton = %CheckButton
@onready var lbl_dub_only: Label = %LblDubOnly


var clip: OmniClip: set = _set_clip




func play_audio_if_match(check_clip: OmniClip) -> void : if clip_audio_player.playing and clip != check_clip: clip_audio_player.stop()


func _toggle_audio_playing() -> void :
	if clip_audio_player.playing:
		clip_audio_player.stop();btn_play.set_first_label_text("▶")
	else: clip_audio_player.play();btn_play.set_first_label_text("■")
func _check_button_text_change(toggled_on: bool) -> void :
	if toggled_on:
		check_button.text = "Included"
		Profile.clip_include(clip)
	else:
		check_button.text = "Excluded"
		Profile.clip_exclude(clip)


func _set_clip(value: OmniClip) -> void :
	clip = value
	if clip_audio_player and !clip.error_flags:
		clip_audio_player.stream = clip.clip_audio
		clip_audio_player.finished.connect( func() -> void : btn_play.set_first_label_text("▶"))
	if btn_play:
		if clip.error_flags: btn_play.enable(false)
		else: btn_play.button_clicked.connect(_toggle_audio_playing)
	if clip_thumbnail: clip_thumbnail.texture = clip.clip_texture
	if label:
		if !clip.error_flags: label.text = clip.file_name
		else: label.text = "⚠" + clip.file_name
	if check_button:
		check_button.toggled.connect(_check_button_text_change)
		check_button.button_pressed = !Profile.ignored_clips.has(clip.seen_path)
	if lbl_dub_only: lbl_dub_only.visible = clip.dub_only
