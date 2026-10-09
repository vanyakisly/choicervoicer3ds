class_name MatchMasterBase extends Node



const POINTSPHRASES: PackedStringArray = ["Zero points", "One point", "Two points", "Three points", "Four points", "Five points", "SIX points"]
const DEFAULT_ABSOLUTE_TEXTURE: Texture2D = preload("res://graphic/image/absolute_score_screen.png")
const DEFAULT_MUSIC: AudioStreamWAV = preload("res://audio/music/studio_music_loop_final.wav")
const VOLUME_FULL: float = 1.0
const VOLUME_REDUCED: float = 0.5
const VOLUME_QUIET: float = 0.25
const VOLUME_MUTED: float = 0.0


enum HM{NONE, SHIFTIN, SHIFTOUT, POPIN, POPOUT}
enum SKIPPABLESTATE{NONE, CAMINTRO, HOSTINTRO, }
enum ERB{VCLIP, P1, P1B, P2, P2B, P3, P3B, P4, P4B, FINISH, EVERYONE, LOBBY}


var uc: = UC.new()
var current_vclip: = VclipResource.new()
var tween
var config_host: Dictionary = {}
var absolute_score_texture: Texture2D


@onready var world_environment: WorldEnvironment = %WorldEnvironment

@onready var camera_master: CameraMaster = %CameraMaster
@onready var contestant_master: Node3D = %ContestantMaster
@onready var judge_master: Node3D = %JudgeMaster

@onready var vclip_screen: Sprite3D = %VclipScreen
@onready var judge_screen: Sprite3D = %JudgeScreen
@onready var contestant_screen: Sprite3D = %ContestantScreen
@onready var contestant_view_overlay: TextureRect = %ContestantViewOverlay

@onready var match_progress: Control = %MatchProgress
@onready var host_master: Control = %HostMaster
@onready var dialogue_master: Control = %DialogueMaster
@onready var record_master: Control = %RecordMaster
@onready var match_buttons: Control = %MatchButtons

@onready var music_match: AudioStreamPlayer = %MusicMatch
@onready var music_polling: AudioStreamPlayer = %MusicPolling
@onready var drumroll_short: AudioStreamPlayer = %DrumrollShort
@onready var multiplayer_rapid_pecho: AudioStreamPlayer = %MultiplayerRapidPecho
@onready var multiuse_stream: AudioStreamPlayer = %MultiuseStream
@onready var conte_talk_audio: AudioStreamPlayer = %ConteTalkAudio
@onready var contestant_streams: Node = %ContestantStreams
@onready var lbl_clip_name: Label = %LblClipName


@export var vox: TwitchAudienceVox


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




func _input(event) -> void :
	if event.is_action_pressed("skip_current_sentence_batch"):
		dialogue_master.Skip()


func add_animation(node) -> String:
	var animation_list = node.get_animation_list()
	if animation_list.size() > 0:
		var world_animation = animation_list[0]
		node.get_animation(world_animation).loop_mode = 1
		node.autoplay = world_animation
		return "Enabled scene animation: %s" % world_animation
	return ""
func force_ao_uv2(material) -> String:
	material.ao_on_uv2 = true
	material.ao_light_affect = 0.75
	return "Ambient occlusion map found for %s - forcing on UV2." % material
func force_emission_uv2(material) -> String:
	material.emission_on_uv2 = true
	return "Emission map found for % - forcing on UV2"
func _check_scene_for_features(gltf_scene_root_node, gltf_state_load) -> void :
	var gltf_scene_children = gltf_scene_root_node.get_children()
	var gltf_materials = gltf_state_load.get_materials()
	for node in gltf_scene_children: if node is AnimationPlayer: print(add_animation(node))
	for mat in gltf_materials:

		if mat.ao_texture: print(force_ao_uv2(mat))

		elif mat.emission_texture: print(force_emission_uv2(mat))


