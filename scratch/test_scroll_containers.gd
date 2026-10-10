extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame

	# Zone 3: Wrap GpuRack in a ScrollContainer
	var z3_vbox = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/VBox")
	var rack = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right/VBox/GpuRack")
	var rack_idx = rack.get_index()
	z3_vbox.remove_child(rack)
	var scroll3 = ScrollContainer.new()
	scroll3.name = "ScrollRack"
	scroll3.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll3.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll3.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll3.custom_minimum_size = Vector2(0, 150)
	z3_vbox.add_child(scroll3)
	z3_vbox.move_child(scroll3, rack_idx)
	scroll3.add_child(rack)
	rack.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Zone 2: Wrap in ScrollContainer
	var z2_panel = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center")
	var z2_vbox = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center/VBox")
	var opt_hash = z2_vbox.get_node("AlgorithmGroup/OptHashType")
	var opt_cat = z2_vbox.get_node("FilterGroup/OptCategory")
	var opt_mode = z2_vbox.get_node("RowModes/ModeGroup/OptAttackMode")
	var opt_workload = z2_vbox.get_node("RowModes/WorkloadGroup/OptWorkload")
	opt_hash.fit_to_longest_item = false
	opt_cat.fit_to_longest_item = false
	opt_mode.fit_to_longest_item = false
	opt_workload.fit_to_longest_item = false

	z2_panel.remove_child(z2_vbox)
	var scroll2 = ScrollContainer.new()
	scroll2.name = "Scroll2"
	scroll2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll2.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll2.custom_minimum_size = Vector2(250, 150)
	z2_panel.add_child(scroll2)
	scroll2.add_child(z2_vbox)
	z2_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Zone 1: Wrap in ScrollContainer
	var z1_panel = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left")
	var z1_vbox = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left/VBox")
	z1_panel.remove_child(z1_vbox)
	var scroll1 = ScrollContainer.new()
	scroll1.name = "Scroll1"
	scroll1.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll1.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll1.custom_minimum_size = Vector2(200, 150)
	z1_panel.add_child(scroll1)
	scroll1.add_child(z1_vbox)
	z1_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# GpuRack labels
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

	# Header buttons clip_text
	for btn in inst.get_node("VBox/Header/HBox").get_children():
		if btn is Button:
			btn.clip_text = true

	await process_frame
	await process_frame

	var vbox = inst.get_node("VBox")
	var z3_panel = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right")
	print("--- WITH ALL 3 ZONES PROTECTED ---")
	print("Zone 1 min_size:", z1_panel.get_combined_minimum_size())
	print("Zone 2 min_size:", z2_panel.get_combined_minimum_size())
	print("Zone 3 min_size:", z3_panel.get_combined_minimum_size())
	print("MainSplit min_size:", inst.get_node("VBox/WorkSplit/MainSplit").get_combined_minimum_size())
	print("WorkSplit min_size:", inst.get_node("VBox/WorkSplit").get_combined_minimum_size())
	print("VBox min_size:", vbox.get_combined_minimum_size())

	quit(0)
