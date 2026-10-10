class_name ServerRack3D
extends Node3D

## 3D Server Cabinet hosting compute nodes with status telemetry.

@export var rack_name: String = "PRIMARY COMPUTE CHASSIS"

var _units: Array[RackUnit3D] = []

func _ready() -> void:
	_build_rack_cabinet()
	_populate_default_units()

func update_device_telemetry(dev_id: int, temp: float, fan: float, util: float) -> void:
	for unit in _units:
		if unit.device_id == dev_id:
			unit.set_telemetry(temp, fan, util)
			return

func get_units() -> Array[RackUnit3D]:
	return _units

func _build_rack_cabinet() -> void:
	# Vertical rack rails (4 posts)
	var rail_mat = StandardMaterial3D.new()
	rail_mat.albedo_color = Color("#1e293b")
	rail_mat.metallic = 0.9
	rail_mat.roughness = 0.3

	var post_positions = [
		Vector3(-1.3, 0.8, -0.6),
		Vector3(1.3, 0.8, -0.6),
		Vector3(-1.3, 0.8, 0.6),
		Vector3(1.3, 0.8, 0.6)
	]

	for pos in post_positions:
		var post = MeshInstance3D.new()
		var post_mesh = BoxMesh.new()
		post_mesh.size = Vector3(0.08, 2.2, 0.08)
		post.mesh = post_mesh
		post.material_override = rail_mat
		post.position = pos
		add_child(post)

	# Top and Bottom Plates
	for y in [-0.3, 1.9]:
		var plate = MeshInstance3D.new()
		var plate_mesh = BoxMesh.new()
		plate_mesh.size = Vector3(2.7, 0.06, 1.3)
		plate.mesh = plate_mesh
		plate.material_override = rail_mat
		plate.position = Vector3(0.0, y, 0.0)
		add_child(plate)

func _populate_default_units() -> void:
	# Unit 1: CPU NUMA Node
	var cpu_unit = RackUnit3D.new()
	cpu_unit.name = "Unit_CPU_Host"
	cpu_unit.position = Vector3(0.0, 1.4, 0.0)
	add_child(cpu_unit)
	cpu_unit.setup_device(5, "CPU #5 [Host NUMA]", true)
	cpu_unit.set_telemetry(42.0, 35.0, 20.0)
	_units.append(cpu_unit)

	# Unit 2: GPU Primary (RX 480)
	var gpu1_unit = RackUnit3D.new()
	gpu1_unit.name = "Unit_GPU_1"
	gpu1_unit.position = Vector3(0.0, 0.85, 0.0)
	add_child(gpu1_unit)
	gpu1_unit.setup_device(1, "GPU #1 [Radeon RX 480]", false)
	gpu1_unit.set_telemetry(54.0, 45.0, 65.0)
	_units.append(gpu1_unit)

	# Unit 3: GPU Secondary (Accelerator)
	var gpu2_unit = RackUnit3D.new()
	gpu2_unit.name = "Unit_GPU_2"
	gpu2_unit.position = Vector3(0.0, 0.3, 0.0)
	add_child(gpu2_unit)
	gpu2_unit.setup_device(2, "GPU #2 [PCIe Compute 2]", false)
	gpu2_unit.set_telemetry(48.0, 40.0, 0.0)
	_units.append(gpu2_unit)
