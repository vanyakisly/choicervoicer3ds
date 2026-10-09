extends VBoxContainer


const TONE_DELAY_CHECK_QUIETER = preload("res://assets/audio/functional/tone_delay_check_quieter.mp3")
const UNCHANGING_PIXEL_WIDTH: int = 360
const UNCHANGING_SAMPLE_SIZE: int = 120
const UNCHANGING_STREAM_TIME: float = UNCHANGING_SAMPLE_SIZE / 60.0


@onready var audio_interface_manager_bufferless: AudioInterfaceManagerBufferless = %AudioInterfaceManagerBufferless
@onready var btn_record: ButtonCV = %BtnRecord
@onready var btn_hear_recording: ButtonCV = %BtnHearRecording
@onready var btn_play_sync_tone: ButtonCV = %BtnPlaySyncTone
@onready var spin_mic_sync_offset: SpinBox = %SpinMicSyncOffset
@onready var voice_time_left: Timer = %VoiceTimeLeft
@onready var vclip: AudioStreamPlayer = %Vclip
@onready var pecho: AudioStreamPlayer = %Pecho
@onready var spectrum_aggregate_vclip: SpectrumAggregateFinite = %SpectrumAggregateVclip
@onready var spectrum_aggregate_plmic: SpectrumAggregateFinite = %SpectrumAggregatePlmic
@onready var spectrum_aggregate_endless: SpectrumAggregateEndless = %SpectrumAggregateEndless
@onready var audio_spectrum_sampler_vclip: AudioSpectrumSampler = %AudioSpectrumSamplerVclip
@onready var audio_spectrum_sampler_plmic: AudioSpectrumSampler = %AudioSpectrumSamplerPlmic
@onready var audio_spectrum_sampler_endless: AudioSpectrumSampler = %AudioSpectrumSamplerEndless
@onready var waveform_drawer_vclip: WaveformDrawer = %WaveformDrawerVclip
@onready var waveform_drawer_plmic: WaveformDrawer = %WaveformDrawerPlmic
@onready var waveform_drawer_live: WaveformDrawer = %WaveformDrawerLive
@onready var playbar: ColorRect = %Playbar
@onready var chk_live_mic: CheckButton = %ChkLiveMic


var target_audio_stream_player: AudioStreamPlayer




func _reset_aggregate_vclip() -> void :
	spectrum_aggregate_vclip.clear()
	spectrum_aggregate_vclip.resize_from_count(UNCHANGING_SAMPLE_SIZE)
	spectrum_aggregate_vclip.sample_index = 0
func _reset_aggregate_plmic() -> void : spectrum_aggregate_plmic.clear();spectrum_aggregate_plmic.resize_from_count(UNCHANGING_SAMPLE_SIZE);spectrum_aggregate_plmic.sample_index = 0
func _reset_aggregate_endless() -> void : spectrum_aggregate_endless.clear();spectrum_aggregate_endless.resize_from_count(UNCHANGING_SAMPLE_SIZE)


func _button_play_tone() -> void :
	waveform_drawer_vclip.show();waveform_drawer_plmic.show();waveform_drawer_live.hide()
	_reset_aggregate_vclip()
	vclip.play()
	audio_spectrum_sampler_vclip.play()
func _button_record() -> void :
	target_audio_stream_player = vclip;voice_time_left.start()
	chk_live_mic.disabled = true
	if pecho.playing: pecho.stop()
	btn_record.enable(false);btn_hear_recording.enable(false)
	waveform_drawer_vclip.show();waveform_drawer_plmic.show();waveform_drawer_live.hide();playbar.show()
	await get_tree().create_timer(0.125).timeout
	_reset_aggregate_plmic()
	audio_spectrum_sampler_plmic.play()
	MicrophoneService.recording_on()
	await spectrum_aggregate_plmic.samples_filled
	playbar.hide()
	audio_spectrum_sampler_plmic.stop()
	MicrophoneService.recording_off()
	var recording: AudioStreamWAV = MicrophoneService.get_recording()
	if Profile.mic_crust_sample_rate_on: recording = GMCrust.reduce_recording_sample_rate(recording)
	pecho.stream = recording
	btn_record.enable(true);btn_hear_recording.enable(true)
	chk_live_mic.disabled = false
func _button_hear_recording() -> void :
	target_audio_stream_player = pecho
	waveform_drawer_vclip.show();waveform_drawer_plmic.show();waveform_drawer_live.hide();playbar.hide()
	chk_live_mic.disabled = true
	playbar.show()
	pecho.play()
	await pecho.finished
	playbar.hide()
	chk_live_mic.disabled = false
func _live_mic_on() -> void :
	if vclip.playing: vclip.stop()
	if audio_spectrum_sampler_vclip.playing: audio_spectrum_sampler_vclip.stop()
	waveform_drawer_vclip.hide();waveform_drawer_plmic.hide();waveform_drawer_live.show();playbar.hide()
	btn_record.enable(false);btn_hear_recording.enable(false);btn_play_sync_tone.enable(false)
	_reset_aggregate_endless()
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Plmic"), false)
	audio_spectrum_sampler_endless.play()
func _live_mic_off() -> void :
	btn_record.enable(true);btn_hear_recording.enable(true);btn_play_sync_tone.enable(true)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Plmic"), true)
	audio_spectrum_sampler_endless.stop()
func _live_mic_toggle(toggle_on: bool) -> void :
	_live_mic_on() if toggle_on else _live_mic_off()

func _set_sync_offset(value: float) -> void : Profile.mic_delay = value
func _connect_signals() -> void :
	spin_mic_sync_offset.value_changed.connect(_set_sync_offset)
	vclip.finished.connect(audio_spectrum_sampler_vclip.stop)


func _exit_tree() -> void :
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Plmic"), true)
	MicrophoneService.disable()
func _process(_delta: float) -> void :
	if !playbar.visible: return
	if target_audio_stream_player == pecho: playbar.position.x = -4 + target_audio_stream_player.get_playback_position() / 2.0 * float(UNCHANGING_PIXEL_WIDTH)
	elif target_audio_stream_player == vclip: playbar.position.x = -4 + (UNCHANGING_STREAM_TIME - voice_time_left.time_left) / 2.0 * float(UNCHANGING_PIXEL_WIDTH)


func _ready() -> void :
	MicrophoneService.warmup()
	spin_mic_sync_offset.value = Profile.mic_delay
	voice_time_left.wait_time = UNCHANGING_STREAM_TIME
	target_audio_stream_player = vclip
	spectrum_aggregate_vclip.resize_from_count(UNCHANGING_SAMPLE_SIZE)
	spectrum_aggregate_plmic.resize_from_count(UNCHANGING_SAMPLE_SIZE)
	_connect_signals()
	btn_record.enable(false);btn_hear_recording.enable(false);chk_live_mic.disabled = true
	var temp_timer: SceneTreeTimer = get_tree().create_timer(1.5)
	temp_timer.timeout.connect(btn_record.enable.bind(true))
	temp_timer.timeout.connect(chk_live_mic.set_disabled.bind(false))
