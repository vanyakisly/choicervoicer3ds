extends Node

enum STATES{OFF, ENABLED, RECORDING}
var state: STATES = STATES.OFF
var wants_record: bool
func _process(delta: float) -> void :
	match state:
		STATES.OFF:
			return

		STATES.ENABLED:
			_common_idle_tick(delta)
			if wants_record:
				wants_record = false
				state = STATES.ENABLED
				return


		STATES.RECORDING:
			_common_idle_tick(delta)

			if !wants_record:
				wants_record = false
				state = STATES.RECORDING
				return

func _common_idle_tick(delta: float) -> void :
	pass




signal mic_ready
signal mic_off
signal waiting_mic_warmup
signal recording_started
signal recording_ended(record_result: AudioStream)


const PRINTSTR: String = "Microphone Service | "
const PLMIC_EFFECT_RECORD_INDEX: int = 7
const PLMIC_EFFECT_SPECTRUM_INDEX: int = 8


var plmic_bus_index: int = AudioServer.get_bus_index("Plmic")
var audio_effect_record: AudioEffectRecord: get = _get_audio_effect_record
var audio_effect_spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance: get = _get_audio_effect_spectrum_analyzer


var player: AudioStreamPlayer
var warmup_timer: Timer


var is_mic_available: bool = false: set = _set_is_mic_available
var enabled: bool = false: set = set_enabled, get = get_enabled
var recording: bool = false: set = set_recording, get = get_recording


func reset() -> void :
	if recording: recording = false
	if enabled: enabled = false
	enabled = true
func _initialize_player() -> void :
	player = AudioStreamPlayer.new()
	player.stream = AudioStreamMicrophone.new()
	player.bus = "Plmic"
	add_child(player)
func _initialize_warmup_timer() -> void :
	warmup_timer = Timer.new()
	warmup_timer.one_shot = true
	warmup_timer.wait_time = 2.0

	var show_mic_as_available: Callable = func() -> void : is_mic_available = enabled
	warmup_timer.timeout.connect(show_mic_as_available)
	add_child(warmup_timer)
func _init() -> void :
	_initialize_player()
	_initialize_warmup_timer()


func _set_is_mic_available(value: bool) -> void :
	if (value and !enabled):
		printerr(PRINTSTR + "Called to show microphone as available despite being inactive. It will be ignored.")
		return
	if (is_mic_available and !value): mic_off.emit()
	elif ( !is_mic_available and value): mic_ready.emit()
	is_mic_available = value
func set_enabled(value: bool) -> void :
	var player_is_playing = player.playing
	if (value and !player_is_playing): player.play();warmup_timer.start()
	elif (value and player_is_playing): printerr(PRINTSTR + "Microphone stream was called to play despite already being active.")
	elif ( !value and player_is_playing):
		if recording:
			printerr(PRINTSTR + "Microphone recording was active when microphone stream was called to stop.")
			recording = false
		is_mic_available = false
		player.stop()
	elif ( !value and !player_is_playing): printerr(PRINTSTR + "Microphone stream was called to stop despite already being inactive."); if is_mic_available: is_mic_available = false
	enabled = value
func set_recording(value: bool) -> void :
	if !enabled:
		if value: printerr(PRINTSTR + "Recording was called to activate despite the player being inactive. The call will be ignored.")
		else: printerr(PRINTSTR + "Recording was called to deactivate despite the player being inactive.")
		return
	if (recording and value): printerr(PRINTSTR + "Recording was called to activate despite already being active. It will be ignored.")
	elif (recording and !value): audio_effect_record.set_recording_active(false);recording_ended.emit(audio_effect_record.get_recording())
	elif ( !recording and value):
		if !is_mic_available:
			print(PRINTSTR + "Recording was called prematurely and will wait for mic warmup to complete before starting.")
			waiting_mic_warmup.emit()
			await mic_ready
		recording_started.emit()
		audio_effect_record.set_recording_active(true)
	elif ( !recording and !value): printerr(PRINTSTR + "Recording was called to deactivated despite already being inactive.")
	recording = value


func _get_audio_effect_record() -> AudioEffectRecord: return AudioServer.get_bus_effect(plmic_bus_index, PLMIC_EFFECT_RECORD_INDEX)
func _get_audio_effect_spectrum_analyzer() -> AudioEffectSpectrumAnalyzerInstance: return AudioServer.get_bus_effect_instance(plmic_bus_index, PLMIC_EFFECT_SPECTRUM_INDEX)
func get_enabled() -> bool: return player.playing
func get_recording() -> bool: return audio_effect_record.is_recording_active()
