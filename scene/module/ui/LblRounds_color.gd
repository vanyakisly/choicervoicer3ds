extends Label


func _ready():
	var uc: = UC.new()
	var button_color: = Color.html((uc.get_json(M.OVEEP.MENU, "config_menu")).ui.button.color1)
	var base_own_color: Color = get_theme_color("font_color")
	add_theme_color_override("font_color", Color.from_hsv(button_color.h, base_own_color.s, base_own_color.v))
	uc.queue_free()
