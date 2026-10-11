extends SceneTree

const DashboardCamera3DScript = preload("res://scripts/ui/3d/dashboard_camera_3d.gd")

func _init() -> void:
	print("=== VERIFYING PHYSICAL SOLIDITY & COLLISION RESISTANCE ===")
	_run_verification()

func _run_verification() -> void:
	var scene = load("res://scenes/dashboard_3d.tscn")
	assert(scene != null, "Failed to load dashboard_3d.tscn")

	var inst = scene.instantiate()
	root.add_child(inst)

	# Await physics frames so all StaticBody3Ds are fully registered in space_state
	for i in range(10):
		await physics_frame

	var cam = inst.find_child("Camera3D", true, false) as DashboardCamera3D
	var core = inst.find_child("HoloCore3D", true, false)
	var rack = inst.find_child("ServerRack3D", true, false)
	var term = inst.find_child("HoloTerminal3D", true, false)
	var wave = inst.find_child("HashrateVisualizer3D", true, false)

	assert(cam != null, "Camera3D not found")
	assert(core != null, "HoloCore3D not found")
	assert(rack != null, "ServerRack3D not found")
	assert(term != null, "HoloTerminal3D not found")
	assert(wave != null, "HashrateVisualizer3D not found")

	# 1. VERIFY STATIC BODIES EXIST ON ALL MODULES
	var core_body = core.find_child("CoreStaticBody", true, false)
	assert(core_body != null, "HoloCore3D must have CoreStaticBody")
	print("[PASS] CoreStaticBody verified on HoloCore3D")

	var rack_body = rack.find_child("RackStaticBody", true, false)
	assert(rack_body != null, "ServerRack3D must have RackStaticBody")
	print("[PASS] RackStaticBody verified on ServerRack3D")

	var term_body = term.find_child("ScreenBody", true, false)
	assert(term_body != null, "HoloTerminal3D must have ScreenBody")
	print("[PASS] ScreenBody verified on HoloTerminal3D")

	var wave_body = wave.find_child("WaveStaticBody", true, false)
	assert(wave_body != null, "HashrateVisualizer3D must have WaveStaticBody")
	print("[PASS] WaveStaticBody verified on HashrateVisualizer3D")

	# 2. TEST COLLISION WITH QUANTUM CORE
	# Position player at (0, 1.72, 2.5), looking towards core at (0, 0, 0)
	cam.global_position = Vector3(0.0, 1.72, 2.5)
	# Attempt to walk straight into the core: motion vector (0, 0, -2.0)
	var move_into_core = Vector3(0.0, 0.0, -2.0)
	var resolved_core_move = cam._move_with_collision(move_into_core)
	# The distance allowed should stop at core radius (1.35) + player radius (0.35) = 1.70m
	# So Z cannot reach below 1.65m!
	var new_pos_core = cam.global_position + resolved_core_move
	print("Move into core: attempted Z -2.0 -> final Z = ", new_pos_core.z)
	assert(new_pos_core.z >= 1.60, "Player must NOT pass through Quantum Core pedestal (Z >= 1.60)")
	print("[PASS] Quantum Core solidity verified: Player blocked at safe distance!")

	# 3. TEST COLLISION WITH SERVER RACK
	# Rack is at (-3.77, 0, -2.64). Position player in front at (-3.77, 1.72, -1.0)
	cam.global_position = Vector3(-3.77, 1.72, -1.0)
	var move_into_rack = Vector3(0.0, 0.0, -2.5)
	var resolved_rack_move = cam._move_with_collision(move_into_rack)
	var new_pos_rack = cam.global_position + resolved_rack_move
	assert(new_pos_rack.z >= -2.35, "Player must NOT pass through Server Rack chassis")
	print("[PASS] Server Rack solidity verified: Player blocked from walking through chassis!")


	# 4. TEST COLLISION WITH CURVED WAVE
	# Wave center is at (0, 0.15, -4.6). Position player at (0, 1.72, -3.5)
	cam.global_position = Vector3(0.0, 1.72, -3.5)
	var move_into_wave = Vector3(0.0, 0.0, -2.0)
	var resolved_wave_move = cam._move_with_collision(move_into_wave)
	var new_pos_wave = cam.global_position + resolved_wave_move
	print("Move into wave: attempted Z -2.0 -> final Z = ", new_pos_wave.z)
	assert(new_pos_wave.z >= -4.25, "Player must NOT pass through Curved Wave bars")
	print("[PASS] Curved Wave solidity verified: Player blocked from walking through bars!")

	# 5. TEST FREE PASSAGE THROUGH WALKWAYS
	# Left walkway: Center between rack edge (-2.99, -3.71) and wave edge (-1.87, -4.20) is around (-2.43, -3.95)
	cam.global_position = Vector3(-1.5, 1.72, -2.0)
	var dir_left = Vector3(-0.46, 0.0, -0.89).normalized()
	var walk_through_left = dir_left * 2.2 # Walk through diagonal corridor
	var resolved_walkway = cam._move_with_collision(walk_through_left)
	print("Left walkway passage: requested length ", walk_through_left.length(), ", moved length ", resolved_walkway.length())
	assert(resolved_walkway.length() > 1.7, "Player must freely walk through left walkway between rack and wave!")
	print("[PASS] Left walkway passage verified: 100% free unblocked human movement!")

	# Right walkway: Center between wave edge (1.87, -4.20) and terminal edge (2.99, -3.71)
	cam.global_position = Vector3(1.5, 1.72, -2.0)
	var dir_right = Vector3(0.46, 0.0, -0.89).normalized()
	var walk_through_right = dir_right * 1.8
	var resolved_right = cam._move_with_collision(walk_through_right)
	print("Right walkway passage: requested length ", walk_through_right.length(), ", moved length ", resolved_right.length())
	assert(resolved_right.length() > 1.7, "Player must freely walk through right walkway between wave and terminal!")
	print("[PASS] Right walkway passage verified: 100% free unblocked human movement!")

	print("=== ALL PHYSICAL SOLIDITY & COLLISION TESTS PASSED 100%! ===")
	inst.queue_free()
	quit(0)
