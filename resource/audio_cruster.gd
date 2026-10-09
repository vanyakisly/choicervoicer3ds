extends Resource
class_name AudioCruster


func crust_wav(input: AudioStreamWAV, sample_reduction: int) -> AudioStreamWAV:
	sample_reduction = clampi(sample_reduction, 0, 5)
	sample_reduction = 2 ** sample_reduction
	var data = input.get_data().duplicate()
	var crusted_data: PackedByteArray = []






	for datapoint_idx in range(0, data.size(), sample_reduction * 4):
		var crust_repeat: PackedByteArray = data.slice(datapoint_idx, datapoint_idx + 4)
		for i in range(sample_reduction):
			crusted_data.append_array(crust_repeat)

	var crust_audio: AudioStreamWAV = input.duplicate(true)
	crust_audio.set_data(crusted_data)
	return crust_audio
