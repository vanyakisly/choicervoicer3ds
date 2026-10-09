extends VBoxContainer


@onready var chk_show_clip_captions: CheckButton = %ChkShowClipCaptions
@onready var chk_show_clip_file_path: CheckButton = %ChkShowClipFilePath
@onready var chk_fully_mute_music: CheckButton = %ChkFullyMuteMusic
@onready var chk_autosave_performances: CheckButton = %ChkAutosavePerformances
@onready var spin_timing_light_time: SpinBox = %SpinTimingLightTime


func _ready() -> void :
	_set_from_profile()
	_connect_signals()


func _set_from_profile() -> void :
	spin_timing_light_time.value = Profile.countdown_time
	chk_show_clip_captions.button_pressed = Profile.show_captions
	chk_show_clip_file_path.button_pressed = Profile.show_clip_file_name
	chk_fully_mute_music.button_pressed = Profile.fully_mute_music
	chk_autosave_performances.button_pressed = Profile.automatically_save_clips


func _connect_signals() -> void :
	spin_timing_light_time.value_changed.connect(Profile._set_countdown_time)
	chk_show_clip_captions.toggled.connect(Profile._set_show_captions)
	chk_show_clip_file_path.toggled.connect(Profile._set_show_clip_file_name)
	chk_fully_mute_music.toggled.connect(Profile._set_fully_mute_music)
	chk_autosave_performances.toggled.connect(Profile._set_automatically_save_clips)
