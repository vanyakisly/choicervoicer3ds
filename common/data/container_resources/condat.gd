class_name Condat extends Resource




signal resource_paths_changed


const SECTION_DATA: String = "data"
const KEY_TITLE: String = "title"
const KEY_ICON_PATH: String = "icon"
const KEY_AUTHORS: String = "authors"
const KEY_README: String = "readme"


@export var folder_name: String
@export var display_name: String
@export var icon_file_name: String:
	set(value): icon_file_name = value;resource_paths_changed.emit()
@export var authors: PackedStringArray
@export var readme: String
@export var unix_last_modified: int
@export var global_path_agnostic: String


var global_directory: String:
	get: return global_path_agnostic.get_base_dir() + "/"
var containing_folder: String:
	get: return global_directory.get_base_dir().get_file()


var _config: ConfigFile




func _load_config_file(global_path_agnostic_: String) -> Error:
	global_path_agnostic = global_path_agnostic_
	var condom: CondomFile = VD.get_config_agnostic(global_path_agnostic)
	if !condom: _config = null;return FAILED
	_config = condom._config
	unix_last_modified = condom.unix_last_modified
	_load_values_from_config()
	return OK
func _load_values_from_config() -> void :
	if !_config: return
	folder_name = containing_folder
	display_name = get_value(SECTION_DATA, KEY_TITLE, folder_name)
	icon_file_name = get_value(SECTION_DATA, KEY_ICON_PATH, "icon")
	authors = get_value(SECTION_DATA, KEY_AUTHORS, [])
	readme = get_value(SECTION_DATA, KEY_README, "")


func get_sections() -> PackedStringArray: return _config.get_sections()
func get_section_keys(section: String) -> PackedStringArray: return _config.get_section_keys(section) if _config.has_section(section) else []
func get_value(section: String, key: String, default: Variant = null) -> Variant: return _config.get_value(section, key, default)
func has_section_key(section: String, key: String) -> bool: return _config.has_section_key(section, key)
func set_value(section: String, key: String, value: Variant) -> void : _config.set_value(section, key, value)


func get_value_as_string(section: String, key: String, default: String = "") -> String:
	var value_as_string: String = str(_config.get_value(section, key, ""))
	if !value_as_string: return default
	return value_as_string
func get_value_as_bool(section: String, key: String, default: bool = false) -> bool:
	var value_as_string: String = str(_config.get_value(section, key, ""))
	if !value_as_string: return default
	return ["1", "true", "yes", "t", "y"].has(value_as_string.to_lower())
func get_value_as_int(section: String, key: String, default: int = 0) -> int:
	var value_as_string: String = str(_config.get_value(section, key, ""))
	if !value_as_string: return default
	return value_as_string.to_int()
func get_value_as_float(section: String, key: String, default = 0.0) -> float:
	var value_as_string: String = str(_config.get_value(section, key, ""))
	if !value_as_string: return default
	return value_as_string.to_float()
func get_value_as_string_array(section: String, key: String, default = []) -> PackedStringArray:
	var value_as_string: String = str(_config.get_value(section, key, ""))
	if !value_as_string: return default
	var output: PackedStringArray = []
	var work: String = _array_strip(value_as_string)
	while !work.is_empty():
		if !work.begins_with("\""): work = work.right(-1)
		else:
			work = work.right(-1)
			var active_word: String = ""
			for character: String in work:
				match work.left(1):
					"\"":
						output.append(active_word.c_unescape())
						work = work.right(-1)
						break
					"\\":
						if work.begins_with("\\\""):
							active_word += "\\\""
							work = work.right(-1)
						else:
							active_word += "\\"
					_: active_word += work.left(1)
				work = work.right(-1)
	return output
func get_value_as_float_array(section: String, key: String, default = []) -> PackedFloat32Array:
	var value_as_string: String = str(_config.get_value(section, key, ""))
	if !value_as_string: return default
	var array_as_string: PackedStringArray = _array_strip(value_as_string).split(",", false)
	var output: PackedFloat32Array = []
	output.resize(array_as_string.size())
	for index: int in array_as_string.size(): output[index] = float(array_as_string[index])
	return output
func get_value_as_int_array(section: String, key: String, default = []) -> PackedInt32Array:
	var value_as_string: String = str(_config.get_value(section, key, ""))
	if !value_as_string: return default
	var array_as_string: PackedStringArray = _array_strip(value_as_string).split(",", false)
	var output: PackedInt32Array = []
	output.resize(array_as_string.size())
	for index: int in array_as_string.size(): output[index] = int(array_as_string[index])
	return output
func _array_strip(input: String) -> String:
	input = input.strip_edges()
	if input.begins_with("["): input = input.right(-1)
	if input.ends_with("]"): input = input.left(-1)
	return input.strip_edges()
