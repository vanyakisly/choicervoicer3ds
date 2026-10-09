extends Node3D


@onready var blip: AudioStreamPlayer = $Audio / Blip
@onready var succ_mesh_instance = $choicer_voicer_podium_modern / Circle_002
@onready var judge_image = $JudgeImage
@onready var nameplate = $Nameplate
@onready var voice: AudioStreamPlayer = $Audio / Voice

@export var position_index: int = 1

var success_texture: BaseMaterial3D = preload("res://graphic/texture/podium_screen_success.tres").duplicate()
var basic_screen: = preload("res://graphic/texture/podium_screen_basic.tres")
var blips: Array[AudioStream] = []


var play_blips_with_voices: bool


func _ready():
	if (position_index % 2 == 0):
		judge_image.position.z = - 0.005


func QueueWin(reveal_time: float, order: int):
	blip.stream = blips[order]
	await get_tree().create_timer(reveal_time).timeout
	succ_mesh_instance.mesh.surface_set_material(1, success_texture)
	if voice.stream:
		voice.play()
		if play_blips_with_voices: blip.play()
	else:
		blip.play()
	get_parent().get_parent().blippeds += 1


func ClearSuccess():
	succ_mesh_instance.mesh.surface_set_material(1, basic_screen)


func SetImages(img: Texture2D, success_image: Texture2D):
	judge_image.texture = img
	judge_image.position.y = img.get_height() / 2.0 * judge_image.pixel_size
	success_texture.set_texture(BaseMaterial3D.TEXTURE_ALBEDO, success_image)
