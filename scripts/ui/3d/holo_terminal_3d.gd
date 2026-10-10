class_name HoloTerminal3D
extends Node3D

## In-World 3D Holographic Operations Terminal.
## Hosts the 2D HoloTerminalUI inside an interactive SubViewport,
## mapped to a 3D QuadMesh with Gui3DPanel mouse raycast collision forwarding.

signal device_toggled(dev_id: int, enabled: bool)
signal compute_mode_selected(mode: String)
signal request_exit_2d()
signal attack_requested(args: Array)
signal benchmark_requested()
signal stop_requested()

const HoloTerminalUIScript = preload("res://scripts/ui/3d/holo_terminal_ui.gd")
const Gui3DPanelScript = preload("res://scripts/ui/3d/gui_3d_panel.gd")

var viewport: SubViewport
var terminal_ui: Control
var screen_mesh: MeshInstance3D
var screen_body: StaticBody3D

func _ready() -> void:
	_build_terminal()

func sync_device_state(dev_id: int, enabled: bool) -> void:
	if terminal_ui:
		terminal_ui.sync_device_state(dev_id, enabled)

func update_device_metrics(dev_id: int, temp: float, fan: float, util: float) -> void:
	if terminal_ui:
		terminal_ui.update_device_metrics(dev_id, temp, fan, util)

func append_console_line(line: String) -> void:
	if terminal_ui and terminal_ui.has_method("append_console_line"):
		terminal_ui.append_console_line(line)

func update_engine_telemetry(speed_str: String, progress_str: String, status_str: String) -> void:
	if terminal_ui and terminal_ui.has_method("update_engine_telemetry"):
		terminal_ui.update_engine_telemetry(speed_str, progress_str, status_str)

func add_cracked_password(hash_val: String, plain_val: String) -> void:
	if terminal_ui and terminal_ui.has_method("add_cracked_password"):
		terminal_ui.add_cracked_password(hash_val, plain_val)

func set_active_tab(idx: int) -> void:
	if terminal_ui and terminal_ui.has_method("set_active_tab"):
		terminal_ui.set_active_tab(idx)

func set_engine_running(running: bool) -> void:
	if terminal_ui and terminal_ui.has_method("set_engine_running"):
		terminal_ui.set_engine_running(running)

func _build_terminal() -> void:
	# 1. 2D SubViewport
	viewport = SubViewport.new()
	viewport.name = "SubViewport"
	viewport.size = Vector2i(1280, 800)
	viewport.disable_3d = true
	viewport.gui_embed_subwindows = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

	# 2. Terminal UI inside Viewport
	terminal_ui = HoloTerminalUIScript.new()
	viewport.add_child(terminal_ui)

	terminal_ui.device_toggled_in_terminal.connect(func(dev_id: int, enabled: bool):
		device_toggled.emit(dev_id, enabled)
	)
	terminal_ui.compute_mode_selected.connect(func(mode: String):
		compute_mode_selected.emit(mode)
	)
	terminal_ui.request_exit_to_2d.connect(func():
		request_exit_2d.emit()
	)
	if terminal_ui.has_signal("attack_requested"):
		terminal_ui.connect("attack_requested", func(args: Array):
			attack_requested.emit(args)
		)
	if terminal_ui.has_signal("benchmark_requested"):
		terminal_ui.connect("benchmark_requested", func():
			benchmark_requested.emit()
		)
	if terminal_ui.has_signal("stop_requested"):
		terminal_ui.connect("stop_requested", func():
			stop_requested.emit()
		)

	# 3. Screen QuadMesh (2.5m x 1.56m)
	screen_mesh = MeshInstance3D.new()
	screen_mesh.name = "ScreenMesh"
	var quad = QuadMesh.new()
	quad.size = Vector2(2.5, 1.56)
	screen_mesh.mesh = quad

	var mat = StandardMaterial3D.new()
	mat.albedo_texture = viewport.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	screen_mesh.material_override = mat
	add_child(screen_mesh)

	# 4. Interactive ScreenBody with Gui3DPanel raycast transfer
	screen_body = StaticBody3D.new()
	screen_body.name = "ScreenBody"
	screen_body.collision_layer = 1 # UI_Panels
	screen_body.collision_mask = 1
	screen_body.set_script(Gui3DPanelScript)
	screen_body.set("target_viewport", viewport)
	screen_body.set("mesh_instance", screen_mesh)

	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.5, 1.56, 0.08)
	shape.shape = box
	screen_body.add_child(shape)
	screen_mesh.add_child(screen_body)

	# 5. Cyber Frame & Stand Pedestal
	_build_frame_and_stand()

func _build_frame_and_stand() -> void:
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color("#111827")
	frame_mat.metallic = 0.85
	frame_mat.roughness = 0.3

	var neon_mat = StandardMaterial3D.new()
	neon_mat.albedo_color = Color("#00f0ff")
	neon_mat.emission_enabled = true
	neon_mat.emission = Color("#00f0ff")
	neon_mat.emission_energy_multiplier = 1.4

	# Outer border bezel - placed at Z = -0.025 (strictly behind screen front face at Z = 0)
	var bezel = MeshInstance3D.new()
	var bezel_box = BoxMesh.new()
	bezel_box.size = Vector3(2.56, 1.62, 0.04)
	bezel.mesh = bezel_box
	bezel.material_override = frame_mat
	bezel.position.z = -0.025
	screen_mesh.add_child(bezel)

	# Glowing neon top and bottom trim
	for y_offset in [-0.79, 0.79]:
		var trim = MeshInstance3D.new()
		var trim_box = BoxMesh.new()
		trim_box.size = Vector3(2.56, 0.02, 0.05)
		trim.mesh = trim_box
		trim.material_override = neon_mat
		trim.position = Vector3(0.0, y_offset, -0.02)
		screen_mesh.add_child(trim)

	# Vertical Pedestal Column down to floor (from bottom bezel at Y = -0.80 down to floor at Y = -1.35)
	# Height = 0.55m, centered at Y = -1.075, Z = -0.08 (never overlaps front screen)
	var column = MeshInstance3D.new()
	var col_cyl = CylinderMesh.new()
	col_cyl.top_radius = 0.07
	col_cyl.bottom_radius = 0.10
	col_cyl.height = 0.55
	column.mesh = col_cyl
	column.material_override = frame_mat
	column.position = Vector3(0.0, -1.075, -0.08)
	screen_mesh.add_child(column)

	# Floor Pedestal Base Plate resting on the floor (Y = -1.33)
	var base = MeshInstance3D.new()
	var base_cyl = CylinderMesh.new()
	base_cyl.top_radius = 0.38
	base_cyl.bottom_radius = 0.48
	base_cyl.height = 0.06
	base.mesh = base_cyl
	base.material_override = frame_mat
	base.position = Vector3(0.0, -1.33, -0.08)
	screen_mesh.add_child(base)

