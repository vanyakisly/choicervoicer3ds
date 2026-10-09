extends MenuBase


const JUDGE_1 = preload("res://game_default/packs_judges/The Choicer Voicer's Default Judges/judge1.png")


@onready var judge_view_1: TextureRect = %JudgeView1
@onready var judge_view_2: TextureRect = %JudgeView2
@onready var judge_view_3: TextureRect = %JudgeView3
@onready var judge_view_4: TextureRect = %JudgeView4
@onready var judge_view_5: TextureRect = %JudgeView5
@onready var lbl_name_1: Label = %LblName1
@onready var lbl_name_2: Label = %LblName2
@onready var lbl_name_3: Label = %LblName3
@onready var lbl_name_4: Label = %LblName4
@onready var lbl_name_5: Label = %LblName5
@onready var line_panelist_name_1: LineEdit = %LinePanelistName1
@onready var line_panelist_name_2: LineEdit = %LinePanelistName2
@onready var line_panelist_name_3: LineEdit = %LinePanelistName3
@onready var line_panelist_name_4: LineEdit = %LinePanelistName4
@onready var line_panelist_name_5: LineEdit = %LinePanelistName5
@onready var option_judge_pack: OptionButton = %OptionJudgePack






func _reload() -> void :
	var gp: String = FileManager.MODPACKS_JUDGES + Profile.judges_slash
	judge_view_1.texture = VD.get_texture_agnostic(gp + "judge1", true); if !judge_view_1.texture: judge_view_1.texture = JUDGE_1
	judge_view_2.texture = VD.get_texture_agnostic(gp + "judge2", true); if !judge_view_2.texture: judge_view_2.texture = JUDGE_1
	judge_view_3.texture = VD.get_texture_agnostic(gp + "judge3", true); if !judge_view_3.texture: judge_view_3.texture = JUDGE_1
	judge_view_4.texture = VD.get_texture_agnostic(gp + "judge4", true); if !judge_view_4.texture: judge_view_4.texture = JUDGE_1
	judge_view_5.texture = VD.get_texture_agnostic(gp + "judge5", true); if !judge_view_5.texture: judge_view_5.texture = JUDGE_1
	var config: Dictionary = VD.get_json_object(gp + "config_judges.json")
	var labels: Array[Label] = [lbl_name_1, lbl_name_2, lbl_name_3, lbl_name_4, lbl_name_5]
	for i: int in range(5):
		var lbl: Label = labels[i]
		var judge: Dictionary = type_convert(config.get("judge" + str(i + 1), {}), TYPE_DICTIONARY)
		lbl.text = judge.get("name", "")
func _set_profile_panelists_from_input() -> void :
	Profile.twitch_panel_username_1 = line_panelist_name_1.text
	Profile.twitch_panel_username_2 = line_panelist_name_2.text
	Profile.twitch_panel_username_3 = line_panelist_name_3.text
	Profile.twitch_panel_username_4 = line_panelist_name_4.text
	Profile.twitch_panel_username_5 = line_panelist_name_5.text
func _set_input_panelists_from_profile() -> void :
	line_panelist_name_1.text = Profile.twitch_panel_username_1
	line_panelist_name_2.text = Profile.twitch_panel_username_2
	line_panelist_name_3.text = Profile.twitch_panel_username_3
	line_panelist_name_4.text = Profile.twitch_panel_username_4
	line_panelist_name_5.text = Profile.twitch_panel_username_5


func _setup_judges_list() -> void :
	option_judge_pack.add_item("Default", 0)
	var judges_modpack_list: Array = Array(DirAccess.get_directories_at(FileManager.MODPACKS_JUDGES))
	judges_modpack_list.sort_custom( func(a: String, b: String) -> bool: return a.to_upper() < b.to_upper())
	for i: int in judges_modpack_list.size():
		var pack_name: String = judges_modpack_list[i]
		option_judge_pack.add_item(pack_name, i + 1)
		if !pack_name.ends_with("/"): pack_name += "/"
		if pack_name == Profile.judges_slash: option_judge_pack.select(i + 1)
func _setup_signals() -> void :
	option_judge_pack.item_selected.connect(_judge_pack_changed)
func _setup_all() -> void :
	_setup_judges_list()
	_setup_signals()


func _ready() -> void :
	_setup_all()
	_reload()
	_set_input_panelists_from_profile()




func _judge_pack_changed(index: int) -> void :
	if index == 0: Profile.judges = "Default"
	else: Profile.judges = option_judge_pack.get_item_text(index)
	_reload()
func _continue() -> void : _set_profile_panelists_from_input();call_slide("res://scenes/nav_specific/clip_selector_menus/clip_selection_standard.tscn", false)