func GENERIC_setup_from_metro() -> void :

	statsteen.total_rounds = Metro.gameplay_omniclip_set.size()
	statsteen.vamba = Metro.gameplay_omniclip_set


	for c: BasicPlayerPackage in Metro.current_players:
		var new_conte: = ContestantResource.new()
		new_conte.set_from_directory(c.pack_reference_name)
		new_conte.audio_input_device = c.input_device_name
		conte_slots.append(new_conte)
	statsteen.contestant_count = Metro.current_players.size()
	sp = (Metro.current_players.size() == 1)
func GENERIC_setup_misc() -> void :
	config_host = uc.get_json(M.OVEEP.HOST, "config_host")
	var config_studio = uc.get_json(M.OVEEP.STUDIO, "config_studio")

	if Profile.debug_disable_fog: (world_environment.environment as Environment).volumetric_fog_enabled = false

	var new_music: AudioStream
	if Profile.studio_slash == "Default/": new_music = DEFAULT_MUSIC
	else:


		var music_named_match: AudioStream = VD.get_audio_agnositc(FileManager.MODPACKS_STUDIO + Profile.studio_slash + "music_match")
		var music_named_studio: AudioStream = VD.get_audio_agnositc(FileManager.MODPACKS_STUDIO + Profile.studio_slash + "music_studio")
		if music_named_studio: new_music = music_named_studio
		else: new_music = music_named_match
		if new_music is AudioStreamWAV:
			if new_music.loop_begin == 0:
				new_music.loop_mode = AudioStreamWAV.LOOP_FORWARD
				new_music.loop_begin = config_studio.audio.music_studio_loop_start
		elif new_music is AudioStreamMP3 or new_music is AudioStreamOggVorbis:
			new_music.loop = true
			if new_music.loop_offset == 0.0: new_music.loop_offset = config_studio.audio.music_studio_loop_start
		if new_music == null:
			new_music = DEFAULT_MUSIC
	music_match.stream = new_music
	music_match.play()

	contestant_master.GenerateContestants(conte_slots)
	var vclip_player: = AudioStreamPlayer.new()
	$Audio.add_child(vclip_player)
	current_vclip.stream_player = vclip_player
	for c in match_progress.get_node("Vertical/MultiplayerTrackers").get_children(): c.free()
	for c_idx in conte_slots.size():
		var c = conte_slots[c_idx]
		$Audio.add_child(c.talk_player)

		var new_progress: MultiplayerProgressTracker = load("res://scene/match/match_progress/multiplayer_progress_tracker.tscn").instantiate()
		new_progress.TrackerAssign(c)
		new_progress.contestant_index = c_idx
		new_progress.show_goal_marker = (statsteen.contestant_count == 1)
		new_progress.attempt_blip.connect(match_progress._attempt_blip)
		new_progress.final_blip.connect(match_progress._final_blip)
		c.progress_tracker = new_progress
		var stream_player: = AudioStreamPlayer.new()
		contestant_streams.add_child(stream_player)
		c.stream_player = stream_player
		match_progress.get_node("Vertical/MultiplayerTrackers").add_child(new_progress)

	match_buttons.ButtonsVisibility(true, true, false)
func GENERIC_scene_model_setup() -> void :
	if M.data.custom.studio != "Default":
		var filepath: String
		var filepath_glb: String = "user://game/packs_studio/" + M.data.custom.studio + "/model.glb"
		var filepath_gltf: String = "user://game/packs_studio/" + M.data.custom.studio + "/model.gltf"
		if FileAccess.file_exists(filepath_glb): filepath = filepath_glb
		elif FileAccess.file_exists(filepath_gltf): filepath = filepath_gltf
		if FileAccess.file_exists(filepath):
			var gltf_document_load: = GLTFDocument.new()
			var gltf_state_load: = GLTFState.new()
			var error: Error = gltf_document_load.append_from_file(filepath, gltf_state_load)
			if error == OK:
				var gltf_scene_root_node: Node = gltf_document_load.generate_scene(gltf_state_load)
				var model_holder: Node3D = $Studio / Model
				for child in model_holder.get_children(): child.free()
				_check_scene_for_features(gltf_scene_root_node, gltf_state_load)
				model_holder.add_child(gltf_scene_root_node)
