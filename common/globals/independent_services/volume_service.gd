extends Node


signal variables_changed_TEST


const TWEEN_META_VOLUME_MASTER_GOTO: String = "tween_meta_volume_master_goto"
const TWEEN_META_VOLUME_MUSIC_GOTO: String = "tween_meta_volume_music_goto"
const TWEEN_META_VOLUME_VOICE_GOTO: String = "tween_meta_volume_voice_goto"
const TWEEN_META_VOLUME_CHATTER_GOTO: String = "tween_meta_volume_chatter_goto"


const PLMIC_EFFECT_INDEX_AMPLIFY: int = 0
const PLMIC_EFFECT_INDEX_COMPRESSOR: int = 1
const PLMIC_EFFECT_INDEX_HIGH_PASS: int = 2
const PLMIC_EFFECT_INDEX_LOW_PASS: int = 3
const PLMIC_EFFECT_INDEX_DISTORTION: int = 4
const PLMIC_EFFECT_INDEX_LIMITER: int = 5
const PLMIC_EFFECT_INDEX_RECORD: int = 7
const PLMIC_EFFECT_INDEX_SPECTRUM: int = 8


var BUS_MASTER: int = AudioServer.get_bus_index("Master")
var BUS_MUSIC: int = AudioServer.get_bus_index("Music")
var BUS_VOICE: int = AudioServer.get_bus_index("Voice")
var BUS_PECHO: int = AudioServer.get_bus_index("Pecho")
var BUS_ALL_SFX: int = AudioServer.get_bus_index("SfxMain")
var BUS_BUTTONS: int = AudioServer.get_bus_index("SfxButton")
var BUS_PLAYBACK: int = AudioServer.get_bus_index("VclipPlayback")
var BUS_SFX_JUDGES: int = AudioServer.get_bus_index("SfxJudges")
var BUS_PLMIC: int = AudioServer.get_bus_index("Plmic")
var BUS_VCLIP: int = AudioServer.get_bus_index("Vclip")
var BUS_VCLIP_DUAL_A: int = AudioServer.get_bus_index("VclipDualA")
var BUS_VCLIP_DUAL_B: int = AudioServer.get_bus_index("VclipDualB")
var BUS_CHATTER: int = AudioServer.get_bus_index("Chatter")


var base_volume_master: float: set = _set_base_volume_master
var base_volume_music: float: set = _set_base_volume_music
var base_volume_voice: float: set = _set_base_volume_voice
var base_volume_recordings: float: set = _set_base_volume_recordings
var base_volume_sfx: float: set = _set_base_volume_sfx
var base_volume_buttons: float: set = _set_base_volume_buttons
var base_volume_sfx_judges: float: set = _set_base_volume_sfx_judges
var base_volume_playback: float: set = _set_base_volume_playback
var base_volume_chatter: float: set = _set_base_volume_chatter


var modulate_volume_master: float = 1.0: set = _set_modulate_volume_master
var modulate_volume_music: float = 1.0: set = _set_modulate_volume_music
var modulate_volume_voice: float = 1.0: set = _set_modulate_volume_voice
var modulate_volume_recordings: float = 1.0: set = _set_modulate_volume_recordings
var modulate_volume_sfx: float = 1.0: set = _set_modulate_volume_sfx
var modulate_volume_buttons: float = 1.0: set = _set_modulate_volume_buttons
var modulate_volume_sfx_judges: float = 1.0: set = _set_modulate_volume_sfx_judges
var modulate_volume_playback: float = 1.0: set = _set_modulate_volume_playback
var modulate_volume_chatter: float = 1.0: set = _set_modulate_volume_chatter


