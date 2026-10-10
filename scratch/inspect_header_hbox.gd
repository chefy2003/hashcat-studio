extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame

	var header_hbox = inst.get_node("VBox/Header/HBox")
	print("Header HBox total size:", header_hbox.size)
	for c in header_hbox.get_children():
		print("  child: ", c.name, " class: ", c.get_class(), " size: ", c.size, " min_size: ", c.get_combined_minimum_size(), " size_flags: ", c.size_flags_horizontal)

	quit(0)
