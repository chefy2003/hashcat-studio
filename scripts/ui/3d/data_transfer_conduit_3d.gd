class_name DataTransferConduit3D
extends Node3D

## 3D High-Speed Optical Data Transfer Conduit.
## Links StorageRack3D to HoloTerminal3D and ServerRack3D / HoloCore3D.
## Visualizes real-time file bursts (amber) and continuous wordlist streaming (electric cyan).

@export var start_point: Vector3 = Vector3.ZERO
@export var end_point: Vector3 = Vector3.ZERO
@export var conduit_width: float = 0.26
@export var is_auto_oriented: bool = true

var _mesh_instance: MeshInstance3D
var _shader_material: ShaderMaterial

var _is_streaming: bool = false
var _is_bursting: bool = false
var _burst_timer: float = 0.0
var _current_activity: float = 0.0

func _ready() -> void:
	add_to_group("data_conduits")
	_build_conduit()

func _process(delta: float) -> void:
	if _is_bursting:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_is_bursting = false

	var mode: int = 0
	var speed: float = 4.0
	if _is_bursting:
		mode = 1
		speed = 10.0
	elif _is_streaming:
		mode = 2
		speed = 14.0

	if _shader_material:
		_shader_material.set_shader_parameter("bus_mode", mode)
		_shader_material.set_shader_parameter("transfer_speed", speed)

func trigger_file_burst(duration: float = 2.8) -> void:
	_is_bursting = true
	_burst_timer = duration

func set_streaming(active: bool) -> void:
	_is_streaming = active

func _build_conduit() -> void:
	var dir = end_point - start_point
	var length = dir.length()
	if length < 0.1:
		return

	_mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(conduit_width, 0.024, length)
	_mesh_instance.mesh = box

	var shader = load("res://shaders/data_transfer_conduit.gdshader")
	if shader:
		_shader_material = ShaderMaterial.new()
		_shader_material.shader = shader
		_shader_material.set_shader_parameter("packet_density", clamp(length * 2.5, 6.0, 25.0))
		_shader_material.set_shader_parameter("bus_mode", 0)
		_shader_material.set_shader_parameter("transfer_speed", 4.0)
		_mesh_instance.material_override = _shader_material

	add_child(_mesh_instance)

	# Position at midpoint
	var mid = (start_point + end_point) * 0.5
	mid.y = 0.018 # Slightly above floor to prevent Z-fighting with floor and energy conduits
	_mesh_instance.position = mid

	# Orient towards end_point
	if is_auto_oriented:
		_mesh_instance.look_at(Vector3(end_point.x, mid.y, end_point.z), Vector3.UP)
