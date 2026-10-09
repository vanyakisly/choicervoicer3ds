extends VBoxContainer

@onready var players_list = $Players
@onready var btn_add = $AddPlayerTile


func _ready():
	AddPlayer()


func Kill(idx: int, override: bool = false):
	if (players_list.get_child_count() > 1) or override:
		var deletor = players_list.get_child(idx)
		deletor.queue_free()
		await deletor.tree_exited
		RefreshIndexes()


func Move(from: int, to: int):
	players_list.move_child(players_list.get_child(from), to)
	RefreshIndexes()


func RefreshIndexes():
	for child_idx: int in players_list.get_child_count():
		var player_tile: LegacyPlayerTile = players_list.get_child(child_idx)
		player_tile.player_index = child_idx
	if !M.unbound: btn_add.visible = (players_list.get_child_count() < 4)
	elif !btn_add.visible: btn_add.show()


func AddPlayer(pack_name: String = "", input_device: String = ""):
	var new_player: ColorRect = load("res://scene/menu/play/player_tile.tscn").instantiate()
	new_player.pack_name = pack_name
	new_player.input_device = input_device
	new_player.connect("kill", Kill)
	new_player.connect("move", Move)
	players_list.add_child(new_player)
	RefreshIndexes()


func _on_add_player_tile_button_clicked():
	AddPlayer()


func Unbounded():
	RefreshIndexes()


func SameLobby(lobby: Array):
	while players_list.get_child_count() > 0: await Kill(0, true)
	for player: BasicPlayerPackage in lobby: AddPlayer(player.pack_reference_name, player.input_device_name)
