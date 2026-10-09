extends Node

enum CLIP_LOCATIONS{NONE, VOICE, DUB}
enum CLIP_USES{NONE, VOICE, DUB, EDITING}

enum OVEEP{NONE, HOST, JUDGES, MENU, STUDIO, VOICE, TWITCH, PLAYER}
enum PERSONALIZER{NONE, MENU, CONTESTANT, STUDIO, JUDGES, HOST, VOICE, CHATTER}
const THISISDEMO: bool = false


const THISISCOMPATIBILITY: bool = false


const GAME_VERSION: String = "0.5.3"

var world: Node:
	get: return get_tree().get_root().get_node("World")


var uc: = UC.new()
var bus_master: = BusMaster.new()
var menu_pack: = MenuModPack.new()


func _ready():

	add_child(uc)

	LoadData()
	LoadConfigs()

	menu_pack.set_pack.call(data.custom.menu)


	if data.player.first_time:
		PrewriteTutorial()


	add_child(bus_master)


	bus_master.crust_enabled(data.settings.mic.crust)
	bus_master.crust_settings(data.settings.mic.crust)
	AssignAndAddSfx()
	SetupAudio()


	SetupButtonsAndLetterbox(config.menu)







	get_tree().root.move_to_center()
	_send_neocities_http_request()


func ExitGame():
	get_tree().get_root().get_node("World").ExitGame()



const SAVEPATH: String = "user://game/saves/save.json"
func LoadData() -> bool:
	if FileAccess.file_exists(SAVEPATH):
		var file = FileAccess.open(SAVEPATH, FileAccess.READ)
		if file == null:

			print("M | Save file does not exist.")
			return false
		var load_data: Dictionary = {}
		var check_load: Variant = JSON.parse_string(file.get_as_text())
		if typeof(check_load) == TYPE_DICTIONARY:
			load_data = check_load
		file.close()
		if load_data.is_empty():

			print("M | Save loading failed. The file is not in a valid format.")
			return false
		else:



			data = load_data
			print("M | Data successfully loaded.")
			return true

	print("M | Save file not found. Using new default profile.")
	data = {}
	return false


func SaveData():

	var file = FileAccess.open(SAVEPATH, FileAccess.WRITE)
	if file == null:
		print("M | File saving failed. UNKNOWN ERROR.")
		return
	var data_strung: String = JSON.stringify(data, "\t")
	file.store_string(data_strung)
	file.close()
	print("M | Data successfully saved.")


func LoadConfigs():
	config.host = uc.get_json(OVEEP.HOST, "config_host")
	config.judges = uc.get_json(OVEEP.JUDGES, "config_judges")
	config.menu = uc.get_json(OVEEP.MENU, "config_menu")
	config.studio = uc.get_json(OVEEP.STUDIO, "config_studio")
	config.player = uc.get_json(OVEEP.PLAYER, "config_player")

func PrewriteTutorial():
	DirAccess.make_dir_absolute("user://game/packs_voice/The Choicer Voicer Tutorial Pack/")
	uc.populate_from_defaults("res://game_default/packs_voice/The Choicer Voicer Tutorial Pack/", "user://game/packs_voice/The Choicer Voicer Tutorial Pack/")



func ShowActivityHint(do: bool, text: String = "Saving", block_mouse: bool = true):
	if do: get_tree().get_root().get_node("World").ActiveHint(true, text, block_mouse)
	else: get_tree().get_root().get_node("World").ActiveHint(false, text)



var button_profile_standard: ButtonProfile
var button_profile_back: ButtonProfile
var button_profile_invis: ButtonProfile
var button_profile_small: ButtonProfile
var button_profile_bubble: ButtonProfile
var button_profile_add_player: ButtonProfile

func SetupButtonsAndLetterbox(menu_con: Dictionary):
	ChangeButtonProfiles(menu_con.ui)
	ChangeLetterboxColor(menu_con.background.letterbox)


func ChangeButtonProfiles(ui: Dictionary):
	button_profile_standard = load("res://graphic/button_profile/standard.tres").duplicate(true)
	button_profile_back = load("res://graphic/button_profile/back.tres").duplicate(true)
	button_profile_invis = load("res://graphic/button_profile/invis.tres").duplicate(true)
	button_profile_small = load("res://graphic/button_profile/small.tres").duplicate(true)
	button_profile_bubble = load("res://graphic/button_profile/bubble.tres").duplicate(true)
	button_profile_add_player = load("res://graphic/button_profile/add_player.tres").duplicate(true)
	for profile: ButtonProfile in [button_profile_standard, button_profile_back, button_profile_small, button_profile_invis, button_profile_bubble, button_profile_add_player]:
		profile.ChangeColorNeo(ui.button)






var letterbox_swatch: GradientTexture2D = load("res://graphic/gradient/letterbox.tres")
func ChangeLetterboxColor(letterbox: Dictionary):
	for i in letterbox_swatch.gradient.colors.size():
		match i:
			2, 3:
				letterbox_swatch.gradient.set_color(i, Color(letterbox.accent))
			1, 4:
				letterbox_swatch.gradient.set_color(i, Color("d1d1d1") * Color(letterbox.color))
			0, 5:
				letterbox_swatch.gradient.set_color(i, Color(letterbox.color))




