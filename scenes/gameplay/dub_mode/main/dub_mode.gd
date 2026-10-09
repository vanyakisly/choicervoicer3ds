extends Control



const DUB_RECORD_PREFIX: String = "_dubrecord_"


@onready var btn_hear_again: ButtonCV = %BtnHearAgain
@onready var btn_stop_listening: ButtonCV = %BtnStopListening
@onready var btn_record: ButtonCV = %BtnRecord
@onready var btn_stop_record: ButtonCV = %BtnStopRecord
@onready var btn_next: ButtonCV = %BtnNext
@onready var btn_watch: ButtonCV = %BtnWatch
@onready var btn_begin: ButtonCV = %BtnBegin
@onready var btn_save_dub: ButtonCV = %BtnSaveDub
@onready var btn_refresh_mic: ButtonCV = %BtnRefreshMic
@onready var btn_expand_contract: ButtonCV = %BtnExpandContract
@onready var btn_goto_cinema: ButtonCV = %BtnGotoCinema


@onready var audio_interface_manager: AudioInterfaceManagerBufferless = %AudioInterfaceManagerBufferless
@onready var replay_streams: Node = %ReplayStreams
@onready var video_stream_player: VideoStreamPlayer = %VideoStreamPlayer
@onready var video_stream_player_expanded: VideoStreamPlayer = %VideoStreamPlayerExpanded
@onready var player_backing_track: AudioStreamPlayer = %PlayerBackingTrack
@onready var waveform_container: ColorRect = %WaveformContainer
@onready var waveform_border: ColorRect = %WaveformBorder
@onready var remote_buttons: VBoxContainer = %RemoteButtons
@onready var lbl_caption: Label = %LblCaption
@onready var lbl_on_clip_number: Label = %LblOnClipNumber
@onready var results: VBoxContainer = %Results
@onready var results_list: VBoxContainer = %ResultsList
@onready var spin_wheel: TextureRect = %SpinWheel
@onready var animation_spin_wheel_player: AnimationPlayer = %AnimationSpinWheelPlayer
@onready var lbl_result_big: Label = %LblResultBig
@onready var results_timer: Timer = %ResultsTimer
@onready var microphone_in: AudioStreamPlayer
@onready var exit: ColorRect = %Exit
@onready var settings: Control = %Settings
@onready var load_last_session_prompt: ColorRect = %LoadLastSessionPrompt
@onready var lbl_load_last_session: Label = %LblLoadLastSession
@onready var speaker_info: HBoxContainer = %SpeakerInfo
@onready var lbl_speaker: Label = %LblSpeaker


@export var waveform_viewport: WaveformViewport


@export_group("Node Group - Method Calls")
@export var video_player_static: VideoStreamPlayer
@export var video_player_main_dynamic: VideoStreamPlayer
@export var video_static_buffer_timer: Timer


@export_group("Node Group - Visibility Changes")
@export var television_solid_color_background: ColorRect
@export var vclip_displayer: TextureRect


var clip_index: int = 0
var dub_save_folder: String = ""
var previous_buttons_state: Array[bool]
var turn_record_attempts: int = 0
var performing_finished: bool = false
var ask_for_exit_confirmation: bool = true
var viewer_is_expanded: bool = false


var resource: GameplayResourceDubMode


var performance_array: Array[OmniClipMemberInstance]
var unperformance_array: Array[OmniClipMemberInstance]




func _buttons_toggle(enable_record: bool, enable_next: bool, enable_watch: bool, enable_hear_again: bool, enable_save_dub: bool, enable_refresh_mic: bool) -> void :
	btn_record.enable(enable_record)
	btn_next.enable(enable_next)
	btn_watch.enable(enable_watch)
	btn_hear_again.enable(enable_hear_again)
	btn_save_dub.enable(enable_save_dub)
	btn_refresh_mic.enable(enable_refresh_mic)
func _current_button_states() -> Array[bool]: return [
	btn_record.enabled, btn_next.enabled, btn_watch.enabled, 
	btn_hear_again.enabled, btn_save_dub.enabled, btn_refresh_mic.enabled]
