extends SceneTree

func _init() -> void:
	print("--- TESTING BIDIRECTIONAL 2D <-> 3D SWITCHING ---")
	_run_switch_test()

func _run_switch_test() -> void:
	# 1. Load 2D Main Wizard
	change_scene_to_file("res://scenes/main_wizard.tscn")
	for i in range(10):
		await process_frame

	var win = root
	var current_scene = win.get_child(win.get_child_count() - 1)
	assert(current_scene.name == "MainUI" or current_scene.find_child("Btn3DOpsDeck", true, false) != null, "Main wizard not loaded")
	print("[PASS] 2D Main Wizard loaded successfully")

	# 2. Trigger 3D Ops Deck switch
	var btn_3d = current_scene.find_child("Btn3DOpsDeck", true, false) as Button
	assert(btn_3d != null, "Btn3DOpsDeck not found in 2D UI")
	btn_3d.emit_signal("pressed")

	# Wait for scene transition
	for i in range(15):
		await process_frame

	current_scene = win.get_child(win.get_child_count() - 1)
	assert(current_scene.name == "Dashboard3D", "Dashboard3D scene not loaded after transition")
	print("[PASS] Transition to Dashboard3D successful: ", current_scene.name)

	# 3. Trigger Return to 2D
	var btn_return = current_scene.find_child("BtnReturn2D", true, false) as Button
	assert(btn_return != null, "BtnReturn2D not found in 3D HUD")
	btn_return.emit_signal("pressed")

	# Wait for return transition
	for i in range(15):
		await process_frame

	current_scene = win.get_child(win.get_child_count() - 1)
	assert(current_scene.name == "MainUI", "MainUI scene not loaded after return")
	print("[PASS] Transition back to MainUI 2D successful: ", current_scene.name)

	print("--- BIDIRECTIONAL SWITCH TEST COMPLETED SUCCESSFULLY! ---")
	quit(0)
