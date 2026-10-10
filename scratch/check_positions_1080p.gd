extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	
	var vp = SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	root.add_child(vp)
	vp.add_child(inst)
	
	await process_frame
	await process_frame
	
	print("vp size:", vp.size)
	print("inst size:", inst.size)
	print("inst position:", inst.position)
	print("vbox size:", inst.get_node("VBox").size)
	print("vbox position:", inst.get_node("VBox").position)
	print("Header position:", inst.get_node("VBox/Header").global_position)
	print("WorkSplit position:", inst.get_node("VBox/WorkSplit").global_position)
	print("Zone1 position:", inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left").global_position)
	print("Zone2 position:", inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center").global_position)
	print("Zone3 position:", inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right").global_position)
	print("BottomDeck position:", inst.get_node("VBox/WorkSplit/BottomDeck").global_position)

	quit(0)
