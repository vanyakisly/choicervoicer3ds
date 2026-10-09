class_name JudgesMaster extends Node3D

signal last_vote

@onready var judges: Node3D = %Judges
@onready var drumroll: AudioStreamPlayer = %LongDrumroll

var difficulty_tier: Array[int] = [0, 1, 2, 3, 4]
var blippeds: int = 0


func _ready():
	SetupJudges()


func SetupJudges():
	var uc: = UC.new()
	var success_panel: Texture2D = uc.get_image(M.OVEEP.JUDGES, "success", true, Vector2i(512, 256))
	var judge_data: Dictionary = uc.get_json(M.OVEEP.JUDGES, "config_judges")
	var play_blips_with_voices: bool = judge_data.get("play_voices_with_blips", true)
	var blips: Array[AudioStream] = [null, null, null, null, null]
	for i in range(5):
		blips[i] = uc.get_audio(M.OVEEP.JUDGES, "scoreblip" + str(i + 1), true)
	var name_hash: String = ""
	for j_idx: int in judges.get_child_count():
		var this_judge: Node3D = judges.get_child(j_idx)
		var this_judges_data: Dictionary = judge_data["judge" + str(j_idx + 1)]
		var individual_image: Texture2D = uc.get_image(M.OVEEP.JUDGES, "judge" + str(j_idx + 1), true, Vector2i.ZERO, true, Image.INTERPOLATE_NEAREST)
		var own_panel_path: String = "user://game/packs_judges/" + M.data.custom.judges + "/judge%s_success" % [j_idx + 1]
		var individual_panel: Image = uc.get_image_direct(own_panel_path)
		if individual_panel != null:
			individual_panel.resize(512, 256)
			this_judge.SetImages(individual_image, ImageTexture.create_from_image(individual_panel))
		else:
			this_judge.SetImages(individual_image, success_panel)
		var individual_voice: AudioStream = uc.get_audio_direct("user://game/packs_judges/" + M.data.custom.judges + "/judge%s_voice" % [j_idx + 1])
		if individual_voice != null: this_judge.voice.stream = individual_voice
		this_judge.play_blips_with_voices = play_blips_with_voices
		this_judge.blips = blips
		if Profile.twitch_panel_override_judge_names and Metro.judge_master_uses_panelists:
			match j_idx:
				0: this_judge.nameplate.text = "@" + Profile.twitch_panel_username_1 if Profile.twitch_panel_username_1 else this_judges_data.name
				1: this_judge.nameplate.text = "@" + Profile.twitch_panel_username_2 if Profile.twitch_panel_username_2 else this_judges_data.name
				2: this_judge.nameplate.text = "@" + Profile.twitch_panel_username_3 if Profile.twitch_panel_username_3 else this_judges_data.name
				3: this_judge.nameplate.text = "@" + Profile.twitch_panel_username_4 if Profile.twitch_panel_username_4 else this_judges_data.name
				4: this_judge.nameplate.text = "@" + Profile.twitch_panel_username_5 if Profile.twitch_panel_username_5 else this_judges_data.name
		else: this_judge.nameplate.text = this_judges_data.name
		name_hash += this_judges_data.name
	if Metro.judge_master_uses_panelists: Metro.judge_master_uses_panelists = false
	DifficultySetup(name_hash)
	JudgePanelsOff()
	uc.queue_free()


func DifficultySetup(string: String):






	seed(string.hash())

	difficulty_tier.shuffle()



func JudgeShow(its_image: bool = true): for j in judges.get_children(): j.judge_image.visible = its_image


func JudgePanelsOff(): for j in judges.get_children(): j.ClearSuccess()


const TIMELENGTH: float = 4.6
func JudgeWinFrom(score: int, time: float = TIMELENGTH) -> void :
	blippeds = 0
	var wait_last_vote = func():
		print("JudgeMaster | Awaiting reveal of all votes.")
		var clamp_score: int = clampi(score, 0, 5)
		while blippeds != clamp_score:
			await get_tree().process_frame
		last_vote.emit()










	var reveal_times: PackedFloat32Array = []
	for i in range(score):
		reveal_times.append(time / TIMELENGTH * (randf() / 2.0 + float(i) / 10.0))
	reveal_times.sort()
	var queued_success_indexes: Array[int] = []
	match score:
		5, 6, 7, 8, 9:
			for judge in judges.get_children():
				queued_success_indexes = [0, 1, 2, 3, 4]
				randomize()
				queued_success_indexes.shuffle()
		0: pass
		_:
			var tier: Array[int] = difficulty_tier.slice(0, 3)

			var selected_judge: int = tier.pick_random()
			queued_success_indexes.append(selected_judge)
			tier.erase(selected_judge)
			tier.append_array(difficulty_tier.slice(3, 5))
			for s in range(clampi(score - 1, 0, 4)):
				selected_judge = tier.pick_random()
				queued_success_indexes.append(selected_judge)
				tier.erase(selected_judge)


	for success_idx in queued_success_indexes.size():
		var judge_idx: int = queued_success_indexes[success_idx]
		judges.get_child(judge_idx).QueueWin(reveal_times[success_idx] * TIMELENGTH, success_idx)
	wait_last_vote.call()


func judge_win_from_slots(votes: Array[ChatParserPanel.VOTE_STATE], score: int, time: float = TIMELENGTH) -> void :
	blippeds = 0
	var reveal_times: PackedFloat32Array = []
	for i: int in range(score): reveal_times.append(time / TIMELENGTH * (randf() / 2.0 + float(i) / 10.0))
	reveal_times.sort()
	var queued_success_indexes: Array[int] = []
	for i: int in votes.size(): if votes[i] == ChatParserPanel.VOTE_STATE.PASS: queued_success_indexes.append(i)
	queued_success_indexes.shuffle()
	for i: int in queued_success_indexes.size(): judges.get_child(queued_success_indexes[i]).QueueWin(reveal_times[i] * TIMELENGTH, i)

	print("JudgeMaster | Awaiting reveal of all votes.")
	while blippeds != score: await get_tree().process_frame
	last_vote.emit()


func FaceCamera(do: bool):
	var assign: int
	if do: assign = VisualShaderNodeBillboard.BILLBOARD_TYPE_FIXED_Y
	else: assign = VisualShaderNodeBillboard.BILLBOARD_TYPE_DISABLED
	for child in judges.get_children(): child.judge_image.set_billboard_mode(assign)
