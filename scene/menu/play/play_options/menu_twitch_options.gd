extends MenuBase

@onready var li_ed_twitch_channel: LineEdit = %LiEdTwitchChannel
@onready var chk_case_sensitive: CheckBox = %ChkCaseSensitive
@onready var chk_exact_phrase: CheckBox = %ChkExactPhrase
@onready var chk_multivote: CheckBox = %ChkMultivote
@onready var chk_use_binary: CheckBox = %ChkUseBinary
@onready var chk_use_score: CheckBox = %ChkUseScore
@onready var li_ed_binary_fail: LineEdit = %LiEdBinaryFail
@onready var li_ed_binary_pass: LineEdit = %LiEdBinaryPass
@onready var li_ed_score_0: LineEdit = %LiEdScore0
@onready var li_ed_score_1: LineEdit = %LiEdScore1
@onready var li_ed_score_2: LineEdit = %LiEdScore2
@onready var li_ed_score_3: LineEdit = %LiEdScore3
@onready var li_ed_score_4: LineEdit = %LiEdScore4
@onready var li_ed_score_5: LineEdit = %LiEdScore5

@onready var chk_advanced: CheckButton = %ChkAdvanced
@onready var chk_close_poll: CheckBox = %ChkClosePoll
@onready var spin_close_poll: SpinBox = %SpinClosePoll
@onready var li_ed_close_poll: LineEdit = %LiEdClosePoll
@onready var chk_close_inactivity: CheckBox = %ChkCloseInactivity
@onready var li_ed_close_inactivity: LineEdit = %LiEdCloseInactivity

@onready var voting_option: OptionButton = %VotingOption

func _ready() -> void :

	li_ed_twitch_channel.text_changed.connect( func(text: String) -> void : M.data.settings.twitch.channel_name = "TriassicPierce" if text.is_empty() else text)

	li_ed_binary_fail.text_changed.connect( func(text: String) -> void : M.data.settings.twitch.commands.binary_fail = "!fail" if text.is_empty() else text)
	li_ed_binary_pass.text_changed.connect( func(text: String) -> void : M.data.settings.twitch.commands.binary_pass = "!pass" if text.is_empty() else text)

	li_ed_score_0.text_changed.connect( func(text: String) -> void : M.data.settings.twitch.commands.score_0 = "!score0" if text.is_empty() else text)
	li_ed_score_1.text_changed.connect( func(text: String) -> void : M.data.settings.twitch.commands.score_1 = "!score1" if text.is_empty() else text)
	li_ed_score_2.text_changed.connect( func(text: String) -> void : M.data.settings.twitch.commands.score_2 = "!score2" if text.is_empty() else text)
	li_ed_score_3.text_changed.connect( func(text: String) -> void : M.data.settings.twitch.commands.score_3 = "!score3" if text.is_empty() else text)
	li_ed_score_4.text_changed.connect( func(text: String) -> void : M.data.settings.twitch.commands.score_4 = "!score4" if text.is_empty() else text)
	li_ed_score_5.text_changed.connect( func(text: String) -> void : M.data.settings.twitch.commands.score_5 = "!score5" if text.is_empty() else text)

	chk_case_sensitive.toggled.connect( func(toggled: bool) -> void : M.data.settings.twitch.is_case_sensitive = toggled)
	chk_exact_phrase.toggled.connect( func(toggled: bool) -> void : M.data.settings.twitch.is_exact_phrase = toggled)
	chk_multivote.toggled.connect( func(toggled: bool) -> void : M.data.settings.twitch.allow_duplicate_voting = toggled)

	chk_use_binary.toggled.connect( func(toggled: bool) -> void :

		M.data.settings.twitch.vote_type_is_binary = toggled
		chk_use_score.button_pressed = not toggled
		)
	chk_use_score.toggled.connect( func(toggled: bool) -> void :

		M.data.settings.twitch.vote_type_is_binary = not toggled
		chk_use_binary.button_pressed = not toggled
		)

	chk_advanced.toggled.connect( func(toggled: bool) -> void : M.data.settings.twitch.advanced_options = toggled)
	chk_close_poll.toggled.connect( func(toggled: bool) -> void : M.data.settings.twitch.close_poll_votes_bool = toggled)
	li_ed_close_poll.text_changed.connect( func(text: String) -> void : M.data.settings.twitch.close_poll_votes_int = int(text))

	chk_close_inactivity.toggled.connect( func(toggled: bool) -> void : M.data.settings.twitch.close_poll_inactivity_bool = toggled)
	li_ed_close_inactivity.text_changed.connect( func(text: String) -> void : M.data.settings.twitch.close_poll_inactivity_int = int(text))



	var twitch: Dictionary = M.data.settings.twitch
	li_ed_twitch_channel.text = twitch.channel_name
	chk_case_sensitive.button_pressed = twitch.is_case_sensitive
	chk_exact_phrase.button_pressed = twitch.is_exact_phrase
	chk_multivote.button_pressed = twitch.allow_duplicate_voting
	chk_use_binary.button_pressed = twitch.vote_type_is_binary
	chk_use_score.button_pressed = !twitch.vote_type_is_binary
	chk_close_poll.button_pressed = twitch.close_poll_votes_bool
	li_ed_close_poll.text = str(int(twitch.close_poll_votes_int))
	chk_close_inactivity.button_pressed = twitch.close_poll_inactivity_bool
	li_ed_close_inactivity.text = str(int(twitch.close_poll_inactivity_int))

	li_ed_binary_fail.text = twitch.commands.binary_fail
	li_ed_binary_pass.text = twitch.commands.binary_pass
	li_ed_score_0.text = twitch.commands.score_0
	li_ed_score_1.text = twitch.commands.score_1
	li_ed_score_2.text = twitch.commands.score_2
	li_ed_score_3.text = twitch.commands.score_3
	li_ed_score_4.text = twitch.commands.score_4
	li_ed_score_5.text = twitch.commands.score_5

	chk_advanced.button_pressed = twitch.advanced_options
	advanced_toggle(self, twitch.advanced_options)



func _on_btn_choose_standard_button_clicked() -> void :
	call_slide("play/play_match_singleplayer")


func _on_chk_advanced_toggled(toggled_on: bool) -> void :
	for child: Control in get_children(): advanced_toggle(child, toggled_on)

func advanced_toggle(c: Control, toggle: bool) -> void :
	if c.get_meta("advanced", false): c.visible = toggle
	for child: Control in c.get_children(): advanced_toggle(child, toggle)


func _setup_voting_option() -> void :
	voting_option.add_item("Binary", 0)
	voting_option.add_item("Score", 1)
	voting_option.add_item("Emotion", 2)
	voting_option.select(M.data.settings.twitch.using_vote_type)
