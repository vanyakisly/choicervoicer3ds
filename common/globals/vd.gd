extends Node



const PRINTMSG: String = "VD | "


const SCANNED_AUDIO_EXTENSIONS_LOWER: PackedStringArray = ["wav", "mp3", "ogg"]
const SCANNED_IMAGE_EXTENSIONS_LOWER: PackedStringArray = ["png", "jpg", "jpeg"]
const SCANNED_CONFIG_EXTENSIONS_LOWER: PackedStringArray = ["ini", "cfg", "txt"]

const SCANNED_AUDIO_EXTENSIONS: PackedStringArray = ["wav", "mp3", "ogg", "WAV", "MP3", "OGG"]
const SCANNED_IMAGE_EXTENSIONS: PackedStringArray = ["png", "jpg", "jpeg", "PNG", "JPG", "JPEG"]
const SCANNED_CONFIG_EXTENSIONS: PackedStringArray = ["ini", "cfg", "txt", "INI", "CFG", "TXT"]
const SCANNED_TEXT_EXTENSIONS: PackedStringArray = ["txt", "TXT"]
const SCANNED_VIDEO_EXTENSIONS: PackedStringArray = ["ogv", "OGV"]


func get_audio(global_path: String) -> AudioStream:
	var output: AudioStream = null
	if !FileAccess.file_exists(global_path): printerr(PRINTMSG + "[Audio] Target file path `%s` does not exist." % global_path);return output
	var extension: String = global_path.get_extension().to_lower()
	match extension:
		"wav":
			output = AudioStreamWAV.new()
			var file_as_bytes: PackedByteArray = FileAccess.get_file_as_bytes(global_path)
			var metadata_format: int = file_as_bytes.decode_u16(34)
			if metadata_format == 8: output.set_format(AudioStreamWAV.FORMAT_8_BITS)
			elif metadata_format == 16: output.set_format(AudioStreamWAV.FORMAT_16_BITS)
			else:
				return null

			var data_location: int = 36
			while (file_as_bytes.decode_u32(data_location) != 1635017060) and (data_location < file_as_bytes.size() - 4):
				data_location += 1
			var data_size: int = file_as_bytes.decode_u32(data_location + 4)

			output.set_mix_rate(file_as_bytes.decode_u32(24))
			output.stereo = true if file_as_bytes.decode_u16(22) == 2 else false
			if output.get_format() == AudioStreamWAV.FORMAT_8_BITS:
				var data: PackedByteArray = []
				for byte: int in file_as_bytes.slice(data_location + 8, data_location + 8 + data_size):
					data.append(byte - 128)
				output.set_data(data)
			else:
				output.set_data(file_as_bytes.slice(data_location + 8, data_location + 8 + data_size))
		"mp3":
			output = AudioStreamMP3.new()
			output.data = FileAccess.get_file_as_bytes(global_path)
		"ogg":
			var output_ogg: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(global_path)
			output = output_ogg
		_:
			printerr(PRINTMSG + "Invalid audio extension for file path `%s`" % global_path)
			return null
	return output


func get_texture(global_path: String, add_transparency_border: bool = false) -> Texture2D:
	if !FileAccess.file_exists(global_path): printerr(PRINTMSG + "[Image] Target file path `%s` does not exist." % global_path);return null
	var image: = Image.load_from_file(global_path)
	if image == null: printerr(PRINTMSG + "Failed to load image file from path `%s`" % global_path);return null
	elif add_transparency_border:
		if image.get_format() != Image.FORMAT_RGBA8: image.convert(Image.FORMAT_RGBA8)
		var img_x: int = image.get_width()
		var img_y: int = image.get_height()
		var stampable_transparency: = Image.create_empty(img_x + 2, img_y + 2, false, Image.FORMAT_RGBA8)
		stampable_transparency.blit_rect(image, Rect2i(0, 0, img_x, img_y), Vector2i(1, 1))
		return ImageTexture.create_from_image(stampable_transparency)
	return ImageTexture.create_from_image(image)


func get_config(global_path: String) -> CondomFile:
	if !FileAccess.file_exists(global_path): printerr(PRINTMSG + "[Config] Target file path `%s` does not exist." % global_path);return null
	var output: = CondomFile.new();output.load(global_path)
	return output


func get_text(global_path: String) -> String:
	if !FileAccess.file_exists(global_path): printerr(PRINTMSG + "[Text] Target file path `%s` does not exist." % global_path);return ""
	var output: String = FileAccess.get_file_as_string(global_path)
	return output.c_escape().replace("\\r", "").c_unescape()


func get_video(global_path: String) -> VideoStream:
	if !FileAccess.file_exists(global_path): printerr(PRINTMSG + "[Video] Target file path `%s` does not exist." % global_path);return null
	var output: = VideoStreamTheora.new()
	output.file = global_path
	return output


func get_audio_agnositc(gfpa: String) -> AudioStream:
	for ext: String in SCANNED_AUDIO_EXTENSIONS: var capa: String = gfpa + "." + ext; if FileAccess.file_exists(capa): return get_audio(capa)
	return null

