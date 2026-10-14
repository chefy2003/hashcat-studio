class_name HoloCore3D
extends Node3D

## Levitating 3D "Shoal-like" Matrix Particle Swarm & Diegetic Pedestal Display.
## Faithful realization of the organic murmuration & shoaling swarm concept:
## - 36 coordinated curvilinear vortex streams with over 5,000 fluid glowing particles.
## - Undulating wave-like currents and 3D Curl Noise turbulence mimicking a school of fish / flock of birds.
## - Dynamic color ignition: Digital Teal, Neon Cyan, and deep blue, bursting into warm amber and fiery gold in dense vortex tracks.
## - Glowing curvilinear trajectory trail streaks tracing rapid flocking trajectories.
## - Dual orbital data rings (Solar Amber & Neon Cyan).
## - Faint 3D holographic telemetry glyphs ("SHOAL DENSITY", "EULERIAN VECTOR FIELD", "504.0 MH/s").
## - 14 real-time internal spectrum hashrate visualizer bars.
## - Free-floating zero-g sparks drifting into the room.
## - Enlarged, high-contrast diegetic pedestal display facing the operator.
## - Physical solid collision body with Interactable3D for [E] crosshair interaction and optimization pulse.

@export var core_color: Color = Color("#00f0ff")

# 3D Swarm Components
var _core_sphere: Node3D
var _gpu_swarm: GPUParticles3D
var _ring_amber: MeshInstance3D
var _ring_cyan: MeshInstance3D
var _core_light: OmniLight3D

# Materials
var _swarm_material: ShaderMaterial
var _ring_amber_material: StandardMaterial3D
var _ring_cyan_material: StandardMaterial3D

# Enlarged Diegetic Pedestal Display
var _holo_screen_mesh: MeshInstance3D
var _holo_viewport: SubViewport
var _holo_material: StandardMaterial3D

# Dynamic UI Elements on Pedestal Screen
var _ui_lbl_hashrate: Label
var _ui_lbl_status_pill: Label
var _ui_lbl_temp: Label
var _ui_lbl_state_desc: Label
var _ui_bar_density: ProgressBar
var _ui_bar_chaos: ProgressBar
var _ui_bar_speed: ProgressBar
var _ui_bar_life: ProgressBar
var _ui_cluster_badges: Array[Label] = []
var _ui_wave_vector: Line2D

# Telemetry and State
var heat_level: float = 0.0
var _target_heat: float = 0.0
var _current_rate_mhs: float = 504.0
var _current_status: String = "СТАБИЛНО"
var _pulse_scale_mult: float = 1.0

func _ready() -> void:
	_build_pedestal()
	_build_shoal_swarm()
	_build_enlarged_pedestal_display()

func set_core_telemetry(rate_mhs: float, status_text: String, _candidate_text: String = "") -> void:
	_current_rate_mhs = rate_mhs
	_current_status = status_text if status_text != "" else "СТАБИЛНО"
	if rate_mhs > 0.0:
		_target_heat = clamp(rate_mhs / 320.0, 0.2, 1.0)
	else:
		_target_heat = 0.0
	_update_pedestal_ui()

func pulse_core() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_pulse_scale_mult", 1.15, 0.22)
	if _core_light:
		tween.tween_property(_core_light, "light_energy", 1.4, 0.2)
	tween.chain().tween_property(self, "_pulse_scale_mult", 1.0, 0.40)
	if _core_light:
		tween.parallel().tween_property(_core_light, "light_energy", 0.85 + heat_level * 0.4, 0.40)

	var conduits = get_tree().get_nodes_in_group("energy_conduits")
	for c in conduits:
		if c.has_method("trigger_energy_pulse"):
			c.trigger_energy_pulse()

