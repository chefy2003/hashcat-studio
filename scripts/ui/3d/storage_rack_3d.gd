class_name StorageRack3D
extends Node3D

## High-Density NVMe Storage Array & Wordlist Vault (42U Chassis).
## Hosts 16 hot-swap NVMe drive sleds with individual I/O activity LEDs,
## diegetic 3D telemetry display showing read speeds and active files,
## and optical bus integration with data transfer conduits.

const MAT_PANEL = preload("res://materials/se_metal/metalhull02.tres")
const MAT_FRAME = preload("res://materials/se_metal/quarryibeama.tres")

const SLED_COLS: int = 4
const SLED_ROWS: int = 4
const TOTAL_SLEDS: int = 16

class DriveSled:
	var root: Node3D
	var mesh: MeshInstance3D
	var led_power: MeshInstance3D
	var led_activity: MeshInstance3D
	var mat_power: StandardMaterial3D
	var mat_activity: StandardMaterial3D
	var is_active: bool = false
	var activity_decay: float = 0.0

var _sleds: Array[DriveSled] = []
var _lbl_header: Label3D
var _lbl_status: Label3D
var _lbl_speed: Label3D
var _lbl_health: Label3D

var is_streaming: bool = false
var is_reading: bool = false
var _read_timer: float = 0.0
var _active_filename: String = ""
var _current_throughput: float = 0.0
var _target_throughput: float = 0.0
var _anim_clock: float = 0.0

func _ready() -> void:
	_build_chassis()
	_build_drive_bays()
	_build_telemetry_display()
	_build_optical_junction()
	_build_collision_box()

func _process(delta: float) -> void:
	_anim_clock += delta

	if is_reading:
		_read_timer -= delta
		if _read_timer <= 0.0:
			is_reading = false
			_target_throughput = 0.0 if not is_streaming else 1450.0
			if not is_streaming:
				_update_status_display("STATE: STANDBY", Color("#10b981"))

	if is_streaming:
		_target_throughput = 1650.0 + sin(_anim_clock * 4.0) * 320.0 + randf_range(-80.0, 80.0)
		_update_status_display("STATE: STREAMING // DATA BUS ACTIVE", Color("#38bdf8"))
	elif not is_reading:
		_target_throughput = 0.0

	_current_throughput = lerp(_current_throughput, _target_throughput, delta * 6.0)

	# Update Speed Label
	if _lbl_speed:
		if _current_throughput > 10.0:
			_lbl_speed.text = "THROUGHPUT: %.1f MB/s" % _current_throughput
			_lbl_speed.modulate = Color("#00f0ff")
		else:
			_lbl_speed.text = "THROUGHPUT: 0.0 MB/s (IDLE)"
			_lbl_speed.modulate = Color("#64748b")

	# Drive LED Simulation
	_update_drive_leds(delta)

func trigger_read_activity(file_path: String, duration: float = 2.8) -> void:
	is_reading = true
	_read_timer = duration
	_active_filename = file_path.get_file()
	if _active_filename.is_empty():
		_active_filename = file_path
	_target_throughput = 3840.0 + randf_range(-250.0, 350.0)
	_update_status_display("STATE: READING // " + _active_filename, Color("#f59e0b"))

	# Flash all drives immediately on burst start
	for sled in _sleds:
		sled.is_active = true
		sled.activity_decay = randf_range(0.2, 0.6)

func set_streaming(active: bool) -> void:
	is_streaming = active
	if is_streaming:
		_target_throughput = 1650.0
		_update_status_display("STATE: STREAMING // DATA BUS ACTIVE", Color("#38bdf8"))
	else:
		if not is_reading:
			_target_throughput = 0.0
			_update_status_display("STATE: STANDBY", Color("#10b981"))

func _update_status_display(text: String, col: Color) -> void:
	if _lbl_status:
		_lbl_status.text = text
		_lbl_status.modulate = col

func _update_drive_leds(delta: float) -> void:
	var drive_busy = is_reading or is_streaming

	for i in range(_sleds.size()):
		var sled = _sleds[i]

		# Power LED subtle breath
		var p_pulse = sin(_anim_clock * 2.5 + float(i) * 0.4) * 0.2 + 0.8
		sled.mat_power.emission_energy_multiplier = 1.2 * p_pulse

		# Activity LED logic
		if drive_busy:
			if sled.activity_decay > 0.0:
				sled.activity_decay -= delta
				if sled.activity_decay <= 0.0:
					sled.is_active = false
			else:
				# Random probability to fire I/O burst
				var fire_prob = 0.25 if is_streaming else 0.45
				if randf() < fire_prob:
					sled.is_active = true
					sled.activity_decay = randf_range(0.04, 0.14)
		else:
			sled.is_active = false
			sled.activity_decay = 0.0

		if sled.is_active:
			sled.mat_activity.emission_energy_multiplier = 2.8
			sled.mat_activity.emission = Color("#f59e0b") if is_reading else Color("#00f0ff")
		else:
			sled.mat_activity.emission_energy_multiplier = 0.0

