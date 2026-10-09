extends OveepCustomizeInterface

@onready var edit_window = %EditWindow
@onready var presentation = %Presentation
@onready var options = %Options
@onready var simple_window = %SimpleWindow
@onready var judge_name_text_edit = %JudgeNameTextEdit
@onready var judge_preview = %JudgePreview
@onready var lbl_judge_name = %LblJudgeName
@onready var podium_image = %PodiumImage
@onready var blip_player = %BlipPlayer
@onready var success_img = %SuccessImg
@onready var btn_save_changes = %BtnSaveChanges

var images_theseus: Array[Texture2D] = [null, null, null, null, null]
var button_selected_page: int = 0
var current_judge: int = 0
var editing: bool = false

var scoreblip: Array[AudioStream] = [null, null, null, null, null]


func _ready():
	add_child(uc)
	VisibilitySetup()


func VisibilitySetup():
	simple_window.visible = true
	edit_window.visible = false
	presentation.visible = true
	options.visible = false

func LoadPack(pack_name: String = M.data.custom.judges):

	Profile.judges = pack_name
	if editing:
		images_theseus = [null, null, null, null, null]
		theseus_config = (uc.get_json(M.OVEEP.JUDGES, "config_judges")).duplicate(true)
		for i in range(5):
			var img = uc.get_image(M.OVEEP.JUDGES, "judge" + str(i + 1), true)
			img.set_size_override(img.get_size() / 3.0)
			images_theseus[i] = img
			scoreblip[i] = uc.get_audio(M.OVEEP.JUDGES, "scoreblip" + str(i + 1), true)
		judge_name_text_edit.text = theseus_config["judge1"].name
		current_judge = 0
		lbl_judge_name.text = "Judge #1: "
		success_img.texture = uc.get_image(M.OVEEP.JUDGES, "success", true, Vector2i(192, 96))
		ShowJudge(current_judge)

	visible = (pack_name != "Default")


func SetAsEditing():
	editing = true
	simple_window.visible = false
	edit_window.visible = true
	LoadPack()

func SaveConfig():

	uc.save_json_config(M.OVEEP.JUDGES, "config_judges", theseus_config)


func ShowJudge(idx: int):
	var tex = images_theseus[idx]
	judge_preview.texture = tex
	var anchor: = Vector2(size.x / 2.0, 460.0 - global_position.y)
	judge_preview.set_size(tex.get_size())
	judge_preview.set_position(anchor - Vector2(tex.get_size().x / 2.0, tex.get_size().y))




func _on_btn_enable_editing_button_clicked():
	SetAsEditing()

func _on_btn_save_changes_button_clicked():
	SaveConfig()

func _on_btn_revert_changes_button_clicked():
	LoadPack()

func _on_judge_name_text_edit_text_changed(text: String):
	theseus_config["judge" + str(current_judge + 1)].name = text

func _on_judges_tabs_selection(index):
	button_selected_page = index
	match button_selected_page:
		0:
			presentation.visible = true
			options.visible = false
		1:
			presentation.visible = false
			options.visible = true


func _on_btn_judge_move_left_button_clicked():
	current_judge -= 1
	if current_judge == -1:
		current_judge = 4
	judge_name_text_edit.text = theseus_config["judge" + str(current_judge + 1)].name
	lbl_judge_name.text = "Judge #%s: " % str(current_judge + 1)
	ShowJudge(current_judge)

func _on_btn_judge_move_right_button_clicked():
	current_judge = (current_judge + 1) % 5
	judge_name_text_edit.text = theseus_config["judge" + str(current_judge + 1)].name
	lbl_judge_name.text = "Judge #%s: " % str(current_judge + 1)
	ShowJudge(current_judge)


func _on_btn_podium_preview_button_clicked():
	podium_image.visible = not podium_image.visible


func _on_btn_play_score_1_button_clicked():
	blip_player.stream = scoreblip[0]
	blip_player.play()

func _on_btn_play_score_2_button_clicked():
	blip_player.stream = scoreblip[1]
	blip_player.play()

func _on_btn_play_score_3_button_clicked():
	blip_player.stream = scoreblip[2]
	blip_player.play()

func _on_btn_play_score_4_button_clicked():
	blip_player.stream = scoreblip[3]
	blip_player.play()

func _on_btn_play_score_5_button_clicked():
	blip_player.stream = scoreblip[4]
	blip_player.play()
