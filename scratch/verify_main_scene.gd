extends SceneTree

func _init():
	print("--- TESTING INSTANTIATION OF SCENES/MAIN.TSCN ---")
	var scene = load("res://scenes/main.tscn")
	assert(scene != null, "Scene must load")
	var inst = scene.instantiate()
	assert(inst != null, "Instance must not be null")
	root.add_child(inst)
	
	await process_frame
	await process_frame
	
	print("[PASS] Scene loaded and added to tree successfully!")
	print("MainUI size:", inst.size)
	print("MainUI position:", inst.position)
	print("VBox size:", inst.get_node("VBox").size)
	print("VBox position:", inst.get_node("VBox").position)
	print("Header position:", inst.get_node("VBox/Header").global_position)
	print("Zone 1 position:", inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left").global_position)
	print("Zone 2 position:", inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center").global_position)
	print("Zone 3 position:", inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right").global_position)
	print("BottomDeck position:", inst.get_node("VBox/WorkSplit/BottomDeck").global_position)
	print("WorkSplit size:", inst.get_node("VBox/WorkSplit").size)

	quit(0)
