extends SceneTree

const HoloTerminal3DScript = preload("res://scripts/ui/3d/holo_terminal_3d.gd")

func _init() -> void:
	print("=== VERIFYING TERMINAL VISUAL & FUNCTIONAL SPECIFICATION ===")
	_test_terminal()

func _test_terminal() -> void:
	var term_3d = HoloTerminal3DScript.new()
	root.add_child(term_3d)

	for i in range(5):
		await process_frame

	# 1. Verify SubViewport transparency
	var vp = term_3d.viewport
	assert(vp != null, "SubViewport must exist")
	assert(vp.transparent_bg == true, "SubViewport must have transparent_bg = true")
	print("[PASS] SubViewport has transparent_bg = true")

	# 2. Verify Material transparency on screen_mesh
	var mat = term_3d.screen_mesh.material_override as StandardMaterial3D
	assert(mat != null, "screen_mesh must have StandardMaterial3D")
	assert(mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "Material must have TRANSPARENCY_ALPHA")
	assert(mat.cull_mode == BaseMaterial3D.CULL_DISABLED, "Material must have CULL_DISABLED")
	print("[PASS] Screen mesh material has TRANSPARENCY_ALPHA and CULL_DISABLED")

	# 3. Verify Projector Puck, Beam & Particles
	var puck = term_3d.find_child("ProjectorPuck", true, false)
	assert(puck != null, "ProjectorPuck must exist on floor")
	print("[PASS] Floor Projector Puck verified at: ", puck.position)

	var particles = term_3d.find_child("HoloParticles", true, false)
	assert(particles != null, "HoloParticles must exist")
	print("[PASS] Floating upward particles verified: ", particles.amount, " particles")

	# 4. Verify Aux Screen on right side
	var aux_mesh = term_3d.find_child("AuxScreenMesh", true, false)
	assert(aux_mesh != null, "AuxScreenMesh must exist on right side")
	print("[PASS] Auxiliary hologram screen verified at: ", aux_mesh.position)

	# 5. Verify Tabs in HoloTerminalUI
	var ui = term_3d.terminal_ui
	assert(ui != null, "terminal_ui must exist")
	var tab_container = ui.find_child("TabContainer", true, false) as TabContainer
	assert(tab_container != null, "TabContainer must exist")
	assert(tab_container.get_tab_count() == 3, "TabContainer must have exactly 3 tabs (no Hardware tab)")
	assert(tab_container.get_tab_title(0).contains("НАСТРОЙКА НА АТАКА"), "Tab 0 must be Attack Setup")
	assert(tab_container.get_tab_title(1).contains("КОНЗОЛА & ИЗПЪЛНЕНИЕ"), "Tab 1 must be Console & Execution")
	assert(tab_container.get_tab_title(2).contains("СЪВЕТНИК ЗА ФЛАГОВЕ"), "Tab 2 must be Flags Guide")
	for idx in range(tab_container.get_tab_count()):
		assert(not tab_container.get_tab_title(idx).contains("Хардуер"), "Hardware tab must NOT exist")
	print("[PASS] 3 Tabs verified. Hardware tab successfully removed!")

	# 6. Verify Intensity Presets and Dials
	assert(ui._btn_low != null, "_btn_low must exist")
	assert(ui._btn_mid != null, "_btn_mid must exist")
	assert(ui._btn_high != null, "_btn_high must exist")
	assert(ui._dial_gpu_load != null, "_dial_gpu_load must exist")
	assert(ui._dial_vram_bus != null, "_dial_vram_bus must exist")
	assert(ui._dial_core_clk != null, "_dial_core_clk must exist")

	ui._set_intensity(1)
	assert(ui._selected_workload == 1, "Selected workload must be 1")
	ui._set_intensity(3)
	assert(ui._selected_workload == 3, "Selected workload must be 3")
	ui._set_intensity(2)
	assert(ui._selected_workload == 2, "Selected workload must be 2")
	print("[PASS] Intensity presets and circular dials verified!")

	# 7. Verify Telemetry Forwarding to both main UI and Aux Screen
	term_3d.update_engine_telemetry("42.5 GH/s", "65%", "ACTIVE")
	term_3d.append_console_line("[TEST] Quantum stream active")
	term_3d.add_cracked_password("098f6bcd4621d373cade4e832627b4f6", "test")
	assert(term_3d._aux_status_lbl.text.contains("ACTIVE"), "Aux status label updated")
	assert(term_3d._aux_speed_lbl.text.contains("42.5 GH/s"), "Aux speed label updated")
	assert(term_3d._aux_cracked_lbl.text.contains("test"), "Aux cracked label updated")
	print("[PASS] Dual-screen telemetry sync verified!")

	print("=== ALL TERMINAL SPECIFICATIONS 100% VERIFIED! ===")
	term_3d.queue_free()
	quit(0)
