extends Control

signal host_out
signal host_in
const SHIFTSPEED: float = 0.75
@onready var host_texture = $HBoxContainer / HostTexture



func _ready():
	RefreshImage()








func ResetIn(position_in: bool = true, is_opaque: bool = true) -> void :

	var shift_position: float
	if position_in:
		shift_position = 0.0
	else:
		shift_position = host_texture.size.x
	host_texture.material.set_shader_parameter("shift_amount", shift_position)
	host_texture.modulate.a = float(is_opaque)


func ShiftIn(shift_speed: float = SHIFTSPEED) -> void :
	ResetIn(false, true)
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.set_meta("is_host", true)
	var SetShift = func(amount: float):
		host_texture.material.set_shader_parameter("shift_amount", amount)

	await tween.tween_method(SetShift, host_texture.size.x, 0.0, shift_speed).finished
	host_in.emit()


func ShiftOut(shift_speed: float = SHIFTSPEED) -> void :
	ResetIn(true, true)
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	tween.set_meta("is_host", true)
	var SetShift = func(amount: float):
		host_texture.material.set_shader_parameter("shift_amount", amount)

	await tween.tween_method(SetShift, 0.0, host_texture.size.x, shift_speed).finished
	host_out.emit()


func PopIn() -> void :
	ResetIn(true, true)
	host_in.emit()

func PopOut() -> void :
	ResetIn(false, false)
	host_out.emit()


func RefreshImage() -> void :
	var uc: = UC.new()
	host_texture.texture = uc.get_image(M.OVEEP.HOST, "host", true)
	uc.queue_free()