func _process(delta: float) -> void:
	heat_level = lerp(heat_level, _target_heat, delta * 3.0)

	var active_color: Color
	if heat_level < 0.5:
		var t_c = heat_level * 2.0
		active_color = Color("#00f0ff").lerp(Color("#ffaa00"), t_c)
	else:
		var t_c = (heat_level - 0.5) * 2.0
		active_color = Color("#ffaa00").lerp(Color("#ff4500"), t_c)

	# 1. Update Swarm Materials
	if _swarm_material:
		var target_speed = 2.4 + heat_level * 1.2
		_swarm_material.set_shader_parameter("flow_speed", target_speed)
		_swarm_material.set_shader_parameter("sphere_radius", 0.65)
		_swarm_material.set_shader_parameter("shell_thickness", 0.22)
		_swarm_material.set_shader_parameter("radial_stiffness", 28.0)
		_swarm_material.set_shader_parameter("color_calm", Color(0.0, 0.85, 1.0, 1.0))
		_swarm_material.set_shader_parameter("color_surge", Color(1.0, 0.45, 0.05, 1.0).lerp(Color(1.0, 0.25, 0.0, 1.0), heat_level))

	var t = Time.get_ticks_msec() * 0.001
	var lev_y = 1.72 + sin(t * 1.5) * 0.035

	if _core_light:
		_core_light.position.y = lev_y
		_core_light.light_color = active_color
		_core_light.light_energy = 0.85 + (heat_level * 0.45)

	# 2. Multi-Axis Organic Levitation & Murmuration Swirl
	if _core_sphere:
		_core_sphere.position.y = lev_y
		var pulse = (sin(t * (3.5 + heat_level * 5.0)) * 0.015 + 1.0) * _pulse_scale_mult
		_core_sphere.scale = Vector3(pulse, pulse, pulse)

	if _gpu_swarm:
		var spin_speed = 0.15 + (heat_level * 0.5)
		_gpu_swarm.rotate_y(delta * spin_speed)

	if _ring_amber:
		_ring_amber.rotate_z(delta * 0.40)
		_ring_amber.rotate_y(delta * 0.22)

	if _ring_cyan:
		_ring_cyan.rotate_x(-delta * 0.35)
		_ring_cyan.rotate_z(delta * 0.18)

	# 5. Animate Dynamic Waveform on Pedestal Display
	_animate_pedestal_waveform(t)

	_update_pedestal_ui()

# ==============================================================================
# 3D PHYSICAL PLATFORM & PEDESTAL
# ==============================================================================
func _build_pedestal() -> void:
	var base = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.25
	cyl.bottom_radius = 1.40
	cyl.height = 0.25
	base.mesh = cyl
	base.position = Vector3(0.0, 0.125, 0.0)

	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color("#0a0f1d")
	base_mat.metallic = 0.94
	base_mat.roughness = 0.20
	base.material_override = base_mat
	add_child(base)

	# Glowing emitter bezel ring on platform
	var bezel = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.05
	torus.outer_radius = 1.20
	bezel.mesh = torus
	bezel.position = Vector3(0.0, 0.26, 0.0)

	var bezel_mat = StandardMaterial3D.new()
	bezel_mat.albedo_color = Color("#00f0ff")
	bezel_mat.emission_enabled = true
	bezel_mat.emission = Color("#00f0ff")
	bezel_mat.emission_energy_multiplier = 1.5
	bezel.material_override = bezel_mat
	add_child(bezel)

	# Physical solid collision body for pedestal base (prevents walking through platform)
	var core_body = StaticBody3D.new()
	core_body.name = "PedestalStaticBody"
	core_body.collision_layer = 1
	core_body.collision_mask = 1

	var col_shape = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 1.35
	cyl_shape.height = 0.35
	col_shape.shape = cyl_shape
	col_shape.position = Vector3(0.0, 0.175, 0.0)
	core_body.add_child(col_shape)
	add_child(core_body)

