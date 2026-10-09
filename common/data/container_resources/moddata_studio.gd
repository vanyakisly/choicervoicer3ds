class_name ModDataStudio extends Resource



var absolute_screen_texture: Texture2D
var studio_music: AudioStream
var score_screen_video: VideoStreamTheora


var music_loop_start: float
var use_builtin_light: bool = true


var color_block_border: Color
var color_body: Color
var color_playbar: Color
var color_record_backlight: Color
var color_record_light: Color
var color_plmic: Color
var color_vclip: Color


var has_studio: bool
var studio_failed_to_load: bool = false
var preload_studio: bool = false




func _get_color(input: Variant, default: String) -> Color:
	var input_string: String = type_convert(input, TYPE_STRING)
	if Color.html_is_valid(input_string): return Color.html(input_string)
	else: return Color.html(default)
func _load_colors(json_colors_section: Dictionary) -> void :
	color_body = _get_color(json_colors_section.get("body", "d1f6ff"), "d1f6ff")
	color_block_border = _get_color(json_colors_section.get("block_border", "80e5ff"), "80e5ff")
	color_playbar = _get_color(json_colors_section.get("playbar", "cc0000"), "cc0000")
	color_record_light = _get_color(json_colors_section.get("record_light", "7dcde3"), "7dcde3")
	color_record_backlight = _get_color(json_colors_section.get("record_backlight", "a1d6d5"), "a1d6d5")
	color_plmic = _get_color(json_colors_section.get("user_color", "00ffff"), "00ffff")
	color_vclip = _get_color(json_colors_section.get("voice_color", "ff00ff"), "ff00ff")
func _load_resources(target_folder: String) -> void :
	studio_music = VD.get_audio_agnositc(target_folder + "music_match")


func save_to_config(target_folder: String) -> void :
	if !target_folder.ends_with("/"): target_folder += "/"
	var data: Dictionary = {}
	data.use_builtin_light = use_builtin_light
	var data__recording_overlay_colors: Dictionary = {}
	data__recording_overlay_colors.block_border = color_block_border.to_html(false)
	data__recording_overlay_colors.body = color_body.to_html(false)
	data__recording_overlay_colors.playbar = color_playbar.to_html(false)
	data__recording_overlay_colors.record_backlight = color_record_backlight.to_html(false)
	data__recording_overlay_colors.record_light = color_record_light.to_html(false)
	data__recording_overlay_colors.user_color = color_plmic.to_html(false)
	data__recording_overlay_colors.voice_color = color_vclip.to_html(false)
	data.recording_overlay_color = data__recording_overlay_colors
	var data__audio: Dictionary = {}
	data__audio.music_studio_loop_start = music_loop_start
	data.audio = data__audio
	VD.save_json_object(FileManager.MODPACKS_STUDIO + target_folder + "config_studio.json", data, true)
func load_from_config(target_folder: String) -> void :
	var data: Dictionary = VD.load_json_object(FileManager.MODPACKS_STUDIO + target_folder + "config_studio.json")
	if data.has("audio"):
		var data__audio: Dictionary = type_convert(data.get("audio", {}), TYPE_DICTIONARY)
		music_loop_start = type_convert(data__audio.get("music_studio_loop_start", 0), TYPE_FLOAT)
	_load_colors(type_convert(data.get("recording_overlay_colors", {}), TYPE_DICTIONARY))


func _init(studio_pack_name: String) -> void :
	if !studio_pack_name.ends_with("/"): studio_pack_name += "/"
	var path: String = FileManager.MODPACKS_STUDIO + studio_pack_name
	load_from_config(studio_pack_name)
