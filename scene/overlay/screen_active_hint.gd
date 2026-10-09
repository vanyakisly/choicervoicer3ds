extends Control

var tween
@onready var bars = $HBoxContainer / VBoxContainer

var text: String:
	set(value):
		text = value
		%Label.word = value


func FadeOutAndDie(block_mouse: bool = true):
	if not block_mouse: mouse_filter = MOUSE_FILTER_IGNORE
	await get_tree().create_timer(1.0).timeout
	mouse_filter = MOUSE_FILTER_IGNORE
	tween = create_tween().set_trans(Tween.TRANS_SINE)
	var lambda = func(value: float):
		modulate.a = value
		$ColorRect.material.set_shader_parameter("alpha_value", value)
	await tween.tween_method(lambda, 1.0, 0.0, 0.35).finished
	if tween:
		tween.kill()
	queue_free()
