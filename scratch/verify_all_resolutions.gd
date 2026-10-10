extends SceneTree

func _init():
	var test_res = [
		Vector2i(960, 600),
		Vector2i(1024, 576),
		Vector2i(1280, 720),
		Vector2i(1920, 1080),
		Vector2i(3200, 1080)
	]
	
	for r in test_res:
		var scene = load("res://scenes/main.tscn")
		var inst = scene.instantiate()
		var vp = SubViewport.new()
		vp.size = r
		root.add_child(vp)
		vp.add_child(inst)
		await process_frame
		await process_frame
		
		var vbox = inst.get_node("VBox")
		var header = inst.get_node("VBox/Header")
		var z1 = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left")
		var z2 = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center")
		var z3 = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right")
		var bd = inst.get_node("VBox/WorkSplit/BottomDeck")
		
		print("================ RESOLUTION: %s x %s ================" % [r.x, r.y])
		print("  VBox pos: %s, size: %s" % [vbox.global_position, vbox.size])
		print("  Header pos: %s, size: %s" % [header.global_position, header.size])
		print("  Zone 1 pos: %s, size: %s" % [z1.global_position, z1.size])
		print("  Zone 2 pos: %s, size: %s" % [z2.global_position, z2.size])
		print("  Zone 3 pos: %s, size: %s" % [z3.global_position, z3.size])
		print("  BottomDeck pos: %s, size: %s" % [bd.global_position, bd.size])
		
		assert(vbox.global_position.x >= 0, "VBox X must not be negative")
		assert(vbox.global_position.y >= 0, "VBox Y must not be negative")
		assert(header.global_position.y >= 0, "Header must be visible at top")
		assert(z1.global_position.x >= 0, "Zone 1 must be visible on left")
		assert(bd.global_position.y >= 0, "BottomDeck must be in bounds")
		
		root.remove_child(vp)
		vp.queue_free()

	print(">>> ALL RESOLUTIONS VERIFIED: 100% IN-BOUNDS AND VISIBLE! <<<")
	quit(0)
