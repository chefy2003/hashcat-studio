class_name HoloTerminal3D
extends Node3D

## In-World 3D Holographic Operations Terminal.
## Hosts the 2D HoloTerminalUI inside an interactive SubViewport,
## mapped to a 3D QuadMesh with Gui3DPanel mouse raycast collision forwarding.

signal device_toggled(dev_id: int, enabled: bool)
signal compute_mode_selected(mode: String)
signal request_exit_2d()
signal terminal_activated()
signal request_deactivate_focus()
signal request_toggle_fullscreen(is_fullscreen: bool)
signal attack_requested(args: Array)
signal benchmark_requested()
signal stop_requested()
signal file_selected(file_type: String, file_path: String)

const HoloTerminalUIScript = preload("res://scripts/ui/3d/holo_terminal_ui.gd")
const Gui3DPanelScript = preload("res://scripts/ui/3d/gui_3d_panel.gd")

var viewport: SubViewport
var terminal_ui: Control
var screen_mesh: MeshInstance3D
var screen_body: StaticBody3D

var aux_viewport: SubViewport
var aux_screen_mesh: MeshInstance3D
var _aux_console_log: RichTextLabel
var _aux_status_lbl: Label
var _aux_speed_lbl: Label
var _aux_cracked_lbl: Label

var is_player_in_range: bool = false
var is_hovered: bool = false
var is_focused: bool = false

var _lbl_interaction_prompt: Label3D
var _neon_mat: StandardMaterial3D
var _interaction_zone: Area3D

func _ready() -> void:
	_build_terminal()

func _process(_delta: float) -> void:
	if (is_player_in_range or is_hovered) and not is_focused:
		if _neon_mat:
			var pulse = (sin(Time.get_ticks_msec() * 0.007) * 0.5 + 0.5) * 1.5 + 1.6
			_neon_mat.emission_energy_multiplier = pulse
	elif is_focused:
		if _neon_mat:
			_neon_mat.emission_energy_multiplier = 2.2
	else:
		if _neon_mat:
			_neon_mat.emission_energy_multiplier = 1.6

func set_focused(focused: bool) -> void:
	is_focused = focused
	if screen_body:
		screen_body.set("is_interaction_enabled", focused)
	if not focused and terminal_ui and terminal_ui.has_method("reset_fullscreen_toggle"):
		terminal_ui.reset_fullscreen_toggle()
	_update_glow_and_prompt()

func set_player_in_range(in_range: bool) -> void:
	if is_player_in_range != in_range:
		is_player_in_range = in_range
		_update_glow_and_prompt()

func _update_glow_and_prompt() -> void:
	var should_show = (is_player_in_range or is_hovered) and not is_focused
	if _lbl_interaction_prompt:
		_lbl_interaction_prompt.visible = should_show

func sync_device_state(dev_id: int, enabled: bool) -> void:
	if terminal_ui:
		terminal_ui.sync_device_state(dev_id, enabled)

func update_device_metrics(dev_id: int, temp: float, fan: float, util: float) -> void:
	if terminal_ui:
		terminal_ui.update_device_metrics(dev_id, temp, fan, util)

func append_console_line(line: String) -> void:
	if terminal_ui and terminal_ui.has_method("append_console_line"):
		terminal_ui.append_console_line(line)
	if _aux_console_log:
		_aux_console_log.append_text(line + "\n")

func update_engine_telemetry(speed_str: String, progress_str: String, status_str: String) -> void:
	if terminal_ui and terminal_ui.has_method("update_engine_telemetry"):
		terminal_ui.update_engine_telemetry(speed_str, progress_str, status_str)
	if _aux_status_lbl and status_str != "":
		_aux_status_lbl.text = "РЕЖИМ: " + status_str
	if _aux_speed_lbl and speed_str != "":
		_aux_speed_lbl.text = "СКОРОСТ: " + speed_str + (" (" + progress_str + ")" if progress_str != "" else "")

func add_cracked_password(hash_val: String, plain_val: String) -> void:
	if terminal_ui and terminal_ui.has_method("add_cracked_password"):
		terminal_ui.add_cracked_password(hash_val, plain_val)
	if _aux_cracked_lbl:
		_aux_cracked_lbl.text = "РАЗБИТИ: " + plain_val

