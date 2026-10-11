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

	# 3. Screen QuadMesh (2.5m x 1.56m) with Translucent Hologram Material
	screen_mesh = MeshInstance3D.new()
	screen_mesh.name = "ScreenMesh"
	var quad = QuadMesh.new()
	quad.size = Vector2(2.5, 1.56)
	screen_mesh.mesh = quad

	var mat = StandardMaterial3D.new()
	mat.albedo_texture = viewport.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
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
	screen_body.set("is_interaction_enabled", false)

	if screen_body.has_signal("hover_state_changed"):
		screen_body.connect("hover_state_changed", func(is_h: bool):
			is_hovered = is_h
			_update_glow_and_prompt()
		)
	if screen_body.has_signal("panel_clicked_in_free_mode"):
		screen_body.connect("panel_clicked_in_free_mode", func():
			if is_player_in_range or is_hovered:
				terminal_activated.emit()
		)

	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.5, 1.56, 0.08)
	shape.shape = box
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
	var col_shape = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 4.0
	cyl_shape.height = 3.5
	col_shape.shape = cyl_shape
	col_shape.position = Vector3(0.0, 0.0, 0.5)
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

	# 4. Volumetric Hologram Light Cone (Upward Projection Beam)
	var beam = MeshInstance3D.new()
	var cone = CylinderMesh.new()
	cone.bottom_radius = 0.35 # At puck on floor
	cone.top_radius = 1.30 # Expanding upward towards bottom of screen
	cone.height = 1.25
	beam.mesh = cone
	var beam_mat = StandardMaterial3D.new()
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam_mat.albedo_color = Color(0.0, 0.92, 1.0, 0.08)
	beam.material_override = beam_mat
	beam.position = Vector3(0.0, -0.98, 0.22)
	beam.rotation_degrees = Vector3(-18.0, 0.0, 0.0) # Angled from puck directly to screen
	add_child(beam)

	# 5. Upward Floating Sparkle Hologram Particles (CPUParticles3D)
	var particles = CPUParticles3D.new()
	particles.name = "HoloParticles"
	particles.amount = 26
	particles.lifetime = 1.8
	particles.preprocess = 0.5
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	particles.emission_ring_radius = 0.28
	particles.emission_ring_inner_radius = 0.05
	particles.emission_ring_height = 0.05
	particles.direction = Vector3(0.0, 1.0, -0.32).normalized()
	particles.spread = 18.0
	particles.gravity = Vector3(0.0, 0.35, 0.0)
	particles.initial_velocity_min = 0.8
	particles.initial_velocity_max = 1.4
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 0.8
	particles.position = Vector3(0.0, -1.28, 0.45)

	var p_mesh = QuadMesh.new()
	p_mesh.size = Vector2(0.02, 0.02)
	particles.mesh = p_mesh
	var p_mat = StandardMaterial3D.new()
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	p_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	p_mat.albedo_color = Color(0.0, 0.95, 1.0, 0.85)
	particles.material_override = p_mat
	add_child(particles)

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

	# 3. 3D QuadMesh for Aux Screen (0.95m x 1.25m)
	aux_screen_mesh = MeshInstance3D.new()
	aux_screen_mesh.name = "AuxScreenMesh"
	var aux_quad = QuadMesh.new()
	aux_quad.size = Vector2(0.95, 1.25)
	aux_screen_mesh.mesh = aux_quad

	var aux_mat = StandardMaterial3D.new()
	aux_mat.albedo_texture = aux_viewport.get_texture()
	aux_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	aux_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aux_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	aux_screen_mesh.material_override = aux_mat

	# Angled floating position on the right of the main terminal
	aux_screen_mesh.position = Vector3(1.70, -0.05, 0.15)
	aux_screen_mesh.rotation_degrees = Vector3(0.0, -15.0, 0.0)
	add_child(aux_screen_mesh)

	# Glowing neon top and bottom trim on aux screen
	for y_off in [-0.63, 0.63]:
		var a_trim = MeshInstance3D.new()
		var a_box = BoxMesh.new()
		a_box.size = Vector3(0.96, 0.012, 0.015)
		a_trim.mesh = a_box
		a_trim.material_override = neon_mat
		a_trim.position = Vector3(0.0, y_off, 0.0)
		aux_screen_mesh.add_child(a_trim)


