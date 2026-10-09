extends VBoxContainer

@onready var option_sampling_buffer: OptionButton = %OptionSamplingBuffer
@onready var option_countdown_type: OptionButton = %OptionCountdownType
@onready var chk_disable_volumetric_fog: CheckButton = %ChkDisableVolumetricFog
func _set_from_profile() -> void :
	option_sampling_buffer.select(Profile.debug_sample_timing)
	option_countdown_type.select(Profile.debug_countdown_type)
	chk_disable_volumetric_fog.button_pressed = Profile.debug_disable_fog
func _connect_signals() -> void :
	option_sampling_buffer.item_selected.connect(Profile._set_debug_sample_timing)
	option_countdown_type.item_selected.connect(Profile._set_debug_countdown_type)
	chk_disable_volumetric_fog.toggled.connect(Profile._set_debug_disable_fog)

func _ready() -> void :
	_set_from_profile()
	_connect_signals()
