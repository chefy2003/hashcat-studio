class_name RackUnit3D
extends Node3D

## High-Performance 3D Hardware Compute Unit (GPU Card / CPU NUMA Node).
## Front-facing dual high-speed cooling turbines, exposed heatsink fins,
## OLED telemetry display badge, dynamic thermal LED lightbar, and interactive power toggle.

signal unit_clicked(dev_id: int)
signal unit_toggled(dev_id: int, enabled: bool)

@export var device_id: int = 1
@export var device_name: String = "GPU #1 [AMD Radeon Graphics]"
@export var is_cpu: bool = false
@export var is_enabled: bool = true

var current_temp: float = 45.0
var current_fan_percent: float = 30.0
var current_util_percent: float = 0.0

var _body_mesh: MeshInstance3D
var _body_mat: StandardMaterial3D
var _fan1_mesh: Node3D
var _fan2_mesh: Node3D
var _led_strip: MeshInstance3D
var _status_led: MeshInstance3D
var _led_material: StandardMaterial3D
var _status_material: StandardMaterial3D
var _lbl_telemetry: Label3D
var _interactable_body: Interactable3D

func _ready() -> void:
	_build_chassis_geometry()
	_build_unit_label()
	_build_collision_area()
	_update_leds()
	_update_label_text()
	_update_interactable_prompt()

func setup_device(p_id: int, p_name: String, p_is_cpu: bool = false, p_enabled: bool = true) -> void:
	device_id = p_id
	device_name = p_name
	is_cpu = p_is_cpu
	is_enabled = p_enabled
	if _interactable_body:
		_interactable_body.name = "UnitInteractable_%d" % device_id
	if is_cpu and _fan2_mesh:
		_fan2_mesh.visible = false
	_update_leds()
	_update_label_text()
	_update_interactable_prompt()

func set_device_enabled(p_enabled: bool) -> void:
	is_enabled = p_enabled
	_update_leds()
	_update_label_text()
	_update_interactable_prompt()

func set_telemetry(temp_celsius: float, fan_pct: float, util_pct: float) -> void:
	current_temp = temp_celsius
	current_fan_percent = fan_pct
	current_util_percent = util_pct
	_update_leds()
	_update_label_text()

func _update_label_text() -> void:
	if _lbl_telemetry:
		if is_enabled:
			var prefix = "CPU #%d" % device_id if is_cpu else "GPU #%d" % device_id
			var short_name = "Intel Xeon" if is_cpu else "Radeon MI25"
			_lbl_telemetry.text = "%s [%s]\n%.0f°C  •  FAN %.0f%%  •  LOAD %.0f%%" % [prefix, short_name, current_temp, current_fan_percent, current_util_percent]
			_lbl_telemetry.modulate = Color("#00f0ff")
		else:
			var prefix = "CPU #%d" % device_id if is_cpu else "GPU #%d" % device_id
			_lbl_telemetry.text = "%s [STANDBY]\n[ИЗКЛЮЧЕНО]" % prefix
			_lbl_telemetry.modulate = Color("#ef4444")

func _process(delta: float) -> void:
	if not is_enabled:
		var pulse: float = (sin(Time.get_ticks_msec() * 0.005 + float(device_id) * 0.7) * 0.5 + 0.5)
		var red_color: Color = Color("#dc2626")

		if _led_material:
			_led_material.albedo_color = red_color.darkened(0.4)
			_led_material.emission_enabled = true
			_led_material.emission = red_color
			_led_material.emission_energy_multiplier = 0.5 + pulse * 0.8

		if _status_material:
			_status_material.albedo_color = red_color
			_status_material.emission_enabled = true
			_status_material.emission = red_color
			_status_material.emission_energy_multiplier = 0.6 + pulse * 0.8

		if _lbl_telemetry:
			_lbl_telemetry.modulate = Color("#ef4444").lerp(Color("#fca5a5"), pulse * 0.5)

		return

	# Rotate front-facing fans dynamically in the XY plane
	var speed_multiplier: float = max(current_fan_percent, 18.0) * 0.12
	var rotation_step: float = speed_multiplier * delta * 20.0

	if _fan1_mesh:
		var r1 = _fan1_mesh.get_node_or_null("Rotor")
		if r1:
			r1.rotate_z(rotation_step)
	if _fan2_mesh and not is_cpu:
		var r2 = _fan2_mesh.get_node_or_null("Rotor")
		if r2:
			r2.rotate_z(rotation_step)

