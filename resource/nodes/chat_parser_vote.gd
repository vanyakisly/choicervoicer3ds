class_name ChatParserVote
extends ChatParser


var scores: PackedInt32Array
var score_keys: Array[ScoreKey]


func get_scoref() -> float:
	var m: = Math.new()
	return m.array_mean(scores)

func _parse_message(chatter: Chatter) -> void :
	if active: for key: ScoreKey in score_keys: if _message_valid(chatter, key.text_string): scores.append(key.value)



func clear() -> void :
	scores.clear()
	voter_log.clear()

class ScoreKey extends Resource:
	var text_string: String
	var value: float
