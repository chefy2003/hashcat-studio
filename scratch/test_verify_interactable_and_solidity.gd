extends SceneTree

const DashboardCamera3DScript = preload("res://scripts/ui/3d/dashboard_camera_3d.gd")
const Interactable3DScript = preload("res://scripts/ui/3d/interactable_3d.gd")
const Gui3DPanelScript = preload("res://scripts/ui/3d/gui_3d_panel.gd")

func _init() -> void:
	print("=== RUNNING FULL VERIFICATION: INTERACTABLE3D, SOLIDITY & MOUSE MODE ===")
	_run_all_tests()

func _run_all_tests() -> void:
	var scene = load("res://scenes/dashboard_3d.tscn")
	assert(scene != null, "Failed to load dashboard_3d.tscn")

	var inst = scene.instantiate()
	root.add_child(inst)

	# Await physics frames so all bodies and raycasts are active in PhysicsServer
	for i in range(12):
		await physics_frame

	var cam = inst.find_child("Camera3D", true, false) as DashboardCamera3D
	var core = inst.find_child("HoloCore3D", true, false)
	var rack = inst.find_child("ServerRack3D", true, false)
	var term = inst.find_child("HoloTerminal3D", true, false)
	var wave = inst.find_child("HashrateVisualizer3D", true, false)

	assert(cam != null, "Camera3D must exist")
	assert(core != null, "HoloCore3D must exist")
	assert(rack != null, "ServerRack3D must exist")
	assert(term != null, "HoloTerminal3D must exist")
	assert(wave != null, "HashrateVisualizer3D must exist")

	# ---------------------------------------------------------
	# 1. VERIFY ALL MODULES INHERIT OR USE INTERACTABLE3D
	# ---------------------------------------------------------
	print("\n--- TEST 1: INTERACTABLE3D INTEGRATION ---")
	var term_screen_body = term.find_child("ScreenBody", true, false)
	assert(term_screen_body != null, "ScreenBody must exist")
	assert(term_screen_body is Interactable3DScript, "ScreenBody must be an Interactable3D")
	assert(term_screen_body.get_prompt() == "Влез в терминала", "Screen prompt mismatch: " + term_screen_body.get_prompt())
	print("[PASS] HoloTerminal3D ScreenBody is Interactable3D ('%s')" % term_screen_body.get_prompt())

	var rack_body = rack.find_child("RackStaticBody", true, false)
	assert(rack_body != null, "RackStaticBody must exist")
	assert(rack_body is Interactable3DScript, "RackStaticBody must be an Interactable3D")
	assert(rack_body.get_prompt() == "Преглед на хардуерните възли", "Rack prompt mismatch: " + rack_body.get_prompt())
	print("[PASS] ServerRack3D RackStaticBody is Interactable3D ('%s')" % rack_body.get_prompt())

	var core_body = core.find_child("CoreStaticBody", true, false)
	assert(core_body != null, "CoreStaticBody must exist")
	assert(core_body is Interactable3DScript, "CoreStaticBody must be an Interactable3D")
	assert(core_body.get_prompt() == "Квантово Ядро: Овърклок статус", "Core prompt mismatch: " + core_body.get_prompt())
	print("[PASS] HoloCore3D CoreStaticBody is Interactable3D ('%s')" % core_body.get_prompt())

	var wave_body = wave.find_child("WaveStaticBody", true, false)
	assert(wave_body != null, "WaveStaticBody must exist")
	assert(wave_body is Interactable3DScript, "WaveStaticBody must be an Interactable3D")
	assert(wave_body.get_prompt() == "Хешрейт Масив: Мониторинг на вълната", "Wave prompt mismatch: " + wave_body.get_prompt())
	print("[PASS] HashrateVisualizer3D WaveStaticBody is Interactable3D ('%s')" % wave_body.get_prompt())

	# ---------------------------------------------------------
	# 2. VERIFY RAYCAST & HUD ARCHITECTURE
	# ---------------------------------------------------------
	print("\n--- TEST 2: RAYCAST & HUD CONTROLLER ---")
	var raycast = cam.find_child("InteractionRayCast", true, false) as RayCast3D
	assert(raycast != null, "InteractionRayCast must be attached to Camera3D")
	assert(raycast.target_position.z <= -2.0, "Raycast target must be at least 2.0m along -Z")
	print("[PASS] RayCast3D verified at length: ", abs(raycast.target_position.z))

	var hud_layer = cam.find_child("InteractionHUDLayer", true, false) as CanvasLayer
	assert(hud_layer != null, "InteractionHUDLayer must exist")
	var reticle = hud_layer.find_child("Reticle", true, false) as Control
	var prompt_lbl = hud_layer.find_child("PromptLabel", true, false) as Label
	assert(reticle != null, "Reticle must exist")
	assert(prompt_lbl != null, "PromptLabel must exist")
	print("[PASS] Cyberpunk Reticle and PromptLabel verified in HUD layer")

	# ---------------------------------------------------------
	# 3. VERIFY AIMING, FOCUS & [E] KEY INTERACTION
	# ---------------------------------------------------------
	print("\n--- TEST 3: AIMING, FOCUS & INTERACTION TRIGGER ---")
	# Point camera directly at the HoloTerminal screen from 1.6m away
	# Terminal screen is around (3.77, 1.35, -2.64), facing ~ -55 degrees
	cam.global_position = Vector3(3.05, 1.38, -2.14)
	cam.rotation_degrees = Vector3(-1.0, -55.0, 0.0)
	raycast.force_raycast_update()
	await physics_frame
	await physics_frame

	print("Raycast colliding: ", raycast.is_colliding())
	if raycast.is_colliding():
		print("Raycast hit: ", raycast.get_collider().name)
	assert(raycast.is_colliding(), "Raycast must collide with HoloTerminal screen")
	assert(raycast.get_collider() == term_screen_body, "Raycast must target ScreenBody")
	assert(prompt_lbl.visible == true, "PromptLabel must be visible when aiming at terminal")
	assert(prompt_lbl.text.contains("Влез в терминала"), "Prompt text must contain 'Влез в терминала'")
	print("[PASS] Focus verified: Screen targeted, prompt displayed: '%s'" % prompt_lbl.text)

	# Simulate pressing [E] key
	var terminal_activated_fired = [false]
	term.terminal_activated.connect(func():
		terminal_activated_fired[0] = true
	)
	var e_event = InputEventKey.new()
	e_event.pressed = true
	e_event.keycode = KEY_E
	raycast._unhandled_input(e_event)
	await physics_frame

	assert(terminal_activated_fired[0] == true, "[E] key must trigger terminal_activated signal")
	print("[PASS] Interaction execution verified: [E] successfully activates terminal!")


	# ---------------------------------------------------------
	# 4. VERIFY MOUSE CAPTURE & TRANSITION TO VISIBLE
	# ---------------------------------------------------------
	print("\n--- TEST 4: MOUSE MODE TRANSITIONS ---")
	# In walking mode, mouse must be captured
	cam.exit_terminal_focus(0.0)
	assert(cam.get_target_mouse_mode() == Input.MOUSE_MODE_CAPTURED, "Mouse mode must be CAPTURED during walking mode")
	print("[PASS] Walking mode: Target mouse mode == MOUSE_MODE_CAPTURED")

	# On entering terminal focus, mouse must be visible
	cam.enter_terminal_focus(0.0)
	assert(cam.get_target_mouse_mode() == Input.MOUSE_MODE_VISIBLE, "Mouse mode must be VISIBLE during terminal focus")
	assert(cam.camera_mode == DashboardCamera3DScript.CameraMode.TERMINAL_FOCUS, "Camera mode must be TERMINAL_FOCUS")
	print("[PASS] Terminal focus mode: Target mouse mode == MOUSE_MODE_VISIBLE")

	# On pressing ESC, mouse must re-capture
	var esc_event = InputEventKey.new()
	esc_event.pressed = true
	esc_event.keycode = KEY_ESCAPE
	cam._unhandled_input(esc_event)
	assert(cam.camera_mode == DashboardCamera3DScript.CameraMode.FREE_FLIGHT, "ESC must return to FREE_FLIGHT mode")
	assert(cam.get_target_mouse_mode() == Input.MOUSE_MODE_CAPTURED, "ESC must re-capture mouse to MOUSE_MODE_CAPTURED")
	print("[PASS] ESC exit: Returned to FREE_FLIGHT and re-captured mouse to MOUSE_MODE_CAPTURED!")


	# ---------------------------------------------------------
	# 5. VERIFY TRUE PHYSICAL SOLIDITY (ZERO PENETRATION)
	# ---------------------------------------------------------
	print("\n--- TEST 5: TRUE PHYSICAL SOLIDITY (ZERO PENETRATION) ---")
	var char_body = cam._char_body
	assert(char_body != null, "Player CharacterBody3D must exist in camera")

	# A. Quantum Core Pedestal Collision (Core at 0, 0, 0, radius 1.35m + player 0.35m = 1.70m boundary)
	cam.global_position = Vector3(0.0, 1.72, 2.5)
	char_body.global_position = Vector3(0.0, 0.0, 2.5)
	await physics_frame
	for f in range(60):
		# Push straight into core (-Z)
		char_body.velocity = Vector3(0.0, 0.0, -5.0)
		char_body.move_and_slide()
		cam.global_position.x = char_body.global_position.x
		cam.global_position.z = char_body.global_position.z
		await physics_frame

	print("Quantum Core collision test: final Z = %f (boundary >= 1.69m)" % char_body.global_position.z)
	assert(char_body.global_position.z >= 1.69, "Player must NOT penetrate Quantum Core! Z was: %f" % char_body.global_position.z)
	print("[PASS] Quantum Core is 100% impenetrable!")

	# B. Server Rack Collision (Rack at -3.77, 0, -2.64, angled 35 deg)
	var rack_front_dir = Vector3(0.573576, 0, 0.819152).normalized()
	char_body.global_position = Vector3(-3.77, 0, -2.64) + rack_front_dir * 1.5
	await physics_frame
	for f in range(60):
		char_body.velocity = -rack_front_dir * 5.0
		char_body.move_and_slide()
		await physics_frame

	var dist_rack = (char_body.global_position - Vector3(-3.77, 0, -2.64)).length()
	print("Server Rack collision test: distance to center = %f (boundary >= 0.75m)" % dist_rack)
	assert(dist_rack >= 0.75, "Player must NOT penetrate Server Rack! Dist was: %f" % dist_rack)
	print("[PASS] Server Rack chassis is 100% impenetrable!")

	# C. Curved Wave Collision (Wave at 0, 0.15, -4.60)
	char_body.global_position = Vector3(0.0, 0.0, -3.5)
	await physics_frame
	for f in range(60):
		char_body.velocity = Vector3(0.0, 0.0, -5.0)
		char_body.move_and_slide()
		await physics_frame

	print("Curved Wave collision test: final Z = %f (boundary >= -4.30m)" % char_body.global_position.z)
	assert(char_body.global_position.z >= -4.30, "Player must NOT penetrate Curved Wave! Z was: %f" % char_body.global_position.z)
	print("[PASS] Curved Wave array is 100% impenetrable!")

	print("\n=======================================================")
	print(">>> ALL VERIFICATION TESTS PASSED 100% SUCCESSFULLY! <<<")
	print("=======================================================")
	inst.queue_free()
	quit(0)