func SetupAudio():
	var selection_text: String = data.settings.mic.devices.audio_in
	if AudioServer.get_input_device_list().has(selection_text): AudioServer.set_input_device(selection_text)
	selection_text = data.settings.mic.devices.audio_out
	if AudioServer.get_output_device_list().has(selection_text): AudioServer.set_output_device(selection_text)



func VolumeMusicAudienceStandard(to_db: float, time: float):
	printerr("M | Method `VolumeMusicAudienceStandard` was called despite being deprecated. Rerouting to VolumeService.")
	VolumeService.tween_volume_music(db_to_linear(clampf(to_db, -12, 0)), time)



@onready var sfx_hover: = AudioStreamPlayer.new()
@onready var sfx_back: = AudioStreamPlayer.new()
@onready var sfx_decrease: = AudioStreamPlayer.new()
@onready var sfx_select: = AudioStreamPlayer.new()


func AssignSfx():
	sfx_hover.stream = uc.get_audio(OVEEP.MENU, "button_sfx_hover", true)
	sfx_back.stream = uc.get_audio(OVEEP.MENU, "button_sfx_back", true)
	sfx_decrease.stream = uc.get_audio(OVEEP.MENU, "button_sfx_decrease", true)
	sfx_select.stream = uc.get_audio(OVEEP.MENU, "button_sfx_select", true)


func AssignAndAddSfx():
	AssignSfx()

	sfx_hover.bus = "SfxButton"
	sfx_back.bus = "SfxButton"
	sfx_decrease.bus = "SfxButton"
	sfx_select.bus = "SfxButton"

	add_child(sfx_hover)
	add_child(sfx_back)
	add_child(sfx_decrease)
	add_child(sfx_select)




var unbound: bool = false
var code: String = ""
var oil: bool = false


func _input(event):







	if event is InputEventKey:
		if OS.is_keycode_unicode(event.keycode) and event.pressed and (event.keycode < 91) and (event.keycode > 47):
			code += OS.get_keycode_string(event.keycode)
			code = code.right(16)

			ParseSecrets()


func ParseSecrets():
	if code.right(6) == "MAYAKA":
		if not unbound:
			print("M | Secret: Unbound on")
			unbound = true
			get_tree().call_group("UnboundReceiver", "Unbounded")
			QuickAudioPlay("res://audio/sfx/cv_unbound_f.wav")
	if code.right(7) == "HEYPOPS":
		oil = not oil
		bus_master.oil(oil)
		QuickAudioPlay("res://audio/sfx/cv_unbound_f.wav")


func QuickAudioPlay(path: String):
	var temp_stream: = AudioStreamPlayer.new()
	add_child(temp_stream)
	temp_stream.stream = load(path)
	temp_stream.play()
	await temp_stream.finished
	temp_stream.queue_free()


const ILLEGALCHARACTERS: String = "/\\*\"<>:|?"
func SanitizeText(text: String) -> String:
	breakpoint
	var output_string: String = ""
	for character in text:
		pass
	return output_string





enum SESSION_TYPE{NONE, STANDARD, STANDARD_JABRONI, TWITCH, AUDITION, VIDEO_DUB, TWITCH_PANEL, DUB_FREESTYLE}
var session_type: SESSION_TYPE


var config: Dictionary = {
	"host": {}, 
	"judges": {}, 
	"menu": {}, 
	"studio": {}, 
	"player": {}
}

var data: Dictionary = {}: set = _set_data, get = _get_data

func _get_data() -> Dictionary: return Profile.export_data()
func _set_data(value: Dictionary) -> void : Profile.import_data(value)





const URL: String = "https://thechoicervoicer.neocities.org/data/update_history.json"
var newer_versions: Array[Dictionary] = []
var http_request: HTTPRequest:
	get:
		if !http_request:
			http_request = HTTPRequest.new()
			add_child(http_request)
		return http_request


func _send_neocities_http_request() -> void :
	if !http_request.request_completed.is_connected(_neocities_request): http_request.request_completed.connect(_neocities_request)
	var headers: PackedStringArray = ["Content-Type: application/json"]
	var error: Error = http_request.request(URL, headers, HTTPClient.METHOD_GET)
	print(error_string(error))
func _neocities_request(results: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void :
	print("M | HTTP request completed.")
	var parsed_json = JSON.parse_string(body.get_string_from_utf8())
	if !parsed_json:
		printerr("M | HTTP request failed to parse.")
		return
	var json: Dictionary = type_convert(parsed_json, TYPE_DICTIONARY) as Dictionary
	var versions: Array = json.get_or_add("version_history", {}).get_or_add("versions", [])
	for i: int in versions.size():
		var version: Dictionary = type_convert(versions[i], TYPE_DICTIONARY) as Dictionary
		if version_is_newer(version.get("version", "")): newer_versions.append(version)
func version_is_newer(version: String) -> bool:
	if !version: return false
	var compare_version: Array[int] = version_to_array(version)
	var own_version: Array[int] = version_to_array(GAME_VERSION)
	for i: int in range(4):
		if compare_version[i] > own_version[i]:
			return true
	return false
func version_to_array(version: String) -> Array[int]:
	var four_numbers: Array[int] = [0, 0, 0, 0]
	var split: PackedStringArray = version.split(".", true)
	split.resize(4)
	for i: int in range(4): four_numbers[i] = int(split[i])
	return four_numbers
