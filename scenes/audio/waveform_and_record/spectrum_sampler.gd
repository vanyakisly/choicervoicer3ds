
class_name SpectrumSampler extends Node


signal taken_sample
signal resized(new_width: float)
signal finished


enum SAMPLING_TARGET{NONE, VCLIP, PLMIC}


const PITCH_C2: float = 65.41
const PITCH_C3: float = 130.81
const PITCH_C8: float = 4186.0
const PITCH_C9: float = 8372.0
const MIN_DB: float = 60.0
const PITCH_DIVISIONS: int = 128
const HZ_MAX: float = PITCH_C9


var audio_effect_spectrum_analyzer_instance: AudioEffectSpectrumAnalyzerInstance
var samples_magnitude_average: PackedByteArray
var samples_magnitude_maximum: PackedByteArray
var samples_pitch: PackedByteArray
var sample_index: int: set = _set_sample_index
var playing: bool = false: set = set_playing
var playing_uncapped: bool = false: set = set_playing_uncapped


@export var sampling_target: SAMPLING_TARGET: set = _set_sampling_target


var is_empty: bool:
	get: return samples_magnitude_average.is_empty()
var size: int:
	get: return samples_magnitude_average.size()
	set(value): resize_from_count(value)


func play(start: int = 0) -> void : sample_index = start;playing = true
func stop() -> void : playing = false;playing_uncapped = false;finished.emit()
func play_uncapped() -> void : sample_index = 0;playing_uncapped = true


func array_of_samples() -> Array[PackedByteArray]: return [samples_magnitude_average, samples_magnitude_maximum, samples_pitch]
func clear() -> void : emre.call_deferred();for a: PackedByteArray in array_of_samples(): a.clear()
func resize_from_time(time: float) -> void : emre.call_deferred(); var new_size: int = floori(time * 60.0);for a: PackedByteArray in array_of_samples(): a.resize(new_size)
func resize_from_stream(stream: AudioStream) -> void : emre.call_deferred(); var new_size: int = floori(stream.get_length() * 60.0);for a: PackedByteArray in array_of_samples(): a.resize(new_size)
func resize_from_count(count: int) -> void : emre.call_deferred();for a: PackedByteArray in array_of_samples(): a.resize(count)
func fill(value: int) -> void : for a: PackedByteArray in array_of_samples(): a.fill(value)
func remove_at_and_shift(index: int) -> void : for a: PackedByteArray in array_of_samples(): a.remove_at(index);a.append(0)


func _sample_frame_all(index: int = sample_index, send_signal: bool = true) -> void :
	samples_magnitude_average[index] = _frame_sample_magnitude_average()
	samples_magnitude_maximum[index] = _frame_sample_magnitude_maximum()
	samples_pitch[index] = _frame_sample_pitch()
	if send_signal: taken_sample.emit()
func _frame_sample_magnitude_average() -> int: return __frame_sample_magnitude(AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE)
func _frame_sample_magnitude_maximum() -> int: return __frame_sample_magnitude(AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX)
func __frame_sample_magnitude(type: AudioEffectSpectrumAnalyzerInstance.MagnitudeMode) -> int:
	var magnitude: float = audio_effect_spectrum_analyzer_instance.get_magnitude_for_frequency_range(PITCH_C2, PITCH_C9, type).length()
	var mag_percent: float = _magnitude_to_percent(magnitude)
	var mag_byte: int = floori(mag_percent * 255)
	return mag_byte
func _frame_sample_pitch() -> int: return floori(__average_from_pitch_set(__frame_sample_pitch_set()))
func __frame_sample_pitch_set() -> PackedByteArray:
	var pitch_set: PackedByteArray = []
	pitch_set.resize(PITCH_DIVISIONS)
	var hz_min: float = PITCH_C3
	var hz_max: float
	for d in range(PITCH_DIVISIONS):
		hz_max = (d + 1) * HZ_MAX / PITCH_DIVISIONS
		var magnitude: float = audio_effect_spectrum_analyzer_instance.get_magnitude_for_frequency_range(hz_min, hz_max, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX).length()
		var high: float = audio_effect_spectrum_analyzer_instance.get_magnitude_for_frequency_range(8372, 16744, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE).length()
		var mag_percent: float = _magnitude_to_percent(magnitude)
		var high_percent: float = _magnitude_to_percent(high)
		if high_percent > mag_percent: pitch_set[d] = floori(high_percent * 255)
		else: pitch_set[d] = floori(mag_percent * 128)
		hz_min = hz_max
	return pitch_set
func __average_from_pitch_set(pitch_set: PackedByteArray) -> float:
	var sum: int = 0
	var expected_value: float = 0.0
	for index in pitch_set.size():
		var sample: int = pitch_set[index]
		sum += sample
		expected_value += sample * index
	return expected_value / float(sum)


func _magnitude_to_percent(magnitude: float) -> float: return clampf((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0.0, 1.0)
func emre() -> void : resized.emit(size)


func set_playing(value: bool) -> void : playing = value;set_physics_process(playing)
func set_playing_uncapped(value: bool) -> void : playing_uncapped = value;set_physics_process(playing_uncapped)
func _set_sample_index(value: int) -> void : sample_index = clampi(value, 0, samples_magnitude_average.size())
func _set_sampling_target(value: SAMPLING_TARGET) -> void :
	sampling_target = value
	match sampling_target:
		SAMPLING_TARGET.VCLIP: audio_effect_spectrum_analyzer_instance = AudioServer.get_bus_effect_instance(VolumeService.BUS_VCLIP, 0)

		SAMPLING_TARGET.PLMIC: audio_effect_spectrum_analyzer_instance = MicrophoneService.audio_effect_spectrum_analyzer



func _physics_process(_delta: float) -> void :
	if playing:
		if sample_index < size: _sample_frame_all();sample_index += 1
		else: stop()
	elif playing_uncapped:
		if sample_index < size - 1: _sample_frame_all();sample_index += 1
		else: remove_at_and_shift(0);_sample_frame_all()
	else: stop()
