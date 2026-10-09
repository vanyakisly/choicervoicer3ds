extends OveepCustomizeInterface

@onready var player_preview = %PlayerPreview
@onready var presentation = %Presentation
@onready var player_name_text_edit = %PlayerNameTextEdit
@onready var page_details = %PageDetails

@onready var mic_record_override_page = %MicRecordOverridePage
@onready var edit_window = %EditWindow

@onready var waveform_mantle = %WaveformMantle
@onready var btn_record = %BtnRecord
@onready var btn_playback = %BtnPlayback
@onready var btn_save_new = %BtnSaveNew
@onready var btn_cancel = %BtnCancel

@onready var clr_pick_1 = %ClrPick1
@onready var clr_pick_2 = %ClrPick2
@onready var introduction_edit = %IntroductionEdit
@onready var introduction_label = %IntroductionLabel
@onready var btn_save_changes = %BtnSaveChanges

@onready var btn_rec_greet = %BtnRecGreet
@onready var btn_rec_cheer = %BtnRecCheer
@onready var btn_rec_upset = %BtnRecUpset

@onready var talk_preview = %TalkPreview
@onready var text_edit_recording_file_name: LineEdit = %TextEditRecordingFileName
@onready var audio_reactions = %AudioReactions

@onready var btn_player_details: ButtonCV = %BtnPlayerDetails

var image_theseus: Texture2D = null
var editing: bool = true
var conte_preview: = ContestantResource.new()
var talk_type_record: String = ""


func _ready():
	add_child(uc)
	mic_record_override_page.visible = false
	page_details.visible = false
	presentation.visible = true


func LoadPack(pack_name: String = Profile.contestant):
	Profile.contestant = pack_name
	theseus_config = (uc.get_json(M.OVEEP.PLAYER, "config_player")).duplicate()
	conte_preview.set_from_directory(pack_name)
	if conte_preview.talk_player.get_parent() == null: add_child(conte_preview.talk_player)
	var img = uc.get_image(M.OVEEP.PLAYER, "player", true)
	img.set_size_override(img.get_size() / 3.0)
	image_theseus = img
	clr_pick_1.color = Color.html(theseus_config.color1)
	clr_pick_2.color = Color.html(theseus_config.color2)
	introduction_edit.text = theseus_config.introduction
	player_name_text_edit.text = theseus_config.name
	RefreshIntroLabelPreview()
	if mic_record_override_page.visible: CloseRecordPage()
	ShowPlayer()
	edit_window.visible = pack_name != "Default"
	audio_reaction_setup()


func ShowPlayer():
	var tex = image_theseus
	player_preview.texture = tex
	var anchor: = Vector2(size.x / 2.0, 460.0 - global_position.y)
	player_preview.set_size(tex.get_size())
	player_preview.set_position(anchor - Vector2(tex.get_size().x / 2.0, tex.get_size().y))


func SaveConfig():

	nodes_to_theseus()
	uc.save_json_config(M.OVEEP.PLAYER, "config_player", theseus_config)


func _on_btn_save_changes_button_clicked():
	SaveConfig()

func _on_btn_revert_changes_button_clicked():
	LoadPack()

func _on_player_name_text_edit_text_changed(text: String):
	theseus_config.name = text
	RefreshIntroLabelPreview()

func _on_player_tabs_selection(index):
	presentation.visible = (index == 0)
	page_details.visible = (index == 1)




func OpenRecordPage():
	waveform_mantle.pecho = null
	talk_preview.stop()
	waveform_mantle.SetVclipAudio(load("res://audio/sfx/silence1-75.wav"))
	edit_window.visible = false
	mic_record_override_page.visible = true
	btn_record.enable(true)
	btn_playback.enable(false)
	btn_save_new.enable(false)


func CloseRecordPage():
	waveform_mantle.StopBoth()
	edit_window.visible = true
	mic_record_override_page.visible = false

func RefreshIntroLabelPreview():
	introduction_label.text = "\"" + theseus_config.introduction + " " + theseus_config.name + "!\""


func _on_btn_play_greet_button_clicked():
	talk_preview.stream = conte_preview.talk_audio.intro_greet
	talk_preview.play()

func _on_btn_play_cheer_button_clicked():
	talk_preview.stream = conte_preview.talk_audio.score_5
	talk_preview.play()

func _on_btn_play_upset_button_clicked():
	talk_preview.stream = conte_preview.talk_audio.score_0
	talk_preview.play()


func _on_btn_cancel_button_clicked():
	CloseRecordPage()

func _on_btn_record_button_clicked():
	waveform_mantle.Reset()
	waveform_mantle.StopBoth()
	btn_record.enable(false)
	btn_playback.enable(false)
	btn_save_new.enable(false)
	waveform_mantle.Plmic()

func _on_btn_playback_button_clicked():
	waveform_mantle.StopBoth()
	btn_record.enable(false)
	btn_playback.enable(false)
	waveform_mantle.Pecho()

func _on_waveform_mantle_replay_finished():
	await get_tree().create_timer(0.7).timeout
	btn_record.enable(true)
	btn_playback.enable(true)
	btn_save_new.enable(true)


func _on_btn_rec_greet_button_clicked():
	OpenRecordPage()


func _on_btn_save_new_button_clicked():
	var new_talk: AudioStreamWAV = waveform_mantle.pecho
	get_tree().get_root().get_node("World").ActiveHint(true, "Saving")

	new_talk.save_to_wav(
		"user://game/packs_player/" + M.data.custom.player
			+ "/" + text_edit_recording_file_name.text)
	get_tree().get_root().get_node("World").ActiveHint(false)
	conte_preview.set_from_directory(M.data.custom.player)


func _on_clr_pick_1_color_changed(color):
	theseus_config.color1 = color.to_html(false)

func _on_clr_pick_2_color_changed(color):
	theseus_config.color2 = color.to_html(false)


func _on_introduction_edit_text_changed():
	theseus_config.introduction = introduction_edit.text
	RefreshIntroLabelPreview()


func _on_text_edit_recording_file_name_text_changed():
	var t: String = text_edit_recording_file_name.text
	btn_save_new.enable(t.is_valid_filename())



func audio_reaction_setup() -> void :
	const meta_keys: PackedStringArray = [
		"intro_greet", "score_0", "score_1", 
		"score_2", "score_3", "score_4", "score_5", 
		"game_winner", "game_loser"]
	var validity_color: Callable = func(node: LineEdit) -> void :
		var audio: AudioStream = uc.get_audio(oveep, node.text)
		if audio == null:
			node.add_theme_color_override("font_color", Color.RED)
		else:
			node.add_theme_color_override("font_color", Color.WHITE)
			talk_preview.stream = audio
			talk_preview.play()
	var recolor_to_white: Callable = func() -> void :
		add_theme_color_override("font_color", Color.WHITE)
	for i in meta_keys.size():
		var ref: HBoxContainer = audio_reactions.get_child(i)
		ref.set_meta("key_reference", meta_keys[i])
		ref.get_child(1).text_changed.connect(recolor_to_white)
		ref.get_child(1).text = theseus_config.audio_assignment[ref.get_meta("key_reference", null)]
		ref.get_child(2).button_clicked.connect(validity_color.bind(ref.get_child(1)))

func nodes_to_theseus() -> void :






	for ref: HBoxContainer in audio_reactions.get_children():
		theseus_config.audio_assignment[ref.get_meta("key_reference", null)] = ref.get_child(1).text
