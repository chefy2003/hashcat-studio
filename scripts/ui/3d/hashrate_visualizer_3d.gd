class_name HashrateVisualizer3D
extends Node3D

## High-performance 3D Spatial Waveform Visualizer using MultiMeshInstance3D.
## Displays live compute throughput without dropping frames.

@export var sample_count: int = 36
@export var bar_spacing: float = 0.14
@export var max_height: float = 1.8

var _multi_mesh_instance: MultiMeshInstance3D
var _height_values: PackedFloat32Array = PackedFloat32Array()
var _target_heights: PackedFloat32Array = PackedFloat32Array()
var _max_recorded_rate: float = 50.0

func _ready() -> void:
	_init_data_arrays()
	_setup_multimesh()

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

	# Material with unshaded neon emissive look
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color("#00f0ff")
	mat.emission_energy_multiplier = 1.4
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

	for i in range(sample_count):
		var h = max(_height_values[i], 0.05)
		var x = (float(i) * bar_spacing) - half_width
		var y = h * 0.5 # Origin at bottom
		var z = 0.0

		var t = Transform3D()
		t = t.scaled(Vector3(1.0, h, 1.0))
		t.origin = Vector3(x, y, z)
		mm.set_instance_transform(i, t)

		# Color gradient: Cyan (low) -> Emerald (medium) -> Amber/Purple (peak)
		var ratio = clamp(h / max_height, 0.0, 1.0)
		var color: Color
		if ratio < 0.5:
			color = Color("#00f0ff").lerp(Color("#10b981"), ratio * 2.0)
		else:
			color = Color("#10b981").lerp(Color("#f59e0b"), (ratio - 0.5) * 2.0)

		mm.set_instance_color(i, color)
