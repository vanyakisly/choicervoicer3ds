extends Node




enum HM{NONE, SHIFTIN, SHIFTOUT, POPIN, POPOUT}
enum SKIPPABLESTATE{NONE, CAMINTRO, HOSTINTRO, }
enum ERB{VCLIP, P1, P1B, P2, P2B, P3, P3B, P4, P4B, FINISH, EVERYONE, LOBBY}


var uc: = UC.new()
var current_vclip: = VclipResource.new()
var tween


@onready var camera_master = %CameraMaster
@onready var contestant_master = %ContestantMaster
@onready var judge_master = %JudgeMaster

@onready var vclip_screen = %VclipScreen
@onready var judge_screen = %JudgeScreen
@onready var contestant_screen = %ContestantScreen
@onready var contestant_view_overlay = %ContestantViewOverlay

@onready var match_progress = %MatchProgress
@onready var host_master = %HostMaster
@onready var dialogue_master = %DialogueMaster
@onready var record_master = %RecordMaster
@onready var match_buttons = %MatchButtons

@onready var music_match = %MusicMatch
@onready var music_polling = %MusicPolling
@onready var drumroll_short = %DrumrollShort
@onready var multiplayer_rapid_pecho = %MultiplayerRapidPecho
@onready var multiuse_stream = %MultiuseStream
@onready var contestant_streams = %ContestantStreams



var skip_triggered: bool = false
var reset_skip: Callable = func() -> bool:
	skip_triggered = false
	return false
var skippable_state: SKIPPABLESTATE = SKIPPABLESTATE.NONE
var conte_slots: Array[ContestantResource] = []
var sp: bool = false

var statsteen: Dictionary = {
	"total_rounds": 1, 
	"vamba": [], 
	"contestant_count": 1
}
var dynasteen: Dictionary = {
	"round": 0, 
	"on_contestant": 0, 
	"moment_points": 0, 
}

var config_host: Dictionary = {}































































































func _input(event):
	if event.is_action_pressed("skip_current_sentence_batch"):
		dialogue_master.Skip()

func _ready():
	VisualSetup()
	OtherSetup()
	if not await Intro(): reset_skip.call()
	await MatchRound()
	add_child(uc)


func OpenLetter(d: Dictionary = {
	"vamba": ["The Birthday Pack/Super Mario Brothers Super Show/smbsshow_football03", "The Birthday Pack/Memes/Vintage Memes/girugamesh"], 
	"players": [
		["test", "Default"], 
		["Oaugh", "Default"]
	]
}):

	statsteen.total_rounds = d.vamba.size()
	statsteen.vamba = d.vamba

	for c in d.players:
		var new_conte: = ContestantResource.new()
		new_conte.set_from_directory(c[0])
		new_conte.audio_input_device = c[1]
		conte_slots.append(new_conte)
	statsteen.contestant_count = d.players.size()
	sp = (d.players.size() == 1)


func VisualSetup():
	host_master.PopOut()
	record_master.visible = false


func OtherSetup():
	config_host = uc.get_json(M.OVEEP.HOST, "config_host")
	music_match.stream = uc.get_audio(M.OVEEP.STUDIO, "music_match", true)
	music_match.play()

	contestant_master.GenerateContestants(conte_slots)
	var vclip_player: = AudioStreamPlayer.new()
	$Audio.add_child(vclip_player)
	current_vclip.stream_player = vclip_player
	for c in match_progress.get_node("Vertical/MultiplayerTrackers").get_children():
		c.free()
	for c_idx in conte_slots.size():
		var c = conte_slots[c_idx]
		$Audio.add_child(c.talk_player)

		var new_progress: MultiplayerProgressTracker = load("res://scene/match/match_progress/multiplayer_progress_tracker.tscn").instantiate()
		new_progress.TrackerAssign(c)
		new_progress.contestant_index = c_idx
		new_progress.show_goal_marker = (statsteen.contestant_count == 1)
		c.progress_tracker = new_progress
		var stream_player: = AudioStreamPlayer.new()
		contestant_streams.add_child(stream_player)
		c.stream_player = stream_player
		match_progress.get_node("Vertical/MultiplayerTrackers").add_child(new_progress)

	match_buttons.ButtonsVisibility(true, true, false)


