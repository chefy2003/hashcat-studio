class_name Dashboard3DController
extends Node3D

## Master controller for the 3D Cyberpunk Operations Deck.
## Orchestrates 3D components, dynamic hardware detection, HUD overlay,
## live telemetry feeds, and bi-directional hardware toggling (HUD + 3D Rack).

signal request_exit_3d()
signal devices_selection_changed(active_ids: Array[int], cli_device_flag: String)

const HoloCore3DScript = preload("res://scripts/ui/3d/holo_core_3d.gd")

@onready var camera: DashboardCamera3D = $Camera3D
@onready var server_rack: ServerRack3D = $ServerRack3D
@onready var hashrate_vis: HashrateVisualizer3D = $HashrateVisualizer3D
@onready var holo_core: Node3D = $HoloCore3D

# Bottom Navigation HUD
@onready var btn_view_front: Button = $HUD/Margin/HBox/BtnViewFront
@onready var btn_view_rack: Button = $HUD/Margin/HBox/BtnViewRack
@onready var btn_view_wave: Button = $HUD/Margin/HBox/BtnViewWave
@onready var btn_view_wide: Button = $HUD/Margin/HBox/BtnViewWide
@onready var btn_return_2d: Button = $HUD/Margin/HBox/BtnReturn2D
@onready var label_status: Label = $HUD/Margin/HBox/LabelStatus

# Top Hardware Control HUD
@onready var btn_mode_cpu: Button = $HUD/TopMargin/Panel/HBox/BtnModeCPU
@onready var btn_mode_gpu: Button = $HUD/TopMargin/Panel/HBox/BtnModeGPU
@onready var btn_mode_all: Button = $HUD/TopMargin/Panel/HBox/BtnModeALL
@onready var device_buttons_container: HBoxContainer = $HUD/TopMargin/Panel/HBox/DeviceButtonsContainer
@onready var label_cli_preview: Label = $HUD/TopMargin/Panel/HBox/LabelCliPreview

var _device_buttons: Dictionary = {} # dev_id -> Button
var _ambient_sim_timer: float = 0.0

func _ready() -> void:
	_connect_hud_signals()
	_build_hardware_toggles()
	_sync_hardware_ui_state()

func _connect_hud_signals() -> void:
	if btn_view_front:
		btn_view_front.pressed.connect(func(): camera.switch_preset(DashboardCamera3D.ViewPreset.OPERATOR_FRONT))
	if btn_view_rack:
		btn_view_rack.pressed.connect(func(): camera.switch_preset(DashboardCamera3D.ViewPreset.RACK_TELEMETRY))
	if btn_view_wave:
		btn_view_wave.pressed.connect(func(): camera.switch_preset(DashboardCamera3D.ViewPreset.HASHRATE_WAVE))
	if btn_view_wide:
		btn_view_wide.pressed.connect(func(): camera.switch_preset(DashboardCamera3D.ViewPreset.WIDE_OVERVIEW))
	if btn_return_2d:
		btn_return_2d.pressed.connect(func():
			request_exit_3d.emit()
			get_tree().change_scene_to_file("res://scenes/main_wizard.tscn")
		)

	if btn_mode_cpu:
		btn_mode_cpu.pressed.connect(func(): set_compute_mode("CPU"))
	if btn_mode_gpu:
		btn_mode_gpu.pressed.connect(func(): set_compute_mode("GPU"))
	if btn_mode_all:
		btn_mode_all.pressed.connect(func(): set_compute_mode("ALL"))

	if server_rack:
		server_rack.device_toggled.connect(func(dev_id: int, _enabled: bool):
			_sync_hardware_ui_state()
		)

func _build_hardware_toggles() -> void:
	if not device_buttons_container:
		return

	for child in device_buttons_container.get_children():
		child.queue_free()
	_device_buttons.clear()

	var detected_devices = HardwareInspector.probe_compute_devices()
	for dev in detected_devices:
		var dev_id: int = dev.get("id", 1)
		var dev_type: String = dev.get("type", "GPU")
		var is_cpu: bool = (dev_type == "CPU")
		var is_en: bool = dev.get("enabled", is_cpu)

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(88, 30)
		_style_device_button(btn, dev_id, is_cpu, is_en)

		btn.pressed.connect(func():
			if server_rack:
				var new_state: bool = server_rack.toggle_device(dev_id)
				_style_device_button(btn, dev_id, is_cpu, new_state)
				_sync_hardware_ui_state()
		)

		device_buttons_container.add_child(btn)
		_device_buttons[dev_id] = btn

