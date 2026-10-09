class_name ChatterPreviewerInstance extends MarginContainer



signal playing_chatter(playing_chatter: ConresChatterInstance)


@onready var audio_player: AudioStreamPlayer = %AudioPlayer
@onready var btn_play: ButtonCV = %BtnPlay
@onready var label: Label = %Label
@onready var lbl_keywords: Label = %LblKeywords


var chatter: ConresChatterInstance




func play_audio_if_match(check_chatter: ConresChatterInstance) -> void : if audio_player.playing and chatter != check_chatter: audio_player.stop()
func set_data(input: ConresChatterInstance, sample_name: String, keywords: PackedStringArray) -> void :
	chatter = input
	if chatter.audio:
		audio_player.stream = chatter.audio
		audio_player.volume_linear = chatter.volume
		btn_play.button_clicked.connect(_toggle_audio_playing)
	else: btn_play.enable(false)
	audio_player.finished.connect( func() -> void : btn_play.set_first_label_text("▶"))
	label.text = sample_name
	lbl_keywords.text = "Broad Keywords: " if chatter.is_contains else "Exact Keywords: "
	lbl_keywords.text += "\"%s\"" % "\", \"".join(keywords)


func _toggle_audio_playing() -> void :
	if audio_player.playing:
		audio_player.stop();btn_play.set_first_label_text("▶")
	else: audio_player.play();btn_play.set_first_label_text("■")
