@tool
class_name TwitchGlobe
extends Node3D


signal score_animation_finished()


@onready var score_progress: ColorRect = %ScoreProgress
@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var animation_player: AnimationPlayer = $choicer_voicer_globe_sphere / AnimationPlayer
@onready var number_labels: HBoxContainer = %NumberLabels
@onready var label_5: Label = %Label5

@export var twitch_handler: ChatParserVote
@export var score: float:
	set(value):
		score = value
		score_progress.custom_minimum_size.x = 512.0 * score
		score_progress.color.h = 0.528 * score
		rich_text_label.text = ("[center] " if score < 0.1 else "[center]") + "%1.2f%%" % [score * 100.0]
		number_label_visibility_refresh(score)


@export var DEBUG_animate_random: bool:
	set(value):
		if value:
			animate_score(randf(), DEBUG_animate_speed)
		DEBUG_animate_random = false
@export var DEBUG_animate_speed: float
@export var DEBUG_trans: = Tween.TransitionType.TRANS_QUINT
@export var DEBUG_ease: = Tween.EaseType.EASE_IN_OUT

func _ready() -> void :
	var anim: Animation = animation_player.get_animation("speen")
	anim.loop_mode = Animation.LOOP_LINEAR
	animation_player.play("speen")


func animate_score(value: float, time: float = 1.0) -> void :
	var tween: = create_tween().set_trans(DEBUG_trans).set_ease(DEBUG_ease)
	tween.finished.connect(
		func() -> void :
			score_animation_finished.emit()
			)

	tween.tween_property(self, "score", value, time)


func number_label_visibility_refresh(input: float) -> void :
	var scorei: int = floori(input * 30.0 / 5.0)
	label_5.text = "6" if scorei == 6 else "5"
	for index: int in number_labels.get_child_count():
		number_labels.get_child(index).modulate.a = float(clampi(scorei, 0, 5) == index)


func show_all_number_labels() -> void : for l: Label in number_labels.get_children(): l.show()
func hide_all_number_labels() -> void : for l: Label in number_labels.get_children(): l.hide()



func reset() -> void :
	score = 0.0
