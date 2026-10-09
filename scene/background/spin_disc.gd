extends Node3D

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@export var roundabout_z_rotation: float:
	set(value): rotation_degrees.z = value
@onready var spinnies_container: Node3D = %SpinniesContainer

var image_array: Array = []
@export var do_spin: bool = true




@export var radius: float = 2



@export var spin: float = 0
@export var squares: int = 2



@export var spin_offset: float = 0.0




var show_clips: bool = true
var state: int = 1
var color: = Color.html("cff7ff")


















func _ready():
	generate()
	do_spin = do_spin


func generate():
	if visible:
		seen_sampling(show_clips)
		make_spinnies(squares)



func _input(event):
	if event.is_action_pressed("F3"):
		generate()

func make_spinnies(count: int):
	for child: Node in spinnies_container.get_children():
		child.free()
	for i in range(count):
		var spinny: = Node3D.new()
		spinnies_container.add_child(spinny)
		var tex: = Sprite3D.new()
		tex.layers = 512
		tex.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

		tex.position.x = radius
		tex.texture = image_array[i]
		spinny.add_child(tex)
		spinny.rotation.z = float(i) / float(count) * TAU + spin_offset


func change_spinnies():
	for i in get_child_count():
		get_child(i).get_child(0).position.x = radius
		get_child(i).rotation.z = float(i) / float(squares) * TAU + spin_offset


func seen_sampling(show_clips_: bool):
	var uc: = UC.new()
	image_array.clear()
	var seen_voices: Array
	var default_image: GradientTexture2D = preload("res://graphic/texture/spinny_default.tres")
	default_image.gradient.set_color(0, color)
	default_image.gradient.set_color(1, Color(color, 0.0))
	if show_clips_:
		seen_voices = M.data.player.clips.seen.duplicate()
	else:
		seen_voices = []
	randomize()
	seen_voices.shuffle()
	for i in range(squares):
		if i >= seen_voices.size():
			image_array.append(default_image)
		else:
			var img = uc.get_image(M.OVEEP.VOICE, seen_voices[i], false, Vector2i(64, 64))
			if img == null:
				img = uc.get_image(M.OVEEP.VOICE, seen_voices[i].get_base_dir() + "/_pack_filler_image", false, Vector2i(64, 64))
				if img == null:
					image_array.append(default_image)
				else:
					image_array.append(img)
			else:
				image_array.append(img)
	image_array.shuffle()
	uc.queue_free()


func colorize(c: String):
	color = Color.html(c)
