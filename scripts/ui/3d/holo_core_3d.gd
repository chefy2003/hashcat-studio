class_name HoloCore3D
extends Node3D

## Central 3D Quantum Cryptographic Core.
## Features concentric gyroscope holographic rings, pulsating core reactor,
## dynamic OmniLight, and a miniature high-contrast holographic display.
## Reacts dynamically to attack load: heats up from cool cyan to fiery ruby red,
## accelerating ring spin and casting dramatic red light.

@export var core_color: Color = Color("#00f0ff")

var _ring1: MeshInstance3D
var _ring2: MeshInstance3D
var _ring3: MeshInstance3D
var _core_sphere: MeshInstance3D
var _core_light: OmniLight3D

# Materials
var _ring_material: ShaderMaterial
var _core_material: StandardMaterial3D

# Heat / Overclock state (0.0 = Idle/Cool Cyan, 1.0 = Max Load/Ruby Red)
var heat_level: float = 0.0
var _target_heat: float = 0.0
var _current_rate_mhs: float = 0.0
var _current_status: String = "ENGINE READY"

# Mini Hologram Display Components
var _holo_screen_mesh: MeshInstance3D
var _holo_viewport: SubViewport
var _holo_material: StandardMaterial3D

# Mini Holo 2D UI elements
var _ui_lbl_hashrate: Label
var _ui_lbl_status_pill: Label
var _ui_lbl_temp: Label
var _ui_lbl_state_desc: Label
var _ui_cluster_badges: Array[Label] = []

func _ready() -> void:
	_build_pedestal()
	_build_rings()
	_build_core_sphere()
	_build_mini_hologram()

func set_core_telemetry(rate_mhs: float, status_text: String, candidate_text: String = "") -> void:
	_current_rate_mhs = rate_mhs
	_current_status = status_text if status_text != "" else "ENGINE READY"
	
	if rate_mhs > 0.0:
		_target_heat = clamp(rate_mhs / 280.0, 0.25, 1.0)
	else:
		_target_heat = 0.0

	_update_mini_holo_ui()

func pulse_core() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_core_sphere, "scale", Vector3(1.4, 1.4, 1.4), 0.3)
	if _core_light:
		tween.tween_property(_core_light, "light_energy", 3.8, 0.2)
	tween.chain().tween_property(_core_sphere, "scale", Vector3.ONE, 0.35)
	if _core_light:
		tween.parallel().tween_property(_core_light, "light_energy", 1.0 + heat_level * 1.5, 0.35)

func _process(delta: float) -> void:
	# Smoothly interpolate heat level
	heat_level = lerp(heat_level, _target_heat, delta * 3.0)

	# Calculate dynamic color based on heat:
	# 0.0 -> Cyan (#00f0ff)
	# 0.5 -> Amber (#ffaa00)
	# 1.0 -> Ruby Red (#ff0044)
	var active_color: Color
	if heat_level < 0.5:
		var t = heat_level * 2.0
		active_color = Color("#00f0ff").lerp(Color("#ffaa00"), t)
	else:
		var t = (heat_level - 0.5) * 2.0
		active_color = Color("#ffaa00").lerp(Color("#ff0044"), t)

	# Update Core Sphere Material
	if _core_material:
		_core_material.albedo_color = active_color.darkened(0.2)
		_core_material.emission = active_color
		_core_material.emission_energy_multiplier = 1.25 + (heat_level * 1.8)

	# Update Ring Shader
	if _ring_material:
		_ring_material.set_shader_parameter("core_color", active_color)

	# Update OmniLight
	if _core_light:
		_core_light.light_color = active_color
		_core_light.light_energy = 0.7 + (heat_level * 1.6)

	# Rotate concentric gimbal rings (speed multiplies up to 3x under load)
	var speed_mult = 1.0 + (heat_level * 2.4)
	if _ring1:
		_ring1.rotate_y(delta * 0.75 * speed_mult)
		_ring1.rotate_x(delta * 0.20 * speed_mult)
	if _ring2:
		_ring2.rotate_x(-delta * 0.95 * speed_mult)
		_ring2.rotate_z(delta * 0.35 * speed_mult)
	if _ring3:
		_ring3.rotate_z(delta * 1.30 * speed_mult)
		_ring3.rotate_y(-delta * 0.45 * speed_mult)

	# Heartbeat core pulsation (faster jitter when overheated)
	if _core_sphere:
		var freq = 0.0035 + (heat_level * 0.008)
		var amp = 0.05 + (heat_level * 0.06)
		var pulse = sin(Time.get_ticks_msec() * freq) * amp + 1.0
		_core_sphere.scale = Vector3(pulse, pulse, pulse)

	# Periodic UI text update
	_update_mini_holo_ui()

