class_name OmniClipCollection extends Resource

const PRINTSTR: String = "OmniClipCollection | "


var load_error_dne_count: int = 0
var load_error_fail_count: int = 0
var load_error_length_count: int = 0
var error_reports: PackedStringArray = []
var coroutine_key: int

@export var data: Array[OmniClip]

func size() -> int: return data.size()
func resize(size: int) -> void : data.resize(size)
func clear() -> void : data.clear()
func append(value: OmniClip) -> void : data.append(value)
func append_array(value: Array[OmniClip]) -> void : data.append_array(value)
func fill(value: OmniClip) -> void : data.fill(value)
func get_index(index: int) -> OmniClip: return data[index]


func generate_from_pack_info(info: PackInfo, include_folder_auto_tags: bool = true, solo: bool = true) -> void :
	if solo: coroutine_key = Time.get_ticks_usec();Metro.coroutine_password_omniclip_collection = coroutine_key
	var list: PackedStringArray = info.audio_files
	for global_file: String in list:
		if solo and coroutine_key != Metro.coroutine_password_omniclip_collection: return
		var clip: = OmniClip.new(info.pack_use)
		clip.generate_from_audio_file_exact(global_file, include_folder_auto_tags, info.path_from_pack)
		if clip.error_flags:
			load_error_dne_count += (clip.error_flags & OmniClip.ERROR_FLAG_DNE)
			load_error_fail_count += (clip.error_flags & OmniClip.ERROR_FLAG_LOAD_FAIL)
			load_error_length_count += (clip.error_flags & OmniClip.ERROR_FLAG_LENGTH)
			error_reports.append(clip.error_report)
			continue
		if clip.dub_only and info.pack_use != M.CLIP_USES.DUB: continue
		if (info.pack_use == M.CLIP_USES.DUB) and (clip.dub_timestamps.is_empty()): continue
		data.append(clip)


func filter_length(minimum: float = 0.0, maximum: float = 60.0) -> Array[OmniClip]:
	var output: Array[OmniClip] = []
	for clip: OmniClip in data:
		var length: float = clip.get_length()
		if (length >= minimum) and (length <= maximum): output.append(clip)
	return output


func get_tags() -> PackedStringArray:
	var output: PackedStringArray = []
	for clip: OmniClip in data: for tag: String in clip.tags: if !output.has(tag): output.append(tag)
	return output


func get_clips_with_tags(tags: PackedStringArray) -> OmniClipCollection:
	var output: = OmniClipCollection.new()
	for clip: OmniClip in data:
		for tag: String in tags:
			if clip.tags.has(tag): output.append(clip);break
	return output


func get_clips_filtered_for_length(min_length: float, max_length: float) -> OmniClipCollection:
	var output: = OmniClipCollection.new()
	min_length = clampf(min_length, 0.0, 59.5)
	max_length = clampf(max_length, maxf(min_length, 0.5), 60.0)
	for clip: OmniClip in data:
		var length: float = clip.get_length()
		if (length >= min_length) and (length <= max_length): output.append(clip)
	return output


func add_tag_to_clips(tag: String) -> void :
	for clip: OmniClip in data: if !clip.tags.has(tag): clip.tags.append(tag)


func add_tags_to_clips(tags: PackedStringArray) -> void :
	for tag: String in tags:
		for clip: OmniClip in data:
			if !clip.tags.has(tag): clip.tags.append(tag)


func get_total_clip_time() -> float:
	var output: float = 0.0
	for clip: OmniClip in data: output += clip.get_length()
	return output


func agnostic_library(global_folder_path: String) -> Dictionary:
	var output: Dictionary = {}
	var dir: = DirAccess.open(global_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while !file_name.is_empty():
			if dir.current_is_dir(): file_name = dir.get_next();continue
			var file_agnostic: String = file_name.get_basename()
			if !output.has(file_agnostic): output[file_agnostic] = PackedStringArray([])
			output[file_agnostic].append(file_name)
			file_name = dir.get_next()
	return output


func get_seen_clips() -> Array[OmniClip]:
	var output: Array[OmniClip]
	for clip: OmniClip in data: if clip.has_been_seen(): output.append(clip)
	return output


func get_unseen_clips() -> Array[OmniClip]:
	var output: Array[OmniClip]
	for clip: OmniClip in data: if !clip.has_been_seen(): output.append(clip)
	return output


func _coroutine_key_invalid() -> bool: return coroutine_key != Metro.coroutine_password_omniclip_collection


func get_dub_characters() -> PackedStringArray:
	var output: PackedStringArray = []
	for clip: OmniClip in data:
		for character: String in clip.dub_characters:
			if !output.has(character): output.append(character)
	return output


func get_clips_from_characters(characters: PackedStringArray) -> Array[OmniClip]:
	var output: Array[OmniClip] = []
	for clip: OmniClip in data:
		for character: String in clip.dub_characters:
			if characters.has(character):
				output.append(clip)
				break
	return output


func get_clips_with_dub_timestamps() -> Array[OmniClip]:
	var output: Array[OmniClip] = []
	for clip: OmniClip in data:
		if clip.dub_timestamps: output.append(clip)
	return output
