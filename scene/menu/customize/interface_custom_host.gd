extends OveepCustomizeInterface


@onready var simple_window = $SimpleWindow
@onready var edit_window: MarginContainer = %EditWindow
@onready var host_name_text_edit = %HostNameTextEdit
@onready var host_master = %HostMaster
@onready var presentation = %Presentation
@onready var dialogue = %Dialogue
@onready var btn_save_changes = %BtnSaveChanges


var image_theseus: Texture2D
var button_selected_page: int = 0
var editing: bool = false


func _ready():
	add_child(uc)
	VisibilitySetup()


func VisibilitySetup():
	host_master.reparent(get_parent().get_parent().get_parent().get_parent().get_node("UnboundedHostCapsule"), false)
	host_master.PopOut()


	SetAsEditing()
	presentation.visible = true
	dialogue.visible = false


func LoadPack(pack_name: String = M.data.custom.host):
	edit_window.visible = pack_name != "Default"
	Profile.host = pack_name
	if editing:
		theseus_config = (uc.get_json(M.OVEEP.HOST, "config_host")).duplicate(true)
		image_theseus = uc.get_image(M.OVEEP.HOST, "host", true)
		host_name_text_edit.text = theseus_config.name
		host_master.host_texture.texture = image_theseus
		if button_selected_page == 0:
			host_master.ShiftIn()
		AssignText(false, theseus_config)

func SetAsEditing():
	editing = true
	simple_window.visible = false
	edit_window.visible = true
	LoadPack()

func SaveConfig():

	uc.save_json_config(M.OVEEP.HOST, "config_host", theseus_config)




func _on_btn_enable_editing_button_clicked():
	SetAsEditing()

func _on_host_tabs_selection(index):
	button_selected_page = index
	match button_selected_page:
		0:
			presentation.visible = true
			dialogue.visible = false
			host_master.ShiftIn()
		1:
			presentation.visible = false
			dialogue.visible = true
			host_master.PopOut()

func _on_btn_save_changes_button_clicked():
	SaveConfig()

func _on_btn_revert_changes_button_clicked():
	LoadPack()

func _on_host_name_text_edit_text_changed(text: String):
	theseus_config.name = text


@onready var match_singleplayer_welcome = %match_singleplayer_welcome
@onready var match_singleplayer_contestant = %match_singleplayer_contestant
@onready var match_singleplayer_judges = %match_singleplayer_judges
@onready var match_singleplayer_explanation = %match_singleplayer_explanation
@onready var match_singleplayer_post_record = %match_singleplayer_post_record
@onready var match_singleplayer_post_listen = %match_singleplayer_post_listen
@onready var match_singleplayer_round_next = %match_singleplayer_round_next
@onready var match_singleplayer_round_final = %match_singleplayer_round_final
@onready var match_singleplayer_score_0 = %match_singleplayer_score_0
@onready var match_singleplayer_score_1 = %match_singleplayer_score_1
@onready var match_singleplayer_score_2 = %match_singleplayer_score_2
@onready var match_singleplayer_score_3 = %match_singleplayer_score_3
@onready var match_singleplayer_score_4 = %match_singleplayer_score_4
@onready var match_singleplayer_score_5 = %match_singleplayer_score_5
@onready var match_singleplayer_final_score = %match_singleplayer_final_score
@onready var match_singleplayer_lose_0 = %match_singleplayer_lose_0
@onready var match_singleplayer_lose_standard = %match_singleplayer_lose_standard
@onready var match_singleplayer_lose_barely = %match_singleplayer_lose_barely
@onready var match_singleplayer_win_barely = %match_singleplayer_win_barely
@onready var match_singleplayer_win_standard = %match_singleplayer_win_standard
@onready var match_singleplayer_win_100 = %match_singleplayer_win_100
@onready var match_multiplayer_welcome = %match_multiplayer_welcome
@onready var match_multiplayer_contestants = %match_multiplayer_contestants
@onready var match_multiplayer_judges = %match_multiplayer_judges
@onready var match_multiplayer_explanation = %match_multiplayer_explanation
@onready var match_multiplayer_get_ready = %match_multiplayer_get_ready
@onready var match_multiplayer_post_record = %match_multiplayer_post_record
@onready var match_multiplayer_post_listen = %match_multiplayer_post_listen
@onready var match_multiplayer_round_next = %match_multiplayer_round_next
@onready var match_multiplayer_round_final = %match_multiplayer_round_final
@onready var match_multiplayer_judged_player = %match_multiplayer_judged_player
@onready var match_multiplayer_post_judging = %match_multiplayer_post_judging
@onready var match_multiplayer_final_score = %match_multiplayer_final_score
@onready var match_multiplayer_winner = %match_multiplayer_winner
@onready var match_multiplayer_tie_win = %match_multiplayer_tie_win
@onready var match_multiplayer_tie_win_start = %match_multiplayer_tie_win_start
@onready var match_multiplayer_tie_win_end = %match_multiplayer_tie_win_end
@onready var match_multiplayer_congrats_goodbye = %match_multiplayer_congrats_goodbye
@onready var match_twitch_intro_audience: TextEdit = %match_twitch_intro_audience
@onready var match_twitch_round_audience_1: TextEdit = %match_twitch_round_audience_1
@onready var match_twitch_round_audience_2: TextEdit = %match_twitch_round_audience_2
@onready var match_twitch_polls_closed: TextEdit = %match_twitch_polls_closed


