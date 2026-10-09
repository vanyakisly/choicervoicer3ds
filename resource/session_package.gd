class_name SessionPackage
extends Resource


enum VALIDITY{NONE, REFUSE, FEWER, VALID}

var total_rounds: int
var vamba: PackedStringArray
var players: Array





func _init(players_node: VBoxContainer, _total_rounds: int = 0, current_pack_pacys: PackedStringArray = []) -> void :
	var vamba_generator: = VambaGenerator.new()
	total_rounds = _total_rounds
	vamba = vamba_generator.generate_vamba(current_pack_pacys, total_rounds, M.data.settings.clip_selection.duplicate(true))
	for player_tile in players_node.get_children():
		players.append([player_tile.pack_name, player_tile.input_device])


func parse() -> VALIDITY:
	if vamba.is_empty(): return VALIDITY.REFUSE
	elif vamba.size() < total_rounds: return VALIDITY.FEWER
	else: return VALIDITY.VALID
