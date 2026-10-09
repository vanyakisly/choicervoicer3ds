extends MenuBase
@onready var member_tile_static: MemberMenuTile = %MemberTileStatic
@onready var add_player_tile: ButtonCV = %AddPlayerTile
@onready var player_tile_list: HBoxContainer = %PlayerTileList

func _disable_static_tile_kill_button() -> void : member_tile_static.kill_button_visible = false

func _update_add_button_visible() -> void :
	if !add_player_tile: return
	if (player_tile_list.get_child_count() > 3):
		if M.unbound:
			if !add_player_tile.visible: add_player_tile.show()
		else:
			if add_player_tile.visible: add_player_tile.hide()
	else: if !add_player_tile.visible: add_player_tile.show()

func _set_first_tile_from_profile() -> void :
	for idx: int in range(member_tile_static.dropdown_packs.item_count):
		if (member_tile_static.dropdown_packs.get_item_metadata(idx) + "/") == Profile.contestant_slash:
			member_tile_static.dropdown_packs.select(idx)
			break
func _set_audio_device_from_profile() -> void :
	for idx: int in range(member_tile_static.dropdown_audio_devices.item_count):
		if (member_tile_static.dropdown_audio_devices.get_item_metadata(idx)) == Profile.audio_device_in:
			member_tile_static.dropdown_audio_devices.select(idx)
			break

func _add_player_tile(allow_kill: bool = true) -> void :
	var new_tile: MemberMenuTile = preload("res://scenes/nav_specific/play_flow/member_tile.tscn").instantiate()
	new_tile.kill_button_visible = allow_kill
	player_tile_list.add_child(new_tile)
func _next_page() -> void :
	var members: Array[BasicPlayerPackage] = []
	for tile: MemberMenuTile in player_tile_list.get_children(): members.append(BasicPlayerPackage.new(tile.contestant_pack_name, tile.audio_device))
	Metro.current_players = members
	call_slide("res://scenes/nav_specific/play_flow/select_game_mode_group.tscn", false)

func _ready() -> void :
	_disable_static_tile_kill_button()

	_add_player_tile(false)
	_set_first_tile_from_profile();member_tile_static.dropdown_packs.item_selected.emit(-1)
	_set_audio_device_from_profile()