func _update_leds() -> void:
	if not _led_material or not _status_material:
		return

	if not is_enabled:
		var red_color: Color = Color("#ff1744")
		_led_material.albedo_color = red_color.darkened(0.3)
		_led_material.emission_enabled = true
		_led_material.emission = red_color
		_led_material.emission_energy_multiplier = 1.2
		_status_material.albedo_color = red_color
		_status_material.emission_enabled = true
		_status_material.emission = red_color
		_status_material.emission_energy_multiplier = 1.5
		return

	# Color scale: Emerald (<55C) -> Amber (55-72C) -> Crimson (>72C)
	var led_color: Color
	if current_temp < 55.0:
		var t = clamp((current_temp - 30.0) / 25.0, 0.0, 1.0)
		led_color = Color("#10b981").lerp(Color("#00f0ff"), t * 0.5)
	elif current_temp < 72.0:
		var t = clamp((current_temp - 55.0) / 17.0, 0.0, 1.0)
		led_color = Color("#10b981").lerp(Color("#f59e0b"), t)
	else:
		var t = clamp((current_temp - 72.0) / 15.0, 0.0, 1.0)
		led_color = Color("#f59e0b").lerp(Color("#ef4444"), t)

	_led_material.albedo_color = led_color
	_led_material.emission_enabled = true
	_led_material.emission = led_color
	_led_material.emission_energy_multiplier = 2.4

	_status_material.emission_enabled = true
	if current_util_percent > 5.0:
		_status_material.albedo_color = Color("#00f0ff")
		_status_material.emission = Color("#00f0ff")
		_status_material.emission_energy_multiplier = 3.2
	else:
		var col = Color("#10b981") if is_cpu else Color("#00f0ff")
		_status_material.albedo_color = col
		_status_material.emission = col
		_status_material.emission_energy_multiplier = 1.6

func _build_unit_label() -> void:
	_lbl_telemetry = Label3D.new()
	_lbl_telemetry.font_size = 20
	_lbl_telemetry.pixel_size = 0.0022
	_lbl_telemetry.modulate = Color("#00f0ff")
	_lbl_telemetry.outline_modulate = Color("#020617")
	_lbl_telemetry.outline_size = 4
	_lbl_telemetry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_telemetry.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_telemetry.position = Vector3(0.0, 0.0, 0.55)
	add_child(_lbl_telemetry)

func _build_chassis_geometry() -> void:
	# 1. Main Card Chassis (Titanium Server Blade)
	_body_mesh = MeshInstance3D.new()
	var body_box = BoxMesh.new()
	body_box.size = Vector3(2.36, 0.30, 1.0)
	_body_mesh.mesh = body_box

	_body_mat = StandardMaterial3D.new()
	_body_mat.albedo_color = Color("#0b111e")
	_body_mat.metallic = 0.92
	_body_mat.roughness = 0.22
	_body_mesh.material_override = _body_mat
	add_child(_body_mesh)

	# 2. Aluminum Base Shelf Plate with Rail Guides
	var shelf = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(2.5, 0.03, 1.05)
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color("#1e293b")
	s_mat.metallic = 0.95
	s_mat.roughness = 0.18
	shelf.mesh = s_mesh
	shelf.material_override = s_mat
	shelf.position = Vector3(0.0, -0.16, 0.0)
	add_child(shelf)

	# 3. Dynamic Thermal Lightbar across top front edge
	_led_strip = MeshInstance3D.new()
	var strip_box = BoxMesh.new()
	strip_box.size = Vector3(2.25, 0.025, 0.025)
	_led_strip.mesh = strip_box
	_led_strip.position = Vector3(0.0, 0.135, 0.51)

	_led_material = StandardMaterial3D.new()
	_led_material.albedo_color = Color("#10b981")
	_led_material.emission_enabled = true
	_led_material.emission = Color("#10b981")
	_led_material.emission_energy_multiplier = 2.4
	_led_strip.material_override = _led_material
	add_child(_led_strip)

	# 4. Center Front Telemetry OLED Display Panel
	var oled_bg = MeshInstance3D.new()
	var o_box = BoxMesh.new()
	o_box.size = Vector3(0.85, 0.22, 0.02)
	var o_mat = StandardMaterial3D.new()
	o_mat.albedo_color = Color("#020617")
	o_mat.metallic = 0.8
	o_mat.roughness = 0.2
	oled_bg.mesh = o_box
	oled_bg.material_override = o_mat
	oled_bg.position = Vector3(0.0, 0.0, 0.52)
	add_child(oled_bg)

	# 5. Dual FRONT-FACING Cooling Fans (XY Plane)
	_fan1_mesh = _create_front_fan_assembly()
	_fan1_mesh.position = Vector3(-0.65, 0.0, 0.52)
	add_child(_fan1_mesh)

	_fan2_mesh = _create_front_fan_assembly()
	_fan2_mesh.position = Vector3(0.65, 0.0, 0.52)
	add_child(_fan2_mesh)

	# 6. PCI-E Power Status LEDs (Dual 8-Pin Connectors)
	for p_idx in [0, 1]:
		var p_conn = MeshInstance3D.new()
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(0.05, 0.035, 0.02)
		var p_mat = StandardMaterial3D.new()
		p_mat.albedo_color = Color("#030712")
		p_conn.mesh = p_mesh
		p_conn.material_override = p_mat
		p_conn.position = Vector3(0.98 + float(p_idx) * 0.07, 0.08, 0.52)
		add_child(p_conn)

		# Power status LED
		var p_led = MeshInstance3D.new()
		var l_mesh = BoxMesh.new()
		l_mesh.size = Vector3(0.012, 0.012, 0.01)
		var l_mat = StandardMaterial3D.new()
		l_mat.albedo_color = Color("#10b981")
		l_mat.emission_enabled = true
		l_mat.emission = Color("#10b981")
		l_mat.emission_energy_multiplier = 2.0
		p_led.mesh = l_mesh
		p_led.material_override = l_mat
		p_led.position = Vector3(0.98 + float(p_idx) * 0.07, 0.11, 0.525)
		add_child(p_led)

	# 7. Activity status indicator dot
	_status_led = MeshInstance3D.new()
	var dot_mesh = SphereMesh.new()
	dot_mesh.radius = 0.025
	dot_mesh.height = 0.05
	_status_led.mesh = dot_mesh
	_status_led.position = Vector3(1.13, 0.08, 0.525)

	_status_material = StandardMaterial3D.new()
	_status_material.albedo_color = Color("#00f0ff")
	_status_material.emission_enabled = true
	_status_material.emission = Color("#00f0ff")
	_status_material.emission_energy_multiplier = 1.6
	_status_led.material_override = _status_material
	add_child(_status_led)

