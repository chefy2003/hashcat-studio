class_name RoomEnclosure3D
extends Node3D

## High-Security Operations Citadel Enclosure.
## Provides physical walls, structural ceiling I-beam trusses, ventilation turbines,
## heavy blast bulkhead gate, perimeter diamond-plate walkways, and physical collision bounds.

const MAT_WALL = preload("res://materials/se_metal/metalhull02.tres")
const MAT_CEILING = preload("res://materials/se_metal/metalhull01.tres")
const MAT_BEAM = preload("res://materials/se_metal/quarryibeama.tres")
const MAT_GATE = preload("res://materials/se_metal/gate.tres")
const MAT_WALKWAY = preload("res://materials/se_metal/sg_metalfloor001.tres")

# Arena Dimensions
const ROOM_WIDTH: float = 18.4   # X: -9.2 to +9.2
const ROOM_DEPTH: float = 15.5   # Z: -7.8 to +7.7
const ROOM_HEIGHT: float = 6.2   # Y: 0.0 to 6.2
const WALL_THICKNESS: float = 0.4

var _fan_blades: Array[Node3D] = []
var _fan_speed: float = 3.2

func _ready() -> void:
	_build_room_geometry()
	_build_roof_trusses()
	_build_north_ventilation()
	_build_south_bulkhead_gate()
	_build_perimeter_walkways()
	_build_collision_bounds()

func _process(delta: float) -> void:
	for fan in _fan_blades:
		if is_instance_valid(fan):
			fan.rotate_z(_fan_speed * delta)

func _build_room_geometry() -> void:
	var half_w = ROOM_WIDTH * 0.5
	var half_d = ROOM_DEPTH * 0.5
	var half_h = ROOM_HEIGHT * 0.5

	# North Wall (Z = -half_d)
	_create_wall_segment(Vector3(0, half_h, -half_d - WALL_THICKNESS * 0.5), Vector3(ROOM_WIDTH, ROOM_HEIGHT, WALL_THICKNESS), MAT_WALL)
	# South Wall (Z = +half_d)
	_create_wall_segment(Vector3(0, half_h, half_d + WALL_THICKNESS * 0.5), Vector3(ROOM_WIDTH, ROOM_HEIGHT, WALL_THICKNESS), MAT_WALL)
	# West Wall (X = -half_w)
	_create_wall_segment(Vector3(-half_w - WALL_THICKNESS * 0.5, half_h, 0), Vector3(WALL_THICKNESS, ROOM_HEIGHT, ROOM_DEPTH), MAT_WALL)
	# East Wall (X = +half_w)
	_create_wall_segment(Vector3(half_w + WALL_THICKNESS * 0.5, half_h, 0), Vector3(WALL_THICKNESS, ROOM_HEIGHT, ROOM_DEPTH), MAT_WALL)

	# Ceiling (Y = ROOM_HEIGHT)
	var ceiling_mesh = BoxMesh.new()
	ceiling_mesh.size = Vector3(ROOM_WIDTH + 1.0, WALL_THICKNESS, ROOM_DEPTH + 1.0)
	ceiling_mesh.material = MAT_CEILING
	var ceiling_inst = MeshInstance3D.new()
	ceiling_inst.name = "Ceiling"
	ceiling_inst.mesh = ceiling_mesh
	ceiling_inst.position = Vector3(0, ROOM_HEIGHT + WALL_THICKNESS * 0.5, 0)
	add_child(ceiling_inst)