func Intro() -> bool:
	if skip_triggered: return false

	camera_master.HostAndVclip()
	if statsteen.contestant_count == 1:
		await HD(config_host.match_singleplayer.intro.a_welcome, HM.SHIFTIN, HM.NONE, true)
		if skip_triggered: return false
		host_master.PopOut()
		camera_master.ConIntroCam(0)
		if skip_triggered: return false
		HD(config_host.match_singleplayer.intro.b_contestant)
		if skip_triggered: return false
		multiuse_stream.stream = conte_slots[0].talk_greet
		await dialogue_master.batch_sentence_finished
		if skip_triggered: return false
		multiuse_stream.play()
		await dialogue_master.entire_batch_finished
		if skip_triggered: return false
		multiuse_stream.stop()
		camera_master.JudgeSweep()
		await HD(config_host.match_singleplayer.intro.c_judges, HM.POPIN)
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
			multiuse_stream.stream = conte_slots[i].talk_greet
			await dialogue_master.batch_sentence_finished
			if skip_triggered: return false
			multiuse_stream.play()
			await dialogue_master.entire_batch_finished
		if skip_triggered: return false
		multiuse_stream.stop()
		camera_master.JudgeSweep()
		await HD(config_host.match_multiplayer.intro.c_judges, HM.POPIN)
		if skip_triggered: return false
		camera_master.HostAndVclip()
		await HD(config_host.match_multiplayer.intro.d_explanation, HM.NONE, HM.POPOUT)
		if skip_triggered: return false
	return true


func ContestantIntroSentence(index: int) -> PackedStringArray:
	var conte: ContestantResource = conte_slots[index]
	return [conte.introduction + " " + conte.name + "!"]


func MatchRound():
	while true:
		await MatchRoundFull()



























func MatchRoundFull():
	await _RF_NewRound_PlayVclip()
	await _RF_RecordContestants()
	if not await _RF_ContestantPerformancePlayback():
		reset_skip.call()
		record_master.StopBoth()
	await _RF_ContestantJudging()
	if dynasteen.round + 1 == statsteen.total_rounds:
		await _RF_ContestantScoreFinale()
	else:
		await _RF_ContestantScoreUpdates()

	await _RF_EndRoundButtonOptions()
	await _RF_WrapupRoundNextRound()


func _RF_NewRound_PlayVclip():

	current_vclip.set_from_directory(statsteen.vamba[dynasteen.round], Vector2i(512, 512))

	host_master.PopOut()
	camera_master.VclipMain()
	match_buttons.ButtonsVisibility(true, false, false)
	match_progress.get_node("Vertical/LblRound").text = "[center]Round %s[font_size=24] / %s" % [dynasteen.round + 1, statsteen.total_rounds]

	M.VolumeMusicAudienceStandard(-60, 1.75)
	drumroll_short.play()
	await get_tree().create_timer(1.5).timeout
	vclip_screen.texture = current_vclip.image
	await record_master.NewVclipPlay(current_vclip)
	await get_tree().create_timer(1.0).timeout

