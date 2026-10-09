extends MenuBase


@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var btn_choose_standard: ButtonCV = %BtnChooseStandard
@onready var btn_choose_jabroni: ButtonCV = %BtnChooseJabroni
@onready var btn_choose_twitch: ButtonCV = %BtnChooseTwitch
@onready var btn_choose_audition: ButtonCV = %BtnChooseAudition

@onready var lbl_is_tutorial: Label = %LblIsTutorial


func _ready() -> void :
	lbl_is_tutorial.visible = M.THISISDEMO
	btn_choose_standard.hover_with_info.connect(update_label)
	btn_choose_jabroni.hover_with_info.connect(update_label)
	btn_choose_twitch.hover_with_info.connect(update_label)
	btn_choose_audition.hover_with_info.connect(update_label)


func update_label(text: String) -> void :
	rich_text_label.text = "[center][wave amp=5.0]%s" % text


func _on_btn_choose_standard_button_clicked() -> void :
	M.session_type = M.SESSION_TYPE.STANDARD
	call_slide("play/play_match_singleplayer")


func _on_btn_choose_jabroni_button_clicked() -> void :
	M.session_type = M.SESSION_TYPE.STANDARD_JABRONI
	call_slide("play/play_match_singleplayer")


func _on_btn_choose_twitch_button_clicked() -> void :
	M.session_type = M.SESSION_TYPE.TWITCH
	call_slide("play/play_options/menu_twitch_options")

func _on_btn_choose_audition_button_clicked() -> void :
	M.session_type = M.SESSION_TYPE.AUDITION
	call_slide("play/play_options/menu_twitch_options")
