extends SceneTree

const DashboardCamera3DScript = preload("res://scripts/ui/3d/dashboard_camera_3d.gd")

func _init() -> void:
	print("--- VERIFYING 3D DASHBOARD SCENE ---")
	_run_verification()

func _run_verification() -> void:
	var scene = load("res://scenes/dashboard_3d.tscn")
	assert(scene != null, "Failed to load dashboard_3d.tscn")
	
	var inst = scene.instantiate()
	assert(inst != null, "Failed to instantiate Dashboard3DController")
	root.add_child(inst)

	# Await frames for all _ready() functions to complete
	for i in range(5):
		await process_frame

	# Verify camera
	var cam = inst.find_child("Camera3D", true, false)
	assert(cam != null, "Camera3D not found")
	print("[PASS] Camera3D initialized at position: ", cam.position)

	# Verify 3D HoloCore (no flat 2D SubViewport!)
	var holo = inst.find_child("HoloCore3D", true, false)
	assert(holo != null, "HoloCore3D not found")
	assert(inst.find_child("SubViewport", true, false) == null, "Old SubViewport should be completely removed!")
	holo.set_core_telemetry(125.4, "COMPUTING")
	print("[PASS] HoloCore3D initialized and telemetry set successfully")

	# Verify 3D Server Rack and Units
	var rack = inst.find_child("ServerRack3D", true, false)
	assert(rack != null, "ServerRack3D not found")
	var units = rack.get_units()
	print("[PASS] ServerRack3D initialized with units count: ", units.size())
	assert(units.size() >= 3, "Expected at least 3 compute units in rack")

	# Verify Hashrate Visualizer 3D
	var vis = inst.find_child("HashrateVisualizer3D", true, false)
	assert(vis != null, "HashrateVisualizer3D not found")
	vis.add_sample(88.5)
	print("[PASS] HashrateVisualizer3D sample added successfully")

	# Test camera preset switching
	cam.switch_preset(DashboardCamera3DScript.ViewPreset.RACK_TELEMETRY, 0.0)
	print("[PASS] Camera switched to RACK_TELEMETRY: ", cam.position)

	cam.switch_preset(DashboardCamera3DScript.ViewPreset.HASHRATE_WAVE, 0.0)
	print("[PASS] Camera switched to HASHRATE_WAVE: ", cam.position)

	cam.switch_preset(DashboardCamera3DScript.ViewPreset.OPERATOR_FRONT, 0.0)
	print("[PASS] Camera switched back to OPERATOR_FRONT: ", cam.position)

	print("--- 3D DASHBOARD VERIFICATION SUCCESSFUL! ---")
	inst.queue_free()
	quit(0)