func AssignText(n2s: bool, config: Dictionary):
	TextTransfer(n2s, match_singleplayer_welcome, config.match_singleplayer.intro, "a_welcome")
	TextTransfer(n2s, match_singleplayer_contestant, config.match_singleplayer.intro, "b_contestant")
	TextTransfer(n2s, match_singleplayer_judges, config.match_singleplayer.intro, "c_judges")
	TextTransfer(n2s, match_singleplayer_explanation, config.match_singleplayer.intro, "d_explanation")
	TextTransfer(n2s, match_singleplayer_post_record, config.match_singleplayer.round, "b_post_record")
	TextTransfer(n2s, match_singleplayer_post_listen, config.match_singleplayer.round, "c_post_listen")
	TextTransfer(n2s, match_singleplayer_round_next, config.match_singleplayer.round, "round_next")
	TextTransfer(n2s, match_singleplayer_round_final, config.match_singleplayer.round, "round_final")
	TextTransfer(n2s, match_singleplayer_score_0, config.match_singleplayer.judging, "score_0")
	TextTransfer(n2s, match_singleplayer_score_1, config.match_singleplayer.judging, "score_1")
	TextTransfer(n2s, match_singleplayer_score_2, config.match_singleplayer.judging, "score_2")
	TextTransfer(n2s, match_singleplayer_score_3, config.match_singleplayer.judging, "score_3")
	TextTransfer(n2s, match_singleplayer_score_4, config.match_singleplayer.judging, "score_4")
	TextTransfer(n2s, match_singleplayer_score_5, config.match_singleplayer.judging, "score_5")
	TextTransfer(n2s, match_singleplayer_final_score, config.match_singleplayer.end, "final_score")
	TextTransfer(n2s, match_singleplayer_lose_0, config.match_singleplayer.end, "lose_0")
	TextTransfer(n2s, match_singleplayer_lose_standard, config.match_singleplayer.end, "lose_standard")
	TextTransfer(n2s, match_singleplayer_lose_barely, config.match_singleplayer.end, "lose_barely")
	TextTransfer(n2s, match_singleplayer_win_barely, config.match_singleplayer.end, "win_barely")
	TextTransfer(n2s, match_singleplayer_win_standard, config.match_singleplayer.end, "win_standard")
	TextTransfer(n2s, match_singleplayer_win_100, config.match_singleplayer.end, "win_100")
	TextTransfer(n2s, match_multiplayer_welcome, config.match_multiplayer.intro, "a_welcome")
	TextTransfer(n2s, match_multiplayer_contestants, config.match_multiplayer.intro, "b_contestants")
	TextTransfer(n2s, match_multiplayer_judges, config.match_multiplayer.intro, "c_judges")
	TextTransfer(n2s, match_multiplayer_explanation, config.match_multiplayer.intro, "d_explanation")
	TextTransfer(n2s, match_multiplayer_get_ready, config.match_multiplayer.round, "a_get_ready")
	TextTransfer(n2s, match_multiplayer_post_record, config.match_multiplayer.round, "b_post_record")
	TextTransfer(n2s, match_multiplayer_post_listen, config.match_multiplayer.round, "c_post_listen")
	TextTransfer(n2s, match_multiplayer_round_next, config.match_multiplayer.round, "round_next")
	TextTransfer(n2s, match_multiplayer_round_final, config.match_multiplayer.round, "round_final")
	TextTransfer(n2s, match_multiplayer_judged_player, config.match_multiplayer.judging, "judged_player")
	TextTransfer(n2s, match_multiplayer_post_judging, config.match_multiplayer.judging, "post_judging")
	TextTransfer(n2s, match_multiplayer_final_score, config.match_multiplayer.end, "final_score")
	TextTransfer(n2s, match_multiplayer_winner, config.match_multiplayer.end, "winner")
	TextTransfer(n2s, match_multiplayer_tie_win, config.match_multiplayer.end, "tie_win")
	TextTransfer(n2s, match_multiplayer_tie_win_start, config.match_multiplayer.end, "tie_win_start")
	TextTransfer(n2s, match_multiplayer_tie_win_end, config.match_multiplayer.end, "tie_win_end")
	TextTransfer(n2s, match_multiplayer_congrats_goodbye, config.match_multiplayer.end, "congrats_goodbye")
	TextTransfer(n2s, match_twitch_intro_audience, config.twitch_standard, "intro_audience")
	TextTransfer(n2s, match_twitch_round_audience_1, config.twitch_standard, "a_audience_turn_1")
	TextTransfer(n2s, match_twitch_round_audience_2, config.twitch_standard, "b_audience_turn_2")
	TextTransfer(n2s, match_twitch_polls_closed, config.twitch_standard, "c_polls_closed")


func TextTransfer(n2s: bool, node: TextEdit, dialogue_set: Dictionary, batch_name: String):
	if n2s:
		var batch: Array = []
		var node_text: String = node.text
		batch = node_text.split("</next>")
		dialogue_set[batch_name] = batch
	else:
		if not node.is_connected("text_changed", _on_text_edit_changed):
			node.connect("text_changed", _on_text_edit_changed)
		var batch: PackedStringArray = dialogue_set[batch_name]
		var combined_batch: String = "</next>".join(batch)
		node.text = combined_batch

func _on_text_edit_changed():
	AssignText(true, theseus_config)
