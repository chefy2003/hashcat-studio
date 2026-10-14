class_name LightingRig3D
extends Node3D

## AAA Cinematic Lighting Rig for Forward+ Vulkan.
## Manages spot cones with volumetric fog scattering (god rays),
## shadow map cascades, entrance airlock illumination, and storage rack key lighting.

@export var pulse_enabled: bool = true
@export var base_rack_light_energy: float = 2.4
@export var base_terminal_light_energy: float = 1.6
@export var gantry_spot_energy: float = 3.5

var _gantry_spot: SpotLight3D
var _rack_spot: SpotLight3D
var _rack_lower_fill: OmniLight3D
var _terminal_spot: SpotLight3D
var _core_omni: OmniLight3D
var _gate_spot: SpotLight3D
var _gate_omni: OmniLight3D
var _storage_spot: SpotLight3D

var _anim_time: float = 0.0

func _ready() -> void:
	_setup_rig_lights()

func _setup_rig_lights() -> void:
	# 1. Main Overhead Gantry Spotlight (God rays through volumetric fog)
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

	# 2. Server Rack Targeted Spotlight (Washes all 4 GPUs + CPU from top to bottom)
	_rack_spot = SpotLight3D.new()
	_rack_spot.name = "ServerBaySpot"
	_rack_spot.position = Vector3(-3.6, 4.5, -0.4)
	_rack_spot.rotation_degrees = Vector3(-55.0, -15.0, 0.0)
	_rack_spot.light_color = Color(0.25, 0.85, 1.0) # Cyber Cyan
	_rack_spot.light_energy = base_rack_light_energy
	_rack_spot.light_volumetric_fog_energy = 1.5
	_rack_spot.shadow_enabled = true
	_rack_spot.spot_range = 9.0
	_rack_spot.spot_angle = 52.0
	add_child(_rack_spot)

	# Lower bay fill light so bottom GPUs (#1 and #2) are vividly illuminated
	_rack_lower_fill = OmniLight3D.new()
	_rack_lower_fill.name = "RackLowerFillLight"
	_rack_lower_fill.position = Vector3(-3.5, 0.6, -2.1)
	_rack_lower_fill.light_color = Color(0.18, 0.82, 1.0)
	_rack_lower_fill.light_energy = 1.2
	_rack_lower_fill.omni_range = 3.5
	add_child(_rack_lower_fill)

	# 3. Hologram Terminal Key Light
	_terminal_spot = SpotLight3D.new()
	_terminal_spot.name = "TerminalBaySpot"
	_terminal_spot.position = Vector3(3.8, 4.2, -0.6)
	_terminal_spot.rotation_degrees = Vector3(-58.0, 15.0, 0.0)
	_terminal_spot.light_color = Color(0.1, 0.95, 0.7) # Cyber Emerald
	_terminal_spot.light_energy = base_terminal_light_energy
	_terminal_spot.light_volumetric_fog_energy = 1.4
	_terminal_spot.shadow_enabled = true
	_terminal_spot.spot_range = 7.5
	_terminal_spot.spot_angle = 40.0
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

	# 5. Storage Rack Key Light (East Wall NVMe Array)
	_storage_spot = SpotLight3D.new()
	_storage_spot.name = "StorageArraySpot"
	_storage_spot.position = Vector3(4.6, 4.5, 1.8)
	_storage_spot.rotation_degrees = Vector3(-52.0, 40.0, 0.0)
	_storage_spot.light_color = Color(0.0, 0.92, 1.0)
	_storage_spot.light_energy = 2.2
	_storage_spot.spot_range = 8.0
	_storage_spot.spot_angle = 45.0
	_storage_spot.shadow_enabled = true
	add_child(_storage_spot)

	# 6. South Airlock Bulkhead Entrance Floodlight (Illuminates blast door)
	_gate_spot = SpotLight3D.new()
	_gate_spot.name = "AirlockGateSpot"
	_gate_spot.position = Vector3(0.0, 5.2, 4.5)
	_gate_spot.rotation_degrees = Vector3(-45.0, 180.0, 0.0) # Points back toward south wall Z=+7.7
	_gate_spot.light_color = Color(0.85, 0.92, 1.0) # Cold security halogen
	_gate_spot.light_energy = 3.2
	_gate_spot.spot_range = 9.5
	_gate_spot.spot_angle = 50.0
	_gate_spot.shadow_enabled = true
	add_child(_gate_spot)

	# South Entrance Ambient Fill
	_gate_omni = OmniLight3D.new()
	_gate_omni.name = "AirlockAmbientFill"
	_gate_omni.position = Vector3(0.0, 3.2, 6.6)
	_gate_omni.light_color = Color(0.2, 0.75, 1.0)
	_gate_omni.light_energy = 1.8
	_gate_omni.omni_range = 6.0
	add_child(_gate_omni)

func _process(delta: float) -> void:
	if not pulse_enabled:
		return
	_anim_time += delta
	var breath = sin(_anim_time * 1.5) * 0.12
	if _terminal_spot:
		_terminal_spot.light_energy = base_terminal_light_energy + breath
	if _rack_spot:
		_rack_spot.light_energy = base_rack_light_energy - breath * 0.8
