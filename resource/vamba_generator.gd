extends Resource
class_name VambaGenerator

var clip_selection_: Dictionary = {
	"rounds": 3, 

	"voice_range": {
		"min": 0, 
		"max": 5.5
	}, 
	"shuffle": true, 
	"start_from": 1, 
	"uniform": true, 

	"unseen_percent": 0.0, 
}














func generate_vamba(batch_available_clips: PackedStringArray, rounds: int, cs: Dictionary) -> PackedStringArray:
	var uc: = UC.new()

	var interim_batch: Array = Array(batch_available_clips.duplicate())
	var sender_batch: PackedStringArray = []
	var min_length: float = clampf(cs.voice_range.min, 0.0, 59.5)
	var max_length: float = clampf(cs.voice_range.max, 0.5, 60.0)

	var length_based_append: Callable = func(batch: Array):
		var audio = uc.get_audio(M.OVEEP.VOICE, batch[0])
		if audio != null:
			var audio_length: float = audio.get_length()
			if (audio_length <= max_length) and (audio_length >= min_length):
				sender_batch.append(batch[0])
		batch.remove_at(0)
	var basic_batch_loop: Callable = func(batch: Array) -> Array:
		while not batch.is_empty():
			if sender_batch.size() == rounds:
				uc.queue_free()
				return sender_batch
			else:
				length_based_append.call(batch)

		uc.queue_free()
		return sender_batch


	if cs.shuffle:
		var start_from: int = int(cs.start_from) - 1
		start_from %= interim_batch.size()
		print(start_from)
		interim_batch.append_array(interim_batch)
		interim_batch = interim_batch.slice(start_from, start_from + rounds)
		return basic_batch_loop.call(interim_batch)
	else:

		var player_seen: Array = M.data.player.clips.seen
		var seen_bucket: Array = []
		var unseen_bucket: Array = []
		var unseen_percent: float = clampf(cs.unseen_percent, 0.0, 100.0) / 100.0

		randomize()
		interim_batch.shuffle()
		for p in interim_batch:
			if player_seen.has(p):
				seen_bucket.append(p)
			else:
				unseen_bucket.append(p)
		while sender_batch.size() < rounds:
			if unseen_bucket.is_empty():
				return basic_batch_loop.call(seen_bucket)
			else:
				if seen_bucket.is_empty():
					return basic_batch_loop.call(unseen_bucket)
				else:
					if randf() <= unseen_percent:
						length_based_append.call(unseen_bucket)
					else:

						var ratio_unseen_to_seen: float = float(unseen_bucket.size()) / float(unseen_bucket.size() + seen_bucket.size())


						if randf() <= ratio_unseen_to_seen:
							length_based_append.call(unseen_bucket)
						else:
							length_based_append.call(seen_bucket)
		uc.queue_free()
		return sender_batch



func generate_vamba_pack_weighted(rounds: int, start_from: String = "") -> PackedStringArray:
	var output: PackedStringArray
	var uc: = UC.new()
	if M.data.settings.clip_selection.unseen_percent > 0:
		var packs: Dictionary = _recursive_packs(start_from, [], false)
		while !packs.is_empty() and output.size() < rounds:
			var pick: String = recursive_pick_and_analyze(packs, uc)
			if !pick.is_empty(): output.append(pick)

	if output.size() < rounds:
		var packs: Dictionary = _recursive_packs(start_from, Array(output), true)
		while !packs.is_empty() and output.size() < rounds:
			var pick: String = recursive_pick_and_analyze(packs, uc)
			if !pick.is_empty(): output.append(pick)
	uc.queue_free()
	return output


func get_agnositc_files(pack_chain: String, already_collected: Array = [], allow_seen: bool = true) -> Array:
	var output: Array
	for file: String in DirAccess.get_files_at("user://game/packs_voice/" + pack_chain):
		var agnostic_file: String = file.get_basename()
		if already_collected.has(pack_chain + agnostic_file): continue
		if agnostic_file.begins_with("_ignore"): continue
		if ["_author", "_pack_filler_image", "_subtitle"].has(agnostic_file): continue
		agnostic_file = pack_chain + agnostic_file
		if !allow_seen: if M.data.player.clips.seen.has(agnostic_file): continue
		if not output.has(agnostic_file): output.append(agnostic_file)
	return output


func _recursive_packs(pack_chain: String, already_collected: Array = [], allow_seen: bool = true) -> Dictionary:
	var output: Dictionary = {}
	var own_agnostic_files: Array = get_agnositc_files(pack_chain, already_collected, allow_seen)
	if not own_agnostic_files.is_empty(): output[""] = own_agnostic_files
	for pack_name: String in DirAccess.get_directories_at("user://game/packs_voice/" + pack_chain):
		if pack_name.begins_with("_ignore"): continue
		pack_name += "/"
		var dict: Dictionary = _recursive_packs(pack_chain + pack_name)
		if not dict.is_empty(): output[pack_chain + pack_name] = dict
	return output


func recursive_pick_and_analyze(parent: Dictionary, uc: UC) -> String:
	while not parent.is_empty():
		var key: String = parent.keys().pick_random()
		if typeof(parent[key]) == TYPE_DICTIONARY:
			if parent[key].is_empty():
				parent.erase(key)
				continue
			return recursive_pick_and_analyze(parent[key], uc)
		elif typeof(parent[key]) == TYPE_ARRAY:
			var this_array: Array = parent[key]
			if this_array.is_empty():
				parent.erase(key)
				continue
			var pick_file: String = this_array.pick_random()
			var audio: AudioStream = uc.get_audio(M.OVEEP.VOICE, pick_file)
			this_array.erase(pick_file)
			if not (
				(audio == null) or 
				(audio.get_length() > M.data.settings.clip_selection.voice_range.max) or 
				(audio.get_length() < M.data.settings.clip_selection.voice_range.min)
			):
				return pick_file
	return ""
