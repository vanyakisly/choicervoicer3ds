class_name MemberMenuTile extends ColorRect
@onready var contestant_view: TextureRect = %ContestantView
@onready var btn_kill: ButtonCV = %BtnKill
@onready var dropdown_packs: OptionButton = %DropdownPacks
@onready var dropdown_audio_devices: OptionButton = %DropdownAudioDevices
@export var kill_button_visible: bool = true: set = _set_kill_button_visible
var contestant_pack_name: String: set = _set_contestant_pack_name
var audio_device: String: get = _get_audio_device

func _setup_dropdown_packs() -> void :
	dropdown_packs.add_item("Default", 0);dropdown_packs.set_item_metadata(0, "/default")
	var packs_list: PackedStringArray = DirAccess.get_directories_at(FileManager.MODPACKS_CONTESTANT)
	for idx: int in packs_list.size():
		if packs_list[idx] == "Default": continue
		var offset_index: int = idx + 1
		dropdown_packs.add_item(packs_list[idx], offset_index)
		dropdown_packs.set_item_metadata(offset_index, packs_list[idx])
func _setup_dropdown_audio_devices() -> void :
	var device_list: PackedStringArray = AudioServer.get_input_device_list()
	for idx: int in device_list.size():
		dropdown_audio_devices.add_item(device_list[idx], idx)
		dropdown_audio_devices.set_item_metadata(idx, device_list[idx])
		if device_list[idx] == Profile.audio_device_in: dropdown_audio_devices.select(idx)

func assign_contestant_pack(pack_name: String) -> void :
	if !pack_name.ends_with("/"): pack_name += "/"
	if pack_name == "/default": contestant_view.texture = preload("res://game_default/packs_player/Player/player.png");return
	var image_file_path: String = FileManager.MODPACKS_CONTESTANT + pack_name + "player"
	var contestant_texture: Texture2D = VD.get_texture_agnostic(image_file_path, true)
	contestant_view.texture = contestant_texture

func _kill_self() -> void : queue_free()

func _dropdown_pack_selected(_dummy: int) -> void : contestant_pack_name = dropdown_packs.get_selected_metadata()

func _set_kill_button_visible(value: bool) -> void : kill_button_visible = value; if is_node_ready(): btn_kill.visible = kill_button_visible
func _set_contestant_pack_name(value: String) -> void : contestant_pack_name = value;assign_contestant_pack(contestant_pack_name)

func _get_audio_device() -> String:
	var midman: String = dropdown_audio_devices.get_selected_metadata()
	if AudioServer.get_input_device_list().has(midman): return midman
	else: return "Default"

func _ready() -> void :
	_set_kill_button_visible(kill_button_visible)
	_setup_dropdown_packs()
	_setup_dropdown_audio_devices()
