@icon("res://assets/gd_icons/spectrum_aggregate_finite.png")
class_name SpectrumAggregateFinite extends SpectrumAggregate


signal samples_filled


@export var sample_index: int
var full: bool:
	get: return sample_index >= size




func write_sample(sampling: SpectrumFrame) -> void :
	samples_magnitude_average[sample_index] = sampling.byte_magnitude_average
	samples_magnitude_maximum[sample_index] = sampling.byte_magnitude_maximum
	samples_pitch[sample_index] = sampling.byte_pitch
	sample_index += 1
	data_updated.emit()
	if sample_index == size:
		samples_filled.emit()
func new_spectrum_frame(sampling: SpectrumFrame) -> void :

	if full: samples_filled.emit();return
	write_sample(sampling)