func _build_pedestal() -> void:
	# Octagonal/Cylindrical base platform
	var base = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 1.2
	cyl.bottom_radius = 1.35
	cyl.height = 0.25
	base.mesh = cyl
	base.position.y = 0.125

	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color("#0d1321")
	base_mat.metallic = 0.9
	base_mat.roughness = 0.25
	base.material_override = base_mat
	add_child(base)

	# Physical solid collision body for Quantum Core & Pedestal
	var core_body = StaticBody3D.new()
	core_body.name = "CoreStaticBody"
	var col_shape = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 1.35
	cyl_shape.height = 2.4
	col_shape.shape = cyl_shape
	col_shape.position = Vector3(0.0, 1.2, 0.0)
	core_body.add_child(col_shape)
	add_child(core_body)

	# Glowing emitter bezel ring on platform
	var bezel = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.15
	bezel.mesh = torus
	bezel.position.y = 0.26

	var bezel_mat = StandardMaterial3D.new()
	bezel_mat.albedo_color = Color("#00b4d8")
	bezel_mat.emission_enabled = true
	bezel_mat.emission = Color("#00b4d8")
	bezel_mat.emission_energy_multiplier = 1.15
	bezel.material_override = bezel_mat
	add_child(bezel)

func _build_rings() -> void:
	var ring_shader = load("res://shaders/hologram_core_rings.gdshader")
	_ring_material = ShaderMaterial.new()
	if ring_shader:
		_ring_material.shader = ring_shader
		_ring_material.set_shader_parameter("core_color", core_color)

	# Ring 1: Outer
	_ring1 = MeshInstance3D.new()
	var t1 = TorusMesh.new()
	t1.inner_radius = 1.12
	t1.outer_radius = 1.18
	_ring1.mesh = t1
	_ring1.position.y = 1.35
	_ring1.material_override = _ring_material
	add_child(_ring1)

	# Ring 2: Middle
	_ring2 = MeshInstance3D.new()
	var t2 = TorusMesh.new()
	t2.inner_radius = 0.95
	t2.outer_radius = 1.00
	_ring2.mesh = t2
	_ring2.position.y = 1.35
	_ring2.rotation.x = deg_to_rad(35.0)
	_ring2.material_override = _ring_material
	add_child(_ring2)

	# Ring 3: Inner
	_ring3 = MeshInstance3D.new()
	var t3 = TorusMesh.new()
	t3.inner_radius = 0.78
	t3.outer_radius = 0.83
	_ring3.mesh = t3
	_ring3.position.y = 1.35
	_ring3.rotation.z = deg_to_rad(65.0)
	_ring3.material_override = _ring_material
	add_child(_ring3)

func _build_core_sphere() -> void:
	_core_sphere = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = 0.32
	sph.height = 0.64
	_core_sphere.mesh = sph
	_core_sphere.position.y = 1.35

	_core_material = StandardMaterial3D.new()
	_core_material.albedo_color = Color("#0096c7")
	_core_material.emission_enabled = true
	_core_material.emission = Color("#00b4d8")
	_core_material.emission_energy_multiplier = 1.25
	_core_sphere.material_override = _core_material
	add_child(_core_sphere)

	# Core Point Light
	_core_light = OmniLight3D.new()
	_core_light.position.y = 1.35
	_core_light.light_color = Color("#00b4d8")
	_core_light.light_energy = 0.7
	_core_light.omni_range = 5.0
	add_child(_core_light)