func _build_chassis() -> void:
	var width = 1.25
	var height = 2.35
	var depth = 0.95

	# Corner Posts (4x)
	var post_w = 0.08
	var corners = [
		Vector3(-width * 0.5 + post_w * 0.5, height * 0.5, -depth * 0.5 + post_w * 0.5),
		Vector3(width * 0.5 - post_w * 0.5, height * 0.5, -depth * 0.5 + post_w * 0.5),
		Vector3(-width * 0.5 + post_w * 0.5, height * 0.5, depth * 0.5 - post_w * 0.5),
		Vector3(width * 0.5 - post_w * 0.5, height * 0.5, depth * 0.5 - post_w * 0.5)
	]
	for c_pos in corners:
		var post = MeshInstance3D.new()
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(post_w, height, post_w)
		p_mesh.material = MAT_FRAME
		post.mesh = p_mesh
		post.position = c_pos
		add_child(post)

	# Top and Bottom Plates
	for y_pos in [0.04, height - 0.04]:
		var plate = MeshInstance3D.new()
		var pl_mesh = BoxMesh.new()
		pl_mesh.size = Vector3(width, 0.08, depth)
		pl_mesh.material = MAT_FRAME
		plate.mesh = pl_mesh
		plate.position = Vector3(0, y_pos, 0)
		add_child(plate)

	# Side Panels (Left & Right)
	for side in [-1.0, 1.0]:
		var panel = MeshInstance3D.new()
		var pn_mesh = BoxMesh.new()
		pn_mesh.size = Vector3(0.04, height - 0.16, depth - 0.1)
		pn_mesh.material = MAT_PANEL
		panel.mesh = pn_mesh
		panel.position = Vector3(side * (width * 0.5 - 0.02), height * 0.5, 0)
		add_child(panel)

	# Rear Perforated Mesh / Plate
	var rear = MeshInstance3D.new()
	var r_mesh = BoxMesh.new()
	r_mesh.size = Vector3(width - 0.1, height - 0.16, 0.04)
	r_mesh.material = MAT_PANEL
	rear.mesh = r_mesh
	rear.position = Vector3(0, height * 0.5, -depth * 0.5 + 0.02)
	add_child(rear)

	# Internal subtle illumination
	var rack_light = OmniLight3D.new()
	rack_light.position = Vector3(0, 1.4, 0.1)
	rack_light.light_color = Color("#00f0ff")
	rack_light.light_energy = 0.65
	rack_light.omni_range = 2.4
	add_child(rack_light)

func _build_drive_bays() -> void:
	var bay_origin_y = 0.35
	var bay_spacing_y = 0.22
	var bay_spacing_x = 0.25
	var start_x = -((float(SLED_COLS) - 1.0) * bay_spacing_x) * 0.5
	var front_z = 0.95 * 0.5 - 0.12

	var sled_mat = StandardMaterial3D.new()
	sled_mat.albedo_color = Color("#111827")
	sled_mat.metallic = 0.9
	sled_mat.roughness = 0.2

	var handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color("#374151")
	handle_mat.metallic = 0.95
	handle_mat.roughness = 0.15

	for row in range(SLED_ROWS):
		var y_pos = bay_origin_y + float(row) * bay_spacing_y

		# Horizontal bay shelf plate
		var shelf = MeshInstance3D.new()
		var sh_mesh = BoxMesh.new()
		sh_mesh.size = Vector3(1.08, 0.02, 0.75)
		sh_mesh.material = MAT_FRAME
		shelf.mesh = sh_mesh
		shelf.position = Vector3(0, y_pos - 0.06, 0)
		add_child(shelf)

		for col in range(SLED_COLS):
			var x_pos = start_x + float(col) * bay_spacing_x
			var sled_obj = DriveSled.new()

			var sled_root = Node3D.new()
			sled_root.name = "Sled_R%d_C%d" % [row, col]
			sled_root.position = Vector3(x_pos, y_pos, front_z)
			add_child(sled_root)
			sled_obj.root = sled_root

			# Main sled body
			var sled_body = MeshInstance3D.new()
			var sb_mesh = BoxMesh.new()
			sb_mesh.size = Vector3(0.22, 0.11, 0.32)
			sb_mesh.material = sled_mat
			sled_body.mesh = sb_mesh
			sled_root.add_child(sled_body)
			sled_obj.mesh = sled_body

			# Release Latch / Handle
			var handle = MeshInstance3D.new()
			var h_mesh = BoxMesh.new()
			h_mesh.size = Vector3(0.14, 0.025, 0.02)
			h_mesh.material = handle_mat
			handle.mesh = h_mesh
			handle.position = Vector3(0, -0.025, 0.165)
			sled_root.add_child(handle)

			# Power LED (Green)
			var p_mesh = BoxMesh.new()
			p_mesh.size = Vector3(0.015, 0.015, 0.01)
			sled_obj.mat_power = StandardMaterial3D.new()
			sled_obj.mat_power.albedo_color = Color("#0f172a")
			sled_obj.mat_power.emission_enabled = true
			sled_obj.mat_power.emission = Color("#10b981")
			sled_obj.mat_power.emission_energy_multiplier = 1.2
			p_mesh.material = sled_obj.mat_power

			var led_p = MeshInstance3D.new()
			led_p.mesh = p_mesh
			led_p.position = Vector3(-0.07, 0.028, 0.165)
			sled_root.add_child(led_p)
			sled_obj.led_power = led_p

			# Activity LED (Amber / Cyan)
			var a_mesh = BoxMesh.new()
			a_mesh.size = Vector3(0.015, 0.015, 0.01)
			sled_obj.mat_activity = StandardMaterial3D.new()
			sled_obj.mat_activity.albedo_color = Color("#0f172a")
			sled_obj.mat_activity.emission_enabled = true
			sled_obj.mat_activity.emission = Color("#f59e0b")
			sled_obj.mat_activity.emission_energy_multiplier = 0.0
			a_mesh.material = sled_obj.mat_activity

			var led_a = MeshInstance3D.new()
			led_a.mesh = a_mesh
			led_a.position = Vector3(-0.04, 0.028, 0.165)
			sled_root.add_child(led_a)
			sled_obj.led_activity = led_a

			_sleds.append(sled_obj)

