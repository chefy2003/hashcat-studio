class_name Dashboard3DController
extends Node3D

## Master controller for the 3D Cyberpunk Operations Deck.
## Orchestrates 3D components, HUD overlay, and live telemetry feeds.

signal request_exit_3d()

const HoloCore3DScript = preload("res://scripts/ui/3d/holo_core_3d.gd")

@onready var camera: DashboardCamera3D = $Camera3D
@onready var server_rack: ServerRack3D = $ServerRack3D
@onready var hashrate_vis: HashrateVisualizer3D = $HashrateVisualizer3D
@onready var holo_core: Node3D = $HoloCore3D

# 2D CanvasLayer HUD Controls
@onready var btn_view_front: Button = $HUD/Margin/HBox/BtnViewFront
@onready var btn_view_rack: Button = $HUD/Margin/HBox/BtnViewRack
@onready var btn_view_wave: Button = $HUD/Margin/HBox/BtnViewWave
@onready var btn_view_wide: Button = $HUD/Margin/HBox/BtnViewWide
@onready var btn_return_2d: Button = $HUD/Margin/HBox/BtnReturn2D
@onready var label_status: Label = $HUD/Margin/HBox/LabelStatus

var _ambient_sim_timer: float = 0.0

func _ready() -> void:
	_connect_hud_signals()

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

func update_telemetry_sample(rate_mhs: float, temp_celsius: float = 48.0, fan_pct: float = 40.0) -> void:
	if hashrate_vis:
		hashrate_vis.add_sample(rate_mhs)
	if server_rack:
		server_rack.update_device_telemetry(1, temp_celsius, fan_pct, clamp(rate_mhs * 0.5, 0.0, 100.0))
	if holo_core:
		holo_core.set_core_telemetry(rate_mhs, "ACTIVE")

func _process(delta: float) -> void:
	# Ambient simulation to keep the 3D scene dynamic and responsive
	_ambient_sim_timer += delta
	if _ambient_sim_timer >= 0.8:
		_ambient_sim_timer = 0.0
		var simulated_jitter = sin(Time.get_ticks_msec() * 0.002) * 8.0
		var current_rate = max(110.0 + simulated_jitter, 15.0)
		if hashrate_vis:
			hashrate_vis.add_sample(current_rate)
		if server_rack:
			server_rack.update_device_telemetry(1, 48.0 + simulated_jitter * 0.25, 42.0, 60.0 + simulated_jitter)
		if holo_core:
			holo_core.set_core_telemetry(current_rate, "COMPUTING")
