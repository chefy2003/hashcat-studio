class_name Dashboard3DController
extends Node3D

## Master controller for the 3D Cyberpunk Operations Arena.
## Zero 2D screen overlays: Orchestrates 3D components, WASD camera,
## and bidirectional sync between ServerRack3D and the in-world HoloTerminal3D.

signal request_exit_3d()
signal devices_selection_changed(active_ids: Array[int], cli_device_flag: String)

@onready var camera: DashboardCamera3D = $Camera3D
@onready var server_rack: ServerRack3D = $ServerRack3D
@onready var holo_core: Node3D = $HoloCore3D
@onready var holo_terminal: Node3D = $HoloTerminal3D
@onready var hashrate_vis: HashrateVisualizer3D = $HashrateVisualizer3D

const HashcatBridgeScript = preload("res://scripts/bridge/hashcat_bridge.gd")

var _bridge: Node = null
var _ambient_sim_timer: float = 0.0

func _ready() -> void:
	_setup_engine_bridge()
	_connect_subsystem_signals()

func _setup_engine_bridge() -> void:
	_bridge = HashcatBridgeScript.new()
	add_child(_bridge)

	_bridge.stdout_line_received.connect(func(line: String):
		if holo_terminal:
			holo_terminal.append_console_line(line)
	)
	_bridge.stderr_line_received.connect(func(line: String):
		if holo_terminal:
			holo_terminal.append_console_line("[color=#ef4444]" + line + "[/color]")
	)
	_bridge.status_updated.connect(func(status_data: Dictionary):
		if holo_terminal:
			var speed = status_data.get("speed", "0 H/s")
			var progress = status_data.get("progress", "0%")
			var status_str = status_data.get("status", "ACTIVE")
			holo_terminal.update_engine_telemetry(speed, progress, status_str)
	)
	_bridge.hashrate_sample_received.connect(func(speed_val: float, _unit: String, raw_str: String):
		update_telemetry_sample(speed_val)
		if holo_terminal:
			holo_terminal.update_engine_telemetry(raw_str, "", "ACTIVE")
	)
	_bridge.password_cracked.connect(func(hash_val: String, plain_val: String):
		if holo_terminal:
			holo_terminal.add_cracked_password(hash_val, plain_val)
	)
	_bridge.process_finished.connect(func(exit_code: int):
		if holo_terminal:
			holo_terminal.append_console_line("[color=#38bdf8][*] Process finished (code %d).[/color]" % exit_code)
			holo_terminal.set_engine_running(false)
	)
	_bridge.emergency_stopped.connect(func():
		if holo_terminal:
			holo_terminal.append_console_line("[color=#ef4444][!] Emergency stop complete.[/color]")
			holo_terminal.set_engine_running(false)
	)

func _connect_subsystem_signals() -> void:
	if camera:
		camera.request_exit_3d.connect(func():
			if _bridge and _bridge.is_running():
				_bridge.stop_attack_emergency()
			request_exit_3d.emit()
			get_tree().change_scene_to_file("res://scenes/main_wizard.tscn")
		)

	if holo_terminal:
		if holo_terminal.has_signal("terminal_activated"):
			holo_terminal.connect("terminal_activated", func():
				if camera:
					camera.enter_terminal_focus()
				holo_terminal.set_focused(true)
			)

		if holo_terminal.has_signal("request_deactivate_focus"):
			holo_terminal.connect("request_deactivate_focus", func():
				if camera:
					camera.exit_terminal_focus()
				holo_terminal.set_focused(false)
			)

		if holo_terminal.has_signal("request_toggle_fullscreen"):
			holo_terminal.connect("request_toggle_fullscreen", func(is_full: bool):
				if camera:
					camera.set_terminal_fullscreen(is_full)
			)

		if camera and camera.has_signal("terminal_focus_changed"):
			camera.terminal_focus_changed.connect(func(is_focused: bool):
				holo_terminal.set_focused(is_focused)
			)

		holo_terminal.device_toggled.connect(func(dev_id: int, enabled: bool):
			if server_rack:
				server_rack.set_device_enabled(dev_id, enabled)
			_emit_selection_update()
		)

		holo_terminal.compute_mode_selected.connect(func(mode: String):
			if server_rack:
				var detected = HardwareInspector.probe_compute_devices()
				for dev in detected:
					var dev_id: int = dev.get("id", 1)
					var is_cpu: bool = (dev.get("type", "") == "CPU")
					var en: bool = false
					if mode == "CPU":
						en = is_cpu
					elif mode == "GPU":
						en = not is_cpu
					elif mode == "ALL":
						en = true
					server_rack.set_device_enabled(dev_id, en)
			_emit_selection_update()
		)

		holo_terminal.attack_requested.connect(func(args: Array):
			if _bridge:
				_bridge.start_attack(args)
		)

		holo_terminal.benchmark_requested.connect(func():
			if _bridge:
				var dev_flag = HardwareInspector.get_cli_device_flag()
				var b_args: Array = ["-b"]
				if not dev_flag.is_empty():
					for p in dev_flag.split(" "):
						if not p.strip_edges().is_empty():
							b_args.append(p.strip_edges())
				_bridge.start_attack(b_args)
		)

		holo_terminal.stop_requested.connect(func():
			if _bridge:
				_bridge.stop_attack_emergency()
		)

	if server_rack:
		server_rack.device_toggled.connect(func(dev_id: int, enabled: bool):
			if holo_terminal:
				holo_terminal.sync_device_state(dev_id, enabled)
			_emit_selection_update()
		)

	_emit_selection_update()

