class_name ChatParser
extends Node




enum COMPARISON_TYPE{NONE, CONTAINS, LEADS, EXACT}

var active: bool = false
var voter_log: PackedStringArray
var comparison: COMPARISON_TYPE

func _accept_message(chatter: Chatter) -> bool:
	voter_log.append(chatter.login)
	return true

func _message_valid(chatter: Chatter, command: String) -> bool:
	if ( !Profile.twitch_allow_duplicate_voting and voter_log.has(chatter.login)): return false
	var message: String = chatter.message
	if !Profile.twitch_is_case_sensitive:
		message = message.to_lower()
		command = command.to_lower()
	if (Profile.twitch_is_exact_phrase and message == command): return _accept_message(chatter)
	if command.contains(" "):

		if message.strip_edges().begins_with(command): return _accept_message(chatter)
	else:

		var args: PackedStringArray = message.strip_edges().split(" ", false)
		var arg1: String = ""
		if !args.is_empty(): arg1 = args[0]
		if command == arg1: return _accept_message(chatter)

	return false

func activate() -> void : active = true
func deactivate() -> void : active = false
