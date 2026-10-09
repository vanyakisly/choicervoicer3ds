extends Node



@onready var studio_container: Node3D = %StudioContainer




func setup_studio() -> void :
	var studio: Node

	studio_container.add_child(studio)