func _buttons_toggle_array(arr: Array[bool]) -> void :
	btn_record.enable(arr[0])
	btn_next.enable(arr[1])
	btn_watch.enable(arr[2])
	btn_hear_again.enable(arr[3])
	btn_save_dub.enable(arr[4])
	btn_refresh_mic.enable(arr[5])
func _buttons_disable_all() -> void : _buttons_toggle(false, false, false, false, false, false)
func _buttons_enable_all() -> void : _buttons_toggle(true, true, true, true, true, true)


func _update_from_difficulty_toggles() -> void :

	AudioServer.set_bus_mute(VolumeService.BUS_VCLIP, Profile.dub_mode_hard_mute_clips and !performing_finished)
	AudioServer.set_bus_mute(VolumeService.BUS_PLAYBACK, Profile.dub_mode_hard_mute_clips)
	lbl_caption.visible = ( !Profile.dub_mode_hard_no_captions and !performing_finished)
	if !performing_finished: btn_record.enable( !Profile.dub_mode_hard_one_take or !bool(turn_record_attempts))
	player_backing_track.volume_linear = float( !Profile.dub_mode_mute_backing_track) * float(performing_finished)


func reset_microphone() -> void :
	audio_interface_manager.idle()
	var preserved_button_states: Array[bool] = _current_button_states()
	_buttons_disable_all()
	MicrophoneService.disable()
	await get_tree().create_timer(0.75).timeout
	MicrophoneService.warmup()
	await MicrophoneService.mic_ready
	_buttons_toggle_array(preserved_button_states)


func _begin_from_idle() -> void :
	btn_begin.hide()
	remote_buttons.show()
	waveform_container.modulate.a = 1.0
	video_player_static.stop();video_player_static.hide()
	previous_buttons_state = _current_button_states();_buttons_disable_all()
	if performance_array[0].is_preserved_instance: _button_next(true)
	else: await prep_and_engage_omniclip(clip_index, true)
func _prep_omniclip(index: int = clip_index) -> void :
	var active_clip: OmniClip = performance_array[index].shared_omniclip
	turn_record_attempts = 0
	lbl_on_clip_number.text = "On clip %s of %s" % [clip_index + 1, performance_array.size()]
	speaker_info.visible = !active_clip.dub_characters.is_empty()
	var speaker_text: String = ", ".join(active_clip.dub_characters)
	lbl_speaker.custom_minimum_size.x = mini(132, FontFile.new().get_string_size(speaker_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14).x + 7)
	lbl_speaker.text = speaker_text
	lbl_caption.modulate.a = 0.0;lbl_caption.text = ""
	audio_interface_manager.load_omniclip(active_clip)
	vclip_displayer.texture = active_clip.clip_texture
func _engage_omniclip(index: int = clip_index) -> void :
	var active_clip: OmniClip = performance_array[index].shared_omniclip

	audio_interface_manager.first()
	await audio_interface_manager.idled

	lbl_caption.modulate.a = 0.0;lbl_caption.text = active_clip.clip_caption; var tween: Tween = create_tween();tween.tween_property(lbl_caption, "modulate:a", 1.0, 0.5)
	_buttons_toggle_array(previous_buttons_state)
	_update_from_difficulty_toggles()
func prep_and_engage_omniclip(index: int = clip_index, skip_static: bool = false) -> bool:
	if performance_array[index].is_preserved_instance: return false
	_prep_omniclip(index)
	if !skip_static:
		await get_tree().create_timer(0.45).timeout
		waveform_container.modulate.a = 1.0
		video_player_static.hide()
		video_player_static.stop()
	_engage_omniclip(index)
	return true
func _hear_again() -> void :
	if !audio_interface_manager.idled.is_connected(_end_again): audio_interface_manager.idled.connect(_end_again)
	previous_buttons_state = _current_button_states();_buttons_disable_all()
	audio_interface_manager.again()
	btn_stop_listening.show();btn_hear_again.hide()
func _end_again() -> void :
	_update_from_difficulty_toggles()
	if audio_interface_manager.idled.is_connected(_end_again): audio_interface_manager.idled.disconnect(_end_again)
	audio_interface_manager.idle()
	_buttons_toggle_array(previous_buttons_state)
	btn_stop_listening.hide();btn_hear_again.show()
	audio_interface_manager.reset_playbar()
