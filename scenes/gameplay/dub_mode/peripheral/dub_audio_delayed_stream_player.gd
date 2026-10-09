class_name DubAudioDelayedStreamPlayer extends AudioStreamPlayer


var timer: = Timer.new()
var delay: float:
	set(value): delay = maxf(0.0, value)


func _init(starting_stream: AudioStream = null, starting_delay: float = -1.0) -> void :
	_timer_setup()
	if starting_stream: stream = starting_stream
	if starting_delay: delay = starting_delay


func _timer_setup() -> void :
	add_child(timer)
	timer.one_shot = true
	timer.timeout.connect(play)


func play_delayed() -> void :
	if delay > 0.0:
		if !timer.is_stopped(): timer.stop()
		timer.wait_time = delay
		timer.start()
	else: play(0.0)


func stop_delayed() -> void :
	timer.stop()
	stop()
