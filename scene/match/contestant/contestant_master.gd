extends Node3D

@onready var contestants = %Contestants



func GenerateContestants(conte_set: Array[ContestantResource]):

	for child in contestants.get_children():
		child.queue_free()

	var count: int = conte_set.size()
	var start_x: int = 1 - count
	for i in range(count):
		var contestant: Node3D = load("res://scene/match/contestant/contestant.tscn").instantiate()
		contestants.add_child(contestant)
		contestant.name = "Contestant" + str(count + 1)
		contestant.position.x = start_x + 2 * i
		contestant.position_index = i
		contestant.SetPodium(conte_set[i])


func ConCam(index: int):
	contestants.get_child(index).con_cam.make_current()


func FaceCamera(do: bool):
	var assign: int
	if do:
		assign = VisualShaderNodeBillboard.BILLBOARD_TYPE_FIXED_Y
	else:
		assign = VisualShaderNodeBillboard.BILLBOARD_TYPE_DISABLED
	for child in contestants.get_children():
		child.contestant_image.set_billboard_mode(assign)