func _enact() -> void :
	if !audio_interface_manager.idled.is_connected(_end_enact): audio_interface_manager.idled.connect(_end_enact)
	previous_buttons_state = _current_button_states();_buttons_disable_all()
	await get_tree().create_timer(0.16).timeout
	audio_interface_manager.reset_plmic_sampling()
	audio_interface_manager.enact()
	btn_stop_record.show();btn_record.hide()
func _end_enact() -> void :
	turn_record_attempts += 1
	if audio_interface_manager.idled.is_connected(_end_enact): audio_interface_manager.idled.disconnect(_end_enact)
	audio_interface_manager.idle()
	audio_interface_manager.reset_playbar()
	_buttons_toggle_array(previous_buttons_state)
	btn_stop_record.hide();btn_record.show()
	audio_interface_manager.reset_playbar()
	btn_next.enable(true)
	_update_from_difficulty_toggles()
func _button_next(first_instance_skipped: bool = false) -> void :
	btn_next.enable(false)
	previous_buttons_state = _current_button_states();_buttons_disable_all()
	var this_member_instance: OmniClipMemberInstance = performance_array[clip_index]
	if !this_member_instance.is_preserved_instance:
		var recording: AudioStreamWAV
		if !first_instance_skipped: recording = MicrophoneService.get_recording()
		if Profile.mic_crust_sample_rate_on: recording = GMCrust.reduce_recording_sample_rate(recording)
		this_member_instance.member_audio = recording
		audio_interface_manager.playbar.hide()
		await get_tree().physics_frame
		await get_tree().process_frame
		this_member_instance.member_waveform_texture = waveform_viewport.get_snapshot()
		audio_interface_manager.playbar.show()
		this_member_instance.write_vclip_data_from_aggregate(audio_interface_manager.spectrum_aggregate_vclip)
		this_member_instance.write_plmic_data_from_aggregate(audio_interface_manager.spectrum_aggregate_plmic)
		this_member_instance.shared_omniclip.attempt_to_mark_as_seen()
		this_member_instance.preserve_data(this_member_instance.shared_omniclip.file_name_agnostic, resource.get_temp_preserve_path())
	clip_index += 1
	while clip_index < performance_array.size() and performance_array[clip_index].is_preserved_instance:
		clip_index += 1
	if clip_index >= performance_array.size():
		_enter_finish()
		return


	waveform_container.modulate.a = 0.0
	video_player_static.show();video_player_static.play();lbl_caption.text = ""
	await prep_and_engage_omniclip()
func _enter_finish() -> void :
	performing_finished = true
	MicrophoneService.disable()
	speaker_info.hide()
	lbl_on_clip_number.text = "Finished!"
	btn_hear_again.enable(false);btn_record.enable(false);btn_refresh_mic.enable(false)
	btn_watch.enable(true);btn_save_dub.enable(true)
	dub_finished()


func _connect_signals() -> void :
	waveform_border.resized.connect(_fit_waveform_border_ratio_to_self)
	Profile.changed_dub_mode_options.connect(_update_from_difficulty_toggles)
func _fit_waveform_border_ratio_to_self() -> void :
	waveform_border.material.set_shader_parameter("node_size", waveform_border.size)
func _setup_performance_array() -> void :
	var debug_output: PackedStringArray = []
	for clip: OmniClip in resource.omni_clip_array.data:
		var clip_member_instance: = OmniClipMemberInstance.new()
		clip_member_instance.shared_omniclip = clip
		if clip.dub_use_as_is:
			clip_member_instance.member_audio = clip.clip_audio
			unperformance_array.append(clip_member_instance)
		else:
			performance_array.append(clip_member_instance)
			debug_output.append(clip_member_instance.shared_omniclip.file_name_agnostic)
	print(debug_output)
func _enable_buttons() -> void :
	btn_hear_again.enable(true)
	btn_record.enable(true)
	btn_refresh_mic.enable(true)
	btn_next.enable(false)
	btn_watch.enable(false)
	btn_save_dub.enable(false)


func _exit_tree() -> void :
	MicrophoneService.disable()
