extends MenuBase

@onready var _info_gs: VBoxContainer = %"[Info]StandardGameshow"
@onready var _info_dm: VBoxContainer = %"[Info]DubModeMinigame"
@onready var _info_df: VBoxContainer = %"[Info]DubModeFreestyle"
@onready var _info_ts: VBoxContainer = %"[Info]TwitchGameshow"
@onready var _info_tp: VBoxContainer = %"[Info]TwitchPanelists"
@onready var button_array_nxt: ButtonArray = %ButtonArrayNxt


func _mode_selected_standard_gameshow() -> void : M.session_type = M.SESSION_TYPE.STANDARD;call_slide("res://scenes/nav_specific/clip_selector_menus/clip_selection_standard.tscn", false)
func _mode_selected_dub() -> void : M.session_type = M.SESSION_TYPE.VIDEO_DUB;call_slide("res://scenes/nav_specific/clip_selector_menus/clip_selection_dub.tscn", false)
func _mode_selected_dub_free() -> void : M.session_type = M.SESSION_TYPE.DUB_FREESTYLE;call_slide("res://scenes/nav_specific/clip_selector_menus/clip_selection_dub.tscn", false)
func _mode_selected_twitch_standard() -> void : M.session_type = M.SESSION_TYPE.TWITCH;call_slide("res://scenes/nav_specific/clip_selector_menus/clip_selection_standard.tscn", false)
func _mode_selected_twitch_panelist() -> void : M.session_type = M.SESSION_TYPE.TWITCH_PANEL;call_slide("res://scenes/nav_specific/play_flow/choose_panelists.tscn", false)

func _hide_all_except(input: VBoxContainer) -> void : for info: VBoxContainer in [_info_gs, _info_dm, _info_df, _info_ts, _info_tp]: info.visible = (info == input)
func _visuals_to(input: VBoxContainer, index: int) -> void : _hide_all_except(input);button_array_nxt.reparent_outline(index)

func _show_standard(_a: String) -> void : _visuals_to(_info_gs, 0)
func _show_dub_mode(_a: String) -> void : _visuals_to(_info_dm, 2)
func _show_dub_freestyle(_a: String) -> void : _visuals_to(_info_df, 3)
func _show_twitch(_a: String) -> void : _visuals_to(_info_ts, 5)
func _show_twitch_panelists(_a: String) -> void : _visuals_to(_info_tp, 6)


func _ready() -> void : _show_standard("")
