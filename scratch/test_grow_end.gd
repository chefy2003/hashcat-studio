extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	var vbox = inst.get_node("VBox")
	vbox.grow_horizontal = Control.GROW_DIRECTION_END
	vbox.grow_vertical = Control.GROW_DIRECTION_END
	inst.grow_horizontal = Control.GROW_DIRECTION_END
	inst.grow_vertical = Control.GROW_DIRECTION_END

	var vp = SubViewport.new()
	vp.size = Vector2i(960, 600)
	root.add_child(vp)
	vp.add_child(inst)
	
	await process_frame
	await process_frame

	print("Viewport size:", vp.size)
	print("VBox position:", vbox.global_position)
	print("Header position:", inst.get_node("VBox/Header").global_position)
	print("Zone 1 position:", inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left").global_position)

	quit(0)
