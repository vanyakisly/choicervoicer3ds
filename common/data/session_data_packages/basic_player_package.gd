class_name BasicPlayerPackage extends Resource
@export var pack_reference_name: String
@export var input_device_name: String
func _init(set_pack_reference_name: String, set_input_device_name: String) -> void :
	pack_reference_name = set_pack_reference_name
	input_device_name = set_input_device_name