func setup_absolute_score_screen() -> void :
	if M.session_type != M.SESSION_TYPE.TWITCH:
		match Profile.content_pack_preference_absolute_image:
			1:
				absolute_score_texture = VD.get_texture_agnostic(FileManager.MODPACKS_STUDIO + Profile.studio_slash + "absolute_image")
				if !absolute_score_texture: absolute_score_texture = VD.get_texture_agnostic(FileManager.MODPACKS_JUDGES + Profile.judges_slash + "absolute_image")
			_:
				absolute_score_texture = VD.get_texture_agnostic(FileManager.MODPACKS_JUDGES + Profile.judges_slash + "absolute_image")
				if !absolute_score_texture: absolute_score_texture = VD.get_texture_agnostic(FileManager.MODPACKS_STUDIO + Profile.studio_slash + "absolute_image")

	else: absolute_score_texture = VD.get_texture_agnostic(FileManager.MODPACKS_STUDIO + Profile.studio_slash + "absolute_image")
	if !absolute_score_texture: absolute_score_texture = DEFAULT_ABSOLUTE_TEXTURE
	else:
		var interim: Image = absolute_score_texture.get_image()
		interim.resize(256, 96, Image.INTERPOLATE_LANCZOS)
		absolute_score_texture = ImageTexture.create_from_image(interim)



func ContestantIntroSentence(index: int) -> PackedStringArray:
	var conte: ContestantResource = conte_slots[index]
	return [conte.introduction + " " + conte.name + "!"]





func GENERIC_RF_NewRound_PlayVclip() -> void :

	current_vclip.set_from_omniclip(statsteen.vamba[dynasteen.round], Vector2i(512, 512))

	host_master.PopOut()
	camera_master.VclipMain()
	match_buttons.ButtonsVisibility(true, false, false)
	match_progress.get_node("Vertical/LblRound").text = "[center]Round %s[font_size=24] / %s" % [dynasteen.round + 1, statsteen.total_rounds]

	VolumeService.tween_volume_music_and_chatter(VOLUME_MUTED, 1.75)
	drumroll_short.play()
	await get_tree().create_timer(1.5).timeout
	vclip_screen.texture = current_vclip.get_image_without_transparency()
	await record_master.NewVclipPlay(current_vclip)
	lbl_clip_name.text = record_master.v.directory + " "
	if M.data.settings.match_settings.show_clip_name:
		var tweenA: Tween = create_tween()
		tweenA.tween_property(lbl_clip_name, "modulate:a", 1.0, 0.5)


func GENERIC_RF_RecordContestants() -> void :

	var individual_contestant_turn = func(i: int):

		var c: = conte_slots[i]
		if tween: tween.kill()
		tween = contestant_view_overlay.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

		if sp:
			if AudioServer.input_device != Profile.audio_device_in: AudioServer.input_device = Profile.audio_device_in
		else:
			if AudioServer.input_device != c.audio_input_device: AudioServer.input_device = c.audio_input_device

		if !sp: camera_master.VclipMain();record_master.ClearPlmicData()
		contestant_view_overlay.position.x = 1153;contestant_view_overlay.show()
		camera_master.ConPerformance(i)

		record_master.microphone_on()
		tween.tween_property(contestant_view_overlay, "position:x", 864, 0.6)

		await get_tree().create_timer(0.25).timeout
		c.round_plmic_data = await record_master.PlmicRecord()
		c.stream_player.stream = record_master.wave_control.pecho
		if match_buttons.match_menu.visible: await match_buttons.match_menu_closed
		c.round_waveform_image = ImageTexture.create_from_image(record_master.WaveformImage())

	if sp: await get_tree().create_timer(1.0).timeout
	else: await get_tree().create_timer(1.25).timeout
	for i in range(statsteen.contestant_count):
		if sp:
			await individual_contestant_turn.call(0)
		else:

			dynasteen.on_contestant = i

			contestant_view_overlay.visible = false
			camera_master.HostAndVclip()

			VolumeService.tween_volume_music_and_chatter(VOLUME_REDUCED, 1.0)
			await HD(DialogueInjection(config_host.match_multiplayer.round.a_get_ready), HM.POPIN, HM.POPOUT)
			VolumeService.tween_volume_music_and_chatter(VOLUME_MUTED, 1.0)
			await individual_contestant_turn.call(i)


