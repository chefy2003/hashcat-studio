class_name HoloCore3D
extends Node3D

## Central 3D Quantum Cryptographic Core.
## Features concentric gyroscope holographic rings, pulsating core reactor,
## dynamic OmniLight, and floating spatial 3D telemetry readouts (no flat 2D cards).

@export var core_color: Color = Color("#00f0ff")

var _ring1: MeshInstance3D
var _ring2: MeshInstance3D
var _ring3: MeshInstance3D
var _core_sphere: MeshInstance3D
var _core_light: OmniLight3D

# Floating Spatial 3D Labels
var _lbl_title: Label3D
var _lbl_status: Label3D
var _lbl_rate: Label3D
var _lbl_topology: Label3D

var _base_scale: Vector3 = Vector3.ONE

func _ready() -> void:
	_build_pedestal()
	_build_rings()
	_build_core_sphere()
	_build_floating_labels()

func set_core_telemetry(rate_mhs: float, status_text: String, candidate_text: String = "") -> void:
	if _lbl_rate:
		_lbl_rate.text = "THROUGHPUT: %.1f MH/s  •  PIPELINE: ACTIVE" % rate_mhs
	if _lbl_status:
		_lbl_status.text = "STATUS: %s  •  %s" % [status_text, candidate_text if candidate_text != "" else "ENGINE READY"]

func pulse_core() -> void:
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_core_sphere, "scale", Vector3(1.35, 1.35, 1.35), 0.35)
	if _core_light:
		tween.tween_property(_core_light, "light_energy", 3.5, 0.2)
	tween.chain().tween_property(_core_sphere, "scale", Vector3.ONE, 0.4)
	if _core_light:
		tween.parallel().tween_property(_core_light, "light_energy", 1.2, 0.4)

func _process(delta: float) -> void:
	# Rotate concentric gimbal rings at staggered multi-axis speeds
	if _ring1:
		_ring1.rotate_y(delta * 0.75)
		_ring1.rotate_x(delta * 0.2)
	if _ring2:
		_ring2.rotate_x(-delta * 0.95)
		_ring2.rotate_z(delta * 0.35)
	if _ring3:
		_ring3.rotate_z(delta * 1.3)
		_ring3.rotate_y(-delta * 0.45)

	# Heartbeat core pulsation
	if _core_sphere:
		var pulse = sin(Time.get_ticks_msec() * 0.0035) * 0.05 + 1.0
		_core_sphere.scale = Vector3(pulse, pulse, pulse)

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

	# Glowing emitter bezel ring on platform
	var bezel = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 1.0
	torus.outer_radius = 1.15
	bezel.mesh = torus
	bezel.position.y = 0.26

	var bezel_mat = StandardMaterial3D.new()
	bezel_mat.albedo_color = Color("#00f0ff")
	bezel_mat.emission_enabled = true
	bezel_mat.emission = Color("#00f0ff")
	bezel_mat.emission_energy_multiplier = 2.0
	bezel.material_override = bezel_mat
	add_child(bezel)

func _build_rings() -> void:
	var ring_shader = load("res://shaders/hologram_core_rings.gdshader")
	var ring_mat = ShaderMaterial.new()
	if ring_shader:
		ring_mat.shader = ring_shader
		ring_mat.set_shader_parameter("core_color", core_color)
		ring_mat.set_shader_parameter("fresnel_power", 2.2)
		ring_mat.set_shader_parameter("pulse_speed", 2.5)

	# Ring 1: Outer
	_ring1 = MeshInstance3D.new()
	var t1 = TorusMesh.new()
	t1.inner_radius = 1.35
	t1.outer_radius = 1.42
	_ring1.mesh = t1
	_ring1.position.y = 1.35
	_ring1.material_override = ring_mat
	add_child(_ring1)

	# Ring 2: Middle
	_ring2 = MeshInstance3D.new()
	var t2 = TorusMesh.new()
	t2.inner_radius = 1.05
	t2.outer_radius = 1.11
	_ring2.mesh = t2
	_ring2.position.y = 1.35
	_ring2.rotation.x = deg_to_rad(35.0)
	_ring2.material_override = ring_mat
	add_child(_ring2)

	# Ring 3: Inner
	_ring3 = MeshInstance3D.new()
	var t3 = TorusMesh.new()
	t3.inner_radius = 0.78
	t3.outer_radius = 0.83
	_ring3.mesh = t3
	_ring3.position.y = 1.35
	_ring3.rotation.z = deg_to_rad(65.0)
	_ring3.material_override = ring_mat
	add_child(_ring3)

func _build_core_sphere() -> void:
	_core_sphere = MeshInstance3D.new()
	var sph = SphereMesh.new()
	sph.radius = 0.32
	sph.height = 0.64
	_core_sphere.mesh = sph
	_core_sphere.position.y = 1.35

	var sph_mat = StandardMaterial3D.new()
	sph_mat.albedo_color = Color("#00f0ff")
	sph_mat.emission_enabled = true
	sph_mat.emission = Color("#00f0ff")
	sph_mat.emission_energy_multiplier = 2.8 # Glow Bloom
	_core_sphere.material_override = sph_mat
	add_child(_core_sphere)

	# Core Point Light
	_core_light = OmniLight3D.new()
	_core_light.position.y = 1.35
	_core_light.light_color = Color("#00f0ff")
	_core_light.light_energy = 1.4
	_core_light.omni_range = 5.5
	add_child(_core_light)

func _build_floating_labels() -> void:
	# 1. Main Holo Header
	_lbl_title = Label3D.new()
	_lbl_title.text = "⚡ HASHCAT QUANTUM ENGINE PRO"
	_lbl_title.font_size = 28
	_lbl_title.modulate = Color("#00f0ff")
	_lbl_title.outline_modulate = Color("#003344")
	_lbl_title.outline_size = 6
	_lbl_title.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_lbl_title.position = Vector3(0.0, 2.5, 0.0)
	add_child(_lbl_title)

	# 2. Status Label
	_lbl_status = Label3D.new()
	_lbl_status.text = "STATUS: ACTIVE // NUMA COMPUTING PIPELINE"
	_lbl_status.font_size = 18
	_lbl_status.modulate = Color("#10b981")
	_lbl_status.outline_modulate = Color("#022c22")
	_lbl_status.outline_size = 4
	_lbl_status.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_lbl_status.position = Vector3(0.0, 2.25, 0.0)
	add_child(_lbl_status)

	# 3. Live Throughput Rate
	_lbl_rate = Label3D.new()
	_lbl_rate.text = "THROUGHPUT: 142.8 MH/s  •  PIPELINE: STREAMING"
	_lbl_rate.font_size = 20
	_lbl_rate.modulate = Color("#f1f5f9")
	_lbl_rate.outline_modulate = Color("#0f172a")
	_lbl_rate.outline_size = 5
	_lbl_rate.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_lbl_rate.position = Vector3(0.0, 0.45, 0.8)
	add_child(_lbl_rate)

	# 4. Hardware Node Summary
	_lbl_topology = Label3D.new()
	_lbl_topology.text = "NODES: CPU #5 (NUMA) + GPU #1 (RX 480) + GPU #2 (ACCEL)"
	_lbl_topology.font_size = 14
	_lbl_topology.modulate = Color("#94a3b8")
	_lbl_topology.outline_modulate = Color("#0f172a")
	_lbl_topology.outline_size = 3
	_lbl_topology.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_lbl_topology.position = Vector3(0.0, 0.28, 0.8)
	add_child(_lbl_topology)
