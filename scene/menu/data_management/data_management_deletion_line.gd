extends HBoxContainer

signal clicked(emit_path: String)

var meta_path: String = ""

func assign(fn: String, img: Texture2D, pth: String):
	%Filename.text = fn
	%Image.texture = img
	%Path.text = pth
	meta_path = pth

func _on_btn_delete_button_clicked():
	clicked.emit(meta_path)
