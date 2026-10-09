class_name SanctuaryAudioPool extends Resource





const MAXIMUM_ALLOWED_LENGTH: float = 10.0




var audio_list_seen: PackedStringArray
var audio_list_recordings: PackedStringArray


var audio_index_seen: int = 0
var audio_index_recordings: int = 0




func seek_audio_seen() -> AudioStream:
	if audio_index_seen % audio_list_seen.size() == 0: _shuffle_seen()
	var playable_audio: AudioStream = null
	while !playable_audio:
		playable_audio = VD.get_audio_either(FileManager.MODPACKS_VOICE + audio_list_seen[wrapi(audio_index_seen, 0, audio_list_seen.size())])
		if !playable_audio or playable_audio.get_length() > MAXIMUM_ALLOWED_LENGTH:
			audio_list_seen.remove_at(audio_index_seen)
			if !audio_list_seen: return playable_audio
		else: audio_index_seen += 1
	return playable_audio
func seek_audio_recording() -> AudioStream:
	if audio_index_recordings % audio_list_recordings.size() == 0: _shuffle_recordings()
	var playable_audio: AudioStream = null
	while !playable_audio:
		playable_audio = VD.get_audio_either(FileManager.RECORDINGS + audio_list_recordings[wrapi(audio_index_recordings, 0, audio_list_recordings.size())])
		if !playable_audio or playable_audio.get_length() > MAXIMUM_ALLOWED_LENGTH:
			audio_list_recordings.remove_at(audio_index_recordings)
			playable_audio = null
			if !audio_list_recordings: return playable_audio
		else: audio_index_recordings += 1
	return playable_audio


func _shuffle_seen() -> void :
	var _temp: = Array(audio_list_seen)
	_temp.shuffle()
	audio_list_seen = PackedStringArray(_temp)
func _shuffle_recordings() -> void :
	var _temp: = Array(audio_list_recordings)
	_temp.shuffle()
	audio_list_recordings = PackedStringArray(_temp)


func generate_pool() -> void :
	audio_list_seen = Profile.seen_clips_voice.duplicate()
	audio_list_recordings = _nested_dub_recordings_retrieval("")
func _nested_dub_recordings_retrieval(recordings_local_path: String) -> PackedStringArray:
	var output: PackedStringArray
	var global_path: String = FileManager.RECORDINGS + recordings_local_path
	if recordings_local_path and !recordings_local_path.ends_with("/"): recordings_local_path += "/"
	var files: PackedStringArray = DirAccess.get_files_at(global_path)
	for i: int in files.size(): files[i] = recordings_local_path + files[i]
	output.append_array(files)
	for folder: String in DirAccess.get_directories_at(global_path): output.append_array(_nested_dub_recordings_retrieval(recordings_local_path + folder))
	return output