func _RF_RecordContestants():

	var individual_contestant_turn = func(i: int):

		var c: = conte_slots[i]
		if tween: tween.kill()
		tween = contestant_view_overlay.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		if not sp: camera_master.VclipMain()
		if not sp: record_master.ClearPlmicData()
		contestant_view_overlay.visible = true
		contestant_view_overlay.position.x = 1153
		camera_master.ConPerformance(i)

		tween.tween_property(contestant_view_overlay, "position:x", 864, 0.6)
		await get_tree().create_timer(0.75).timeout
		c.round_plmic_data = await record_master.PlmicRecord()
		c.stream_player.stream = record_master.wave_control.pecho
		if match_buttons.match_menu.visible: await match_buttons.match_menu_closed
		c.round_waveform_image = ImageTexture.create_from_image(record_master.WaveformImage())

	for i in range(statsteen.contestant_count):
		if sp:
			await individual_contestant_turn.call(0)
		else:

			dynasteen.on_contestant = i

			contestant_view_overlay.visible = false
			camera_master.HostAndVclip()

			M.VolumeMusicAudienceStandard(-3, 1.0)
			await HD(DialogueInjection(config_host.match_multiplayer.round.a_get_ready), HM.POPIN, HM.POPOUT)
			M.VolumeMusicAudienceStandard(-60, 1.0)
			await individual_contestant_turn.call(i)

func _RF_ContestantPerformancePlayback() -> bool:

	if skip_triggered: return false
	M.VolumeMusicAudienceStandard(0, 1.5)

	var individual_contestant_playback = func(i: int) -> bool:

		var c: = conte_slots[i]
		if skip_triggered: return false
		record_master.waveform_mantle.pecho = c.stream_player.stream
		var clip_length: float = c.stream_player.stream.get_length()

		record_master.waveform_mantle.waveform_core.plmic_drawer.receive_plmic_data(c.round_plmic_data)
		record_master.visible = true
		camera_master.ConPerformanceCam(i, clip_length)

		if skip_triggered: return false
		await get_tree().create_timer(0.25).timeout
		if skip_triggered: return false
		record_master.Replay()
		await record_master.replay_finished
		if skip_triggered: return false
		await get_tree().create_timer(1.0).timeout
		if skip_triggered: return false
		return true

	match_buttons.ButtonsVisibility(true, true, false)
	record_master.HideNonMantleItems(true)
	if skip_triggered: return false

	if sp:

		camera_master.HostAndVclip()

		if skip_triggered: return false
		await HD(config_host.match_singleplayer.round.b_post_record, HM.POPIN, HM.POPOUT)
		if skip_triggered: return false
		M.VolumeMusicAudienceStandard(-12, 1.0)
		if not await individual_contestant_playback.call(0): return false
	else:

		camera_master.GoodJob()

		if skip_triggered: return false
		await HD(config_host.match_multiplayer.round.b_post_record, HM.SHIFTIN, HM.SHIFTOUT, false, true)
		if skip_triggered: return false
		M.VolumeMusicAudienceStandard(-12, 1.0)
		for i in range(statsteen.contestant_count):
			if not await individual_contestant_playback.call(i): return false
	return true