func GENERIC_Skippable_RF_ContestantPerformancePlayback() -> void :
	if not await GENERIC_RF_ContestantPerformancePlayback():
		reset_skip.call()
		record_master.StopBoth()
func GENERIC_RF_ContestantPerformancePlayback() -> bool:

	if skip_triggered: return false
	VolumeService.tween_volume_music_and_chatter(VOLUME_FULL, 1.5)

	lbl_clip_name.modulate.a = 0.0
	var individual_contestant_playback = func(i: int) -> bool:

		var c: = conte_slots[i]
		if skip_triggered: return false
		record_master.waveform_mantle.pecho = c.stream_player.stream
		var clip_length: float = c.stream_player.stream.get_length()

		record_master.waveform_mantle.waveform_core.plmic_drawer.receive_plmic_data(c.round_plmic_data)
		record_master.show()
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

	record_master.hide_and_reset_caption()
	if sp:


		if not M.data.settings.match_settings.skip_host_post_record:
			camera_master.HostAndVclip()
			if skip_triggered: return false
			await HD(config_host.match_singleplayer.round.b_post_record, HM.POPIN, HM.POPOUT)
		else: contestant_view_overlay.visible = false
		if skip_triggered: return false
		if Profile.fully_mute_music: VolumeService.tween_volume_music(VOLUME_MUTED, 1.0)
		else: VolumeService.tween_volume_music(VOLUME_QUIET, 1.0)
		VolumeService.tween_volume_chatter(VOLUME_MUTED, 0.5)

		if not await individual_contestant_playback.call(0): return false
	else:


		if not M.data.settings.match_settings.skip_host_post_record:
			camera_master.GoodJob()
			if skip_triggered: return false
			await HD(config_host.match_multiplayer.round.b_post_record, HM.SHIFTIN, HM.SHIFTOUT, false, true)
		else: contestant_view_overlay.visible = false
		if skip_triggered: return false
		if Profile.fully_mute_music: VolumeService.tween_volume_music(VOLUME_MUTED, 1.0)
		else: VolumeService.tween_volume_music(VOLUME_QUIET, 1.0)
		VolumeService.tween_volume_chatter(VOLUME_MUTED, 0.5)
		for i in range(statsteen.contestant_count):
			if not await individual_contestant_playback.call(i): return false
	return true


func GENERIC_RF_WrapupRoundNextRound() -> void :
	match_buttons.ButtonsVisibility(true, false, false);camera_master.HostAndVclip()
	dynasteen.round += 1
	var is_final_round: bool = (dynasteen.round + 1) == statsteen.total_rounds
	if sp:

		if is_final_round: await HD(config_host.match_singleplayer.round.round_final, HM.SHIFTIN)
		else: await HD(config_host.match_singleplayer.round.round_next, HM.SHIFTIN)
	else:
		if is_final_round: await HD(config_host.match_multiplayer.round.round_final, HM.SHIFTIN)
		else: await HD(config_host.match_multiplayer.round.round_next, HM.SHIFTIN)


