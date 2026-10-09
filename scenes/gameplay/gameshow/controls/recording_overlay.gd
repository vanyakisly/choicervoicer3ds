class_name RecordingOverlay extends VBoxContainer



func _setup_nodes() -> void :
	var buffer: = Control.new();buffer.size_flags_vertical = Control.SIZE_EXPAND

func _setup_own_values() -> void :
	add_theme_constant_override("separation", 0)
