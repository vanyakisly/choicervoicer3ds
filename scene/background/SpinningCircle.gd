extends ColorRect

@export var offset_percent: float = 0.05
@export var spin_time: float = 12.0


@onready var tween = create_tween().set_loops()

func _ready():
	ChangeSpin()


func ChangeSpin():
	print("ChangeSpin")
	tween.stop()
	tween.tween_property(self, "rotation", 2.0 * PI, spin_time).as_relative()
	pivot_offset = Vector2(size.x * (0.5 + offset_percent), size.y * (0.5 + offset_percent))