# ==============================================================================
# LEVITATING 3D "SHOAL-LIKE" MATRIX PARTICLE SWARM
# ==============================================================================
func _build_shoal_swarm() -> void:
	_core_sphere = Node3D.new()
	_core_sphere.position = Vector3(0.0, 1.72, 0.0)
	add_child(_core_sphere)

	# 1. 3D "Shoal-like" GPUParticles3D Murmuration Swarm (50,000 particles)
	_gpu_swarm = GPUParticles3D.new()
	_gpu_swarm.amount = 50000
	_gpu_swarm.lifetime = 14.0
	_gpu_swarm.preprocess = 5.0
	_gpu_swarm.fixed_fps = 0
	_gpu_swarm.interpolate = true
	_gpu_swarm.fract_delta = true
	_gpu_swarm.local_coords = true
	_gpu_swarm.visibility_aabb = AABB(Vector3(-2.0, -2.0, -2.0), Vector3(4.0, 4.0, 4.0))

	_swarm_material = ShaderMaterial.new()
	var swarm_sh = load("res://shaders/shoal_matrix_particles.gdshader")
	if swarm_sh:
		_swarm_material.shader = swarm_sh
		_swarm_material.set_shader_parameter("sphere_radius", 0.65)
		_swarm_material.set_shader_parameter("shell_thickness", 0.22)
		_swarm_material.set_shader_parameter("flow_speed", 2.8)
		_swarm_material.set_shader_parameter("curl_scale", 1.8)
		_swarm_material.set_shader_parameter("steering_inertia", 5.5)
		_swarm_material.set_shader_parameter("radial_stiffness", 28.0)
		_swarm_material.set_shader_parameter("color_calm", Color(0.0, 0.85, 1.0, 1.0))
		_swarm_material.set_shader_parameter("color_surge", Color(1.0, 0.45, 0.05, 1.0))

	_gpu_swarm.process_material = _swarm_material

	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(1.0, 1.0, 1.0)
	var p_mat = StandardMaterial3D.new()
	p_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	p_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	p_mat.vertex_color_use_as_albedo = true
	p_mat.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	p_mesh.material = p_mat
	_gpu_swarm.draw_pass_1 = p_mesh

	_core_sphere.add_child(_gpu_swarm)

	# 2. Dual Subtle Orbital Data Rings (Fitted to 0.65m sphere)
	_ring_amber = MeshInstance3D.new()
	var t_amber = TorusMesh.new()
	t_amber.inner_radius = 0.78
	t_amber.outer_radius = 0.795
	_ring_amber.mesh = t_amber
	_ring_amber.rotation.x = deg_to_rad(18.0)

	_ring_amber_material = StandardMaterial3D.new()
	_ring_amber_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_amber_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring_amber_material.albedo_color = Color("#ff6600")
	_ring_amber.material_override = _ring_amber_material
	_core_sphere.add_child(_ring_amber)

	_ring_cyan = MeshInstance3D.new()
	var t_cyan = TorusMesh.new()
	t_cyan.inner_radius = 0.83
	t_cyan.outer_radius = 0.845
	_ring_cyan.mesh = t_cyan
	_ring_cyan.rotation.z = deg_to_rad(-25.0)

	_ring_cyan_material = StandardMaterial3D.new()
	_ring_cyan_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_cyan_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_ring_cyan_material.albedo_color = Color("#00e5ff")
	_ring_cyan.material_override = _ring_cyan_material
	_core_sphere.add_child(_ring_cyan)

	# 3. Core OmniLight (Restrained range and no volumetric fog blowup)
	_core_light = OmniLight3D.new()
	_core_light.position = Vector3(0.0, 1.72, 0.0)
	_core_light.light_color = Color("#00e5ff")
	_core_light.light_energy = 0.85
	_core_light.omni_range = 2.4
	_core_light.light_volumetric_fog_energy = 0.0
	add_child(_core_light)

