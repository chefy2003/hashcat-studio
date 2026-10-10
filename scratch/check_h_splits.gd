extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	
	for w in [1920, 1280, 960]:
		inst.size = Vector2(w, 720)
		await process_frame
		await process_frame
		var z1 = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left")
		var z2 = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center")
		var z3 = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right")
		print("Window width ", w, ":")
		print("  Zone 1: ", z1.size.x)
		print("  Zone 2: ", z2.size.x)
		print("  Zone 3: ", z3.size.x)

	quit(0)
