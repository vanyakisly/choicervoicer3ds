extends Label


@export var word: String = "Loading"
var periods: int = 1

func _ready():
	while true:
		await LoopPeriods()


func LoopPeriods():
	text = " " + word + ".".repeat(periods)
	periods = (periods + 1) % 4
	await get_tree().create_timer(2.0).timeout
