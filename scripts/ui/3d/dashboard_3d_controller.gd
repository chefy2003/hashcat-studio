class_name Dashboard3DController
extends Node3D

## Master controller for the 3D Cyberpunk Operations Deck.
## Orchestrates 3D components, HUD overlay, and live telemetry feeds.

signal request_exit_3d()

@onready var camera: DashboardCamera3D = $Camera3D
@onready var server_rack: ServerRack3D = $ServerRack3D
@onready var hashrate_vis: HashrateVisualizer3D = $HashrateVisualizer3D
@onready var display_mesh: MeshInstance3D = $DisplayAnchor/CurvedDisplay3D
@onready var sub_viewport: SubViewport = $DisplayAnchor/SubViewport

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
	_apply_hologram_material()

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

func _apply_hologram_material() -> void:
	if not display_mesh or not sub_viewport:
		return

	var shader = load("res://shaders/hologram_display_3d.gdshader")
	if not shader:
		return

	var mat = ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("screen_viewport_texture", sub_viewport.get_texture())
	mat.set_shader_parameter("holo_tint", Color("#00f0ff"))
	mat.set_shader_parameter("tint_mix", 0.08)
	mat.set_shader_parameter("fresnel_intensity", 0.6)
	mat.set_shader_parameter("scanline_intensity", 0.1)
	display_mesh.material_override = mat

func update_telemetry_sample(rate_mhs: float, temp_celsius: float = 48.0, fan_pct: float = 40.0) -> void:
	if hashrate_vis:
		hashrate_vis.add_sample(rate_mhs)
	if server_rack:
		server_rack.update_device_telemetry(1, temp_celsius, fan_pct, clamp(rate_mhs * 0.5, 0.0, 100.0))

func _process(delta: float) -> void:
	# Subtle ambient simulation to keep the 3D scene dynamic and responsive
	_ambient_sim_timer += delta
	if _ambient_sim_timer >= 1.0:
		_ambient_sim_timer = 0.0
		var simulated_jitter = sin(Time.get_ticks_msec() * 0.002) * 5.0
		if hashrate_vis:
			hashrate_vis.add_sample(max(25.0 + simulated_jitter, 5.0))
		if server_rack:
			server_rack.update_device_telemetry(1, 48.0 + simulated_jitter * 0.3, 42.0, 50.0 + simulated_jitter)
