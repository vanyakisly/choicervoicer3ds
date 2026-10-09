class_name TwitchHandler
extends Node




enum PARSE_TYPE{NONE, CLASSIC, PANELIST}

var twitch_chat: TwitchChat:
	get:
		if twitch_chat == null:
			twitch_chat = TwitchChat.new()
			add_child(twitch_chat)
		return twitch_chat
var twitch_channel_name: String:
	set(value):
		if not value.is_empty():
			twitch_channel_name = value.strip_edges()
			twitch_chat.login_anon(twitch_channel_name)
@export var parser_vote: ChatParserVote:
	set(value):
		parser_vote = value
		if parser_vote.get_parent() == null: add_child(parser_vote)
var parser_panel: ChatParserPanel


func _init(input_channel_name: String = "", parse_as: PARSE_TYPE = PARSE_TYPE.CLASSIC) -> void :
	twitch_channel_name = input_channel_name
	match parse_as:
		PARSE_TYPE.PANELIST:
			parser_panel = ChatParserPanel.new()
			add_child(parser_panel)
			twitch_chat.OnMessage.connect(parser_panel.panel_parse_chatter_message)
		PARSE_TYPE.CLASSIC:
			if Profile.twitch_vote_type_is_binary:
				parser_vote = ChatParserVoteBinary.new()
			else: parser_vote = ChatParserVoteScore.new()
			twitch_chat.OnMessage.connect(parser_vote._parse_message)
