extends MenuBase

@onready var rebind_control_panel = $HBoxContainer / RebindControlPanel
@onready var confirm_rebind_text = %ConfirmRebindText
@onready var duplicate_instructions = $HBoxContainer / RebindControlPanel / MarginContainer / ScrollContainer / VBoxContainer / DuplicateInstructions
@onready var confirm_rebind = $HBoxContainer / RebindControlPanel / MarginContainer / ScrollContainer / VBoxContainer / ConfirmRebind
@onready var btn_check_for_dupes = $HBoxContainer / RebindControlPanel / MarginContainer / ScrollContainer / VBoxContainer / DuplicateInstructions / BtnCheckForDupes
@onready var btn_confirm_rebind = $HBoxContainer / RebindControlPanel / MarginContainer / ScrollContainer / VBoxContainer / ConfirmRebind / BtnConfirmRebind
@onready var rebind_complete = $HBoxContainer / RebindControlPanel / MarginContainer / ScrollContainer / VBoxContainer / RebindComplete
@onready var rebind_complete_text = $HBoxContainer / RebindControlPanel / MarginContainer / ScrollContainer / VBoxContainer / RebindComplete / RebindCompleteText


@onready var delete_control_panel = $HBoxContainer / DeleteControlPanel
@onready var deletion_retrieved_list = $HBoxContainer / DeleteControlPanel / MarginContainer / VBoxContainer / DeletionRetrievedList
@onready var deletion_button_begin = $HBoxContainer / DeleteControlPanel / MarginContainer / VBoxContainer / DeletionButtonBegin


@onready var btn_rebind_seen_voices = $HBoxContainer / VBoxContainer / BtnRebindSeenVoices
@onready var btn_delete_clips = $HBoxContainer / VBoxContainer / BtnDeleteClips

@onready var outline = $HBoxContainer / VBoxContainer / BtnRebindSeenVoices / Outline





func CheckForDuplicates() -> Dictionary:
	get_tree().get_root().get_node("World").ActiveHint(true, "Searching")


	var seen_filenames: PackedStringArray = []
	var pack_dupes: PackedStringArray = []
	var seen_dupes: PackedStringArray = []
	for fn in M.data.player.clips.seen:
		var base_name = fn.get_file()
		if seen_filenames.has(base_name):
			seen_dupes.append(base_name)
		else:
			seen_filenames.append(base_name)

	var sf: Dictionary = _so_far.duplicate(true)
	await RecursivePackCheck("user://game/packs_voice/", sf)

	pack_dupes = sf.dupes

	print(seen_dupes)
	print(pack_dupes)
	get_tree().get_root().get_node("World").ActiveHint(false)
	return {
		"seen_voice_dupes": seen_dupes, 
		"pack_voice_dupes": pack_dupes
	}


var _so_far: Dictionary = {
	"filenames": [], 
	"dupes": []
}

func RecursivePackCheck(directory_string: String, so_far: Dictionary):
	var wait_frame: int = 0
	var dir = DirAccess.open(directory_string)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			wait_frame += 1
			if wait_frame % 12 == 0:
				await get_tree().process_frame
			if dir.current_is_dir():
				RecursivePackCheck(directory_string + "/" + file_name, so_far)
			elif not dir.current_is_dir() and (file_name.ends_with(".wav") or file_name.ends_with(".mp3")):
				var base_name = file_name.get_basename()
				if so_far.filenames.has(base_name):
					so_far.dupes.append(base_name)
				else:
					so_far.filenames.append(base_name)
			file_name = dir.get_next()

func _on_btn_check_for_dupes_button_clicked():
	btn_check_for_dupes.enable(false)
	var dupe_result = await CheckForDuplicates()
	RebindConfirmAsk(dupe_result)
	duplicate_instructions.visible = false
	confirm_rebind.visible = true



func RebindConfirmAsk(dr: Dictionary):
	if dr.seen_voice_dupes.is_empty() and dr.pack_voice_dupes.is_empty():
		confirm_rebind_text.text = "No duplicate file names found in seen clips list or packs.\n\nWould you like to rebind all seen clips on file?"
	else:
		confirm_rebind_text.text = "Duplicate file names were found among seen clips and packs:\n"
		confirm_rebind_text.text += "Packs:\n"
		for dupe_file_name in dr.pack_voice_dupes:
			confirm_rebind_text.text += str(dupe_file_name) + "\n"
		confirm_rebind_text.text += "Seen voices:\n"
		for dupe_file_name in dr.seen_voice_dupes:
			confirm_rebind_text.text += str(dupe_file_name) + "\n"
		confirm_rebind_text.text += "\nRebinding is not recommended. Do you still wish to rebind seen voices on file? Some clips with duplicate names will be incorrectly reassigned."


