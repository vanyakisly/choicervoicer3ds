extends VBoxContainer
@onready var option_button: OptionButton = %OptionButton
var temp_disable_select_trigger: bool = false
func _setup() -> void :
	option_button.clear()
	var device_list: PackedStringArray = AudioServer.get_input_device_list()
	for index: int in device_list.size():
		var device_name: String = device_list[index];option_button.add_item(device_name, index);option_button.set_item_metadata(index, device_name)
		if device_name == Profile.audio_device_in: temp_disable_select_trigger = true;option_button.select(index);temp_disable_select_trigger = false
func _device_selected(_index: int) -> void :
	if temp_disable_select_trigger: return
	var writeable_name: String = option_button.get_selected_metadata()
	Profile.audio_device_in = writeable_name
func _ready() -> void : _setup();option_button.button_down.connect(_setup)
