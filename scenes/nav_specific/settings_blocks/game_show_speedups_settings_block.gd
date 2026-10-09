extends VBoxContainer


@onready var chk_faster_scoring: CheckButton = %ChkFasterScoring
@onready var chk_skip_host_post_record: CheckButton = %ChkSkipHostPostRecord
@onready var chk_skip_host_post_playback: CheckButton = %ChkSkipHostPostPlayback
@onready var chk_skip_host_post_scoring: CheckButton = %ChkSkipHostPostScoring


func _ready() -> void :
	_set_from_profile()
	_connect_signals()


func _set_from_profile() -> void :
	chk_faster_scoring.button_pressed = Profile.faster_judge_scoring
	chk_skip_host_post_record.button_pressed = Profile.skip_host_post_record
	chk_skip_host_post_playback.button_pressed = Profile.skip_host_post_playback
	chk_skip_host_post_scoring.button_pressed = Profile.skip_host_post_scoring


func _connect_signals() -> void :
	chk_faster_scoring.toggled.connect(Profile._set_faster_judge_scoring)
	chk_skip_host_post_record.toggled.connect(Profile._set_skip_host_post_record)
	chk_skip_host_post_playback.toggled.connect(Profile._set_skip_host_post_playback)
	chk_skip_host_post_scoring.toggled.connect(Profile._set_skip_host_post_scoring)
