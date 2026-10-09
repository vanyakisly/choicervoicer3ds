class_name Wupsilon extends SubViewport


signal playbar_finished
signal recording_finished

const PRINTMSG: String = "Wupsilon | "
const PIXELS_PER_SAMPLE: int = 3
const SAMPLES_PER_SECOND: int = 60


@onready var waveform_buffer_left: TextureRect = %WaveformBufferLeft
@onready var waveform_buffer_right: TextureRect = %WaveformBufferRight
@onready var playbar: TextureRect = %Playbar


@export var left_buffer_time: float:
	set(value): left_buffer_time = value;_update_buffer_widths()
@export var right_buffer_time: float:
	set(value): right_buffer_time = value;_update_buffer_widths()

@export var vclip_player: AudioStreamPlayer
@export var vclip_drawer: SpectrumDrawer
@export var vclip_sampler: SpectrumSampler


@export var plmic_drawer: SpectrumDrawer
@export var plmic_sampler: SpectrumSampler

@export var pecho_player: AudioStreamPlayer

var mic_record_effect: AudioEffectRecord = AudioServer.get_bus_effect(VolumeService.BUS_PLMIC, VolumeService.PLMIC_EFFECT_INDEX_RECORD)
var mic_check_stream: AudioStreamWAV
var active_clip: OmniClip:
	get: return clip_member_instance.shared_omniclip if clip_member_instance else null
var clip_member_instance: OmniClipMemberInstance


func _ready() -> void :
	_update_buffer_widths()


func _update_buffer_widths() -> void :
	if !is_node_ready(): return
	waveform_buffer_left.custom_minimum_size.x = _get_left_buffer_pixel_size()
	waveform_buffer_right.custom_minimum_size.x = _get_right_buffer_pixel_size()


func set_clip(input_clip: OmniClip) -> OmniClipMemberInstance:
	playbar_stop();playbar_reset()
	clear_vclip_sample_data();clear_plmic_sample_data()
	clip_member_instance = OmniClipMemberInstance.new()
	clip_member_instance.shared_omniclip = input_clip
	vclip_sampler.resize_from_stream(active_clip.clip_audio)
	plmic_sampler.resize_from_stream(active_clip.clip_audio)
	size.x = get_full_pixel_size()
	vclip_player.stream = active_clip.clip_audio
	return clip_member_instance


func play_vclip(sample: bool = true) -> void :
	vclip_sampler.clear()
	playbar_start()
	await get_tree().create_timer(left_buffer_time).timeout
	vclip_player.play()
	if sample: vclip_sampler.play()
func play_plmic() -> void :
	plmic_sampler.clear()


	playbar_start()
	await get_tree().create_timer(left_buffer_time).timeout
	vclip_player.bus = "VclipPlayback";vclip_player.play()
	await get_tree().create_timer(Profile.mic_delay).timeout
	plmic_sampler.play()


	await get_tree().create_timer(active_clip.get_length()).timeout


	clip_member_instance.member_audio = mic_record_effect.get_recording()
	vclip_player.bus = "Vclip"
	recording_finished.emit()
func play_pecho() -> void :
	pecho_player.stream = clip_member_instance.member_audio
	playbar_start()
	await get_tree().create_timer(left_buffer_time).timeout
	pecho_player.play()
func stop() -> void :
	playbar_stop();playbar_reset()
	if vclip_player.playing: vclip_player.stop()
	if pecho_player.playing: pecho_player.stop()
	if vclip_sampler.playing: vclip_sampler.stop()
	if plmic_sampler.playing: plmic_sampler.stop()
	if mic_record_effect.is_recording_active(): mic_record_effect.set_recording_active(false)


func playbar_start() -> void :
	playbar_stop();playbar_reset()
	var tween: Tween = create_tween()
	tween.finished.connect( func() -> void : playbar_finished.emit())
	tween.set_meta("is_tween_playbar_animator", true)
	tween.tween_property(playbar, "position:x", size.x, clip_and_buffer_time())
func playbar_stop() -> void : for active_tween: Tween in get_tree().get_processed_tweens(): if active_tween.get_meta("is_tween_playbar_animator", false): active_tween.kill()
func playbar_reset() -> void : playbar.position.x = -9
func playbar_is_active() -> bool:
	for active_tween: Tween in get_tree().get_processed_tweens(): if active_tween.get_meta("is_tween_playbar_animator", false): return true
	return false


func clear_vclip_sample_data() -> void : vclip_sampler.clear()
func clear_plmic_sample_data() -> void : plmic_sampler.clear()


func get_current_waveform_texture() -> Texture2D:
	return ImageTexture.create_from_image(get_texture().get_image().get_region(
		Rect2i(
			Vector2i(_get_left_buffer_pixel_size(), 0), 
			Vector2i(size.x - (_get_left_buffer_pixel_size() + _get_right_buffer_pixel_size()), size.y)
			)
		))

func clip_and_buffer_time() -> float: return active_clip.get_length() + left_buffer_time + right_buffer_time

func _get_clip_pixel_size() -> int: return floori(active_clip.get_length() * SAMPLES_PER_SECOND * PIXELS_PER_SAMPLE)
func _get_left_buffer_pixel_size() -> int: return floori(left_buffer_time * SAMPLES_PER_SECOND * PIXELS_PER_SAMPLE)
func _get_right_buffer_pixel_size() -> int: return floori(right_buffer_time * SAMPLES_PER_SECOND * PIXELS_PER_SAMPLE)
func get_full_pixel_size() -> int: return _get_clip_pixel_size() + _get_left_buffer_pixel_size() + _get_right_buffer_pixel_size()



func set_stream(stream: AudioStream) -> void :
	playbar_stop();playbar_reset()
	clear_vclip_sample_data();clear_plmic_sample_data()
	vclip_sampler.resize_from_stream(stream)
	plmic_sampler.resize_from_stream(stream)
	size.x = stream.get_length() * SAMPLES_PER_SECOND * PIXELS_PER_SAMPLE + _get_left_buffer_pixel_size() + _get_right_buffer_pixel_size()
	vclip_player.stream = stream


func play_stream(sampling: bool = true) -> void :
	vclip_sampler.clear()
	playbar_stream_start()
	await get_tree().create_timer(left_buffer_time).timeout
	vclip_player.play()
	if sampling: vclip_sampler.play()


func play_stream_plmic() -> void :
	plmic_sampler.clear()


	playbar_stream_start()
	await get_tree().create_timer(left_buffer_time).timeout
	vclip_player.bus = "VclipPlayback";vclip_player.play()
	await get_tree().create_timer(Profile.mic_delay).timeout
	plmic_sampler.play()


	await get_tree().create_timer(active_clip.get_length()).timeout



	mic_check_stream = mic_record_effect.get_recording()
	vclip_player.bus = "Vclip"
	recording_finished.emit()


func play_stream_pecho() -> void :
	pecho_player.stream = mic_check_stream
	playbar_stream_start()
	await get_tree().create_timer(left_buffer_time).timeout
	pecho_player.play()


func playbar_stream_start() -> void :
	playbar_stop();playbar_reset()
	var tween: Tween = create_tween()
	tween.finished.connect( func() -> void : playbar_finished.emit())
	tween.set_meta("is_tween_playbar_animator", true)
	tween.tween_property(playbar, "position:x", size.x, 
		vclip_player.stream.get_length() * SAMPLES_PER_SECOND * PIXELS_PER_SAMPLE + _get_left_buffer_pixel_size() + _get_right_buffer_pixel_size())


func live_mic_start() -> void :
	clear_vclip_sample_data();clear_plmic_sample_data()



	plmic_sampler.play_uncapped()
