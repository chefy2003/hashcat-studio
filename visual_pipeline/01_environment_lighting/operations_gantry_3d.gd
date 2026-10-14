class_name OperationsGantry3D
extends Node3D

## Architectural Sci-Fi Hangar Gantry & Ceiling Truss System.
## Grounds the 3D operations arena inside a massive subterranean black-ops citadel.
## Interacts with Volumetric Fog and Spotlights to produce dramatic shadow silhouettes.

@export var gantry_height: float = 5.4
@export var deck_span_x: float = 16.5
@export var deck_length_z: float = 14.0

func _ready() -> void:
	_build_gantry_structure()

func _build_gantry_structure() -> void:
	# PBR Dark Titanium Truss Material
	var truss_mat = StandardMaterial3D.new()
	truss_mat.albedo_color = Color("#090e18")
	truss_mat.metallic = 0.92
	truss_mat.roughness = 0.28

	# Neon conduit guide strip material (Deep Cyber Emerald / Cyan)
	var strip_mat = StandardMaterial3D.new()
	strip_mat.albedo_color = Color("#00f0ff")
	strip_mat.emission_enabled = true
	strip_mat.emission = Color("#00f0ff")
	strip_mat.emission_energy_multiplier = 2.4

	# 1. Main Left and Right Heavy Runway I-Beams (Longitudinal)
	for x_side in [-deck_span_x * 0.5, deck_span_x * 0.5]:
		var beam = MeshInstance3D.new()
		var b_box = BoxMesh.new()
		b_box.size = Vector3(0.5, 0.45, deck_length_z)
		beam.mesh = b_box
		beam.position = Vector3(x_side, gantry_height, -0.5)
		beam.material_override = truss_mat
		add_child(beam)

		# Edge hazard light strip along runway beam
		var strip = MeshInstance3D.new()
		var s_box = BoxMesh.new()
		s_box.size = Vector3(0.06, 0.04, deck_length_z)
		strip.mesh = s_box
		strip.position = Vector3(x_side * 0.96, gantry_height - 0.2, -0.5)
		strip.material_override = strip_mat
		add_child(strip)

	# 2. Transverse Structural Girders / Ceiling Arches across the deck
	var z_crossings = [-5.8, -2.2, 1.8, 5.4]
	for z_pos in z_crossings:
		var girder = MeshInstance3D.new()
		var g_box = BoxMesh.new()
		g_box.size = Vector3(deck_span_x, 0.38, 0.42)
		girder.mesh = g_box
		girder.position = Vector3(0.0, gantry_height + 0.15, z_pos)
		girder.material_override = truss_mat
		add_child(girder)

		# Diagonal support gussets at each end
		for side in [-1.0, 1.0]:
			var gusset = MeshInstance3D.new()
			var gus_box = BoxMesh.new()
			gus_box.size = Vector3(1.6, 0.22, 0.35)
			gusset.mesh = gus_box
			gusset.position = Vector3(side * (deck_span_x * 0.5 - 0.9), gantry_height - 0.35, z_pos)
			gusset.rotation_degrees = Vector3(0.0, 0.0, side * 35.0)
			gusset.material_override = truss_mat
			add_child(gusset)

	# 3. Central Overhead Equipment Crane / Gantry Carriage
	var carriage = MeshInstance3D.new()
	var c_box = BoxMesh.new()
	c_box.size = Vector3(2.8, 0.32, 2.4)
	carriage.mesh = c_box
	carriage.position = Vector3(0.0, gantry_height + 0.25, -1.8)
	carriage.material_override = truss_mat
	add_child(carriage)

	# 4. Heavy dark ceiling baffle plates (Blocks empty void above)
	var ceiling = MeshInstance3D.new()
	var ceil_box = BoxMesh.new()
	ceil_box.size = Vector3(deck_span_x + 6.0, 0.1, deck_length_z + 8.0)
	ceiling.mesh = ceil_box
	ceiling.position = Vector3(0.0, gantry_height + 0.65, -0.5)
	var ceil_mat = StandardMaterial3D.new()
	ceil_mat.albedo_color = Color("#05080f")
	ceil_mat.metallic = 0.95
	ceil_mat.roughness = 0.5
	ceiling.material_override = ceil_mat
	add_child(ceiling)
