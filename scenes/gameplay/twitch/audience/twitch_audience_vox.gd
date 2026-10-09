class_name TwitchAudienceVox extends Node



const TOTAL_STREAMS: int = 25


var audio_players: Array[AudioStreamPlayer]


var chatter_units: Array[PackChatter]


var last_accessed_index: int = 0
var global_last_triggered_time: int = 0
var user_last_triggered_time: Dictionary[String, int] = {}




func _setup_streams() -> void :
	for i: int in range(TOTAL_STREAMS):
		var new_stream: = AudioStreamPlayer.new()
		new_stream.bus = "Chatter"
		audio_players.append(new_stream)
		add_child(new_stream)
func _setup_chatter_units() -> void :
	for native_chatter: String in NativePackService.NATIVE_CHATTER_PACKS:
		if Profile.ignored_packs_chatter.has(native_chatter): continue
		var new_pack: PackChatter = NativePackService.get_native_chatter_pack(native_chatter)
		new_pack.native_create_sounds_directories()
		chatter_units.append(new_pack)
	for chatter_folder: String in DirAccess.get_directories_at(FileManager.MODPACKS_CHATTER):
		if Profile.ignored_packs_chatter.has(chatter_folder): continue
		var new_pack: = PackChatter.new()
		new_pack.generate_from_global_directory(FileManager.MODPACKS_CHATTER + chatter_folder)
		chatter_units.append(new_pack)


func _ready() -> void :
	_setup_streams()
	_setup_chatter_units()



func _new_chat(user: Chatter) -> void :
	if !Profile.twitch_chatter_on: return
	var users_time: int = Time.get_ticks_msec()
	if users_time - global_last_triggered_time < Profile.twitch_chatter_global_cooldown * 1000: return
	if (users_time - user_last_triggered_time.get(user.login, 0)) < Profile.twitch_chatter_user_cooldown * 1000: return
	var args: PackedStringArray = user.message.split(" ", false)
	var arg0: String = ""
	if args.size(): arg0 = args[0]
	if arg0:
		for unit: PackChatter in chatter_units:
			var result: ConresChatterInstance = unit.conres.search(arg0)
			if !result: continue

			global_last_triggered_time = users_time
			user_last_triggered_time[user.login] = users_time

			last_accessed_index = wrapi(last_accessed_index + 1, 0, TOTAL_STREAMS)
			var stream_player: AudioStreamPlayer = audio_players[last_accessed_index]
			if stream_player.playing: stream_player.stop()
			stream_player.stream = result.audio
			stream_player.volume_linear = result.volume
			if user.login.to_lower() == "dealtadelta":
				stream_player.pitch_scale = 1.0
			else:


				var seeded_number: int = wrapi(hash(user.login), 0, 20)
				var pitch_flux: float = 1.0 + (seeded_number - 10.0) / 100.0
				stream_player.pitch_scale = pitch_flux
			stream_player.play()
			return
