extends CVModPack
class_name MenuModPack

var config_menu: Dictionary = {
	"audio": {
		"music_menu_loop_start": 0, 
		"music_menu_loop_start_README": "For WAV, the start must be the SAMPLE position. For MP3 and OGG, it must be the TIME, in seconds."
	}, 
	"background": {
		"image": {
			"use_type": 0, 
			"scroll": {
				"x": 0.3, 
				"y": 0.5
			}
		}, 
		"overlay": {
			"on": false, 
		}, 
		"clip_disc": {
			"state": 1, 
			"color": "cff7ff"
		}, 
		"top_gradient": {
			"on": false, 
			"color": "ffffff"
		}, 
		"bottom_gradient": {
			"on": true, 
			"color": "ffffff"
		}, 
		"circles": {
			"on": true, 
			"color": "abe5f5cc"
		}, 
		"waves": {
			"on": false, 
			"color": "ffffff"
		}, 
		"letterbox": {
			"on": true, 
			"color": "909090", 
			"accent": "6abcd4"
		}
	}, 
	"ui": {
		"button": {
			"invert": false, 
			"color1": "accbd1", 
			"color2": "accbd1"
		}
	}
}

var button_sfx_select: AudioStream
var button_sfx_back: AudioStream
var button_sfx_decrease: AudioStream
var button_sfx_hover: AudioStream

var music_menu: AudioStream

var background: Image
var overlay: Image
var unseen_image: Image
var no_image: Image

var modular_background: Control

var local_oveep: = M.OVEEP.MENU
var local_set_pack: Callable = func(pack_name: String = ""):
	var load_defaults_where_applicable: Callable = func():
		for value in [
			&"button_sfx_select", &"button_sfx_back", &"button_sfx_decrease", &"button_sfx_hover", 
			&"music_menu", &"background", &"overlay", &"unseen_image", &"no_image"
		]: if self[value] == null: self[value] = load_default(value)

	var uc: = UC.new()
	absolute_path += "packs_menu/"
	if pack_name == "" or not DirAccess.dir_exists_absolute(absolute_path + pack_name):
		pack_name = "Default"
		M.data.custom.menu = "Default"
	else:
		M.data.custom.menu = pack_name
	match pack_name:
		"Default":
			pass
		_:
			config_overwrite(config_menu, uc.get_json(oveep, "config_menu", true, false))
			button_sfx_select = uc.get_audio(oveep, &"button_sfx_select", false)
			button_sfx_back = uc.get_audio(oveep, &"button_sfx_back", false)
			button_sfx_decrease = uc.get_audio(oveep, &"button_sfx_decrease", false)
			button_sfx_hover = uc.get_audio(oveep, &"button_sfx_hover", false)

			music_menu = get_pack_music(&"music_menu")
			background = uc.get_existing_image(oveep, &"background")
			overlay = uc.get_existing_image(oveep, &"overlay")
			unseen_image = uc.get_existing_image(oveep, &"unseen_image")
			no_image = uc.get_existing_image(oveep, &"no_image")
	load_defaults_where_applicable.call()
	uc.queue_free()


func load_default(value):
	match value:
		&"button_sfx_back": return load("res://game_default/packs_menu/The Choicer Voicer's Default Menu/button_sfx_back.wav")
		&"button_sfx_decrease": return load("res://game_default/packs_menu/The Choicer Voicer's Default Menu/button_sfx_decrease.wav")
		&"button_sfx_hover": return load("res://game_default/packs_menu/The Choicer Voicer's Default Menu/button_sfx_hover.wav")
		&"button_sfx_select": return load("res://game_default/packs_menu/The Choicer Voicer's Default Menu/button_sfx_select.wav")
		&"music_menu": return load("res://audio/music/cartridge_loop.wav")
		&"background": return load("res://game_default/packs_menu/The Choicer Voicer's Default Menu/background.png").get_image()

		&"unseen_image": return load("res://game_default/packs_menu/The Choicer Voicer's Default Menu/unseen_image.png").get_image()
		&"no_image": return load("res://game_default/packs_menu/The Choicer Voicer's Default Menu/no_image.png").get_image()
		_:
			return null


func _init():
	oveep = local_oveep
	set_pack = local_set_pack
	config = config_menu


func get_image(img: Image, resize: = Vector2i.ZERO, interpolation: = Image.INTERPOLATE_LANCZOS) -> ImageTexture:
	var img_copy: = img.duplicate(true)
	if resize:
		img_copy.resize(resize.x, resize.y, interpolation)
	return ImageTexture.create_from_image(img_copy)


func refresh():
	M.SetupButtonsAndLetterbox(config)
