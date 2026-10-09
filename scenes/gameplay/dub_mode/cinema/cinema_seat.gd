class_name CinemaSeat extends Node3D


const Y_OFFSET: float = -0.5

@onready var character_sprite: Sprite3D = %CharacterSprite
@onready var character_sprite_back: Sprite3D = %CharacterSpriteBack
@onready var character_sprite_back_light: Sprite3D = %CharacterSpriteBackLight
@onready var sprite_offset: Node3D = %SpriteOffset
@onready var audio: AudioStreamPlayer3D = %Audio
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var using_pack: String
var shut: bool = false


func _assign_image_to_sprite(img: Texture2D) -> void :
	character_sprite.texture = img
	character_sprite_back.texture = img
	character_sprite_back_light.texture = img

func load_character_contestant(global_folder_path: String) -> void :
	var image: Texture2D = VD.get_texture_agnostic(global_folder_path + "player", true)
	if !image: clear_character();return
	_assign_image_to_sprite(image)
	audio.stream = VD.get_audio_agnositc(global_folder_path + "talk_win")
	if !audio.stream: audio.stream = VD.get_audio_agnositc(global_folder_path + "talk_cheer")
	if global_folder_path.ends_with("/"): global_folder_path = global_folder_path.left(-1)
	using_pack = global_folder_path.get_file()
	adjust_height()
func load_random_contestant() -> void :
	var contestants: PackedStringArray = DirAccess.get_directories_at(FileManager.MODPACKS_CONTESTANT)
	if !contestants:
		clear_character()
		return
	var arr: Array = Array(contestants)
	load_character_contestant(FileManager.MODPACKS_CONTESTANT + arr.pick_random() + "/")


func load_character_judge(global_folder_path: String, index: int = -1) -> void :
	if global_folder_path[-2] == "/" and index == -1:
		index = global_folder_path[-1].to_int() + 1
		global_folder_path = global_folder_path.left(-2) + "/"
	var image: Texture2D = VD.get_texture_agnostic(global_folder_path + "judge%s" % index, true)
	if !image: clear_character();return
	_assign_image_to_sprite(image)
	var target_audio_path: String = global_folder_path + "judge%s_voice" % index
	if FileAccess.file_exists(target_audio_path): audio.stream = VD.get_audio_agnositc(target_audio_path)
	else: audio.stream = null
	if global_folder_path.ends_with("/"): global_folder_path = global_folder_path.left(-1)
	using_pack = global_folder_path.get_file() + "/%s" % index
	adjust_height()
func load_random_judge() -> void :
	var judges: PackedStringArray = DirAccess.get_directories_at(FileManager.MODPACKS_JUDGES)
	if !judges: clear_character();return
	var arr: Array = Array(judges)
	load_character_judge(FileManager.MODPACKS_JUDGES + arr.pick_random() + "/", randi_range(1, 5))


func load_character_either(folder_path: String) -> void :
	if folder_path.begins_with("/?JUDGE"):
		folder_path = FileManager.MODPACKS_JUDGES + folder_path.right(-7)
		load_character_judge(folder_path)
	else: load_character_contestant(FileManager.MODPACKS_CONTESTANT + folder_path + "/")
func load_random_either() -> void :
	if randf() < 0.5: load_random_contestant()
	else: load_random_judge()


func adjust_height() -> void :
	if !character_sprite.texture: return
	var image: Image = character_sprite.texture.get_image()
	var shifted_position: float = (image.get_height() / 2.0 * character_sprite.pixel_size) + Y_OFFSET
	sprite_offset.position.y = shifted_position


func character_visible(make_visible: bool) -> void : sprite_offset.visible = make_visible


func clear_character() -> void :
	_assign_image_to_sprite(null)
	audio.stream = null
	using_pack = ""


func react(offset_gap: float = 0.0, chance: float = 0.7) -> void :
	if randf() > chance: return
	if !sprite_offset.visible: return
	await get_tree().create_timer(randf_range(0.0, offset_gap)).timeout
	animation_player.play("bobbing")
	if shut: return
	if audio.stream: audio.play()
func stop(for_how_long: float = 0.0) -> void :
	shut = true
	if audio.playing: audio.stop()
	await get_tree().create_timer(for_how_long).timeout
	shut = false


func get_camera_position() -> Vector3:
	return global_position + Vector3(0.0, 1.45, -0.2)


func adjust_sprite_gap(camera_global: Vector3) -> void :
	character_sprite_back.position.z = - (camera_global.z - global_position.z) / 140.16


	var x_distance: float = global_position.x - camera_global.x
	character_sprite.rotation.y = signf(x_distance) * 0.2


func mute() -> void : audio.volume_linear = 0.0
func unmute() -> void : audio.volume_linear = 1.0
