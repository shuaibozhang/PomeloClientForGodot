extends Control

var sayitem = preload("res://Label.tscn")
# class member variables go here, for example:
# var a = 2
# var b = "textvar"
signal say(content)

var userMap = []

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func addMsgToList(msg):
	var item = sayitem.instance()
	item.text = msg
	$ScrollContainer/VBoxContainer.add_child(item)

func firstShowUsers(users):
	var usertree = $userTree
	var root = usertree.create_item()
	root.set_text(0, "房间成员")
	for i in range(users.size()):
		var item= usertree.create_item()
		item.set_text(0, users[i])
		userMap.append(users[i])
		pass

func addUser(name):
	var usertree = $userTree
	var item = usertree.create_item()
	item.set_text(0, name)
	userMap.append(name)

func removeUser(name):
	var usertree = $userTree
	usertree.clear()
	var idx = userMap.find(name)
	if idx != -1:
		userMap.remove(idx)	
	var root = usertree.create_item()
	root.set_text(0, "房间成员")
	for i in userMap:
		var item= usertree.create_item()
		item.set_text(0, i)
	pass
	
	
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_send_button_down():
	get_node("/root/CanvasLayer").emit_signal("say", $LineEdit.text)
	pass # replace with function body
