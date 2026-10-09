class_name OmniClip extends Resource


const PRINTMSG: String = "OmniClip | "

const SECTION_DATA: String = "data"

const KEY_CAPTION: String = "caption"
const KEY_DUB_TIMESTAMPS: String = "dub_timestamps"
const KEY_DUB_CHARACTERS: String = "dub_characters"
const KEY_IMAGE: String = "image"
const KEY_TAGS: String = "tags"
const KEY_DUB_ONLY: String = "dub_only"

const RESERVED_AUDIO_STARTERS: Array = [
	"_ignore", 
	"_backing_track", 
	"_dubrecord_freestyle"
]
const RESERVED_IMAGE_STARTERS: Array = [
	"_pack_filler_image", "_icon"
]


const ERROR_FLAG_DNE: int = 1
const ERROR_FLAG_LOAD_FAIL: int = 2
const ERROR_FLAG_LENGTH: int = 4
@export_flags("Path DNE", "Load Failure", "Too Long") var error_flags: int = 0
var error_report: String



@export var self_global_path: String: set = _set_self_global_path
var self_global_path_agnostic: String
var global_containing_folder: String
var file_name: String
var file_name_agnostic: String
var seen_path: String


@export var use_as: M.CLIP_USES


@export var clip_audio: AudioStream
@export var clip_texture: Texture2D


@export_multiline var clip_caption: String
@export var tags: PackedStringArray
@export var image_sibling_name: String
@export var dub_only: bool



@export var dub_timestamps: PackedFloat32Array
@export var dub_characters: PackedStringArray
@export var dub_use_as_is: bool


@export var seen: bool



func _init(use: = M.CLIP_USES.VOICE) -> void : use_as = use


func import_config_data(config: CondomFile) -> void :
	tags = config.get_section_key_as_packed_string_array(SECTION_DATA, KEY_TAGS)
	clip_caption = config.get_section_key_as_string(SECTION_DATA, KEY_CAPTION)
	image_sibling_name = config.get_section_key_as_string(SECTION_DATA, KEY_IMAGE)
	dub_timestamps = config.get_section_key_as_packed_float_array(SECTION_DATA, KEY_DUB_TIMESTAMPS)
	dub_only = config.get_section_key_as_bool(SECTION_DATA, KEY_DUB_ONLY)


func validate_audio() -> bool:
	if !FileAccess.file_exists(self_global_path):
		error_report = "Target file does not exist: `%s`" % self_global_path
		printerr(PRINTMSG + "Target file path `%s` does not exist." % self_global_path);error_flags = error_flags | ERROR_FLAG_DNE;return false
	clip_audio = VD.get_audio(self_global_path)
	if !clip_audio:
		error_report = "Target file failed to load. It may be in an incorrect format: `%s`" % self_global_path
		printerr(PRINTMSG + "Audio file `%s` failed to load and will be skipped." % self_global_path);error_flags = error_flags | ERROR_FLAG_LOAD_FAIL;return false
	if clip_audio.get_length() > 60.0:
		error_report = "Target file is longer than 60-second maximum clip length: `%s`" % self_global_path
		printerr(PRINTMSG + "Audio file `%s` is longer than the maximum allowed length of 60 seconds and will be skipped." % self_global_path);error_flags = error_flags | ERROR_FLAG_LENGTH;clip_audio = null;return false
	return true


