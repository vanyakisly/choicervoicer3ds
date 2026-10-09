class_name MatchMasterStandard extends MatchMasterBase


@onready var awaiting_panelists: Control = %AwaitingPanelists

var twitch_handler: TwitchHandler


func _ready() -> void :
	add_child(uc)
	_setup_visuals()
	GENERIC_setup_misc()
	GENERIC_scene_model_setup()
	_setup_twitch_chatter()
	if not await _intro(): reset_skip.call()
	await _gameplay_loop_method()


func _setup_visuals() -> void :
	host_master.PopOut()
	record_master.hide();awaiting_panelists.hide()
	setup_absolute_score_screen()

func _setup_twitch_chatter() -> void :
	if Profile.twitch_chatter_on:
		twitch_handler = TwitchHandler.new(Profile.twitch_channel_name, TwitchHandler.PARSE_TYPE.NONE);add_child(twitch_handler)
		vox = TwitchAudienceVox.new();add_child(vox);twitch_handler.twitch_chat.OnMessage.connect(vox._new_chat)

func _intro() -> bool:
	if skip_triggered: return false

	camera_master.HostAndVclip()
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
		camera_master.JudgeSweep()
		await HD(config_host.match_singleplayer.intro.c_judges, HM.SHIFTIN)
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

func _gameplay_loop_method() -> void : while true: await _one_gameplay_loop()





func _one_gameplay_loop() -> void :
	await GENERIC_RF_NewRound_PlayVclip()
	await GENERIC_RF_RecordContestants()
	await GENERIC_Skippable_RF_ContestantPerformancePlayback()
	await _RF_ContestantJudging()
	if dynasteen.round + 1 == statsteen.total_rounds: await GENERIC_RF_ContestantScoreFinale()
	else: await _RF_ContestantScoreUpdates()
	await GENERIC_RF_EndRoundButtonOptions()
	await GENERIC_RF_WrapupRoundNextRound()


func _RF_ContestantJudging() -> void :

	var scorer: = Scorer.new()
	VolumeService.tween_volume_music_and_chatter(VOLUME_REDUCED, 1.5)
	var individual_contestant_judge_scoring = func(i: int) -> int:

		var c: = conte_slots[i]
		var wave_img: Texture = c.round_waveform_image
		wave_img.set_size_override(Vector2i(256, 96))

		judge_master.JudgePanelsOff()
		judge_screen.texture = wave_img

		var scorei: int
		if M.session_type == M.SESSION_TYPE.STANDARD_JABRONI:
			scorei = randi_range(0, 5)
			print("MatchMaster | scoref: %1.4f (Jabroni RNG)" % scorei)
		else:
			var scoref: float = scorer.tweaker_freaker(current_vclip.round_data, c.round_plmic_data, 0.85)
			scorei = clampi(roundi(scoref), 0, 6)
			print("MatchMaster | scoref: %1.4f" % scoref)
		c.round_scores.append(scorei)
		return scorei
	var absolute_score = func():
		print("MatchMaster | entering absolute score")
		multiuse_stream.stream = load("res://audio/sfx/sfx-wham.wav")
		await judge_master.last_vote
		print("MatchMaster | last vote triggered")
		judge_screen.texture = absolute_score_texture
		multiuse_stream.play()
		var shake_cam_tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
		var cam: Camera3D = camera_master.cam_judge_suspense
		cam.rotation.z = 0.007 * TAU
		shake_cam_tween.tween_property(cam, "rotation:z", 0.0, 0.4)

	match_buttons.ButtonsVisibility(true, false, false)
	record_master.HideNonMantleItems(false)
	if sp: judge_screen.texture = conte_slots[0].round_waveform_image
	else: judge_screen.texture = preload("res://graphic/image/cv_temp_preview_banner.png")
	record_master.visible = false
	camera_master.HostAndJudges()

	if sp:

		var score = individual_contestant_judge_scoring.call(0)
		dynasteen.moment_points = score

		if not M.data.settings.match_settings.skip_host_post_playback:
			await HD(config_host.match_singleplayer.round.c_post_listen, HM.SHIFTIN, HM.POPOUT)
		VolumeService.tween_volume_music_and_chatter(VOLUME_QUIET, 1.5)
		if not M.data.settings.match_settings.faster_scoring_from_judges:
			camera_master.JudgeSuspenseSingle(4.6)
			judge_master.drumroll.play()
			judge_master.JudgeWinFrom(score)
			if score == 6: absolute_score.call()
			await judge_master.drumroll.finished
		else:
			camera_master.JudgeSuspenseSingle(1.8)
			drumroll_short.play()
			judge_master.JudgeWinFrom(score, 1.8)
			if score == 6: absolute_score.call()
			await drumroll_short.finished
		VolumeService.tween_volume_music_and_chatter(VOLUME_FULL, 1.0)
		if not M.data.settings.match_settings.skip_host_post_scoring:
			camera_master.HostAndJudges()
			var score_comment: PackedStringArray = []
			if score in range(0, 7): score_comment = config_host.match_singleplayer.judging["score_" + str(score)]


			else: score_comment = ["If you're reading this, something went wrong..."]
			await HD(score_comment, HM.POPIN, HM.POPOUT)
	else:

		await HD(config_host.match_multiplayer.round.c_post_listen, HM.SHIFTIN, HM.POPOUT)
		VolumeService.tween_volume_music_and_chatter(VOLUME_QUIET, 1.5)
		for i in range(statsteen.contestant_count):

			var score = individual_contestant_judge_scoring.call(i)
			dynasteen.moment_points = score
			dynasteen.on_contestant = i

			if i != 0:
				await get_tree().create_timer(0.75).timeout
			camera_master.JudgeSuspenseMulti(1.5, i, statsteen.contestant_count)
			drumroll_short.play()
			judge_master.JudgeWinFrom(score, 1.8)
			if score == 6: absolute_score.call()
			await drumroll_short.finished
			await HD(config_host.match_multiplayer.judging.judged_player)
		VolumeService.tween_volume_music_and_chatter(VOLUME_FULL, 1.0)
		camera_master.HostAndJudges()
		await HD(config_host.match_multiplayer.judging.post_judging, HM.SHIFTIN, HM.POPOUT)

func _RF_ContestantScoreUpdates() -> void :

	var math: = Math.new()
	var contestant_percentages_this_round: Array = []
	var contestant_percentage_change_this_round: Array = []
	var max_percent_change_this_round: float = 0.0
	for c: ContestantResource in conte_slots:
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
	judge_master.JudgePanelsOff()

	await get_tree().create_timer(0.15).timeout
	for i in conte_slots.size():
		individual_contestant_updating.call(i)
	await get_tree().create_timer(max_time_change).timeout
	for c: ContestantResource in conte_slots:
		match c.round_scores[-1]:
			0: c.random_delay_talk("score_0")
			1: c.random_delay_talk("score_1")
			2: c.random_delay_talk("score_2")
			3: c.random_delay_talk("score_3")
			4: c.random_delay_talk("score_4")
			5, 6: c.random_delay_talk("score_5")