func _build_mini_hologram() -> void:
	# 1. SubViewport for rendering the 2D UI into a 3D texture
	_holo_viewport = SubViewport.new()
	_holo_viewport.size = Vector2i(540, 300)
	_holo_viewport.transparent_bg = true
	_holo_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_holo_viewport)

	# 2. Holographic UI Root Panel (Glassmorphic dark background with neon border)
	var root_panel = PanelContainer.new()
	root_panel.custom_minimum_size = Vector2(540, 300)
	root_panel.size = Vector2(540, 300)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.06, 0.12, 0.88) # High contrast dark glass
	style.border_color = Color("#00f0ff")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 18
	style.content_margin_top = 14
	style.content_margin_right = 18
	style.content_margin_bottom = 14
	root_panel.add_theme_stylebox_override("panel", style)
	_holo_viewport.add_child(root_panel)

	# VBox layout inside panel
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	root_panel.add_child(vbox)

	# Header: Icon + Title + Status Pill
	var header = HBoxContainer.new()
	vbox.add_child(header)

	var lbl_title = Label.new()
	lbl_title.text = "⚛ КВАНТОВО ЯДРО"
	lbl_title.add_theme_font_size_override("font_size", 17)
	lbl_title.add_theme_color_override("font_color", Color("#00f0ff"))
	lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(lbl_title)

	_ui_lbl_status_pill = Label.new()
	_ui_lbl_status_pill.text = "[ ГОТОВНОСТ ]"
	_ui_lbl_status_pill.add_theme_font_size_override("font_size", 14)
	_ui_lbl_status_pill.add_theme_color_override("font_color", Color("#10b981"))
	header.add_child(_ui_lbl_status_pill)

	# Separator line
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Big Hashrate Display
	var rate_box = VBoxContainer.new()
	rate_box.add_theme_constant_override("separation", 2)
	vbox.add_child(rate_box)

	var lbl_rate_tag = Label.new()
	lbl_rate_tag.text = "ИЗЧИСЛИТЕЛЕН ХАШРЕЙТ / THROUGHPUT:"
	lbl_rate_tag.add_theme_font_size_override("font_size", 13)
	lbl_rate_tag.add_theme_color_override("font_color", Color("#94a3b8"))
	rate_box.add_child(lbl_rate_tag)

	_ui_lbl_hashrate = Label.new()
	_ui_lbl_hashrate.text = "0.0 MH/s"
	_ui_lbl_hashrate.add_theme_font_size_override("font_size", 34)
	_ui_lbl_hashrate.add_theme_color_override("font_color", Color("#00f0ff"))
	rate_box.add_child(_ui_lbl_hashrate)

	# Hardware Cluster Badges
	var cluster_box = VBoxContainer.new()
	cluster_box.add_theme_constant_override("separation", 3)
	vbox.add_child(cluster_box)

	var lbl_cluster_tag = Label.new()
	lbl_cluster_tag.text = "АКТИВНИ ИЗЧИСЛИТЕЛНИ КЛЪСТЕРИ:"
	lbl_cluster_tag.add_theme_font_size_override("font_size", 12)
	lbl_cluster_tag.add_theme_color_override("font_color", Color("#64748b"))
	cluster_box.add_child(lbl_cluster_tag)

	var badge_row = HBoxContainer.new()
	badge_row.add_theme_constant_override("separation", 6)
	cluster_box.add_child(badge_row)

	var node_names = ["GPU 0", "GPU 1", "GPU 2", "GPU 3", "CPU #5"]
	for n_name in node_names:
		var badge = Label.new()
		badge.text = "[ %s: ON ]" % n_name
		badge.add_theme_font_size_override("font_size", 12)
		badge.add_theme_color_override("font_color", Color("#38bdf8"))
		badge_row.add_child(badge)
		_ui_cluster_badges.append(badge)

	# Thermal / State Footer
	var footer_box = HBoxContainer.new()
	vbox.add_child(footer_box)

	_ui_lbl_temp = Label.new()
	_ui_lbl_temp.text = "ТЕМПЕРАТУРА: 38°C [NOMINAL]"
	_ui_lbl_temp.add_theme_font_size_override("font_size", 12)
	_ui_lbl_temp.add_theme_color_override("font_color", Color("#10b981"))
	_ui_lbl_temp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_box.add_child(_ui_lbl_temp)

	_ui_lbl_state_desc = Label.new()
	_ui_lbl_state_desc.text = "РЕЖИМ: ОХЛАЖДАНЕ"
	_ui_lbl_state_desc.add_theme_font_size_override("font_size", 12)
	_ui_lbl_state_desc.add_theme_color_override("font_color", Color("#94a3b8"))
	footer_box.add_child(_ui_lbl_state_desc)

	# 3. 3D Quad Mesh Instance in the scene
	_holo_screen_mesh = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(0.85, 0.48)
	_holo_screen_mesh.mesh = quad

	# Positioned at front edge of core pedestal, angled slightly upwards towards operator
	_holo_screen_mesh.position = Vector3(0.0, 0.72, 1.25)
	_holo_screen_mesh.rotation_degrees = Vector3(-16.0, 0.0, 0.0)

	_holo_material = StandardMaterial3D.new()
	_holo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_holo_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_holo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_holo_material.albedo_texture = _holo_viewport.get_texture()
	_holo_screen_mesh.material_override = _holo_material
	add_child(_holo_screen_mesh)

	# Subtle plinth mount post under the screen
	var post = MeshInstance3D.new()
	var post_mesh = CylinderMesh.new()
	post_mesh.top_radius = 0.02
	post_mesh.bottom_radius = 0.03
	post_mesh.height = 0.50
	post.mesh = post_mesh
	post.position = Vector3(0.0, 0.45, 1.20)
	var post_mat = StandardMaterial3D.new()
	post_mat.albedo_color = Color("#0f172a")
	post_mat.metallic = 0.9
	post.material_override = post_mat
	add_child(post)

