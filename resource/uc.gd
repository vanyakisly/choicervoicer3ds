extends Node
class_name UC


func generate_surface_folders():
	DirAccess.make_dir_absolute("user://game")
	DirAccess.make_dir_absolute("user://game/packs_host")
	DirAccess.make_dir_absolute("user://game/packs_judges")
	DirAccess.make_dir_absolute("user://game/packs_menu")
	DirAccess.make_dir_absolute("user://game/packs_studio")
	DirAccess.make_dir_absolute("user://game/packs_voice")

	DirAccess.make_dir_absolute("user://game/packs_player")
	DirAccess.make_dir_absolute("user://game/saves")
	DirAccess.make_dir_absolute("user://game/recordings")






























func populate_from_defaults(res_map: String = "res://game_default/", replacer_map: String = "user://game/"):

	print("UC | Beginning folder population with %s as a base" % res_map)
	var dir = DirAccess.open(res_map)
	if dir:
		dir.list_dir_begin()
		var variant_file: String = dir.get_next()
		while variant_file != "":


			await M.get_tree().process_frame





			if !dir.current_is_dir():
				print("\t\t%s" % variant_file)
				var iffyee: String = variant_file
				var res_directoryee: String = res_map + iffyee
				if (res_directoryee.get_extension() == "import") or dir.file_exists(res_directoryee + ".import"):

					if res_directoryee.get_extension() == "import":

						res_directoryee = res_directoryee.get_basename()
					var usr_directory = res_directoryee.replace(res_map, replacer_map).get_basename()

					var usr_dir_exists: bool = false
					match res_directoryee.get_extension():
						"png":
							for extension in [".png", ".jpg", ".jpeg"]: if FileAccess.file_exists(usr_directory + extension): usr_dir_exists = true;break
							if not usr_dir_exists:
								print("UC | Copying default image from %s -> %s" % [res_directoryee, usr_directory])
								var res_image_resource: CompressedTexture2D = ResourceLoader.load(res_directoryee, "", ResourceLoader.CACHE_MODE_IGNORE)
								res_image_resource.get_image().save_png(usr_directory + ".png")

						"wav":
							for extension in [".wav", ".mp3"]: if FileAccess.file_exists(usr_directory + extension): usr_dir_exists = true;break
							if not usr_dir_exists:
								print("UC | Copying default audio from %s -> %s" % [res_directoryee, usr_directory])
								var res_audio_resource: AudioStreamWAV = ResourceLoader.load(res_directoryee, "", ResourceLoader.CACHE_MODE_IGNORE)
								res_audio_resource.save_to_wav(usr_directory)
















				else:

					var usr_directoryee = res_directoryee.replace(res_map, replacer_map)
					if not dir.file_exists(usr_directoryee):

						print("UC | Copying default file from %s -> %s" % [res_directoryee, usr_directoryee])

						if res_directoryee.contains("model_template"): DirAccess.copy_absolute(res_directoryee, usr_directoryee.get_basename() + ".glb")
						else: DirAccess.copy_absolute(res_directoryee, usr_directoryee)
			variant_file = dir.get_next()

func user_oveep_pack_path(oveep: M.OVEEP, assume_pack: bool = true) -> String:
	var start: String = "user://game/packs_"
	match oveep:
		M.OVEEP.HOST: return FileManager.MODPACKS_HOST + Profile.host_slash

		M.OVEEP.JUDGES: return FileManager.MODPACKS_JUDGES + Profile.judges_slash

		M.OVEEP.MENU: return FileManager.MODPACKS_MENU + Profile.menu_slash

		M.OVEEP.STUDIO: return FileManager.MODPACKS_STUDIO + Profile.studio_slash

		M.OVEEP.VOICE:
			return start + "voice/"
		M.OVEEP.TWITCH:
			return start + "twitch/" + M.data.custom.twitch + "/"
		M.OVEEP.PLAYER:
			if assume_pack: return FileManager.MODPACKS_CONTESTANT + Profile.contestant_slash

			else: return FileManager.MODPACKS_CONTESTANT

		M.OVEEP.NONE:
			return ""
		_:
			return start


