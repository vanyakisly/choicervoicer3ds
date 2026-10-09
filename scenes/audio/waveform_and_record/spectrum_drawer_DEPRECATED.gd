class_name SpectrumDrawer extends Control


const MIDLINE_UPPER: int = 254
const MIDLINE_LOWER: int = MIDLINE_UPPER + 4
const PITCH_VISUAL_MODIFIER: float = 1.333
const PITCH_LINE_THICKNESS: int = 4

@export var waveform_color_average: = Color("ff00ff")
@export var waveform_color_maximum: = Color("ff00ff", 0.44)
@export var waveform_color_pitch: = Color("ff0000")


@export var spectrum_sampler: SpectrumSampler


func _ready() -> void :
	_connect_signals()


func _connect_signals() -> void :
	spectrum_sampler.taken_sample.connect(queue_redraw)


func _draw() -> void :





	if spectrum_sampler.size <= 600:
		_draw_waveform_interpolated()
	else:
		_draw_waveform_raw_multiplied()


func _draw_waveform_raw_multiplied() -> void :
	for sample_index: int in spectrum_sampler.size:


		_draw_magnitude_box(sample_index, spectrum_sampler.samples_magnitude_maximum[sample_index], waveform_color_maximum)
		_draw_magnitude_box(sample_index, spectrum_sampler.samples_magnitude_average[sample_index], waveform_color_average)












		var pitch_position: float = 512 - spectrum_sampler.samples_pitch[sample_index] * PITCH_VISUAL_MODIFIER
		draw_rect(Rect2(Vector2(sample_index * 3, pitch_position), Vector2(3, PITCH_LINE_THICKNESS)), waveform_color_pitch)


func _draw_waveform_interpolated() -> void :
	for sample_index: int in spectrum_sampler.size:
		_draw_interpolated_magnitude_lines(sample_index, spectrum_sampler.samples_magnitude_maximum, waveform_color_maximum)
		_draw_interpolated_magnitude_lines(sample_index, spectrum_sampler.samples_magnitude_average, waveform_color_average)

		var pitch_position: float = 512 - spectrum_sampler.samples_pitch[sample_index] * PITCH_VISUAL_MODIFIER
		draw_rect(Rect2(Vector2(sample_index * 3, pitch_position), Vector2(3, PITCH_LINE_THICKNESS)), waveform_color_pitch)



func _draw_magnitude_line(x: int, height: int, color: Color) -> void :
	draw_rect(Rect2(
		Vector2(x, MIDLINE_UPPER - height), 
		Vector2(1, height * 2)
	), color, true)

func _draw_magnitude_box(x: int, height: int, color: Color) -> void :
	x *= 3
	height = maxi(2, height)
	draw_rect(Rect2(
		Vector2(x, MIDLINE_UPPER - height), 
		Vector2(3, height * 2)
	), color, true)

func _draw_interpolated_magnitude_lines(sample_index: int, samples: PackedByteArray, color: Color) -> void :
	var current: int = samples[sample_index]
	_draw_magnitude_line(sample_index * 3 + 1, current, color)
	if sample_index != 0:
		var previous: int = samples[sample_index - 1]
		_draw_magnitude_line(sample_index * 3, ceili((previous + current * 2.0) / 3.0), color)
	if sample_index < samples.size() - 1:
		var next: int = samples[sample_index + 1]
		_draw_magnitude_line(sample_index * 3 + 2, ceili((next + current * 2.0) / 3.0), color)




const DIVISIONS: int = SpectrumSampler.PITCH_DIVISIONS
func DrawSample():
	var waveheight: float = size.y / 128.0 / 2.0
	var y_pos: float = position.y + size.y / 2.0
	InterpolatedRect(spectrum_sampler.samples_magnitude_maximum, waveheight, y_pos, waveform_color_maximum)
	InterpolatedRect(spectrum_sampler.samples_magnitude_average, waveheight, y_pos, waveform_color_average)

	waveheight = (size.y * 0.4)
	for pitch_idx in spectrum_sampler.samples_pitch.size():
		var pitch_sample: float = (2.5 - spectrum_sampler.samples_pitch[pitch_idx] / float(DIVISIONS)) * waveheight
		draw_line(Vector2(pitch_idx * PIXELSPERFRAME, pitch_sample), \
		Vector2(pitch_idx * PIXELSPERFRAME + PIXELSPERFRAME, pitch_sample), waveform_color_pitch, 2.0)


const PIXELSPERFRAME: float = 3.0
func InterpolatedRect(sample: PackedByteArray, waveheight: float, y_pos: float, clr: Color):
	for idx in sample.size():
		if idx == 0:
			var height: float = max(1.0, sample[idx] * waveheight)
			draw_rect(Rect2(
				Vector2(idx * PIXELSPERFRAME, y_pos - height / 2.0), \
				Vector2(PIXELSPERFRAME, height)), clr, true)
		elif idx != sample.size() - 1:
			var height: float = max(1.0, (sample[idx] * 2.0 + sample[idx - 1]) / 3.0 * waveheight)
			draw_rect(Rect2(
				Vector2(idx * PIXELSPERFRAME, y_pos - height / 2.0), \
				Vector2(1, height)), clr, true)
			height = max(1, sample[idx] * waveheight)
			draw_rect(Rect2(
				Vector2(idx * PIXELSPERFRAME + 1, y_pos - height / 2.0), \
				Vector2(1, height)), clr, true)
			height = max(1, (sample[idx] * 2.0 + sample[idx + 1]) / 3.0 * waveheight)
			draw_rect(Rect2(
				Vector2(idx * PIXELSPERFRAME + 2.0, y_pos - height / 2.0), \
				Vector2(1, height)), clr, true)
		else:
			var height: float = max(1.0, (sample[idx] * 2.0 + sample[idx - 1]) / 3.0 * waveheight)
			draw_rect(Rect2(
				Vector2(idx * PIXELSPERFRAME, y_pos - height / 2.0), \
				Vector2(1, height)), clr, true)
			height = max(1.0, sample[idx] * waveheight)
			draw_rect(Rect2(
				Vector2(idx * PIXELSPERFRAME + 1.0, y_pos - height / 2.0), \
				Vector2(PIXELSPERFRAME - 1.0, height)), clr, true)
