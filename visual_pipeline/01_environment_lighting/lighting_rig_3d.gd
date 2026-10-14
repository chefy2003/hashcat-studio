class_name LightingRig3D
extends Node3D

## AAA Cinematic Lighting Rig for Forward+ Vulkan.
## Manages spot cones with volumetric fog scattering (god rays),
## shadow map cascades, and dynamic compute lighting pulses.

@export var pulse_enabled: bool = true
@export var base_rack_light_energy: float = 1.6
@export var base_terminal_light_energy: float = 1.4
@export var gantry_spot_energy: float = 3.5

var _gantry_spot: SpotLight3D
var _rack_spot: SpotLight3D
var _terminal_spot: SpotLight3D
var _core_omni: OmniLight3D

var _anim_time: float = 0.0

func _ready() -> void:
	_setup_rig_lights()

func _setup_rig_lights() -> void:
	# 1. Main Overhead Gantry Spotlight (Casts dramatic god rays through volumetric fog)
	_gantry_spot = SpotLight3D.new()
	_gantry_spot.name = "GantryGodRaySpot"
	_gantry_spot.position = Vector3(0.0, 7.5, -1.8)
	_gantry_spot.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	_gantry_spot.light_color = Color(0.72, 0.88, 1.0) # Cold industrial halogen
	_gantry_spot.light_energy = gantry_spot_energy
	_gantry_spot.light_volumetric_fog_energy = 0.8
	_gantry_spot.shadow_enabled = true
	_gantry_spot.shadow_bias = 0.03
	_gantry_spot.spot_range = 14.0
	_gantry_spot.spot_angle = 48.0
	_gantry_spot.spot_attenuation = 1.2
	add_child(_gantry_spot)

	# 2. Server Rack Targeted Spotlight (Highlights dark anodized metal and glass door)
	_rack_spot = SpotLight3D.new()
	_rack_spot.name = "ServerBaySpot"
	_rack_spot.position = Vector3(-3.8, 4.2, -0.6)
	_rack_spot.rotation_degrees = Vector3(-58.0, -15.0, 0.0)
	_rack_spot.light_color = Color(0.25, 0.85, 1.0) # Cyber Cyan
	_rack_spot.light_energy = base_rack_light_energy
	_rack_spot.light_volumetric_fog_energy = 1.5
	_rack_spot.shadow_enabled = true
	_rack_spot.spot_range = 7.0
	_rack_spot.spot_angle = 38.0
	add_child(_rack_spot)

	# 3. Hologram Terminal Key Light (Emphasizes terminal frame and user zone)
	_terminal_spot = SpotLight3D.new()
	_terminal_spot.name = "TerminalBaySpot"
	_terminal_spot.position = Vector3(3.8, 4.2, -0.6)
	_terminal_spot.rotation_degrees = Vector3(-58.0, 15.0, 0.0)
	_terminal_spot.light_color = Color(0.1, 0.95, 0.7) # Cyber Emerald
	_terminal_spot.light_energy = base_terminal_light_energy
	_terminal_spot.light_volumetric_fog_energy = 1.4
	_terminal_spot.shadow_enabled = true
	_terminal_spot.spot_range = 7.0
	_terminal_spot.spot_angle = 38.0
	add_child(_terminal_spot)

	# 4. Central Cryptographic Core Accent Light
	_core_omni = OmniLight3D.new()
	_core_omni.name = "CoreCenterLight"
	_core_omni.position = Vector3(0.0, 1.4, -1.2)
	_core_omni.light_color = Color(0.06, 0.9, 0.6)
	_core_omni.light_energy = 1.2
	_core_omni.omni_range = 4.8
	_core_omni.shadow_enabled = false
	add_child(_core_omni)

func _process(delta: float) -> void:
	if not pulse_enabled:
		return
	_anim_time += delta
	# Subtle breathing pulse on terminal and rack fill
	var breath = sin(_anim_time * 1.5) * 0.12
	if _terminal_spot:
		_terminal_spot.light_energy = base_terminal_light_energy + breath
	if _rack_spot:
		_rack_spot.light_energy = base_rack_light_energy - breath * 0.8
