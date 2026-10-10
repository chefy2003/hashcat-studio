extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame
	
	var z3 = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right")
	print("Zone 3 combined min size:", z3.get_combined_minimum_size())
	print("Zone 3 size:", z3.size)
	
	var rack = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/VBox/GpuRack")
	print("GpuRack combined min size:", rack.get_combined_minimum_size())
	for c in rack.get_children():
		print("  child: ", c, " name: ", c.name, " min_size: ", c.get_combined_minimum_size())
		if c is PanelContainer:
			for gc in c.get_children():
				print("    gc: ", gc, " min_size: ", gc.get_combined_minimum_size())
				for ggc in gc.get_children():
					print("      ggc: ", ggc, " class: ", ggc.get_class(), " text: ", ggc.get("text"), " min_size: ", ggc.get_combined_minimum_size())

	quit(0)
