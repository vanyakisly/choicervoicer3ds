@icon("res://graphic/gd_icons/buttoncv.png")
class_name ButtonCV
extends ColorRect

signal button_clicked
signal button_array_item_clicked(index: int)
signal hover_with_info(info: String)

enum BUTTONTYPE{STANDARD, BACK, SMALL, INVIS, BUBBLE, ADDPLAYER}
@export var button_type: BUTTONTYPE
enum SOUNDTYPE{SELECT, BACK, DECREASE, NONE}
@export var sound_type: SOUNDTYPE

var profile: ButtonProfile
var original_set_font_size: float

var mouse_within_button: bool = false
@export var enabled: bool = true






@export var hover_info: String

func enable(q: bool):
	enabled = q
	if enabled: GradIdle()
	else: GradDisabled()


func _ready():

	UpdatePalette()
	if enabled: GradIdle()
	else: GradDisabled()
	mouse_entered.connect(MouseEntered)
	mouse_exited.connect(MouseExited)



func UpdatePalette():
	GetProfileMatch()
	enable(enabled)




func GetProfileMatch():
	match button_type:
		BUTTONTYPE.STANDARD: profile = M.button_profile_standard
		BUTTONTYPE.BACK: profile = M.button_profile_back
		BUTTONTYPE.INVIS: profile = M.button_profile_invis
		BUTTONTYPE.SMALL: profile = M.button_profile_small
		BUTTONTYPE.BUBBLE: profile = M.button_profile_bubble
		BUTTONTYPE.ADDPLAYER: profile = M.button_profile_add_player


func _input(event):
	if mouse_within_button and enabled:
		if event is InputEventMouseButton:
			if event.get_button_index() == 1 and event.pressed:
				get_viewport().set_input_as_handled()
				click()


func click() -> void :
	button_clicked.emit()
	if get_meta("button_array_item", false): button_array_item_clicked.emit(get_meta("selection_index"))
	match sound_type:
		SOUNDTYPE.SELECT: M.sfx_select.play()
		SOUNDTYPE.BACK: M.sfx_back.play()
		SOUNDTYPE.DECREASE: M.sfx_decrease.play()


func MouseEntered():
	mouse_within_button = true
	hover_with_info.emit(hover_info)
	if enabled: GradHover();M.sfx_hover.play()


func MouseExited():
	mouse_within_button = false
	hover_with_info.emit("")
	if enabled: GradIdle()


func GradIdle():
	material.set_shader_parameter("palette", profile.gradient_standard)
	material.set_shader_parameter("center_color", profile.center_detail)
	material.set_shader_parameter("reflection_color", profile.reflection)
	for child: Node in get_children():
		if child is Label: child.add_theme_color_override("font_color", profile.font_color)

func GradHover():
	material.set_shader_parameter("palette", profile.gradient_hover)
	material.set_shader_parameter("center_color", profile.center_detail_hover)
	material.set_shader_parameter("reflection_color", profile.reflection_hover)
	for child: Node in get_children():
		if child is Label: child.add_theme_color_override("font_color", profile.font_color)

func GradDisabled():
	material.set_shader_parameter("palette", profile.gradient_disabled)
	material.set_shader_parameter("center_color", profile.center_detail_disabled)
	material.set_shader_parameter("reflection_color", profile.reflection_disabled)
	for child: Node in get_children():
		if child is Label: child.add_theme_color_override("font_color", profile.font_color_disabled)


func set_first_label_text(text: String) -> void : for n: Node in get_children(): if n is Label: n.text = text;break
