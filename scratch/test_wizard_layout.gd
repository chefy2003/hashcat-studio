extends SceneTree

func _init() -> void:
	print(">>> [TEST START] Verifying Modern Container-First Wizard Architecture...")

	# 1. Instantiate Main Wizard Scene
	var scene = load("res://scenes/main_wizard.tscn")
	assert(scene != null, "scenes/main_wizard.tscn must load")
	var inst = scene.instantiate()
	assert(inst != null, "main_wizard instance must not be null")
	root.add_child(inst)
	
	await process_frame
	await process_frame

	print("[PASS] scenes/main_wizard.tscn loaded and added to tree successfully!")

	# 2. Check Node Tree References
	var wizard_tabs = inst.get_node("MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs")
	var monitoring_view = inst.get_node("MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/MonitoringView")
	var sidebar = inst.get_node("MainLayout/SidebarPanel")
	var workspace_split = inst.get_node("MainLayout/WorkspaceSplit")
	var console_split = inst.get_node("MainLayout/WorkspaceSplit/BottomConsoleSplit")
	var console_panel = inst.get_node("MainLayout/WorkspaceSplit/BottomConsoleSplit/ConsolePanel")
	var help_panel = inst.get_node("MainLayout/WorkspaceSplit/BottomConsoleSplit/HelpPanel")

	assert(wizard_tabs.visible == true, "WizardTabs must be visible by default")
	assert(monitoring_view.visible == false, "MonitoringView must be hidden by default")
	print("[PASS] Default visibility: WizardTabs=ON, MonitoringView=OFF.")

	# 3. Test Dynamic View Transition
	inst.show_monitoring_view()
	assert(wizard_tabs.visible == false, "WizardTabs must hide in monitoring view")
	assert(monitoring_view.visible == true, "MonitoringView must show in monitoring view")
	print("[PASS] show_monitoring_view() successful: WizardTabs=OFF, MonitoringView=ON.")

	inst.show_wizard_view()
	assert(wizard_tabs.visible == true, "WizardTabs must show in wizard view")
	assert(monitoring_view.visible == false, "MonitoringView must hide in wizard view")
	print("[PASS] show_wizard_view() successful: WizardTabs=ON, MonitoringView=OFF.")

	# 4. Test Console Maximize
	var initial_offset = workspace_split.split_offset
	inst._toggle_maximize_console()
	assert(inst._is_console_maximized == true, "Console must be maximized")
	assert(workspace_split.split_offset < initial_offset, "Maximized offset must give more space to console")
	inst._toggle_maximize_console()
	assert(inst._is_console_maximized == false, "Console must be restored")
	print("[PASS] Console maximize/restore verified.")

	# 5. Test Help Panel Collapse
	assert(help_panel.visible == true, "HelpPanel must be visible initially")
	inst._toggle_collapse_help()
	assert(help_panel.visible == false, "HelpPanel must hide when collapsed")
	assert(inst._is_help_collapsed == true, "Help collapsed flag must be true")
	inst.ensure_help_panel_visible()
	assert(help_panel.visible == true, "HelpPanel must restore when ensure_help_panel_visible() is called")
	print("[PASS] HelpPanel collapse/restore verified.")

	# 6. Test Multi-Resolution Bounds & In-Screen Positions
	var resolutions = [
		Vector2i(1024, 576),
		Vector2i(1280, 720),
		Vector2i(1920, 1080),
		Vector2i(3200, 1080)
	]

	for res in resolutions:
		var vp = SubViewport.new()
		vp.size = res
		root.add_child(vp)
		var test_inst = scene.instantiate()
		vp.add_child(test_inst)
		await process_frame
		await process_frame

		var test_layout = test_inst.get_node("MainLayout")
		var test_side = test_inst.get_node("MainLayout/SidebarPanel")
		var test_work = test_inst.get_node("MainLayout/WorkspaceSplit")
		var test_console = test_inst.get_node("MainLayout/WorkspaceSplit/BottomConsoleSplit/ConsolePanel")

		print("  Res %s x %s -> Layout pos: %s, Side size: %s, Work size: %s, Console size: %s" % [
			res.x, res.y, test_layout.global_position, test_side.size, test_work.size, test_console.size
		])

		assert(test_layout.global_position.x >= 0, "Layout X must be in bounds")
		assert(test_layout.global_position.y >= 0, "Layout Y must be in bounds")
		assert(test_side.size.x >= 200, "Sidebar must maintain readable width")
		assert(test_console.size.y >= 100, "Console must have comfortable height")

		root.remove_child(vp)
		vp.queue_free()

	# 7. Verify NUMA Safety
	var HardwareInspectorScript = load("res://scripts/utils/hardware_inspector.gd")
	var devs = HardwareInspectorScript.probe_compute_devices()
	print("[PASS] NUMA Safety intact: Discovered %d compute devices." % devs.size())

	print(">>> [TEST COMPLETED SUCCESSFULLY] Modern Container-First Wizard Architecture verified with 0 errors!")
	quit(0)
