extends Node
const PRINTSTR: String = "MicrophoneService | "
var microphone_record_effect: AudioEffectRecord = AudioServer.get_bus_effect(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_RECORD)
var active_microphone_stream_player: AudioStreamPlayer: set = _set_active_microphone_stream_player
func get_recording() -> AudioStream: return microphone_record_effect.get_recording()
func microphone_idle(toggle: bool) -> void :
	if toggle:
		if !active_microphone_stream_player.playing: active_microphone_stream_player.play()
		else: print(PRINTSTR + "Called active microphone player to turn on, but it is already on.")
	else:
		if microphone_record_effect.is_recording_active(): microphone_record_effect.set_recording_active(false)
		if (active_microphone_stream_player.playing): active_microphone_stream_player.stop()
		else: print(PRINTSTR + "Called active microphone player to turn off, but it is already off.")
func microphone_recording(toggle: bool) -> void :
	if toggle:
		if !microphone_record_effect.is_recording_active(): microphone_record_effect.set_recording_active(true)
		else: print(PRINTSTR + "Called record effect to begin recording, but record effect is already recording.")
	else:
		if (microphone_record_effect.is_recording_active()): microphone_record_effect.set_recording_active(false)
		else: print(PRINTSTR + "Called record effect to stop recording, but record effect is already off.")
func _set_active_microphone_stream_player(value: AudioStreamPlayer) -> void : active_microphone_stream_player = value;print(PRINTSTR + "Active microphone player has changed.")
