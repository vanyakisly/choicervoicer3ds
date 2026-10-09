class_name ConresChatterInstance extends Resource
@export var audio_file_name: String
@export var audio: AudioStream
@export var is_case_sensitive: bool
@export var is_contains: bool
@export var volume: float = 1.0
func set_values(in_audio: AudioStream, in_is_case_sensitive: bool, in_is_contains: bool, in_volume: float, in_audio_file_name: String) -> void :
	audio = in_audio
	is_case_sensitive = in_is_case_sensitive
	is_contains = in_is_contains
	volume = in_volume
	audio_file_name = in_audio_file_name
