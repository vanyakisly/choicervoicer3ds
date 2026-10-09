extends MatchMasterStandard



var chat_parser: ChatParserPanel


@onready var lbl_waiting_on_panelists: Label = %LblWaitingOnPanelists
@onready var lbl_pass_vote: Label = %LblPassVote
@onready var lbl_fail_vote: Label = %LblFailVote
@onready var btn_close_poll: ButtonCV = %BtnClosePoll

@onready var lines_btn_play_clip: ButtonCV = %LinesBtnPlayClip
@onready var lines_btn_play_performance: ButtonCV = %LinesBtnPlayPerformance
@onready var lines_btn_you_plus_clip: ButtonCV = %LinesBtnYouPlusClip


func _ready() -> void :
	add_child(uc)
	_setup_visuals()
	GENERIC_setup_misc()
	GENERIC_scene_model_setup()
	_setup_twitch_panel()
	if not await _intro(): reset_skip.call()
	await _gameplay_loop_method()


func _setup_twitch_panel() -> void :
	twitch_handler = TwitchHandler.new(Profile.twitch_channel_name, TwitchHandler.PARSE_TYPE.PANELIST)
	chat_parser = twitch_handler.parser_panel
	add_child(twitch_handler)
	if Profile.twitch_chatter_on: vox = TwitchAudienceVox.new();add_child(vox);twitch_handler.twitch_chat.OnMessage.connect(vox._new_chat)
	lbl_pass_vote.text = "Vote \"%s\" if you liked this performance!" % Profile.twitch_commands_binary_pass
	lbl_fail_vote.text = "Vote \"%s\" if you disliked this performance!" % Profile.twitch_commands_binary_fail
	btn_close_poll.button_clicked.connect(_stop_waiting_on_panelists)

	lines_btn_play_clip.button_clicked.connect(_on_lines_btn_play_clip_button_clicked)
	lines_btn_play_performance.button_clicked.connect(_on_lines_btn_play_performance_button_clicked)
	lines_btn_you_plus_clip.button_clicked.connect(_on_lines_btn_you_plus_clip_button_clicked)
	chat_parser.new_vote_occurred.connect(_refresh_panelists_waiting)



func _stop_waiting_on_panelists() -> void :
	for i: int in chat_parser.judge_states.size():
		if chat_parser.judge_states[i] == ChatParserPanel.VOTE_STATE.NONE: chat_parser.judge_states[i] = ChatParserPanel.VOTE_STATE.FAIL
	_performance_on_demand_stop()
	chat_parser.voting_ready.emit()
func _performance_on_demand_replay() -> void : conte_slots[0].play_pecho()
func _performance_on_demand_stop() -> void : conte_slots[0].stream_player.stop();current_vclip.stream_player.stop()
func _replay_clip() -> void : current_vclip.stream_player.play()





func _one_gameplay_loop() -> void :
	await GENERIC_RF_NewRound_PlayVclip()
	await GENERIC_RF_RecordContestants()
	chat_parser.reset()
	chat_parser.activate()
	await GENERIC_Skippable_RF_ContestantPerformancePlayback()
	await _RF_ContestantJudging()
	if dynasteen.round + 1 == statsteen.total_rounds: await GENERIC_RF_ContestantScoreFinale()
	else: await _RF_ContestantScoreUpdates()
	await GENERIC_RF_EndRoundButtonOptions()
	await GENERIC_RF_WrapupRoundNextRound()


func _RF_await_panel() -> bool:
	if chat_parser.everyone_voted: return false


	print("MatchMasterPanel | Awaiting all judges to vote...")
	_refresh_panelists_waiting()
	camera_master.to_cam_waiting_panelists()
	awaiting_panelists.show()
	await chat_parser.voting_ready
	awaiting_panelists.hide()
	return true









