extends VBoxContainer
@onready var line_edit_channel_name: LineEdit = %LineEditChannelName
@onready var chk_show_advanced_options: CheckButton = %ChkShowAdvancedOptions
@onready var chk_allow_multi_voting: CheckButton = %ChkAllowMultiVoting
@onready var chk_enable_case_sensitivity: CheckButton = %ChkEnableCaseSensitivity
@onready var spin_box_vote_end: SpinBox = %SpinBoxVoteEnd
@onready var chk_vote_end: CheckButton = %ChkVoteEnd
@onready var spin_box_inactivity_time: SpinBox = %SpinBoxInactivityTime
@onready var chk_inactivity_time: CheckButton = %ChkInactivityTime
@onready var chk_enable_chatter: CheckButton = %ChkEnableChatter
@onready var chk_binary_vote: CheckBox = %ChkBinaryVote
@onready var chk_score_vote: CheckBox = %ChkScoreVote
@onready var line_edit_binary_fail: LineEdit = %LineEditBinaryFail
@onready var line_edit_binary_pass: LineEdit = %LineEditBinaryPass
@onready var line_edit_vote_0: LineEdit = %LineEditVote0
@onready var line_edit_vote_1: LineEdit = %LineEditVote1
@onready var line_edit_vote_2: LineEdit = %LineEditVote2
@onready var line_edit_vote_3: LineEdit = %LineEditVote3
@onready var line_edit_vote_4: LineEdit = %LineEditVote4
@onready var line_edit_vote_5: LineEdit = %LineEditVote5
@onready var spin_box_chatter_global_cooldown: SpinBox = %SpinBoxChatterGlobalCooldown
@onready var spin_box_chatter_user_cooldown: SpinBox = %SpinBoxChatterUserCooldown
@onready var __list__advanced_options: VBoxContainer = %"[LIST]_AdvancedOptions"
@onready var __list__chatter_options: VBoxContainer = %"[LIST]_ChatterOptions"
func _set_from_profile() -> void :
	line_edit_channel_name.text = Profile.twitch_channel_name
	chk_show_advanced_options.button_pressed = Profile.twitch_advanced_options
	__list__advanced_options.visible = Profile.twitch_advanced_options
	chk_enable_case_sensitivity.button_pressed = Profile.twitch_is_case_sensitive
	chk_allow_multi_voting.button_pressed = Profile.twitch_allow_duplicate_voting
	chk_binary_vote.button_pressed = Profile.twitch_vote_type_is_binary;chk_score_vote.button_pressed = !Profile.twitch_vote_type_is_binary
	chk_vote_end.button_pressed = Profile.twitch_close_poll_votes_bool
	chk_inactivity_time.button_pressed = Profile.twitch_close_poll_inactivity_bool

	spin_box_vote_end.value = Profile.twitch_close_poll_votes_int
	spin_box_inactivity_time.value = Profile.twitch_close_poll_inactivity_int
	line_edit_binary_pass.text = Profile.twitch_commands_binary_pass
	line_edit_binary_fail.text = Profile.twitch_commands_binary_fail
	line_edit_vote_0.text = Profile.twitch_commands_score_0
	line_edit_vote_1.text = Profile.twitch_commands_score_1
	line_edit_vote_2.text = Profile.twitch_commands_score_2
	line_edit_vote_3.text = Profile.twitch_commands_score_3
	line_edit_vote_4.text = Profile.twitch_commands_score_4
	line_edit_vote_5.text = Profile.twitch_commands_score_5
	chk_enable_chatter.button_pressed = Profile.twitch_chatter_on
	__list__chatter_options.visible = Profile.twitch_chatter_on
	spin_box_chatter_global_cooldown.value = Profile.twitch_chatter_global_cooldown
	spin_box_chatter_user_cooldown.value = Profile.twitch_chatter_user_cooldown
func _connect_signals() -> void :
	line_edit_channel_name.text_changed.connect(Profile._set_twitch_channel_name)
	chk_show_advanced_options.toggled.connect(Profile._set_twitch_advanced_options)
	chk_show_advanced_options.toggled.connect( func(toggled_on: bool) -> void : __list__advanced_options.visible = toggled_on)
	chk_enable_case_sensitivity.toggled.connect(Profile._set_twitch_is_case_sensitive)
	chk_allow_multi_voting.toggled.connect(Profile._set_twitch_allow_duplicate_voting)
	chk_binary_vote.toggled.connect(Profile._set_twitch_vote_type_is_binary)
	chk_vote_end.toggled.connect(Profile._set_twitch_close_poll_votes_bool)
	chk_inactivity_time.toggled.connect(Profile._set_twitch_close_poll_inactivity_bool)

	spin_box_vote_end.value_changed.connect(Profile._set_twitch_close_poll_votes_int)
	spin_box_inactivity_time.value_changed.connect(Profile._set_twitch_close_poll_inactivity_int)
	line_edit_binary_pass.text_changed.connect(Profile._set_twitch_commands_binary_pass)
	line_edit_binary_fail.text_changed.connect(Profile._set_twitch_commands_binary_fail)
	line_edit_vote_0.text_changed.connect(Profile._set_twitch_commands_score_0)
	line_edit_vote_1.text_changed.connect(Profile._set_twitch_commands_score_1)
	line_edit_vote_2.text_changed.connect(Profile._set_twitch_commands_score_2)
	line_edit_vote_3.text_changed.connect(Profile._set_twitch_commands_score_3)
	line_edit_vote_4.text_changed.connect(Profile._set_twitch_commands_score_4)
	line_edit_vote_5.text_changed.connect(Profile._set_twitch_commands_score_5)
	chk_enable_chatter.toggled.connect(Profile._set_twitch_chatter_on)
	chk_enable_chatter.toggled.connect( func(toggled_on: bool) -> void : __list__chatter_options.visible = toggled_on)
	spin_box_chatter_global_cooldown.value_changed.connect(Profile._set_twitch_chatter_global_cooldown)
	spin_box_chatter_user_cooldown.value_changed.connect(Profile._set_twitch_chatter_user_cooldown)
func _ready() -> void :
	_set_from_profile()
	_connect_signals()
