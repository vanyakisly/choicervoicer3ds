extends VBoxContainer
signal changes_to_filtering
const BUFFER_WAIT_TIME: float = 1.0 / 6.0
@onready var signal_send_timer: Timer = %SignalSendTimer
@onready var chk_clips_length_filtered: CheckButton = %ChkClipsLengthFiltered
@onready var chk_tag_nested_folders: CheckButton = %ChkTagNestedFolders
@onready var num_min_length: SpinBox = %NumMinLength
@onready var num_max_length: SpinBox = %NumMaxLength
@onready var num_new_clip_bias: SpinBox = %NumNewClipBias
@onready var chk_clips_ordered: CheckButton = %ChkClipsOrdered
@onready var num_default_rounds: SpinBox = %NumDefaultRounds

@onready var min_clip_length: VBoxContainer = %MinClipLength
func _queue_timer(_filler: Variant) -> void : signal_send_timer.start(BUFFER_WAIT_TIME)
func _set_from_profile() -> void :
	chk_clips_length_filtered.button_pressed = Profile.clip_range_on
	chk_tag_nested_folders.button_pressed = Profile.auto_tag_with_nested_folders
	min_clip_length.visible = Profile.clip_range_on
	num_min_length.value = Profile.clip_range_minimum
	num_max_length.value = Profile.clip_range_maximum
	num_new_clip_bias.value = int(Profile.unseen_percent * 100.0)
	chk_clips_ordered.button_pressed = !Profile.shuffle
	num_default_rounds.value = Profile.default_rounds

func _connect_signals() -> void :
	chk_clips_length_filtered.toggled.connect(Profile._set_clip_range_on)
	chk_clips_length_filtered.toggled.connect( func(toggled_on: bool) -> void : min_clip_length.visible = toggled_on)
	chk_tag_nested_folders.toggled.connect(Profile._set_auto_tag_with_nested_folders)
	num_min_length.value_changed.connect(Profile._set_clip_range_minimum)
	num_max_length.value_changed.connect(Profile._set_clip_range_maximum)
	num_new_clip_bias.value_changed.connect(Profile._set_unseen_percent)
	chk_clips_ordered.toggled.connect( func(toggled: bool) -> void : Profile.shuffle = int( !toggled))
	num_default_rounds.value_changed.connect(Profile._set_default_rounds)


	chk_clips_length_filtered.toggled.connect(_queue_timer)
	num_min_length.value_changed.connect(_queue_timer)
	num_max_length.value_changed.connect(_queue_timer)
func _ready() -> void :
	_set_from_profile()
	signal_send_timer.timeout.connect(changes_to_filtering.emit)
	_connect_signals()