func _build_telemetry_display() -> void:
	var disp_y = 1.68
	var front_z = 0.95 * 0.5 - 0.08

	# Display backplane
	var panel = MeshInstance3D.new()
	var p_mesh = BoxMesh.new()
	p_mesh.size = Vector3(1.05, 0.42, 0.04)
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color("#020617")
	p_mat.metallic = 0.8
	p_mat.roughness = 0.25
	panel.mesh = p_mesh
	panel.material_override = p_mat
	panel.position = Vector3(0, disp_y, front_z)
	add_child(panel)

	# Emissive display border
	var border = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(1.03, 0.40, 0.01)
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color("#030712")
	b_mat.emission_enabled = true
	b_mat.emission = Color("#00f0ff")
	b_mat.emission_energy_multiplier = 0.6
	border.mesh = b_mesh
	border.material_override = b_mat
	border.position = Vector3(0, disp_y, front_z + 0.02)
	add_child(border)

	# Label 1: Header
	_lbl_header = Label3D.new()
	_lbl_header.text = "NVMe STORAGE ARRAY // TIER-0 VAULT"
	_lbl_header.font_size = 20
	_lbl_header.pixel_size = 0.0018
	_lbl_header.modulate = Color("#00f0ff")
	_lbl_header.outline_modulate = Color("#0284c7")
	_lbl_header.outline_size = 2
	_lbl_header.position = Vector3(0, disp_y + 0.12, front_z + 0.03)
	add_child(_lbl_header)

	# Label 2: Status
	_lbl_status = Label3D.new()
	_lbl_status.text = "STATE: STANDBY"
	_lbl_status.font_size = 18
	_lbl_status.pixel_size = 0.0018
	_lbl_status.modulate = Color("#10b981")
	_lbl_status.position = Vector3(0, disp_y + 0.04, front_z + 0.03)
	add_child(_lbl_status)

	# Label 3: Throughput
	_lbl_speed = Label3D.new()
	_lbl_speed.text = "THROUGHPUT: 0.0 MB/s (IDLE)"
	_lbl_speed.font_size = 22
	_lbl_speed.pixel_size = 0.0018
	_lbl_speed.modulate = Color("#64748b")
	_lbl_speed.position = Vector3(0, disp_y - 0.05, front_z + 0.03)
	add_child(_lbl_speed)

	# Label 4: Health & Topology
	_lbl_health = Label3D.new()
	_lbl_health.text = "HEALTH: 100% OK  |  TEMP: 32.4°C  |  16/16 ONLINE"
	_lbl_health.font_size = 14
	_lbl_health.pixel_size = 0.0018
	_lbl_health.modulate = Color("#94a3b8")
	_lbl_health.position = Vector3(0, disp_y - 0.13, front_z + 0.03)
	add_child(_lbl_health)

func _build_optical_junction() -> void:
	# Glowing fiber optic junction box at the base of the rack
	var jbox = MeshInstance3D.new()
	var j_mesh = BoxMesh.new()
	j_mesh.size = Vector3(0.4, 0.14, 0.22)
	var j_mat = StandardMaterial3D.new()
	j_mat.albedo_color = Color("#0f172a")
	j_mat.emission_enabled = true
	j_mat.emission = Color("#00f0ff")
	j_mat.emission_energy_multiplier = 1.6
	jbox.mesh = j_mesh
	jbox.material_override = j_mat
	jbox.position = Vector3(0, 0.14, 0.95 * 0.5 - 0.05)
	add_child(jbox)

func _build_collision_box() -> void:
	var body = StaticBody3D.new()
	body.name = "StorageRackCollision"
	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1.25, 2.35, 0.95)
	col.shape = box
	col.position = Vector3(0, 2.35 * 0.5, 0)
	body.add_child(col)
	add_child(body)
