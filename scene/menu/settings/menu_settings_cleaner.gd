extends MenuBase

const SILENCE_1_75 = preload("res://audio/sfx/silence1-75.wav")
@export var live_mic_filler_clip: OmniClip
@onready var settings_pages: MarginContainer = %SettingsPages
@onready var array_page_selection: ButtonArray = $MarginContainer / ArrayPageSelection
@onready var button_cv_clip_selection_settings: ButtonCV = %ButtonCVClipSelectionSettings

var in_initial_setup: bool = true
var original_values: Dictionary = Profile.export_data()


func _on_array_page_selection_selection(index: int) -> void :
	for child_index: int in settings_pages.get_child_count():
		settings_pages.get_child(child_index).visible = child_index == index

func _ready():
	await get_tree().process_frame
	for child_index: int in settings_pages.get_child_count(): settings_pages.get_child(child_index).visible = child_index == 0
	in_initial_setup = false

func ReturnDiscard():
	BusWrite(M.data.settings)
	Profile.import_data(original_values)

func ReturnSave():
	M.ShowActivityHint(true, "Saving")
	BusWrite(M.data.settings)
	M.SaveData()
	M.ShowActivityHint(false)


func BusWrite(settings: Dictionary):
	BusWriteCrust(settings.mic.crust)
	AudioWriteDevices(settings.mic.devices)

func BusWriteCrust(crust: Dictionary):
	M.bus_master.crust_enabled(crust)
	M.bus_master.crust_settings(crust)

func AudioWriteDevices(devices: Dictionary): M.bus_master.audio_devices(devices)
