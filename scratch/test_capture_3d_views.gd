extends SceneTree

const DashboardCamera3DScript = preload("res://scripts/ui/3d/dashboard_camera_3d.gd")

func _init() -> void:
	change_scene_to_file("res://scenes/dashboard_3d.tscn")
	_capture_views()

func _capture_views() -> void:
	for i in range(25):
		await process_frame

	var win = root
	var scene = win.get_child(win.get_child_count() - 1)
	var cam = scene.find_child("Camera3D", true, false)
	var vis = scene.find_child("HashrateVisualizer3D", true, false)
	var core_node = scene.find_child("HoloCore3D", true, false)
	var term_node = scene.find_child("HoloTerminal3D", true, false)

	# Feed throughput samples into the wave
	for v in [50.0, 95.0, 160.0, 220.0, 280.0, 310.0, 350.0]:
		vis.add_sample(v)
		for f in range(5):
			await process_frame
	for f in range(35):
		await process_frame

	# Simulate active telemetry on terminal and quantum core
	if term_node:
		term_node.update_engine_telemetry("312.4 MH/s", "68%", "ACTIVE")
		term_node.append_console_line("[color=#00f0ff]>>> GPU CLUSTERS 1-4 SATURATED AT 99%[/color]")
		term_node.append_console_line("[color=#ff0055][*] Quantum core thermal overclocking engaged.[/color]")

	if core_node:
		core_node.set_core_telemetry(312.4, "ACTIVE // OVERCLOCK")
		# Heat up the core for dramatic ruby glow
		core_node.heat_level = 0.95

	# 1. Capture Operator Front View (Harmonious layout, mini-holo core, conduits, thermal wave)
	cam.switch_preset(DashboardCamera3DScript.ViewPreset.OPERATOR_FRONT, 0.0)
	for i in range(20):
		await process_frame
	var img1 = win.get_texture().get_image()
	img1.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_ops_deck.png")
	print("Saved verify_3d_ops_deck.png")

	# 2. Capture Quantum Core Close-up (Ruby Red Overclock + Mini Holographic Display + Energy Conduits)
	cam.global_position = Vector3(0.0, 1.25, 2.7)
	cam.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
	for i in range(16):
		await process_frame
	var img_core = win.get_texture().get_image()
	img_core.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_core_overclock.png")
	print("Saved verify_3d_core_overclock.png")

	# 3. Capture Thermal Multi-Color Wave (Blue base -> Yellow mid -> Ruby Red peak)
	cam.global_position = Vector3(1.4, 1.20, -1.5)
	cam.rotation_degrees = Vector3(-4.0, -32.0, 0.0)
	for i in range(16):
		await process_frame
	var img_wave = win.get_texture().get_image()
	img_wave.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_thermal_wave.png")
	print("Saved verify_3d_thermal_wave.png")

	# 4. Capture First-Person Terminal Focus (~30% realistic approach, centered)
	cam.enter_terminal_focus(0.0)
	if term_node:
		term_node.set_focused(true)
		term_node.set_active_tab(0)
	for i in range(16):
		await process_frame
	var img_term = win.get_texture().get_image()
	img_term.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_holo_terminal.png")
	print("Saved verify_3d_holo_terminal.png")

	# 5. Capture Wide Panoramic Cockpit Architecture (Bulkheads, Conduits, Arena)
	cam.exit_terminal_focus(0.0)
	if term_node:
		term_node.set_focused(false)
	cam.switch_preset(DashboardCamera3DScript.ViewPreset.WIDE_OVERVIEW, 0.0)
	for i in range(16):
		await process_frame
	var img_wide = win.get_texture().get_image()
	img_wide.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_wide_cockpit.png")
	print("Saved verify_3d_wide_cockpit.png")

	quit(0)
