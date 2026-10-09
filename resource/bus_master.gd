extends Node
class_name BusMaster


var bi_music: int = AudioServer.get_bus_index("Music")
var bi_voice: int = AudioServer.get_bus_index("Voice")
var bi_plmic: int = AudioServer.get_bus_index("Plmic")


























func load_van_volumes_from(vans: Dictionary = M.data.settings.volume) -> void :


	for van in vans.keys():
		if van_data.has(van):
			van_data[van].volume = vans[van]



func van_volume_to_bus(van: Dictionary) -> void :

	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(van.bus), linear_to_db(van.volume * van.quietus))

func apply_all_vans_to_buses() -> void :
	for bus in van_data.keys():
		van_volume_to_bus(van_data[bus])

func reset_all_quietus() -> void :
	for van in van_data.keys():
		van_data[van].quietus = 1.0

func extract_van_volumes() -> Dictionary:

	var extract: Dictionary = {}
	for van in van_data.keys():
		extract[van] = van_data[van].volume
	return extract



func tween_van_quietus(van_name: String, to_db: float, seconds: float, wait: bool = false):




	var quietus_tween = create_tween()
	var van: Dictionary = van_data[van_name]

	var animate_quietus = func(volume_db: float):
		van.quietus = db_to_linear(volume_db)
		van_volume_to_bus(van)
	var quietus_db = linear_to_db(van.quietus)
	if to_db > quietus_db: quietus_tween.set_ease(Tween.EASE_IN)
	else: quietus_tween.set_ease(Tween.EASE_OUT)

	if wait: await quietus_tween.tween_method(animate_quietus, quietus_db, to_db, seconds).finished
	else: quietus_tween.tween_method(animate_quietus, quietus_db, to_db, seconds)






const AMOUNT: float = 1.1
const SHIFTUP: float = 0.0
const TIMESPERSEC: float = 50
const TIMELENGTH: float = 1.0 / TIMESPERSEC / 2.0
var oil_tween
func OilVibrato(play: bool = true):
	if not play:
		if oil_tween:
			oil_tween.kill()
	else:
		var pitch_shift_effect: AudioEffectPitchShift = AudioServer.get_bus_effect(bi_plmic, 6)
		if oil_tween:
			oil_tween.kill()
		oil_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		oil_tween.tween_property(pitch_shift_effect, "pitch_scale", 1.0 * AMOUNT + SHIFTUP, TIMELENGTH)
		oil_tween.tween_property(pitch_shift_effect, "pitch_scale", 1.0 / AMOUNT + SHIFTUP, TIMELENGTH)


func crust_enabled(crust: Dictionary):
	AudioServer.set_bus_effect_enabled(bi_plmic, 1, type_convert(crust.get("mic_crust_compressor_on", false), TYPE_BOOL))
	AudioServer.set_bus_effect_enabled(bi_plmic, 2, type_convert(crust.get("mic_crust_cutoff_on", false), TYPE_BOOL))
	AudioServer.set_bus_effect_enabled(bi_plmic, 3, type_convert(crust.get("mic_crust_cutoff_on", false), TYPE_BOOL))
	AudioServer.set_bus_effect_enabled(bi_plmic, 4, type_convert(crust.get("mic_crust_distortion_on", false), TYPE_BOOL))
	AudioServer.set_bus_effect_enabled(bi_plmic, 5, type_convert(crust.get("mic_crust_limiter_on", false), TYPE_BOOL))


func oil(do: bool):
	AudioServer.set_bus_effect_enabled(bi_plmic, 6, do)
	OilVibrato(do)


func crust_settings(crust: Dictionary):
	var amplifier: AudioEffectAmplify = AudioServer.get_bus_effect(bi_plmic, 0)
	var compressor: AudioEffectCompressor = AudioServer.get_bus_effect(bi_plmic, 1)
	var highpass: AudioEffectHighPassFilter = AudioServer.get_bus_effect(bi_plmic, 2)
	var lowpass: AudioEffectLowPassFilter = AudioServer.get_bus_effect(bi_plmic, 3)
	var distortion: AudioEffectDistortion = AudioServer.get_bus_effect(bi_plmic, 4)
	var limiter: AudioEffectLimiter = AudioServer.get_bus_effect(bi_plmic, 5)
	amplifier.volume_db = linear_to_db(crust.mic_input)
	compressor.threshold = crust.compressor_threshold
	compressor.gain = crust.compressor_gain
	highpass.cutoff_hz = crust.cutoff_high_pass
	lowpass.cutoff_hz = crust.cutoff_low_pass
	distortion.pre_gain = crust.distortion_pre_gain
	distortion.drive = crust.distortion_drive
	distortion.post_gain = crust.distortion_post_gain
	limiter.ceiling_db = crust.limiter_ceilingdb
	limiter.threshold_db = crust.limiter_thresholddb


func audio_devices(devices: Dictionary):
	if AudioServer.get_input_device_list().has(devices.audio_in):
		print("BusMaster | Devices has chosen in of '%s'" % devices.audio_in)
		AudioServer.set_input_device(devices.audio_in)
	else: print("BusMaster | Device in of '%s' not found" % devices.audio_in)
	if AudioServer.get_output_device_list().has(devices.audio_out):
		print("BusMaster | Devices has chosen out of '%s'" % devices.audio_out)
		AudioServer.set_output_device(devices.audio_out)
	else: print("BusMaster | Device out of '%s' not found" % devices.audio_out)
	print("\n")


func SetupVanTween(actual_used: PackedStringArray):
	for key in van_data.keys():
		if actual_used.has(key):
			van_data[key]["tween"] = create_tween()


var van_data: Dictionary = {
	"master": {
		"bus": "Master", 
		"volume": 1.0, 
		"quietus": 1.0
	}, 
	"music": {
		"bus": "Music", 
		"volume": 1.0, 
		"quietus": 1.0
	}, 
	"sound_effects": {
		"bus": "SfxMain", 
		"volume": 1.0, 
		"quietus": 1.0
	}, 
	"button_sounds": {
		"bus": "SfxButton", 
		"volume": 1.0, 
		"quietus": 1.0
	}, 
	"voice": {
		"bus": "Voice", 
		"volume": 1.0, 
		"quietus": 1.0
	}, 
	"clip_playback": {
		"bus": "VclipPlayback", 
		"volume": 1.0, 
		"quietus": 1.0
	}, 
	"audience": {
		"bus": "Twitch", 
		"volume": 1.0, 
		"quietus": 1.0
	}, 
	"pecho": {
		"bus": "Pecho", 
		"volume": 1.0, 
		"quietus": 1.0
	}, 





}
