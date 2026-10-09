extends ColorRect

@export var order: int = 0

func _ready():
	await get_tree().create_timer(1.0 * order).timeout
	Begin()


func Begin():
	var tween = create_tween().set_loops().set_ease(Tween.EASE_IN)
	tween.tween_method(AdjustWaveHeight, 4, 20, 0.5).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_method(AdjustWaveHeight, 20, 4, 1.5).set_trans(Tween.TRANS_ELASTIC)
	await tween.tween_interval(1.0).finished


func AdjustWaveHeight(height: float):
	custom_minimum_size.y = height