func _update_mini_holo_ui() -> void:
	if not _ui_lbl_hashrate:
		return

	# Color palette shifts with heat
	var active_color: Color
	if heat_level < 0.5:
		var t = heat_level * 2.0
		active_color = Color("#00f0ff").lerp(Color("#ffaa00"), t)
	else:
		var t = (heat_level - 0.5) * 2.0
		active_color = Color("#ffaa00").lerp(Color("#ff0044"), t)

	_ui_lbl_hashrate.text = "%.1f MH/s" % _current_rate_mhs
	_ui_lbl_hashrate.add_theme_color_override("font_color", active_color)

	if heat_level > 0.65:
		_ui_lbl_status_pill.text = "[ КРИТИЧНО НАТОВАРВАНЕ ]"
		_ui_lbl_status_pill.add_theme_color_override("font_color", Color("#ff0044"))
		var temp_val = int(72.0 + (heat_level * 18.0))
		_ui_lbl_temp.text = "ТЕМПЕРАТУРА: %d°C [SUPERCRITICAL]" % temp_val
		_ui_lbl_temp.add_theme_color_override("font_color", Color("#ff0044"))
		_ui_lbl_state_desc.text = "РЕЖИМ: ОВЪРКЛОК (РУБИН)"
		_ui_lbl_state_desc.add_theme_color_override("font_color", Color("#ffaa00"))
	elif heat_level > 0.2:
		_ui_lbl_status_pill.text = "[ АКТИВНО ИЗПЪЛНЕНИЕ ]"
		_ui_lbl_status_pill.add_theme_color_override("font_color", Color("#ffaa00"))
		var temp_val = int(50.0 + (heat_level * 22.0))
		_ui_lbl_temp.text = "ТЕМПЕРАТУРА: %d°C [HIGH LOAD]" % temp_val
		_ui_lbl_temp.add_theme_color_override("font_color", Color("#ffaa00"))
		_ui_lbl_state_desc.text = "РЕЖИМ: АКТИВЕН ПАЙПЛАЙН"
		_ui_lbl_state_desc.add_theme_color_override("font_color", Color("#38bdf8"))
	else:
		_ui_lbl_status_pill.text = "[ ГОТОВНОСТ ]"
		_ui_lbl_status_pill.add_theme_color_override("font_color", Color("#10b981"))
		_ui_lbl_temp.text = "ТЕМПЕРАТУРА: 38°C [NOMINAL]"
		_ui_lbl_temp.add_theme_color_override("font_color", Color("#10b981"))
		_ui_lbl_state_desc.text = "РЕЖИМ: СТАНДАРТЕН"
		_ui_lbl_state_desc.add_theme_color_override("font_color", Color("#94a3b8"))

	# Update badges color
	for badge in _ui_cluster_badges:
		if heat_level > 0.2:
			badge.add_theme_color_override("font_color", active_color)
		else:
			badge.add_theme_color_override("font_color", Color("#38bdf8"))
