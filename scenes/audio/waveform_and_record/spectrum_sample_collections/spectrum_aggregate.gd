class_name SpectrumAggregate extends Node


signal resized
signal data_updated


const PRINTSTR: String = "SpectrumAggregate | "
const SAMPLES_PER_SECOND: int = 60


var samples_magnitude_average: PackedByteArray
var samples_magnitude_maximum: PackedByteArray
var samples_pitch: PackedByteArray


@export var connected_sampler: AudioSpectrumSampler: set = _set_connected_sampler


var size: int:
	get: return samples_magnitude_average.size()
	set(value): resize_from_count(value)




func resize_from_count(count: int) -> void : emre.call_deferred();for a: PackedByteArray in all_arrays(): a.resize(count)
func resize_from_time(time: float) -> void : emre.call_deferred();for a: PackedByteArray in all_arrays(): a.resize(ceili(time * SAMPLES_PER_SECOND))
func resize_from_stream(stream: AudioStream) -> void : emre.call_deferred();for a: PackedByteArray in all_arrays(): a.resize(ceili(stream.get_length() * SAMPLES_PER_SECOND))
func clear() -> void : for a: PackedByteArray in all_arrays(): a.clear()
func fill(value: int) -> void : for a: PackedByteArray in all_arrays(): a.fill(value)
func remove_at(index: int) -> void : for a: PackedByteArray in all_arrays(): a.remove_at(index)


func all_arrays() -> Array[PackedByteArray]: return [samples_magnitude_average, samples_magnitude_maximum, samples_pitch]
func emre() -> void : resized.emit()


func new_spectrum_frame(collection: SpectrumFrame) -> void : pass


func _set_connected_sampler(value: AudioSpectrumSampler) -> void :
	if !value: printerr(PRINTSTR + "Connected sampler is being set to a null value. Was this intended?")

	if connected_sampler: if connected_sampler.sample_taken.is_connected(new_spectrum_frame): connected_sampler.sample_taken.disconnect(new_spectrum_frame)
	connected_sampler = value

	if connected_sampler: connected_sampler.sample_taken.connect(new_spectrum_frame)
