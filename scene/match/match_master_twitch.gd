extends MatchMasterBase

signal vote_concluded

@onready var twitch_audience_globe: TwitchGlobe = %TwitchAudienceGlobe

var twitch_handler: = TwitchHandler.new(Profile.twitch_channel_name)
var chat_parser: ChatParserVote = twitch_handler.parser_vote

@onready var vote_labels_grid: GridContainer = %VoteLabelsGrid
@onready var lines_are_open: Control = %LinesAreOpen
@onready var cam_globe_spiral: Camera3D = %CamGlobeSpiral
@onready var animation_player_cam_globe_spiral: AnimationPlayer = %AnimationPlayerCamGlobeSpiral
@onready var cam_panopticon: Camera3D = %CamPanopticon
@onready var animation_player_cam_panopticon: AnimationPlayer = %AnimationPlayerCamPanopticon
@onready var lbl_send_in_your_vote: Label = %LblSendInYourVote
@onready var lbl_votes_in: Label = %LblVotesIn

@onready var lines_btn_play_clip: ButtonCV = %LinesBtnPlayClip
@onready var lines_btn_play_performance: ButtonCV = %LinesBtnPlayPerformance
@onready var lines_btn_you_plus_clip: ButtonCV = %LinesBtnYouPlusClip
@onready var inactivity_timer: Timer = %InactivityTimer
@onready var lbl_timer: RichTextLabel = %LblTimer


func _ready() -> void :
	add_child(uc)
	_setup_visuals()
	_setup_twitch_channel()
	GENERIC_setup_misc()
	_setup_additional_twitch()
	GENERIC_scene_model_setup()
	if not await _intro(): reset_skip.call()
	await _gameplay_loop_method()


func _setup_visuals() -> void :
	setup_absolute_score_screen()
	animation_player_cam_panopticon.play("PanopticonView")
	lbl_send_in_your_vote.text = "SEND IN YOUR VOTE AT THE TOLL-FREE %s CHATROOM" % (Profile.twitch_channel_name).to_upper()
	host_master.PopOut()
	record_master.visible = false
	lines_are_open.hide()
	if not Profile.twitch_vote_type_is_binary:
		for index: int in vote_labels_grid.get_child_count():
			var c: Label = vote_labels_grid.get_child(index)
			c.text = "Vote %s with \"%s\"" % [index, Profile.get("twitch_commands_score_" + str(index))]
	else:
		for c: Label in vote_labels_grid.get_children(): c.hide()
		vote_labels_grid.columns = 1
		vote_labels_grid.get_child(2).show()
		vote_labels_grid.get_child(4).show()
		vote_labels_grid.get_child(2).text = "Vote \"%s\" if you liked this performance!" % Profile.twitch_commands_binary_pass
		vote_labels_grid.get_child(4).text = "Vote \"%s\" if you disliked this performance!" % Profile.twitch_commands_binary_fail


func _setup_additional_twitch() -> void :
	music_polling.finished.connect( func() -> void : vote_concluded.emit())
	twitch_handler.twitch_chat.OnMessage.connect( func(_chatter: Chatter) -> void :
		lbl_votes_in.text = "%s VOTES ARE IN" % chat_parser.voter_log.size()
		if Profile.twitch_close_poll_inactivity_bool: inactivity_timer.start(Profile.twitch_close_poll_inactivity_int)
		if Profile.twitch_close_poll_votes_bool and int(chat_parser.voter_log.size() >= Profile.twitch_close_poll_votes_int):
			vote_concluded.emit()
		)
	if Profile.twitch_close_poll_inactivity_bool:
		inactivity_timer.timeout.connect( func() -> void : vote_concluded.emit())


func _setup_twitch_channel() -> void :
	add_child(twitch_handler)
	if Profile.twitch_chatter_on: vox = TwitchAudienceVox.new();add_child(vox);twitch_handler.twitch_chat.OnMessage.connect(vox._new_chat)


