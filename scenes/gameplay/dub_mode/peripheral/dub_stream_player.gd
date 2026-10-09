class_name DubStreamPlayer extends VideoStreamPlayer




var audio_streams_container: = Node.new()
var audio_stream_backing: = AudioStreamPlayer.new()
var audio_stream_freestyle: = AudioStreamPlayer.new()
var is_freestyle: bool

func _init() -> void :
	add_child(audio_streams_container)
	add_child(audio_stream_backing)
	add_child(audio_stream_freestyle)
	expand = true


func _reset() -> void :
	stop()
	Profile.changed_dub_mode_options.connect(_check_backing_track_muting)
	for child: AudioStreamPlayer in audio_streams_container.get_children(): child.queue_free()
	audio_stream_freestyle.stream = null
	audio_stream_backing.stream = null
	stream = null


func load_dub(global_folder_path_to_recording: String) -> void :
	_reset()
	if global_folder_path_to_recording.ends_with("/"): global_folder_path_to_recording = global_folder_path_to_recording.left(-1)

	var global_folder_path: String = "/packs_voice/".join(global_folder_path_to_recording.split("/recordings/dub_recordings/", false, 1)).get_base_dir() + "/"
	var resource: = GameplayResourceDubMode.new(global_folder_path)
	if resource.failed_to_load or resource.no_video_file: return
	resource.graft_dub_recording(global_folder_path_to_recording)
	if resource.freestyle_dub:
		is_freestyle = true
		audio_stream_freestyle.stream = resource.freestyle_dub
		audio_stream_freestyle.bus = "Pecho"
	else:
		is_freestyle = false
		for clip: OmniClip in resource.omni_clip_array.data:
			for timestamp: float in clip.dub_timestamps:
				var audio_player: = DubAudioDelayedStreamPlayer.new(clip.clip_audio, timestamp)
				audio_player.bus = "Pecho"
				audio_streams_container.add_child(audio_player)
	audio_stream_backing.bus = "Pecho"
	bus = "Mute"
	stream = resource.video
	audio_stream_backing.stream = resource.backing_track


func play_dub() -> void :
	stop_dub()
	play()
	_play_collection() if !is_freestyle else _play_freestyle()


func _play_collection() -> void :
	if audio_stream_backing.stream and !Profile.dub_mode_mute_backing_track: audio_stream_backing.play()
	for child: DubAudioDelayedStreamPlayer in audio_streams_container.get_children(): child.play_delayed()


func _play_freestyle() -> void :
	audio_stream_freestyle.play()
	if audio_stream_backing.stream and !Profile.dub_mode_mute_backing_track: audio_stream_backing.play()
	play()


func stop_dub() -> void :
	stop()
	audio_stream_backing.stop()
	audio_stream_freestyle.stop()
	for child: DubAudioDelayedStreamPlayer in audio_streams_container.get_children(): child.stop_delayed()


func _check_backing_track_muting() -> void : audio_stream_backing.volume_linear = 0.0 if Profile.dub_mode_mute_backing_track else 1.0
