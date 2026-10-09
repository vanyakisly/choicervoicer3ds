class_name State extends Node


var state_time_elapsed: float
signal finished(next_state: State, data: Dictionary)



func enter_state(_data: Dictionary = {}) -> void : state_time_elapsed = 0.0


func exit_state() -> void : pass


func process_input(_event: InputEvent) -> void : pass


func process_physics(delta: float) -> void : state_time_elapsed += delta


func process_frame(_delta: float) -> void : pass


func _finish_state(state: State, data: Dictionary = {}) -> void :
	finished.emit(state, data)
