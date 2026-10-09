@icon("res://assets/gd_icons/spectrum_aggregate_endless.png")
class_name SpectrumAggregateEndless extends SpectrumAggregate





@export var accepting_new_frames: bool = true
@export var maximum_size: int: set = _set_maximum_size


func append_sampling(sampling: SpectrumFrame) -> void :
	if size >= maximum_size: remove_at(0)
	samples_magnitude_average.append(sampling.byte_magnitude_average)
	samples_magnitude_maximum.append(sampling.byte_magnitude_maximum)
	samples_pitch.append(sampling.byte_pitch)
	data_updated.emit()
func new_spectrum_frame(sampling: SpectrumFrame) -> void :
	if !accepting_new_frames: return
	append_sampling(sampling)


func _set_maximum_size(value: int) -> void : maximum_size = maxi(value, 1)
