class_name AudioInterfaceManagerBufferless extends Node




signal idled


enum INTERFACE_STATE{IDLE, FIRST, AGAIN, ENACT, WINCE, PAUSE, RENEW}


const FRAMES_PER_SECOND: int = 60
const PIXELS_PER_FRAME: int = 3
const PIXELS_PER_SECOND: int = PIXELS_PER_FRAME * FRAMES_PER_SECOND


@export var waveform_display: WaveformDisplay
@export var waveform_drawers_container: Control
@export var playbar: Control
@export var spectrum_aggregate_vclip: SpectrumAggregateFinite
@export var spectrum_aggregate_plmic: SpectrumAggregateFinite
@export var audio_spectrum_sampler_vclip: AudioSpectrumSampler
@export var audio_spectrum_sampler_plmic: AudioSpectrumSampler
@export var audio_player_vclip: AudioStreamPlayer
@export var audio_player_pecho: AudioStreamPlayer


var state: INTERFACE_STATE: set = _set_interface_state




func load_omniclip(oc: OmniClip) -> void :
	if (process_mode != Node.PROCESS_MODE_DISABLED): process_mode = Node.PROCESS_MODE_DISABLED
	for spectrum_aggregate: SpectrumAggregateFinite in [spectrum_aggregate_vclip, spectrum_aggregate_plmic]:
		if !spectrum_aggregate: continue
		spectrum_aggregate.clear()
		spectrum_aggregate.sample_index = 0
		spectrum_aggregate.resize_from_stream(oc.clip_audio)
	waveform_drawers_container.custom_minimum_size.x = floori(PIXELS_PER_SECOND * oc.clip_audio.get_length())
	for child: Node in waveform_drawers_container.get_children(): if child is WaveformDrawer: child.queue_redraw()
	audio_player_vclip.stop()
	audio_player_vclip.stream = oc.clip_audio
	reset_playbar()
func idle() -> void : state = INTERFACE_STATE.IDLE
func first() -> void : state = INTERFACE_STATE.FIRST
func again() -> void : state = INTERFACE_STATE.AGAIN
func enact() -> void : state = INTERFACE_STATE.ENACT
func wince() -> void : state = INTERFACE_STATE.WINCE
func pause() -> void : state = INTERFACE_STATE.PAUSE
func renew() -> void : state = INTERFACE_STATE.RENEW
func reset_playbar() -> void : playbar.position.x = 0
func reset_plmic_sampling(reset_index: bool = true) -> void :
	spectrum_aggregate_plmic.clear()
	spectrum_aggregate_plmic.resize_from_stream(audio_player_vclip.stream)
	if reset_index: spectrum_aggregate_plmic.sample_index = 0


func _set_interface_state(value: INTERFACE_STATE) -> void :
	state = value

	match state:
		INTERFACE_STATE.IDLE:
			if (process_mode != Node.PROCESS_MODE_DISABLED): process_mode = Node.PROCESS_MODE_DISABLED
			if audio_player_vclip.stream_paused: audio_player_vclip.stream_paused = false
			if audio_player_pecho.stream_paused: audio_player_pecho.stream_paused = false
			if audio_player_vclip.playing: audio_player_vclip.stop()
			if audio_player_pecho.playing: audio_player_pecho.stop()
			if audio_spectrum_sampler_vclip.playing: audio_spectrum_sampler_vclip.stop()
			if audio_spectrum_sampler_plmic.playing: audio_spectrum_sampler_plmic.stop()
			if MicrophoneService.state == MicrophoneService.STATE.RECORDING: MicrophoneService.state = MicrophoneService.STATE.ENABLED
			if audio_player_vclip.bus != "Vclip": audio_player_vclip.bus = "Vclip"
			idled.emit()

		INTERFACE_STATE.FIRST:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
			if audio_player_vclip.volume_linear < 1.0: audio_player_vclip.volume_linear = 1.0
			audio_player_vclip.play()
			audio_spectrum_sampler_vclip.play()

		INTERFACE_STATE.AGAIN:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
			if audio_player_vclip.volume_linear < 1.0: audio_player_vclip.volume_linear = 1.0
			audio_player_vclip.play()

		INTERFACE_STATE.ENACT:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
			if audio_player_vclip.volume_linear < 1.0: audio_player_vclip.volume_linear = 1.0
			reset_plmic_sampling()
			audio_player_vclip.bus = "VclipPlayback"
			audio_player_vclip.play()
			await get_tree().create_timer(0.125).timeout
			MicrophoneService.recording_on()
			audio_spectrum_sampler_plmic.play()

		INTERFACE_STATE.WINCE:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
			if audio_player_vclip.volume_linear > 0.0: audio_player_vclip.volume_linear = 0.0
			audio_player_vclip.play()
			audio_player_pecho.play()

		INTERFACE_STATE.PAUSE:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
			if audio_player_vclip.playing: audio_player_vclip.stream_paused = true
			if audio_player_pecho.playing: audio_player_pecho.stream_paused = true
			if audio_spectrum_sampler_vclip.playing: audio_spectrum_sampler_vclip.stop()
			if audio_spectrum_sampler_plmic.playing: audio_spectrum_sampler_plmic.stop()
			if MicrophoneService.state == MicrophoneService.STATE.RECORDING: MicrophoneService.state = MicrophoneService.STATE.ENABLED

		INTERFACE_STATE.RENEW:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
			if audio_player_vclip.volume_linear < 1.0: audio_player_vclip.volume_linear = 1.0
			audio_player_vclip.stream_paused = false
			if !spectrum_aggregate_vclip.full: audio_spectrum_sampler_vclip.play()



func _setup_signals() -> void :
	audio_player_vclip.finished.connect(vclip_timeout_attempt_idle)
	spectrum_aggregate_vclip.samples_filled.connect(_on_vclip_samples_filled)
	if spectrum_aggregate_plmic: spectrum_aggregate_plmic.samples_filled.connect(_on_plmic_samples_filled)
func vclip_timeout_attempt_idle() -> void : if state != INTERFACE_STATE.ENACT: idle()
func _on_vclip_samples_filled() -> void :
	audio_spectrum_sampler_vclip.stop()
	idle()
func _on_plmic_samples_filled() -> void :
	MicrophoneService.recording_off()
	audio_spectrum_sampler_plmic.stop()
	audio_player_pecho.stream = MicrophoneService.get_recording()
	idle()


func _process(_delta: float) -> void :
	playbar.position.x = audio_player_vclip.get_playback_position() / audio_player_vclip.stream.get_length() * waveform_drawers_container.custom_minimum_size.x










func _init() -> void :
	process_mode = Node.PROCESS_MODE_DISABLED
func _ready() -> void :
	_setup_signals()