func res_oveep_pack_path(oveep: M.OVEEP) -> String:
	var res_doremifa: String = "res://game_default/packs_"
	match oveep:
		M.OVEEP.HOST:
			res_doremifa += "host/Default - Shae/"
		M.OVEEP.JUDGES:
			res_doremifa += "judges/The Choicer Voicer's Default Judges/"
		M.OVEEP.MENU:
			res_doremifa += "menu/The Choicer Voicer's Default Menu/"
		M.OVEEP.STUDIO:
			res_doremifa += "studio/The Choicer Voicer's Default Studio/"
		M.OVEEP.VOICE:
			res_doremifa += "voice/The Choicer Voicer Tutorial Pack/"
		M.OVEEP.TWITCH:
			res_doremifa += "twitch/The Choicer Voicer's Default Twitch Integration/"
		M.OVEEP.PLAYER:
			res_doremifa += "player/Player/"
	return res_doremifa

























func get_image(oveep: M.OVEEP, iffy_or_directory: String, retrieve_default: bool = false, resize_dimensions: Vector2i = Vector2i.ZERO, 
		assume_pack: bool = true, interpolation: Image.Interpolation = Image.INTERPOLATE_LANCZOS) -> Texture:
	var usr_directory: String = user_oveep_pack_path(oveep, assume_pack) + iffy_or_directory

	var template_call: Callable = func(extension: String) -> Texture:
		if FileAccess.file_exists(usr_directory + "." + extension):
			var image_buffer: = FileAccess.open(usr_directory + "." + extension, FileAccess.READ)
			var image: = Image.new()
			if image.call("load_%s_from_buffer" % extension, image_buffer.get_buffer(image_buffer.get_length())) == OK:
				if image != null and resize_dimensions: image.resize(resize_dimensions.x, resize_dimensions.y, interpolation)
				return ImageTexture.create_from_image(image)
		return null
	var texture: = Texture.new()
	for ext in ["png", "jpg", "jpeg", "webp"]:
		texture = template_call.call(ext)
		if texture != null: return texture


	if retrieve_default:

		var res_texture: CompressedTexture2D = load(res_oveep_pack_path(oveep) + iffy_or_directory.get_file() + ".png")
		var image: Image = res_texture.get_image()
		if resize_dimensions:
			image.resize(resize_dimensions.x, resize_dimensions.y, interpolation)
		return ImageTexture.create_from_image(image)
	else:
		return null


func get_vclip_image(config_iffy_or_directory: String, iffy_or_directory: String, resize_dimensions: Vector2i = Vector2i.ZERO, 
		assume_pack: bool = true, interpolation: Image.Interpolation = Image.INTERPOLATE_LANCZOS) -> ImageTexture:

	var texture: ImageTexture
	if config_iffy_or_directory != "":
		texture = get_image(M.OVEEP.VOICE, config_iffy_or_directory, false, resize_dimensions, assume_pack, interpolation)
	if texture == null:

		texture = get_image(M.OVEEP.VOICE, iffy_or_directory, false, resize_dimensions, assume_pack, interpolation)
		if texture == null:

			texture = get_image(M.OVEEP.VOICE, iffy_or_directory.get_base_dir() + "/_pack_filler_image", false, resize_dimensions, assume_pack, interpolation)



	return texture


func get_vclip_image_full(is_seen: bool, unseen_image: ImageTexture, no_image: ImageTexture, image_assignment: Dictionary, 
		iffy_or_directory: String, resize_dimensions: Vector2i = Vector2i.ZERO, assume_pack: bool = true, 
		interpolation: Image.Interpolation = Image.INTERPOLATE_LANCZOS) -> ImageTexture:
	if not is_seen:
		return unseen_image
	else:
		var config_value_or_blank: Callable = func(path: String) -> String:
			var pathee = path.get_file()
			if image_assignment.has(pathee):
				return path.get_base_dir() + "/" + image_assignment[pathee]
			else: return ""
		var texture: ImageTexture
		texture = get_vclip_image(config_value_or_blank.call(iffy_or_directory), iffy_or_directory, resize_dimensions, assume_pack, interpolation)
		if texture == null: return no_image
		else: return texture


