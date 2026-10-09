extends ColorRect
class_name MultiplayerProgressTracker

signal attempt_blip
signal final_blip

const BARCOUNT: float = 34.0
@onready var bars: HBoxContainer = %Bars
@onready var goal_marker: HBoxContainer = %GoalMarker
@onready var round_images: HBoxContainer = %RoundImages
@onready var label: Label = %Label
@export var contestant_index: int = 0


var show_goal_marker: bool = true
var palette: = GradientTexture1D.new()

var colorw: = Color.WHITE:
	set(value):
		colorw = value
		label.add_theme_color_override("font_outline_color", colorw)
		palette.gradient.set_color(3, colorw)
var color2: = Color.html("a6f0ff"):
	set(value):
		color2 = value
		bars.modulate = Color(color2, 1.0)
var color1: = Color.BLACK:
	set(value):
		color1 = value
		palette.gradient.set_color(0, Color(color1, 0.0))
		palette.gradient.set_color(1, color1)
		palette.gradient.set_color(2, color1)
		label.add_theme_color_override("font_color", color1)
var percent: float = 0.0


func _init():
	palette.gradient = Gradient.new()
	palette.gradient.offsets = [0, 0.07, 0.16, 0.227]
	material.set_shader_parameter("palette", palette)


func _ready():
	goal_marker.visible = show_goal_marker
	for panel_idx: int in bars.get_child_count():
		var panel: Panel = bars.get_child(panel_idx)
		panel.size_flags_vertical = SIZE_SHRINK_END
		panel.custom_minimum_size.y = 111.0 * panel_idx / 33.0 + 25.0


func TrackerAssign(c: ContestantResource):
	if not is_node_ready():
		await ready
	colorw = Color.WHITE
	color1 = c.color1
	color2 = c.color2


func AddRoundImage(img: Texture, score: int):
	if round_images.get_child_count() > 4:
		round_images.get_child(0).free()
	var new_image: TextureRect = load("res://scene/match/match_progress/progress_round_img_score.tscn").instantiate()
	new_image.texture = img
	new_image.score = score
	new_image.color1 = color1
	new_image.colorw = colorw
	round_images.add_child(new_image)


func NewPercentAnimate2(new_percent: float, time: float = 2.0):
	var old_percent: float = percent
	if old_percent == new_percent:
		attempt_blip.emit()
		return
	percent = new_percent
	var lambda: Callable = func(p: float):
		for b_idx: int in bars.get_child_count():
			var c: Panel = bars.get_child(b_idx)
			if c.visible != (p >= b_idx / BARCOUNT): c.visible = (p >= b_idx / BARCOUNT)
			label.text = "%2.2f%%" % [p * 100.0]
		attempt_blip.emit()
	var tween: Tween = create_tween()
	await tween.tween_method(lambda, old_percent, new_percent, time).finished
	final_blip.emit()
	await get_tree().create_timer(0.5).timeout
