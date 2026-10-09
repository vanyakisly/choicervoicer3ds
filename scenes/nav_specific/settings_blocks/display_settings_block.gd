extends VBoxContainer


@onready var option_mode: OptionButton = %OptionMode
@onready var option_resolution: OptionButton = %OptionResolution
@onready var chk_snap_window_center: CheckButton = %ChkSnapWindowCenter
@onready var lbl_resolution: Label = %LblResolution


func _ready() -> void :
	_setup()
	_update()
	DisplayManager.window_mode_changed.connect(_update)


func _setup() -> void :
	option_mode.add_item("Windowed", 0)
	option_mode.set_item_metadata(0, 0)
	option_mode.add_item("Fullscreen", 1)
	option_mode.set_item_metadata(1, 1)
	option_mode.add_item("Borderless Window", 2)
	option_mode.set_item_metadata(2, 2)
	option_mode.add_item("Borderless Fullscreen", 3)
	option_mode.set_item_metadata(3, 3)

	option_resolution.add_item("1152 x 648", 0);option_resolution.set_item_metadata(0, DisplayManager.SCREEN_RESOLUTIONS.R1152)
	option_resolution.add_item("1280 x 720", 1);option_resolution.set_item_metadata(1, DisplayManager.SCREEN_RESOLUTIONS.R1280)
	option_resolution.add_item("1360 x 768", 2);option_resolution.set_item_metadata(2, DisplayManager.SCREEN_RESOLUTIONS.R1360)
	option_resolution.add_item("1366 x 768", 3);option_resolution.set_item_metadata(3, DisplayManager.SCREEN_RESOLUTIONS.R1366)
	option_resolution.add_item("1600 x 900", 4);option_resolution.set_item_metadata(4, DisplayManager.SCREEN_RESOLUTIONS.R1600)
	option_resolution.add_item("1920 x 1080", 5);option_resolution.set_item_metadata(5, DisplayManager.SCREEN_RESOLUTIONS.R1920)
	option_resolution.add_item("2560 x 1440", 6);option_resolution.set_item_metadata(6, DisplayManager.SCREEN_RESOLUTIONS.R2560)
	option_resolution.add_item("3200 x 1800", 7);option_resolution.set_item_metadata(7, DisplayManager.SCREEN_RESOLUTIONS.R3200)
	option_resolution.add_item("3840 x 2160", 8);option_resolution.set_item_metadata(8, DisplayManager.SCREEN_RESOLUTIONS.R3840)

	chk_snap_window_center.button_pressed = Profile.snap_window_to_center
	chk_snap_window_center.toggled.connect(Profile._set_snap_window_to_center)


func _update() -> void :
	option_mode.select(Profile.window_mode)
	option_resolution.select(Profile.window_resolution)
	_grey_out_resolution()

func _grey_out_resolution() -> void :
	match Profile.window_mode:
		1, 3: for node: Control in [lbl_resolution, option_resolution]: node.modulate = Color.DIM_GRAY
		0, 2: for node: Control in [lbl_resolution, option_resolution]: node.modulate = Color.WHITE

func _set_window_mode(_index: int) -> void : Profile.window_mode = option_mode.get_selected_metadata()
func _set_resolution(_index: int) -> void : Profile.window_resolution = option_resolution.get_selected_metadata()
