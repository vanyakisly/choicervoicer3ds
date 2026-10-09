extends Control


enum ERB{VCLIP, P1, P1B, P2, P2B, P3, P3B, P4, P4B, FINISH, EVERYONE, LOBBY}


signal button_index(idx: ERB)
signal finished
signal skip
signal save_conte(idx: int)
signal match_menu_closed
signal match_menu_opened

@onready var end_round_options = %EndRoundOptions
@onready var match_menu = %MatchMenu
@onready var menu_on_open = %MenuOnOpen
@onready var exit_confirmation = %ExitConfirmation

@onready var btn_open_menu = %BtnOpenMenu
@onready var btn_skip = %BtnSkip

@onready var lbl_next_round_button = %LblNextRoundButton

@onready var player_replay_single = %PlayerReplaySingle
@onready var player_replay_1 = %PlayerReplay1
@onready var player_replay_2 = %PlayerReplay2
@onready var player_replay_3 = %PlayerReplay3
@onready var player_replay_4 = %PlayerReplay4

@onready var btn_save_single = %BtnSaveSingle
@onready var btn_save_1 = %BtnSave1
@onready var btn_save_2 = %BtnSave2
@onready var btn_save_3 = %BtnSave3
@onready var btn_save_4 = %BtnSave4
@onready var btn_play_everyone = %BtnPlayEveryone
@onready var btn_toggle_saves = %BtnToggleSaves

@onready var btn_lobby_same_players = %BtnLobbySamePlayers


var theseus_volume: Dictionary = M.data.settings.volume.duplicate(true)



















func _ready():
	end_round_options.visible = false
	match_menu.visible = false
	btn_toggle_saves.visible = false
	ShowSaveButtons(false)


func ShowReplaysViaPlayers(player_count: int):
	if player_count == 1:
		player_replay_1.visible = false
		player_replay_2.visible = false
		player_replay_3.visible = false
		player_replay_4.visible = false
		btn_play_everyone.visible = false
	else:
		player_replay_single.visible = false
		player_replay_3.visible = (player_count > 2)
		player_replay_4.visible = (player_count > 3)


func ShowSaveButtons(do: bool):
	btn_save_single.visible = do
	btn_save_1.visible = do
	btn_save_2.visible = do
	btn_save_3.visible = do
	btn_save_4.visible = do


func _on_btn_back_to_match_button_clicked():
	match_menu.visible = false
	await get_tree().process_frame
	match_menu_closed.emit()


func _on_btn_exit_to_menu_button_clicked():
	menu_on_open.visible = false
	exit_confirmation.visible = true


func _on_btn_exit_no_button_clicked():
	menu_on_open.visible = true
	exit_confirmation.visible = false


func _on_btn_open_menu_button_clicked():
	match_menu.visible = true
	match_menu_opened.emit()


func _on_btn_skip_button_clicked():
	skip.emit()


func _on_btn_exit_yes_button_clicked():
	M.data.settings.volume = theseus_volume
	get_tree().get_root().get_node("World").CreateMenu()



func _on_btn_play_clip_button_clicked():
	button_index.emit(ERB.VCLIP)

func _on_btn_play_con_only_1_button_clicked():
	button_index.emit(ERB.P1)

func _on_btn_play_con_and_clip_1_button_clicked():
	button_index.emit(ERB.P1B)

func _on_btn_play_con_only_2_button_clicked():
	button_index.emit(ERB.P2)

func _on_btn_play_con_and_clip_2_button_clicked():
	button_index.emit(ERB.P2B)

func _on_btn_play_con_only_3_button_clicked():
	button_index.emit(ERB.P3)

func _on_btn_play_con_and_clip_3_button_clicked():
	button_index.emit(ERB.P3B)

func _on_btn_play_con_only_4_button_clicked():
	button_index.emit(ERB.P4)

func _on_btn_play_con_and_clip_4_button_clicked():
	button_index.emit(ERB.P4B)

func _on_btn_next_round_button_clicked():
	button_index.emit(ERB.FINISH)

func _on_btn_play_everyone_button_clicked():
	button_index.emit(ERB.EVERYONE)

func _on_btn_lobby_same_players_button_clicked():
	button_index.emit(ERB.LOBBY)

func _on_btn_toggle_saves_button_clicked():
	ShowSaveButtons( not btn_save_single.visible)


signal preserve_performance
func _on_btn_test_preserve_button_clicked():
	DirAccess.make_dir_absolute("user://game/TESTING/")
	DirAccess.make_dir_absolute("user://game/TESTING/scoring_algo/")
	preserve_performance.emit()


func _on_btn_save_single_button_clicked():
	save_conte.emit(0)

func _on_btn_save_1_button_clicked():
	save_conte.emit(0)

func _on_btn_save_2_button_clicked():
	save_conte.emit(1)

func _on_btn_save_3_button_clicked():
	save_conte.emit(2)

func _on_btn_save_4_button_clicked():
	save_conte.emit(3)

func HideSaveButtons():
	btn_save_1.visible = false
	btn_save_2.visible = false
	btn_save_3.visible = false
	btn_save_4.visible = false


func ButtonsVisibility(menu_btn_vis: bool, skip_vis: bool, end_round_options_vis: bool, mini_save_buttons_vis: bool = false, contestant_count: int = 1):
	if btn_open_menu.visible != menu_btn_vis: btn_open_menu.visible = menu_btn_vis
	if btn_skip.visible != skip_vis: btn_skip.visible = skip_vis
	if end_round_options.visible != end_round_options_vis: end_round_options.visible = end_round_options_vis
	if btn_toggle_saves.visible != end_round_options_vis: btn_toggle_saves.visible = end_round_options_vis
	if end_round_options_vis:
		player_replay_single.visible = (contestant_count == 1)
		btn_play_everyone.visible = (contestant_count > 1)
		player_replay_1.visible = (contestant_count > 1)
		player_replay_2.visible = (contestant_count > 1)
		player_replay_3.visible = (contestant_count > 2)
		player_replay_4.visible = (contestant_count > 3)
		if contestant_count == 1:
			if btn_save_single.visible != mini_save_buttons_vis: btn_save_single.visible = mini_save_buttons_vis
			btn_save_1.visible = false
			btn_save_2.visible = false
			btn_save_3.visible = false
			btn_save_4.visible = false
		else:
			btn_save_single.visible = false
			btn_save_1.visible = (mini_save_buttons_vis)
			btn_save_2.visible = (mini_save_buttons_vis)
			btn_save_3.visible = (mini_save_buttons_vis and contestant_count > 2)
			btn_save_4.visible = (mini_save_buttons_vis and contestant_count > 3)




func ChangeVolume():
	M.bus_master.load_van_volumes_from(theseus_volume)
	M.bus_master.apply_all_vans_to_buses()

func _on_slider_master_vol_value_changed(value):
	theseus_volume.master = value
	ChangeVolume()

func _on_slider_music_vol_value_changed(value):
	theseus_volume.music = value
	ChangeVolume()

func _on_slider_button_vol_value_changed(value):
	theseus_volume.button_sounds = value
	ChangeVolume()

func _on_slider_sfx_vol_value_changed(value):
	theseus_volume.sound_effects = value
	ChangeVolume()

func _on_slider_playback_vol_value_changed(value):
	theseus_volume.clip_playback = value
	ChangeVolume()
