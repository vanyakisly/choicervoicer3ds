extends Node


signal mic_ready
signal mic_off
signal waiting_mic_warmup
signal recording_started
signal recording_ended(record_result: AudioStream)


enum STATE{OFF, WARMUP, ENABLED, RECORDING}


const PRINTSTR: String = "Microphone Service | "
const PLMIC_EFFECT_RECORD_INDEX: int = 7
const PLMIC_EFFECT_SPECTRUM_INDEX: int = 8
const WARMUP_TIME: float = 1.5


var state: STATE = STATE.OFF: set = _set_state


var player: AudioStreamPlayer
var warmup_timer: Timer


var plmic_bus_index: int = AudioServer.get_bus_index("Plmic")
var audio_effect_record: AudioEffectRecord: get = _get_audio_effect_record
var audio_effect_spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance: get = _get_audio_effect_spectrum_analyzer




func _set_state(value: STATE) -> void :
	var state_pair: Array[STATE] = []
	state_pair = [state, value]
	match state_pair:
		[STATE.OFF, STATE.WARMUP]:
			player.play()
			warmup_timer.start()
			state = value;waiting_mic_warmup.emit()
		[STATE.WARMUP, STATE.OFF]:
			player.stop()
			warmup_timer.stop()
			state = value;mic_off.emit()
		[STATE.WARMUP, STATE.ENABLED]:
			if warmup_timer.time_left:
				printerr(PRINTSTR + "Tried leaving warmup without waiting sufficiently long.")
				return
			state = value;mic_ready.emit()
		[STATE.WARMUP, STATE.RECORDING]:
			printerr(PRINTSTR + "Tried recording while still in warmup.")
			waiting_mic_warmup.emit()
		[STATE.ENABLED, STATE.OFF]:
			player.stop()
			state = value;mic_off.emit()
		[STATE.ENABLED, STATE.RECORDING]:
			audio_effect_record.set_recording_active(true)
			state = value;recording_started.emit()
		[STATE.RECORDING, STATE.OFF]:
			audio_effect_record.set_recording_active(false)
			player.stop()
			mic_off.emit()
			state = value;recording_ended.emit(audio_effect_record.get_recording())
		[STATE.RECORDING, STATE.ENABLED]:
			audio_effect_record.set_recording_active(false)
			state = value;recording_ended.emit(audio_effect_record.get_recording())
		_: printerr(PRINTSTR + "Invalid state change was attmpted, from state `%s` to state `%s`" % [state, value])


func reset() -> void :
	state = STATE.OFF
	await get_tree().process_frame
	state = STATE.WARMUP
func disable() -> void : state = STATE.OFF
func warmup() -> void : state = STATE.WARMUP
func recording_on() -> void : state = STATE.RECORDING
func recording_off() -> void : state = STATE.ENABLED
func get_recording() -> AudioStreamWAV: return audio_effect_record.get_recording()


func _initialize_player() -> void :
	player = AudioStreamPlayer.new()
	player.stream = AudioStreamMicrophone.new()
	player.bus = "Plmic"
	add_child(player)
func _initialize_warmup_timer() -> void :
	warmup_timer = Timer.new()
	warmup_timer.one_shot = true
	warmup_timer.wait_time = WARMUP_TIME

	warmup_timer.timeout.connect(_set_state.bind(STATE.ENABLED))
	add_child(warmup_timer)


func _get_audio_effect_record() -> AudioEffectRecord: return AudioServer.get_bus_effect(plmic_bus_index, PLMIC_EFFECT_RECORD_INDEX)
func _get_audio_effect_spectrum_analyzer() -> AudioEffectSpectrumAnalyzerInstance: return AudioServer.get_bus_effect_instance(plmic_bus_index, PLMIC_EFFECT_SPECTRUM_INDEX)
func get_enabled() -> bool: return player.playing
func get_is_recording() -> bool: return audio_effect_record.is_recording_active()


func _init() -> void :
	_initialize_player()
	_initialize_warmup_timer()
