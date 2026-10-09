class_name CondatChatter extends Condat









const KEY_VOLUME: String = "volume"
const KEY_KEYWORDS: String = "keywords"
const SECTION_EXACT_KEYWORDS: String = "exact_keywords"
const SECTION_BROAD_KEYWORDS: String = "broad_keywords"
const KEY_IS_EXACT: String = "is_exact"


@export_range(0.0, 1.0, 0.01, "or_greater") var volume: float = 1.0




func edit_exact(file_name: String, keywords: PackedStringArray) -> void : set_value(SECTION_EXACT_KEYWORDS, file_name, keywords)
func edit_broad(file_name: String, keywords: PackedStringArray) -> void : set_value(SECTION_BROAD_KEYWORDS, file_name, keywords)
func edit_volume(value: float) -> void : set_value(SECTION_DATA, KEY_VOLUME, maxf(0.0, value))


func _load_local_variables() -> void :
	volume = maxf(0.0, get_value_as_float(SECTION_DATA, KEY_VOLUME, 1.0))
func load_from_file_agnostic(global_path_agnostic_: String) -> Error:
	var error: Error = _load_config_file(global_path_agnostic_)
	if error != OK: return FAILED
	_load_local_variables()
	return OK
