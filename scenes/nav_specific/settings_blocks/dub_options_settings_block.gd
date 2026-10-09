extends Control



@onready var list: VBoxContainer = %List
@onready var chk_mute_backing_track: CheckButton = %ChkMuteBackingTrack
@onready var option_clip_order: OptionButton = %OptionClipOrder
@onready var chk_hard_one_take: CheckButton = %ChkHardOneTake
@onready var chk_hard_mute: CheckButton = %ChkHardMute
@onready var chk_hard_no_captions: CheckButton = %ChkHardNoCaptions




func change_to_freestyle_variant() -> void :
	option_clip_order.get_parent().hide()
	chk_hard_one_take.get_parent().hide()


func _connect_signals() -> void :
	chk_mute_backing_track.toggled.connect(Profile._set_dub_mode_mute_backing_track)
	option_clip_order.item_selected.connect(_option_id_to_profile)
	chk_hard_one_take.toggled.connect(Profile._set_dub_mode_hard_one_take)
	chk_hard_mute.toggled.connect(Profile._set_dub_mode_hard_mute_clips)
	chk_hard_no_captions.toggled.connect(Profile._set_dub_mode_hard_no_captions)
func _option_id_to_profile(_dummy: int) -> void :
	Profile.dub_mode_clip_order_index = option_clip_order.get_selected_id()


func _initial_values_from_profile() -> void :
	chk_mute_backing_track.button_pressed = Profile.dub_mode_mute_backing_track
	match Profile.dub_mode_clip_order_index:
		0: option_clip_order.selected = 2
		1: option_clip_order.selected = 0
		2: option_clip_order.selected = 3
		3: option_clip_order.selected = 1
	chk_hard_one_take.button_pressed = Profile.dub_mode_hard_one_take
	chk_hard_mute.button_pressed = Profile.dub_mode_hard_mute_clips
	chk_hard_no_captions.button_pressed = Profile.dub_mode_hard_no_captions


func _ready() -> void :
	_initial_values_from_profile()
	_connect_signals()
