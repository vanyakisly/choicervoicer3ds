extends Control

signal entire_batch_finished
signal batch_sentence_finished
@onready var dialogue_box = $MarginContainer / DialogueBox
@onready var dialogue_label = $MarginContainer / DialogueBox / MarginContainer / HBoxContainer / LblDialogue
@onready var dot = $MarginContainer / DialogueBox / MarginContainer / HBoxContainer / VBoxContainer / Dot

var tween

const CHARACTERSPERFRAME: float = 1.0

var flag_reveal_text: bool = false

var dialogue_active: bool = false
var sentence_batch: PackedStringArray = []
var sentence_index: int = 0
var float_visible_characters: float = 0.0


var accepting_user_input: bool = true
var enabled: bool = true


func _ready():
	dialogue_box.visible = false
	dot.modulate.a = 0.0


func _physics_process(_delta):
	if flag_reveal_text:
		ProcessRevealText()


func _input(event):
	if enabled:
		if (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_mouse1")) and accepting_user_input:
			if dialogue_label.visible_ratio < 1.0:
				ProcessRevealText(true)
				batch_sentence_finished.emit()
			else:
				NextSentence()



func KillDotTweens() -> void :
	if tween:
		tween.kill()




	dot.modulate.a = 0.0


func DotPulse(pulse_time: float = 3.0) -> void :
	dot.modulate.a = 1.0
	if tween:
		tween.kill()
	tween = dot.create_tween().set_loops().set_trans(Tween.TRANS_CIRC)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(dot, "modulate:a", 0.0, pulse_time / 2.0)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(dot, "modulate:a", 1.0, pulse_time / 2.0)


func NewBatch(batch: PackedStringArray) -> void :
	sentence_index = 0
	sentence_batch = batch
	NewSentence(sentence_index)


func NewSentence(idx: int) -> void :
	KillDotTweens()
	dialogue_box.visible = true
	dialogue_label.visible_characters = 0
	dialogue_label.text = sentence_batch[idx]
	flag_reveal_text = true
	dialogue_active = true
	float_visible_characters = 0.0


func NextSentence(disable_user_input: bool = false) -> void :
	if disable_user_input:
		accepting_user_input = false
	if dialogue_active:
		sentence_index += 1
		if sentence_index >= sentence_batch.size():
			dialogue_active = false
			KillDotTweens()
			dialogue_box.visible = false
			entire_batch_finished.emit()
		else:
			NewSentence(sentence_index)


func ProcessRevealText(full: bool = false) -> void :
	if full:
		dialogue_label.visible_ratio = 1.0
		flag_reveal_text = false
		batch_sentence_finished.emit()
		DotPulse()
	else:
		float_visible_characters += CHARACTERSPERFRAME
		dialogue_label.visible_characters = floori(float_visible_characters)
		if dialogue_label.visible_ratio >= 1.0:
			flag_reveal_text = false
			batch_sentence_finished.emit()
			DotPulse()


func Skip() -> void :

	if accepting_user_input:
		dialogue_active = false
		KillDotTweens()
		dialogue_box.visible = false
		batch_sentence_finished.emit()
		entire_batch_finished.emit()
