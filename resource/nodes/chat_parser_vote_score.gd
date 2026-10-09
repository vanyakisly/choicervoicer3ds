class_name ChatParserVoteScore
extends ChatParserVote


func _init() -> void :
	var key_score_0: = ScoreKey.new()
	var key_score_1: = ScoreKey.new()
	var key_score_2: = ScoreKey.new()
	var key_score_3: = ScoreKey.new()
	var key_score_4: = ScoreKey.new()
	var key_score_5: = ScoreKey.new()

	key_score_0.text_string = Profile.twitch_commands_score_0
	key_score_1.text_string = Profile.twitch_commands_score_1
	key_score_2.text_string = Profile.twitch_commands_score_2
	key_score_3.text_string = Profile.twitch_commands_score_3
	key_score_4.text_string = Profile.twitch_commands_score_4
	key_score_5.text_string = Profile.twitch_commands_score_5

	key_score_0.value = 0
	key_score_1.value = 1
	key_score_2.value = 2
	key_score_3.value = 3
	key_score_4.value = 4
	key_score_5.value = 5

	score_keys.append(key_score_0)
	score_keys.append(key_score_1)
	score_keys.append(key_score_2)
	score_keys.append(key_score_3)
	score_keys.append(key_score_4)
	score_keys.append(key_score_5)