func _refresh_panelists_waiting() -> void :
	var output: String = "Waiting on "
	var unvoted: PackedStringArray = []
	var js: Array[ChatParserPanel.VOTE_STATE] = chat_parser.judge_states
	for i: int in range(5):
		if js[i] == ChatParserPanel.VOTE_STATE.NONE:
			var profile_username: String = Profile["twitch_panel_username_%s" % [i + 1]]
			var match_found: bool = false
			for username: String in unvoted:
				match_found = match_found or (username.to_lower() == "@" + profile_username.to_lower())
				if match_found: break
			if !match_found: unvoted.append("@" + profile_username)
	lbl_waiting_on_panelists.text = output + ", ".join(unvoted)


func _RF_ContestantJudging() -> void :

	var scorer: = Scorer.new()
	var individual_contestant_judge_scoring = func(i: int) -> int:

		var c: = conte_slots[i]
		var wave_img: Texture = c.round_waveform_image
		wave_img.set_size_override(Vector2i(256, 96))

		judge_master.JudgePanelsOff()
		judge_screen.texture = wave_img

		var scoref: float = scorer.tweaker_freaker(current_vclip.round_data, c.round_plmic_data, 0.85)
		var computer_score = clampi(roundi(scoref), 0, 5)
		var panel_count_pass: int = 0
		var panel_count_fail: int = 0
		for vote: ChatParserPanel.VOTE_STATE in chat_parser.judge_states:
			match vote:
				ChatParserPanel.VOTE_STATE.PASS: panel_count_pass += 1
				ChatParserPanel.VOTE_STATE.FAIL: panel_count_fail += 1
		var actual_score: int = mini(5 - panel_count_fail, maxi(computer_score, panel_count_pass))
		print("MatchMaster | scoref from computer: %1.4f" % scoref)
		c.round_scores.append(actual_score)
		return actual_score

	match_buttons.ButtonsVisibility(true, false, false)
	record_master.HideNonMantleItems(false)

	record_master.visible = false
	camera_master.HostAndJudges()

	VolumeService.tween_volume_chatter(VOLUME_FULL, 1.0)
	VolumeService.tween_volume_music(VOLUME_REDUCED, 1.0)
	_quickfix_connect_finish_stream_to_reset_labels()
	if sp:
		var score: int = individual_contestant_judge_scoring.call(0)

		var awaiting_judges: bool = chat_parser.everyone_voted
		var skip_host: bool = Profile.skip_host_post_playback



		await HD(config_host.match_singleplayer.round.c_post_listen, HM.SHIFTIN, HM.POPOUT)
		await _RF_await_panel()
		_performance_on_demand_stop()
		dynasteen.moment_points = score
		VolumeService.tween_volume_chatter(VOLUME_REDUCED, 1.0)
		VolumeService.tween_volume_music(VOLUME_QUIET, 0.5)













		var adjusted_panel_vote_slots: Array[ChatParserPanel.VOTE_STATE] = _fill_panelist_slots(chat_parser.judge_states, score)
		var panel_score: int = _panel_votes_count_pass(adjusted_panel_vote_slots)
		conte_slots[0].round_scores[-1] = panel_score
		if !Profile.faster_judge_scoring:
			camera_master.JudgeSuspenseSingle(4.6)
			judge_master.drumroll.play()
			judge_master.judge_win_from_slots(adjusted_panel_vote_slots, panel_score)
			await judge_master.drumroll.finished
		else:
			camera_master.JudgeSuspenseSingle(1.8)
			drumroll_short.play()
			judge_master.judge_win_from_slots(adjusted_panel_vote_slots, panel_score, 1.8)
			await drumroll_short.finished
		VolumeService.tween_volume_music_and_chatter(VOLUME_FULL, 1.0)
		if !Profile.skip_host_post_scoring:
			camera_master.HostAndJudges()
			var score_comment: PackedStringArray = []
			if panel_score in range(0, 7): score_comment = config_host.match_singleplayer.judging["score_" + str(panel_score)]


			else: score_comment = ["If you're reading this, something went wrong..."]
			await HD(score_comment, HM.POPIN, HM.POPOUT)


