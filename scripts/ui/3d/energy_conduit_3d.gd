class_name EnergyConduit3D
extends Node3D

## 3D Floor Energy & Data Conduit linking compute components to the quantum core.
## Uses an emissive shader with traveling energy pulses and thermal heat transitions.

@export var start_point: Vector3 = Vector3.ZERO
@export var end_point: Vector3 = Vector3.ZERO
@export var conduit_width: float = 0.22
@export var is_auto_oriented: bool = true

var _mesh_instance: MeshInstance3D
var _shader_material: ShaderMaterial

func _ready() -> void:
	_build_conduit()

func set_heat_level(heat: float) -> void:
	if _shader_material:
		_shader_material.set_shader_parameter("heat_amount", clamp(heat, 0.0, 1.0))
		_shader_material.set_shader_parameter("pulse_speed", 3.0 + (heat * 9.0))
		_shader_material.set_shader_parameter("glow_intensity", 1.8 + (heat * 1.5))

func _build_conduit() -> void:
	var dir = end_point - start_point
	var length = dir.length()
	if length < 0.1:
		return

	_mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(conduit_width, 0.02, length)
	_mesh_instance.mesh = box

	var shader = load("res://shaders/energy_conduit.gdshader")
	if shader:
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = shader
		_shader_material.set_shader_parameter("pulse_density", max(length * 1.8, 4.0))
		_mesh_instance.material_override = _shader_material

	add_child(_mesh_instance)

	# Position at midpoint
	var mid = (start_point + end_point) * 0.5
	mid.y = 0.015 # Slightly above floor grid to prevent Z-fighting
	_mesh_instance.position = mid

	# Orient towards end_point
	if is_auto_oriented:
		_mesh_instance.look_at(Vector3(end_point.x, mid.y, end_point.z), Vector3.UP)
