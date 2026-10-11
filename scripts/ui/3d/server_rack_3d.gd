class_name ServerRack3D
extends Node3D

## 3D Server Cabinet hosting compute nodes with dynamic hardware auto-discovery.
## Probes compute topology (4x AMD GPUs + 1x Intel Xeon CPU) via HardwareInspector,
## dynamically sizes the chassis geometry, and handles device toggles with internal illumination.

signal device_toggled(dev_id: int, enabled: bool)
signal device_clicked(dev_id: int)

@export var rack_name: String = "PRIMARY COMPUTE CHASSIS"

var _units: Array[RackUnit3D] = []
var _interior_light: OmniLight3D

func _ready() -> void:
	_populate_dynamic_units()

func update_device_telemetry(dev_id: int, temp: float, fan: float, util: float) -> void:
	for unit in _units:
		if unit.device_id == dev_id:
			unit.set_telemetry(temp, fan, util)
			return

func get_units() -> Array[RackUnit3D]:
	return _units

func get_unit_by_id(dev_id: int) -> RackUnit3D:
	for unit in _units:
		if unit.device_id == dev_id:
			return unit
	return null

func toggle_device(dev_id: int) -> bool:
	for unit in _units:
		if unit.device_id == dev_id:
			var new_state: bool = not unit.is_enabled
			set_device_enabled(dev_id, new_state)
			return new_state
	return false

func set_device_enabled(dev_id: int, enabled: bool) -> void:
	for unit in _units:
		if unit.device_id == dev_id:
			unit.set_device_enabled(enabled)
			HardwareInspector.set_device_enabled(dev_id, enabled)
			device_toggled.emit(dev_id, enabled)
			return

func _populate_dynamic_units() -> void:
	# Clear existing children
	for child in get_children():
		child.queue_free()
	_units.clear()

	# Discover real hardware dynamically
	var detected_devices: Array[Dictionary] = HardwareInspector.probe_compute_devices()
	if detected_devices.is_empty():
		detected_devices = [
			{"id": 5, "name": "Intel Xeon E5-2696 v2", "type": "CPU", "enabled": true},
			{"id": 1, "name": "AMD Radeon Graphics", "type": "GPU", "enabled": false},
			{"id": 2, "name": "AMD Radeon Graphics", "type": "GPU", "enabled": false},
			{"id": 3, "name": "AMD Radeon Graphics", "type": "GPU", "enabled": false},
			{"id": 4, "name": "AMD Radeon Graphics", "type": "GPU", "enabled": false}
		]

	var num_units: int = detected_devices.size()
	var unit_spacing: float = 0.40
	var y_start: float = 0.22
	var y_end: float = y_start + float(num_units - 1) * unit_spacing

	var post_center_y: float = (y_start + y_end) * 0.5
	var post_height: float = max(2.3, (y_end - y_start) + 0.65)
	var bottom_plate_y: float = y_start - 0.22
	var top_plate_y: float = y_end + 0.22

	# 1. Build Cabinet Structure
	_build_cabinet_chassis(post_center_y, post_height, bottom_plate_y, top_plate_y)

	# 2. Sort devices: CPU on top, GPUs below in ascending ID order
	var cpu_devices: Array[Dictionary] = []
	var gpu_devices: Array[Dictionary] = []

	for dev in detected_devices:
		if dev.get("type", "") == "CPU":
			cpu_devices.append(dev)
		else:
			gpu_devices.append(dev)

	var ordered_devices: Array[Dictionary] = []
	# GPUs from bottom up or top down:
	# Place GPUs on lower shelves, CPU on topmost shelf
	ordered_devices.append_array(gpu_devices)
	ordered_devices.append_array(cpu_devices)

	# 3. Instantiate 3D Rack Units
	for i in range(ordered_devices.size()):
		var dev = ordered_devices[i]
		var dev_id: int = dev.get("id", 1)
		var dev_name: String = dev.get("name", "Device #" + str(dev_id))
		var dev_type: String = dev.get("type", "GPU")
		var is_cpu: bool = (dev_type == "CPU")
		var default_enabled: bool = dev.get("enabled", is_cpu)

		var unit: RackUnit3D = RackUnit3D.new()
		unit.name = "Unit_Dev_%d" % dev_id
		unit.position = Vector3(0.0, y_start + float(i) * unit_spacing, 0.0)
		add_child(unit)

		var display_label: String
		if is_cpu:
			display_label = "CPU #%d [%s]" % [dev_id, dev_name]
		else:
			display_label = "GPU #%d [%s]" % [dev_id, dev_name]

		unit.setup_device(dev_id, display_label, is_cpu, default_enabled)

		# Initial telemetry baseline
		if is_cpu:
			unit.set_telemetry(38.0, 32.0, 15.0)
		else:
			unit.set_telemetry(42.0 + float(dev_id) * 2.0, 30.0, 0.0)

		unit.unit_toggled.connect(func(id: int, enabled: bool):
			HardwareInspector.set_device_enabled(id, enabled)
			device_toggled.emit(id, enabled)
		)
		unit.unit_clicked.connect(func(id: int):
			device_clicked.emit(id)
		)

		_units.append(unit)

func _build_cabinet_chassis(center_y: float, height: float, bottom_y: float, top_y: float) -> void:
	# PBR Metallic material: dark slate steel (metallic 0.8, roughness 0.3)
	var rail_mat = StandardMaterial3D.new()
	rail_mat.albedo_color = Color("#222d3d")
	rail_mat.metallic = 0.8
	rail_mat.roughness = 0.3

	# 4 Corner Vertical Posts
	var post_x = 1.3
	var post_z = 0.6
	var post_positions = [
		Vector3(-post_x, center_y, -post_z),
		Vector3(post_x, center_y, -post_z),
		Vector3(-post_x, center_y, post_z),
		Vector3(post_x, center_y, post_z)
	]

	for pos in post_positions:
		var post = MeshInstance3D.new()
		var post_mesh = BoxMesh.new()
		post_mesh.size = Vector3(0.08, height, 0.08)
		post.mesh = post_mesh
		post.material_override = rail_mat
		post.position = pos
		add_child(post)

	# Top and Bottom Heavy Plates
	for y in [bottom_y, top_y]:
		var plate = MeshInstance3D.new()
		var plate_mesh = BoxMesh.new()
		plate_mesh.size = Vector3(2.7, 0.06, 1.3)
		plate.mesh = plate_mesh
		plate.material_override = rail_mat
		plate.position = Vector3(0.0, y, 0.0)
		add_child(plate)

	# Discrete Cool-Blue OmniLight inside the rack
	_interior_light = OmniLight3D.new()
	_interior_light.light_color = Color("#00a8ff") # Cool Blue
	_interior_light.light_energy = 0.75
	_interior_light.omni_range = 3.6
	_interior_light.position = Vector3(0.0, center_y, 0.35)
	add_child(_interior_light)

	# Physical solid collision body for Server Rack Chassis
	var rack_body = StaticBody3D.new()
	rack_body.name = "RackStaticBody"
	var col_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2.5, height, 0.85)
	col_shape.shape = box_shape
	col_shape.position = Vector3(0.0, center_y, 0.0)
	rack_body.add_child(col_shape)
	add_child(rack_body)