func GENERIC_RF_ContestantScoreFinale() -> void :

	var math: = Math.new()
	var contestant_percentages_this_round: Array = []
	var contestant_percentage_change_this_round: Array = []
	var max_percent_change_this_round: float = 0.0
	for c: ContestantResource in conte_slots:
		var c_percent: float = math.array_mean(c.round_scores) / 5.0
		contestant_percentages_this_round.append(c_percent)
		contestant_percentage_change_this_round.append(c_percent - c.previous_percent)
		max_percent_change_this_round = max(max_percent_change_this_round, abs(c.previous_percent - c_percent))

	var host_end_single_or_multi: PackedStringArray = []
	if sp: host_end_single_or_multi = config_host.match_singleplayer.end.final_score
	else: host_end_single_or_multi = config_host.match_multiplayer.end.final_score
	var individual_contestant_updating = func(i: int):

		var c: = conte_slots[i]
		var pt: = c.progress_tracker

		pt.AddRoundImage(current_vclip.image, c.round_scores[-1])




		c.progress_tracker.NewPercentAnimate2(contestant_percentages_this_round[i], 4.5)

	camera_master.ContestantsProgress()
	await get_tree().create_timer(0.35).timeout

	VolumeService.tween_volume_chatter(VOLUME_REDUCED, 1.25)
	VolumeService.tween_volume_music(VOLUME_MUTED, 1.25)
	await HD(host_end_single_or_multi, HM.SHIFTIN, HM.SHIFTOUT, false, true)
	judge_master.drumroll.play()
	camera_master.ContestantsProgressZoomIn()
	await get_tree().create_timer(0.15).timeout
	for i in conte_slots.size(): individual_contestant_updating.call(i)
	await get_tree().create_timer(5.0).timeout
	VolumeService.tween_volume_music_and_chatter(VOLUME_FULL, 1.25)
	if sp:
		var host_singleplayer_comment: PackedStringArray = []
		var fp: float = contestant_percentages_this_round[0]
		var endc: Dictionary = config_host.match_singleplayer.end
		if fp <= 0.0: host_singleplayer_comment = endc.lose_0;conte_slots[dynasteen.on_contestant].random_delay_talk("game_loser")
		elif fp < 0.53: host_singleplayer_comment = endc.lose_standard;conte_slots[dynasteen.on_contestant].random_delay_talk("game_loser")
		elif fp < 0.6: host_singleplayer_comment = endc.lose_barely;conte_slots[dynasteen.on_contestant].random_delay_talk("game_loser")
		elif fp < 0.66: host_singleplayer_comment = endc.win_barely;conte_slots[dynasteen.on_contestant].random_delay_talk("game_winner")
		elif fp < 1.0: host_singleplayer_comment = endc.win_standard;conte_slots[dynasteen.on_contestant].random_delay_talk("game_winner")
		elif fp >= 1.0: host_singleplayer_comment = endc.win_100;conte_slots[dynasteen.on_contestant].random_delay_talk("game_winner")
		else: host_singleplayer_comment = PackedStringArray(["Error comment. How did you get this?"]);conte_slots[dynasteen.on_contestant].random_delay_talk("game_loser")
		camera_master.ContestantsProgress()
		await HD(host_singleplayer_comment, HM.SHIFTIN, HM.SHIFTOUT, false, true)
	else:
		var highest_score: float = 0.0
		for s in contestant_percentages_this_round: highest_score = max(highest_score, s)
		var winner_indexes: Array = []
		for i in contestant_percentages_this_round.size(): if contestant_percentages_this_round[i] >= highest_score: winner_indexes.append(i)
		if winner_indexes.size() == 1:
			dynasteen.on_contestant = winner_indexes[0]
			var contecam: Camera3D = contestant_master.contestants.get_child(dynasteen.on_contestant).performance_cam
			contecam.make_current()
			conte_slots[dynasteen.on_contestant].random_delay_talk("game_winner")
			await HD(config_host.match_multiplayer.end.winner, HM.SHIFTIN, HM.NONE, false, false)
		else:
			await HD(config_host.match_multiplayer.end.tie_win, HM.SHIFTIN)

			camera_master.ConPerformanceCam(winner_indexes[0], 2.0)
			dynasteen.on_contestant = winner_indexes[0]
			conte_slots[dynasteen.on_contestant].random_delay_talk("game_winner")
			await HD(config_host.match_multiplayer.end.tie_win_start)

			if winner_indexes.size() > 2:
				for i in winner_indexes.slice(1, winner_indexes.size() - 1):
					camera_master.ConPerformanceCam(i, 2.0)
					dynasteen.on_contestant = i
					conte_slots[dynasteen.on_contestant].random_delay_talk("game_winner")
					await HD(PackedStringArray(["...<player>..."]))

			camera_master.ConPerformanceCam(winner_indexes[-1], 2.0)
			dynasteen.on_contestant = winner_indexes[-1]
			conte_slots[dynasteen.on_contestant].random_delay_talk("game_winner")
			await HD(config_host.match_multiplayer.end.tie_win_end)
		camera_master.ContestantsProgress()
		await HD(config_host.match_multiplayer.end.congrats_goodbye, HM.NONE, HM.SHIFTOUT, false, true)





