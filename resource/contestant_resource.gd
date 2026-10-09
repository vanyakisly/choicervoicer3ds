extends Resource
class_name ContestantResource

var directory: String = ""

var image: Texture
var name: String
var introduction: String
var color1: = Color.BLACK
var color2: = Color.WHITE
var iffy: String



var talk_player: = AudioStreamPlayer.new()
var talk_audio: Dictionary = {
	"intro_greet": null, 
	"score_0": null, 
	"score_1": null, 
	"score_2": null, 
	"score_3": null, 
	"score_4": null, 
	"score_5": null, 
	"game_winner": null, 
	"game_loser": null
}


func set_from_directory(name_of_pack: String):
	directory = name_of_pack
	var append: String = directory + "/"
	const oveep: = M.OVEEP.PLAYER
	var uc: = UC.new()
	image = uc.get_image(oveep, append + "player", true, Vector2i.ZERO, false, Image.INTERPOLATE_NEAREST)
	var config: Dictionary = uc.get_json(oveep, append + "config_player", false)
	name = config.name
	color1 = Color.html(config.color1)
	color2 = Color.html(config.color2)
	introduction = config.introduction







	var audio_assignment: Dictionary = config.audio_assignment
	var paths: Dictionary = {}
	for key in audio_assignment.keys():
		paths[audio_assignment[key]] = null
	for key in paths.keys():
		paths[key] = uc.get_audio(oveep, append + key, false, false)
	for key in talk_audio.keys():
		talk_audio[key] = paths[audio_assignment[key]]

	uc.queue_free()



var round_scores: Array = []
var audio_input_device: String = "Default"
var round_waveform_image: Texture = null

var round_plmic_data: Dictionary = {}
var progress_tracker: MultiplayerProgressTracker = null
var stream_player: AudioStreamPlayer = null
var previous_percent: float = 0.0

func set_my_input_device():
	AudioServer.set_input_device(audio_input_device)

func play_pecho():
	stream_player.play(0.13)

func stop_pecho():
	stream_player.stop()


var allow_talk: bool = false
func random_delay_talk(talk_type: String = ""):
	allow_talk = true
	randomize()
	var rand = randf() / 2.0







	talk_player.stream = talk_audio.get(talk_type, null)
	await M.get_tree().create_timer(rand).timeout
	if allow_talk: talk_player.play()