func set_active_tab(idx: int) -> void:
	if terminal_ui and terminal_ui.has_method("set_active_tab"):
		terminal_ui.set_active_tab(idx)

func set_engine_running(running: bool) -> void:
	if terminal_ui and terminal_ui.has_method("set_engine_running"):
		terminal_ui.set_engine_running(running)
	if _aux_status_lbl:
		_aux_status_lbl.text = "РЕЖИМ: " + ("АКТИВЕН (RUNNING)" if running else "ГОТОВ (STANDBY)")
		_aux_status_lbl.add_theme_color_override("font_color", Color("#00f0ff") if running else Color("#10b981"))

func _build_terminal() -> void:
	# 1. 2D SubViewport (Transparent Background for Hologram Glassmorphism)
	viewport = SubViewport.new()
	viewport.name = "SubViewport"
	viewport.size = Vector2i(1280, 800)
	viewport.transparent_bg = true
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
		request_deactivate_focus.emit()
		request_exit_2d.emit()
	)
	if terminal_ui.has_signal("request_deactivate_terminal"):
		terminal_ui.connect("request_deactivate_terminal", func():
			request_deactivate_focus.emit()
		)
	if terminal_ui.has_signal("request_toggle_fullscreen"):
		terminal_ui.connect("request_toggle_fullscreen", func(is_full: bool):
			request_toggle_fullscreen.emit(is_full)
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
	if terminal_ui.has_signal("file_selected"):
		terminal_ui.connect("file_selected", func(ftype: String, fpath: String):
			file_selected.emit(ftype, fpath)
		)

	if terminal_ui.get("_cyber_explorer") != null:
		var explorer = terminal_ui._cyber_explorer as Control
		explorer.visibility_changed.connect(func():
			if explorer.visible:
				terminal_activated.emit()
		)

	# 3. Screen QuadMesh (2.5m x 1.56m) with Translucent Hologram Material
	screen_mesh = MeshInstance3D.new()
	screen_mesh.name = "ScreenMesh"
	var quad = QuadMesh.new()
	quad.size = Vector2(2.5, 1.56)
	screen_mesh.mesh = quad

	var holo_shader = preload("res://shaders/holo_diegetic_display.gdshader")
	var mat = ShaderMaterial.new()
	mat.shader = holo_shader
	mat.set_shader_parameter("terminal_texture", viewport.get_texture())
	mat.set_shader_parameter("border_color", Color("#00f0ff"))
	mat.set_shader_parameter("border_thickness", 0.003)
	mat.set_shader_parameter("brightness_boost", 1.15)
	screen_mesh.material_override = mat
	add_child(screen_mesh)

	# Tactile physical dark anodized chassis backplate
	var chassis_back = MeshInstance3D.new()
	chassis_back.name = "ChassisBackplate"
	var chassis_box = BoxMesh.new()
	chassis_box.size = Vector3(2.55, 1.61, 0.04)
	chassis_back.mesh = chassis_box
	chassis_back.position = Vector3(0.0, 0.0, -0.025)
	var chassis_mat = StandardMaterial3D.new()
	chassis_mat.albedo_color = Color("#090e18")
	chassis_mat.metallic = 0.92
	chassis_mat.roughness = 0.28
	chassis_back.material_override = chassis_mat
	screen_mesh.add_child(chassis_back)

	# 4. Interactive ScreenBody with Gui3DPanel raycast transfer
	screen_body = StaticBody3D.new()
	screen_body.name = "ScreenBody"
	screen_body.collision_layer = 1 # UI_Panels
	screen_body.collision_mask = 1
	screen_body.set_script(Gui3DPanelScript)
	screen_body.set("target_viewport", viewport)
	screen_body.set("mesh_instance", screen_mesh)
	screen_body.set("is_interaction_enabled", false)

	if screen_body.has_signal("hover_state_changed"):
		screen_body.connect("hover_state_changed", func(is_h: bool):
			is_hovered = is_h
			_update_glow_and_prompt()
		)
	if screen_body.has_signal("panel_clicked_in_free_mode"):
		screen_body.connect("panel_clicked_in_free_mode", func():
			terminal_activated.emit()
		)


	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.5, 1.56, 0.004)
	shape.shape = box
	shape.position = Vector3(0.0, 0.0, 0.002)
	screen_body.add_child(shape)
	screen_mesh.add_child(screen_body)

	# 5. Floating Interaction Prompt Badge [E] ВЛЕЗ В ТЕРМИНАЛА
	_lbl_interaction_prompt = Label3D.new()
	_lbl_interaction_prompt.text = "[E] ВЛЕЗ В ТЕРМИНАЛА"
	_lbl_interaction_prompt.font_size = 28
	_lbl_interaction_prompt.modulate = Color("#00f0ff")
	_lbl_interaction_prompt.outline_modulate = Color("#020617")
	_lbl_interaction_prompt.outline_size = 6
	_lbl_interaction_prompt.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_lbl_interaction_prompt.position = Vector3(0.0, 0.94, 0.05)
	_lbl_interaction_prompt.visible = false
	add_child(_lbl_interaction_prompt)

	# 6. Interaction Zone (Area3D)
	_interaction_zone = Area3D.new()
	_interaction_zone.name = "InteractionZone"
	_interaction_zone.input_ray_pickable = false
	_interaction_zone.collision_layer = 0
	_interaction_zone.collision_mask = 1
	var col_shape = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 2.4
	cyl_shape.height = 2.0
	col_shape.shape = cyl_shape
	col_shape.position = Vector3(0.0, 0.0, 0.3)
	_interaction_zone.add_child(col_shape)
	_interaction_zone.body_entered.connect(func(_b): set_player_in_range(true))
	_interaction_zone.body_exited.connect(func(_b): set_player_in_range(false))
	_interaction_zone.area_entered.connect(func(_a): set_player_in_range(true))
	_interaction_zone.area_exited.connect(func(_a): set_player_in_range(false))
	add_child(_interaction_zone)

	# 7. Hologram Projector Base Puck, Light Cone, Particles & Auxiliary Screen
	_build_hologram_projector_and_frame()