func _emit_selection_update() -> void:
	var active_ids = HardwareInspector.get_active_device_ids()
	var cli_flag = HardwareInspector.get_cli_device_flag()
	devices_selection_changed.emit(active_ids, cli_flag)

func update_telemetry_sample(rate_mhs: float, temp_celsius: float = 48.0, fan_pct: float = 40.0) -> void:
	if hashrate_vis:
		hashrate_vis.add_sample(rate_mhs)
	if server_rack:
		server_rack.update_device_telemetry(1, temp_celsius, fan_pct, clamp(rate_mhs * 0.5, 0.0, 100.0))
	if holo_core:
		holo_core.set_core_telemetry(rate_mhs, "ACTIVE")

func _process(delta: float) -> void:
	if camera and holo_terminal:
		var dist = camera.global_position.distance_to(holo_terminal.global_position)
		holo_terminal.set_player_in_range(dist < 5.2)

	# Sync energy conduits with quantum core thermal load
	if holo_core and "heat_level" in holo_core:
		var c_heat: float = holo_core.heat_level
		for conduit in get_tree().get_nodes_in_group("energy_conduits"):
			if conduit.has_method("set_heat_level"):
				conduit.set_heat_level(c_heat)

	_ambient_sim_timer += delta
	if _ambient_sim_timer < 0.75:
		return
	_ambient_sim_timer = 0.0

	var detected_devices = HardwareInspector.probe_compute_devices()
	var active_gpus: int = 0
	var active_cpus: int = 0

	for dev in detected_devices:
		if dev.get("enabled", false):
			if dev.get("type", "") == "CPU":
				active_cpus += 1
			else:
				active_gpus += 1

	if _bridge and _bridge.is_running():
		return # Active attack running - live metrics streamed via HashcatBridge

	var simulated_jitter = sin(Time.get_ticks_msec() * 0.002) * 8.0
	var current_rate: float = 0.0
	var status_text: String = "STANDBY"

	if active_gpus > 0 or active_cpus > 0:
		current_rate = float(active_gpus) * 118.0 + float(active_cpus) * 24.0 + simulated_jitter
		current_rate = max(current_rate, 12.0)
		if active_gpus > 0 and active_cpus > 0:
			status_text = "HYBRID ACCEL"
		elif active_gpus > 0:
			status_text = "GPU CLUSTER"
		else:
			status_text = "NUMA CPU"

	if hashrate_vis:
		hashrate_vis.add_sample(current_rate)

	if server_rack:
		for dev in detected_devices:
			var dev_id: int = dev.get("id", 1)
			var is_en: bool = dev.get("enabled", false)
			var is_cpu: bool = (dev.get("type", "") == "CPU")
			if is_en:
				var dev_temp = (40.0 if is_cpu else 53.0) + simulated_jitter * 0.25
				var dev_fan = 35.0 if is_cpu else 46.0 + simulated_jitter * 0.4
				var dev_load = 32.0 if is_cpu else 68.0 + simulated_jitter
				server_rack.update_device_telemetry(dev_id, dev_temp, dev_fan, dev_load)
				if holo_terminal:
					holo_terminal.update_device_metrics(dev_id, dev_temp, dev_fan, dev_load)
			else:
				server_rack.update_device_telemetry(dev_id, 32.0, 0.0, 0.0)
				if holo_terminal:
					holo_terminal.update_device_metrics(dev_id, 32.0, 0.0, 0.0)

	if holo_core:
		holo_core.set_core_telemetry(current_rate, status_text)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			if camera and holo_terminal:
				if camera.camera_mode == DashboardCamera3D.CameraMode.FREE_FLIGHT:
					if holo_terminal.is_player_in_range or holo_terminal.is_hovered:
						camera.enter_terminal_focus()
						holo_terminal.set_focused(true)
						get_viewport().set_input_as_handled()
				elif camera.camera_mode == DashboardCamera3D.CameraMode.TERMINAL_FOCUS:
					camera.exit_terminal_focus()
					holo_terminal.set_focused(false)
					get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			if camera and camera.camera_mode == DashboardCamera3D.CameraMode.TERMINAL_FOCUS:
				camera.exit_terminal_focus()
				if holo_terminal:
					holo_terminal.set_focused(false)
				get_viewport().set_input_as_handled()
