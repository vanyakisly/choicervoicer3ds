extends Node


const BACKGROUND: Texture2D = preload("res://game_default/packs_menu/The Choicer Voicer's Default Menu/background.png")
const BUTTON_SFX_BACK: AudioStream = preload("res://game_default/packs_menu/The Choicer Voicer's Default Menu/button_sfx_back.wav")
const BUTTON_SFX_DECREASE: AudioStream = preload("res://game_default/packs_menu/The Choicer Voicer's Default Menu/button_sfx_decrease.wav")
const BUTTON_SFX_HOVER: AudioStream = preload("res://game_default/packs_menu/The Choicer Voicer's Default Menu/button_sfx_hover.wav")
const BUTTON_SFX_SELECT: AudioStream = preload("res://game_default/packs_menu/The Choicer Voicer's Default Menu/button_sfx_select.wav")
const NO_IMAGE: Texture2D = preload("res://game_default/packs_menu/The Choicer Voicer's Default Menu/no_image.png")
const UNSEEN_IMAGE: Texture2D = preload("res://game_default/packs_menu/The Choicer Voicer's Default Menu/unseen_image.png")
const CONFIG_MENU: JSON = preload("res://game_default/packs_menu/The Choicer Voicer's Default Menu/config_menu.json")
const CARTRIDGE_LOOP = preload("res://audio/music/cartridge_loop.wav")


@export var background: Texture2D: get = _get_background
@export var button_sfx_back: AudioStream: get = _get_button_sfx_back
@export var button_sfx_decrease: AudioStream: get = _get_button_sfx_decrease
@export var button_sfx_hover: AudioStream: get = _get_button_sfx_hover
@export var button_sfx_select: AudioStream: get = _get_button_sfx_select
@export var no_image: Texture2D: get = _get_no_image
@export var unseen_image: Texture2D: get = _get_unseen_image
@export var music: AudioStream: get = _get_music


func _get_background() -> Texture2D: return background if background else BACKGROUND
func _get_button_sfx_back() -> AudioStream: return button_sfx_back if button_sfx_back else BUTTON_SFX_BACK
func _get_button_sfx_decrease() -> AudioStream: return button_sfx_decrease if button_sfx_decrease else BUTTON_SFX_DECREASE
func _get_button_sfx_hover() -> AudioStream: return button_sfx_hover if button_sfx_hover else BUTTON_SFX_HOVER
func _get_button_sfx_select() -> AudioStream: return button_sfx_select if button_sfx_select else BUTTON_SFX_SELECT
func _get_no_image() -> Texture2D: return no_image if no_image else NO_IMAGE
func _get_unseen_image() -> Texture2D: return unseen_image if unseen_image else UNSEEN_IMAGE
func _get_music() -> AudioStream: return music if music else CARTRIDGE_LOOP

func _ready() -> void :
	update()
	Profile.changed_menu.connect(update)


func update() -> void :
	background = VD.get_texture_agnostic(FileManager.MODPACKS_MENU + Profile.menu_slash + "background")
	button_sfx_back = VD.get_audio_agnositc(FileManager.MODPACKS_MENU + Profile.menu_slash + "button_sfx_back")
	button_sfx_decrease = VD.get_audio_agnositc(FileManager.MODPACKS_MENU + Profile.menu_slash + "button_sfx_decrease")
	button_sfx_hover = VD.get_audio_agnositc(FileManager.MODPACKS_MENU + Profile.menu_slash + "button_sfx_hover")
	button_sfx_select = VD.get_audio_agnositc(FileManager.MODPACKS_MENU + Profile.menu_slash + "button_sfx_select")
	no_image = VD.get_texture_agnostic(FileManager.MODPACKS_MENU + Profile.menu_slash + "no_image")
	unseen_image = VD.get_texture_agnostic(FileManager.MODPACKS_MENU + Profile.menu_slash + "unseen_image")
	music = VD.get_audio_agnositc(FileManager.MODPACKS_MENU + Profile.menu_slash + "music_menu")
