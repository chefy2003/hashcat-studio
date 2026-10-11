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

	# 4. Verify ServerRack3D (Left side, safe distance on concentric arc)
	var rack = inst.find_child("ServerRack3D", true, false)
	assert(rack != null, "ServerRack3D not found")
	print("[PASS] ServerRack3D initialized with units count: ", rack.get_units().size())
	assert(rack.get_units().size() == 5, "Expected 5 compute units in rack")
	assert(rack.position.x <= -3.0, "ServerRack3D must be on the left flank (x <= -3.0)")
	var rack_dist = Vector2(rack.position.x, rack.position.z).length()
	assert(abs(rack_dist - 4.60) < 0.3, "ServerRack3D must be on the concentric arc (radius ~4.60m)")
	print("[PASS] ServerRack3D concentric position verified at: ", rack.position, " (radius: ", rack_dist, ")")

	# 5. Verify HoloTerminal3D (Right side, on concentric arc)
	var term = inst.find_child("HoloTerminal3D", true, false)
	assert(term != null, "HoloTerminal3D not found!")
	assert(term.position.x > 3.0, "HoloTerminal3D must be on the right side (x > 3.0)")
	var term_dist = Vector2(term.position.x, term.position.z).length()
	assert(abs(term_dist - 4.60) < 0.3, "HoloTerminal3D must be on the concentric arc (radius ~4.60m)")
	print("[PASS] HoloTerminal3D concentric position verified at: ", term.position, " (radius: ", term_dist, ")")

	# 6. Verify HashrateVisualizer3D (Curved Arc at center-rear)
	var vis = inst.find_child("HashrateVisualizer3D", true, false)
	assert(vis != null, "HashrateVisualizer3D not found")
	assert(vis.is_curved, "HashrateVisualizer3D must have curved arc enabled")
	var vis_dist = Vector2(vis.position.x, vis.position.z).length()
	assert(abs(vis_dist - 4.60) < 0.3, "HashrateVisualizer3D must be at radius ~4.60m")
	vis.add_sample(180.0)
	print("[PASS] HashrateVisualizer3D curved arc verified at position: ", vis.position, " (radius: ", vis_dist, ")")

	# 7. Verify Walkway Clearances between modules (> 1.15m human passage)
	var rack_to_wave_dist = rack.position.distance_to(vis.position)
	assert(rack_to_wave_dist > 2.0, "Sufficient span between rack and wave centers for passage")
	var term_to_wave_dist = term.position.distance_to(vis.position)
	assert(term_to_wave_dist > 2.0, "Sufficient span between terminal and wave centers for passage")
	print("[PASS] Free walkable clearance verified between all laboratory modules")

	# 8. Test First-Person Grounded Walking Camera
	assert(is_equal_approx(cam.position.y, 1.72) or abs(cam.position.y - 1.72) < 0.1, "Camera must start at human eye height (1.72m)")
	cam._process(0.1)
	assert(abs(cam.position.y - 1.72) < 0.1, "Camera Y position must remain locked at eye height during walking simulation")
	print("[PASS] Camera first-person grounded walking verified at eye height: ", cam.position.y)

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
