extends ColorRect



func _ready():
	var uc: = UC.new()
	var palette_to_change: GradientTexture1D = load("res://graphic/gradient/title_circular.tres").duplicate(true)
	var button_color: = Color.html((uc.get_json(M.OVEEP.MENU, "config_menu")).ui.button.color1)
	palette_to_change.gradient.set_color(3, Color.from_hsv(button_color.h, pow(button_color.s, 0.245), 0.68))

	material.set_shader_parameter("palette", palette_to_change)
	uc.queue_free()