func _set_base_volume_master(value: float) -> void : base_volume_master = value;_set_bus_volume_master(base_volume_master * modulate_volume_master)
func _set_base_volume_music(value: float) -> void : base_volume_music = value;_set_bus_volume_music(base_volume_music * modulate_volume_music)
func _set_base_volume_voice(value: float) -> void : base_volume_voice = value;_set_bus_volume_voice(base_volume_voice * modulate_volume_voice)
func _set_base_volume_recordings(value: float) -> void : base_volume_recordings = value;_set_bus_volume_recordings(base_volume_recordings * modulate_volume_recordings)
func _set_base_volume_sfx(value: float) -> void : base_volume_sfx = value;_set_bus_volume_sfx(base_volume_sfx * modulate_volume_sfx)
func _set_base_volume_buttons(value: float) -> void : base_volume_buttons = value;_set_bus_volume_buttons(base_volume_buttons * modulate_volume_buttons)
func _set_base_volume_sfx_judges(value: float) -> void : base_volume_sfx_judges = value;_set_bus_volume_sfx_judges(base_volume_sfx_judges * modulate_volume_sfx_judges)
func _set_base_volume_playback(value: float) -> void : base_volume_playback = value;_set_bus_volume_playback(base_volume_playback * modulate_volume_playback)
func _set_base_volume_chatter(value: float) -> void : base_volume_chatter = value;_set_bus_volume_chatter(base_volume_chatter * modulate_volume_chatter)

func _set_modulate_volume_master(value: float) -> void : modulate_volume_master = value;_set_bus_volume_master(base_volume_master * modulate_volume_master)
func _set_modulate_volume_music(value: float) -> void : modulate_volume_music = value;_set_bus_volume_music(base_volume_music * modulate_volume_music)
func _set_modulate_volume_voice(value: float) -> void : modulate_volume_voice = value;_set_bus_volume_voice(base_volume_voice * modulate_volume_voice)
func _set_modulate_volume_recordings(value: float) -> void : modulate_volume_recordings = value;_set_bus_volume_recordings(base_volume_recordings * modulate_volume_recordings)
func _set_modulate_volume_sfx(value: float) -> void : modulate_volume_sfx = value;_set_bus_volume_sfx(base_volume_sfx * modulate_volume_sfx)
func _set_modulate_volume_buttons(value: float) -> void : modulate_volume_buttons = value;_set_bus_volume_buttons(base_volume_buttons * modulate_volume_buttons)
func _set_modulate_volume_sfx_judges(value: float) -> void : modulate_volume_sfx_judges = value;_set_bus_volume_sfx_judges(base_volume_sfx_judges * modulate_volume_sfx_judges)
func _set_modulate_volume_playback(value: float) -> void : modulate_volume_playback = value;_set_bus_volume_playback(base_volume_playback * modulate_volume_playback)
func _set_modulate_volume_chatter(value: float) -> void : modulate_volume_chatter = value;_set_bus_volume_chatter(base_volume_chatter * modulate_volume_chatter)

func tween_volume_master(to_multiplier: float, time: float = 1.0) -> void :
	for tween: Tween in get_tree().get_processed_tweens(): if tween.get_meta(TWEEN_META_VOLUME_MASTER_GOTO, false): tween.kill()
	var new_tween: Tween = get_tree().create_tween();new_tween.set_meta(TWEEN_META_VOLUME_MASTER_GOTO, true)
	new_tween.tween_property(self, "modulate_volume_master", to_multiplier, time)

func tween_volume_music(to_multiplier: float, time: float = 1.0) -> void :
	for tween: Tween in get_tree().get_processed_tweens(): if tween.get_meta(TWEEN_META_VOLUME_MUSIC_GOTO, false): tween.kill()
	var new_tween: Tween = get_tree().create_tween();new_tween.set_meta(TWEEN_META_VOLUME_MUSIC_GOTO, true)
	new_tween.tween_property(self, "modulate_volume_music", to_multiplier, time)

func tween_volume_voice(to_multiplier: float, time: float = 1.0) -> void :
	for tween: Tween in get_tree().get_processed_tweens(): if tween.get_meta(TWEEN_META_VOLUME_VOICE_GOTO, false): tween.kill()
	var new_tween: Tween = get_tree().create_tween();new_tween.set_meta(TWEEN_META_VOLUME_VOICE_GOTO, true)
	new_tween.tween_property(self, "modulate_volume_voice", to_multiplier, time)

