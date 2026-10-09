class_name PackWeightedSelector extends Resource



signal clip_validated(clip: OmniClip)
signal clip_error(clip: OmniClip)
signal finished


var error_reports: PackedStringArray
var validated_clips: Array[OmniClip]
var size: int:
	get: return validated_clips.size()
var coroutine_key: int




func _construct_string_dictionary_from_tree(input: VoicePackTree) -> Dictionary[String, Variant]:
	var output: Dictionary[String, Variant] = {}
	for top_level_folder: VoicePackTreeItem in input.section_custom.get_children():
		if coroutine_key != Metro.coroutine_password_pack_weighted_selector: break
		var folder_output: Dictionary[String, Variant] = _nesting_from_tree_item(top_level_folder)
		if !folder_output.is_empty(): output[top_level_folder.pack_info.folder_name] = folder_output
	return output
func _nesting_from_tree_item(input: VoicePackTreeItem) -> Dictionary[String, Variant]:
	var output: Dictionary[String, Variant] = {}
	for child: VoicePackTreeItem in input.get_children():
		if coroutine_key != Metro.coroutine_password_pack_weighted_selector: break
		var child_output: Dictionary = _nesting_from_tree_item(child)
		if !child_output.is_empty(): output[child.pack_info.folder_name] = child_output
	if input.pack_info.audio_files_unnested: output[""] = Array(input.pack_info.audio_files_unnested)
	return output
func process_from_tree(input: VoicePackTree) -> void :
	if !input.has_finished_loading: await input.loading_finished
	var construction: Dictionary[String, Variant] = _construct_string_dictionary_from_tree(input)
	var active_variant: Variant
	var parent_of_active: Dictionary
	var active_key: String
	var var_type: int
	var seen_backup: Array[String]






	parent_of_active = construction
	active_key = parent_of_active.keys().pick_random()
	active_variant = parent_of_active[active_key]
	var_type = typeof(active_variant)
	while !construction.is_empty() and size < ClipSelectionBook.GAME_SHOW_ROUND_LIMIT:
		if coroutine_key != Metro.coroutine_password_pack_weighted_selector: return
		match var_type:
			TYPE_DICTIONARY:
				if active_variant.is_empty():
					parent_of_active.erase(active_key)

					if construction.is_empty(): continue
					parent_of_active = construction;active_key = parent_of_active.keys().pick_random();active_variant = parent_of_active[active_key];var_type = typeof(active_variant)
					continue
				parent_of_active = active_variant
				active_key = active_variant.keys().pick_random()
				active_variant = parent_of_active[active_key]
				var_type = typeof(active_variant)
			TYPE_ARRAY:
				if active_variant.is_empty():
					parent_of_active.erase(active_key)

					parent_of_active = construction;active_key = parent_of_active.keys().pick_random();active_variant = parent_of_active[active_key];var_type = typeof(active_variant)
					continue
				var path_to_test: String = active_variant.pop_at(randi_range(0, active_variant.size() - 1))
				var seen_path: String = path_to_test.trim_prefix(FileManager.MODPACKS_VOICE)
				if Profile.seen_clips_voice.has(seen_path) and randf() <= Profile.unseen_percent:
					if seen_backup.size() < ClipSelectionBook.GAME_SHOW_ROUND_LIMIT: seen_backup.append(path_to_test)
					continue
				var clip: = OmniClip.new()
				clip.generate_from_audio_file_exact(path_to_test)
				if clip.dub_only: continue
				if !clip.error_flags:
					if !clip.is_within_length_filter_range(): continue
					validated_clips.append(clip)
					clip_validated.emit(clip)

					parent_of_active = construction;active_key = parent_of_active.keys().pick_random();active_variant = parent_of_active[active_key];var_type = typeof(active_variant)
					continue
				else: error_reports.append(clip.error_report);clip_error.emit(clip)
			_:
				parent_of_active.erase(active_key)

				parent_of_active = construction;active_key = parent_of_active.keys().pick_random();active_variant = parent_of_active[active_key];var_type = typeof(active_variant)
				continue
	seen_backup.reverse()
	while size < ClipSelectionBook.GAME_SHOW_ROUND_LIMIT and seen_backup:
		if coroutine_key != Metro.coroutine_password_pack_weighted_selector: return
		var path: String = seen_backup.pop_back(); if !path: continue
		var clip: = OmniClip.new()
		clip.generate_from_audio_file_exact(path)
		if clip.error_flags or !clip.is_within_length_filter_range(): continue
		validated_clips.append(clip)
		clip_validated.emit(clip)
	if Engine.is_editor_hint():
		var list: PackedStringArray = []
		for el: OmniClip in validated_clips: list.append(el.file_name_agnostic)
		print("Selector | List: %s" % list)
	finished.emit()
