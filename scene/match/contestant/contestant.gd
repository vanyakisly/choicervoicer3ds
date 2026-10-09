extends Node3D

@onready var contestant_image = %ContestantImage
@onready var con_cam = %ConCam
@onready var intro_cam = %IntroCam
@onready var performance_cam = %PerformanceCam

@onready var podium_smooth = %PodiumSmooth
@onready var podium_flat = %PodiumFlat
@onready var pillar_left = %PillarLeft
@onready var pillar_right = %PillarRight


@export var position_index: int = 0


var texture_white = preload("res://graphic/texture/conte_podium_white.tres").duplicate(true)
var texture_screen = preload("res://graphic/texture/conte_podium_screen.tres").duplicate(true)
var texture_emission = preload("res://graphic/texture/conte_podium_emission.tres").duplicate(true)


func SetImage(img: Texture):
	if not self.is_node_ready():
		await self.ready
	contestant_image.set_texture(img)
	contestant_image.position.y = img.get_height() / 2.0 * contestant_image.pixel_size


func SetPodium(conte: ContestantResource):
	if not self.is_node_ready():
		await self.ready
	contestant_image.set_texture(conte.image)
	contestant_image.position.y = conte.image.get_height() / 2.0 * contestant_image.pixel_size

	texture_white.albedo_color = conte.color2
	texture_screen.albedo_color = conte.color1
	texture_emission.emission = conte.color1
	podium_smooth.set_surface_override_material(0, texture_white)
	podium_smooth.set_surface_override_material(1, texture_screen)
	podium_flat.set_surface_override_material(0, texture_white)
	pillar_right.set_surface_override_material(0, texture_white)
	pillar_right.set_surface_override_material(1, texture_emission)
	pillar_left.set_surface_override_material(0, texture_white)
	pillar_left.set_surface_override_material(1, texture_emission)
