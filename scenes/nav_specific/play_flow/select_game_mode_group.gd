extends MenuBase

@onready var mode_list_standard: VBoxContainer = %"[ModeList] STANDARD"
@onready var mode_list_minigames: VBoxContainer = %"[ModeList] MINIGAMES"
@onready var mode_list_twitch: VBoxContainer = %"[ModeList] TWITCH"

@onready var game_mode_info: Control = %GameModeInfo
@onready var info_standard_gameshow: ScrollContainer = %InfoStandardGameshow
@onready var info_dub_mode: ScrollContainer = %InfoDubMode
@onready var info_twitch_standard: ScrollContainer = %InfoTwitchStandard

func _show_modes_standard() -> void : mode_list_standard.show();mode_list_minigames.hide();mode_list_twitch.hide()
func _show_modes_minigame() -> void : mode_list_standard.hide();mode_list_minigames.show();mode_list_twitch.hide()
func _show_modes_twitch__() -> void : mode_list_standard.hide();mode_list_minigames.hide();mode_list_twitch.show()
func _on_game_types_bar_selection(index: int) -> void :
	match index:
		0: _show_modes_standard()
		1: _show_modes_minigame()
		2: _show_modes_twitch__()

func _hide_all_mode_info_pages() -> void : for page: Control in game_mode_info.get_children(): page.hide()
func _show_page_standard_gameshow(_d: String) -> void : _hide_all_mode_info_pages();info_standard_gameshow.show()
func _show_page_dub_mode(_d: String) -> void : _hide_all_mode_info_pages();info_dub_mode.show()
func _show_page_twitch_standard(_d: String) -> void : _hide_all_mode_info_pages();info_twitch_standard.show()

func _mode_selected_standard_gameshow() -> void : M.session_type = M.SESSION_TYPE.STANDARD;call_slide("res://scenes/nav_specific/clip_selector_menus/clip_selection_standard.tscn", false)
func _mode_selected_dub() -> void : pass
func _mode_selected_twitch_standard() -> void : M.session_type = M.SESSION_TYPE.TWITCH;call_slide("res://scenes/nav_specific/clip_selector_menus/clip_selection_standard.tscn", false)

func _ready() -> void : _show_modes_standard();_hide_all_mode_info_pages();info_standard_gameshow.show()


@onready var _info_standard_gameshow: VBoxContainer = %"[Info]StandardGameshow"
@onready var _info_dub_mode_minigame: VBoxContainer = %"[Info]DubModeMinigame"
@onready var _info_twitch_gameshow: VBoxContainer = %"[Info]TwitchGameshow"
@onready var button_array_nxt: ButtonArray = %ButtonArrayNxt

func _show_standard(_a: String) -> void : _info_standard_gameshow.show();_info_dub_mode_minigame.hide();_info_twitch_gameshow.hide();button_array_nxt.reparent_outline(0)
func _show_dub_mode(_a: String) -> void : _info_standard_gameshow.hide();_info_dub_mode_minigame.show();_info_twitch_gameshow.hide();button_array_nxt.reparent_outline(1)
func _show_twitch(_a: String) -> void : _info_standard_gameshow.hide();_info_dub_mode_minigame.hide();_info_twitch_gameshow.show();button_array_nxt.reparent_outline(2)
