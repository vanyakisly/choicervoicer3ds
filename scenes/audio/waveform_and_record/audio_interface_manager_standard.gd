class_name AudioInterfaceManagerStandard extends Node




enum INTERFACE_STATE{IDLE, FIRST, AGAIN, ENACT, WINCE}
enum PLAYBAR_STATE{IDLE, LEFT_BUFFER, WAVEFORM_AREA_VCLIP, WAVEFORM_AREA_PLMIC, RIGHT_BUFFER}


@export var waveform_display: WaveformDisplay
@export var spectrum_aggregate_vclip: SpectrumAggregateFinite
@export var spectrum_aggregate_plmic: SpectrumAggregateFinite
@export var waveform_buffer_left: TextureRect
@export var waveform_drawers_container: Control
@export var waveform_buffer_right: TextureRect
@export var audio_player_vclip: AudioStreamPlayer
@export var playbar: Control
@export var timer: Timer


var state: INTERFACE_STATE: set = _set_interface_state
var playbar_state: PLAYBAR_STATE




func load_omniclip(oc: OmniClip) -> void :
	for spectrum_aggregate: SpectrumAggregateFinite in [spectrum_aggregate_vclip, spectrum_aggregate_plmic]:
		spectrum_aggregate.clear()
		spectrum_aggregate.sample_index = 0
		spectrum_aggregate.resize_from_stream(oc.clip_audio)
	audio_player_vclip.stop()
	audio_player_vclip.stream = oc.clip_audio
	playbar.position.x = - playbar.size.x
func play_vclip() -> void :
	playbar_state = PLAYBAR_STATE.LEFT_BUFFER
	timer.start(waveform_buffer_left.custom_minimum_size.x * 20.0)




func _set_interface_state(value: INTERFACE_STATE) -> void :
	state = value
	match state:
		INTERFACE_STATE.IDLE:
			if (process_mode != Node.PROCESS_MODE_DISABLED): process_mode = Node.PROCESS_MODE_DISABLED
		INTERFACE_STATE.FIRST:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT

		INTERFACE_STATE.AGAIN:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
			pass
		INTERFACE_STATE.ENACT:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
			pass
		INTERFACE_STATE.WINCE:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
			pass
func _set_playbar_state(value: PLAYBAR_STATE) -> void :
	playbar_state = value
	process_mode = Node.PROCESS_MODE_DISABLED if playbar_state == PLAYBAR_STATE.IDLE else Node.PROCESS_MODE_INHERIT
	match playbar_state:
		PLAYBAR_STATE.LEFT_BUFFER:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
		PLAYBAR_STATE.WAVEFORM_AREA_VCLIP:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
			audio_player_vclip.play()
		PLAYBAR_STATE.WAVEFORM_AREA_PLMIC:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
			audio_player_vclip.play()
		PLAYBAR_STATE.RIGHT_BUFFER:
			if (process_mode != Node.PROCESS_MODE_INHERIT): process_mode = Node.PROCESS_MODE_INHERIT
			audio_player_vclip.stop()


func _process(_delta: float) -> void :
	match playbar_state:
		PLAYBAR_STATE.LEFT_BUFFER: playbar.position.x = timer.time_left / 20.0
		PLAYBAR_STATE.WAVEFORM_AREA_VCLIP, PLAYBAR_STATE.WAVEFORM_AREA_PLMIC: playbar.position.x = waveform_buffer_left.custom_minimum_size.x + timer.time_left / 20.0
		PLAYBAR_STATE.RIGHT_BUFFER: playbar.position.x = waveform_buffer_left.custom_minimum_size.x + waveform_drawers_container.custom_minimum_size.x + timer.time_left / 20.0
func _init() -> void :
	process_mode = Node.PROCESS_MODE_DISABLED
