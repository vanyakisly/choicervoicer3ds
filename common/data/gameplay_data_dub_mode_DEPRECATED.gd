class_name GameplayDataDubMode extends Resource

const PRINTSTR: String = "GameplayDataDubMode | "

@export var pack_info: PackData
@export var omni_clip_array: OmniClipCollection
@export var video: VideoStream
@export var backing_track: AudioStream



var failed_to_load: bool = false
var no_video_file: bool = false


func _init(global_folder_path: String = "") -> void :
	if !global_folder_path: print(PRINTSTR + "No path specified, assuming premade resource.");return
	_generate_from_path(global_folder_path)


func _generate_from_path(global_folder_path: String) -> void :
	if !DirAccess.dir_exists_absolute(global_folder_path): printerr(PRINTSTR + "Folder path `%s` does not exist." % global_folder_path);failed_to_load = true;return
	if !global_folder_path.ends_with("/"): global_folder_path += "/"
	pack_info = PackData.new(global_folder_path)
	video = VD.get_video(global_folder_path + "dub_video.ogv")
	backing_track = VD.get_any_audio_from(DirAccess.get_files_at(global_folder_path), "_backing_track")
	omni_clip_array = OmniClipCollection.new();omni_clip_array.generate_collection_from_folder(global_folder_path)
	if !video: no_video_file = true
