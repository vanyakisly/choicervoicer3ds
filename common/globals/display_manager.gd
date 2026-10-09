extends Node


signal window_mode_changed


enum SCREEN_RESOLUTIONS{
	R1152, 
	R1280, 
	R1360, 
	R1366, 
	R1600, 
	R1920, 
	R2560, 
	R3200, 
	R3840
}


const RESOLUTION_VECTORS: Dictionary = {
	SCREEN_RESOLUTIONS.R1152: Vector2i(1152, 648), 
	SCREEN_RESOLUTIONS.R1280: Vector2i(1280, 720), 
	SCREEN_RESOLUTIONS.R1360: Vector2i(1360, 768), 
	SCREEN_RESOLUTIONS.R1366: Vector2i(1366, 768), 
	SCREEN_RESOLUTIONS.R1600: Vector2i(1600, 900), 
	SCREEN_RESOLUTIONS.R1920: Vector2i(1920, 1080), 
	SCREEN_RESOLUTIONS.R2560: Vector2i(2560, 1440), 
	SCREEN_RESOLUTIONS.R3200: Vector2i(3200, 1800), 
	SCREEN_RESOLUTIONS.R3840: Vector2i(3840, 2160), 
}





func _update_from_profile() -> void :
	change_window_mode(Profile.window_mode)
	change_window_resolution(Profile.window_resolution)


func _input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_fullscreen"):
		Profile.window_mode = 1 if (Profile.window_mode != 1) else 0


func change_window_mode(mode: int) -> void :
	match mode:
		0:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			change_window_resolution(Profile.window_resolution)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			change_window_resolution(Profile.window_resolution)
		3:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	window_mode_changed.emit()


func change_window_resolution(index: int, attempt_centering: bool = false) -> void :
	if RESOLUTION_VECTORS.has(index): DisplayServer.window_set_size(RESOLUTION_VECTORS[index])
	var window: Window = get_tree().root
	if attempt_centering and Profile.snap_window_to_center: window.move_to_center()