func _build_hologram_projector_and_frame() -> void:
	_neon_mat = StandardMaterial3D.new()
	_neon_mat.albedo_color = Color("#00f0ff")
	_neon_mat.emission_enabled = true
	_neon_mat.emission = Color("#00f0ff")
	_neon_mat.emission_energy_multiplier = 1.6
	var neon_mat = _neon_mat

	var dark_metal_mat = StandardMaterial3D.new()
	dark_metal_mat.albedo_color = Color("#0c1524")
	dark_metal_mat.metallic = 0.92
	dark_metal_mat.roughness = 0.25

	# 1. Main Screen Glowing Neon Edge Bars (No solid backplate!)
	for y_off in [-0.78, 0.78]:
		var h_trim = MeshInstance3D.new()
		var h_box = BoxMesh.new()
		h_box.size = Vector3(2.52, 0.015, 0.02)
		h_trim.mesh = h_box
		h_trim.material_override = neon_mat
		h_trim.position = Vector3(0.0, y_off, 0.0)
		screen_mesh.add_child(h_trim)

	for x_off in [-1.25, 1.25]:
		var v_trim = MeshInstance3D.new()
		var v_box = BoxMesh.new()
		v_box.size = Vector3(0.015, 1.56, 0.02)
		v_trim.mesh = v_box
		v_trim.material_override = neon_mat
		v_trim.position = Vector3(x_off, 0.0, 0.0)
		screen_mesh.add_child(v_trim)

	# 2. Glowing Holographic Corner Accents (L-brackets)
	for cx in [-1.22, 1.22]:
		for cy in [-0.75, 0.75]:
			var bracket = MeshInstance3D.new()
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(0.08, 0.08, 0.025)
			bracket.mesh = b_mesh
			bracket.material_override = neon_mat
			bracket.position = Vector3(cx, cy, 0.005)
			screen_mesh.add_child(bracket)

	# 3. Floor Hologram Projector Puck (Resting on floor Y = -1.33)
	var puck_root = Node3D.new()
	puck_root.name = "ProjectorPuck"
	puck_root.position = Vector3(0.0, -1.33, 0.45) # Centered on floor, shifted forward towards operator
	add_child(puck_root)

	# Dark cyber metallic outer puck ring
	var puck_base = MeshInstance3D.new()
	var base_cyl = CylinderMesh.new()
	base_cyl.top_radius = 0.42
	base_cyl.bottom_radius = 0.48
	base_cyl.height = 0.05
	puck_base.mesh = base_cyl
	puck_base.material_override = dark_metal_mat
	puck_base.position.y = 0.025
	puck_root.add_child(puck_base)

	# Physical solid collision body for Projector Puck
	var puck_body = StaticBody3D.new()
	puck_body.name = "PuckStaticBody"
	var col_shape = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 0.52
	cyl_shape.height = 0.4
	col_shape.shape = cyl_shape
	col_shape.position = Vector3(0.0, 0.2, 0.0)
	puck_body.add_child(col_shape)
	puck_root.add_child(puck_body)

	# Glowing inner projector emitter lens
	var puck_core = MeshInstance3D.new()
	var core_cyl = CylinderMesh.new()
	core_cyl.top_radius = 0.35
	core_cyl.bottom_radius = 0.35
	core_cyl.height = 0.06
	puck_core.mesh = core_cyl
	var emitter_mat = StandardMaterial3D.new()
	emitter_mat.albedo_color = Color("#00f0ff")
	emitter_mat.emission_enabled = true
	emitter_mat.emission = Color("#00f0ff")
	emitter_mat.emission_energy_multiplier = 2.4
	puck_core.material_override = emitter_mat
	puck_core.position.y = 0.03
	puck_root.add_child(puck_core)

	# Glowing outer rim ring
	var puck_ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.36
	torus.outer_radius = 0.40
	puck_ring.mesh = torus
	puck_ring.material_override = neon_mat
	puck_ring.position.y = 0.055
	puck_root.add_child(puck_ring)

	# 4. Heavy Dark Anodized Articulating Console Mount Arm
	var mount_arm = MeshInstance3D.new()
	mount_arm.name = "TerminalMountArm"
	var arm_cyl = CylinderMesh.new()
	arm_cyl.top_radius = 0.08
	arm_cyl.bottom_radius = 0.14
	arm_cyl.height = 1.35
	mount_arm.mesh = arm_cyl
	mount_arm.material_override = dark_metal_mat
	mount_arm.position = Vector3(0.0, -0.92, -0.06)
	mount_arm.rotation_degrees = Vector3(-10.0, 0.0, 0.0) # Anchored securely into rear chassis backplate
	add_child(mount_arm)

	# 6. Secondary Auxiliary Hologram Screen on the Right (Concept Art Companion)
	_build_auxiliary_screen(neon_mat)

