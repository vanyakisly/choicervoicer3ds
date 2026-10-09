class_name ContentPackCore extends Resource




const SECTION_DATA: String = "data"
const KEY_VERSION: String = "version"
const KEY_DISPLAY_NAME: String = "name"
const KEY_AUTHORS: String = "authors"
const KEY_BLURB: String = "blurb"
const KEY_README: String = "readme"
const KEY_CREDITS: String = "credits"
const KEY_TARGET_ICON: String = "icon"


const DEFAULT_VERSION: String = ""

const DEFAULT_AUTHORS: PackedStringArray = []
const DEFAULT_BLURB: String = ""
const DEFAULT_README: String = ""
const DEFAULT_CREDITS: String = ""
const DEFAULT_TARGET_ICON: String = "_icon"




var global_config_path: String
var unique_name: String
var date: String


var pack_folder_name: String: get = _get_pack_folder_name
func _get_pack_folder_name() -> String:
	var work: String = unique_name
	work = work.trim_suffix("/")
	var a: = work.split("/")
	work = a[-1]
	work += "/"

	return unique_name.trim_suffix("/").split("/")[-1] + "/"
var pack_folder_name_global: String: get = _get_pack_folder_name_global
func _get_pack_folder_name_global() -> String: return global_config_path.get_base_dir() + "/"


@export var version: String
@export var display_name: String
@export var authors: PackedStringArray
@export var blurb: String
@export var readme: String
@export var credits: String
@export var target_icon: String





var data: CondomFile
var icon: Texture2D




func load_global_file(global_file_path: String, include_resources: bool = false) -> void :
	data = VD.get_config_either(global_file_path)
	global_config_path = global_file_path
	unique_name = global_config_path.trim_prefix(FileManager.GAME).get_base_dir()
	if !unique_name.ends_with("/"): unique_name += "/"
	_get_core_data_from_config()
	_get_core_resources_from_config()
	_get_pack_data_from_config()
	if include_resources: _get_pack_resources_from_config()


func _get_core_data_from_config() -> void :
	version = data.get_section_key_as_string(SECTION_DATA, KEY_VERSION, DEFAULT_VERSION)
	display_name = data.get_section_key_as_string(SECTION_DATA, KEY_DISPLAY_NAME, pack_folder_name)
	authors = data.get_section_key_as_packed_string_array(SECTION_DATA, KEY_AUTHORS, DEFAULT_AUTHORS)
	blurb = data.get_section_key_as_string(SECTION_DATA, KEY_BLURB, DEFAULT_BLURB)
	readme = data.get_section_key_as_string(SECTION_DATA, KEY_BLURB, DEFAULT_README)
	credits = data.get_section_key_as_string(SECTION_DATA, KEY_CREDITS, DEFAULT_CREDITS)
	target_icon = data.get_section_key_as_string(SECTION_DATA, KEY_CREDITS, DEFAULT_TARGET_ICON)


func _get_core_resources_from_config() -> void :
	icon = VD.get_texture_either(unique_name + target_icon)




func _get_pack_data_from_config() -> void : pass
func _get_pack_resources_from_config() -> void : pass