func _intro() -> bool:
	if skip_triggered: return false

	camera_master.HostAndVclip()
	twitch_audience_globe.hide_all_number_labels()
	if statsteen.contestant_count == 1:
		await HD(config_host.match_singleplayer.intro.a_welcome, HM.SHIFTIN, HM.NONE, true)
		if skip_triggered: return false
		camera_master.ConIntroCam(0)
		if skip_triggered: return false
		HD(config_host.match_singleplayer.intro.b_contestant)
		if skip_triggered: return false
		conte_talk_audio.stream = conte_slots[0].talk_audio.intro_greet
		await dialogue_master.batch_sentence_finished
		if skip_triggered: return false
		conte_talk_audio.play()
		await dialogue_master.entire_batch_finished
		if skip_triggered: return false
		conte_talk_audio.stop()

		animation_player_cam_globe_spiral.play("GlobeSpiral")
		cam_globe_spiral.make_current()
		await HD(config_host.twitch_standard.intro_audience, HM.SHIFTIN)
		if skip_triggered: return false
		camera_master.HostAndVclip()
		await HD(config_host.match_singleplayer.intro.d_explanation, HM.NONE, HM.POPOUT)
		if skip_triggered: return false
	else:
		if skip_triggered: return false
		await HD(config_host.match_multiplayer.intro.a_welcome, HM.SHIFTIN, HM.NONE, true)
		if skip_triggered: return false
		await HD(config_host.match_multiplayer.intro.b_contestants)
		if skip_triggered: return false
		for i in range(statsteen.contestant_count):
			camera_master.ConIntroCam(i)
			if skip_triggered: return false
			HD(ContestantIntroSentence(i))
			if skip_triggered: return false
			conte_talk_audio.stream = conte_slots[i].talk_audio.intro_greet
			await dialogue_master.batch_sentence_finished
			if skip_triggered: return false
			conte_talk_audio.play()
			await dialogue_master.entire_batch_finished
		GENERIC_IRF_StopAllContestants()
		if skip_triggered: return false
		conte_talk_audio.stop()
		camera_master.JudgeSweep()
		await HD(config_host.match_multiplayer.intro.c_judges, HM.POPIN)
		if skip_triggered: return false
		camera_master.HostAndVclip()
		await HD(config_host.match_multiplayer.intro.d_explanation, HM.NONE, HM.POPOUT)
		if skip_triggered: return false
	return true


func _gameplay_loop_method() -> void :
	twitch_audience_globe.show_all_number_labels()
	while true: await _one_gameplay_loop()





func _one_gameplay_loop() -> void :
	await GENERIC_RF_NewRound_PlayVclip()
	await GENERIC_RF_RecordContestants()
	await GENERIC_Skippable_RF_ContestantPerformancePlayback()
	await _RF_VotingBegin()
	await _RF_ContestantTwitchJudging()
	if dynasteen.round + 1 == statsteen.total_rounds: await GENERIC_RF_ContestantScoreFinale()
	else: await _RF_ContestantScoreUpdates()
	await GENERIC_RF_EndRoundButtonOptions()
	chat_parser.clear()
	await GENERIC_RF_WrapupRoundNextRound()


func _RF_VotingBegin() -> void :

	match_buttons.ButtonsVisibility(true, false, false)
	record_master.HideNonMantleItems(false)
	judge_screen.texture = load("res://graphic/image/cv_temp_preview_banner.png")
	record_master.visible = false
	camera_master.HostAndJudges()
	var c: = conte_slots[0]
	var wave_img: Texture = c.round_waveform_image
	wave_img.set_size_override(Vector2i(256, 96))
	judge_screen.texture = wave_img

	VolumeService.tween_volume_music(VOLUME_MUTED, 2.0)
	VolumeService.tween_volume_chatter(VOLUME_FULL, 0.8)
	_quickfix_connect_finish_stream_to_reset_labels()
	chat_parser.activate()
	await HD(config_host.twitch_standard.a_audience_turn_1, HM.SHIFTIN, HM.NONE, false, false)
	await HD(config_host.twitch_standard.b_audience_turn_2, HM.NONE, HM.SHIFTOUT, false, true)
	music_match.stream_paused = true
	VolumeService.tween_volume_music(VOLUME_FULL, 0.1)
	cam_panopticon.make_current()
	animation_player_cam_panopticon.play("PanopticonView")
	lines_are_open.show()
	music_polling.play()

	lbl_votes_in.text = "%s VOTES ARE IN" % chat_parser.voter_log.size()
	lbl_timer.activate()
	VolumeService.tween_volume_chatter(VOLUME_REDUCED, 0.8)
	await vote_concluded