func GENERIC_round_startup() -> void :
	match_buttons.ButtonsVisibility(true, false, false)
	host_master.PopOut()
	match_progress.get_node("Vertical/LblRound").text = "[center]Round %s[font_size=24] / %s" % [dynasteen.round + 1, statsteen.total_rounds]
	current_vclip.set_from_omniclip(statsteen.vamba[dynasteen.round], Vector2i(512, 512))

	await GENERIC_IRF_DrumrollReveal()

	await GENERIC_IRF_RecordMasterBegin()

func GENERIC_IRF_DrumrollReveal() -> void :
	camera_master.VclipMain()
	VolumeService.tween_volume_music_and_chatter(VOLUME_MUTED, 1.75)
	drumroll_short.play()
	record_master.visible = true
	await get_tree().create_timer(1.5).timeout
	vclip_screen.texture = current_vclip.image

func GENERIC_IRF_RecordMasterBegin() -> void :
	await record_master.NewVclipPlay(current_vclip)
	await get_tree().create_timer(1.0).timeout

func GENERIC_IRF_FinishMatch() -> void :



	M.SaveData()


func GENERIC_RF_EndRoundButtonOptions() -> void :
	var stop_talk = func(): for c: ContestantResource in conte_slots: c.talk_player.stop()
	var exit_when_done: bool = false
	var current_omniclip: OmniClip = statsteen.vamba[dynasteen.round]
	current_omniclip.attempt_to_mark_as_seen()
	M.SaveData()
	if Profile.automatically_save_clips: _autosave_all_performances()
	if dynasteen.round + 1 == statsteen.total_rounds:
		match_buttons.lbl_next_round_button.text = "Main Menu"
		match_buttons.btn_lobby_same_players.show()
		exit_when_done = true
	match_buttons.ButtonsVisibility(true, false, true, false, statsteen.contestant_count)
	while true:
		stop_talk.call()
		var selection: ERB = await match_buttons.button_index
		if selection == ERB.FINISH:

			current_vclip.stream_player.stop()
			GENERIC_IRF_StopAllContestants()
			if exit_when_done:
				GENERIC_IRF_FinishMatch()
				M.data.settings.volume = match_buttons.theseus_volume
				await M.world.CreateMenu()
				await get_tree().create_timer(10.0).timeout
			VolumeService.tween_volume_music_and_chatter(VOLUME_FULL, 1.0)
			break
		elif selection == ERB.LOBBY:

			current_vclip.stream_player.stop()
			GENERIC_IRF_StopAllContestants()
			if exit_when_done:
				GENERIC_IRF_FinishMatch()

				var lobby: Array = []
				for c: ContestantResource in conte_slots: lobby.append(BasicPlayerPackage.new(c.directory, c.audio_input_device))
				await M.world.CreateSameLobby(lobby)
				await get_tree().create_timer(10.0).timeout
			VolumeService.tween_volume_music_and_chatter(VOLUME_FULL, 1.0)
			break
		else:
			GENERIC_IRF_StopAllContestants()
			VolumeService.tween_volume_music_and_chatter(VOLUME_QUIET, 0.1)
			if selection == ERB.EVERYONE: for c: ContestantResource in conte_slots: c.play_pecho()
			else:
				match selection:
					ERB.VCLIP: current_vclip.stream_player.play()
					ERB.P1: conte_slots[0].play_pecho()
					ERB.P1B: conte_slots[0].play_pecho();current_vclip.stream_player.play()
					ERB.P2: conte_slots[1].play_pecho()
					ERB.P2B: conte_slots[1].play_pecho();current_vclip.stream_player.play()
					ERB.P3: conte_slots[2].play_pecho()
					ERB.P3B: conte_slots[2].play_pecho();current_vclip.stream_player.play()
					ERB.P4: conte_slots[3].play_pecho()
					ERB.P4B: conte_slots[3].play_pecho();current_vclip.stream_player.play()
		await get_tree().process_frame

