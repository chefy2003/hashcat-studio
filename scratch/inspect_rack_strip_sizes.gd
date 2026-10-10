extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame

	var rack = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/Scroll3/VBox/GpuRack")
	for c in rack.get_children():
		if c is PanelContainer:
			var hbox = c.get_child(0)
			print("Strip HBox size: ", hbox.size)
			for ggc in hbox.get_children():
				print("    ", ggc.name, " class: ", ggc.get_class(), " size: ", ggc.size, " text: '", ggc.get("text"), "'")

	quit(0)