func _ready() -> void :
	resource = Metro.gameplay_resource_dub_mode
	_connect_signals()
	_setup_performance_array()
	_enable_buttons()
	_update_from_difficulty_toggles()
	btn_begin.show();vclip_displayer.show();hide_settings()

	waveform_container.modulate.a = 0.0
	%TelevisionExpanded.hide();btn_expand_contract.hide();btn_goto_cinema.hide()
	video_stream_player.hide();remote_buttons.hide();exit.hide();results.hide();load_last_session_prompt.hide()
	btn_stop_listening.hide();btn_stop_record.hide()
	television_solid_color_background.color = Color.BLACK
	lbl_on_clip_number.text = ""
	video_player_static.show()
	video_player_static.play()
	MicrophoneService.warmup()
	_check_incomplete_session()



func dub_finished() -> void :
	lbl_caption.hide()
	vclip_displayer.hide();waveform_container.hide();btn_save_dub.show();btn_watch.show()
	television_solid_color_background.color = Color("0037ff")
	results_list.hide()
	animation_spin_wheel_player.play("SpinWheel")
	spin_wheel.show()
	results.show()
	results_timer.start(1.0)
	var thread: = Thread.new()
	thread.start(generate_results)
	while thread.is_alive(): await get_tree().process_frame
	enter_results(thread.wait_to_finish())
	if results_timer.time_left: await results_timer.timeout
	animation_spin_wheel_player.stop()
	spin_wheel.hide()
	results_list.show()
	btn_expand_contract.show()
	btn_goto_cinema.show()
	_update_from_difficulty_toggles()


func generate_results() -> float:
	var scores: PackedFloat32Array = []
	for clip: OmniClipMemberInstance in performance_array:
		clip.generate_score()
		var this_clips_score: float = clampf(clip.score, 0.0, 5.0)
		scores.append(this_clips_score)




	var score: float = MathService.array_average_mean(scores) / 5.0
	if floori(score) == 67: score += [-1.0, 1.0].pick_random()
	return score


func enter_results(overall_score: float) -> void :
	const LIMIT_PER_FRAME: int = 4
	var counter: int = 0
	for clip: OmniClipMemberInstance in performance_array:
		var this_clips_score: float = clampf(clip.score, 0.0, 5.0)
		var row: = HBoxContainer.new()
		var image: = TextureRect.new()
		image.custom_minimum_size = Vector2(64, 64)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.texture = clip.shared_omniclip.clip_texture
		var waveform: = TextureRect.new()
		waveform.custom_minimum_size = Vector2(192, 64)
		waveform.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		waveform.texture = clip.member_waveform_texture
		var label: = Label.new()
		label.text = "Score: %1.0f%%" % (this_clips_score * 20.0)
		row.add_child(image)
		row.add_child(label)
		row.add_child(waveform)
		row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		row.add_theme_constant_override("separation", 10)
		results_list.add_child(row)
		counter += 1
		if counter % LIMIT_PER_FRAME == 0: await get_tree().process_frame
	lbl_result_big.text = "%1.2f%%\n" % [overall_score * 100.0]
	if overall_score <= 0.1: lbl_result_big.text += "Pathetic!"
	elif overall_score <= 0.2: lbl_result_big.text += "Unprofessional!"
	elif overall_score <= 0.4: lbl_result_big.text += "You'll get there some day!"
	elif overall_score <= 0.6: lbl_result_big.text += "Don't quit your day job!"
	elif overall_score <= 0.8: lbl_result_big.text += "Talented!"
	elif overall_score < 1.0: lbl_result_big.text += "The next big thing!"
	else: lbl_result_big.text += "Perfection!"



func watch() -> void :
	clear_playing_clips()
	var performance_fusion: Array[OmniClipMemberInstance] = []
	performance_fusion.append_array(performance_array)
	performance_fusion.append_array(unperformance_array)
	for clip: OmniClipMemberInstance in performance_fusion:
		for timestamp: float in clip.shared_omniclip.dub_timestamps:
			var player: = AudioStreamPlayer.new()
			player.bus = "Pecho"
			player.stream = clip.member_audio
			var timer: = Timer.new()
			timer.one_shot = true
			timer.wait_time = maxf(0.01, timestamp)
			timer.timeout.connect(player.play)
			timer.add_child(player)
			replay_streams.add_child(timer)
	video_stream_player.bus = "Mute"
	player_backing_track.stream = resource.backing_track
	video_stream_player.stream = resource.video
	video_stream_player.show();results.hide()
	video_stream_player.play()
	video_stream_player_expanded.stream = resource.video
	video_stream_player_expanded.play()
	if player_backing_track.stream: player_backing_track.play()
	for timer: Timer in replay_streams.get_children(): timer.start()

