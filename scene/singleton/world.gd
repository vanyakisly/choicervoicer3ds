extends Node


@onready var primary_capsule = %PrimaryCapsule
@onready var blackout = %Blackout
@onready var active_hint_capsule = %ActiveHintCapsule
@onready var debug_info: Control = %DebugInfo


var tween: Tween




func _TEST_setup_volume_visuals() -> void :
	for hbox: Control in debug_info.get_child(1).get_children():
		hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if hbox is HBoxContainer:
			for child: Control in hbox.get_children(): child.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var keyword: String = hbox.name
			hbox.get_child(0).text = keyword
			hbox.get_child(0).custom_minimum_size.x = 84
			for idx: int in [1, 2, 3]:
				var bar: ProgressBar = hbox.get_child(idx)
				bar.allow_greater = true
			VolumeService.variables_changed_TEST.connect( func() -> void : hbox.get_child(1).value = VolumeService["base_volume_" + keyword])
			VolumeService.variables_changed_TEST.connect( func() -> void : hbox.get_child(2).value = VolumeService["modulate_volume_" + keyword])
			VolumeService.variables_changed_TEST.connect( func() -> void : hbox.get_child(3).value = VolumeService["base_volume_" + keyword] * VolumeService["modulate_volume_" + keyword])


func BlackoutDown(time: float = 0.75) -> void :
	if tween: tween.kill()
	tween = blackout.create_tween();blackout.color.a = 0.0;blackout.visible = true
	await tween.tween_property(blackout, "color:a", 1.0, time).finished
	if tween: tween.kill()
func BlackoutUp(time: float = 0.75) -> void :
	if tween: tween.kill()
	tween = blackout.create_tween()
	await tween.tween_property(blackout, "color:a", 0.0, time).finished
	blackout.visible = false
	if tween: tween.kill()
func ActiveHint(on: bool, text: String = "Loading", block_mouse: bool = true, show_bars: bool = true):
	if on:
		var active_hint: Control = load("res://scene/overlay/screen_active_hint.tscn").instantiate()
		if !block_mouse: active_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else: active_hint.mouse_filter = Control.MOUSE_FILTER_STOP
		active_hint.text = text
		for child in active_hint_capsule.get_children(): child.queue_free()
		active_hint_capsule.add_child(active_hint)
	else:
		for child in active_hint_capsule.get_children():
			child.text = text
			child.bars.visible = show_bars
			child.FadeOutAndDie(block_mouse)


func _standard_down(tween_volume: bool = true, load_text: String = "Loading") -> void :
	if tween_volume: VolumeService.tween_volume_music(0.0, 0.5)
	ActiveHint(true, load_text)
	await BlackoutDown()
	for child: Node in primary_capsule.get_children(): child.free()
func _standard_up(tween_volume: bool = true, post_load_time: float = 0.5) -> void :
	if tween_volume: VolumeService.tween_volume_music(1.0, 0.5)
	ActiveHint(false)
	if post_load_time: await get_tree().create_timer(post_load_time).timeout
	await BlackoutUp()
func _standard_load(path: String) -> void :
	await _standard_down()
	var new_scene: Node = load(path).instantiate();primary_capsule.add_child(new_scene)
	await _standard_up()


func CreateMenu() -> void : _standard_load("res://scene/menu/_master/menu_master.tscn")
func CreateSameLobby(lobby: Array) -> void :
	await _standard_down()
	var new_menu: Node = load("res://scene/menu/_master/menu_master.tscn").instantiate()






	new_menu.stopgap_ignore_standard_instruction = true
	primary_capsule.add_child(new_menu)
	new_menu.NewSlide("res://scenes/nav_specific/clip_selector_menus/clip_selection_standard.tscn", false)
	await _standard_up()
func CreateTutorial() -> void :
	await _standard_down()
	var tutorial: Node = load("res://scene/tutorial/tutorial_redux/tutorial_redux.tscn").instantiate()
	primary_capsule.add_child(tutorial)
	await _standard_up(false, 0.0)
func enter_metadata_editor() -> void :
	await _standard_down(false)
	var new_scene: Node = load("res://scenes/editors/clips/primary_voice_pack_editor.tscn").instantiate()
	primary_capsule.add_child(new_scene)
	ActiveHint(false)
	await BlackoutUp()
func return_to_dub_selection() -> void :
	await _standard_down()
	var new_menu: Node = load("res://scene/menu/_master/menu_master.tscn").instantiate()
	new_menu.stopgap_ignore_standard_instruction = true
	primary_capsule.add_child(new_menu)
	new_menu.NewSlide("res://scenes/nav_specific/clip_selector_menus/clip_selection_dub.tscn", false)
	await _standard_up()


func CreateMatch(_mailto: Dictionary = {}) -> void :
	await _standard_down()
	var new_match: Node = load("res://scene/match/match_master.tscn").instantiate()
	new_match.GENERIC_setup_from_metro()
	primary_capsule.add_child(new_match)
	await _standard_up()
func generate_session_twitch(_mailto: Dictionary = {}) -> void :
	await _standard_down()
	var new_match: Node = load("res://scene/match/match_master_twitch.tscn").instantiate()
	new_match.GENERIC_setup_from_metro()
	primary_capsule.add_child(new_match)
	await _standard_up()
func generate_session_twitch_panel() -> void :
	await _standard_down()




	var panelist_script: GDScript = load("res://scene/match/match_master_twitch_panel.gd")
	var new_scene: Node = load("res://scene/match/match_master.tscn").instantiate()
	new_scene.set_script(panelist_script)
	Metro.judge_master_uses_panelists = true
	new_scene.GENERIC_setup_from_metro()
	primary_capsule.add_child(new_scene)
	await _standard_up()
func enter_dub_mode() -> void : _standard_load("res://scenes/gameplay/dub_mode/main/dub_mode.tscn")
func enter_dub_freestyle() -> void : _standard_load("res://scenes/gameplay/dub_mode/peripheral/dub_mode_freestyle.tscn")

func enter_dub_cinema() -> void : _standard_load("res://scenes/gameplay/dub_mode/cinema/dub_cinema.tscn")


func ExitGame() -> void :
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()




func _ready() -> void :
	if M.data.player.first_time and not M.THISISDEMO:
		CreateTutorial()