func _create_front_fan_assembly() -> Node3D:
	var fan_root = Node3D.new()

	# Outer Shroud Ring (Bezel facing front)
	var shroud_ring = MeshInstance3D.new()
	var t_mesh = TorusMesh.new()
	t_mesh.inner_radius = 0.11
	t_mesh.outer_radius = 0.13
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color("#0f172a")
	t_mat.emission_enabled = true
	t_mat.emission = Color("#00f0ff")
	t_mat.emission_energy_multiplier = 0.8
	shroud_ring.mesh = t_mesh
	shroud_ring.material_override = t_mat
	shroud_ring.rotation_degrees = Vector3(90, 0, 0)
	fan_root.add_child(shroud_ring)

	# Rotating Rotor Hub & Blades
	var rotor = Node3D.new()
	rotor.name = "Rotor"
	fan_root.add_child(rotor)

	var hub = MeshInstance3D.new()
	var h_mesh = CylinderMesh.new()
	h_mesh.top_radius = 0.04
	h_mesh.bottom_radius = 0.04
	h_mesh.height = 0.02
	var h_mat = StandardMaterial3D.new()
	h_mat.albedo_color = Color("#1e293b")
	h_mat.metallic = 0.8
	hub.mesh = h_mesh
	hub.material_override = h_mat
	hub.rotation_degrees = Vector3(90, 0, 0)
	rotor.add_child(hub)

	# 6 Turbine blades
	var blade_mat = StandardMaterial3D.new()
	blade_mat.albedo_color = Color("#020617")
	blade_mat.metallic = 0.9
	blade_mat.roughness = 0.2

	for i in range(6):
		var angle = float(i) * (TAU / 6.0)
		var blade = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		b_mesh.size = Vector3(0.022, 0.08, 0.008)
		blade.mesh = b_mesh
		blade.material_override = blade_mat
		blade.position = Vector3(cos(angle) * 0.065, sin(angle) * 0.065, 0.0)
		blade.rotation_degrees = Vector3(0, 0, rad_to_deg(angle) + 20.0)
		rotor.add_child(blade)

	return fan_root

func _build_collision_area() -> void:
	var interactable_script = preload("res://scripts/ui/3d/interactable_3d.gd")
	_interactable_body = interactable_script.new()
	_interactable_body.name = "UnitInteractable_%d" % device_id
	_interactable_body.collision_layer = 1
	_interactable_body.collision_mask = 1
	_update_interactable_prompt()

	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(2.4, 0.32, 0.15)
	shape.shape = box
	shape.position = Vector3(0.0, 0.0, 0.52)
	_interactable_body.add_child(shape)

	_interactable_body.focused.connect(_on_mouse_hover_enter)
	_interactable_body.unfocused.connect(_on_mouse_hover_exit)
	_interactable_body.interacted.connect(func(_actor: Node3D):
		toggle_device()
	)
	_interactable_body.input_event.connect(_on_interactable_input)
	add_child(_interactable_body)

func _on_interactable_input(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle_device()

func toggle_device() -> void:
	set_device_enabled(not is_enabled)
	unit_clicked.emit(device_id)
	unit_toggled.emit(device_id, is_enabled)

func _update_interactable_prompt() -> void:
	if _interactable_body:
		var action_text = "Изключи " if is_enabled else "Включи "
		_interactable_body.prompt_message = action_text + device_name

func get_prompt() -> String:
	return ("Изключи " if is_enabled else "Включи ") + device_name

func interact(_actor: Node3D = null) -> void:
	toggle_device()

func _on_mouse_hover_enter() -> void:
	if _body_mat:
		_body_mat.emission_enabled = true
		_body_mat.emission = Color("#00a8ff")
		_body_mat.emission_energy_multiplier = 0.5

func _on_mouse_hover_exit() -> void:
	if _body_mat:
		_body_mat.emission_enabled = false