func _style_device_button(btn: Button, dev_id: int, is_cpu: bool, enabled: bool) -> void:
	var icon = "🖥️ CPU" if is_cpu else "⚡ GPU"
	btn.text = "%s #%d: %s" % [icon, dev_id, "ВКЛ" if enabled else "ИЗКЛ"]

	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 2
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3

	if enabled:
		sb.bg_color = Color("#0b2938") if not is_cpu else Color("#0f2a24")
		sb.border_color = Color("#00f0ff") if not is_cpu else Color("#10b981")
		btn.add_theme_color_override("font_color", Color("#00f0ff") if not is_cpu else Color("#10b981"))
	else:
		sb.bg_color = Color("#111827")
		sb.border_color = Color("#374151")
		btn.add_theme_color_override("font_color", Color("#6b7280"))

	btn.add_theme_stylebox_override("normal", sb)

func set_compute_mode(mode: String) -> void:
	var detected_devices = HardwareInspector.probe_compute_devices()
	for dev in detected_devices:
		var dev_id: int = dev.get("id", 1)
		var is_cpu: bool = (dev.get("type", "") == "CPU")
		var activate: bool = false
		if mode == "CPU":
			activate = is_cpu
		elif mode == "GPU":
			activate = not is_cpu
		elif mode == "ALL":
			activate = true

		if server_rack:
			server_rack.set_device_enabled(dev_id, activate)
		HardwareInspector.set_device_enabled(dev_id, activate)

	_sync_hardware_ui_state()

func _sync_hardware_ui_state() -> void:
	var detected_devices = HardwareInspector.probe_compute_devices()
	var active_ids: Array[int] = []

	for dev in detected_devices:
		var dev_id: int = dev.get("id", 1)
		var is_cpu: bool = (dev.get("type", "") == "CPU")
		var is_en: bool = dev.get("enabled", false)
		if is_en:
			active_ids.append(dev_id)

		if _device_buttons.has(dev_id):
			_style_device_button(_device_buttons[dev_id], dev_id, is_cpu, is_en)

	active_ids.sort()
	var cli_flag: String = HardwareInspector.get_cli_device_flag()

	if label_cli_preview:
		label_cli_preview.text = "CLI: " + (cli_flag if not cli_flag.is_empty() else "Няма избрани (-d none)")
		label_cli_preview.add_theme_color_override("font_color", Color("#00f0ff") if not active_ids.is_empty() else Color("#ef4444"))

	if label_status:
		label_status.text = "🪐 3D OPS DECK // %d/%d АКТИВНИ ВЪЗЕЛА" % [active_ids.size(), detected_devices.size()]

	devices_selection_changed.emit(active_ids, cli_flag)

func update_telemetry_sample(rate_mhs: float, temp_celsius: float = 48.0, fan_pct: float = 40.0) -> void:
	if hashrate_vis:
		hashrate_vis.add_sample(rate_mhs)
	if server_rack:
		server_rack.update_device_telemetry(1, temp_celsius, fan_pct, clamp(rate_mhs * 0.5, 0.0, 100.0))
	if holo_core:
		holo_core.set_core_telemetry(rate_mhs, "ACTIVE")

func _process(delta: float) -> void:
	_ambient_sim_timer += delta
	if _ambient_sim_timer < 0.8:
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

	var simulated_jitter = sin(Time.get_ticks_msec() * 0.002) * 6.0
	var current_rate: float = 0.0
	var status_text: String = "IDLE / STANDBY"

	if active_gpus > 0 or active_cpus > 0:
		current_rate = float(active_gpus) * 115.0 + float(active_cpus) * 22.0 + simulated_jitter
		current_rate = max(current_rate, 12.0)
		status_text = "HYBRID ACCEL" if (active_gpus > 0 and active_cpus > 0) else ("GPU COMPUTE" if active_gpus > 0 else "NUMA CPU")

	if hashrate_vis:
		hashrate_vis.add_sample(current_rate)

	if server_rack:
		for dev in detected_devices:
			var dev_id: int = dev.get("id", 1)
			var is_en: bool = dev.get("enabled", false)
			var is_cpu: bool = (dev.get("type", "") == "CPU")
			if is_en:
				var dev_temp = (40.0 if is_cpu else 52.0) + simulated_jitter * 0.3
				var dev_fan = 35.0 if is_cpu else 45.0 + simulated_jitter * 0.5
				var dev_load = 30.0 if is_cpu else 65.0 + simulated_jitter
				server_rack.update_device_telemetry(dev_id, dev_temp, dev_fan, dev_load)
			else:
				server_rack.update_device_telemetry(dev_id, 32.0, 0.0, 0.0)

	if holo_core:
		holo_core.set_core_telemetry(current_rate, status_text)
