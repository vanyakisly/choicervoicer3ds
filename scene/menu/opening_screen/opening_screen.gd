extends Control


@onready var animation_player: AnimationPlayer = $Blackout / AnimationPlayer
@onready var timer: Timer = $Timer
@onready var blackout: ColorRect = $Blackout

var accept_input: bool = true

func _ready() -> void :

	M.SaveData()
	timer.timeout.connect(down)


func _input(event: InputEvent) -> void :
	if accept_input and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_mouse1")):
		accept_input = false
		down()


func down() -> void :
	accept_input = false
	timer.stop()
	animation_player.play_backwards("Fadeout")
	await animation_player.animation_finished
	get_tree().root.add_child(load("res://scene/singleton/world.tscn").instantiate())
	queue_free()
