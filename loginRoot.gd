extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
signal enterServer(name, roomid)

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_Button_button_down():
	var name = $user/LineEdit.text
	var roomid = $roomid/LineEdit.text
	if name != "" && roomid != "":
		print(name)
		print(roomid)
		get_node("/root/CanvasLayer").emit_signal("enterServer", name, roomid)
		
		visible = false
	pass # replace with function body
