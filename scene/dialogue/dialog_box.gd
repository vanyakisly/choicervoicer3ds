class_name DialogBox extends Control


signal text_finished
signal text_final_finished
signal new_text
signal batch_done
signal current(reverse_index: int)

enum TEXT_STATE{NONE, ACTIVE, STATIC}

@onready var lbl_dialog_text: Label = %LblDialogText
@onready var anim_text: AnimationPlayer = %AnimText
@onready var anim_dot: AnimationPlayer = %AnimDot
@onready var dialog_dot: TextureRect = %Dot

var state: = TEXT_STATE.STATIC
var allow_skipping: bool
var disable_input: bool
var block_on_done: bool
var ongoing_batch: Array


func _process(_delta: float) -> void :
	if anim_text.is_playing():
		if lbl_dialog_text.visible_ratio >= 1.0:
			_snap_end()


func _input(event: InputEvent) -> void :
	if (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_mouse1")) and not disable_input:
		if allow_skipping and (state == TEXT_STATE.ACTIVE):
			_snap_end()
		elif state == TEXT_STATE.STATIC:
			if ongoing_batch.is_empty():
				lbl_dialog_text.text = ""
				dialog_dot.modulate.a = 0.0
				batch_done.emit()
			else:
				new_text.emit()
				next_text()


func _snap_end() -> void :
	state = TEXT_STATE.STATIC if !block_on_done else TEXT_STATE.NONE
	anim_text.stop()
	anim_dot.play("DotFade")
	lbl_dialog_text.visible_ratio = 1.0
	text_finished.emit()
	if ongoing_batch.is_empty():
		text_final_finished.emit()



func next_text(text: String = ongoing_batch.pop_front()) -> void :
	current.emit(ongoing_batch.size())
	anim_dot.stop()
	dialog_dot.modulate.a = 0.0
	lbl_dialog_text.visible_ratio = 0.0
	lbl_dialog_text.text = text
	anim_text.play("IncrementText")
	state = TEXT_STATE.ACTIVE


func new_batch(batch: PackedStringArray, allow_skip: bool = true, do_block_on_done: bool = false) -> void :
	state = TEXT_STATE.STATIC
	block_on_done = do_block_on_done
	allow_skipping = allow_skip
	ongoing_batch = Array(batch)
