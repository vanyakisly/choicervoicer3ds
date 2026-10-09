extends Node



var mic_delay: float: set = _set_mic_delay
var mic_crust_compressor_on: bool: set = _set_mic_crust_compressor_on
var mic_crust_cutoff_on: bool: set = _set_mic_crust_cutoff_on
var mic_crust_limiter_on: bool: set = _set_mic_crust_limiter_on
var mic_crust_distortion_on: bool: set = _set_mic_crust_distortion_on
var mic_crust_sample_rate_on: bool: set = _set_mic_crust_sample_rate_on
var mic_crust_sample_rate_index: int: set = _set_mic_crust_sample_rate_index
var mic_crust_cutoff_low_pass: int: set = _set_mic_crust_cutoff_low_pass
var mic_crust_cutoff_high_pass: int: set = _set_mic_crust_cutoff_high_pass
var mic_crust_compressor_threshold: float: set = _set_mic_crust_compressor_threshold
var mic_crust_compressor_gain: float: set = _set_mic_crust_compressor_gain
var mic_crust_limiter_ceilingdb: float: set = _set_mic_crust_limiter_ceilingdb
var mic_crust_limiter_thresholddb: float: set = _set_mic_crust_limiter_thresholddb
var mic_crust_distortion_pre_gain: float: set = _set_mic_crust_distortion_pre_gain
var mic_crust_distortion_drive: float: set = _set_mic_crust_distortion_drive
var mic_crust_distortion_post_gain: float: set = _set_mic_crust_distortion_post_gain
var mic_crust_mic_input: float: set = _set_mic_crust_mic_input




func reduce_recording_sample_rate(input: AudioStreamWAV, sample_rate_index: int = Profile.mic_crust_sample_rate_index) -> AudioStreamWAV:
	sample_rate_index = clampi(sample_rate_index, 0, 5)
	sample_rate_index = 2 ** sample_rate_index
	var data = input.get_data().duplicate()
	var crusted_data: PackedByteArray = []
	for datapoint_idx in range(0, data.size(), sample_rate_index * 4):
		var crust_repeat: PackedByteArray = data.slice(datapoint_idx, datapoint_idx + 4)
		for i in range(sample_rate_index): crusted_data.append_array(crust_repeat)
	var crust_audio: AudioStreamWAV = input.duplicate(true)
	crust_audio.set_data(crusted_data)
	return crust_audio


func _set_mic_delay(value: float) -> void : mic_delay = value
func _set_mic_crust_compressor_on(value: bool) -> void :
	mic_crust_compressor_on = value
	AudioServer.set_bus_effect_enabled(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_COMPRESSOR, mic_crust_compressor_on)
func _set_mic_crust_cutoff_on(value: bool) -> void :
	mic_crust_cutoff_on = value
	AudioServer.set_bus_effect_enabled(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_HIGH_PASS, mic_crust_cutoff_on)
	AudioServer.set_bus_effect_enabled(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_LOW_PASS, mic_crust_cutoff_on)
func _set_mic_crust_limiter_on(value: bool) -> void :
	mic_crust_limiter_on = value
	AudioServer.set_bus_effect_enabled(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_LIMITER, mic_crust_limiter_on)
func _set_mic_crust_distortion_on(value: bool) -> void :
	mic_crust_distortion_on = value
	AudioServer.set_bus_effect_enabled(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_DISTORTION, mic_crust_distortion_on)
func _set_mic_crust_sample_rate_on(value: bool) -> void : mic_crust_sample_rate_on = value


func _set_mic_crust_sample_rate_index(value: int) -> void : mic_crust_sample_rate_index = value
func _set_mic_crust_cutoff_low_pass(value: int) -> void :
	mic_crust_cutoff_low_pass = value
	var effect: AudioEffectLowPassFilter = AudioServer.get_bus_effect(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_LOW_PASS)
	effect.cutoff_hz = mic_crust_cutoff_low_pass
func _set_mic_crust_cutoff_high_pass(value: int) -> void :
	mic_crust_cutoff_high_pass = value
	var effect: AudioEffectHighPassFilter = AudioServer.get_bus_effect(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_HIGH_PASS)
	effect.cutoff_hz = mic_crust_cutoff_high_pass
func _set_mic_crust_compressor_threshold(value: float) -> void :
	mic_crust_compressor_threshold = value
	var effect: AudioEffectCompressor = AudioServer.get_bus_effect(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_COMPRESSOR)
	effect.threshold = mic_crust_compressor_threshold
func _set_mic_crust_compressor_gain(value: float) -> void :
	mic_crust_compressor_gain = value
	var effect: AudioEffectCompressor = AudioServer.get_bus_effect(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_COMPRESSOR)
	effect.gain = mic_crust_compressor_gain
func _set_mic_crust_limiter_ceilingdb(value: float) -> void :
	mic_crust_limiter_ceilingdb = value
	var effect: AudioEffectLimiter = AudioServer.get_bus_effect(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_LIMITER)
	effect.ceiling_db = mic_crust_limiter_ceilingdb
func _set_mic_crust_limiter_thresholddb(value: float) -> void :
	mic_crust_limiter_thresholddb = value
	var effect: AudioEffectLimiter = AudioServer.get_bus_effect(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_LIMITER)
	effect.threshold_db = mic_crust_limiter_thresholddb
func _set_mic_crust_distortion_pre_gain(value: float) -> void :
	mic_crust_distortion_pre_gain = value
	var effect: AudioEffectDistortion = AudioServer.get_bus_effect(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_DISTORTION)
	effect.pre_gain = mic_crust_distortion_pre_gain
func _set_mic_crust_distortion_drive(value: float) -> void :
	mic_crust_distortion_drive = value
	var effect: AudioEffectDistortion = AudioServer.get_bus_effect(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_DISTORTION)
	effect.drive = mic_crust_distortion_drive
func _set_mic_crust_distortion_post_gain(value: float) -> void :
	mic_crust_distortion_post_gain = value
	var effect: AudioEffectDistortion = AudioServer.get_bus_effect(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_DISTORTION)
	effect.post_gain = mic_crust_distortion_post_gain
func _set_mic_crust_mic_input(value: float) -> void :
	mic_crust_mic_input = value
	var effect: AudioEffectAmplify = AudioServer.get_bus_effect(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_AMPLIFY)
	effect.volume_linear = value
