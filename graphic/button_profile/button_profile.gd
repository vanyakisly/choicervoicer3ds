extends Resource
class_name ButtonProfile
@export_category("Gradients")
@export var gradient_standard: GradientTexture1D
@export var gradient_hover: GradientTexture1D
@export var gradient_disabled: GradientTexture1D
@export_category("Enabled Colors")
@export var center_detail: Color
var center_detail_hover: Color
@export var reflection: Color
var reflection_hover: Color = Color.MAGENTA
@export var font_color: Color
@export_category("Disabled Colors")
@export var center_detail_disabled: Color
@export var reflection_disabled: Color
@export var font_color_disabled: Color
@export_category("Allow Recoloring")
@export var enabled_color_allow: Array[bool]
@export var hover_color_allow: Array[bool]
@export var disabled_color_allow: Array[bool]
@export var center_color_allow: bool = false
@export var reflection_color_allow: bool = false
@export var font_color_allow: bool = false
@export_category("Allow Inversion")
@export var enabled_invert_allow: Array[bool]
@export var hover_invert_allow: Array[bool]
@export var disabled_invert_allow: Array[bool]
@export var center_invert_allow: bool = false
@export var reflection_invert_allow: bool = false
@export var font_invert_allow: bool = false



func ChangeColorNeo(config_buttons: Dictionary):
	ChangeGradient(gradient_standard, config_buttons.color1, enabled_color_allow, enabled_invert_allow, config_buttons.invert)
	ChangeGradient(gradient_hover, config_buttons.color2, hover_color_allow, hover_invert_allow, config_buttons.invert)
	center_detail_hover = InjectInvertClassic(center_detail, config_buttons.color2, center_color_allow, center_invert_allow and config_buttons.invert)
	center_detail = InjectInvertClassic(center_detail, config_buttons.color1, center_color_allow, center_invert_allow and config_buttons.invert)
	reflection_hover = InjectInvertClassic(reflection, config_buttons.color2, reflection_color_allow, reflection_invert_allow and config_buttons.invert, true)
	reflection = InjectInvertClassic(reflection, config_buttons.color1, reflection_color_allow, reflection_invert_allow and config_buttons.invert, true)
	font_color = InjectInvertClassic(font_color, config_buttons.color1, font_color_allow, font_invert_allow and config_buttons.invert)












func ChangeGradient(gradtex: GradientTexture1D, new_color: Color, color_allow: Array[bool], invert_allow: Array[bool], config_invert: bool):
	var g = gradtex.gradient
	for i in g.colors.size():
		g.set_color(i, InjectInvertClassic(g.colors[i], new_color, color_allow[i], invert_allow[i] and config_invert))


func InjectInvert(old_color: Color, new_color: Color, do_injection: bool, do_inversion: bool, not_value: bool = false) -> Color:
	var k: Color = old_color
	if do_injection:
		if not_value:
			k = Color.from_hsv(new_color.h, new_color.s / 8.0, old_color.v, old_color.a)
		else:
			k = Color.from_hsv(new_color.h, new_color.s, old_color.v * new_color.v, old_color.a)
	if do_inversion:
		k = Color.from_hsv(k.h + 0.5, k.s, k.v, k.a).inverted()
	return k


func InjectInvertClassic(old_color: Color, new_color: Color, do_injection: bool, do_inversion: bool, not_value: bool = false) -> Color:
	var saturation_application: float = old_color.s * new_color.s * 6.071
	if not do_injection:
		saturation_application = old_color.s

	var value_application: float = old_color.v * new_color.v * 1.22
	if not_value:
		value_application = old_color.v

	if do_inversion:
		return Color.from_hsv((new_color.h + 0.5), (saturation_application * new_color.s * 6.071), (value_application), old_color.a).inverted()
	else:
		return Color.from_hsv((new_color.h), (saturation_application * new_color.s * 6.071), (value_application), old_color.a)




func ChangeColor(new_color: Color):
	for palette in [gradient_standard, gradient_hover, gradient_disabled]:
		for i in palette.gradient.colors.size():
			var old_color = palette.gradient.colors[i]
			palette.gradient.set_color(i, Color.from_hsv((new_color.h), (old_color.s * 6.071 * new_color.s), old_color.v * 1.22 * new_color.v, old_color.a))
	center_detail = ChangeIndividualColor(center_detail, new_color)
	reflection = ChangeIndividualColor(reflection, new_color)
	font_color = ChangeIndividualColor(font_color, new_color)
	center_detail_disabled = ChangeIndividualColor(center_detail_disabled, new_color)
	reflection_disabled = ChangeIndividualColor(reflection_disabled, new_color)
	font_color_disabled = ChangeIndividualColor(font_color_disabled, new_color)


func ChangeColorInvert(new_color: Color):
	for palette in [gradient_standard, gradient_hover, gradient_disabled]:
		for i in palette.gradient.colors.size():
			var old_color = palette.gradient.colors[i]
			palette.gradient.set_color(i, (Color.from_hsv((new_color.h + 0.5), (old_color.s * 6.071 * new_color.s), old_color.v * 1.22 * new_color.v, old_color.a)).inverted())
	center_detail = ChangeIndividualColor(center_detail, new_color, false, true).inverted()
	reflection = ChangeIndividualColor(reflection, new_color, true).inverted()
	font_color = ChangeIndividualColor(font_color, new_color, false, true).inverted()
	center_detail_disabled = ChangeIndividualColor(center_detail_disabled, new_color, false, true).inverted()
	reflection_disabled = ChangeIndividualColor(reflection_disabled, new_color, true).inverted()
	font_color_disabled = ChangeIndividualColor(font_color_disabled, new_color, false, true).inverted()



func ChangeIndividualColor(old_color: Color, new_color: Color, reflection_invert: bool = false, center_invert: bool = false) -> Color:
	var value: float = old_color.v * 1.22 * new_color.v
	var hue: float = new_color.h
	if reflection_invert:
		value = 1.0 - value
	if center_invert:
		hue += 0.5
	return Color.from_hsv(hue, (old_color.s * 6.071 * new_color.s), value, old_color.a)


func ColorValueInvert(clr: Color) -> Color:
	return Color.from_hsv(clr.h, clr.s, 1.0 - clr.v)
