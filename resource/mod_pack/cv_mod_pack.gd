extends Resource
class_name CVModPack


var oveep: = M.OVEEP.NONE
var top_name: String:
	set(value):
		set_pack.call()




var config: Dictionary = {}
var config_hidden: Dictionary = {}
var set_pack: Callable
var absolute_path: String = "user://game/"


func config_overwrite(base: Dictionary, injector: Dictionary):
	for key in base.keys():
		if typeof(base[key]) == TYPE_DICTIONARY:
			if injector.has(key):
				config_overwrite(base[key], injector[key])
			else:
				print("CVModPack | Loaded config lacks dictionary key '%s'. Using default." % key)
		else:
			if injector.has(key):
				var key_base: = typeof(base[key])
				var key_injector: = typeof(injector[key])

				if (key_base == TYPE_INT) or (key_base == TYPE_FLOAT):
					if (key_injector == TYPE_INT) or (key_injector == TYPE_FLOAT):
						base[key] = injector[key]
					else:
						print("CVModPack | Loaded config value type for key '%s' is unexpected. Using default." % key)
				elif key_base == key_injector:
					base[key] = injector[key]
				else:
					print("CVModPack | Loaded config value type for key '%s' is unexpected. Using default." % key)
			else:
				print("CVModPack | Loaded config lacks value key '%s'. Using default." % key)


func get_pack_music(file_name: StringName, target_oveep: M.OVEEP = oveep) -> AudioStream:
	var uc: = UC.new()
	var new_music: AudioStream = uc.get_audio(target_oveep, file_name, false)
	if new_music is AudioStreamWAV:
		if new_music.loop_begin == 0:
			new_music.loop_mode = AudioStreamWAV.LOOP_FORWARD
			new_music.loop_begin = config.music.loop_start
	elif new_music is AudioStreamMP3 or new_music is AudioStreamOggVorbis:
		new_music.loop = true

		if new_music.loop_offset == 0.0: new_music.loop_offset = config.get("audio", {}).get("music_menu_loop_start", 0)
	else:
		return null
	uc.queue_free()
	return new_music
