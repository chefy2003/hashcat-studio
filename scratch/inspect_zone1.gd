extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame
	
	var z1 = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left/VBox")
	print("Zone 1 VBox min_size: ", z1.get_combined_minimum_size())
	for c in z1.get_children():
		print("  child: ", c.name, " class: ", c.get_class(), " min_size: ", c.get_combined_minimum_size())
		if c is Container:
			for gc in c.get_children():
				print("    gc: ", gc.name, " class: ", gc.get_class(), " min_size: ", gc.get_combined_minimum_size())
				if gc is Container:
					for ggc in gc.get_children():
						print("      ggc: ", ggc.name, " class: ", ggc.get_class(), " min_size: ", ggc.get_combined_minimum_size())

	quit(0)