func _RF_ContestantJudging():

	var scorer: = Scorer.new()
	M.VolumeMusicAudienceStandard(-3, 1.5)
	var individual_contestant_judge_scoring = func(i: int) -> int:

		var c: = conte_slots[i]
		var wave_img: Texture = c.round_waveform_image
		wave_img.set_size_override(Vector2i(256, 96))

		judge_master.JudgePanelsOff()
		judge_screen.texture = wave_img


		var scoref = scorer.tweaker_freaker(current_vclip.round_data, c.round_plmic_data, 0.85)
		var scorei = clampi(roundi(scoref), 0, 6)

		print("MatchMaster | scoref: %1.4f" % scoref)
		c.round_scores.append(scorei)
		return scorei
	var absolute_score = func():
		print("MatchMaster | entering absolute score")
		multiuse_stream.stream = load("res://audio/sfx/sfx-wham.wav")
		await judge_master.last_vote
		print("MatchMaster | last vote triggered")
		judge_screen.texture = load("res://graphic/image/absolute_score_screen.png")
		multiuse_stream.play()
		var shake_cam_tween = create_tween().set_trans(Tween.TRANS_ELASTIC)
		var cam: Camera3D = camera_master.cam_judge_suspense
		cam.rotation.z = 0.007 * TAU
		shake_cam_tween.tween_property(cam, "rotation:z", 0.0, 0.4)

	match_buttons.ButtonsVisibility(true, false, false)
	record_master.HideNonMantleItems(false)
	judge_screen.texture = load("res://graphic/image/cv_temp_preview_banner.png")
	record_master.visible = false
	camera_master.HostAndJudges()

	if sp:

		var score = individual_contestant_judge_scoring.call(0)
		dynasteen.moment_points = score
		var score_comment: PackedStringArray = []
		if score in range(0, 6):
			score_comment = config_host.match_singleplayer.judging["score_" + str(score)]
		elif score == 6:
			score_comment = ["Wh-what?! Your performance...\nThe judges have declared it\nan EXACT match! Wow!"]
		else:
			score_comment = ["If you're reading this, something went wrong..."]

		await HD(config_host.match_singleplayer.round.c_post_listen, HM.SHIFTIN, HM.POPOUT)
		M.VolumeMusicAudienceStandard(-12, 1.5)
		camera_master.JudgeSuspenseSingle(4.6)
		judge_master.drumroll.play()
		judge_master.JudgeWinFrom(score)
		if score == 6: absolute_score.call()
		await judge_master.drumroll.finished
		M.VolumeMusicAudienceStandard(0, 1.0)
		camera_master.HostAndJudges()
		await HD(score_comment, HM.POPIN, HM.POPOUT)
	else:

		await HD(config_host.match_multiplayer.round.c_post_listen, HM.SHIFTIN, HM.POPOUT)
		M.VolumeMusicAudienceStandard(-12, 1.5)
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
		M.VolumeMusicAudienceStandard(0, 1.0)
		camera_master.HostAndJudges()
		await HD(config_host.match_multiplayer.judging.post_judging, HM.SHIFTIN, HM.POPOUT)

func _RF_ContestantScoreUpdates():

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
	judge_master.JudgePanelsOff()

	await get_tree().create_timer(0.35).timeout
	for i in conte_slots.size():
		individual_contestant_updating.call(i)
	await get_tree().create_timer(max_time_change + 0.5).timeout



	for c in conte_slots:
		match c.round_scores[-1]:
			4, 5, 6:
				c.random_delay_talk("cheer")
			0, 1:
				c.random_delay_talk("upset")


func _RF_WrapupRoundNextRound():
	match_buttons.ButtonsVisibility(true, false, false)
	camera_master.HostAndVclip()
	dynasteen.round += 1
	if sp:
		if dynasteen.round + 1 == statsteen.total_rounds:
			await HD(config_host.match_singleplayer.round.round_final, HM.SHIFTIN)
		else:
			await HD(config_host.match_singleplayer.round.round_next, HM.SHIFTIN)
	else:
		if dynasteen.round + 1 == statsteen.total_rounds:
			await HD(config_host.match_multiplayer.round.round_final, HM.SHIFTIN)
		else:
			await HD(config_host.match_multiplayer.round.round_next, HM.SHIFTIN)


