class_name ServerRack3D
extends Node3D

## 3D Server Cabinet hosting compute nodes with dynamic hardware auto-discovery.
## Probes compute topology (4x AMD GPUs + 1x Intel Xeon CPU) via HardwareInspector,
## dynamically sizes the chassis geometry, and handles device toggles with internal illumination.

signal device_toggled(dev_id: int, enabled: bool)
signal device_clicked(dev_id: int)

const MAT_PANEL = preload("res://materials/se_metal/metalhull02.tres")
const MAT_FRAME = preload("res://materials/se_metal/quarryibeama.tres")

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
			{"id": 1, "name": "AMD Radeon Graphics", "type": "GPU", "enabled": true},
			{"id": 2, "name": "AMD Radeon Graphics", "type": "GPU", "enabled": true},
			{"id": 3, "name": "AMD Radeon Graphics", "type": "GPU", "enabled": true},
			{"id": 4, "name": "AMD Radeon Graphics", "type": "GPU", "enabled": true}
		]

	var num_units: int = detected_devices.size()
	var unit_spacing: float = 0.44
	var y_start: float = 0.28
	var y_end: float = y_start + float(num_units - 1) * unit_spacing

	var post_center_y: float = (y_start + y_end) * 0.5
	var post_height: float = max(2.5, (y_end - y_start) + 0.7)
	var bottom_plate_y: float = y_start - 0.22
	var top_plate_y: float = y_end + 0.24

	# 1. Build Cabinet Structure
	_build_cabinet_chassis(post_center_y, post_height, bottom_plate_y, top_plate_y)

	# 2. Sort devices: GPUs on lower shelves, CPU on topmost shelf
	var cpu_devices: Array[Dictionary] = []
	var gpu_devices: Array[Dictionary] = []

	for dev in detected_devices:
		if dev.get("type", "") == "CPU":
			cpu_devices.append(dev)
		else:
			gpu_devices.append(dev)

	var ordered_devices: Array[Dictionary] = []
	ordered_devices.append_array(gpu_devices)
	ordered_devices.append_array(cpu_devices)

	# 3. Instantiate 3D Rack Units
	for i in range(ordered_devices.size()):
		var dev = ordered_devices[i]
		var dev_id: int = dev.get("id", 1)
		var dev_name: String = dev.get("name", "Device #" + str(dev_id))
		var dev_type: String = dev.get("type", "GPU")
		var is_cpu: bool = (dev_type == "CPU")
		var default_enabled: bool = dev.get("enabled", true)

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
	# 4 Corner Vertical Posts (I-Beam material)
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
		post.material_override = MAT_FRAME
		post.position = pos
		add_child(post)

	# Top and Bottom Heavy Plates
	for y in [bottom_y, top_y]:
		var plate = MeshInstance3D.new()
		var plate_mesh = BoxMesh.new()
		plate_mesh.size = Vector3(2.7, 0.08, 1.3)
		plate.mesh = plate_mesh
		plate.material_override = MAT_FRAME
		plate.position = Vector3(0.0, y, 0.0)
		add_child(plate)

	# Side Panels (Left & Right)
	for side in [-1.0, 1.0]:
		var side_panel = MeshInstance3D.new()
		var sp_mesh = BoxMesh.new()
		sp_mesh.size = Vector3(0.04, height - 0.16, 1.15)
		side_panel.mesh = sp_mesh
		side_panel.material_override = MAT_PANEL
		side_panel.position = Vector3(side * (post_x + 0.02), center_y, 0.0)
		add_child(side_panel)

	# Top Diegetic Header Marquee
	var header_bar = MeshInstance3D.new()
	var h_mesh = BoxMesh.new()
	h_mesh.size = Vector3(2.5, 0.14, 0.06)
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color("#020617")
	h_mat.metallic = 0.9
	header_bar.mesh = h_mesh
	header_bar.material_override = h_mat
	header_bar.position = Vector3(0.0, top_y + 0.12, post_z + 0.02)
	add_child(header_bar)

	var header_lbl = Label3D.new()
	header_lbl.text = "PRIMARY COMPUTE CHASSIS // 4x GPU + 1x CPU"
	header_lbl.font_size = 20
	header_lbl.pixel_size = 0.0022
	header_lbl.modulate = Color("#00f0ff")
	header_lbl.outline_modulate = Color("#0369a1")
	header_lbl.outline_size = 3
	header_lbl.position = Vector3(0.0, top_y + 0.12, post_z + 0.06)
	add_child(header_lbl)

	# Internal Cool-Blue illumination
	_interior_light = OmniLight3D.new()
	_interior_light.light_color = Color("#00a8ff")
	_interior_light.light_energy = 1.2
	_interior_light.omni_range = 4.2
	_interior_light.position = Vector3(0.0, center_y, 0.4)
	add_child(_interior_light)

	# Physical solid collision body
	var rack_body = StaticBody3D.new()
	rack_body.name = "RackChassisCollision"
	rack_body.collision_layer = 1
	rack_body.collision_mask = 1

	var col_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(2.6, height, 0.7)
	col_shape.shape = box_shape
	col_shape.position = Vector3(0.0, center_y, -0.25)
	rack_body.add_child(col_shape)
	add_child(rack_body)