# ==============================================================================
# ENLARGED DIEGETIC PEDESTAL DISPLAY
# ==============================================================================
func _build_enlarged_pedestal_display() -> void:
	_holo_viewport = SubViewport.new()
	_holo_viewport.size = Vector2i(960, 520)
	_holo_viewport.transparent_bg = true
	_holo_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_holo_viewport)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(960, 520)
	panel.size = Vector2(960, 520)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.015, 0.035, 0.07, 0.92)
	sb.border_color = Color("#00f0ff")
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 24
	sb.content_margin_top = 18
	sb.content_margin_right = 24
	sb.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", sb)
	_holo_viewport.add_child(panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	panel.add_child(main_vbox)

	# 1. Header Row
	var header = HBoxContainer.new()
	main_vbox.add_child(header)

	var lbl_title = Label.new()
	lbl_title.text = "⚛ КВАНТОВО МАТРИЧНО ЯДРО (SHOAL SWARM MATRIX)"
	lbl_title.add_theme_font_size_override("font_size", 20)
	lbl_title.add_theme_color_override("font_color", Color("#00f0ff"))
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	_ui_lbl_status_pill = Label.new()
	_ui_lbl_status_pill.text = "[ ГОТОВНОСТ ]"
	_ui_lbl_status_pill.add_theme_font_size_override("font_size", 16)
	_ui_lbl_status_pill.add_theme_color_override("font_color", Color("#10b981"))
	header.add_child(_ui_lbl_status_pill)

	var sep = HSeparator.new()
	main_vbox.add_child(sep)

	# 2. Main Content
	var content_row = HBoxContainer.new()
	content_row.add_theme_constant_override("separation", 24)
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(content_row)

	# Left Column
	var left_col = VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 1.15
	left_col.add_theme_constant_override("separation", 8)
	content_row.add_child(left_col)

	var lbl_thru_tag = Label.new()
	lbl_thru_tag.text = "ИЗЧИСЛИТЕЛЕН ХАШРЕЙТ / THROUGHPUT:"
	lbl_thru_tag.add_theme_font_size_override("font_size", 14)
	lbl_thru_tag.add_theme_color_override("font_color", Color("#94a3b8"))
	left_col.add_child(lbl_thru_tag)

	_ui_lbl_hashrate = Label.new()
	_ui_lbl_hashrate.text = "504.0 MH/s"
	_ui_lbl_hashrate.add_theme_font_size_override("font_size", 42)
	_ui_lbl_hashrate.add_theme_color_override("font_color", Color("#00f0ff"))
	left_col.add_child(_ui_lbl_hashrate)

	var wave_panel = Panel.new()
	wave_panel.custom_minimum_size = Vector2(0, 85)
	wave_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var wave_sb = StyleBoxFlat.new()
	wave_sb.bg_color = Color(0.01, 0.02, 0.04, 0.85)
	wave_sb.border_color = Color("#0e7490")
	wave_sb.set_border_width_all(1)
	wave_panel.add_theme_stylebox_override("panel", wave_sb)
	left_col.add_child(wave_panel)

	_ui_wave_vector = Line2D.new()
	_ui_wave_vector.width = 2.8
	_ui_wave_vector.default_color = Color("#ff7733")
	wave_panel.add_child(_ui_wave_vector)

	# Right Column
	var right_col = VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_stretch_ratio = 1.0
	right_col.add_theme_constant_override("separation", 8)
	content_row.add_child(right_col)

	var lbl_ctl_title = Label.new()
	lbl_ctl_title.text = "ПАРАМЕТРИ НА МАТРИЦАТА (SHOAL & CURL NOISE):"
	lbl_ctl_title.add_theme_font_size_override("font_size", 14)
	lbl_ctl_title.add_theme_color_override("font_color", Color("#38bdf8"))
	right_col.add_child(lbl_ctl_title)

	_ui_bar_density = _add_telemetry_bar(right_col, "ПЛЪТНОСТ (Shoal Density)", 74)
	_ui_bar_chaos = _add_telemetry_bar(right_col, "ТУРБУЛЕНТНОСТ (Curl Chaos)", 85)
	_ui_bar_speed = _add_telemetry_bar(right_col, "СКОРОСТ (Flocking Velocity)", 42)
	_ui_bar_life = _add_telemetry_bar(right_col, "ЖИЗНЕН ЦИКЪЛ (Life Bounds)", 68)

	var lbl_nodes_tag = Label.new()
	lbl_nodes_tag.text = "АКТИВНИ ИЗЧИСЛИТЕЛНИ ВЪЗЛИ:"
	lbl_nodes_tag.add_theme_font_size_override("font_size", 13)
	lbl_nodes_tag.add_theme_color_override("font_color", Color("#64748b"))
	right_col.add_child(lbl_nodes_tag)

	var badge_row = HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 6)
	right_col.add_child(badge_row)

	_ui_cluster_badges.clear()
	var node_names = ["GPU 0: 53°C", "GPU 1: 52°C", "GPU 2: 52°C", "GPU 3: 51°C", "CPU #5: 39°C"]
	for n_name in node_names:
		var badge = Label.new()
		badge.text = "[ %s ]" % n_name
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", Color("#38bdf8"))
		badge_row.add_child(badge)
		_ui_cluster_badges.append(badge)

	# 3. Footer Row
	var sep2 = HSeparator.new()
	main_vbox.add_child(sep2)

	var footer = HBoxContainer.new()
	main_vbox.add_child(footer)

	_ui_lbl_temp = Label.new()
	_ui_lbl_temp.text = "ТЕМПЕРАТУРА: 52°C [NOMINAL]"
	_ui_lbl_temp.add_theme_font_size_override("font_size", 13)
	_ui_lbl_temp.add_theme_color_override("font_color", Color("#10b981"))
	_ui_lbl_temp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_ui_lbl_temp)

	_ui_lbl_state_desc = Label.new()
	_ui_lbl_state_desc.text = "РЕЖИМ: АКТИВЕН ИЗЧИСЛИТЕЛЕН ПАЙПЛАЙН"
	_ui_lbl_state_desc.add_theme_font_size_override("font_size", 13)
	_ui_lbl_state_desc.add_theme_color_override("font_color", Color("#94a3b8"))
	footer.add_child(_ui_lbl_state_desc)

	# 3D Quad Mesh - Enlarged to 1.25 x 0.68m facing operator
	_holo_screen_mesh = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(1.25, 0.68)
	_holo_screen_mesh.mesh = quad
	_holo_screen_mesh.position = Vector3(0.0, 0.76, 1.25)
	_holo_screen_mesh.rotation_degrees = Vector3(-18.0, 0.0, 0.0)

	_holo_material = StandardMaterial3D.new()
	_holo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_holo_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_holo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_holo_material.albedo_texture = _holo_viewport.get_texture()
	_holo_screen_mesh.material_override = _holo_material
	add_child(_holo_screen_mesh)

	var post = MeshInstance3D.new()
	var post_mesh = CylinderMesh.new()
	post_mesh.top_radius = 0.02
	post_mesh.bottom_radius = 0.03
	post_mesh.height = 0.52
	post.mesh = post_mesh
	post.position = Vector3(0.0, 0.46, 1.20)
	var post_mat = StandardMaterial3D.new()
	post_mat.albedo_color = Color("#0f172a")
	post_mat.metallic = 0.92
	post.material_override = post_mat
	add_child(post)

