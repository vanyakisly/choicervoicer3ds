@tool
class_name WaveformViewport extends SubViewport




const PRINTSTR: String = "WaveformViewport | "


@export var buffer_left: TextureRect: set = _set_buffer_left
@export var buffer_right: TextureRect: set = _set_buffer_right
@export var waveform_drawers_container: Control: set = _set_waveform_drawers_container





func refresh_width() -> void :
	var previous_width: float = size.x
	size.x = buffer_left.custom_minimum_size.x + buffer_right.custom_minimum_size.x + waveform_drawers_container.custom_minimum_size.x
	if (size.x == previous_width): size_changed.emit()


func get_snapshot() -> Texture2D: return ImageTexture.create_from_image(get_texture().get_image())


func _set_buffer_left(value: TextureRect) -> void :
	if !value: printerr(PRINTSTR + "The left buffer reference is being set to a null instance. Was this intended?")
	if buffer_left:
		if buffer_left.resized.is_connected(refresh_width): buffer_left.resized.disconnect(refresh_width)
	buffer_left = value
	if buffer_left: buffer_left.resized.connect(refresh_width)
func _set_buffer_right(value: TextureRect) -> void :
	if !value: printerr(PRINTSTR + "The right buffer reference is being set to a null instance. Was this intended?")
	if buffer_right:
		if buffer_right.resized.is_connected(refresh_width): buffer_right.resized.disconnect(refresh_width)
	buffer_right = value
	if buffer_right: buffer_right.resized.connect(refresh_width)
func _set_waveform_drawers_container(value: Control) -> void :
	if !value: printerr(PRINTSTR + "The waveform drawers container reference is being set to a null instance. Was this intended?")
	if waveform_drawers_container:
		if waveform_drawers_container.resized.is_connected(refresh_width): waveform_drawers_container.resized.disconnect(refresh_width)
	waveform_drawers_container = value
	if waveform_drawers_container: waveform_drawers_container.resized.connect(refresh_width)
