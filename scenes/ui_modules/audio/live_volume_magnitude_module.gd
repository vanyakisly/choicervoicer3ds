class_name LiveVolumeModule extends Control



enum AudioInputSource{NONE, MICROPHONE}


@onready var magbar: ProgressBar = %MagnitudeBar
@onready var audio_spectrum_sampler: AudioSpectrumSampler = %AudioSpectrumSampler


var input_source: AudioInputSource




func new_sample(frame: SpectrumFrame) -> void : magbar.value = sqrt(float(frame.byte_magnitude_average) / float(255) / 0.67)
func play() -> void : audio_spectrum_sampler.play()
func stop() -> void : audio_spectrum_sampler.stop();magbar.value = 0.0


func _ready() -> void :
	if MicrophoneService.state == MicrophoneService.STATE.OFF: MicrophoneService.warmup()