func get_audio(oveep: M.OVEEP, iffy_or_directory: String, retrieve_default: bool = false, assume_pack: bool = true) -> AudioStream:
	var usr_directory: String = user_oveep_pack_path(oveep, assume_pack) + iffy_or_directory


	if FileAccess.file_exists(usr_directory + ".wav"):

		var audio: = AudioStreamWAV.new()
		var full_load: PackedByteArray = FileAccess.get_file_as_bytes(usr_directory + ".wav")
		if full_load.decode_u16(34) == 8:
			audio.set_format(AudioStreamWAV.FORMAT_8_BITS)
		elif full_load.decode_u16(34) == 16:
			audio.set_format(AudioStreamWAV.FORMAT_16_BITS)
		else:
			return null

		var data_location: int = 36
		while (full_load.decode_u32(data_location) != 1635017060) and (data_location < full_load.size() - 4):
			data_location += 1
		var data_size: int = full_load.decode_u32(data_location + 4)

		audio.set_mix_rate(full_load.decode_u32(24))
		audio.stereo = true if full_load.decode_u16(22) == 2 else false
		if audio.get_format() == AudioStreamWAV.FORMAT_8_BITS:
			var data: PackedByteArray = []
			for byte in full_load.slice(data_location + 8, data_location + 8 + data_size):
				data.append(byte - 128)
			audio.set_data(data)
		else:
			audio.set_data(full_load.slice(data_location + 8, data_location + 8 + data_size))
		return audio


	if FileAccess.file_exists(usr_directory + ".mp3"):
		var audio: = AudioStreamMP3.new()
		var file = FileAccess.open(usr_directory + ".mp3", FileAccess.READ)
		audio.data = file.get_buffer(file.get_length())
		if audio != null:
			return audio


	if FileAccess.file_exists(usr_directory + ".ogg"):
		var audio: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(usr_directory + ".ogg")
		if audio != null:
			return audio


	if retrieve_default and iffy_or_directory != "music_studio":
		var audio: AudioStreamWAV = ResourceLoader.load(res_oveep_pack_path(oveep) + iffy_or_directory + ".wav", "", ResourceLoader.CACHE_MODE_IGNORE)
		return audio
	else:
		return null


func get_text(oveep: M.OVEEP, iffy_or_directory: String, retrieve_default: bool = false, assume_pack: bool = true) -> String:
	var usr_directory: String = user_oveep_pack_path(oveep, assume_pack) + iffy_or_directory
	const VALIDEXTENSIONS: PackedStringArray = [".txt"]
	for extension in VALIDEXTENSIONS:
		if FileAccess.file_exists(usr_directory + extension):
			return FileAccess.get_file_as_string(usr_directory + extension).c_escape().replace("\\r", "").c_unescape()
		else:
			if retrieve_default:
				var res_directoryee: String = res_oveep_pack_path(oveep) + iffy_or_directory + extension
				if FileAccess.file_exists(res_directoryee):
					return FileAccess.get_file_as_string(res_directoryee).c_escape().replace("\\r", "").c_unescape()
			else:
				return ""
	return ""


func get_json(oveep: M.OVEEP, iffy_or_directory: String, assume_pack: bool = true, fill_gaps: bool = true) -> Dictionary:
	var usr_directoryee: String = user_oveep_pack_path(oveep, assume_pack) + iffy_or_directory + ".json"
	var res_directoryee: String
	if assume_pack:
		res_directoryee = res_oveep_pack_path(oveep) + iffy_or_directory + ".json"
	else:
		res_directoryee = res_oveep_pack_path(oveep) + iffy_or_directory.get_file() + ".json"

	if fill_gaps:
		var res_gap_filler: Dictionary = JSON.parse_string(FileAccess.open(res_directoryee, FileAccess.READ).get_as_text())

		for i in range(1):
			if FileAccess.file_exists(usr_directoryee):
				var file: = FileAccess.open(usr_directoryee, FileAccess.READ)
				if file == null:
					print("UC | User JSON file failed to load at '%s'" % usr_directoryee)
					break
				var content: String = file.get_as_text()
				file.close()
				var json: Dictionary = JSON.parse_string(content)
				if json == null:
					print("UC | User JSON file failed to parse at '%s'" % usr_directoryee)
					break
				elif oveep != M.OVEEP.NONE:
					return json_gap_fill_recursion(json, res_gap_filler)
				else:
					return json
			else:
				print("UC | Expected user file '%s' does not exist" % usr_directoryee)
				pass

		print("UC | Using entirety of default JSON")
		return res_gap_filler
	else:
		for i in range(1):
			if FileAccess.file_exists(usr_directoryee):
				var file: = FileAccess.open(usr_directoryee, FileAccess.READ)
				if file == null:
					print("UC | User JSON file failed to load at '%s'" % usr_directoryee)
					return {}
				var content: String = file.get_as_text()
				file.close()

				var json: Dictionary = JSON.parse_string(content)
				if json == null:
					print("UC | User JSON file failed to parse at '%s'" % usr_directoryee)
					return {}
				else:
					return json
			else:
				print("UC | Expected user file '%s' does not exist" % usr_directoryee)
		return {}


