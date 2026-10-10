extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame
	
	var vbox = inst.get_node("VBox")
	var header = inst.get_node("VBox/Header")
	var z1 = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left")
	var z2 = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center")
	var z3 = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right")
	var rack = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/VBox/GpuRack")
	var opt_hash = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/VBox/AlgorithmGroup/OptHashType")
	var opt_cat = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/VBox/FilterGroup/OptCategory")
	var opt_mode = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/VBox/RowModes/ModeGroup/OptAttackMode")
	var opt_workload = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/VBox/RowModes/WorkloadGroup/OptWorkload")

	# Fix OptionButtons fit_to_longest_item
	opt_hash.fit_to_longest_item = false
	opt_cat.fit_to_longest_item = false
	opt_mode.fit_to_longest_item = false
	opt_workload.fit_to_longest_item = false

	# Fix GpuRack labels
	for c in rack.get_children():
		if c is Label:
			c.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			c.clip_text = true
		elif c is PanelContainer:
			for gc in c.get_children():
				if gc is HBoxContainer:
					for ggc in gc.get_children():
						if ggc is Label:
							ggc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
							ggc.clip_text = true
							if ggc.custom_minimum_size.x > 80:
								ggc.custom_minimum_size.x = 80
						elif ggc is CheckBox:
							ggc.custom_minimum_size.x = 75

	# Fix Header button sizes & overrun
	for btn in inst.get_node("VBox/Header/HBox").get_children():
		if btn is Button:
			btn.clip_text = true

	await process_frame
	await process_frame

	print("--- AFTER FIXES ---")
	print("Zone 3 min_size:", z3.get_combined_minimum_size())
	print("Zone 2 min_size:", z2.get_combined_minimum_size())
	print("Zone 1 min_size:", z1.get_combined_minimum_size())
	print("MainSplit min_size:", inst.get_node("VBox/WorkSplit/MainSplit").get_combined_minimum_size())
	print("Header min_size:", header.get_combined_minimum_size())
	print("VBox min_size:", vbox.get_combined_minimum_size())

	quit(0)
