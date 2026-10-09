class_name CondomFile extends Resource

const PRINTSTR: String = "CondomFile | "

var unix_last_modified: int
var _config: = ConfigFile.new()


func load(path: String) -> void :
	var file: = FileAccess.open(path, FileAccess.READ)
	var output: = ConfigFile.new()
	if !file: printerr(PRINTSTR + "Failed to load target file at `%s`" % path);return
	var lines: PackedStringArray = []
	while !file.eof_reached(): lines.append(file.get_line())
	var section: String = ""
	for line: String in lines:
		line = line.strip_edges()
		if !line.begins_with("[") and !section: continue
		if line.begins_with("#") or line.begins_with(";") or line.is_empty(): continue
		if line.begins_with("[") and line.ends_with("]"):
			section = line.left(-1).right(-1)
			section = section.strip_edges()
			continue

		var delimiter: String = "="
		var delimiter_position: int = line.find(delimiter)
		if delimiter_position == -1: delimiter = ":";delimiter_position = line.find(delimiter)
		if delimiter_position == -1: continue
		var split_line: PackedStringArray = line.split(delimiter, false, 1)
		if split_line.size() < 2: continue
		var key = split_line[0]
		var value = split_line[1]
		key = key.strip_edges()
		value = value.strip_edges()
		if !output.has_section_key(section, key): output.set_value(section, key, value)
	unix_last_modified = FileAccess.get_modified_time(path)
	_config = output


func get_section_key_as(section: String, key: String, type: Variant.Type, default: Variant = null) -> Variant:
	if !_config.has_section_key(section, key): return default
	var string_value: String = _config.get_value(section, key, "")
	match type:
		TYPE_STRING:
			if (string_value.begins_with("'") and string_value.ends_with("'")) or (string_value.begins_with("\"") and string_value.ends_with("\"")): string_value = string_value.left(-1).right(-1)
			return string_value.c_unescape()
		TYPE_BOOL: return _string_to_bool(string_value)
		TYPE_FLOAT: return float(string_value)
		TYPE_INT: return int(string_value)
		TYPE_PACKED_STRING_ARRAY: return _conventional_string_to_packed_string_array(string_value)
		TYPE_PACKED_FLOAT32_ARRAY: return _string_to_float_array(string_value)
		TYPE_PACKED_INT32_ARRAY: return _string_to_int_array(string_value)
		TYPE_COLOR: return Color.html(string_value.replace("'", "").replace("\"", ""))
		_: printerr(PRINTSTR + "Type parameter has no parse match.")
	return ""
func get_section_key_as_string(section: String, key: String, default: String = "") -> String: return get_section_key_as(section, key, TYPE_STRING, default)
func get_section_key_as_bool(section: String, key: String, default: bool = false) -> bool: return get_section_key_as(section, key, TYPE_BOOL, default)
func get_section_key_as_float(section: String, key: String, default: float = 0.0) -> float: return get_section_key_as(section, key, TYPE_FLOAT, default)
func get_section_key_as_int(section: String, key: String, default: int = 0) -> int: return get_section_key_as(section, key, TYPE_INT, default)
func get_section_key_as_packed_string_array(section: String, key: String, default: PackedStringArray = []) -> PackedStringArray: return get_section_key_as(section, key, TYPE_PACKED_STRING_ARRAY, default)
func get_section_key_as_packed_float_array(section: String, key: String, default: PackedFloat32Array = []) -> PackedFloat32Array: return get_section_key_as(section, key, TYPE_PACKED_FLOAT32_ARRAY, default)
func get_section_key_as_packed_int_array(section: String, key: String, default: PackedInt32Array = []) -> PackedInt32Array: return get_section_key_as(section, key, TYPE_PACKED_INT32_ARRAY, default)
func get_section_key_as_color(section: String, key: String, default: = Color.BLACK, include_alpha: bool = false) -> Color: return get_section_key_as(section, key, TYPE_COLOR, default) if include_alpha else Color(get_section_key_as(section, key, TYPE_COLOR), 1.0)


func _string_to_bool(input: String) -> bool:
	input = input.strip_edges()
	return (input.to_lower() == "true")


func _string_to_packed_string_array(input: String) -> PackedStringArray:
	const SINGLE_QUOTE: String = "'";const DOUBLE_QUOTE: String = "\""
	var working_string: String = __array_strip(input)
	var output: PackedStringArray = []
	while !working_string.is_empty():
		var next_single: int = working_string.find(SINGLE_QUOTE)
		var next_double: int = working_string.find(DOUBLE_QUOTE)
		if (next_single == -1) and (next_double == -1): break
		if next_single == -1: next_single = 65535
		if next_double == -1: next_double = 65535
		if next_single < next_double:
			working_string = working_string.right( - (next_single + 1))
			next_single = working_string.find(SINGLE_QUOTE)
			if next_single == -1: break
			else: output.append(working_string.substr(0, next_single))
			working_string = working_string.right( - (next_single + 1))
		else:
			working_string = working_string.right( - (next_double + 1))
			next_double = working_string.find(DOUBLE_QUOTE)
			if next_double == -1: break
			else: output.append(working_string.substr(0, next_double))
			working_string = working_string.right( - (next_double + 1))
	return output


func _conventional_string_to_packed_string_array(input: String) -> PackedStringArray:
	var output: PackedStringArray = []
	var work: String = input.strip_edges()
	if work.begins_with("[") and work.ends_with("]"): work.left(-1).right(-1);work.strip_edges()
	var active_word: String = ""
	while !work.is_empty():
		if !work.begins_with("\""): work = work.right(-1)
		else:
			work = work.right(-1)
			active_word = ""
			for character: String in work:
				match work.left(1):
					"\\":
						if work.begins_with("\\\""): active_word += "\\\"";work = work.right(-1)
						else:
							active_word += "\\"
					"\"": output.append(active_word.c_unescape());work = work.right(-1);break
					_: active_word += work.left(1)
				work = work.right(-1)
	return output


func _string_to_float_array(input: String) -> PackedFloat32Array:
	var string_array: PackedStringArray = __array_strip(input).split(",", false)
	var output: PackedFloat32Array = []
	output.resize(string_array.size())
	for index: int in string_array.size(): output[index] = float(string_array[index])
	return output


func _string_to_int_array(input: String) -> PackedInt32Array:
	var string_array: PackedStringArray = __array_strip(input).split(",")
	var output: PackedInt32Array = []
	output.resize(string_array.size())
	for index: int in string_array.size(): output[index] = int(string_array[index])
	return output


func __array_strip(input: String) -> String:
	input = input.strip_edges()
	if input.begins_with("["): input = input.right(-1)
	if input.ends_with("]"): input = input.left(-1)
	return input.strip_edges()