func clear_playing_clips() -> void : for timer: Timer in replay_streams.get_children(): timer.queue_free()
func stop() -> void :
	clear_playing_clips()
	results.show()
	if video_stream_player.is_playing(): video_stream_player.stop()
	if player_backing_track.playing: player_backing_track.stop()


func _save_dub() -> void :
	btn_save_dub.enable(false)
	btn_save_dub.get_child(0).text = "Saving..."
	dub_save_folder = Time.get_datetime_string_from_system().validate_filename().replace("T", " ")
	var target_folder: String = "dub_recordings/" + resource.pack_info.path_from_pack + dub_save_folder + "/"
	DirAccess.make_dir_recursive_absolute(FileManager.RECORDINGS + target_folder)
	for clip: OmniClipMemberInstance in performance_array: clip.save_recording(target_folder + DUB_RECORD_PREFIX + clip.shared_omniclip.file_name_agnostic + ".wav")
	btn_save_dub.get_child(0).text = "Saved!"
	ask_for_exit_confirmation = false


func _expand_screen() -> void : %TelevisionExpanded.show()
func _contract_screen() -> void : %TelevisionExpanded.hide()
func _toggle_screen_size() -> void :
	if viewer_is_expanded:
		viewer_is_expanded = false
		btn_expand_contract.set_first_label_text("Expand View")
		_contract_screen()
	else:
		viewer_is_expanded = true
		btn_expand_contract.set_first_label_text("Shrink View")
		_expand_screen()


func show_settings() -> void : settings.show()
func hide_settings() -> void : settings.hide()
func consider_exit() -> void :
	if ask_for_exit_confirmation: show_exit()
	else: actually_exit()
func show_exit() -> void : exit.show()
func stay() -> void : exit.hide()
func actually_exit() -> void :
	%ClickBlocker.show()
	AudioServer.set_bus_mute(VolumeService.BUS_VCLIP, false)
	AudioServer.set_bus_mute(VolumeService.BUS_PLAYBACK, false)
	M.SaveData()
	resource.clear_incomplete_session()
	M.world.return_to_dub_selection()
func _goto_cinema() -> void :
	%ClickBlocker.show()
	AudioServer.set_bus_mute(VolumeService.BUS_VCLIP, false)
	AudioServer.set_bus_mute(VolumeService.BUS_PLAYBACK, false)
	M.world.ActiveHint(true, "Saving dub...")
	M.SaveData()
	await get_tree().create_timer(1.0).timeout
	M.world.ActiveHint(false)
	if !dub_save_folder: _save_dub()
	Metro.cinema_came_from_dub_mode = true
	Metro.cinema_from_dub_mode = FileManager.RECORDINGS_DUBS + resource.pack_info.path_from_pack + dub_save_folder + "/"
	Metro.cinema_name = [resource.pack_info.display_name, dub_save_folder]
	resource.clear_incomplete_session()
	M.world.enter_dub_cinema()


func _check_incomplete_session() -> void : if resource.has_incomplete_session(): load_last_session_prompt.show()
func _discard_incomplete_session() -> void :
	resource.clear_incomplete_session()
	load_last_session_prompt.hide()
func _load_incomplete_session() -> void :
	var clips_loaded: int = 0
	lbl_load_last_session.text = "Checking temp data..."
	for clip: OmniClipMemberInstance in performance_array:
		if clip.load_preserved_data(clip.shared_omniclip.file_name_agnostic, resource.get_temp_preserve_path()):
			clips_loaded += 1
			lbl_load_last_session.text = "Checking temp data...\n%s clips loaded..." % clips_loaded
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	load_last_session_prompt.hide()
