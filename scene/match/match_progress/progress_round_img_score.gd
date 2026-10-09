extends TextureRect

@onready var label: Label = $Label

var score: int = 0:
	set(value):
		score = value
		if not is_node_ready():
			await ready
		label.text = "+" + str(score)

var color1: Color = Color.BLACK:
	set(value):
		color1 = value
		if not is_node_ready():
			await ready
		label.add_theme_color_override("font_color", color1)

var colorw: Color = Color.WHITE:
	set(value):
		colorw = value
		if not is_node_ready():
			await ready
		label.add_theme_color_override("font_outline_color", colorw)
