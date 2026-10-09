extends Control

@onready var slide_capsule = $SlideCapsule
@onready var slide_hint_path = $MenuSlideHint

@onready var btn_back: ButtonCV = $BottomButtons / BtnBack
@onready var btn_discard_return: ButtonCV = $BottomButtons / BtnDiscardReturn
@onready var btn_save_return: ButtonCV = $BottomButtons / BtnSaveReturn
@onready var btn_exit: ButtonCV = $BottomButtons / ExitButtonContainer / BtnExitGame
@onready var btn_options: ButtonCV = %BtnOptions

@onready var version: Label = %Version

@onready var loading_capsule = $LoadingCapsule
@onready var music: AudioStreamPlayer

@onready var uc: = UC.new()
var stream_is_ogg: bool = false
var previous_music_hash: int = 0






var start_from_slide: String = "home/menu_home"
var stopgap_ignore_standard_instruction: bool = false

var same_lobby: Dictionary = {
	"do": false, 
	"lobby": []
}


func _ready():
	version.text = "Early Access Version " + M.GAME_VERSION
	if M.THISISCOMPATIBILITY: version.text += "\nCompatibility Mode"
	add_child(uc)
	if !stopgap_ignore_standard_instruction: NewSlide(start_from_slide)
	stopgap_ignore_standard_instruction = false
	UpdateMusic()


func NewSlide(path: String, assume_path: bool = true):
	if assume_path: path = "res://scene/menu/" + path + ".tscn"
	if slide_capsule: for el: Node in slide_capsule.get_children(): el.queue_free()
	var current_slide: Control = load(path).instantiate()
	match current_slide.menu_data.type:
		MenuData.SLIDETYPE.NORMAL:
			btn_exit.visible = false
			btn_back.visible = true
			btn_discard_return.visible = false
			btn_save_return.visible = false
			btn_options.hide()
		MenuData.SLIDETYPE.HOME:
			btn_exit.visible = true
			btn_back.visible = false
			btn_discard_return.visible = false
			btn_save_return.visible = false
			btn_options.hide()
		MenuData.SLIDETYPE.SETTINGS:
			btn_exit.visible = false
			btn_back.visible = false
			btn_discard_return.visible = true
			btn_save_return.visible = true
			btn_options.hide()
		MenuData.SLIDETYPE.HAS_OPTIONS:
			btn_exit.hide();btn_discard_return.hide();btn_save_return.hide()
			btn_back.show();btn_options.show()
	for menu_path: String in current_slide.menu_data.slide_hint:
		pass
	for i: int in current_slide.menu_data.slide_hint.size():
		match current_slide.menu_data.slide_hint[i]:
			"&soloOrGroup": current_slide.menu_data.slide_hint[i] = "Solo" if Metro.current_players.size() == 1 else "Group"
			"&specificMode":
				match M.session_type:
					M.SESSION_TYPE.STANDARD: current_slide.menu_data.slide_hint[i] = "Standard"
					M.SESSION_TYPE.TWITCH: current_slide.menu_data.slide_hint[i] = "Twitch Audience"
					M.SESSION_TYPE.TWITCH_PANEL: current_slide.menu_data.slide_hint[i] = "Twitch Panel"
					M.SESSION_TYPE.VIDEO_DUB: current_slide.menu_data.slide_hint[i] = "Dub Mode"
					M.SESSION_TYPE.DUB_FREESTYLE: current_slide.menu_data.slide_hint[i] = "Freestyle Dub Mode"
	slide_hint_path.SetSlides(current_slide.menu_data.slide_hint)
	slide_capsule.add_child(current_slide)

	if same_lobby.do:
		current_slide.SameLobby(same_lobby.lobby)
		same_lobby.do = false
		same_lobby.lobby.clear()


func UpdateMusic():
	if music.stream: previous_music_hash = MusicHash(music.stream)
	else: previous_music_hash = -1

	var new_music: AudioStream = ProxyMiddlemanMenu.music
	if new_music is AudioStreamWAV:
		if new_music.loop_begin == 0:
			new_music.loop_mode = AudioStreamWAV.LOOP_FORWARD
			new_music.loop_begin = uc.get_json(M.OVEEP.MENU, "config_menu").audio.music_menu_loop_start
	elif new_music is AudioStreamMP3 or new_music is AudioStreamOggVorbis:
		new_music.loop = true
		if new_music.loop_offset == 0.0: new_music.loop_offset = uc.get_json(M.OVEEP.MENU, "config_menu").audio.music_menu_loop_start

	if new_music == null: new_music = load("res://audio/music/cartridge_loop.wav")
	var new_hash: int
	if new_music: new_hash = MusicHash(new_music)
	else: new_hash = 0
	print("MenuMaster | Music change hash comparison: %s vs %s" % [previous_music_hash, new_hash])
	if new_hash != previous_music_hash:
		music.stream = new_music
		music.play()
	previous_music_hash = new_hash


func MusicHash(audio: AudioStream) -> int:
	if (audio is AudioStreamWAV) or (audio is AudioStreamMP3): return hash(audio.data)
	elif (audio is AudioStreamOggVorbis): return hash(audio)
	else: print("MenuMaster | Unrecognized audio type hash attempt");return -1


func LoadingScreen(on: bool, text: String = "Loading"):
	if on:
		var lo: Control = load("res://scene/menu/modules/please_wait_overlay.tscn").instantiate()
		lo.text = text
		for child in loading_capsule.get_children(): child.queue_free()
		loading_capsule.add_child(lo)
	else: for child in loading_capsule.get_children(): child.Reduce()


func _on_music_finished():
	if music.stream:

		if (music.stream is AudioStreamWAV): if !music.stream.data.is_empty(): music.play();print("MenuMaster | Replay music; not empty WAV")
		else: music.play();print("MenuMaster | Replay music; not WAV")


func _on_btn_exit_game_button_clicked():
	M.SaveData()
	M.ExitGame()


func new_slide_from_data() -> void :
	var menu_data: MenuData = slide_capsule.get_child(0).menu_data
	NewSlide(menu_data.back_path, menu_data.assume_path)


func _on_btn_back_button_clicked():
	get_tree().call_group("OnBack", "BackButtonPressed")
	new_slide_from_data()


func _on_btn_discard_return_button_clicked():
	get_tree().call_group("OnBack", "ReturnDiscard")
	new_slide_from_data()


func _on_btn_save_return_button_clicked():
	get_tree().call_group("OnBack", "ReturnSave")
	new_slide_from_data()


func _options_button_pressed() -> void :
	get_tree().call_group("MenuWithOptions", "options_up")


func _on_modular_background_music_toggle(toggle_on: bool) -> void :
	if music == null: music = %Music; await get_tree().process_frame
	if toggle_on:
		if !music.playing: music.play()
	else: music.stop()
