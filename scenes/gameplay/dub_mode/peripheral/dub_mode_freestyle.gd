extends Control



const DUB_RECORD_PREFIX: String = "_dubrecord_"
const CAPTION_EARLY: float = 0.6


@onready var btn_watch: ButtonCV = %BtnWatch
@onready var btn_begin: ButtonCV = %BtnBegin
@onready var btn_save_dub: ButtonCV = %BtnSaveDub
@onready var btn_refresh_mic: ButtonCV = %BtnRefreshMic
@onready var btn_toggle_assistance: ButtonCV = %BtnToggleAssistance
@onready var btn_expand_contract: ButtonCV = %BtnExpandContract
@onready var btn_goto_cinema: ButtonCV = %BtnGotoCinema


@onready var audio_interface_manager: AudioInterfaceManagerBufferless = %AudioInterfaceManagerBufferless
@onready var replay_streams: Node = %ReplayStreams
@onready var video_stream_player: VideoStreamPlayer = %VideoStreamPlayer
@onready var video_stream_player_expanded: VideoStreamPlayer = %VideoStreamPlayerExpanded
@onready var player_backing_track: AudioStreamPlayer = %PlayerBackingTrack
@onready var remote_buttons: VBoxContainer = %RemoteButtons
@onready var microphone_in: AudioStreamPlayer
@onready var exit_overlay: ColorRect = %Exit
@onready var settings: Control = %Settings
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var freestyle_streams: Node = %FreestyleStreams
@onready var lbl_countdown: Label = %LblCountdown
@onready var lbl_freestyle_caption_1: Label = %LblFreestyleCaption1
@onready var lbl_freestyle_caption_2: Label = %LblFreestyleCaption2
@onready var live_volume_magnitude_module: LiveVolumeModule = %LiveVolumeMagnitudeModule
@onready var freestyle_player: AudioStreamPlayer = %FreeStyle
@onready var captions_container: VBoxContainer = %CaptionsContainer
@onready var texture_active_clip: TextureRect = %TextureActiveClip
@onready var section_assistance: MarginContainer = %SectionAssistance
@onready var texture_clips_capsule: HFlowContainer = %TextureClipsCapsule


@export_group("Node Group - Method Calls")
@export var video_player_static: VideoStreamPlayer
@export var video_player_main_dynamic: VideoStreamPlayer
@export var video_static_buffer_timer: Timer


@export_group("Node Group - Visibility Changes")
@export var television_solid_color_background: ColorRect


var clip_index: int = 0
var dub_save_folder: String = ""
var previous_buttons_state: Array[bool]
var turn_record_attempts: int = 0
var performing_finished: bool = false
var ask_for_exit_confirmation: bool = true
var freestyle_caption_active_indexes: Array[int]
var freestyle_caption_previous_position: int
var full_recording: AudioStreamWAV
var recording_over: bool
var viewer_is_expanded: bool = false


var resource: GameplayResourceDubMode
var performance_array: Array[OmniClipMemberInstance]
var unperformance_array: Array[OmniClipMemberInstance]




func _remote_to_begin() -> void : remote_buttons.hide();btn_begin.show()
func _turn_on_static() -> void : video_player_static.play();video_player_static.show()

func _turn_off_static() -> void : video_player_static.stop();video_player_static.hide()
func _remote_to_main() -> void : btn_begin.hide();remote_buttons.show()
func _freestyle_play_sync_streams() -> void : for player: AudioStreamPlayer in freestyle_streams.get_children(): var timer: Timer = player.get_child(0);timer.start()
func _freestyle_play_video() -> void :
	video_stream_player.bus = "Mute"
	video_stream_player.stream = resource.video
	video_stream_player.show()
	video_stream_player.play()
	video_stream_player_expanded.stream = resource.video
	video_stream_player_expanded.play()
	player_backing_track.play()
func _freestyle_stop_video() -> void :
	for child: Node in freestyle_streams.get_children(): child.queue_free()
	if video_stream_player.is_playing(): video_stream_player.stop()