func GENERIC_IRF_StopAllContestants() -> void :
	current_vclip.stream_player.stop()
	for c: ContestantResource in conte_slots:
		c.allow_talk = false
		if c.stream_player.playing: c.stop_pecho()
		if c.talk_player.playing: c.talk_player.stop()


func HD(sen_batch: PackedStringArray, move_in: HM = HM.NONE, move_out: HM = HM.NONE, wait_in_signal: bool = false, wait_out_signal: bool = false) -> bool:
	if skip_triggered: return false
	match move_in:
		HM.SHIFTIN: host_master.ShiftIn()
		HM.POPIN: host_master.PopIn()
	if skip_triggered: return false
	if wait_in_signal: await host_master.host_in
	if skip_triggered: return false
	dialogue_master.NewBatch(DialogueInjection(sen_batch))
	if skip_triggered: return false
	await dialogue_master.entire_batch_finished
	if skip_triggered: return false
	match move_out:
		HM.SHIFTOUT: host_master.ShiftOut()
		HM.POPOUT: host_master.PopOut()
	if skip_triggered: return false
	if wait_out_signal: await host_master.host_out
	if skip_triggered: return false
	return true


func DialogueInjection(sen_batch: PackedStringArray) -> PackedStringArray:
	var injected_batch: PackedStringArray = []
	for sentence: String in sen_batch:
		var sen: String = sentence
		sen = sen.replace("<host_name>", config_host.name)
		sen = sen.replace("<next_round>", str(dynasteen.round + 2))
		sen = sen.replace("<round>", str(dynasteen.round + 1))
		sen = sen.replace("<player>", conte_slots[dynasteen.on_contestant].name)
		sen = sen.replace("<points>", POINTSPHRASES[dynasteen.moment_points])
		sen = sen.replace("<character_introduction>", conte_slots[dynasteen.on_contestant].introduction)
		injected_batch.append(sen)
	return injected_batch



func _on_match_buttons_skip():
	skip_triggered = true
	if conte_talk_audio.playing: conte_talk_audio.stop()
	dialogue_master.Skip()
	if record_master.visible: record_master.replay_finished.emit()

func _on_music_match_finished(): music_match.play()

func _on_music_polling_finished(): music_polling.play()

func _on_match_buttons_save_conte(idx: int, manually_called: bool = true) -> void :
	if manually_called: M.ShowActivityHint(true, "Saving...", false)
	var c: ContestantResource = conte_slots[idx]
	var date_dict: Dictionary = Time.get_datetime_dict_from_system()

	var timestamp: String = "%0*d%0*d%0*d%0*d%0*d_%s__%s_%s" % [
		4, date_dict.year, 
		2, date_dict.month, 
		2, date_dict.day, 
		2, date_dict.hour, 
		2, date_dict.minute, 
		current_vclip.file_name_agnostic, 
		idx, 
		str(hash(Time.get_ticks_usec())).right(4)]
	c.stream_player.stream.save_to_wav("user://game/recordings/" + timestamp)
	M.ShowActivityHint(false)


func _autosave_all_performances() -> void :
	for contes_idx: int in conte_slots.size(): _on_match_buttons_save_conte(contes_idx, false)
	M.ShowActivityHint(true, "Saving...", false)
	await get_tree().create_timer(1.25).timeout
	M.ShowActivityHint(false)



func _on_match_buttons_match_menu_opened(): dialogue_master.accepting_user_input = false
func _on_match_buttons_match_menu_closed(): dialogue_master.accepting_user_input = true
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
		if file == null: print("M | File saving failed. UNKNOWN ERROR.");return
		var data_strung: String = JSON.stringify(data, "\t")
		file.store_string(data_strung)
		file.close()
		print("M | Data successfully saved.")