func json_gap_fill_recursion(input: Dictionary, filler: Dictionary) -> Dictionary:
	for key in filler.keys():
		if typeof(filler[key]) == TYPE_DICTIONARY:
			if input.has(key) and typeof(input[key]) == TYPE_DICTIONARY:

				json_gap_fill_recursion(input[key], filler[key])
			else:

				print("UC | Dictionary for %s is missing or the wrong type. Using the default value of %s" % [key, filler[key]])
				input[key] = filler[key].duplicate(true)
		else:

			if not input.has(key):
				input[key] = filler[key]
				print("UC | Value for %s is missing. Using the default value of %s" % [key, filler[key]])

			elif not (typeof(filler[key]) == typeof(input[key])):
				var tf = typeof(filler[key])
				var ti = typeof(input[key])
				if ((tf == TYPE_INT or tf == TYPE_FLOAT) and (ti == TYPE_INT or ti == TYPE_FLOAT)):

					pass
				else:
					print("UC | Value for %s is the wrong type: %s vs expected %s. Using the default value of %s" % [key, typeof(input[key]), typeof(filler[key]), filler[key]])
					input[key] = filler[key]

	return input


func save_json_config(oveep: M.OVEEP, iffy_or_directory: String, config: Dictionary):
	var usr_directoryee: String = user_oveep_pack_path(oveep) + iffy_or_directory + ".json"
	var file = FileAccess.open(usr_directoryee, FileAccess.WRITE)
	if file == null:
		print("UC | '%s' config failed to save. UNKNOWN ERROR." % iffy_or_directory)
		return
	var stringified_config: String = JSON.stringify(config, "\t")
	file.store_string(stringified_config)
	file.close()


func new_player_talk(audio: AudioStreamWAV, talk: String):
	var pacy: String = "user://game/packs_player/" + M.data.custom.player + "/talk_" + talk
	var pacy_prev: String = "user://game/packs_player/" + M.data.custom.player + "/previous_talk_" + talk
	for extension in [".wav", ".mp3", ".ogg"]:
		if FileAccess.file_exists(pacy + extension):
			var _err = DirAccess.rename_absolute(pacy + extension, pacy_prev + extension)
	audio.save_to_wav(pacy)



func get_json_DEBUG(oveep: M.OVEEP, iffy_or_directory: String, assume_pack: bool = true) -> Dictionary:
	var usr_directoryee: String = user_oveep_pack_path(oveep, assume_pack) + iffy_or_directory







	for i in range(1):
		if FileAccess.file_exists(usr_directoryee):
			var file: = FileAccess.open(usr_directoryee, FileAccess.READ)
			if file == null:
				print("UC | User JSON file failed to load at '%s'" % usr_directoryee)
				break
			var content: String = file.get_as_text()
			file.close()
			var json: Dictionary = JSON.parse_string(content)
			if json == null:
				print("UC | User JSON file failed to parse at '%s'" % usr_directoryee)
				break
			else:
				return json
		else:
			print("UC | Expected user file '%s' does not exist" % usr_directoryee)
			pass

	print("UC | Using entirety of default JSON")
	return {}






