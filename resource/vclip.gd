extends Node
class_name VclipResource


var directory: String = ""

var audio: AudioStream
var image: Texture
var hint: String = ""
var iffy: String = ""
var file_name_agnostic: String

var round_data: Dictionary = {}
var stream_player: AudioStreamPlayer


func set_from_omniclip(input: OmniClip, image_size: Vector2i = Vector2i.ZERO) -> void :
	directory = "packs_voice/" + input.seen_path + "." + input.file_name.get_extension()
	audio = input.clip_audio
	if image_size:
		var original_texture = input.clip_texture
		var image_interim: Image = original_texture.get_image()
		image_interim.resize(image_size.x, image_size.y, Image.INTERPOLATE_LANCZOS)
		image = ImageTexture.create_from_image(image_interim)
	else: image = input.clip_texture
	hint = input.clip_caption
	file_name_agnostic = input.file_name_agnostic
	if stream_player: stream_player.stream = audio;stream_player.bus = "Vclip"


func set_from_directory(directory_: String, image_size: Vector2i = Vector2i.ZERO):
	directory = directory_
	const oveep: = M.OVEEP.VOICE
	var uc: = UC.new()
	audio = uc.get_audio(oveep, directory)
	image = uc.get_image(oveep, directory, false, image_size)
	if image == null:
		image = uc.get_image(oveep, directory.get_base_dir() + "/_pack_filler_image", false, image_size)
		if image == null:
			image = uc.get_image(M.OVEEP.MENU, "no_image", true, image_size)
	hint = uc.get_text(oveep, directory)
	iffy = directory.get_basename().get_file()
	if stream_player:
		stream_player.stream = audio
		stream_player.bus = "Vclip"
	uc.queue_free()

func get_image_without_transparency(c: = Color(0.1, 0.1, 0.1)) -> Texture:
	var img: Image = image.get_image()
	for y in img.get_height():
		for x in img.get_width():
			var pxl: Color = img.get_pixel(x, y)
			img.set_pixel(x, y, Color(pxl.r, pxl.g, pxl.b, 1.0) * pxl.a)
	return ImageTexture.create_from_image(img)
