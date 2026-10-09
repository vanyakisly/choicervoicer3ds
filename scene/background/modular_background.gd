extends Control

@onready var background_texture = $BackgroundTexture
@onready var spinning_circles = $SpinningCircles
@onready var spin_disc = $SpinDisc
@onready var top_gradient = $TopGradient
@onready var bottom_gradient = $BottomGradient
@onready var letterboxing = $Letterboxing
@onready var waves = $Waves
@onready var overlay_texture = $BorderTexture
@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer


@onready var uc: = UC.new()


signal music_toggle(toggle_on: bool)

func _ready():
	add_child(uc)
	Begin()


func Begin():

	AssignAll()


func AssignAll():
	var config: Dictionary = uc.get_json(M.OVEEP.MENU, "config_menu")
	var background_config: Dictionary = config.background
	AssignBackground(background_config.image)
	AssignBorder(background_config.overlay)
	AssignCircles(background_config.circles)
	AssignTopGradient(background_config.top_gradient)
	AssignBottomGradient(background_config.bottom_gradient)
	AssignLetterbox(background_config.letterbox)
	AssignWaves(background_config.waves)
	AssignSpinDisc(background_config.clip_disc)
	AssignVideo(config.audio)


func AssignBackground(image_config: Dictionary):
	var background_image: Texture2D
	var scroll: Dictionary = image_config.scroll.duplicate(true)
	match int(image_config.use_type):
		0:
			background_image = uc.get_image(M.OVEEP.MENU, "background", true)
		1:
			background_image = uc.get_image(M.OVEEP.MENU, "background", true, Vector2i(1152, 648))
			scroll.x = 0
			scroll.y = 0
		_:
			background_image = uc.get_image(M.OVEEP.MENU, "background", true)
	background_texture.texture = background_image
	var adjusted_scroll: = Vector2(scroll.x / float(background_image.get_width()) * 32.0, scroll.y / float(background_image.get_height()) * 32.0)
	background_texture.material.set_shader_parameter("direction", adjusted_scroll)


func AssignBorder(overlay: Dictionary):
	if int(overlay.on):
		var overlay_img: Texture2D = uc.get_image(M.OVEEP.MENU, "overlay", false, Vector2i(1152, 648))
		overlay_texture.texture = overlay_img
	else:
		overlay_texture.texture = null


func AssignCircles(circles: Dictionary):

	spinning_circles.visible = circles.on
	spinning_circles.get_child(0).material.set_shader_parameter("color", Color(circles.color))


func AssignTopGradient(top_grad: Dictionary):
	top_gradient.visible = top_grad.on
	top_gradient.modulate = Color(top_grad.color)


func AssignBottomGradient(bot_grad: Dictionary):
	bottom_gradient.visible = bot_grad.on
	bottom_gradient.modulate = Color(bot_grad.color)


func AssignLetterbox(letterbox: Dictionary):
	letterboxing.visible = letterbox.on
	M.ChangeLetterboxColor(letterbox)


func AssignWaves(wave: Dictionary):
	waves.visible = wave.on
	waves.material.set_shader_parameter("kolor", Color(wave.color))


func AssignSpinDisc(clip_disc: Dictionary):
	var on_state = (clampi(clip_disc.state, 0, 2) != 0)
	var show_clips = (clampi(clip_disc.state, 0, 2) == 1)
	var actual_disc = spin_disc.get_node("SubViewport/SpinDisc")
	var state_changed: bool = (actual_disc.state != clip_disc.state) or (actual_disc.color != Color.html(clip_disc.color))
	spin_disc.visible = clampi(clip_disc.state, 0, 2)
	actual_disc.state = clip_disc.state
	actual_disc.visible = on_state
	actual_disc.show_clips = show_clips
	actual_disc.color = Color.html(clip_disc.color)
	if state_changed:
		actual_disc.generate()


func AssignVideo(audio: Dictionary) -> void :
	if FileAccess.file_exists("user://game/packs_menu/" + Profile.menu_slash + "video.ogv"):
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Video"), !audio.get("use_video", true))

		music_toggle.emit( !audio.get("use_video", true))
		var vidloader: = VideoStreamTheora.new()
		vidloader.file = "user://game/packs_menu/" + Profile.menu_slash + "video.ogv"
		if video_stream_player.stream == null or video_stream_player.stream.file != vidloader.file:
			video_stream_player.stream = vidloader
			video_stream_player.play.call_deferred()
	else:
		video_stream_player.stream = null
		music_toggle.emit(true)