func get_image_as_texture1(oveep: M.OVEEP, iffy_or_directory: String, retrieve_default: bool = false, resize_dimensions: Vector2i = Vector2i.ZERO, 
		assume_pack: bool = true, interpolation: Image.Interpolation = Image.INTERPOLATE_LANCZOS) -> Texture:
	var usr_directory: String = user_oveep_pack_path(oveep, assume_pack) + iffy_or_directory
	const VALIDEXTENSIONS: PackedStringArray = [".png", ".jpg", ".jpeg", ".webp"]
	for extension in VALIDEXTENSIONS:
		if FileAccess.file_exists(usr_directory + extension):
			var image: = Image.load_from_file(usr_directory + extension)
			if resize_dimensions:
				image.resize(resize_dimensions.x, resize_dimensions.y, interpolation)
			return ImageTexture.create_from_image(image)

	if retrieve_default:

		var res_texture: CompressedTexture2D = load(res_oveep_pack_path(oveep) + iffy_or_directory.get_file() + ".png")
		var image: Image = res_texture.get_image()
		if resize_dimensions:
			image.resize(resize_dimensions.x, resize_dimensions.y, interpolation)
		return ImageTexture.create_from_image(image)
	else:
		return null

func get_existing_image(oveep: M.OVEEP, iffy_or_directory: String) -> Image:
	var usr_directory: String = user_oveep_pack_path(oveep) + iffy_or_directory
	const VALIDEXTENSIONS: PackedStringArray = [".png", ".jpg", ".jpeg", ".webp"]
	for extension in VALIDEXTENSIONS:
		if FileAccess.file_exists(usr_directory + extension):
			return Image.load_from_file(usr_directory + extension)
	return null























func get_image_direct(upath: String) -> Image:
	for extension: String in ["", "png", "PNG", "jpg", "JPG", "jpeg", "JPEG", "webp", "WEBP"]:
		if FileAccess.file_exists(upath + "." + extension):
			return Image.load_from_file(upath + "." + extension)
	return null


func get_audio_direct(upath: String) -> AudioStream:

	if FileAccess.file_exists(upath + ".wav"):

		var audio: = AudioStreamWAV.new()
		var full_load: PackedByteArray = FileAccess.get_file_as_bytes(upath + ".wav")
		if full_load.decode_u16(34) == 8:
			audio.set_format(AudioStreamWAV.FORMAT_8_BITS)
		elif full_load.decode_u16(34) == 16:
			audio.set_format(AudioStreamWAV.FORMAT_16_BITS)


		else:
			return null

		var data_location: int = 36
		while (full_load.decode_u32(data_location) != 1635017060) and (data_location < full_load.size() - 4):
			data_location += 1
		var data_size: int = full_load.decode_u32(data_location + 4)

		audio.set_mix_rate(full_load.decode_u32(24))
		audio.stereo = true if full_load.decode_u16(22) == 2 else false
		if audio.get_format() == AudioStreamWAV.FORMAT_8_BITS:
			var data: PackedByteArray = []
			for byte in full_load.slice(data_location + 8, data_location + 8 + data_size):
				data.append(byte - 128)
			audio.set_data(data)
		else:
			audio.set_data(full_load.slice(data_location + 8, data_location + 8 + data_size))
		return audio


	if FileAccess.file_exists(upath + ".mp3"):
		var audio: = AudioStreamMP3.new()
		var file = FileAccess.open(upath + ".mp3", FileAccess.READ)
		audio.data = file.get_buffer(file.get_length())
		if audio != null:
			return audio


	if FileAccess.file_exists(upath + ".ogg"):
		var audio: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(upath + ".ogg")
		if audio != null:
			return audio
	return null


func get_json_direct(upath: String) -> Dictionary:
	if FileAccess.file_exists(upath):
		var file: = FileAccess.open(upath, FileAccess.READ)
		if file == null:
			print("UC | User JSON file failed to load at '%s'" % upath)
			return {}
		var content: String = file.get_as_text()
		file.close()

		var json: Dictionary = JSON.parse_string(content)
		if json == null:
			print("UC | User JSON file failed to parse at '%s'" % upath)
			return {}
		else:
			return json
	else:
		print("UC | Expected user file '%s' does not exist" % upath)
	return {}
