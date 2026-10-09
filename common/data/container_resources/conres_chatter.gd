class_name ConresChatter extends Conres



@export var exact_collection: Dictionary[ConresChatterInstance, PackedStringArray]
@export var broad_collection: Dictionary[ConresChatterInstance, PackedStringArray]
var sounds_exact_cased: Dictionary[String, Array] = {}
var sounds_contain_insen: Dictionary[String, Array] = {}









func load_from_condat(condat: CondatChatter) -> void :
	_load_common_from_condat(condat)
	var files_list_exact: PackedStringArray = condat.get_section_keys(condat.SECTION_EXACT_KEYWORDS)
	for file_name: String in files_list_exact:
		var audio: AudioStream = VD.get_audio_either(condat.global_directory + file_name)
		if !audio: continue
		var new_instance: = ConresChatterInstance.new()
		new_instance.set_values(audio, true, false, condat.volume, file_name)
		var file_keywords: PackedStringArray = condat.get_value_as_string_array(condat.SECTION_EXACT_KEYWORDS, file_name)
		exact_collection[new_instance] = file_keywords
	var files_list_broad: PackedStringArray = condat.get_section_keys(condat.SECTION_BROAD_KEYWORDS)
	for file_name: String in files_list_broad:
		var audio: AudioStream = VD.get_audio_either(condat.global_directory + file_name)
		if !audio: continue
		var new_instance: = ConresChatterInstance.new()
		new_instance.set_values(audio, false, true, condat.volume, file_name)
		var file_keywords: PackedStringArray = condat.get_value_as_string_array(condat.SECTION_BROAD_KEYWORDS, file_name)
		broad_collection[new_instance] = file_keywords
	create_sounds_directory_from_collection()
func create_sounds_directory_from_collection() -> void :
	for chatter: ConresChatterInstance in exact_collection.keys():
		for keyword: String in exact_collection[chatter]:
			if !sounds_exact_cased.has(keyword): sounds_exact_cased[keyword] = []
			sounds_exact_cased[keyword].append(chatter)
	for chatter: ConresChatterInstance in broad_collection.keys():
		for keyword: String in broad_collection[chatter]:
			if !sounds_contain_insen.has(keyword): sounds_contain_insen[keyword] = []
			sounds_contain_insen[keyword].append(chatter)










































func search(arg: String) -> ConresChatterInstance:
	if sounds_exact_cased.has(arg): return sounds_exact_cased[arg].pick_random()
	for key: String in sounds_contain_insen.keys(): if arg.containsn(key): return sounds_contain_insen[key].pick_random()
	return null
