class_name RWECUChatter extends Resource



const SECTION_DATA: String = "data"



const KEY_VOLUME: String = "volume"
const KEY_KEYWORDS: String = "keywords"
const SECTION_EXACT_KEYWORDS: String = "exact_keywords"
const SECTION_BROAD_KEYWORDS: String = "broad_keywords"
const KEY_IS_EXACT: String = "is_exact"




var volume: float
var sounds_exact_cased: Dictionary[String, Array] = {}


var sounds_contain_insen: Dictionary[String, Array] = {}




func load_from_folder_name(folder_name: String) -> void :
	if !folder_name.ends_with("/"): folder_name += "/"
	var config: CondomFile = VD.get_config_agnostic(FileManager.MODPACKS_CHATTER + folder_name + "config_chatter")
	if !config: return
	volume = maxf(config.get_section_key_as_float(SECTION_DATA, KEY_VOLUME), 0.0) if config._config.has_section_key(SECTION_DATA, KEY_VOLUME) else 1.0

	var files_list_exact: PackedStringArray = config._config.get_section_keys(SECTION_EXACT_KEYWORDS)
	for file_name: String in files_list_exact:
		var audio: AudioStream = VD.get_audio_either(FileManager.MODPACKS_CHATTER + folder_name + file_name)
		if !audio: continue
		var new_instance: = RWECUChatterInstance.new()
		new_instance.generate(audio, true, true, volume)
		var file_keywords: PackedStringArray = config.get_section_key_as_packed_string_array(SECTION_EXACT_KEYWORDS, file_name)
		for keyword: String in file_keywords:
			if !sounds_exact_cased.has(keyword): sounds_exact_cased[keyword] = []
			sounds_exact_cased[keyword].append(new_instance)

	var files_list_broad: PackedStringArray = config._config.get_section_keys(SECTION_BROAD_KEYWORDS)
	for file_name: String in files_list_broad:
		var audio: AudioStream = VD.get_audio_either(FileManager.MODPACKS_CHATTER + folder_name + file_name)
		if !audio: continue
		var new_instance: = RWECUChatterInstance.new()
		new_instance.generate(audio, false, false, volume)
		var file_keywords: PackedStringArray = config.get_section_key_as_packed_string_array(SECTION_BROAD_KEYWORDS, file_name)
		for keyword: String in file_keywords:
			if !sounds_contain_insen.has(keyword): sounds_contain_insen[keyword] = []
			sounds_contain_insen[keyword].append(new_instance)

	for section: String in config._config.get_sections():
		if !section.begins_with("%"): continue
		var file_name = section.right(-1)
		var audio: AudioStream = VD.get_audio_either(FileManager.MODPACKS_CHATTER + folder_name + file_name)
		if !audio: continue
		var file_keywords: PackedStringArray = config.get_section_key_as_packed_string_array(section, KEY_KEYWORDS)
		var this_file_exact: bool = config.get_section_key_as_bool(section, KEY_IS_EXACT)
		var this_file_volume: float = maxf(config.get_section_key_as_float(section, KEY_VOLUME), 0.0) if config._config.has_section_key(section, KEY_VOLUME) else 1.0
		var new_instance: = RWECUChatterInstance.new()
		new_instance.generate(audio, this_file_exact, !this_file_exact, this_file_volume)
		if this_file_exact: for keyword: String in file_keywords:
			if !sounds_exact_cased.has(keyword): sounds_exact_cased[keyword] = []
			sounds_exact_cased[keyword].append(new_instance)
		else: for keyword: String in file_keywords:
			if !sounds_contain_insen.has(keyword): sounds_contain_insen[keyword] = []
			sounds_contain_insen[keyword].append(new_instance)













































func search(arg: String) -> RWECUChatterInstance:
	if sounds_exact_cased.has(arg): return sounds_exact_cased[arg].pick_random()


	for key: String in sounds_contain_insen.keys(): if arg.containsn(key): return sounds_contain_insen[key].pick_random()
	return null




class RWECUChatterInstance extends Resource:
	var audio: AudioStream
	var is_case_sensitive: bool
	var is_contains: bool
	var volume: float
	func generate(in_audio: AudioStream, in_is_case_sensitive: bool, in_is_contains: bool, in_volume: float) -> void :
		audio = in_audio
		is_case_sensitive = in_is_case_sensitive
		is_contains = in_is_contains
		volume = in_volume
