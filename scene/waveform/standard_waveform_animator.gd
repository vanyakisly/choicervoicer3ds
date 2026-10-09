class_name StandardWaveformAnimator extends SubViewport



const PRINTSTR: String = "StandardWaveformAnimator | "


@export var playbar: TextureRect
@export var waveform_drawer: WaveformDrawer: set = _set_waveform_drawer
@export var buffer_left: TextureRect
@export var buffer_right: TextureRect


@export var buffer_left_width: int = 78: set = _set_buffer_left_width
@export var buffer_rigth_width: int = 39: set = _set_buffer_right_width




func _set_buffer_left_width(value: int) -> void : buffer_left_width = value;buffer_left.custom_minimum_size.x = buffer_left_width;resize_from_children()
func _set_buffer_right_width(value: int) -> void : buffer_rigth_width = value;buffer_right.custom_minimum_size.x = buffer_rigth_width;resize_from_children()
func _set_waveform_drawer(value: WaveformDrawer) -> void :
	if !value: printerr(PRINTSTR + "The waveform drawer is being set to a null value. Was this intended?")
	if waveform_drawer: if waveform_drawer.changed_custom_minimum_size.is_connected(resize_from_children): waveform_drawer.changed_custom_minimum_size.disconnect(resize_from_children)
	waveform_drawer = value
	if waveform_drawer:
		waveform_drawer.changed_custom_minimum_size.connect(resize_from_children)


func resize_from_children() -> void :
	print(PRINTSTR + "resize_from_children()")
	size.x = buffer_left_width + buffer_rigth_width + waveform_drawer.custom_minimum_size.x




func reset_playbar() -> void : playbar.position.x = - playbar.custom_minimum_size.x
func play_playbar() -> void :
	for active_tween: Tween in get_tree().get_processed_tweens(): if active_tween.get_meta("is_waveform_playbar_tween", false): active_tween.kill()
	reset_playbar()
	var tween: Tween = create_tween()
	tween.set_meta("is_waveform_playbar_tween", true)
	tween.tween_property(playbar, "position:x", size.x, size.x / (60.0 * waveform_drawer.PIXELS_PER_FRAME))
