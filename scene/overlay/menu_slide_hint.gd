extends Control


@onready var lbl = $MarginContainer / Label
var strings: PackedStringArray = []











func SetSlides(batch: PackedStringArray):
	strings.clear()
	for s: String in batch:
		strings.append(_rename_hint_text(s))
	WriteArray()


func WriteArray():
	lbl.text = "  " + " > ".join(strings) + "    "


func _rename_hint_text(input: String) -> String:
	if input == "$variableSession":
		var change_slide_name: String
		match M.session_type:
			M.SESSION_TYPE.STANDARD: change_slide_name = "Standard Session"
			M.SESSION_TYPE.STANDARD_JABRONI: change_slide_name = "Jabroni Session"
			M.SESSION_TYPE.TWITCH: change_slide_name = "Twitch Chat Session"
			M.SESSION_TYPE.AUDITION: change_slide_name = "Audition Session"
			_: change_slide_name = "INVALID TYPE IDENTIFIED"
		return change_slide_name
	else: return input