func generate_from_audio_file_exact(global_file_path: String, include_folder_auto_tags: bool = true, auto_tag_trim_path: String = "") -> void :
	self_global_path = global_file_path

	if !validate_audio(): return
	var text_file_contents = VD.get_text_agnostic(self_global_path_agnostic)
	if !text_file_contents.strip_edges().begins_with("[data]"): clip_caption = text_file_contents

	var config: CondomFile = VD.get_config_agnostic(self_global_path_agnostic)
	if config:
		match use_as:
			M.CLIP_USES.VOICE: tags = config.get_section_key_as_packed_string_array(SECTION_DATA, KEY_TAGS)
			M.CLIP_USES.DUB:
				tags = config.get_section_key_as_packed_string_array(SECTION_DATA, KEY_DUB_CHARACTERS)
				dub_characters = config.get_section_key_as_packed_string_array(SECTION_DATA, KEY_DUB_CHARACTERS)
				dub_timestamps = config.get_section_key_as_packed_float_array(SECTION_DATA, KEY_DUB_TIMESTAMPS)
			M.CLIP_USES.EDITING:
				tags = config.get_section_key_as_packed_string_array(SECTION_DATA, KEY_TAGS)
				dub_characters = config.get_section_key_as_packed_string_array(SECTION_DATA, KEY_DUB_CHARACTERS)
				dub_timestamps = config.get_section_key_as_packed_float_array(SECTION_DATA, KEY_DUB_TIMESTAMPS)
		image_sibling_name = config.get_section_key_as_string(SECTION_DATA, KEY_IMAGE)
		if image_sibling_name:
			var possible_config_texture: Texture2D
			if image_sibling_name.contains("."): possible_config_texture = VD.get_texture(global_containing_folder + image_sibling_name)
			else: possible_config_texture = VD.get_texture_agnostic(global_containing_folder + image_sibling_name)
			if possible_config_texture: clip_texture = possible_config_texture
		if !clip_caption: clip_caption = config.get_section_key_as_string(SECTION_DATA, KEY_CAPTION)
		dub_only = config.get_section_key_as_bool(SECTION_DATA, KEY_DUB_ONLY)
	if !clip_texture: clip_texture = VD.get_texture_agnostic(self_global_path_agnostic);image_sibling_name = file_name_agnostic
	if !clip_texture: clip_texture = VD.get_texture_agnostic(global_containing_folder + "_pack_filler_image");image_sibling_name = "_pack_filler_image"
	if !clip_texture: clip_texture = VD.get_texture_agnostic(global_containing_folder + "_icon");image_sibling_name = "_icon"
	if !clip_texture: clip_texture = ProxyMiddlemanMenu.no_image;image_sibling_name = ""
	if include_folder_auto_tags and Profile.auto_tag_with_nested_folders:
		var auto_tag_path: String = seen_path.trim_prefix(auto_tag_trim_path)
		var path_split: PackedStringArray = auto_tag_path.split("/", false)
		if !path_split.is_empty():
			var folder_auto_tags: PackedStringArray = path_split.slice(0, -1)
			for tag: String in folder_auto_tags: tags.append(tag)




func get_length() -> float: return clip_audio.get_length()

func filter_for_agnostic_file(check_file_name: String) -> bool: return check_file_name.get_basename() == file_name_agnostic

func has_been_seen() -> bool: return Profile.seen_clips_voice.has(seen_path)

func is_within_length_filter_range() -> bool:
	if !Profile.clip_range_on: return true
	else:
		var length: float = get_length()
		return (length <= Profile.clip_range_maximum) and (length >= Profile.clip_range_minimum)



func attempt_to_mark_as_seen() -> void : if !Profile.seen_clips_voice.has(seen_path): Profile.seen_clips_voice.append(seen_path)


func save_config() -> void :
	var config: = ConfigFile.new()
	if clip_caption: config.set_value(SECTION_DATA, KEY_CAPTION, clip_caption)
	if tags: config.set_value(SECTION_DATA, KEY_TAGS, Array(tags))
	if image_sibling_name: config.set_value(SECTION_DATA, KEY_IMAGE, image_sibling_name)
	if dub_timestamps: config.set_value(SECTION_DATA, KEY_DUB_TIMESTAMPS, Array(dub_timestamps))
	if dub_characters: config.set_value(SECTION_DATA, KEY_DUB_CHARACTERS, Array(dub_characters))
	if dub_only: config.set_value(SECTION_DATA, KEY_DUB_ONLY, dub_only)
	VD.save_config(self_global_path_agnostic + ".ini", config)



func _set_self_global_path(value: String) -> void :
	self_global_path = value;file_name = self_global_path.get_file()
	file_name_agnostic = file_name.get_basename();self_global_path_agnostic = self_global_path.get_basename()
	global_containing_folder = self_global_path.get_base_dir() + "/"
	seen_path = self_global_path.replace(FileManager.MODPACKS_VOICE, "").get_basename()
