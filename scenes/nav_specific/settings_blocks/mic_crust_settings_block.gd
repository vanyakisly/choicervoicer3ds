extends VBoxContainer


@onready var save_line: HBoxContainer = %SaveLine
@onready var btn_open_save: ButtonCV = %BtnOpenSave
@onready var btn_save: ButtonCV = %BtnSave
@onready var line_crust_profile_name: LineEdit = %LineCrustProfileName
@onready var lbl_btn_save: Label = %LblBtnSave

@onready var option_crust_profiles: OptionButton = %OptionCrustProfiles

@onready var chk_compressor: CheckButton = %ChkCompressor
@onready var slider_compressor_threshold: HSlider = %SliderCompressorThreshold
@onready var slider_compressor_gain: HSlider = %SliderCompressorGain
@onready var chk_limiter: CheckButton = %ChkLimiter
@onready var slider_limiter_ceiling: HSlider = %SliderLimiterCeiling
@onready var slider_limiter_threshold: HSlider = %SliderLimiterThreshold
@onready var chk_cutoff: CheckButton = %ChkCutoff
@onready var slider_cutoff_high_pass: HSlider = %SliderCutoffHighPass
@onready var slider_cutoff_low_pass: HSlider = %SliderCutoffLowPass
@onready var chk_distortion: CheckButton = %ChkDistortion
@onready var slider_distortion_pre_gain: HSlider = %SliderDistortionPreGain
@onready var slider_distortion_drive: HSlider = %SliderDistortionDrive
@onready var slider_distortion_post_gain: HSlider = %SliderDistortionPostGain
@onready var chk_sample_rate: CheckButton = %ChkSampleRate
@onready var slider_sample_rate_index: HSlider = %SliderSampleRateReduction
@onready var slider_mic_input_volume: HSlider = %SliderMicInputVolume
@onready var slider_mic_multiplier: HSlider = %SliderMicMultiplier

@onready var lbl_compressor_threshold: Label = %LblCompressorThreshold
@onready var lbl_compressor_gain: Label = %LblCompressorGain
@onready var lbl_cutoff_high_pass: Label = %LblCutoffHighPass
@onready var lbl_cutoff_low_pass: Label = %LblCutoffLowPass
@onready var lbl_distortion_pre_gain: Label = %LblDistortionPreGain
@onready var lbl_distortion_drive: Label = %LblDistortionDrive
@onready var lbl_distortion_post_gain: Label = %LblDistortionPostGain
@onready var lbl_limiter_ceiling: Label = %LblLimiterCeiling
@onready var lbl_limiter_threshold: Label = %LblLimiterThreshold
@onready var lbl_sample_rate_reduction: Label = %LblSampleRateReduction
@onready var lbl_mic_input_volume: Label = %LblMicInputVolume
@onready var lbl_mic_multiplier: Label = %LblMicMultiplier

@onready var row_high_pass: HBoxContainer = %RowHighPass
@onready var row_low_pass: HBoxContainer = %RowLowPass


var reset_to_custom_enabled: bool = false


func _ready() -> void :
	save_line.hide()
	_connect_signals()

	_update_from_profile()
	reset_to_custom_enabled = false
	_set_to_custom_and_update_labels_from_sliders()
	reset_to_custom_enabled = true


func _connect_signals() -> void :
	chk_compressor.toggled.connect(Profile._set_mic_crust_compressor_on)
	chk_limiter.toggled.connect(Profile._set_mic_crust_limiter_on)
	chk_cutoff.toggled.connect(Profile._set_mic_crust_cutoff_on)
	chk_distortion.toggled.connect(Profile._set_mic_crust_distortion_on)
	chk_sample_rate.toggled.connect(Profile._set_mic_crust_sample_rate_on)
	slider_compressor_threshold.value_changed.connect(Profile._set_mic_crust_compressor_threshold)
	slider_compressor_gain.value_changed.connect(Profile._set_mic_crust_compressor_gain)
	slider_limiter_ceiling.value_changed.connect(Profile._set_mic_crust_limiter_ceilingdb)
	slider_limiter_threshold.value_changed.connect(Profile._set_mic_crust_limiter_thresholddb)
	slider_cutoff_high_pass.value_changed.connect(Profile._set_mic_crust_cutoff_high_pass)
	slider_cutoff_low_pass.value_changed.connect(Profile._set_mic_crust_cutoff_low_pass)
	slider_distortion_pre_gain.value_changed.connect(Profile._set_mic_crust_distortion_pre_gain)
	slider_distortion_drive.value_changed.connect(Profile._set_mic_crust_distortion_drive)
	slider_distortion_post_gain.value_changed.connect(Profile._set_mic_crust_distortion_post_gain)
	slider_sample_rate_index.value_changed.connect(Profile._set_mic_crust_sample_rate_index)
	slider_mic_input_volume.value_changed.connect(Profile._set_mic_crust_mic_input)
	slider_mic_multiplier.value_changed.connect(Profile._set_mic_crust_mic_multiplier)

	chk_compressor.toggled.connect(_set_to_custom_and_update_labels_from_sliders)
	chk_limiter.toggled.connect(_set_to_custom_and_update_labels_from_sliders)
	chk_cutoff.toggled.connect(_set_to_custom_and_update_labels_from_sliders)
	chk_distortion.toggled.connect(_set_to_custom_and_update_labels_from_sliders)
	chk_sample_rate.toggled.connect(_set_to_custom_and_update_labels_from_sliders)
	slider_compressor_threshold.value_changed.connect(_set_to_custom_and_update_labels_from_sliders)
	slider_compressor_gain.value_changed.connect(_set_to_custom_and_update_labels_from_sliders)
	slider_limiter_ceiling.value_changed.connect(_set_to_custom_and_update_labels_from_sliders)
	slider_limiter_threshold.value_changed.connect(_set_to_custom_and_update_labels_from_sliders)
	slider_cutoff_high_pass.value_changed.connect(_set_to_custom_and_update_labels_from_sliders)
	slider_cutoff_low_pass.value_changed.connect(_set_to_custom_and_update_labels_from_sliders)
	slider_distortion_pre_gain.value_changed.connect(_set_to_custom_and_update_labels_from_sliders)
	slider_distortion_drive.value_changed.connect(_set_to_custom_and_update_labels_from_sliders)
	slider_distortion_post_gain.value_changed.connect(_set_to_custom_and_update_labels_from_sliders)
	slider_sample_rate_index.value_changed.connect(_set_to_custom_and_update_labels_from_sliders)
	slider_mic_input_volume.value_changed.connect(_set_to_custom_and_update_labels_from_sliders)
	slider_mic_multiplier.value_changed.connect(_set_to_custom_and_update_labels_from_sliders)