func _RF_ContestantScoreFinale():

	var math: = Math.new()
	var contestant_percentages_this_round: Array = []
	var contestant_percentage_change_this_round: Array = []
	var max_percent_change_this_round: float = 0.0
	for c in conte_slots:
		var c_percent: float = math.array_mean(c.round_scores) / 5.0
		contestant_percentages_this_round.append(c_percent)
		contestant_percentage_change_this_round.append(c_percent - c.previous_percent)
		max_percent_change_this_round = max(max_percent_change_this_round, abs(c.previous_percent - c_percent))

	var host_end_single_or_multi: PackedStringArray = []
	if sp: host_end_single_or_multi = config_host.match_singleplayer.end.final_score
	else: host_end_single_or_multi = config_host.match_multiplayer.end.final_score
	var cam_tween = camera_master.cam_contestants_progress.create_tween().set_trans(Tween.TRANS_SINE)
	var individual_contestant_updating = func(i: int):

		var c: = conte_slots[i]
		var pt: = c.progress_tracker

		pt.AddRoundImage(current_vclip.image, c.round_scores[-1])




		c.progress_tracker.NewPercentAnimate2(contestant_percentages_this_round[i], 4.5)

	camera_master.ContestantsProgress()
	judge_master.JudgePanelsOff()
	await get_tree().create_timer(0.35).timeout

	M.VolumeMusicAudienceStandard(-60, 1.25)
	await HD(host_end_single_or_multi, HM.SHIFTIN, HM.SHIFTOUT, false, true)
	judge_master.drumroll.play()
	camera_master.ContestantsProgressZoomIn()
	await get_tree().create_timer(0.35).timeout
	for i in conte_slots.size():
		individual_contestant_updating.call(i)
	await get_tree().create_timer(5.0).timeout
	M.VolumeMusicAudienceStandard(0, 1.25)
	if sp:
		var host_singleplayer_comment: PackedStringArray = []
		var fp: float = contestant_percentages_this_round[0]
		var endc: Dictionary = config_host.match_singleplayer.end
		if fp <= 0.0:
			host_singleplayer_comment = endc.lose_0
			conte_slots[dynasteen.on_contestant].random_delay_talk("upset")
		elif fp < 0.53:
			host_singleplayer_comment = endc.lose_standard
			conte_slots[dynasteen.on_contestant].random_delay_talk("upset")
		elif fp < 0.6:
			host_singleplayer_comment = endc.lose_barely
			conte_slots[dynasteen.on_contestant].random_delay_talk("upset")
		elif fp < 0.66:
			host_singleplayer_comment = endc.win_barely
			conte_slots[dynasteen.on_contestant].random_delay_talk("cheer")
		elif fp < 1.0:
			host_singleplayer_comment = endc.win_standard
			conte_slots[dynasteen.on_contestant].random_delay_talk("cheer")
		elif fp >= 1.0:
			host_singleplayer_comment = endc.win_100
			conte_slots[dynasteen.on_contestant].random_delay_talk("cheer")
		else:
			host_singleplayer_comment = PackedStringArray(["Error comment. How did you get this?"])
			conte_slots[dynasteen.on_contestant].random_delay_talk("upset")
		camera_master.ContestantsProgress()
		await HD(host_singleplayer_comment, HM.SHIFTIN, HM.SHIFTOUT, false, true)
	else:
		var highest_score: float = 0.0
		for s in contestant_percentages_this_round:
			highest_score = max(highest_score, s)
		var winner_indexes: Array = []
		for i in contestant_percentages_this_round.size():
			if contestant_percentages_this_round[i] >= highest_score:
				winner_indexes.append(i)
		if winner_indexes.size() == 1:
			dynasteen.on_contestant = winner_indexes[0]
			var contecam: Camera3D = contestant_master.contestants.get_child(dynasteen.on_contestant).performance_cam
			contecam.make_current()
			cam_tween.tween_property(camera_master.cam_contestants_progress, "global_position", contecam.global_position, 1.5)
			await HD(config_host.match_multiplayer.end.winner, HM.SHIFTIN, HM.SHIFTOUT, false, true)
		else:
			await HD(config_host.match_multiplayer.end.tie_win, HM.SHIFTIN)

			camera_master.ConPerformanceCam(winner_indexes[0], 2.0)
			dynasteen.on_contestant = winner_indexes[0]
			conte_slots[dynasteen.on_contestant].random_delay_talk("cheer")
			await HD(config_host.match_multiplayer.end.tie_win_start)

			if winner_indexes.size() > 2:
				for i in winner_indexes.slice(1, winner_indexes.size() - 1):
					camera_master.ConPerformanceCam(i, 2.0)
					dynasteen.on_contestant = i
					conte_slots[dynasteen.on_contestant].random_delay_talk("cheer")
					await HD(PackedStringArray(["...<player>..."]))

			camera_master.ConPerformanceCam(winner_indexes[-1], 2.0)
			dynasteen.on_contestant = winner_indexes[-1]
			conte_slots[dynasteen.on_contestant].random_delay_talk("cheer")
			await HD(config_host.match_multiplayer.end.tie_win_end)
		camera_master.ContestantsProgress()
		await HD(config_host.match_multiplayer.end.congrats_goodbye, HM.NONE, HM.SHIFTOUT, false, true)





