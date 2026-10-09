extends CVModPack
class_name HostModPack

var config_host: Dictionary = {
	"host_type": "basic", 
	"name": "Shae", 
	"match_singleplayer": {
		"intro": {
			"a_welcome": ["Welcome to The Choicer Voicer!\nI'm <host_name>, and I'll be your host for today's game!"], 
			"b_contestant": ["Audience, please give a round of applause for today's contestant, <player>!"], 
			"c_judges": ["...and in this corner, we have a wonderful panel of judges! I'm excited to see how this pans out."], 
			"d_explanation": [
				"For any new viewers at home, the goal is for contestants to expertly match various audio clips, using their own voice.", 
				"Now, with introductions out of the way, let's jump into the first round!"]
		}, 
		"round": {
			"b_post_record": ["Good job! Let's hear how that turned out."], 
			"c_post_listen": ["I like it! But which of our judges will vote for your performance?"], 
			"round_next": ["It's now time for round <round>. Get ready!"], 
			"round_final": ["It's the final round. Time to give it your all. Let's see what we've got!"]
		}, 
		"judging": {
			"score_0": ["Seems the judges weren't impressed...\nBut you'll do better next round!"], 
			"score_1": ["Seems the judges weren't impressed...\nBut you'll do better next round!"], 
			"score_2": ["That score's okay, but you'll need to go all-out if you want to win!"], 
			"score_3": ["It was a great performance! The judges agree."], 
			"score_4": ["It was a great performance! The judges agree."], 
			"score_5": ["A perfect score from the judges! Fantastic work!"]
		}, 
		"end": {
			"final_score": ["And with that, this match has concluded! Let's see what your final score comes up to!"], 
			"win_standard": ["Congratulations! You won the match! Excellent work!"], 
			"win_barely": ["Wow, just barely made it! Well done!"], 
			"win_100": ["Incredible! You managed a perfect score throughout! You truly are our Choicer Voicer!"], 
			"lose_standard": ["Not enough this time around. But we hope to see you again!"], 
			"lose_barely": ["Agh, and you were so close, too!\nYou hate to see it..."], 
			"lose_0": ["Ah, hmm...\nWell, thank you for coming today!"]
		}
	}, 
	"match_multiplayer": {
		"intro": {
			"a_welcome": ["Welcome to The Choicer Voicer!\nI'm <host_name>, and I'll be your host for today's game!"], 
			"b_contestants": ["Audience, please give a round of applause for today's contestants!"], 
			"c_judges": ["...and in this corner, we have a wonderful panel of judges! I'm excited to see how this pans out."], 
			"d_explanation": [
				"For any new viewers at home, the goal of the game is for them to expertly match various audio clips, using their own voice.", 
				"Now, with introductions out of the way, let's jump into the first round!"]
		}, 
		"round": {
			"a_get_ready": ["<player>,\nget ready, it's your turn!"], 
			"b_post_record": ["Excellent work, everyone! Let's hear each of your performances."], 
			"c_post_listen": ["I think you each did wonderfully! But which of our judges will agree?"], 
			"round_next": ["Alright contestants, get ready for round <round>!"], 
			"round_final": ["Last chance, contestants! It's the final round. Let's see what we've got!"]
		}, 
		"judging": {
			"judged_player": ["<points> for <player>!"], 
			"post_judging": ["...and there you have it!"]
		}, 
		"end": {
			"winner": ["And it looks like today's winner is <player>!"], 
			"tie_win": ["Goodness, it appears we have a tie!"], 
			"tie_win_start": ["Our winners for today are <player>..."], 
			"tie_win_end": ["...and <player>!"], 
			"congrats_goodbye": ["Congratulations! We hope to see you all again on The Choicer Voicer!"], 
			"final_score": ["And that's a wrap, contestants! Now, whose performance came out on top?"]
		}
	}
}

var config_host_hidden: Dictionary = {
	"match_singleplayer": {
		"judging": {
			"score_6": ""
		}
	}
}

enum DIALOGUETYPE{BASIC, MULTI}
var dialogue_type: DIALOGUETYPE
var host_image_basic: Image
var host_image_multi: Array[Image]

var local_oveep: = M.OVEEP.HOST
var local_set_pack: Callable = func(pack_name: String = ""):
	var load_defaults_where_applicable: Callable
	match dialogue_type:
		DIALOGUETYPE.BASIC:
			load_defaults_where_applicable = func():
				for value in [
					&"host_image_basic"
				]: if self[value] == null: self[value] = load_default(value)

	var uc: = UC.new()
	absolute_path += "packs_host/"
	if pack_name == "" or not DirAccess.dir_exists_absolute(absolute_path + pack_name):
		pack_name = "Default - Shae"
		M.data.custom.host = "Default - Shae"
	else:
		M.data.custom.host = pack_name
	match pack_name:
		"Default - Shae":
			pass
		_:
			config_overwrite(config_host, uc.get_json(oveep, "config_host", true, false))
			host_image_basic = uc.get_existing_image(oveep, "host")
	uc.queue_free()


func load_default(value):
	match value:
		&"host_image_basic": return load("res://game_default/packs_host/Default - Shae/host.png").get_image()
		_:
			return null


func _init():
	oveep = local_oveep
	set_pack = local_set_pack
	config = config_host
	config_hidden = config_host_hidden
