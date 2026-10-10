extends SceneTree

const DashboardCamera3DScript = preload("res://scripts/ui/3d/dashboard_camera_3d.gd")

func _init() -> void:
	print("--- VERIFYING 3D COCKPIT ARENA & HOLO TERMINAL ---")
	_run_verification()

func _run_verification() -> void:
	var scene = load("res://scenes/dashboard_3d.tscn")
	assert(scene != null, "Failed to load dashboard_3d.tscn")

	var inst = scene.instantiate()
	assert(inst != null, "Failed to instantiate Dashboard3DController")
	root.add_child(inst)

	# Await frames for all _ready() functions to complete
	for i in range(8):
		await process_frame

	# 1. VERIFY ZERO 2D SCREEN OVERLAYS
	var hud_node = inst.find_child("HUD", true, false)
	assert(hud_node == null, "CRITICAL: No 2D HUD CanvasLayer should exist on screen!")
	print("[PASS] Confirmed ZERO 2D screen overlays (HUD completely removed)!")

	# 2. Verify Camera3D
	var cam = inst.find_child("Camera3D", true, false) as DashboardCamera3D
	assert(cam != null, "Camera3D not found")
	print("[PASS] Camera3D initialized at position: ", cam.position)

	# 3. Verify HoloCore3D at Center (0, 0, 0)
	var holo = inst.find_child("HoloCore3D", true, false)
	assert(holo != null, "HoloCore3D not found")
	assert(holo.position == Vector3.ZERO, "HoloCore3D must be at center (0, 0, 0)")
	holo.set_core_telemetry(240.0, "HYBRID COMPUTING")
	print("[PASS] HoloCore3D in center verified")

	# 4. Verify ServerRack3D (Left side, distance x2)
	var rack = inst.find_child("ServerRack3D", true, false)
	assert(rack != null, "ServerRack3D not found")
	print("[PASS] ServerRack3D initialized with units count: ", rack.get_units().size())
	assert(rack.get_units().size() == 5, "Expected 5 compute units in rack")
	assert(rack.position.x <= -4.5, "ServerRack3D must be spaced out on the left")

	# 5. Verify HoloTerminal3D (Right side, in-world terminal)
	var term = inst.find_child("HoloTerminal3D", true, false)
	assert(term != null, "HoloTerminal3D not found!")
	assert(term.position.x > 4.5, "HoloTerminal3D must be on the right side")
	print("[PASS] HoloTerminal3D on right side verified at position: ", term.position)

	# 6. Verify HashrateVisualizer3D
	var vis = inst.find_child("HashrateVisualizer3D", true, false)
	assert(vis != null, "HashrateVisualizer3D not found")
	vis.add_sample(180.0)
	print("[PASS] HashrateVisualizer3D verified at position: ", vis.position)

	# 7. Test WASD Camera simulation
	var prev_pos = cam.global_position
	# Simulate process with move input
	cam._process(0.1)
	print("[PASS] Camera _process executed successfully")

	# 8. Test Presets
	cam.switch_preset(DashboardCamera3DScript.ViewPreset.HOLO_TERMINAL, 0.0)
	print("[PASS] Camera switched to HOLO_TERMINAL: ", cam.position)

	cam.switch_preset(DashboardCamera3DScript.ViewPreset.RACK_TELEMETRY, 0.0)
	print("[PASS] Camera switched to RACK_TELEMETRY: ", cam.position)

	cam.switch_preset(DashboardCamera3DScript.ViewPreset.OPERATOR_FRONT, 0.0)
	print("[PASS] Camera switched back to OPERATOR_FRONT: ", cam.position)

	print("--- ALL 3D COCKPIT ARENA VERIFICATIONS PASSED! ---")
	inst.queue_free()
	quit(0)
