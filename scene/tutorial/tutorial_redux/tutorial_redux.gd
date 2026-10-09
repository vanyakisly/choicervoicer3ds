extends Control


enum HM{NONE, SHIFTIN, SHIFTOUT, POPIN, POPOUT}
@onready var modular_background = $ModularBackground
@onready var host_master = $HostMaster











enum STATE_NEXT_BATCH{NONE, DIRECTORY}

@onready var btn_array_directory: ButtonArray = %BtnArrayDirectory
@onready var dialog_box: DialogBox = %DialogBox


@onready var btn_folder: ButtonCV = %BtnFolder
@onready var shae_help_packs_folders: Sprite2D = %ShaeHelpPacksFolders
@onready var shae_help_packguide: Sprite2D = %ShaeHelpPackguide
@onready var shae_help_newpack: Sprite2D = %ShaeHelpNewpack
@onready var shae_help_performance: Sprite2D = %ShaeHelpPerformance
@onready var shae_help_judges: Sprite2D = %ShaeHelpJudges
@onready var shae_help_score: Sprite2D = %ShaeHelpScore
@onready var waveform_examples: Control = %WaveformExamples



@export var elysian: DialogElysian
@onready var ed: Dictionary = elysian.dialog

var scorer: = Scorer.new()
var tutorial_vclip: = VclipResource.new()
var looked_around: bool = false
var state: = STATE_NEXT_BATCH.DIRECTORY


func _ready():
	VolumeService.tween_volume_music(1.0, 0)
	Prep()


	call_deferred("begin_dialog")


func _on_dialog_box_batch_done() -> void :
	match state:
		STATE_NEXT_BATCH.DIRECTORY:
			host_master.host_texture.texture = elysian.images[0]

			dialog_box.new_batch(ed.directory, true, true)
			dialog_box.next_text()
			await dialog_box.text_finished
			btn_array_directory.show()


func Prep():
	host_master.host_texture.texture = elysian.images[0]














	btn_array_directory.outline.hide()
	btn_array_directory.hide()
	dialog_box.hide()



func begin_dialog() -> void :
	if Profile.first_time: dialog_box.new_batch(elysian.dialog.begin_1)
	else: dialog_box.new_batch(elysian.dialog.begin_2)
	dialog_box.next_text()
	dialog_box.show()



func _on_btn_array_directory_selection(index: int) -> void :
	btn_array_directory.hide()
	await get_tree().create_timer(0.333).timeout
	match index:
		0:
			looked_around = true
			dialog_box.new_batch(ed.how_to_play)
			dialog_box.next_text()
			host_master.host_texture.texture = elysian.images[8]
			while true:
				var current_reverse: int = await dialog_box.current
				match current_reverse:
					4: host_master.host_texture.texture = elysian.images[0]
					3: host_master.host_texture.texture = elysian.images[1];shae_help_performance.show()
					2: shae_help_judges.show()
					1: shae_help_performance.hide();shae_help_judges.hide()
					0: shae_help_score.show();break
			await dialog_box.batch_done
			shae_help_score.hide()
		1:
			looked_around = true
			dialog_box.new_batch(ed.scuff)
			dialog_box.next_text()
			host_master.host_texture.texture = elysian.images[4]
			while true:
				var current_reverse: int = await dialog_box.current
				match current_reverse:
					3: host_master.host_texture.texture = elysian.images[9]
					2: host_master.host_texture.texture = elysian.images[3];waveform_examples.show()
					1: host_master.host_texture.texture = elysian.images[5]
					0: waveform_examples.hide();host_master.host_texture.texture = elysian.images[2];break
		2:
			looked_around = true
			dialog_box.new_batch(ed.customize)
			dialog_box.next_text()
			host_master.host_texture.texture = elysian.images[8]
			while true:
				var current_reverse: int = await dialog_box.current
				match current_reverse:
					6: host_master.host_texture.texture = elysian.images[0]
					5: host_master.host_texture.texture = elysian.images[1];btn_folder.show()
					4: shae_help_packs_folders.show()
					2: host_master.host_texture.texture = elysian.images[0];btn_folder.hide();shae_help_packs_folders.hide()
					1: host_master.host_texture.texture = elysian.images[1];shae_help_newpack.show()
					0: shae_help_packguide.show();break


			await dialog_box.batch_done
			shae_help_newpack.hide();shae_help_packguide.hide()
		3:
			looked_around = true
		4:
			state = STATE_NEXT_BATCH.NONE
			if looked_around:
				dialog_box.new_batch(ed.continue_to_game_questions)
				dialog_box.next_text()
			else:
				if M.data.player.first_time:
					dialog_box.new_batch(ed.continue_to_game_immediate)
					dialog_box.next_text()
				else:
					host_master.host_texture.texture = elysian.images[7]
					dialog_box.new_batch(ed.continue_to_game_tease)
					dialog_box.next_text()
					await dialog_box.new_text
					host_master.host_texture.texture = elysian.images[0]
			await dialog_box.batch_done
			dialog_box.hide()
			host_master.ShiftOut()
			await host_master.host_out

			Profile.first_time = false
			M.SaveData()
			get_tree().get_root().get_node("World").CreateMenu()



func _on_btn_folder_button_clicked() -> void :
	OS.shell_open(ProjectSettings.globalize_path("user://game/"))
