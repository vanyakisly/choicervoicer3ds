extends CVModPack
class_name StudioModPack


var config_studio: Dictionary = {
	"audio": {
		"music_studio_loop_start": 0, 
		"music_studio_loop_start_README": "For WAV, the start must be the SAMPLE. For MP3 and OGG, it must be the TIME, in seconds."
	}, 
	"recording_overlay_colors": {
		"body": "d1f6ff", 
		"block_border": "80e5ff", 
		"playbar": "cc0000", 
		"record_light": "7dcde3", 
		"record_backlight": "a1d6d5", 
		"voice_color": "ff00ff", 
		"user_color": "00ffff"
	}
}

var music_studio: AudioStream

var local_oveep: = M.OVEEP.STUDIO
var local_set_pack: Callable = func(pack_name: String = ""):
	var load_defaults_where_applicable: Callable = func():
		for value in [
			&"music_studio"
		]: if self[value] == null: self[value] = load_default(value)
	var uc: = UC.new()
	absolute_path += "packs_studio/"
	if pack_name == "" or not DirAccess.dir_exists_absolute(absolute_path + pack_name):
		pack_name = "Default"
		M.data.custom.studio = "Default"
	else:
		M.data.custom.studio = pack_name
	match pack_name:
		"Default":
			pass
		_:
			music_studio = get_pack_music(&"music_studio")
	load_defaults_where_applicable.call()
	uc.queue_free()


func load_default(value):
	match value:
		&"music_studio": return load("res://audio/music/studio_music_loop_final.wav")
		_:
			return null


func _init():
	oveep = local_oveep
	set_pack = local_set_pack
	config = config_studio
