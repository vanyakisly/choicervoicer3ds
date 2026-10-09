extends Node


signal camera_change(camera_global: Vector3)

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var sidebar: ColorRect = %Sidebar

@onready var back_camera: Camera3D = %BackCamera
@onready var seats_camera: Camera3D = %SeatsCamera
@onready var seats: Node3D = %Seats
@onready var screen: Sprite3D = %Screen
@onready var player: DubStreamPlayer = %DubStreamPlayer
@onready var button_seating_grid: GridContainer = %ButtonSeatingGrid
@onready var lbl_recordings_for: Label = %LblRecordingsFor
@onready var fullscreen: ColorRect = %Fullscreen

@onready var page_dubs: VBoxContainer = %PageDubs
@onready var page_seating: VBoxContainer = %PageSeating
@onready var page_audio: VBoxContainer = %PageAudio

@onready var btn_new_audience: ButtonCV = %BtnNewAudience
@onready var btn_play_stop_dub: ButtonCV = %BtnPlayStopDub
@onready var btn_back_view: ButtonCV = %BtnBackView
@onready var btn_fullscreen: ButtonCV = %BtnFullscreen

@onready var chk_mute_backing_track: CheckButton = %ChkMuteBackingTrack
@onready var lbl_volume_master: Label = %LblVolumeMaster
@onready var lbl_volume_voice: Label = %LblVolumeVoice
@onready var lbl_volume_sound_effects: Label = %LblAllSoundEffects
@onready var lbl_volume_button_sounds: Label = %LblButtonSfx
@onready var slider_volume_master: HSlider = %SliderMaster
@onready var slider_volume_voice: HSlider = %SliderVoice
@onready var slider_volume_sound_effects: HSlider = %SliderAllSoundEffects
@onready var slider_volume_button_sounds: HSlider = %SliderButtonSfx
@onready var chk_mute_audience: CheckButton = %ChkMuteAudience
@onready var tree: VoicePackTree = %Tree
@onready var tree_recordings: Tree = %TreeRecordings
@onready var chk_create_audience_automatically: CheckButton = %ChkCreateAudienceAutomatically
@onready var chk_start_fullscreened: CheckButton = %ChkStartFullscreened


var active_seat: CinemaSeat
var active_seat_index: int
var dub_playing: bool

var active_dub: String
var queued_dub: String


func _ready() -> void :
	%VisualBlocker.show()
	_setup()
	if Profile.dub_cinema_autoload_audience: await create_audience()
	%VisualBlocker.hide()
	for seat: CinemaSeat in _get_all_seats(): camera_change.connect(seat.adjust_sprite_gap)
	for i: int in button_seating_grid.get_child_count():
		var btn: ButtonCV = button_seating_grid.get_child(i)
		btn.button_clicked.connect(sit_at.bind(i))
	if Metro.cinema_came_from_dub_mode:
		player.load_dub(Metro.cinema_from_dub_mode)
		$Control / Sidebar / MarginContainer / VBoxContainer / PageDubs / Label4.text = "%s\n%s" % [Metro.cinema_name[0], Metro.cinema_name[1]]
		await get_tree().create_timer(0.5).timeout
		btn_play_stop_dub.enable(true)
		btn_play_stop_dub.click()



func _setup() -> void :
	_setup_visuals()
	_setup_tree_recordings()
	_audio_options_setup()
	_additional_settings_setup()
func _setup_visuals() -> void :
	page_dubs.show()
	page_seating.hide()
	page_audio.hide()
	fullscreen.hide()
	if Profile.dub_cinema_start_fullscreened: fullscreen_view()
func _setup_tree_recordings() -> void :
	tree_recordings.create_item()
	tree_recordings.auto_tooltip = false
	tree_recordings.add_theme_constant_override("v_separation", -2)
func _audio_options_setup() -> void :
	chk_mute_backing_track.toggled.connect(Profile._set_dub_mode_mute_backing_track)
	chk_mute_backing_track.button_pressed = Profile.dub_mode_mute_backing_track
	_connect_signals_volumes()
	_onready_slider_match_volumes()
	_update_labels_volumes()
	chk_mute_audience.button_pressed = Profile.dub_cinema_mute_audience
func _additional_settings_setup() -> void :
	chk_create_audience_automatically.set_pressed_no_signal(Profile.dub_cinema_autoload_audience)
	chk_start_fullscreened.set_pressed_no_signal(Profile.dub_cinema_start_fullscreened)
	chk_create_audience_automatically.toggled.connect(Profile._set_dub_cinema_autoload_audience)
	chk_start_fullscreened.toggled.connect(Profile._set_dub_cinema_start_fullscreened)