func _microphone_warmup() -> void : MicrophoneService.warmup()
func _microphone_record() -> void : MicrophoneService.recording_on()
func _microphone_finish() -> AudioStreamWAV: MicrophoneService.recording_off();return MicrophoneService.get_recording()
func _enable_buttons_save_watch() -> void : btn_save_dub.enable(true);btn_watch.enable(true)
func _magnitude_module_on() -> void : live_volume_magnitude_module.play()
func _magnitude_module_off() -> void : live_volume_magnitude_module.stop()
func _clear_captions_labels() -> void : lbl_freestyle_caption_1.text = "";lbl_freestyle_caption_2.text = ""


func _update_from_difficulty_toggles() -> void :
	AudioServer.set_bus_mute(VolumeService.BUS_VCLIP, Profile.dub_mode_hard_mute_clips and !recording_over)
	player_backing_track.volume_linear = float( !Profile.dub_mode_mute_backing_track) * float(recording_over)
	captions_container.visible = !Profile.dub_mode_hard_no_captions
	VolumeService.modulate_volume_voice = 1.0 if recording_over else float( !Profile.dub_mode_hard_mute_clips)


func reset_microphone() -> void :
	audio_interface_manager.idle()
	btn_refresh_mic.enable(false)
	MicrophoneService.disable()
	await get_tree().create_timer(0.75).timeout
	MicrophoneService.warmup()
	await MicrophoneService.mic_ready
	btn_refresh_mic.enable(true)


func _freestyle_begin_initiate() -> void :
	_turn_off_static()
	_remote_to_main()
	_magnitude_module_on()
func _freestyle_countdown() -> void :
	lbl_countdown.text = "3"
	lbl_countdown.show()
	for i: int in [3, 2, 1]:
		lbl_countdown.text = str(i)
		await get_tree().create_timer(1.0).timeout
	lbl_countdown.hide()
func _freestyle_core_gameplay() -> void :
	_freestyle_play_video()
	_freestyle_play_sync_streams()
	_microphone_record()
func _freestyle_core_finish() -> void :
	_freestyle_stop_video()
	if recording_over: return
	freestyle_player.stream = _microphone_finish()
	_magnitude_module_off()
	_clear_captions_labels()
	_enable_buttons_save_watch()
	recording_over = true
	_update_from_difficulty_toggles()
	_hide_and_disable_assistance()
	btn_expand_contract.show()
	btn_goto_cinema.show()
func _freestyle_watch() -> void :
	_freestyle_play_video()
	freestyle_player.play()
func _freestyle_flow_from_begin() -> void :
	_freestyle_begin_initiate()
	await _freestyle_countdown()
	_freestyle_core_gameplay()
func _hide_and_disable_assistance() -> void :
	btn_toggle_assistance.enable(false)
	section_assistance.hide()


func _freestyle_new_clip_caption(clip: OmniClip, start_time: float) -> void :
	clip_index += 1
	clip.set_meta("my_index", clip_index)
	_queue_new_clip_image(clip)
	if !clip.clip_caption: return
	if !lbl_freestyle_caption_1.text: _freestyle_set_label(lbl_freestyle_caption_1, clip, start_time);return
	if !lbl_freestyle_caption_2.text: _freestyle_set_label(lbl_freestyle_caption_2, clip, start_time);return
	var time_1: float = lbl_freestyle_caption_1.get_meta("start_time", -1)
	var time_2: float = lbl_freestyle_caption_2.get_meta("start_time", -1)
	if time_1 < time_2: _freestyle_set_label(lbl_freestyle_caption_1, clip, start_time)
	else: _freestyle_set_label(lbl_freestyle_caption_2, clip, start_time)
func _queue_new_clip_image(clip: OmniClip) -> void :
	var copy: TextureRect = texture_active_clip.duplicate()
	copy.texture = clip.clip_texture
	texture_clips_capsule.add_child(copy)
	await get_tree().create_timer(CAPTION_EARLY).timeout
	copy.show()
	await get_tree().create_timer(maxf(clip.get_length() - 0.166, 0.01)).timeout
	copy.queue_free()
func _freestyle_set_label(lbl: Label, clip: OmniClip, time: float) -> void :
	lbl.modulate = Color.WEB_GRAY;lbl.text = clip.clip_caption;lbl.set_meta("start_time", time);lbl.set_meta("clip", clip)
