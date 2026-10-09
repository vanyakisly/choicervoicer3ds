class_name OmniClipMemberInstance extends Resource


@export var shared_omniclip: OmniClip


@export var member_audio: AudioStream
@export var member_waveform_texture: Texture2D
@export var data_vclip_average: PackedByteArray
@export var data_vclip_maximum: PackedByteArray
@export var data_vclip_pitches: PackedByteArray
@export var data_plmic_average: PackedByteArray
@export var data_plmic_maximum: PackedByteArray
@export var data_plmic_pitches: PackedByteArray
@export var score: float
var is_preserved_instance: bool




func write_vclip_data_from_aggregate(input: SpectrumAggregate) -> void :
	data_vclip_average = input.samples_magnitude_average.duplicate()
	data_vclip_maximum = input.samples_magnitude_maximum.duplicate()
	data_vclip_pitches = input.samples_pitch.duplicate()
func write_plmic_data_from_aggregate(input: SpectrumAggregate) -> void :
	data_plmic_average = input.samples_magnitude_average.duplicate()
	data_plmic_maximum = input.samples_magnitude_maximum.duplicate()
	data_plmic_pitches = input.samples_pitch.duplicate()


func generate_score() -> void :
	data_plmic_average.resize(data_vclip_average.size())
	data_plmic_maximum.resize(data_vclip_maximum.size())
	data_plmic_pitches.resize(data_vclip_pitches.size())
	score = MathService.gen_3_scorer(
		data_vclip_average, 
		data_vclip_maximum, 
		data_vclip_pitches, 
		data_plmic_average, 
		data_plmic_maximum, 
		data_plmic_pitches
	)


	var buffed_score: float = sqrt(maxf(score, 0.0) / 5.0)
	if buffed_score > 0.97: buffed_score = 1.0
	score = buffed_score * 5.0


func save_recording(as_file_name: String, target_location: String = FileManager.RECORDINGS) -> void :
	if !member_audio is AudioStreamWAV: return
	if !member_audio: printerr("OmniClipMemberInstance | No recording to save.");return
	if !as_file_name.ends_with(".wav"): as_file_name += ".wav"
	member_audio.save_to_wav(target_location + as_file_name)
	print("OmniClipMemberInstance | Recording saved.")

func preserve_data(as_file_name: String, target_location: String) -> void :
	if !DirAccess.dir_exists_absolute(target_location): DirAccess.make_dir_recursive_absolute(target_location)
	save_recording("preserved_" + as_file_name, target_location)
	if member_waveform_texture: member_waveform_texture.get_image().save_png(target_location + "preserved_waveform_%s.png" % as_file_name)
	var config: = ConfigFile.new()
	config.set_value("data", "data_vclip_average", data_vclip_average)
	config.set_value("data", "data_vclip_maximum", data_vclip_maximum)
	config.set_value("data", "data_vclip_pitches", data_vclip_pitches)
	config.set_value("data", "data_plmic_average", data_plmic_average)
	config.set_value("data", "data_plmic_maximum", data_plmic_maximum)
	config.set_value("data", "data_plmic_pitches", data_plmic_pitches)
	config.set_value("data", "score", score)
	VD.save_config(target_location + "preserved_data_%s.ini" % as_file_name, config, true, "613251")
func load_preserved_data(as_file_name: String, target_location: String) -> bool:
	member_audio = VD.get_audio_agnositc(target_location + "preserved_%s" % as_file_name)


	if !member_audio: return false
	member_waveform_texture = VD.get_texture_agnostic(target_location + "preserved_waveform_%s" % as_file_name)
	var config: = ConfigFile.new()
	config.load_encrypted_pass(target_location + "preserved_data_%s.ini" % as_file_name, "613251")

	data_vclip_average = config.get_value("data", "data_vclip_average", data_vclip_average)
	data_vclip_maximum = config.get_value("data", "data_vclip_maximum", data_vclip_maximum)
	data_vclip_pitches = config.get_value("data", "data_vclip_pitches", data_vclip_pitches)
	data_plmic_average = config.get_value("data", "data_plmic_average", data_plmic_average)
	data_plmic_maximum = config.get_value("data", "data_plmic_maximum", data_plmic_maximum)
	data_plmic_pitches = config.get_value("data", "data_plmic_pitches", data_plmic_pitches)
	score = config.get_value("data", "score", score)
	is_preserved_instance = true
	return true
