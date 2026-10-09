@icon("res://assets/gd_icons/audio_spectrum_sampler.png")
class_name AudioSpectrumSampler extends Node

signal sample_taken(samples: SpectrumFrame)


enum SPECTRUMS{NONE, VCLIP, PLMIC, VCLIP_DUAL_A, VCLIP_DUAL_B}


const PRINTSTR: String = "AudioSpectrumSampler | "
const SPECTRUM_INDEX_PLMIC: int = 8
const SPECTRUM_INDEX_VCLIP: int = 0
const PITCH_C2: float = 65.41
const PITCH_C3: float = 130.81
const PITCH_C8: float = 4186.0
const PITCH_C9: float = 8372.0
const MIN_DB: float = 60.0
const PITCH_DIVISIONS: int = 128
const HZ_MAX: float = PITCH_C9








@export var spectrum_target: SPECTRUMS = SPECTRUMS.NONE: set = _set_spectrum_target
var local_analyzer: AudioEffectSpectrumAnalyzerInstance
var playing: bool = false: set = _set_playing



func play() -> void : playing = true
func stop() -> void : playing = false


func _sample_frame_all() -> void :
	if !local_analyzer: printerr(PRINTSTR + "No spectrum analyzer is set. This sample call will be ignored.");return
	var sampled_byte_magnitude_average: int = _frame_sample_magnitude_average()
	var sampled_byte_magnitude_maximum: int = _frame_sample_magnitude_maximum()
	var sampled_byte_pitch: int = _frame_sample_pitch()
	var samples: = SpectrumFrame.new()
	samples.set_samples(sampled_byte_magnitude_average, sampled_byte_magnitude_maximum, sampled_byte_pitch)
	sample_taken.emit(samples)
func _frame_sample_magnitude_average() -> int: return __frame_sample_magnitude(AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE)
func _frame_sample_magnitude_maximum() -> int: return __frame_sample_magnitude(AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX)
func __frame_sample_magnitude(type: AudioEffectSpectrumAnalyzerInstance.MagnitudeMode) -> int:
	if !local_analyzer: printerr(PRINTSTR + "If you see this, something has gone horribly wrong.");return 0
	var magnitude: float = local_analyzer.get_magnitude_for_frequency_range(PITCH_C2, PITCH_C9, type).length()
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
		var magnitude: float = local_analyzer.get_magnitude_for_frequency_range(hz_min, hz_max, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_MAX).length()
		var high: float = local_analyzer.get_magnitude_for_frequency_range(PITCH_C9, 16744, AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE).length()
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


func _set_spectrum_target(value: SPECTRUMS) -> void :
	spectrum_target = value
	match spectrum_target:
		SPECTRUMS.NONE: local_analyzer = null




		SPECTRUMS.PLMIC: local_analyzer = AudioServer.get_bus_effect_instance(VolumeService.BUS_PLMIC, SPECTRUM_INDEX_PLMIC)
		SPECTRUMS.VCLIP: local_analyzer = AudioServer.get_bus_effect_instance(VolumeService.BUS_VCLIP, SPECTRUM_INDEX_VCLIP)
		SPECTRUMS.VCLIP_DUAL_A: local_analyzer = AudioServer.get_bus_effect_instance(VolumeService.BUS_VCLIP_DUAL_A, SPECTRUM_INDEX_VCLIP)
		SPECTRUMS.VCLIP_DUAL_B: local_analyzer = AudioServer.get_bus_effect_instance(VolumeService.BUS_VCLIP_DUAL_B, SPECTRUM_INDEX_VCLIP)
func _set_playing(value: bool) -> void :
	playing = value






	if playing:
		match Profile.debug_sample_timing:
			0: while playing:
				_sample_frame_all()
				await get_tree().physics_frame
			1: while playing:
				_sample_frame_all()
				await get_tree().process_frame
			2: while playing:
				_sample_frame_all()
				await get_tree().create_timer(0.016).timeout
			3:
				var prev_sample_msec: int = 0
				while playing:
					if (Time.get_ticks_msec() - prev_sample_msec > 3):
						prev_sample_msec = Time.get_ticks_msec()
						_sample_frame_all()
					await get_tree().physics_frame
			4:
				var prev_sample_msec: int = 0
				while playing:
					if (Time.get_ticks_msec() - prev_sample_msec > 3):
						prev_sample_msec = Time.get_ticks_msec()
						_sample_frame_all()
					await get_tree().process_frame
			5:
				var prev_sample_msec: int = 0
				while playing:
					if (Time.get_ticks_msec() - prev_sample_msec > 16):
						prev_sample_msec = Time.get_ticks_msec()
						_sample_frame_all()
					await get_tree().physics_frame










func _ready() -> void : playing = false
