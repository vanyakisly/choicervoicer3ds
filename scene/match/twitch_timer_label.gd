extends RichTextLabel

@onready var timer: Timer = $Timer


func activate() -> void :
	timer.start(34)
	while timer.time_left:
		var time: int = floori(timer.time_left) + 1
		if time > 5: text = "0:%02d" % [time]
		else: text = "[color=red]0:%02d" % [time]
		await get_tree().process_frame
