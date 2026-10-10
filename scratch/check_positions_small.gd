extends SceneTree

func _init():
	for s in [Vector2i(1280, 720), Vector2i(960, 600)]:
		var scene = load("res://scenes/main.tscn")
		var inst = scene.instantiate()
		var vp = SubViewport.new()
		vp.size = s
		root.add_child(vp)
		vp.add_child(inst)
		await process_frame
		await process_frame
		
		print("=== Viewport: ", s, " ===")
		print("vbox size:", inst.get_node("VBox").size)
		print("vbox position:", inst.get_node("VBox").position)
		print("Header position:", inst.get_node("VBox/Header").global_position)
		print("WorkSplit position:", inst.get_node("VBox/WorkSplit").global_position)
		print("Zone1 position:", inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left").global_position)
		print("BottomDeck position:", inst.get_node("VBox/WorkSplit/BottomDeck").global_position)
		root.remove_child(vp)
		vp.queue_free()

	quit(0)
