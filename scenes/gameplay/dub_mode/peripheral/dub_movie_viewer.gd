extends Control


@onready var replay_streams: Node = %ReplayStreams
@onready var player_backing_track: AudioStreamPlayer = %PlayerBackingTrack
@onready var video_stream_player: VideoStreamPlayer = %Video
@onready var video_static: VideoStreamPlayer = %VideoStatic
@onready var freestyle_player: AudioStreamPlayer = %FreestylePlayer

@onready var btn_leave: ButtonCV = %BtnLeave
@onready var btn_play: ButtonCV = %BtnPlay
@onready var btn_stop: ButtonCV = %BtnStop

var resource: GameplayResourceDubMode
var is_freestyle: bool

func _ready() -> void :
	resource = Metro.gameplay_resource_dub_mode
	video_stream_player.hide();video_static.show()
	video_static.play()
	_watch_setup()
	await get_tree().create_timer(0.6).timeout
	btn_play.click()


func _watch_setup() -> void :
	if resource.freestyle_dub:
		is_freestyle = true
		freestyle_player.stream = resource.freestyle_dub
	video_stream_player.bus = "Mute"
	player_backing_track.stream = resource.backing_track
	video_stream_player.stream = resource.video


func _watch() -> void :
	clear_playing_clips()




	for clip: OmniClip in resource.omni_clip_array.data:
		for timestamp: float in clip.dub_timestamps:
			var player: = AudioStreamPlayer.new()
			player.bus = "Pecho"
			player.stream = clip.clip_audio
			var timer: = Timer.new()
			timer.one_shot = true
			timer.wait_time = maxf(0.01, timestamp)
			timer.timeout.connect(player.play)
			timer.add_child(player)
			replay_streams.add_child(timer)
	video_stream_player.show()
	video_stream_player.play()
	if player_backing_track.stream and !Profile.dub_mode_mute_backing_track: player_backing_track.play()
	for timer: Timer in replay_streams.get_children(): timer.start()

func _watch_freestyle() -> void :
	freestyle_player.play()
	video_stream_player.show()
	video_stream_player.play()
	if player_backing_track.stream and !Profile.dub_mode_mute_backing_track: player_backing_track.play()

























func clear_playing_clips() -> void : for timer: Timer in replay_streams.get_children(): timer.queue_free()

func stop() -> void :
	if video_stream_player.is_playing(): video_stream_player.stop()
	btn_play.show();btn_stop.hide()
	if player_backing_track.playing: player_backing_track.stop();
	clear_playing_clips()
	if freestyle_player.playing: freestyle_player.stop()

func _on_video_finished() -> void : stop()
func _on_btn_stop_button_clicked() -> void : stop()
func _on_btn_leave_button_clicked() -> void : M.world.return_to_dub_selection()
func _on_btn_play_button_clicked() -> void :
	btn_play.hide();btn_stop.show()
	if !is_freestyle: _watch()
	else: _watch_freestyle()
