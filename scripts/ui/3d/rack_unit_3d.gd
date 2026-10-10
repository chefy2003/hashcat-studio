class_name RackUnit3D
extends Node3D

## 3D Hardware Compute Unit (GPU Card / CPU NUMA Node)
## Handles dynamic fan rotation, real-time LED emission based on thermal telemetry,
## and interactive ON/OFF power toggling via direct 3D clicks or HUD control.

signal unit_clicked(dev_id: int)
signal unit_toggled(dev_id: int, enabled: bool)

@export var device_id: int = 1
@export var device_name: String = "GPU #1 [RX 480]"
@export var is_cpu: bool = false
@export var is_enabled: bool = true

var current_temp: float = 45.0
var current_fan_percent: float = 30.0
var current_util_percent: float = 0.0

var _body_mesh: MeshInstance3D
var _body_mat: StandardMaterial3D
var _fan1_mesh: MeshInstance3D
var _fan2_mesh: MeshInstance3D
var _led_strip: MeshInstance3D
var _status_led: MeshInstance3D
var _led_material: StandardMaterial3D
var _status_material: StandardMaterial3D
var _lbl_telemetry: Label3D
var _hit_area: Area3D

func _ready() -> void:
	_build_chassis_geometry()
	_build_unit_label()
	_build_collision_area()
	_update_leds()
	_update_label_text()

func setup_device(p_id: int, p_name: String, p_is_cpu: bool = false, p_enabled: bool = true) -> void:
	device_id = p_id
	device_name = p_name
	is_cpu = p_is_cpu
	is_enabled = p_enabled
	if is_cpu and _fan2_mesh:
		_fan2_mesh.visible = false # Single fan for CPU cooler
	_update_leds()
	_update_label_text()

func set_device_enabled(p_enabled: bool) -> void:
	is_enabled = p_enabled
	_update_leds()
	_update_label_text()

func set_telemetry(temp_celsius: float, fan_pct: float, util_pct: float) -> void:
	current_temp = temp_celsius
	current_fan_percent = fan_pct
	current_util_percent = util_pct
	_update_leds()
	_update_label_text()

func _update_label_text() -> void:
	if _lbl_telemetry:
		if is_enabled:
			_lbl_telemetry.text = "%s  |  %.0f°C  |  FAN %.0f%%  |  LOAD %.0f%%" % [device_name, current_temp, current_fan_percent, current_util_percent]
			_lbl_telemetry.modulate = Color("#e2e8f0")
		else:
			_lbl_telemetry.text = "[%s - ИЗКЛЮЧЕНО / STANDBY]" % device_name
			_lbl_telemetry.modulate = Color("#64748b")

func _process(delta: float) -> void:
	if not is_enabled:
		return # Fans completely stopped when disabled

	# Rotate fans dynamically based on fan percentage
	var speed_multiplier: float = max(current_fan_percent, 15.0) * 0.1
	var rotation_step: float = speed_multiplier * delta * 25.0

	if _fan1_mesh:
		_fan1_mesh.rotate_z(rotation_step)
	if _fan2_mesh and not is_cpu:
		_fan2_mesh.rotate_z(rotation_step)

func _update_leds() -> void:
	if not _led_material or not _status_material:
		return

	if not is_enabled:
		_led_material.albedo_color = Color("#151d28") # Dark unpowered acrylic
		_led_material.emission_enabled = false
		_status_material.albedo_color = Color("#1e293b")
		_status_material.emission_enabled = false
		return

	# Color scale: Emerald (<55C) -> Amber (55-72C) -> Crimson (>72C)
	var led_color: Color
	if current_temp < 55.0:
		var t = clamp((current_temp - 30.0) / 25.0, 0.0, 1.0)
		led_color = Color("#10b981").lerp(Color("#06b6d4"), t * 0.4)
	elif current_temp < 72.0:
		var t = clamp((current_temp - 55.0) / 17.0, 0.0, 1.0)
		led_color = Color("#10b981").lerp(Color("#f59e0b"), t)
	else:
		var t = clamp((current_temp - 72.0) / 15.0, 0.0, 1.0)
		led_color = Color("#f59e0b").lerp(Color("#ef4444"), t)

	_led_material.albedo_color = led_color
	_led_material.emission_enabled = true
	_led_material.emission = led_color
	_led_material.emission_energy_multiplier = 1.8

	# Activity status LED
	_status_material.emission_enabled = true
	if current_util_percent > 5.0:
		_status_material.albedo_color = Color("#00f0ff")
		_status_material.emission = Color("#00f0ff")
		_status_material.emission_energy_multiplier = 1.8
	else:
		var col = Color("#10b981") if is_cpu else Color("#00f0ff")
		_status_material.albedo_color = col
		_status_material.emission = col
		_status_material.emission_energy_multiplier = 0.8


