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
			var strip = c
			var old_hbox = strip.get_child(0)
			var chk = old_hbox.get_child(0)
			var lbl_name = old_hbox.get_child(1)
			var lbl_temp = old_hbox.get_child(2)
			var lbl_status = old_hbox.get_child(3)
			
			old_hbox.remove_child(chk)
			old_hbox.remove_child(lbl_name)
			old_hbox.remove_child(lbl_temp)
			old_hbox.remove_child(lbl_status)
			strip.remove_child(old_hbox)
			old_hbox.queue_free()

			var vbox = VBoxContainer.new()
			vbox.add_theme_constant_override("separation", 4)
			
			var row1 = HBoxContainer.new()
			row1.add_child(chk)
			row1.add_child(lbl_name)
			lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var row2 = HBoxContainer.new()
			row2.add_child(lbl_temp)
			var sp = Control.new()
			sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row2.add_child(sp)
			row2.add_child(lbl_status)
			
			vbox.add_child(row1)
			vbox.add_child(row2)
			strip.add_child(vbox)
			
			await process_frame
			await process_frame
			
			print("=== PROTOTYPE 2-ROW STRIP ===")
			print("Strip size:", strip.size)
			print("Row 1 size:", row1.size, " lbl_name size:", lbl_name.size, " text:", lbl_name.text)
			print("Row 2 size:", row2.size, " lbl_temp size:", lbl_temp.size, " lbl_status size:", lbl_status.size)
			break

	quit(0)