func RoundStartup():
	match_buttons.ButtonsVisibility(true, false, false)
	host_master.PopOut()
	match_progress.get_node("Vertical/LblRound").text = "[center]Round %s[font_size=24] / %s" % [dynasteen.round + 1, statsteen.total_rounds]
	current_vclip.set_from_directory(statsteen.vamba[dynasteen.round], Vector2i(512, 512))

	await _IRF_DrumrollReveal()

	await _IRF_RecordMasterBegin()

func _IRF_DrumrollReveal():
	camera_master.VclipMain()
	M.VolumeMusicAudienceStandard(-60, 1.75)
	drumroll_short.play()
	record_master.visible = true
	await get_tree().create_timer(1.5).timeout
	vclip_screen.texture = current_vclip.image

func _IRF_RecordMasterBegin():
	await record_master.NewVclipPlay(current_vclip)
	await get_tree().create_timer(1.0).timeout

func _IRF_FinishMatch():
	for pacy in statsteen.vamba:
		if not M.data.player.clips.seen.has(pacy):
			M.data.player.clips.seen.append(pacy)
	M.SaveData()


func _RF_EndRoundButtonOptions():
	var stop_talk = func(): for c in conte_slots: c.talk_player.stop()
	var exit_when_done: bool = false
	if dynasteen.round + 1 == statsteen.total_rounds:
		match_buttons.lbl_next_round_button.text = "Main Menu"
		if statsteen.contestant_count > 1:
			match_buttons.btn_lobby_same_players.visible = true
		exit_when_done = true
	match_buttons.ButtonsVisibility(true, false, true, false, statsteen.contestant_count)
	while true:
		var selection: ERB = await match_buttons.button_index
		if selection == ERB.FINISH:

			M.VolumeMusicAudienceStandard(0, 1.0)
			current_vclip.stream_player.stop()
			for c in conte_slots:
				c.stream_player.stop()
			if exit_when_done:
				_IRF_FinishMatch()
				await get_tree().get_root().get_node("World").CreateMenu()
			break
		elif selection == ERB.LOBBY:

			M.VolumeMusicAudienceStandard(0, 1.0)
			current_vclip.stream_player.stop()
			for c in conte_slots:
				c.stream_player.stop()
			if exit_when_done:
				_IRF_FinishMatch()

				var lobby: Array = []
				for c in conte_slots:
					lobby.append([c.directory, c.audio_input_device])
				await get_tree().get_root().get_node("World").CreateSameLobby(lobby)
			break
		else:
			_IRF_StopAllContestants()
			M.VolumeMusicAudienceStandard(-12, 0.1)
			stop_talk.call()
			if selection == ERB.EVERYONE:
				for c in conte_slots:
					c.play_pecho()
			else:
				match selection:
					ERB.VCLIP:
						current_vclip.stream_player.play()
					ERB.P1:
						conte_slots[0].play_pecho()
					ERB.P1B:
						conte_slots[0].play_pecho()
						current_vclip.stream_player.play()
					ERB.P2:
						conte_slots[1].play_pecho()
					ERB.P2B:
						conte_slots[1].play_pecho()
						current_vclip.stream_player.play()
					ERB.P3:
						conte_slots[2].play_pecho()
					ERB.P3B:
						conte_slots[2].play_pecho()
						current_vclip.stream_player.play()
					ERB.P4:
						conte_slots[3].play_pecho()
					ERB.P4B:
						conte_slots[3].play_pecho()
						current_vclip.stream_player.play()

func _IRF_StopAllContestants():
	current_vclip.stream_player.stop()
	for c in conte_slots:
		c.stop_pecho()





































































































































































































































