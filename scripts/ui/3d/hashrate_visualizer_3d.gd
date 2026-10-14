class_name HashrateVisualizer3D
extends Node3D

## High-performance 3D Spatial Waveform Visualizer using MultiMeshInstance3D.
## Displays live compute throughput without dropping frames.

@export var sample_count: int = 36
@export var bar_spacing: float = 0.14
@export var max_height: float = 1.8
@export var is_curved: bool = true
@export var arc_radius: float = 4.60
@export var arc_angle_span_deg: float = 48.0

var _multi_mesh_instance: MultiMeshInstance3D
var _height_values: PackedFloat32Array = PackedFloat32Array()
var _target_heights: PackedFloat32Array = PackedFloat32Array()
var _max_recorded_rate: float = 50.0

func _ready() -> void:
	_init_data_arrays()
	_setup_multimesh()
	_setup_collision()

func _setup_collision() -> void:
	var body = StaticBody3D.new()
	body.name = "WaveStaticBody"
	body.collision_layer = 1
	body.collision_mask = 1

	var span_rad: float = deg_to_rad(arc_angle_span_deg)
	var segment_count = 6
	var arc_len = arc_radius * span_rad
	var seg_w = (arc_len / float(segment_count)) * 1.05

	for k in range(segment_count):
		var factor = (float(k) / float(segment_count - 1)) - 0.5
		var theta = factor * span_rad
		var col = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(seg_w, max_height, 0.28)
		col.shape = box
		if is_curved:
			var x = arc_radius * sin(theta)
			var z = arc_radius * (1.0 - cos(theta))
			col.position = Vector3(x, max_height * 0.5, z)
			col.rotation_degrees.y = -rad_to_deg(theta)
		else:
			var x = factor * (float(sample_count) * bar_spacing)
			col.position = Vector3(x, max_height * 0.5, 0.0)
		body.add_child(col)

	add_child(body)

func pulse_wave() -> void:
	for i in range(sample_count):
		_target_heights[i] = min(_target_heights[i] + randf_range(0.3, 0.7), max_height)


func add_sample(rate_mhs: float) -> void:
	if rate_mhs > _max_recorded_rate:
		_max_recorded_rate = max(rate_mhs, 1.0)

	# Shift values left
	for i in range(sample_count - 1):
		_target_heights[i] = _target_heights[i + 1]

	var normalized_h = clamp(rate_mhs / _max_recorded_rate, 0.05, 1.0) * max_height
	_target_heights[sample_count - 1] = normalized_h

func _init_data_arrays() -> void:
	_height_values.resize(sample_count)
	_target_heights.resize(sample_count)
	for i in range(sample_count):
		# Default idle undulating pattern
		var base = (sin(float(i) * 0.4) * 0.5 + 0.5) * 0.35 + 0.05
		_height_values[i] = base
		_target_heights[i] = base

func _setup_multimesh() -> void:
	_multi_mesh_instance = MultiMeshInstance3D.new()
	add_child(_multi_mesh_instance)

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = sample_count

	# Unit cube mesh for each bar
	var bar_mesh = BoxMesh.new()
	bar_mesh.size = Vector3(0.09, 1.0, 0.09)
	mm.mesh = bar_mesh

	# Thermal gradient spectrum shader: Blue -> Yellow -> Ruby Red
	var shader = load("res://shaders/hashrate_bar.gdshader")
	if shader:
		var s_mat = ShaderMaterial.new()
		s_mat.shader = shader
		s_mat.set_shader_parameter("max_spectrum_height", max_height * 0.68)
		_multi_mesh_instance.material_override = s_mat
	else:
		var mat = StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.emission_enabled = true
		mat.emission = Color("#00a8ff")
		mat.emission_energy_multiplier = 0.8
		_multi_mesh_instance.material_override = mat
	_multi_mesh_instance.multimesh = mm

	_update_instance_transforms()

func _process(delta: float) -> void:
	var needs_update = false
	for i in range(sample_count):
		var cur = _height_values[i]
		var target = _target_heights[i]
		if abs(cur - target) > 0.005:
			_height_values[i] = lerp(cur, target, delta * 9.0)
			needs_update = true

	if needs_update:
		_update_instance_transforms()

func _update_instance_transforms() -> void:
	if not _multi_mesh_instance or not _multi_mesh_instance.multimesh:
		return

	var mm = _multi_mesh_instance.multimesh
	var half_width = (float(sample_count) * bar_spacing) * 0.5
	var span_rad: float = deg_to_rad(arc_angle_span_deg)

	for i in range(sample_count):
		var h = max(_height_values[i], 0.05)
		var y = h * 0.5 # Origin at bottom

		var t = Transform3D()
		if is_curved:
			# Evenly distribute bars across the arc
			var factor: float = (float(i) / float(max(sample_count - 1, 1))) - 0.5 # [-0.5, 0.5]
			var theta: float = factor * span_rad
			# Position bars along circle radius arc; curves backward so distance to core is exactly arc_radius
			var x = arc_radius * sin(theta)
			var z = arc_radius * (1.0 - cos(theta))
			# Rotate the bar so its face points inward toward the Quantum Core
			t = t.rotated(Vector3.UP, -theta)
			t = t.scaled(Vector3(1.0, h, 1.0))
			t.origin = Vector3(x, y, z)
		else:
			var x = (float(i) * bar_spacing) - half_width
			t = t.scaled(Vector3(1.0, h, 1.0))
			t.origin = Vector3(x, y, 0.0)

		mm.set_instance_transform(i, t)

		# Color gradient: Cyan (#00FFFF) to Deep Blue (#0055FF) across bars without overexposure
		var t_pos: float = float(i) / float(max(sample_count - 1, 1))
		var color: Color = Color("#00ffff").lerp(Color("#0055ff"), t_pos)
		
		# Slight height brightening (staying within saturated cool gamut)
		var h_ratio: float = clamp(h / max_height, 0.0, 1.0)
		color = color.lerp(Color("#38bdf8"), h_ratio * 0.35)

		mm.set_instance_color(i, color)