func _fill_panelist_slots(votes_in: Array[ChatParserPanel.VOTE_STATE], score: int) -> Array[ChatParserPanel.VOTE_STATE]:
	var votes: Array[ChatParserPanel.VOTE_STATE] = votes_in.duplicate()
	var slot_processing_order: Array[int] = [0, 1, 2, 3, 4];slot_processing_order.shuffle()
	for i: int in slot_processing_order:
		var vote: ChatParserPanel.VOTE_STATE = votes[i]
		match vote:
			ChatParserPanel.VOTE_STATE.NONE: votes[i] = ChatParserPanel.VOTE_STATE.FAIL
			ChatParserPanel.VOTE_STATE.COMPUTER:
				var current_pass_count: int = _panel_votes_count_pass(votes)
				votes[i] = ChatParserPanel.VOTE_STATE.PASS if current_pass_count < score else ChatParserPanel.VOTE_STATE.FAIL
	return votes


func _panel_votes_count(value: Array[ChatParserPanel.VOTE_STATE], type: ChatParserPanel.VOTE_STATE) -> int:
	var output: int = 0
	for v: ChatParserPanel.VOTE_STATE in value: if v == type: output += 1
	return output
func _panel_votes_count_computer(value: Array[ChatParserPanel.VOTE_STATE]) -> int: return _panel_votes_count(value, ChatParserPanel.VOTE_STATE.COMPUTER)
func _panel_votes_count_pass(value: Array[ChatParserPanel.VOTE_STATE]) -> int: return _panel_votes_count(value, ChatParserPanel.VOTE_STATE.PASS)




func _on_lines_btn_play_performance_button_clicked() -> void :

	var do_play: bool = !( !current_vclip.stream_player.playing and conte_slots[0].stream_player.playing)
	_stop_all_playback_buttons()
	if do_play: conte_slots[0].play_pecho();lines_btn_play_performance.get_child(0).text = "■ You"


func _on_lines_btn_play_clip_button_clicked() -> void :
	var do_play: bool = !(current_vclip.stream_player.playing and !conte_slots[0].stream_player.playing)
	_stop_all_playback_buttons()
	if do_play: current_vclip.stream_player.play();lines_btn_play_clip.get_child(0).text = "■ Clip"


func _on_lines_btn_you_plus_clip_button_clicked() -> void :
	var do_play: bool = !(current_vclip.stream_player.playing and conte_slots[0].stream_player.playing)
	_stop_all_playback_buttons()
	if do_play:
		conte_slots[0].play_pecho()
		current_vclip.stream_player.play()
		lines_btn_you_plus_clip.get_child(0).text = "■You+Clip"


func _stop_all_playback_buttons() -> void :
	if current_vclip.stream_player.playing: current_vclip.stream_player.stop()
	if conte_slots[0].stream_player.playing: conte_slots[0].stream_player.stop()
	lines_btn_play_clip.get_child(0).text = "▶ Clip"
	lines_btn_play_performance.get_child(0).text = "▶ You"
	lines_btn_you_plus_clip.get_child(0).text = "▶You+Clip"


func _reset_twitch_replay_buttons_labels() -> void :
	lines_btn_play_clip.get_child(0).text = "▶ Clip"
	lines_btn_play_performance.get_child(0).text = "▶ You"
	lines_btn_you_plus_clip.get_child(0).text = "▶You+Clip"

func _quickfix_connect_finish_stream_to_reset_labels() -> void :
	if !current_vclip.stream_player.finished.is_connected(_reset_twitch_replay_buttons_labels): current_vclip.stream_player.finished.connect(_reset_twitch_replay_buttons_labels)
	if !conte_slots[0].stream_player.finished.is_connected(_reset_twitch_replay_buttons_labels): conte_slots[0].stream_player.finished.connect(_reset_twitch_replay_buttons_labels)