func _watch() -> void :
	player.play_dub()
	dub_playing = true
	btn_play_stop_dub.set_first_label_text("■ Stop")

func _dub_finished() -> void :
	dub_playing = false
	await get_tree().create_timer(0.33).timeout
	cheer()
	btn_play_stop_dub.set_first_label_text("▶ Play")

func _stop_dub() -> void :
	player.stop_dub()
	dub_playing = false
	btn_play_stop_dub.set_first_label_text("▶ Play")


func create_audience(audience: Array[CinemaSeat] = _get_all_seats()) -> void :
	var contestants: Array = DirAccess.get_directories_at(FileManager.MODPACKS_CONTESTANT)
	var judges: Array = []
	for dir: String in DirAccess.get_directories_at(FileManager.MODPACKS_JUDGES):
		var slice: PackedStringArray = ["", "", "", "", ""]
		for i: int in range(5): slice[i] = "/?JUDGE" + dir + "/%s" % i
		judges.append_array(slice)
	var all: Array = [];all.append_array(contestants);all.append_array(judges)
	all.shuffle()
	audience.shuffle()
	for seat: CinemaSeat in audience:
		if !all: return
		seat.load_character_either(all.pop_back())
		await get_tree().process_frame


func _clear_audience() -> void : for seat: CinemaSeat in _get_all_seats(): seat.clear_character()
func _new_audience() -> void :
	btn_new_audience.enable(false)
	_clear_audience()
	await create_audience()
	btn_new_audience.enable(true)


func back_view() -> void :
	if fullscreen.visible:
		fullscreen.hide()
		btn_fullscreen.enable(true)
	back_camera.make_current()
	camera_change.emit(back_camera.global_position)
	for btn: ButtonCV in button_seating_grid.get_children(): if !btn.enabled: btn.enable(true)
	btn_back_view.enable(false)
func sit_at(index: int) -> void :
	if fullscreen.visible:
		fullscreen.hide()
		btn_fullscreen.enable(true)
	for i: int in button_seating_grid.get_child_count():
		var btn: ButtonCV = button_seating_grid.get_child(i)
		if !btn.enabled and index != i: btn.enable(true)
		elif index == i: btn.enable(false)
	if !btn_back_view.enabled: btn_back_view.enable(true)
	var seat: CinemaSeat = _get_seat_by_index(index)
	if active_seat: active_seat.character_visible(true)
	active_seat = seat
	seat.character_visible(false)
	seats_camera.position = seat.get_camera_position()
	seats_camera.look_at(screen.position + Vector3.FORWARD * 3.0)
	seats_camera.make_current()
	camera_change.emit(seats_camera.global_position)
func random_seat_view() -> void : sit_at(randi_range(0, 23))
func fullscreen_view() -> void :
	fullscreen.show()
	btn_fullscreen.enable(false)
	btn_back_view.enable(true)
	for btn: ButtonCV in button_seating_grid.get_children(): if !btn.enabled: btn.enable(true)

func _get_all_seats() -> Array[CinemaSeat]:
	var output: Array[CinemaSeat] = []
	for n3d: Node3D in seats.get_children(): for seat: CinemaSeat in n3d.get_children(): output.append(seat)
	return output
func _get_seat_by_index(i: int) -> CinemaSeat:
	i = clampi(i, 0, 23)
	return seats.get_child(floori(i / 6.0)).get_child(i % 6)


func cheer() -> void : for seat: CinemaSeat in _get_all_seats(): seat.react(1.0)
func shut_up_the_house() -> void : for seat: CinemaSeat in _get_all_seats(): seat.stop(1.2)


func dub_recording_selected() -> void : pass


func list_dubs_recordings(pack: PackInfo) -> void :
	for child: TreeItem in tree_recordings.get_root().get_children(): child.free()
	lbl_recordings_for.text = ""
	if !pack.has_dub_video_file: return
	if !pack.has_recordings_folder(): return
	lbl_recordings_for.text = "Recordings for\n%s" % pack.display_name
	for rec_folder: String in pack.get_recordings_list():
		var item: TreeItem = tree_recordings.get_root().create_child()
		item.set_text(0, rec_folder)
		item.set_meta("dub_load_path", pack.path_from_pack + rec_folder)



