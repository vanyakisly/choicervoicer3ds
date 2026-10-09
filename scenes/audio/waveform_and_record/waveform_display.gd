@tool
class_name WaveformDisplay extends TextureRect




const PRINTSTR: String = "WaveformDisplay | "


@export var max_width: int = 600


@export var waveform_viewport: WaveformViewport: set = _set_waveform_viewport




func resize_from_viewport() -> void : custom_minimum_size.x = mini(max_width, waveform_viewport.size.x)


func _set_waveform_viewport(value: WaveformViewport) -> void :
	if !value: printerr(PRINTSTR + "The waveform viewport reference is being set to a null reference. Was this intended?")
	if waveform_viewport:
		if waveform_viewport.size_changed.is_connected(resize_from_viewport): waveform_viewport.size_changed.disconnect(resize_from_viewport)
	waveform_viewport = value
	if waveform_viewport: waveform_viewport.size_changed.connect(resize_from_viewport)


func _init() -> void :
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
