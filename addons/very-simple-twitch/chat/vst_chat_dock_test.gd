@tool
extends Control

const MAX_MESSAGES: int = 50


@onready var support_button: Button = %SupportButton

var twitch_chat: TwitchChat:
	get:
		if twitch_chat == null:
			twitch_chat = TwitchChat.new()
			add_child(twitch_chat)
		return twitch_chat

@onready var channel_line_edit: LineEdit = %ChannelLineEdit

@onready var connect_button: Button = %ConnectButton









func _ready():
	support_button.icon = get_theme_icon("Heart", "EditorIcons")
	support_button.tooltip_text = "Support me on Ko-fi"

func _on_button_pressed():

	twitch_chat.OnMessage.connect(Pfunc)


	twitch_chat.login_anon(channel_line_edit.text)
	connect_button.disabled = true
	channel_line_edit.editable = false




func _on_line_edit_text_changed(new_text):
	connect_button.disabled = len(new_text) == 0

func _on_disconnect_button_pressed():

	twitch_chat.queue_free()
	twitch_chat = null


	show_connect_layout()





func on_chat_connected():

	show_chat_layout()
















func escape_bbcode(bbcode_text) -> String:
	return bbcode_text.replace("[", "[lb]")


@onready var lbl: Label = $Label
var total_downs: int = 0
var total_ups: int = 0
func Pfunc(chatter: Chatter):
	chatter.message = escape_bbcode(chatter.message)
	if (chatter.message).to_lower() == "down":
		total_downs += 1
	if (chatter.message).to_lower() == "up":
		total_ups += 1
	lbl.text = "downs: %s\nups: %s" % [total_downs, total_ups]





























































func show_chat_layout():


	channel_line_edit.visible = false
	connect_button.visible = false

func show_connect_layout():


	channel_line_edit.editable = true
	channel_line_edit.visible = true
	connect_button.visible = true
	connect_button.disabled = false