func get_texture_agnostic(gfpa: String, add_transparency_border: bool = false) -> Texture2D:
	for ext: String in SCANNED_IMAGE_EXTENSIONS: var capa: String = gfpa + "." + ext; if FileAccess.file_exists(capa): return get_texture(capa, add_transparency_border)
	return null

func get_config_agnostic(gfpa: String) -> CondomFile:
	for ext: String in SCANNED_CONFIG_EXTENSIONS: var capa: String = gfpa + "." + ext; if FileAccess.file_exists(capa): return get_config(capa)
	return null

func get_text_agnostic(gfpa: String) -> String:
	for ext: String in SCANNED_TEXT_EXTENSIONS: var capa: String = gfpa + "." + ext; if FileAccess.file_exists(capa): return get_text(capa)
	return ""

func get_video_agnostic(gfpa: String) -> VideoStream:
	for ext: String in SCANNED_VIDEO_EXTENSIONS: var capa: String = gfpa + "." + ext; if FileAccess.file_exists(capa): return get_video(capa)
	return null


func get_audio_either(gfp: String) -> AudioStream:
	if SCANNED_AUDIO_EXTENSIONS.has(gfp.get_extension()): return get_audio(gfp)
	else: return get_audio_agnositc(gfp)

func get_texture_either(gfp: String, add_transparency_border: bool = false) -> Texture2D:
	if SCANNED_IMAGE_EXTENSIONS.has(gfp.get_extension()): return get_texture(gfp, add_transparency_border)
	else: return get_texture_agnostic(gfp)

func get_config_either(gfp: String) -> CondomFile:
	if SCANNED_CONFIG_EXTENSIONS.has(gfp.get_extension()): return get_config(gfp)
	else: return get_config_agnostic(gfp)


func get_font(global_path: String) -> FontFile:

	var output: = FontFile.new()
	if not FileAccess.file_exists(global_path): return output
	var path_lower: String = global_path.to_lower()
	for extension: String in [".ttf", ".otf", ".woff", ".woff2", ".pfb", ".pfm"]:
		if path_lower.ends_with(extension): output.load_dynamic_font(global_path)
		return output
	for extension: String in [".fnt", ".font"]:
		if path_lower.ends_with(extension): output.load_bitmap_font(global_path)
		return output
	push_error(PRINTMSG + "Invalid font file format from path `%s`" % global_path)
	return null


func __get_model(global_path: String, specular_floor_fix: bool = true) -> PackedScene:
	var output: = PackedScene.new()
	if not FileAccess.file_exists(global_path): printerr(PRINTMSG + "[Model] No file exists at `%s`" % global_path);return output
	var gltf_document: = GLTFDocument.new()
	var gltf_state: = GLTFState.new()
	var error: Error = gltf_document.append_from_file(global_path, gltf_state)
	if not error == OK: return output
	if specular_floor_fix:
		var materials: Array[Material] = gltf_state.get_materials()
		for material: Material in materials:
			if material is StandardMaterial3D:
				if material.resource_name == "FloorImage": material.metallic_specular = 0.1
	var output_node: Node = gltf_document.generate_scene(gltf_state)

	for node: Node in output_node.get_children():
		if node is AnimationPlayer:
			var animation_list: PackedStringArray = node.get_animation_list()
			if animation_list.size() > 0:
				var world_animation: StringName = animation_list[0]
				node.get_animation(world_animation).loop_mode = 1
				node.autoplay = world_animation
	var result: Error = output.pack(output_node)
	if result != OK: printerr(PRINTMSG + "Failed to pack generated scene node.")
	return output











func get_json_object(global_path: String) -> Dictionary: return load_json_object(global_path)
func load_json_object(global_path: String) -> Dictionary:
	var output: Dictionary = {}
	if not FileAccess.file_exists(global_path):
		print(PRINTMSG + "No file exists for target path `%s`, returning empty object." % global_path)
		return output
	var file: = FileAccess.open(global_path, FileAccess.READ)
	if file:
		var file_as_string: String = file.get_as_text()
		file.close()
		var file_as_json: Dictionary = type_convert(JSON.parse_string(file_as_string), TYPE_DICTIONARY)
		if file_as_json: output = file_as_json
		else: printerr(PRINTMSG + "Failed to parse text from file at `%s`" % global_path)
	else: printerr(PRINTMSG + "Failed to retrieve file expected at `%s`" % global_path)
	return output


func save_json_object(global_path: String, data: Dictionary, create_files_path: bool = false) -> Error:
	if create_files_path and !DirAccess.dir_exists_absolute(global_path): DirAccess.make_dir_recursive_absolute(global_path.get_base_dir())
	var file: = FileAccess.open(global_path, FileAccess.WRITE)
	if file:
		var string_to_store: String = JSON.stringify(data, "\t")
		file.store_string(string_to_store)
		file.close()
		return OK
	else: return ERR_CANT_OPEN


func save_config(global_path: String, data: ConfigFile, create_files_path: bool = true, password: String = "") -> Error:
	if create_files_path and !DirAccess.dir_exists_absolute(global_path): DirAccess.make_dir_recursive_absolute(global_path.get_base_dir())
	if password:
		return data.save_encrypted_pass(global_path, password)
	else:
		return data.save(global_path)
