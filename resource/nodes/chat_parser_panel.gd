class_name ChatParserPanel extends ChatParser



signal voting_ready(votes: Array[VOTE_STATE])
signal new_vote_occurred


enum VOTE_STATE{NONE, COMPUTER, PASS, FAIL}


var judge_states: Array[VOTE_STATE] = []
var voting_period_ended: bool = false


var everyone_voted: bool:
	get: return !judge_states.has(VOTE_STATE.NONE)




func reset() -> void :
	judge_states.resize(5)
	judge_states[0] = VOTE_STATE.COMPUTER if Profile.twitch_panel_username_1.is_empty() else VOTE_STATE.NONE
	judge_states[1] = VOTE_STATE.COMPUTER if Profile.twitch_panel_username_2.is_empty() else VOTE_STATE.NONE
	judge_states[2] = VOTE_STATE.COMPUTER if Profile.twitch_panel_username_3.is_empty() else VOTE_STATE.NONE
	judge_states[3] = VOTE_STATE.COMPUTER if Profile.twitch_panel_username_4.is_empty() else VOTE_STATE.NONE
	judge_states[4] = VOTE_STATE.COMPUTER if Profile.twitch_panel_username_5.is_empty() else VOTE_STATE.NONE
	voting_period_ended = false


func end() -> void :
	voting_period_ended = true
	var score: int = 0


	voting_ready.emit(judge_states)
func check_for_end() -> void : if everyone_voted: end()
func panel_parse_chatter_message(chatter: Chatter) -> void :
	var chatter_login: String = chatter.login.to_lower()
	if chatter_login == Profile.twitch_panel_username_1.to_lower() and judge_states[0] == VOTE_STATE.NONE: _check_for_binary_command(chatter.message, 0)
	if chatter_login == Profile.twitch_panel_username_2.to_lower() and judge_states[1] == VOTE_STATE.NONE: _check_for_binary_command(chatter.message, 1)
	if chatter_login == Profile.twitch_panel_username_3.to_lower() and judge_states[2] == VOTE_STATE.NONE: _check_for_binary_command(chatter.message, 2)
	if chatter_login == Profile.twitch_panel_username_4.to_lower() and judge_states[3] == VOTE_STATE.NONE: _check_for_binary_command(chatter.message, 3)
	if chatter_login == Profile.twitch_panel_username_5.to_lower() and judge_states[4] == VOTE_STATE.NONE: _check_for_binary_command(chatter.message, 4)
	check_for_end()
func _check_for_binary_command(message: String, judge_index: int) -> void :
	if _check_if_used_command(message, Profile.twitch_commands_binary_pass): judge_states[judge_index] = VOTE_STATE.PASS
	elif _check_if_used_command(message, Profile.twitch_commands_binary_fail): judge_states[judge_index] = VOTE_STATE.FAIL
	new_vote_occurred.emit()
func _check_if_used_command(message: String, command: String) -> bool:
	if !Profile.twitch_is_case_sensitive: message = message.to_lower();command = command.to_lower()
	if command.contains(" "): return message.strip_edges().begins_with(command)
	else:
		var args: PackedStringArray = message.strip_edges().split(" ", false)
		var arg1: String = ""
		if !args.is_empty(): arg1 = args[0]
		return command == arg1


func _ready() -> void :
	reset()