func HD(sen_batch: PackedStringArray, move_in: HM = HM.NONE, move_out: HM = HM.NONE, wait_in_signal: bool = false, wait_out_signal: bool = false) -> bool:
	if skip_triggered: return false
	match move_in:
		HM.SHIFTIN:
			host_master.ShiftIn()
		HM.POPIN:
			host_master.PopIn()
	if skip_triggered: return false
	if wait_in_signal:
		await host_master.host_in
	if skip_triggered: return false
	dialogue_master.NewBatch(DialogueInjection(sen_batch))
	if skip_triggered: return false
	await dialogue_master.entire_batch_finished
	if skip_triggered: return false
	match move_out:
		HM.SHIFTOUT:
			host_master.ShiftOut()
		HM.POPOUT:
			host_master.PopOut()
	if skip_triggered: return false
	if wait_out_signal:
		await host_master.host_out
	if skip_triggered: return false
	return true


const POINTSPHRASES: PackedStringArray = ["Zero points", "One point", "Two points", "Three points", "Four points", "Five points", "SIX points"]
func DialogueInjection(sen_batch: PackedStringArray) -> PackedStringArray:
	var injected_batch: PackedStringArray = []
	for sentence in sen_batch:
		var sen = sentence
		sen = sen.replace("<host_name>", config_host.name)
		sen = sen.replace("<next_round>", str(dynasteen.round + 2))
		sen = sen.replace("<round>", str(dynasteen.round + 1))
		sen = sen.replace("<player>", conte_slots[dynasteen.on_contestant].name)
		sen = sen.replace("<points>", POINTSPHRASES[dynasteen.moment_points])
		injected_batch.append(sen)
	return injected_batch





func _on_match_buttons_skip():
	skip_triggered = true
	dialogue_master.entire_batch_finished.emit()
	if record_master.visible: record_master.replay_finished.emit()










func _on_music_match_finished():
	music_match.play()

func _on_music_polling_finished():
	music_polling.play()

func _on_match_buttons_save_conte(idx):
	M.ShowActivityHint(true, "Saving...", false)
	var c = conte_slots[idx]
	var date_dict: Dictionary = Time.get_datetime_dict_from_system()

	var timestamp: String = "%0*d%0*d%0*d%0*d%0*d_%s_%s" % [
		4, date_dict.year, 
		2, date_dict.month, 
		2, date_dict.day, 
		2, date_dict.hour, 
		2, date_dict.minute, 
		c.name.left(10), 
		str(hash(Time.get_ticks_usec())).right(6)]
	c.stream_player.stream.save_to_wav("user://game/recordings/" + timestamp)
	M.ShowActivityHint(false)







func _on_match_buttons_preserve_performance():
	var date_dict: Dictionary = Time.get_datetime_dict_from_system()
	var timestamp: String = str(date_dict.year) + str(date_dict.month) + str(date_dict.day) + str(date_dict.hour) + str(date_dict.minute)


	for c in conte_slots:
		var addon: String = timestamp + "_" + str(hash(Time.get_ticks_usec()))
		c.stream_player.stream.save_to_wav("user://game/TESTING/scoring_algo2/preserve_%s" % addon)
		var data: Dictionary = {}
		data["vclip"] = record_master.wave_control.get_vclip_data()
		data["plmic"] = c.round_plmic_data
		data["vclip_path"] = current_vclip.directory
		data["score"] = c.round_scores[-1]

		var file = FileAccess.open("user://game/TESTING/scoring_algo2/preserve_%s" % addon, FileAccess.WRITE)
		if file == null:
			print("M | File saving failed. UNKNOWN ERROR.")
			return
		var data_strung: String = JSON.stringify(data, "\t")
		file.store_string(data_strung)
		file.close()
		print("M | Data successfully saved.")


func _on_match_buttons_match_menu_opened():
	dialogue_master.accepting_user_input = false


func _on_match_buttons_match_menu_closed():
	dialogue_master.accepting_user_input = true
