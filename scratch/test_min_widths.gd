extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame

	# Zone 1
	var z1_vbox = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left/VBox")
	for c in z1_vbox.get_children():
		if c is Container:
			for gc in c.get_children():
				if gc is Button:
					gc.clip_text = true
				elif gc is Container:
					for ggc in gc.get_children():
						if ggc is Button:
							ggc.clip_text = true

	# Zone 2
	var z2_vbox = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/VBox")
	var opt_hash = z2_vbox.get_node("AlgorithmGroup/OptHashType")
	var opt_cat = z2_vbox.get_node("FilterGroup/OptCategory")
	var opt_mode = z2_vbox.get_node("RowModes/ModeGroup/OptAttackMode")
	var opt_workload = z2_vbox.get_node("RowModes/WorkloadGroup/OptWorkload")
	for opt in [opt_hash, opt_cat, opt_mode, opt_workload]:
		opt.fit_to_longest_item = false
		opt.clip_text = true
		opt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	# Zone 3
	var rack = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/VBox/GpuRack")
	for c in rack.get_children():
		if c is Label:
			c.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			c.clip_text = true
		elif c is HBoxContainer:
			for gc in c.get_children():
				if gc is Button:
					gc.clip_text = true
					gc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		elif c is PanelContainer:
			for gc in c.get_children():
				if gc is HBoxContainer:
					for ggc in gc.get_children():
						if ggc is Label:
							ggc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
							ggc.clip_text = true
							if ggc.custom_minimum_size.x > 75:
								ggc.custom_minimum_size.x = 75
						elif ggc is CheckBox:
							ggc.custom_minimum_size.x = 75

	await process_frame
	await process_frame

	var z1 = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left")
	var z2 = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center")
	var z3 = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right")
	print("Zone 1 min width:", z1.get_combined_minimum_size().x)
	print("Zone 2 min width:", z2.get_combined_minimum_size().x)
	print("Zone 3 min width:", z3.get_combined_minimum_size().x)
	print("MainSplit min width:", inst.get_node("VBox/WorkSplit/MainSplit").get_combined_minimum_size().x)

	quit(0)