func tween_volume_chatter(to_multiplier: float, time: float = 1.0) -> void :
	for tween: Tween in get_tree().get_processed_tweens(): if tween.get_meta(TWEEN_META_VOLUME_CHATTER_GOTO, false): tween.kill()
	var new_tween: Tween = get_tree().create_tween();new_tween.set_meta(TWEEN_META_VOLUME_CHATTER_GOTO, true)
	new_tween.tween_property(self, "modulate_volume_chatter", to_multiplier, time)

func tween_volume_music_and_chatter(to_multiplier: float, time: float = 1.0) -> void :
	tween_volume_music(to_multiplier, time)
	tween_volume_chatter(to_multiplier, time)


func clear_tween_multipliers() -> void :
	for tween: Tween in get_tree().get_processed_tweens():
		if tween.get_meta(TWEEN_META_VOLUME_MASTER_GOTO, false): tween.kill()
		elif tween.get_meta(TWEEN_META_VOLUME_MUSIC_GOTO, false): tween.kill()
		elif tween.get_meta(TWEEN_META_VOLUME_VOICE_GOTO, false): tween.kill()



func _set_bus_volume_master(value: float) -> void : AudioServer.set_bus_volume_db(BUS_MASTER, linear_to_db(clampf(value, 0.0, 1.5)));variables_changed_TEST.emit()
func _set_bus_volume_music(value: float) -> void : AudioServer.set_bus_volume_db(BUS_MUSIC, linear_to_db(clampf(value, 0.0, 1.5)));variables_changed_TEST.emit()
func _set_bus_volume_voice(value: float) -> void : AudioServer.set_bus_volume_db(BUS_VOICE, linear_to_db(clampf(value, 0.0, 1.5)));variables_changed_TEST.emit()
func _set_bus_volume_recordings(value: float) -> void : AudioServer.set_bus_volume_db(BUS_PECHO, linear_to_db(clampf(value, 0.0, 1.5)));variables_changed_TEST.emit()
func _set_bus_volume_sfx(value: float) -> void : AudioServer.set_bus_volume_db(BUS_ALL_SFX, linear_to_db(clampf(value, 0.0, 1.5)));variables_changed_TEST.emit()
func _set_bus_volume_buttons(value: float) -> void : AudioServer.set_bus_volume_db(BUS_BUTTONS, linear_to_db(clampf(value, 0.0, 1.5)));variables_changed_TEST.emit()
func _set_bus_volume_sfx_judges(value: float) -> void : AudioServer.set_bus_volume_db(BUS_SFX_JUDGES, linear_to_db(clampf(value, 0.0, 1.5)));variables_changed_TEST.emit()
func _set_bus_volume_playback(value: float) -> void : AudioServer.set_bus_volume_db(BUS_PLAYBACK, linear_to_db(clampf(value, 0.0, 1.5)));variables_changed_TEST.emit()
func _set_bus_volume_chatter(value: float) -> void : AudioServer.set_bus_volume_db(BUS_CHATTER, linear_to_db(clampf(value, 0.0, 1.5)));variables_changed_TEST.emit()

























func desample_wav(input: AudioStreamWAV, sample_rate_value: int) -> AudioStreamWAV:
	if sample_rate_value == 0: return input
	var sample_reduction: int = 2 ** sample_rate_value
	var data: PackedByteArray = input.get_data().duplicate()
	var desampled_data: PackedByteArray = []
	for datapoint_index: int in range(0, data.size(), sample_reduction * 4):
		var repeater: PackedByteArray = data.slice(datapoint_index, datapoint_index + 4)
		for i in range(sample_reduction): desampled_data.append_array(repeater)
	var desampled_audio: AudioStreamWAV = input.duplicate(true)
	desampled_audio.set_data(desampled_data)
	return desampled_audio
