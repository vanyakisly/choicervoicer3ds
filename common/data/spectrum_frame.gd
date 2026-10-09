class_name SpectrumFrame extends Resource


var byte_magnitude_average: int
var byte_magnitude_maximum: int
var byte_pitch: int


func set_samples(average: int, maximum: int, pitch: int) -> void :
	byte_magnitude_average = average
	byte_magnitude_maximum = maximum
	byte_pitch = pitch
func set_samples_from_percentage(average: float, maximum: float, pitch: float) -> void :
	set_magnitude_average_from_percentage(average)
	set_magnitude_maximum_from_percentage(maximum)
	set_pitch_from_percentage(pitch)


func _set_value_from_percentage(member_name: String, value: float, ceiling: bool) -> void :
	var test: int = get(member_name)
	set(member_name, "uh")
	value = clampf(value, 0.0, 1.0)
	if ceiling:

		set(member_name, ceili(255 * value))
	else:

		set(member_name, roundi(255 * value))
func set_magnitude_average_from_percentage(value: float, ceiling: bool = true) -> void : _set_value_from_percentage("byte_magnitude_average", value, ceiling)
func set_magnitude_maximum_from_percentage(value: float, ceiling: bool = true) -> void : _set_value_from_percentage("byte_magnitude_maximum", value, ceiling)
func set_pitch_from_percentage(value: float, ceiling: bool = true) -> void : _set_value_from_percentage("byte_pitch", value, ceiling)


func _set_byte_magnitude_average(value: int) -> void : byte_magnitude_average = clampi(value, 0, 255)
func _set_byte_magnitude_maximum(value: int) -> void : byte_magnitude_maximum = clampi(value, 0, 255)
func _set_byte_pitch(value: int) -> void : byte_pitch = clampi(value, 0, 255)
