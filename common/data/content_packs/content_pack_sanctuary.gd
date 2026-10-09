class_name ContentPackSanctuary extends ContentPackCore




const SECTION_SANCTUARY: String = "sanctuary"
const KEY_COLOR_SKY: String = "color_sky"
const KEY_COLOR_HORIZON: String = "color_horizon"
const KEY_COLOR_GROUND: String = "color_ground"
const KEY_USE_OWN_LIGHTING: String = "use_own_lighting"
const KEY_TARGET_MODEL_ENVIRONMENT: String = "target_model_environment"
const KEY_TARGET_MUSIC: String = "music"
const KEY_ADVANCED_CURVE_SKY: String = "advanced_curve_sky"
const KEY_ADVANCED_CURVE_GROUND: String = "advanced_curve_ground"


const DEFAULT_COLOR_SKY: = Color("a9d3db")
const DEFAULT_COLOR_HORIZON: = Color.WHITE
const DEFAULT_COLOR_GROUND: = Color("4fe8ff")
const DEFAULT_TARGET_MUSIC: PackedStringArray = []




@export var color_sky: Color
@export var color_horizon: Color
@export var color_ground: Color
@export var use_own_lighting: bool
@export var target_model_environment: String
@export var target_music: PackedStringArray
@export var advanced_curve_sky: float
@export var advanced_curve_ground: float


@export var music: Array[AudioStream]




func _get_pack_data_from_config() -> void :
	color_sky = data.get_section_key_as_color(SECTION_SANCTUARY, KEY_COLOR_SKY, DEFAULT_COLOR_SKY, false)
	color_horizon = data.get_section_key_as_color(SECTION_SANCTUARY, KEY_COLOR_HORIZON, DEFAULT_COLOR_HORIZON, false)
	color_ground = data.get_section_key_as_color(SECTION_SANCTUARY, KEY_COLOR_GROUND, DEFAULT_COLOR_GROUND, false)
	target_music = data.get_section_key_as_packed_string_array(SECTION_SANCTUARY, KEY_TARGET_MUSIC, DEFAULT_TARGET_MUSIC)
func _get_pack_resources_from_config() -> void :
	for file: String in target_music: music.append(VD.get_audio_either(pack_folder_name_global + file))
