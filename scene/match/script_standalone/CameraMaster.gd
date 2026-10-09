class_name CameraMaster extends Node3D

var tween: Tween


@onready var cam_judge_sweep: Camera3D = %CamJudgeSweep
@onready var cam_judge_suspense: Camera3D = %CamJudgeSuspense
@onready var cam_vclip_main: Camera3D = %CamVclipMain
@onready var cam_host_and_vclip: Camera3D = %CamHostAndVclip
@onready var cam_host_and_judges: Camera3D = %CamHostAndJudges
@onready var cam_contestant: Camera3D = %CamContestant
@onready var cam_contestants_full: Camera3D = %CamContestantsFull
@onready var cam_contestants_progress: Camera3D = %CamContestantsProgress
@onready var cam_good_job: Camera3D = %CamGoodJob
@onready var cam_waiting_panelists: Camera3D = %CamWaitingPanelists


@onready var record_master = %RecordMaster
@onready var contestant_view_overlay = %ContestantViewOverlay


@onready var contestant_master = %ContestantMaster
@onready var judge_master = %JudgeMaster


func FirstVisuals():
	record_master.visible = false
	cam_vclip_main.make_current()


func VclipMain(cam_only: bool = false):
	cam_vclip_main.make_current()
	if not cam_only:
		record_master.visible = true


func HostAndVclip(cam_only: bool = false):
	cam_host_and_vclip.make_current()
	if not cam_only:
		record_master.visible = false
		contestant_view_overlay.visible = false


func HostAndJudges(cam_only: bool = false):
	cam_host_and_judges.make_current()
	if not cam_only:
		record_master.visible = false


func ConCam(index: int):
	contestant_master.ConCam(index)


func ConIntroCam(index: int, time: float = 9.0):
	var cam: Camera3D = contestant_master.contestants.get_child(index).intro_cam
	cam.position.z = 0
	cam.fov = 60
	cam.make_current()
	if tween: tween.kill()
	tween = cam.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(cam, "position:z", -1.5, time)

func ConPerformanceCam(index: int, time: float = 9.0):
	var cam: Camera3D = contestant_master.contestants.get_child(index).performance_cam
	cam.position.z = 0

	cam.position.y = 0.45
	cam.fov = 45
	cam.make_current()
	if tween: tween.kill()
	tween = cam.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cam, "position:z", -0.5, time)


func FaceCamera(do: bool):
	contestant_master.FaceCamera(do)
	judge_master.FaceCamera(do)


func ConPerformance(index: int):
	var camref: Camera3D = contestant_master.contestants.get_child(index).con_cam
	cam_contestant.position = camref.global_position
	cam_contestant.rotation = camref.global_rotation

func ConFull(cam_only: bool = false):
	cam_contestants_full.make_current()
	if not cam_only:
		record_master.visible = false
		contestant_view_overlay.visible = false


func JudgeSuspenseSingle(time: float):
	cam_judge_suspense.make_current()
	cam_judge_suspense.position.z = 6
	if tween: tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(cam_judge_suspense, "position:z", 5, time)


func JudgeSuspenseMultiPre(total_conte: int):
	cam_judge_suspense.position.z = 5.0 + (total_conte) * 0.5
	cam_judge_suspense.make_current()

func JudgeSuspenseMulti(time: float, conte_idx: int, total_conte: int):
	cam_judge_suspense.position.z = 5.0 + (total_conte - conte_idx) * 0.5
	cam_judge_suspense.make_current()
	if tween: tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(cam_judge_suspense, "position:z", -0.5, time).as_relative()


func ContestantsProgress(reset: bool = false):
	if reset:
		cam_contestants_progress.position = Vector3(0, 3, 25)
	cam_contestants_progress.make_current()


func ContestantsProgressZoomIn(time: float = 4.7):
	cam_contestants_progress.make_current()
	var tween_c = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE).set_parallel(true)
	tween_c.tween_property(cam_contestants_progress, "position:z", 16.75, time)
	tween_c.tween_property(cam_contestants_progress, "position:y", 4.3, time)


func JudgeSweep():
	cam_judge_sweep.position.x = -2.5
	cam_judge_sweep.make_current()
	var tween_j = create_tween().set_loops().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween_j.tween_property(cam_judge_sweep, "position:x", 2.5, 9.0)
	tween_j.tween_property(cam_judge_sweep, "position:x", -2.5, 9.0)


func GoodJob(cam_only: bool = false):
	cam_good_job.make_current()
	if not cam_only:
		record_master.visible = false
		contestant_view_overlay.visible = false


func to_cam_waiting_panelists() -> void : cam_waiting_panelists.make_current()
