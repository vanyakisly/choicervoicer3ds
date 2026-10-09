class_name StimChunk extends Node







signal finished


enum StimType{
	NONE, 
	RAPID_SCURRY, 
	FULL_GET_HIGHER, 
	BACK_AND_FORTH_FASTER, 
	STUTTER, 
	DEEPFRY, 
	INCREASE_LOOP, 
}


const BUS: String = "StimCell"




@export var type: StimType: set = _set_type
var stream_player_1: AudioStreamPlayer
var stream_player_2: AudioStreamPlayer
var stream_player_3: AudioStreamPlayer


var clip1: AudioStreamPlayer: get = get_clip1
func get_clip1() -> AudioStreamPlayer: return stream_player_1
var clip2: AudioStreamPlayer: get = get_clip2
func get_clip2() -> AudioStreamPlayer: return stream_player_2




func _set_type(value: StimType) -> void :
	type = value
	for child: Node in get_children(): child.queue_free()
func feed(value: Array[AudioStream]) -> void :
	if stream_player_1: stream_player_1.stream = value[0]
	if stream_player_2: stream_player_2.stream = value[1]
	if stream_player_3: stream_player_3.stream = value[2]
func generate_from_type(from_type: StimType, value: Array[AudioStream]) -> void :
	type = from_type
	match from_type:
		StimType.BACK_AND_FORTH_FASTER:
			stream_player_1 = AudioStreamPlayer.new();add_child(stream_player_1);stream_player_1.bus = BUS
			stream_player_2 = AudioStreamPlayer.new();add_child(stream_player_2);stream_player_2.bus = BUS
		StimType.DEEPFRY:
			stream_player_1 = AudioStreamPlayer.new();add_child(stream_player_1);stream_player_1.bus = "StimCellDeepfry"
		_:
			stream_player_1 = AudioStreamPlayer.new();add_child(stream_player_1);stream_player_1.bus = BUS
	feed(value)
func play() -> void :
	if !clip1 or !clip1.stream: printerr("Stim chunk has no base audio stream player.");return
	for child: AudioStreamPlayer in get_children():
		if child.playing: child.stop()
		if child.pitch_scale != 1.0: child.pitch_scale = 1.0
	match type:
		StimType.RAPID_SCURRY: await _play_rapid_scurry()
		StimType.FULL_GET_HIGHER: await _play_full_get_higher()
		StimType.BACK_AND_FORTH_FASTER: await _play_back_and_forth_faster()
		StimType.STUTTER: await _play_stutter()
		StimType.DEEPFRY: await _play_deepfry()
		StimType.INCREASE_LOOP: await _play_increase_loop()
	finished.emit()


func _play_rapid_scurry() -> void :
	var clip_length: float = clip1.stream.get_length()
	for i: int in randi_range(20, 30):
		clip1.play(randf_range(0.0, maxf(0.0, clip_length - 0.25)))
		await get_tree().create_timer(randf_range(0.1, 0.25)).timeout
	clip1.stop()
func _play_full_get_higher() -> void :
	for i: int in randi_range(1, 3) + randi_range(1, 2):
		clip1.play(); await clip1.finished
		clip1.pitch_scale = 1.0 + randf_range(0.1, 0.75) + randf_range(0.05, 0.25)
		await get_tree().create_timer(randf_range(2.0, 8.0)).timeout
func _play_back_and_forth_faster() -> void :
	var wait_time: float
	var clip1_start_time: float = 0.3 if clip1.stream.get_length() > 0.7 else 0.0
	var clip2_start_time: float = 0.3 if clip2.stream.get_length() > 0.7 else 0.0
	for i: int in range(16):
		match floori(i / 2.0):
			0, 1: wait_time = 0.25
			2, 3: wait_time = 0.12
			_: wait_time = 0.06
		clip1.play(clip1_start_time); await get_tree().create_timer(wait_time).timeout;clip1.stop()
		clip2.play(clip2_start_time); await get_tree().create_timer(wait_time).timeout;clip2.stop()
func _play_stutter() -> void :
	var start_point: float = maxf(0.0, clip1.stream.get_length())
	for i: int in randi_range(30, 60):
		clip1.play(start_point)
		await get_tree().create_timer(0.1).timeout
	clip1.stop()
func _play_deepfry() -> void : clip1.play(); await get_tree().create_timer(3.0).timeout;clip1.stop()
func _play_increase_loop() -> void :
	var clip_length: float = clip1.stream.get_length()
	var play_length: float = 1.7 if clip_length > 2.8 else maxf(1.0, clip_length)
	for i: int in randi_range(4, 6):
		var pitch_scale: float = 1.2 ** i
		clip1.pitch_scale = pitch_scale
		clip1.play()
		await get_tree().create_timer(play_length / pitch_scale).timeout
	clip1.stop()