func _build_unit_label() -> void:
	_lbl_telemetry = Label3D.new()
	_lbl_telemetry.font_size = 20
	_lbl_telemetry.pixel_size = 0.0028
	_lbl_telemetry.modulate = Color("#e2e8f0")
	_lbl_telemetry.outline_modulate = Color("#07090e")
	_lbl_telemetry.outline_size = 4
	_lbl_telemetry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_telemetry.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_telemetry.position = Vector3(0.0, -0.04, 0.58)
	add_child(_lbl_telemetry)

func _build_chassis_geometry() -> void:
	# 1. Main GPU/Card Body (Dark Slate Titanium)
	_body_mesh = MeshInstance3D.new()
	var body_box = BoxMesh.new()
	body_box.size = Vector3(2.4, 0.35, 1.1)
	_body_mesh.mesh = body_box

	_body_mat = StandardMaterial3D.new()
	_body_mat.albedo_color = Color("#0d1321")
	_body_mat.metallic = 0.85
	_body_mat.roughness = 0.25
	_body_mesh.material_override = _body_mat
	add_child(_body_mesh)

	# 2. Heatsink Shroud (Elevated Brushed Metal)
	var shroud = MeshInstance3D.new()
	var shroud_box = BoxMesh.new()
	shroud_box.size = Vector3(2.2, 0.08, 0.95)
	shroud.mesh = shroud_box
	shroud.position = Vector3(0.0, 0.18, 0.0)

	var shroud_mat = StandardMaterial3D.new()
	shroud_mat.albedo_color = Color("#151f32")
	shroud_mat.metallic = 0.9
	shroud_mat.roughness = 0.35
	shroud.material_override = shroud_mat
	add_child(shroud)

	# 3. Dynamic Thermal LED Strip along front face
	_led_strip = MeshInstance3D.new()
	var strip_box = BoxMesh.new()
	strip_box.size = Vector3(2.1, 0.04, 0.04)
	_led_strip.mesh = strip_box
	_led_strip.position = Vector3(0.0, 0.08, 0.56)

	_led_material = StandardMaterial3D.new()
	_led_material.albedo_color = Color("#10b981")
	_led_material.emission_enabled = true
	_led_material.emission = Color("#10b981")
	_led_material.emission_energy_multiplier = 2.0
	_led_strip.material_override = _led_material
	add_child(_led_strip)

	# 4. Activity status indicator dot
	_status_led = MeshInstance3D.new()
	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = 0.04
	dot_mesh.height = 0.08
	_status_led.mesh = dot_mesh
	_status_led.position = Vector3(1.1, 0.1, 0.56)

	_status_material = StandardMaterial3D.new()
	_status_material.albedo_color = Color("#00f0ff")
	_status_material.emission_enabled = true
	_status_material.emission = Color("#00f0ff")
	_status_material.emission_energy_multiplier = 1.2
	_status_led.material_override = _status_material
	add_child(_status_led)

	# 5. Cooling Fans
	_fan1_mesh = _create_fan_mesh()
	_fan1_mesh.position = Vector3(-0.55, 0.23, 0.0)
	add_child(_fan1_mesh)

	_fan2_mesh = _create_fan_mesh()
	_fan2_mesh.position = Vector3(0.55, 0.23, 0.0)
	add_child(_fan2_mesh)

func _create_fan_mesh() -> MeshInstance3D:
	var fan_root = MeshInstance3D.new()
	var hub = CylinderMesh.new()
	hub.top_radius = 0.12
	hub.bottom_radius = 0.12
	hub.height = 0.04
	fan_root.mesh = hub

	var hub_mat = StandardMaterial3D.new()
	hub_mat.albedo_color = Color("#05080e")
	hub_mat.metallic = 0.5
	hub_mat.roughness = 0.5
	fan_root.material_override = hub_mat

	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var blade = MeshInstance3D.new()
		var blade_mesh = BoxMesh.new()
		blade_mesh.size = Vector3(0.38, 0.015, 0.08)
		blade.mesh = blade_mesh
		blade.material_override = hub_mat
		blade.position = Vector3(cos(angle) * 0.22, 0.0, sin(angle) * 0.22)
		blade.rotation.y = angle
		fan_root.add_child(blade)

	return fan_root

func _build_collision_area() -> void:
	_hit_area = Area3D.new()
	_hit_area.collision_layer = 1 # UI_Panels
	_hit_area.collision_mask = 1

	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.4, 0.38, 1.15)
	shape.shape = box
	_hit_area.add_child(shape)

	_hit_area.input_event.connect(_on_hit_area_input)
	_hit_area.mouse_entered.connect(_on_mouse_hover_enter)
	_hit_area.mouse_exited.connect(_on_mouse_hover_exit)
	add_child(_hit_area)

func _on_hit_area_input(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		set_device_enabled(not is_enabled)
		unit_clicked.emit(device_id)
		unit_toggled.emit(device_id, is_enabled)

func _on_mouse_hover_enter() -> void:
	if _body_mat:
		_body_mat.emission_enabled = true
		_body_mat.emission = Color("#00a8ff")
		_body_mat.emission_energy_multiplier = 0.25

func _on_mouse_hover_exit() -> void:
	if _body_mat:
		_body_mat.emission_enabled = false