func _create_wall_segment(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var inst = MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	add_child(inst)
	return inst

func _build_roof_trusses() -> void:
	var truss_count = 5
	var z_step = (ROOM_DEPTH - 2.0) / float(truss_count - 1)
	var start_z = -ROOM_DEPTH * 0.5 + 1.0

	for i in range(truss_count):
		var z_pos = start_z + float(i) * z_step
		# Main Cross Beam (spans across X)
		var beam_mesh = BoxMesh.new()
		beam_mesh.size = Vector3(ROOM_WIDTH, 0.45, 0.3)
		beam_mesh.material = MAT_BEAM
		var beam = MeshInstance3D.new()
		beam.name = "TrussBeam_%d" % i
		beam.mesh = beam_mesh
		beam.position = Vector3(0, ROOM_HEIGHT - 0.35, z_pos)
		add_child(beam)

		# Vertical supports on left and right walls
		for side in [-1.0, 1.0]:
			var col_mesh = BoxMesh.new()
			col_mesh.size = Vector3(0.35, ROOM_HEIGHT, 0.35)
			col_mesh.material = MAT_BEAM
			var col = MeshInstance3D.new()
			col.mesh = col_mesh
			col.position = Vector3(side * (ROOM_WIDTH * 0.5 - 0.18), ROOM_HEIGHT * 0.5, z_pos)
			add_child(col)

		# Diagonal support brackets
		for side in [-1.0, 1.0]:
			var bracket = MeshInstance3D.new()
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(1.2, 0.15, 0.2)
			b_mesh.material = MAT_BEAM
			bracket.mesh = b_mesh
			bracket.position = Vector3(side * (ROOM_WIDTH * 0.5 - 0.7), ROOM_HEIGHT - 0.7, z_pos)
			bracket.rotation_degrees = Vector3(0, 0, -side * 35.0)
			add_child(bracket)

func _build_north_ventilation() -> void:
	# Twin industrial ventilation turbines on the North wall (Z = -ROOM_DEPTH * 0.5)
	var fan_x_offsets = [-4.5, 4.5]
	var fan_y = 3.6
	var wall_z = -ROOM_DEPTH * 0.5 + 0.15

	for i in range(fan_x_offsets.size()):
		var fx = fan_x_offsets[i]

		# Outer circular duct frame (hexagonal / cylinder casing)
		var casing = MeshInstance3D.new()
		var c_mesh = CylinderMesh.new()
		c_mesh.top_radius = 1.15
		c_mesh.bottom_radius = 1.15
		c_mesh.height = 0.35
		c_mesh.radial_segments = 16
		c_mesh.material = MAT_BEAM
		casing.mesh = c_mesh
		casing.position = Vector3(fx, fan_y, wall_z)
		casing.rotation_degrees = Vector3(90, 0, 0)
		add_child(casing)

		# Emissive warning rim inside casing
		var rim = MeshInstance3D.new()
		var r_mesh = TorusMesh.new()
		r_mesh.inner_radius = 0.98
		r_mesh.outer_radius = 1.12
		var r_mat = StandardMaterial3D.new()
		r_mat.albedo_color = Color("#0f172a")
		r_mat.emission_enabled = true
		r_mat.emission = Color("#00f0ff")
		r_mat.emission_energy_multiplier = 1.8
		rim.mesh = r_mesh
		rim.position = Vector3(fx, fan_y, wall_z + 0.08)
		rim.rotation_degrees = Vector3(90, 0, 0)
		add_child(rim)

		# Rotating blade hub & assembly
		var fan_hub = Node3D.new()
		fan_hub.name = "VentTurbine_%d" % i
		fan_hub.position = Vector3(fx, fan_y, wall_z + 0.05)
		add_child(fan_hub)

		# Central axle cap
		var hub_cap = MeshInstance3D.new()
		var h_mesh = CylinderMesh.new()
		h_mesh.top_radius = 0.28
		h_mesh.bottom_radius = 0.28
		h_mesh.height = 0.2
		h_mesh.material = MAT_WALL
		hub_cap.mesh = h_mesh
		hub_cap.rotation_degrees = Vector3(90, 0, 0)
		fan_hub.add_child(hub_cap)

		# 6 turbine blades
		var blade_mat = StandardMaterial3D.new()
		blade_mat.albedo_color = Color("#1e293b")
		blade_mat.metallic = 0.85
		blade_mat.roughness = 0.25

		for b in range(6):
			var blade = MeshInstance3D.new()
			var b_mesh = BoxMesh.new()
			b_mesh.size = Vector3(0.18, 0.72, 0.04)
			b_mesh.material = blade_mat
			blade.mesh = b_mesh
			blade.position = Vector3(0, 0.45, 0)
			blade.rotation_degrees = Vector3(0, 18, 0)

			var blade_pivot = Node3D.new()
			blade_pivot.rotation_degrees = Vector3(0, 0, float(b) * 60.0)
			blade_pivot.add_child(blade)
			fan_hub.add_child(blade_pivot)

		_fan_blades.append(fan_hub)

func _build_south_bulkhead_gate() -> void:
	# Heavy airlock blast door on South wall (Z = +ROOM_DEPTH * 0.5)
	var half_d = ROOM_DEPTH * 0.5
	var wall_z = half_d - 0.25
	var gate_width = 4.0
	var gate_height = 4.2

	# Door Frame Pillars (Heavier structural I-Beams)
	for side in [-1.0, 1.0]:
		var frame_col = MeshInstance3D.new()
		var col_mesh = BoxMesh.new()
		col_mesh.size = Vector3(0.55, gate_height + 0.5, 0.6)
		col_mesh.material = MAT_BEAM
		frame_col.mesh = col_mesh
		frame_col.position = Vector3(side * (gate_width * 0.5 + 0.28), gate_height * 0.5, wall_z - 0.1)
		add_child(frame_col)

		# Vertical hazard strip on pillar
		var stripe = MeshInstance3D.new()
		var st_mesh = BoxMesh.new()
		st_mesh.size = Vector3(0.10, gate_height, 0.04)
		var st_mat = StandardMaterial3D.new()
		st_mat.albedo_color = Color("#f59e0b")
		st_mat.emission_enabled = true
		st_mat.emission = Color("#f59e0b")
		st_mat.emission_energy_multiplier = 2.0
		stripe.mesh = st_mesh
		stripe.material_override = st_mat
		stripe.position = Vector3(side * (gate_width * 0.5 + 0.1), gate_height * 0.5, wall_z - 0.42)
		add_child(stripe)

	# Door Lintel / Top Header
	var header = MeshInstance3D.new()
	var h_mesh = BoxMesh.new()
	h_mesh.size = Vector3(gate_width + 1.2, 0.6, 0.65)
	h_mesh.material = MAT_BEAM
	header.mesh = h_mesh
	header.position = Vector3(0, gate_height + 0.3, wall_z - 0.1)
	add_child(header)

	# Blast Door Panel (using gate.tres) positioned proud of wall
	var door_panel = MeshInstance3D.new()
	var d_mesh = BoxMesh.new()
	d_mesh.size = Vector3(gate_width, gate_height, 0.18)
	d_mesh.material = MAT_GATE
	door_panel.mesh = d_mesh
	door_panel.position = Vector3(0, gate_height * 0.5, wall_z - 0.08)
	add_child(door_panel)

	# Overhead high-intensity linear light fixture
	var lamp = MeshInstance3D.new()
	var l_mesh = BoxMesh.new()
	l_mesh.size = Vector3(2.8, 0.14, 0.25)
	var l_mat = StandardMaterial3D.new()
	l_mat.albedo_color = Color("#030712")
	l_mat.emission_enabled = true
	l_mat.emission = Color("#e2e8f0")
	l_mat.emission_energy_multiplier = 3.5
	lamp.mesh = l_mesh
	lamp.material_override = l_mat
	lamp.position = Vector3(0, gate_height + 0.35, wall_z - 0.45)
	add_child(lamp)

	# Status indicator bar above gate (Green Secure)
	var status_mesh = BoxMesh.new()
	status_mesh.size = Vector3(1.8, 0.14, 0.1)
	var s_mat = StandardMaterial3D.new()
	s_mat.albedo_color = Color("#0f172a")
	s_mat.emission_enabled = true
	s_mat.emission = Color("#10b981") # Secure green
	s_mat.emission_energy_multiplier = 2.4
	status_mesh.material = s_mat
	var status_inst = MeshInstance3D.new()
	status_inst.mesh = status_mesh
	status_inst.position = Vector3(0, gate_height + 0.65, wall_z - 0.42)
	add_child(status_inst)

	# Text signage above gate
	var gate_lbl = Label3D.new()
	gate_lbl.text = "AIRLOCK BULKHEAD // RESTRICTED ACCESS"
	gate_lbl.font_size = 24
	gate_lbl.pixel_size = 0.0028
	gate_lbl.modulate = Color("#00f0ff")
	gate_lbl.outline_modulate = Color("#0369a1")
	gate_lbl.outline_size = 4
	gate_lbl.position = Vector3(0, gate_height + 0.9, wall_z - 0.42)
	add_child(gate_lbl)

func _build_perimeter_walkways() -> void:
	# Diamond-plate steel border walkways with neon edge strip
	var half_w = ROOM_WIDTH * 0.5
	var half_d = ROOM_DEPTH * 0.5
	var border_w = 0.85
	var step_h = 0.05

	# Strip emission material
	var strip_mat = StandardMaterial3D.new()
	strip_mat.albedo_color = Color("#0f172a")
	strip_mat.emission_enabled = true
	strip_mat.emission = Color("#00f0ff")
	strip_mat.emission_energy_multiplier = 1.4

	# North Walkway
	_create_walkway_segment(Vector3(0, step_h * 0.5, -half_d + border_w * 0.5), Vector3(ROOM_WIDTH, step_h, border_w))
	_create_strip(Vector3(0, step_h + 0.01, -half_d + border_w), Vector3(ROOM_WIDTH, 0.01, 0.04), strip_mat)

	# South Walkway
	_create_walkway_segment(Vector3(0, step_h * 0.5, half_d - border_w * 0.5), Vector3(ROOM_WIDTH, step_h, border_w))
	_create_strip(Vector3(0, step_h + 0.01, half_d - border_w), Vector3(ROOM_WIDTH, 0.01, 0.04), strip_mat)

	# West Walkway
	_create_walkway_segment(Vector3(-half_w + border_w * 0.5, step_h * 0.5, 0), Vector3(border_w, step_h, ROOM_DEPTH - border_w * 2.0))
	_create_strip(Vector3(-half_w + border_w, step_h + 0.01, 0), Vector3(0.04, 0.01, ROOM_DEPTH - border_w * 2.0), strip_mat)

	# East Walkway
	_create_walkway_segment(Vector3(half_w - border_w * 0.5, step_h * 0.5, 0), Vector3(border_w, step_h, ROOM_DEPTH - border_w * 2.0))
	_create_strip(Vector3(half_w - border_w, step_h + 0.01, 0), Vector3(0.04, 0.01, ROOM_DEPTH - border_w * 2.0), strip_mat)

func _create_walkway_segment(pos: Vector3, size: Vector3) -> void:
	var mesh = BoxMesh.new()
	mesh.size = size
	mesh.material = MAT_WALKWAY
	var inst = MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	add_child(inst)

func _create_strip(pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh = BoxMesh.new()
	mesh.size = size
	mesh.material = mat
	var inst = MeshInstance3D.new()
	inst.mesh = mesh
	inst.position = pos
	add_child(inst)

func _build_collision_bounds() -> void:
	var static_body = StaticBody3D.new()
	static_body.name = "CitadelRoomBoundaries"
	add_child(static_body)

	var half_w = ROOM_WIDTH * 0.5
	var half_d = ROOM_DEPTH * 0.5
	var half_h = ROOM_HEIGHT * 0.5

	# North Collision
	_add_wall_collision(static_body, Vector3(0, half_h, -half_d), Vector3(ROOM_WIDTH, ROOM_HEIGHT, 0.5))
	# South Collision
	_add_wall_collision(static_body, Vector3(0, half_h, half_d), Vector3(ROOM_WIDTH, ROOM_HEIGHT, 0.5))
	# West Collision
	_add_wall_collision(static_body, Vector3(-half_w, half_h, 0), Vector3(0.5, ROOM_HEIGHT, ROOM_DEPTH))
	# East Collision
	_add_wall_collision(static_body, Vector3(half_w, half_h, 0), Vector3(0.5, ROOM_HEIGHT, ROOM_DEPTH))

func _add_wall_collision(body: StaticBody3D, pos: Vector3, size: Vector3) -> void:
	var col_shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = size
	col_shape.shape = box
	col_shape.position = pos
	body.add_child(col_shape)