func _freestyle_remove_clip_caption(clip: OmniClip) -> void :
	if clip.get_meta("my_index", -1) == clip_index: texture_active_clip.texture = null
	if !clip.clip_caption: return
	for lbl: Label in [lbl_freestyle_caption_1, lbl_freestyle_caption_2]:
		var clip_time: float = lbl.get_meta("start_time", -1)
		if clip.dub_timestamps.has(clip_time) and clip.clip_caption == lbl.text: lbl.text = ""
func _execute_predelayed_clip(clip: OmniClip) -> void :
	var stream_player: AudioStreamPlayer = clip.get_meta("stream_player") as AudioStreamPlayer
	var label: Label
	if lbl_freestyle_caption_1.has_meta("clip") and lbl_freestyle_caption_1.get_meta("clip") == clip: label = lbl_freestyle_caption_1
	if lbl_freestyle_caption_2.has_meta("clip") and lbl_freestyle_caption_2.get_meta("clip") == clip: label = lbl_freestyle_caption_2
	if label: label.modulate = Color.WHITE
	stream_player.play()


func _setup_scene() -> void :
	video_stream_player.hide()
	television_solid_color_background.color = Color.BLACK
	exit_overlay.hide()
	_remote_to_begin()
	_turn_on_static()
	%TelevisionExpanded.hide();btn_expand_contract.hide();btn_goto_cinema.hide()
func _setup_freestyle() -> void :
	player_backing_track.stream = resource.backing_track
	for clip: OmniClip in resource.omni_clip_array.data:
		for start_time: float in clip.dub_timestamps:
			var new_stream: = AudioStreamPlayer.new()
			clip.set_meta("stream_player", new_stream)
			var new_timer: = Timer.new()
			new_timer.one_shot = true
			var start_time_early: float = maxf(0.01, start_time - CAPTION_EARLY)
			new_timer.wait_time = start_time_early
			new_timer.timeout.connect(_freestyle_new_clip_caption.bind(clip, start_time))
			new_timer.timeout.connect( func() -> void : await get_tree().create_timer(start_time - start_time_early).timeout;_execute_predelayed_clip(clip))
			new_stream.stream = clip.clip_audio
			new_stream.bus = "VclipPlayback"
			new_stream.finished.connect(_freestyle_remove_clip_caption.bind(clip))
			new_stream.finished.connect(new_stream.queue_free)
			new_stream.add_child(new_timer)
			freestyle_streams.add_child(new_stream)
func _toggle_assistance() -> void : section_assistance.visible = !section_assistance.visible
func _connect_signals() -> void :
	Profile.changed_dub_mode_options.connect(_update_from_difficulty_toggles)


func _exit_tree() -> void :
	VolumeService.modulate_volume_voice = 1.0
	MicrophoneService.disable()
func _ready() -> void :
	resource = Metro.gameplay_resource_dub_mode
	_connect_signals()
	_setup_scene()
	_setup_freestyle()
	_update_from_difficulty_toggles()



func _save_dub() -> void :
	btn_save_dub.enable(false)
	btn_save_dub.get_child(0).text = "Saving..."
	dub_save_folder = Time.get_datetime_string_from_system().validate_filename().replace("T", " ")
	var target_folder: String = "dub_recordings/" + resource.pack_info.path_from_pack + dub_save_folder + "_F/"
	DirAccess.make_dir_recursive_absolute(FileManager.RECORDINGS + target_folder)
	MicrophoneService.get_recording().save_to_wav(FileManager.RECORDINGS + target_folder + DUB_RECORD_PREFIX + "freestyle.wav")
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
func show_exit() -> void : exit_overlay.show()
func stay() -> void : exit_overlay.hide()
func actually_exit() -> void :
	AudioServer.set_bus_mute(VolumeService.BUS_VCLIP, false)
	M.SaveData();M.world.return_to_dub_selection()
func _goto_cinema() -> void :
	if !dub_save_folder: _save_dub()
	Metro.cinema_came_from_dub_mode = true
	Metro.cinema_from_dub_mode = FileManager.RECORDINGS_DUBS + resource.pack_info.path_from_pack + dub_save_folder + "/"
	Metro.cinema_name = [resource.pack_info.display_name, dub_save_folder]
	M.world.enter_dub_cinema()


func watch() -> void :
	pass
