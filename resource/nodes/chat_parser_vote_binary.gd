class_name ChatParserVoteBinary
extends ChatParserVote


func _init() -> void :
	var key_pass: = ScoreKey.new()
	var key_fail: = ScoreKey.new()

	key_pass.text_string = Profile.twitch_commands_binary_pass
	key_fail.text_string = Profile.twitch_commands_binary_fail

	key_pass.value = 5
	key_fail.value = 0

	score_keys.append(key_pass)
	score_keys.append(key_fail)
