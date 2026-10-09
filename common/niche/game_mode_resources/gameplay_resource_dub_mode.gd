class_name GameplayResourceDubMode extends Resource
const PRINTSTR: String = "GameResourceDubMode | "
@export var pack_info: PackInfo
@export var omni_clip_array: OmniClipCollection
@export var video: VideoStream
@export var backing_track: AudioStream
@export var freestyle_dub: AudioStream

var failed_to_load: bool = false
var no_video_file: bool = false

func _generate_from_path(global_folder_path: String) -> void :
	if !global_folder_path.ends_with("/"): global_folder_path += "/"
	if !DirAccess.dir_exists_absolute(global_folder_path): printerr(PRINTSTR + "Folder path `%s` does not exist." % global_folder_path);failed_to_load = true;return
	pack_info = PackInfo.new(M.CLIP_USES.DUB)
	pack_info.generate_from_target_pack_folder(global_folder_path)
	video = VD.get_video(global_folder_path + "dub_video.ogv")
	backing_track = VD.get_audio_agnositc(global_folder_path + "_backing_track")
	omni_clip_array = OmniClipCollection.new()
	omni_clip_array.generate_from_pack_info(pack_info, false)
	if !video: no_video_file = true
func graft_dub_recording(target_path: String) -> void :
	if !target_path.ends_with("/"): target_path += "/"
	for clip: OmniClip in omni_clip_array.data:
		var existence_check: AudioStream = VD.get_audio_agnositc(target_path + "_dubrecord_" + clip.file_name_agnostic)
		if existence_check: clip.clip_audio = existence_check
	freestyle_dub = VD.get_audio_agnositc(target_path + "_dubrecord_freestyle")

func get_temp_preserve_path() -> String: return FileManager.TEMP_DUBMODE + pack_info.folder_name
func has_incomplete_session() -> bool:
	var dub_mode_preserved_sessions: PackedStringArray = DirAccess.get_directories_at(FileManager.TEMP_DUBMODE)
	return dub_mode_preserved_sessions.has(pack_info.folder_name.left(-1))
func clear_incomplete_session() -> void :
	if has_incomplete_session():
		var temp_path: String = get_temp_preserve_path()
		for file: String in DirAccess.get_files_at(temp_path): DirAccess.remove_absolute(temp_path + file)
		print(error_string(DirAccess.remove_absolute(temp_path)))











func _init(global_folder_path: String = "") -> void :
	if !global_folder_path: print(PRINTSTR + "No path specified, assuming premade resource.");return
	_generate_from_path(global_folder_path)
