@icon("res://assets/gd_icons/state_machine.png")
class_name StateMachine extends Node

signal states_initialized
@export var starting_state: State
var current_state: State



func initialize() -> void :
	await owner.ready
	for child: State in get_children(false): child.finished.connect(change_state)
	states_initialized.emit()
	if !current_state: change_state(starting_state)



func change_state(new_state: State, data: Dictionary = {}) -> void :
	if current_state: current_state.exit_state()
	current_state = new_state
	current_state.enter_state(data)


func process_input(event: InputEvent) -> void :
	current_state.process_input(event)


func process_physics(delta: float) -> void :
	current_state.process_physics(delta)


func process_frame(delta: float) -> void :
	current_state.process_frame(delta)
