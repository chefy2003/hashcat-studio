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

	for v in [35.0, 68.0, 115.0, 160.0, 240.0, 210.0, 285.0, 260.0, 310.0]:
		vis.add_sample(v)
		for f in range(2):
			await process_frame

	var term_node = scene.find_child("HoloTerminal3D", true, false)
	if term_node:
		term_node.update_engine_telemetry("284.5 MH/s", "42%", "ACTIVE")
		term_node.append_console_line("[color=#00f0ff]>>> GPU CLUSTERS 1-4 SATURATED AT 98%[/color]")
		term_node.append_console_line("[color=#10b981][*] Pipeline throughput optimal.[/color]")

	# 1. Capture Operator Front View (Distance x2, Clean 3D arena, Wave completely separated)
	for i in range(16):
		await process_frame
	var img1 = win.get_texture().get_image()
	img1.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_ops_deck.png")
	print("Saved verify_3d_ops_deck.png")

	# 2. Capture Proximity Hover & Interaction Prompt [E] ВЛЕЗ В ТЕРМИНАЛА
	cam.global_position = Vector3(4.0, 1.4, -0.45)
	cam.rotation_degrees = Vector3(-4.0, -78.5, 0.0)
	for i in range(15):
		await process_frame
	var img_hover = win.get_texture().get_image()
	img_hover.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_terminal_hover.png")
	print("Saved verify_3d_terminal_hover.png")

	# 3. Enter First-Person Terminal Focus (~30% realistic zoom, centered, locked controls)
	cam.enter_terminal_focus(0.0)
	if term_node:
		term_node.set_focused(true)
		term_node.set_active_tab(0)
	for i in range(15):
		await process_frame
	var img3 = win.get_texture().get_image()
	img3.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_holo_terminal.png")
	print("Saved verify_3d_holo_terminal.png")

	# 3b. Switch to Terminal Fullscreen Mode (Operator toggle)
	cam.set_terminal_fullscreen(true, 0.0)
	for i in range(15):
		await process_frame
	var img_full = win.get_texture().get_image()
	img_full.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_terminal_fullscreen.png")
	print("Saved verify_3d_terminal_fullscreen.png")

	# 3c. Switch back to First-Person and open Tab 1: Console
	cam.set_terminal_fullscreen(false, 0.0)
	if term_node:
		term_node.set_active_tab(1)
	for i in range(15):
		await process_frame
	var img3b = win.get_texture().get_image()
	img3b.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_terminal_console.png")
	print("Saved verify_3d_terminal_console.png")

	# 4. Deactivate focus and Switch to Wide Panoramic Cockpit View
	cam.exit_terminal_focus(0.0)
	if term_node:
		term_node.set_focused(false)
	cam.switch_preset(DashboardCamera3DScript.ViewPreset.WIDE_OVERVIEW, 0.0)
	for i in range(15):
		await process_frame
	var img4 = win.get_texture().get_image()
	img4.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_wide_cockpit.png")
	print("Saved verify_3d_wide_cockpit.png")

	quit(0)
