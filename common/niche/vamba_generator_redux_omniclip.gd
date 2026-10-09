class_name VambaGeneratorReduxOmniClip extends Resource

func generate_uniform_shuffle(input: OmniClipCollection, size: int) -> Array[OmniClip]:
	var output: Array[OmniClip] = []
	var unseen_percentage: float = float(Profile.unseen_percent) / 100.0
	var total: Array[OmniClip] = [];total.append_array(input.data);total.shuffle()
	var backup_bucket: Array[OmniClip] = []
	while !total.is_empty():
		var checking: OmniClip = total.pop_back()
		if !checking.has_been_seen(): output.append(checking)
		else:
			if randf() <= unseen_percentage: backup_bucket.append(checking)
			else: output.append(checking)
		if output.size() == size: return output
	while !backup_bucket.is_empty() and (output.size() < size): output.append(backup_bucket.pop_back())
	return output
func generate_packweighted_shuffle(input: OmniClipCollection, size: int) -> Array[OmniClip]:
	var output: Array[OmniClip] = []
	var unseen_percentage: float = float(Profile.unseen_percent) / 100.0
	var amount_seen: Array[OmniClip] = input.get_seen_clips();amount_seen.shuffle()
	var amount_unseen: Array[OmniClip] = input.get_unseen_clips();amount_unseen.shuffle()
	var pseudo_seen: Dictionary = _pseudo_file_structure(amount_seen)
	var pseudo_unseen: Dictionary = _pseudo_file_structure(amount_unseen)
	while (output.size() < size) and ( !pseudo_unseen.is_empty() or !pseudo_seen.is_empty()):
		var active_selection: Variant
		if pseudo_unseen.is_empty(): active_selection = pseudo_seen
		elif pseudo_seen.is_empty(): active_selection = pseudo_unseen
		else:
			if randf() <= unseen_percentage:
				active_selection = pseudo_unseen
			else: active_selection = pseudo_seen
		var key: String
		while typeof(active_selection) == TYPE_DICTIONARY:
			key = active_selection.keys().pick_random()
			if active_selection[key].is_empty(): active_selection.erase(key);break
			if active_selection.is_empty(): break
			active_selection = active_selection[key]
		if typeof(active_selection) == TYPE_ARRAY: if !active_selection.is_empty(): output.append(active_selection.pop_front())
	return output
func _pseudo_file_structure(input: Array[OmniClip]) -> Dictionary:
	var output: Dictionary = {}
	for clip: OmniClip in input:
		var file: String = clip.seen_path
		var fldr_packed: PackedStringArray = file.split("/", false)

		var folders: Array = Array(fldr_packed)
		__recursive_pseudo(output, folders, clip)
	return output
func __recursive_pseudo(dict: Dictionary, input: Array, clip: OmniClip) -> void :
	var key: String = input.pop_front()
	if !dict.has(key): dict[key] = {}
	if input.size() > 1:
		__recursive_pseudo(dict[key], input, clip)
	elif input.size() == 1:
		if !dict[key].has("/"): dict[key]["/"] = []
		dict[key]["/"].append(clip)