func new_dub_selected() -> void :
	btn_play_stop_dub.enable(false)
	if player.is_playing(): _stop_dub()
	player.load_dub(FileManager.RECORDINGS_DUBS + tree_recordings.get_selected().get_meta("dub_load_path"))
	$Control / Sidebar / MarginContainer / VBoxContainer / PageDubs / Label4.text = "%s\n%s" % [ %Tree.get_selected().get_text(0), tree_recordings.get_selected().get_text(0)]
	btn_play_stop_dub.enable(true)

func _input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_mouse2"):
		M.sfx_back.play()
		_on_btn_sidebar_button_clicked()
func _unhandled_input(event: InputEvent) -> void :






	if seats_camera.current:
		if event is InputEventMouseMotion and Input.is_action_pressed("ui_mouse1"):
			_mouse_movement(event)
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif Input.is_action_just_released("ui_mouse1"): Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func _mouse_movement(event: InputEventMouseMotion) -> void :
	if seats_camera:
		seats_camera.rotation.y += event.screen_relative.x / 270
		seats_camera.rotation.x = clampf(seats_camera.rotation.x + event.screen_relative.y / 270, - PI / 2.0, PI / 2.0)


func _on_btn_leave_button_clicked() -> void :
	if Metro.cinema_came_from_dub_mode:
		M.world.return_to_dub_selection()
	else:
		M.world.CreateMenu()
func _exit_tree() -> void :
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Metro.cinema_came_from_dub_mode: Metro.cinema_came_from_dub_mode = false
func _on_btn_play_stop_dub_button_clicked() -> void :
	if dub_playing: _stop_dub()
	else:
		shut_up_the_house()
		_watch()
func _on_array_page_selection_selection(index: int) -> void :
	match index:
		0: page_dubs.show();page_seating.hide();page_audio.hide()
		1: page_dubs.hide();page_seating.show();page_audio.hide()
		2: page_dubs.hide();page_seating.hide();page_audio.show()


func _connect_signals_volumes() -> void :
	slider_volume_master.value_changed.connect(Profile._set_volume_master)
	slider_volume_voice.value_changed.connect(Profile._set_volume_voice_clips)
	slider_volume_sound_effects.value_changed.connect(Profile._set_volume_sfx)
	slider_volume_button_sounds.value_changed.connect(Profile._set_volume_buttons)

	slider_volume_master.value_changed.connect(_update_labels_volumes)
	slider_volume_voice.value_changed.connect(_update_labels_volumes)
	slider_volume_sound_effects.value_changed.connect(_update_labels_volumes)
	slider_volume_button_sounds.value_changed.connect(_update_labels_volumes)

func _onready_slider_match_volumes() -> void :
	slider_volume_master.set_value_no_signal(Profile.volume_master)
	slider_volume_voice.set_value_no_signal(Profile.volume_voice_clips)
	slider_volume_sound_effects.set_value_no_signal(Profile.volume_sfx)
	slider_volume_button_sounds.set_value_no_signal(Profile.volume_buttons)

func _update_labels_volumes(_dummy: float = 0.0) -> void :
	lbl_volume_master.text = "%1.0f%%" % [Profile.volume_master * 100.0];lbl_volume_master.add_theme_color_override("font_color", Color.ORANGE) if (Profile.volume_master > 1.01) else lbl_volume_master.add_theme_color_override("font_color", Color.WHITE)
	lbl_volume_voice.text = "%1.0f%%" % [Profile.volume_voice_clips * 100.0];lbl_volume_voice.add_theme_color_override("font_color", Color.ORANGE) if (Profile.volume_voice_clips > 1.01) else lbl_volume_voice.add_theme_color_override("font_color", Color.WHITE)
	lbl_volume_sound_effects.text = "%1.0f%%" % [Profile.volume_sfx * 100.0];lbl_volume_sound_effects.add_theme_color_override("font_color", Color.ORANGE) if (Profile.volume_sfx > 1.01) else lbl_volume_sound_effects.add_theme_color_override("font_color", Color.WHITE)
	lbl_volume_button_sounds.text = "%1.0f%%" % [Profile.volume_buttons * 100.0];lbl_volume_button_sounds.add_theme_color_override("font_color", Color.ORANGE) if (Profile.volume_buttons > 1.01) else lbl_volume_button_sounds.add_theme_color_override("font_color", Color.WHITE)


func _on_btn_sidebar_button_clicked() -> void :
	if sidebar.position.x >= -103:
		animation_player.play_backwards("sidebar")
	else:
		animation_player.play("sidebar")


func _audience_muting(toggle_on: bool) -> void :
	Profile.dub_cinema_mute_audience = toggle_on
	for seat: CinemaSeat in _get_all_seats():
		if Profile.dub_cinema_mute_audience: seat.mute()
		else: seat.unmute()