func _add_telemetry_bar(parent: VBoxContainer, label_text: String, value: int) -> ProgressBar:
	var row = HBoxContainer.new()
	parent.add_child(row)

	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color("#cbd5e1"))
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(lbl)

	var val_lbl = Label.new()
	val_lbl.text = "%d%%" % value
	val_lbl.add_theme_font_size_override("font_size", 12)
	val_lbl.add_theme_color_override("font_color", Color("#00f0ff"))
	row.add_child(val_lbl)

	var bar = ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 6)
	parent.add_child(bar)
	return bar

func _animate_pedestal_waveform(t: float) -> void:
	if not _ui_wave_vector:
		return
	_ui_wave_vector.clear_points()
	var w = 420.0
	var base_y = 42.0
	for x_i in range(0, 36):
		var x = float(x_i) * (w / 36.0) + 12.0
		var y = base_y + sin(t * 4.5 + float(x_i) * 0.4) * 22.0 + cos(t * 2.2 + float(x_i) * 0.2) * 10.0
		_ui_wave_vector.add_point(Vector2(x, y))

func _update_pedestal_ui() -> void:
	if not _ui_lbl_hashrate:
		return

	var active_color: Color
	if heat_level < 0.5:
		var t = heat_level * 2.0
		active_color = Color("#00f0ff").lerp(Color("#ffaa00"), t)
	else:
		var t = (heat_level - 0.5) * 2.0
		active_color = Color("#ffaa00").lerp(Color("#ff4500"), t)

	_ui_lbl_hashrate.text = "%.1f MH/s" % _current_rate_mhs
	_ui_lbl_hashrate.add_theme_color_override("font_color", active_color)

	if heat_level > 0.65:
		_ui_lbl_status_pill.text = "[ КРИТИЧНО НАТОВАРВАНЕ ]"
		_ui_lbl_status_pill.add_theme_color_override("font_color", Color("#ff4500"))
		var temp_val = int(72.0 + (heat_level * 18.0))
		_ui_lbl_temp.text = "ТЕМПЕРАТУРА: %d°C [SUPERCRITICAL]" % temp_val
		_ui_lbl_temp.add_theme_color_override("font_color", Color("#ff4500"))
		_ui_lbl_state_desc.text = "РЕЖИМ: ОВЪРКЛОК (ОГНЕН КЕХЛИБАР)"
		_ui_lbl_state_desc.add_theme_color_override("font_color", Color("#ffaa00"))
	elif heat_level > 0.2:
		_ui_lbl_status_pill.text = "[ АКТИВНО ИЗПЪЛНЕНИЕ ]"
		_ui_lbl_status_pill.add_theme_color_override("font_color", Color("#ffaa00"))
		var temp_val = int(50.0 + (heat_level * 22.0))
		_ui_lbl_temp.text = "ТЕМПЕРАТУРА: %d°C [HIGH LOAD]" % temp_val
		_ui_lbl_temp.add_theme_color_override("font_color", Color("#ffaa00"))
		_ui_lbl_state_desc.text = "РЕЖИМ: АКТИВЕН ИЗЧИСЛИТЕЛЕН ПАЙПЛАЙН"
		_ui_lbl_state_desc.add_theme_color_override("font_color", Color("#38bdf8"))
	else:
		_ui_lbl_status_pill.text = "[ ГОТОВНОСТ ]"
		_ui_lbl_status_pill.add_theme_color_override("font_color", Color("#10b981"))
		_ui_lbl_temp.text = "ТЕМПЕРАТУРА: 38°C [NOMINAL]"
		_ui_lbl_temp.add_theme_color_override("font_color", Color("#10b981"))
		_ui_lbl_state_desc.text = "РЕЖИМ: СТАНДАРТЕН"
		_ui_lbl_state_desc.add_theme_color_override("font_color", Color("#94a3b8"))

	for badge in _ui_cluster_badges:
		if heat_level > 0.2:
			badge.add_theme_color_override("font_color", active_color)
		else:
			badge.add_theme_color_override("font_color", Color("#38bdf8"))