func _build_auxiliary_screen(neon_mat: StandardMaterial3D) -> void:
	# 1. SubViewport for Aux Display (512x680)
	aux_viewport = SubViewport.new()
	aux_viewport.name = "AuxSubViewport"
	aux_viewport.size = Vector2i(512, 680)
	aux_viewport.transparent_bg = true
	aux_viewport.disable_3d = true
	aux_viewport.gui_embed_subwindows = true
	aux_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(aux_viewport)

	# 2. UI Container
	var aux_root = PanelContainer.new()
	aux_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var aux_sb = StyleBoxFlat.new()
	aux_sb.bg_color = Color(0.02, 0.045, 0.09, 0.65)
	aux_sb.border_width_left = 2
	aux_sb.border_width_top = 2
	aux_sb.border_width_right = 2
	aux_sb.border_width_bottom = 2
	aux_sb.border_color = Color("#00f0ff")
	aux_sb.set_corner_radius_all(8)
	aux_sb.content_margin_left = 12
	aux_sb.content_margin_top = 10
	aux_sb.content_margin_right = 12
	aux_sb.content_margin_bottom = 10
	aux_root.add_theme_stylebox_override("panel", aux_sb)
	aux_viewport.add_child(aux_root)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	aux_root.add_child(vbox)

	# Header
	var lbl_h = Label.new()
	lbl_h.text = "❖ СИСТЕМЕН МОНИТОРИНГ & ЛОГ"
	lbl_h.add_theme_color_override("font_color", Color("#00f0ff"))
	lbl_h.add_theme_font_size_override("font_size", 14)
	vbox.add_child(lbl_h)

	# Status row
	_aux_status_lbl = Label.new()
	_aux_status_lbl.text = "РЕЖИМ: ГОТОВ (STANDBY)"
	_aux_status_lbl.add_theme_color_override("font_color", Color("#10b981"))
	_aux_status_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_aux_status_lbl)

	_aux_speed_lbl = Label.new()
	_aux_speed_lbl.text = "СКОРОСТ: 0 H/s  •  ПРОГРЕС: 0%"
	_aux_speed_lbl.add_theme_color_override("font_color", Color("#38bdf8"))
	_aux_speed_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_aux_speed_lbl)

	_aux_cracked_lbl = Label.new()
	_aux_cracked_lbl.text = "РАЗБИТИ ПАРОЛИ: 0"
	_aux_cracked_lbl.add_theme_color_override("font_color", Color("#f59e0b"))
	_aux_cracked_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(_aux_cracked_lbl)

	# Hardware details box
	var hw_lbl = Label.new()
	hw_lbl.text = "ХАРДУЕР: 4x AMD Radeon (HIP) + Intel Xeon (OpenCL)"
	hw_lbl.add_theme_color_override("font_color", Color("#94a3b8"))
	hw_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hw_lbl)

	# Live Log Output
	_aux_console_log = RichTextLabel.new()
	_aux_console_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_aux_console_log.scroll_following = true
	_aux_console_log.bbcode_enabled = true
	_aux_console_log.text = "[color=#00f0ff]>>> QUANTUM TELEMETRY STREAM CONNECTED[/color]\n[color=#64748b][*] All 5 compute nodes synchronized.[/color]\n"
	vbox.add_child(_aux_console_log)

	# 3. 3D QuadMesh for Aux Screen (0.85m x 1.40m curved cockpit companion)
	aux_screen_mesh = MeshInstance3D.new()
	aux_screen_mesh.name = "AuxScreenMesh"
	var aux_quad = QuadMesh.new()
	aux_quad.size = Vector2(0.85, 1.40)
	aux_screen_mesh.mesh = aux_quad

	var holo_shader = preload("res://shaders/holo_diegetic_display.gdshader")
	var aux_mat = ShaderMaterial.new()
	aux_mat.shader = holo_shader
	aux_mat.set_shader_parameter("terminal_texture", aux_viewport.get_texture())
	aux_mat.set_shader_parameter("border_color", Color("#00f0ff"))
	aux_mat.set_shader_parameter("border_thickness", 0.003)
	aux_mat.set_shader_parameter("brightness_boost", 1.15)
	aux_screen_mesh.material_override = aux_mat

	# Aux Screen Dark Metallic Chassis Backplate
	var aux_chassis = MeshInstance3D.new()
	aux_chassis.name = "AuxChassisBackplate"
	var aux_box = BoxMesh.new()
	aux_box.size = Vector3(0.88, 1.43, 0.03)
	aux_chassis.mesh = aux_box
	aux_chassis.position = Vector3(0.0, 0.0, -0.02)
	var chassis_mat = StandardMaterial3D.new()
	chassis_mat.albedo_color = Color("#090e18")
	chassis_mat.metallic = 0.92
	chassis_mat.roughness = 0.28
	aux_chassis.material_override = chassis_mat
	aux_screen_mesh.add_child(aux_chassis)

	# Ergonomically curved wrap-around cockpit position on the right of the main terminal
	aux_screen_mesh.position = Vector3(1.60, 0.0, 0.26)
	aux_screen_mesh.rotation_degrees = Vector3(0.0, -36.0, 0.0)
	add_child(aux_screen_mesh)

	# Glowing neon top and bottom trim on aux screen
	for y_off in [-0.70, 0.70]:
		var a_trim = MeshInstance3D.new()
		var a_box = BoxMesh.new()
		a_box.size = Vector3(0.86, 0.012, 0.015)
		a_trim.mesh = a_box
		a_trim.material_override = neon_mat
		a_trim.position = Vector3(0.0, y_off, 0.0)
		aux_screen_mesh.add_child(a_trim)


