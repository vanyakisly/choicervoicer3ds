class_name LegacyPlayerTile extends ColorRect

signal kill(idx: int)
signal move(from: int, to: int)

@onready var option_player_packs = %OptionPlayerPacks
@onready var option_input_devices = %OptionInputDevices
@onready var lbl_player_idx = %LblPlayerIdx

var player_index: int = 0:
	set(value):
		player_index = value
		lbl_player_idx.text = "P%s" % (player_index + 1)

var pack_name: String = ""
var input_device: String = ""


func _ready():
	GetPlayers()
	GetAudioDevices()


func GetPlayers():
	var player_pack_list = DirAccess.get_directories_at("user://game/packs_player/")

	option_player_packs.add_item("Default")
	option_player_packs.set_item_metadata(0, "Default")


	for idx in player_pack_list.size():
		option_player_packs.add_item(player_pack_list[idx])
		option_player_packs.set_item_metadata(idx + 1, player_pack_list[idx])
		if pack_name != "":
			if player_pack_list[idx] == pack_name:
				option_player_packs.select(idx + 1)
		else:
			if player_pack_list[idx] == M.data.custom.player:
				option_player_packs.select(idx + 1)
				pack_name = option_player_packs.get_selected_metadata()

func GetAudioDevices():
	var audio_input_list = AudioServer.get_input_device_list()
	for idx in audio_input_list.size():
		option_input_devices.add_item(audio_input_list[idx], idx)
		option_input_devices.set_item_metadata(idx, audio_input_list[idx])
		if input_device != "":
			if audio_input_list[idx] == input_device:
				option_input_devices.select(idx)
		else:
			if audio_input_list[idx] == M.data.settings.mic.devices.audio_in:
				option_input_devices.select(idx)
				input_device = option_input_devices.get_selected_metadata()


func _on_btn_kill_button_clicked():
	kill.emit(player_index)


func _on_btn_moveup_button_clicked():
	move.emit(player_index, player_index - 1)


func _on_btn_movedown_button_clicked():
	move.emit(player_index, player_index + 1)


func _on_option_player_packs_item_selected(_index):
	pack_name = option_player_packs.get_selected_metadata()


func _on_option_input_devices_item_selected(_index):
	input_device = option_input_devices.get_selected_metadata()