func _update_from_profile() -> void :
	reset_to_custom_enabled = false
	chk_compressor.button_pressed = Profile.mic_crust_compressor_on
	chk_limiter.button_pressed = Profile.mic_crust_limiter_on
	chk_cutoff.button_pressed = Profile.mic_crust_cutoff_on
	chk_distortion.button_pressed = Profile.mic_crust_distortion_on
	chk_sample_rate.button_pressed = Profile.mic_crust_sample_rate_on
	slider_compressor_threshold.value = Profile.mic_crust_compressor_threshold
	slider_compressor_gain.value = Profile.mic_crust_compressor_gain
	slider_limiter_ceiling.value = Profile.mic_crust_limiter_ceilingdb
	slider_limiter_threshold.value = Profile.mic_crust_limiter_thresholddb
	slider_cutoff_high_pass.value = Profile.mic_crust_cutoff_high_pass
	slider_cutoff_low_pass.value = Profile.mic_crust_cutoff_low_pass
	slider_distortion_pre_gain.value = Profile.mic_crust_distortion_pre_gain
	slider_distortion_drive.value = Profile.mic_crust_distortion_drive
	slider_distortion_post_gain.value = Profile.mic_crust_distortion_post_gain
	slider_sample_rate_index.value = Profile.mic_crust_sample_rate_index
	slider_mic_input_volume.value = Profile.mic_crust_mic_input
	slider_mic_multiplier.value = Profile.mic_crust_mic_multiplier
	reset_to_custom_enabled = true


func _set_to_custom_and_update_labels_from_sliders(_dummy: Variant = null) -> void :

	lbl_compressor_threshold.text = "%1.1f dB" % slider_compressor_threshold.value
	lbl_compressor_gain.text = "%1.1f" % slider_compressor_gain.value
	lbl_cutoff_high_pass.text = "%s Hz" % slider_cutoff_high_pass.value
	lbl_cutoff_low_pass.text = "%s Hz" % slider_cutoff_low_pass.value
	lbl_distortion_pre_gain.text = "%1.1f dB" % slider_distortion_pre_gain.value
	lbl_distortion_drive.text = "%s" % slider_distortion_drive.value
	lbl_distortion_post_gain.text = "%1.1f dB" % slider_distortion_post_gain.value
	lbl_limiter_ceiling.text = "%1.1f dB" % slider_limiter_ceiling.value
	lbl_limiter_threshold.text = "%1.1f dB" % slider_limiter_threshold.value
	lbl_sample_rate_reduction.text = "1/%1.0f" % pow(2.0, slider_sample_rate_index.value)
	if slider_cutoff_high_pass.value >= slider_cutoff_low_pass.value:
		if row_high_pass.modulate != Color.FIREBRICK: row_high_pass.modulate = Color.FIREBRICK
		if row_low_pass.modulate != Color.FIREBRICK: row_low_pass.modulate = Color.FIREBRICK
	else:
		if row_high_pass.modulate != Color.WHITE: row_high_pass.modulate = Color.WHITE
		if row_low_pass.modulate != Color.WHITE: row_low_pass.modulate = Color.WHITE
	lbl_mic_input_volume.text = "%1.0f%%" % [slider_mic_input_volume.value * 100.0]
	lbl_mic_multiplier.text = "%1.0fx" % slider_mic_multiplier.value
