extends SceneTree

const DashboardCamera3DScript = preload("res://scripts/ui/3d/dashboard_camera_3d.gd")

func _init() -> void:
	change_scene_to_file("res://scenes/dashboard_3d.tscn")
	_capture_views()

func _capture_views() -> void:
	# Wait for rendering pipeline and shaders to compile
	for i in range(25):
		await process_frame

	var win = root
	var scene = win.get_child(win.get_child_count() - 1)
	var cam = scene.find_child("Camera3D", true, false)
	var vis = scene.find_child("HashrateVisualizer3D", true, false)
	var rack = scene.find_child("ServerRack3D", true, false)

	# Feed rich hashrate samples into 3D visualizer
	for v in [18.0, 32.0, 55.0, 78.0, 120.0, 95.0, 142.0, 110.0, 130.0]:
		vis.add_sample(v)
		for f in range(2):
			await process_frame

	# 1. Capture Operator Front View
	for i in range(10):
		await process_frame
	var img1 = win.get_texture().get_image()
	img1.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_ops_deck.png")
	print("Saved verify_3d_ops_deck.png")

	# 2. Switch to 3D Server Rack view
	cam.switch_preset(DashboardCamera3DScript.ViewPreset.RACK_TELEMETRY, 0.0)
	for i in range(15):
		await process_frame
	var img2 = win.get_texture().get_image()
	img2.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_rack_telemetry.png")
	print("Saved verify_3d_rack_telemetry.png")

	# 3. Switch to 3D Hashrate Waveform view
	cam.switch_preset(DashboardCamera3DScript.ViewPreset.HASHRATE_WAVE, 0.0)
	for i in range(15):
		await process_frame
	var img3 = win.get_texture().get_image()
	img3.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_hashrate_mesh.png")
	print("Saved verify_3d_hashrate_mesh.png")

	# 4. Switch to Wide Cockpit View
	cam.switch_preset(DashboardCamera3DScript.ViewPreset.WIDE_OVERVIEW, 0.0)
	for i in range(15):
		await process_frame
	var img4 = win.get_texture().get_image()
	img4.save_png("/home/deliriumxs/.gemini/antigravity/brain/badeab8c-b4e7-4a09-ac7b-8b0b445992d6/verify_3d_wide_cockpit.png")
	print("Saved verify_3d_wide_cockpit.png")

	quit(0)
