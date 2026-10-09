extends Control

const BLIP_MIN_MILLIS: int = 50

@onready var background: Control = %Background
@onready var bg_video: VideoStreamPlayer = %BgVideo
@onready var master_blip: AudioStreamPlayer = %MasterBlip
@onready var final_blip: AudioStreamPlayer = %FinalBlip

var tracker_last_blip_call_time: int = 0


func _ready() -> void :
	var custom: String = M.data.custom.studio
	if DirAccess.dir_exists_absolute("user://game/packs_studio/" + custom):
		if FileAccess.file_exists("user://game/packs_studio/" + custom + "/screen.ogv"):
			var video: = VideoStreamTheora.new()
			video.file = "user://game/packs_studio/" + custom + "/screen.ogv"
			if video != null:
				bg_video.stream = video
				bg_video.play()
				background.hide()
				bg_video.show()


func _attempt_blip() -> void :


	master_blip.play.call_deferred()

func _final_blip() -> void : final_blip.play()
