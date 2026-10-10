extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame
	
	var header = inst.get_node("VBox/Header/HBox")
	print("Header HBox min_size: ", header.get_combined_minimum_size())
	for c in header.get_children():
		print("  child: ", c.name, " class: ", c.get_class(), " min_size: ", c.get_combined_minimum_size())

	quit(0)
