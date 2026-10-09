@icon("res://assets/gd_icons/waveform_drawer.png")
class_name WaveformDrawer extends Control



signal changed_custom_minimum_size


const PRINTSTR: String = "WaveformDrawer | "
const MIDLINE_UPPER: int = 254
const MIDLINE_LOWER: int = MIDLINE_UPPER + 4
const PITCH_VISUAL_MODIFIER: float = 1.333
const PITCH_LINE_THICKNESS: int = 4
const DIVISIONS: int = SpectrumSampler.PITCH_DIVISIONS
const PIXELSPERFRAME: float = 3.0


@export var waveform_color_average: = Color("ff00ff")
@export var waveform_color_maximum: = Color("ff00ff", 0.44)
@export var waveform_color_pitch: = Color("ff0000")
@export var aggregate_data_node: SpectrumAggregate: set = _set_aggregate_data_node




func _draw_magnitude_line(x: int, height: int, color: Color) -> void :
	draw_rect(Rect2(
		Vector2(x, MIDLINE_UPPER - height), 
		Vector2(1, height * 2)), color, true)
func _draw_interpolated_magnitude_lines(sample_index: int, samples: PackedByteArray, color: Color) -> void :
	var current: int = samples[sample_index];_draw_magnitude_line(sample_index * 3 + 1, current, color)
	if sample_index != 0: var previous: int = samples[sample_index - 1];_draw_magnitude_line(sample_index * 3, ceili((previous + current * 2.0) / 3.0), color)
	if sample_index < samples.size() - 1: var next: int = samples[sample_index + 1];_draw_magnitude_line(sample_index * 3 + 2, ceili((next + current * 2.0) / 3.0), color)
func _draw_waveform_interpolated() -> void : for sample_index: int in aggregate_data_node.size:
	_draw_interpolated_magnitude_lines(sample_index, aggregate_data_node.samples_magnitude_maximum, waveform_color_maximum)
	_draw_interpolated_magnitude_lines(sample_index, aggregate_data_node.samples_magnitude_average, waveform_color_average)
	var pitch_position: float = 512 - aggregate_data_node.samples_pitch[sample_index] * PITCH_VISUAL_MODIFIER
	draw_rect(Rect2(Vector2(sample_index * 3, pitch_position), Vector2(3, PITCH_LINE_THICKNESS)), waveform_color_pitch)
func _draw_magnitude_box(x: int, height: int, color: Color) -> void :
	height = maxi(2, height)
	draw_rect(Rect2(
		Vector2(x * 3, MIDLINE_UPPER - height), 
		Vector2(3, height * 2)), color, true)
func _draw_waveform_raw_multiplied() -> void : for sample_index: int in aggregate_data_node.size:
	_draw_magnitude_box(sample_index, aggregate_data_node.samples_magnitude_maximum[sample_index], waveform_color_maximum)
	_draw_magnitude_box(sample_index, aggregate_data_node.samples_magnitude_average[sample_index], waveform_color_average)
	var pitch_position: float = 512 - aggregate_data_node.samples_pitch[sample_index] * PITCH_VISUAL_MODIFIER
	draw_rect(Rect2(Vector2(sample_index * 3, pitch_position), Vector2(3, PITCH_LINE_THICKNESS)), waveform_color_pitch)


func _resize_from_aggregate() -> void :
	if aggregate_data_node: custom_minimum_size.x = PIXELSPERFRAME * aggregate_data_node.size
	else: custom_minimum_size.x = 1
	changed_custom_minimum_size.emit()


func _set_aggregate_data_node(value: SpectrumAggregate) -> void :
	if !value: printerr(PRINTSTR + "Aggregate data is being set to a null value. Was this intended?")
	if aggregate_data_node:
		if aggregate_data_node.data_updated.is_connected(queue_redraw): aggregate_data_node.data_updated.disconnect(queue_redraw)
		if aggregate_data_node.resized.is_connected(_resize_from_aggregate): aggregate_data_node.resized.disconnect(_resize_from_aggregate)
	aggregate_data_node = value
	if aggregate_data_node:
		aggregate_data_node.data_updated.connect(queue_redraw)
		aggregate_data_node.resized.connect(_resize_from_aggregate)


func _draw() -> void :
	if aggregate_data_node.size <= 600:
		_draw_waveform_interpolated()
	else:
		_draw_waveform_raw_multiplied()