func _RF_ContestantTwitchJudging() -> void :
	inactivity_timer.stop()
	conte_slots[0].stream_player.stop()
	current_vclip.stream_player.stop()
	lines_are_open.hide()
	chat_parser.deactivate()

	var c: = conte_slots[0]
	var absolute_score = func():
		print("MatchMaster | entering absolute score")
		multiuse_stream.stream = load("res://audio/sfx/sfx-wham.wav")


		print("MatchMaster | last vote triggered")
		judge_screen.texture = absolute_score_texture
		multiuse_stream.play()
		var shake_cam_tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
		var cam: Camera3D = camera_master.cam_judge_suspense
		cam.rotation.z = 0.007 * TAU
		shake_cam_tween.tween_property(cam, "rotation:z", 0.0, 0.4)
	var music_down_and_swap: Callable = func() -> void :
		VolumeService.tween_volume_music(VOLUME_MUTED, 0.1)
		await get_tree().create_timer(0.1).timeout
		music_polling.stop()
		music_match.stream_paused = false
		VolumeService.tween_volume_music(VOLUME_REDUCED, 1.5)
		VolumeService.tween_volume_chatter(VOLUME_FULL, 1.5)

	camera_master.HostAndJudges()

	music_down_and_swap.call()
	var scoref: float = twitch_handler.parser_vote.get_scoref()
	var scorei: int = floori(scoref * 1.2)
	c.round_scores.append(scorei)
	dynasteen.moment_points = scorei




	if !Profile.skip_host_post_playback: await HD(config_host.twitch_standard.c_polls_closed, HM.SHIFTIN, HM.POPOUT)
	VolumeService.tween_volume_music_and_chatter(VOLUME_QUIET, 1.5)
	camera_master.JudgeSuspenseSingle(1.8)
	drumroll_short.play()
	twitch_audience_globe.animate_score(scoref / 5.0, 1.5)
	await twitch_audience_globe.score_animation_finished
	if scorei == 6: absolute_score.call()
	if drumroll_short.playing: await drumroll_short.finished
	VolumeService.tween_volume_music_and_chatter(VOLUME_FULL, 1.0)
	if !Profile.skip_host_post_scoring:
		camera_master.HostAndJudges()
		var score_comment: PackedStringArray = []
		if scorei in range(0, 7): score_comment = config_host.match_singleplayer.judging["score_" + str(scorei)]
		else: score_comment = ["If you're reading this, something went wrong..."]
		await HD(score_comment, HM.POPIN, HM.POPOUT)


func _RF_ContestantScoreUpdates() -> void :

	var math: = Math.new()
	var contestant_percentages_this_round: Array = []
	var contestant_percentage_change_this_round: Array = []
	var max_percent_change_this_round: float = 0.0
	for c in conte_slots:
		var c_percent: float = math.array_mean(c.round_scores) / 5.0
		contestant_percentages_this_round.append(c_percent)
		contestant_percentage_change_this_round.append(c_percent - c.previous_percent)
		max_percent_change_this_round = max(max_percent_change_this_round, abs(c.previous_percent - c_percent))
	var max_time_change: float = min(0.5, max_percent_change_this_round) / 0.5 * 1.25
	var individual_contestant_updating = func(i: int):

		var c: = conte_slots[i]
		var pt: = c.progress_tracker

		pt.AddRoundImage(current_vclip.image, c.round_scores[-1])




		c.progress_tracker.NewPercentAnimate2(contestant_percentages_this_round[i], contestant_percentage_change_this_round[i] / max_percent_change_this_round * max_time_change)

	camera_master.ContestantsProgress()

	twitch_audience_globe.reset()

	await get_tree().create_timer(0.15).timeout
	for i in conte_slots.size():
		individual_contestant_updating.call(i)
	await get_tree().create_timer(max_time_change).timeout
	for c in conte_slots:
		match c.round_scores[-1]:
			0: c.random_delay_talk("score_0")
			1: c.random_delay_talk("score_1")
			2: c.random_delay_talk("score_2")
			3: c.random_delay_talk("score_3")
			4: c.random_delay_talk("score_4")
			5, 6: c.random_delay_talk("score_5")







func _on_music_match_finished(): music_match.play()



func _on_match_buttons_match_menu_opened():
	dialogue_master.accepting_user_input = false


func _on_match_buttons_match_menu_closed():
	dialogue_master.accepting_user_input = true


func _on_btn_close_poll_button_clicked() -> void :
	vote_concluded.emit()


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
