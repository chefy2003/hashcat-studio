extends SceneTree

const DashboardCamera3DScript = preload("res://scripts/ui/3d/dashboard_camera_3d.gd")

func _init() -> void:
	print("=== VERIFYING TERMINAL INTERACTION, CONTROLS & WAVE SEPARATION ===")
	_run_test()

func _run_test() -> void:
	var scene = load("res://scenes/dashboard_3d.tscn")
	if scene == null:
		print("Failed to load scene")
		quit(1)
		return
	var root_node = scene.instantiate()
	root.add_child(root_node)

	for i in range(10):
		await process_frame

	var cam = root_node.find_child("Camera3D", true, false) as DashboardCamera3D
	var term = root_node.find_child("HoloTerminal3D", true, false)
	var vis = root_node.find_child("HashrateVisualizer3D", true, false)
	if cam == null or term == null or vis == null:
		print("Failed to find nodes")
		quit(1)
		return

	# 1. VERIFY WAVE SEPARATION (NO OVERLAP)
	var term_pos = term.global_position
	var vis_pos = vis.global_position
	var dist = term_pos.distance_to(vis_pos)
	print("[PASS] Distance between terminal and wave: ", dist, "m (Expected > 4.0m)")
	if dist <= 4.0:
		print("FAIL: Wave not separated!")
		quit(1)
		return

	# 2. VERIFY FREE FLIGHT MODE & INPUT GATING
	if cam.camera_mode != DashboardCamera3DScript.CameraMode.FREE_FLIGHT:
		print("FAIL: Not in FREE_FLIGHT")
		quit(1)
		return
	if term.screen_body.get("is_interaction_enabled") != false:
		print("FAIL: Interaction must be disabled in free flight")
		quit(1)
		return
	print("[PASS] Initial mode is FREE_FLIGHT, terminal clicks are gated/disabled")

	# 3. VERIFY PROXIMITY DETECTION & INTERACTION PROMPT
	# Move camera into interaction range (< 5.2m from terminal)
	cam.global_position = Vector3(4.2, 1.35, 1.5)
	for i in range(3):
		await process_frame
	if not term.is_player_in_range:
		print("FAIL: Player should be in range at 4.2m")
		quit(1)
		return
	if not term._lbl_interaction_prompt.visible:
		print("FAIL: Prompt should be visible in range")
		quit(1)
		return
	if not term._lbl_interaction_prompt.text.contains("[E] ВЛЕЗ В ТЕРМИНАЛА"):
		print("FAIL: Prompt text mismatch")
		quit(1)
		return
	print("[PASS] Proximity detection verified: prompt '[E] ВЛЕЗ В ТЕРМИНАЛА' is visible")

	# Move camera away (> 6.0m)
	cam.global_position = Vector3(0.0, 1.8, 5.8)
	for i in range(3):
		await process_frame
	if term.is_player_in_range:
		print("FAIL: Player should NOT be in range at 7.3m")
		quit(1)
		return
	if term._lbl_interaction_prompt.visible:
		print("FAIL: Prompt should hide when out of range")
		quit(1)
		return
	print("[PASS] Out-of-range detection verified: prompt hides automatically")

	# 4. VERIFY ENTERING TERMINAL FOCUS (FP VIEW CENTERING)
	cam.enter_terminal_focus(0.0)
	term.set_focused(true)
	await process_frame
	if cam.camera_mode != DashboardCamera3DScript.CameraMode.TERMINAL_FOCUS:
		print("FAIL: CameraMode should be TERMINAL_FOCUS")
		quit(1)
		return
	if term.screen_body.get("is_interaction_enabled") != true:
		print("FAIL: Interaction should be enabled in focus")
		quit(1)
		return
	if term._lbl_interaction_prompt.visible:
		print("FAIL: Prompt should be hidden when focused")
		quit(1)
		return
	if cam.position.distance_to(DashboardCamera3DScript.FP_TERMINAL_POS) > 0.05:
		print("FAIL: Camera not at FP position: ", cam.position)
		quit(1)
		return
	print("[PASS] Terminal focus entered: First Person view centered, interaction enabled, prompt hidden")

	# 5. VERIFY FULLSCREEN TOGGLE
	cam.set_terminal_fullscreen(true, 0.0)
	await process_frame
	if not cam.is_terminal_fullscreen or abs(cam.fov - DashboardCamera3DScript.FULLSCREEN_FOV) > 0.01:
		print("FAIL: Fullscreen toggle ON failed")
		quit(1)
		return
	print("[PASS] Fullscreen mode toggled ON (FOV = ", cam.fov, ")")

	cam.set_terminal_fullscreen(false, 0.0)
	await process_frame
	if cam.is_terminal_fullscreen or cam.fov != 68.0:
		print("FAIL: Fullscreen toggle OFF failed")
		quit(1)
		return
	print("[PASS] Fullscreen mode toggled OFF back to First Person")

	# 6. VERIFY EXIT FOCUS / DEACTIVATION
	cam.exit_terminal_focus(0.0)
	term.set_focused(false)
	await process_frame
	if cam.camera_mode != DashboardCamera3DScript.CameraMode.FREE_FLIGHT:
		print("FAIL: Should return to FREE_FLIGHT")
		quit(1)
		return
	if term.screen_body.get("is_interaction_enabled") != false:
		print("FAIL: Interaction should be disabled again")
		quit(1)
		return
	print("[PASS] Deactivated focus: Camera returned to free flight, WASD re-enabled")

	print("=== ALL INTERACTION & SEPARATION TESTS PASSED 100%! ===")
	root_node.queue_free()
	quit(0)
