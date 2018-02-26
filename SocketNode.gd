extends Node
const PomeloMessageClass = preload('res://PomeloMessage.gd')
var pomelo = PomeloMessageClass.new()
var socket = StreamPeerTCP.new()
var _accum = 0  # delta accumulator
var _active = false   # socket intended for use
var _connected = false  # socket is connected

var nextHeartbeatTimeout = 0
var needSendHeartBeat = true
var curTime = 0

const ERR = 1

export(String) var host = "127.0.0.1"
export(int) var port = 3014

var handlerFuncs = {}
var requestId = 1

signal login(name, roomid)
signal enterServer(name, roomid)
signal say(content)

var userid = ""
var roomid = 1

var clientState = ""

func _ready():
	connect_to_server(host, port)
	set_process(true)
	connect("login", self, "loginWithNameAndRoomId")
	connect("enterServer", self, "getServerInfo")
	connect("say", self, "sendChat")
	
func _process(delta):
	curTime = curTime + delta
	_readloop(delta)	

func write(string):
	if(_connected):
		socket.put_utf8_string(string)

func connect_to_server(host, port):
	_active = true
	var err = socket.connect_to_host(host, port)
	_connected = socket.is_connected_to_host()
	if _connected:
		#socket.put_8(1)
		needSendHeartBeat = true
		pomelo.handshakeFirst(socket)
		pass
	return err

func disconnect():
	_active = false
	_connected = false
	needSendHeartBeat = false
	socket.disconnect_from_host()

func _readloop(delta):
	if(not _active):
		return
		pass
		
	# TODO, emit errors and data
	_accum += delta
	
	if(_accum > 1):
		_accum = 0
		var connected = socket.is_connected_to_host()
		
		if(not connected):
			print("Lost Connection")
			_respond("Lost Connection", ERR)
		else:
			var output = socket.get_partial_data(socket.get_available_bytes())
			var errCode = output[0]
			var outputData = output[1]
			
			if(errCode != 0):
				_respond( "ErrCode:" + str(errCode), ERR)
			else:
				var outStr = outputData.get_string_from_utf8()
				if(outStr != ""):
					_respond( outputData, 0 )
	
	if curTime >= nextHeartbeatTimeout and needSendHeartBeat == true:
		pomelo.heartBeat(socket)
		needSendHeartBeat = false
	
func _respond(outputData, errCode):
	if(errCode == 0):
		_respondOK(outputData)
	elif(errCode == ERR):
		_respondErr(outputData)

func _respondOK(outputData):
	# TODO emit?
	var msgs = pomelo.processPackage(socket, outputData)
	if typeof(msgs) == TYPE_ARRAY:
		for i in range(msgs.size()):
			handlerWithType(socket, msgs[i].type, msgs[i].body)
		pass
	else:
		handlerWithType(socket, msgs.type, msgs.body)
	pass

func handlerWithType(socket, type, body):
	if type == pomelo.TYPE_HANDSHAKE:
		print(PoolByteArray(body).get_string_from_utf8())
		pomelo.handshakeACK(socket)
		if clientState == "wait_to_login":
			emit_signal("login", userid, roomid)
			clientState = ""
		pass
	
	if type == pomelo.TYPE_HEARTBEAT:
		print("get heart beat")
		needSendHeartBeat = true
		nextHeartbeatTimeout = curTime + 3

	if type == pomelo.TYPE_DATA:
		var resoult = pomelo.decodeMessage(body)
		if resoult.id > 0 && resoult.type == pomelo.TYPE_RESPONSE && handlerFuncs[resoult.id] == "gate.gateHandler.queryEntry":
			disconnect()
			var jsonstring = PoolByteArray(resoult.body).get_string_from_utf8()
			var jsonresult = JSON.parse(jsonstring)
			connect_to_server(jsonresult.result.host, jsonresult.result.port)
			clientState = "wait_to_login"
		
		if resoult.id > 0 && resoult.type == pomelo.TYPE_RESPONSE && handlerFuncs[resoult.id] == "connector.entryHandler.enter":
			var jsonstring = PoolByteArray(resoult.body).get_string_from_utf8()
			var jsonresult = JSON.parse(jsonstring)
			$roomRoot.firstShowUsers(jsonresult.result.users)
			$roomRoot.visible = true
			pass
		if resoult.type == pomelo.TYPE_PUSH:
			if resoult.route == "onChat":
				var jsonstring = PoolByteArray(resoult.body).get_string_from_utf8()
				var jsonresult = JSON.parse(jsonstring)
				var format_string = "%s:%s"
				var text = format_string % [jsonresult.result.from, jsonresult.result.msg]
				$roomRoot.addMsgToList(text)
			if resoult.route == "onAdd":
				var jsonstring = PoolByteArray(resoult.body).get_string_from_utf8()
				var jsonresult = JSON.parse(jsonstring)
				$roomRoot.addUser(jsonresult.result.user)
			if resoult.route == "onLeave":
				var jsonstring = PoolByteArray(resoult.body).get_string_from_utf8()
				var jsonresult = JSON.parse(jsonstring)
				$roomRoot.removeUser(jsonresult.result.user)
				
		

func _respondErr(outputData):
	# TODO emit?
	print(outputData)
	pass

func getServerInfo(name, roomid):
	userid = name
	roomid = roomid
	if(_connected):
		requestId = requestId + 1
		pomelo.sendMessage(socket, requestId, "gate.gateHandler.queryEntry", to_json({"uid":name}))
		handlerFuncs[requestId] = "gate.gateHandler.queryEntry"
		print(handlerFuncs)
		
	pass # replace with function body


func loginWithNameAndRoomId(name, roomid):
	if(_connected):
		requestId = requestId + 1
		pomelo.sendMessage(socket, requestId, "connector.entryHandler.enter", to_json({"username":name, "rid":roomid }))
		handlerFuncs[requestId] = "connector.entryHandler.enter"
		print(handlerFuncs)
	pass # replace with function body

func sendChat(content):
	if _connected:
		print("send:")
		print(content)
		requestId = requestId + 1
		var msg = {
			"rid": userid,
			"content": content,
			"from": userid,
			"target": "*"
		}
		pomelo.sendMessage(socket, requestId, "chat.chatHandler.send", to_json(msg))
		handlerFuncs[requestId] = "chat.chatHandler.send"
	pass
