extends SceneTree

func _init() -> void:
	print("--- TESTING FULL 3D HOLO TERMINAL INTELLIGENCE SUITE ---")
	_run()

func _run() -> void:
	var term_ui_script = load("res://scripts/ui/3d/holo_terminal_ui.gd")
	assert(term_ui_script != null, "Failed to load HoloTerminalUI")

	var ui = term_ui_script.new()
	root.add_child(ui)

	for i in range(5):
		await process_frame

	# 1. Test Hardware & NUMA Toggles
	print("[TEST] Hardware topology & NUMA protection...")
	ui.set_compute_mode("CPU")
	assert(ui._slots.size() == 5, "Expected 5 compute slots in terminal")
	for s in ui._slots:
		if s["is_cpu"]:
			assert(s["enabled"] == true, "CPU must be active in CPU mode")
		else:
			assert(s["enabled"] == false, "GPU must be isolated in CPU mode")
	print("  -> [PASS] Safe CPU mode verified.")

	ui.set_compute_mode("GPU")
	for s in ui._slots:
		if s["is_cpu"]:
			assert(s["enabled"] == false, "CPU must be isolated in GPU mode")
		else:
			assert(s["enabled"] == true, "GPU must be active in GPU mode")
	print("  -> [PASS] GPU mode verified.")

	ui.set_compute_mode("ALL")
	for s in ui._slots:
		assert(s["enabled"] == true, "All devices must be active in ALL mode")
	print("  -> [PASS] Hybrid ALL mode verified.")

	# 2. Test Hash Detector
	print("[TEST] Automated Hash Format Detector...")
	ui._edit_detector_input.text = "098f6bcd4621d373cade4e832627b4f6"
	ui._on_detect_hash_pressed()
	assert(ui._detected_mode_id == 0, "Expected MD5 (-m 0) to be detected")
	assert(ui._btn_apply_detected.visible == true, "Apply button must become visible")
	ui._on_apply_detected_pressed()
	print("  -> [PASS] Hash detector successfully recognized MD5 and applied mode.")

	# 3. Test Attack Configuration & CLI builder
	print("[TEST] Attack configuration & CLI argument generator...")
	var args = ui._build_attack_args(false)
	print("  Generated attack args: ", args)
	assert("-m" in args, "Missing -m in args")
	assert("0" in args, "Expected mode 0")
	assert("-a" in args, "Missing -a in args")
	assert("-w" in args, "Missing -w in args")
	print("  -> [PASS] Attack CLI arguments valid.")

	# 4. Test Benchmark Args
	var bench_args = ui._build_attack_args(true)
	print("  Generated bench args: ", bench_args)
	assert("-b" in bench_args, "Expected -b in benchmark args")
	print("  -> [PASS] Benchmark CLI arguments valid.")

	# 5. Test Live Console & Cracked Passwords
	print("[TEST] Live Console & Cracked Passwords...")
	ui.append_console_line("[color=#10b981]Test log streaming line[/color]")
	ui.update_engine_telemetry("142.5 MH/s", "45.2%", "ACTIVE")
	ui.add_cracked_password("098f6bcd4621d373cade4e832627b4f6", "test")
	assert(ui._cracked_count == 1, "Expected cracked count = 1")
	print("  -> [PASS] Console and cracked passwords verified.")

	# 6. Test Flags Guide
	print("[TEST] Flags Guide knowledge base...")
	assert(ui._tree_flags.get_root().get_first_child() != null, "Flags tree should have items")
	ui._selected_flag_str = "--status-timer 1"
	ui._on_add_flag_to_cli()
	var new_cli = ui._lbl_cli_preview.text
	assert("--status-timer 1" in new_cli, "CLI preview should contain added flag")
	print("  -> [PASS] Flags guide 1-click insert verified.")

	print("--- ALL HOLO TERMINAL INTELLIGENCE TESTS PASSED! ---")
	ui.queue_free()
	quit(0)