func _on_btn_confirm_rebind_button_clicked():
	btn_confirm_rebind.enable(false)
	get_tree().get_root().get_node("World").ActiveHint(true, "Rebinding")
	var player_seen: PackedStringArray = M.data.player.clips.seen.duplicate()
	var new_player_seen: PackedStringArray = []
	var changed_paths: PackedStringArray = []
	var wait_frames: int = 0
	for path in player_seen:
		var fn = path.get_basename().get_file()
		wait_frames += 1
		if wait_frames % 12 == 0:
			await get_tree().process_frame
		var findings: String = RecursiveNameCompare(fn, "")
		if findings != "":
			if findings != path:
				changed_paths.append(findings)
			new_player_seen.append(findings)
		else:
			new_player_seen.append(path)
	print("New seen: [total of %s | %s changes occurred]" % [new_player_seen.size(), changed_paths.size()])
	print(new_player_seen)
	M.data.player.clips.seen = new_player_seen.duplicate()
	await RebindingComplete(new_player_seen.size(), changed_paths)
	get_tree().get_root().get_node("World").ActiveHint(false)





func RecursiveNameCompare(seen_file_name: String, path: String) -> String:
	var dir = DirAccess.open("user://game/packs_voice/" + path)
	if dir:
		dir.list_dir_begin()
		var current_file_name = dir.get_next()
		while current_file_name != "":
			if dir.current_is_dir():
				var findings: String = RecursiveNameCompare(seen_file_name, path + current_file_name + "/")
				if findings != "":
					return findings
			elif not dir.current_is_dir() and (current_file_name.ends_with(".wav") or current_file_name.ends_with(".mp3")):
				if current_file_name.get_basename() == seen_file_name:
					return path + seen_file_name
			current_file_name = dir.get_next()

	return ""


func RebindingComplete(total_checked: int, changed: PackedStringArray):
	rebind_complete_text.text = "Rebinding Complete\n\t%s paths were checked\n\t" % [total_checked]
	if changed.size() > 0:
		rebind_complete_text.text += "%s were changed to:\n" % changed.size()
	else:
		rebind_complete_text.text += "No path changes required"
	confirm_rebind.visible = false
	rebind_complete.visible = true
	var wait_frames: int = 0
	for path in changed:
		wait_frames += 1
		if wait_frames % 12 == 0:
			await get_tree().process_frame
		rebind_complete_text.text += "\n• " + path





const IMAGERESIZE: int = 48
func _on_btn_get_list_to_delete_button_clicked():
	get_tree().get_root().get_node("World").ActiveHint(true, "Searching")
	await get_tree().create_timer(0.1).timeout
	deletion_button_begin.visible = false
	deletion_retrieved_list.visible = true
	var uc: = UC.new()
	var seen_rev: PackedStringArray = M.data.player.clips.seen.duplicate()
	seen_rev.reverse()
	var wait_frames: int = 0
	for seen in seen_rev:
		wait_frames += 1
		if wait_frames % 12 == 0:
			await get_tree().process_frame
		if uc.get_audio(M.OVEEP.VOICE, seen) != null:
			var line: HBoxContainer = load("res://scene/menu/data_management/data_management_deletion_line.tscn").instantiate()
			var image: Texture2D = uc.get_image(M.OVEEP.VOICE, seen, false, Vector2i(IMAGERESIZE, IMAGERESIZE))
			if image == null:
				image = uc.get_image(M.OVEEP.VOICE, seen.get_base_dir() + "/_pack_filler_image", false, Vector2i(IMAGERESIZE, IMAGERESIZE))
				if image == null:
					image = uc.get_image(M.OVEEP.MENU, "no_image", true, Vector2i(IMAGERESIZE, IMAGERESIZE))
			line.assign(seen.get_file(), image, seen)
			line.clicked.connect(HideClip)
			deletion_retrieved_list.get_child(0).add_child(line)
	get_tree().get_root().get_node("World").ActiveHint(false)
	uc.queue_free()


func HideClip(path: String):
	var base = path.get_base_dir()
	var file = path.get_file()
	var extension: String = ""
	var dir = DirAccess.open("user://game/packs_voice/" + base)
	if dir.file_exists(file + ".wav"):
		extension = ".wav"
	elif dir.file_exists(file + ".mp3"):
		extension = ".mp3"
	var new = "user://game/packs_voice/" + base + "/_ignore_" + file + extension
	var err = DirAccess.rename_absolute("user://game/packs_voice/" + path + extension, new)
	print(error_string(err))

	for line in deletion_retrieved_list.get_child(0).get_children():
		if line.meta_path == path:
			line.queue_free()
			break



func _on_btn_rebind_seen_voices_button_clicked():
	outline.visible = true
	outline.reparent(btn_rebind_seen_voices, false)
	rebind_control_panel.visible = true
	delete_control_panel.visible = false


func _on_btn_delete_clips_button_clicked():
	outline.visible = true
	outline.reparent(btn_delete_clips, false)
	rebind_control_panel.visible = false
	delete_control_panel.visible = true
