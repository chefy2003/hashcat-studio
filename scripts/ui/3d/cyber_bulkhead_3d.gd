class_name CyberBulkhead3D
extends Node3D

## Architectural Sci-Fi Cockpit Bulkhead Pillar.
## Frames the operations deck with dark structural composite beams and vertical neon conduit ribs.

@export var pillar_height: float = 5.2
@export var neon_color: Color = Color("#00f0ff")

func _ready() -> void:
	_build_pillar()

func _build_pillar() -> void:
	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color("#090e17")
	dark_mat.metallic = 0.95
	dark_mat.roughness = 0.35

	var neon_mat = StandardMaterial3D.new()
	neon_mat.albedo_color = neon_color
	neon_mat.emission_enabled = true
	neon_mat.emission = neon_color
	neon_mat.emission_energy_multiplier = 1.35

	# Main vertical column
	var main_col = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.55, pillar_height, 0.45)
	main_col.mesh = box
	main_col.position.y = pillar_height * 0.5
	main_col.material_override = dark_mat
	add_child(main_col)

	# Physical solid collision body for Bulkhead Column
	var body = StaticBody3D.new()
	body.name = "BulkheadStaticBody"
	var col = CollisionShape3D.new()
	var col_box = BoxShape3D.new()
	col_box.size = Vector3(0.55, pillar_height, 0.45)
	col.shape = col_box
	col.position = Vector3(0.0, pillar_height * 0.5, 0.0)
	body.add_child(col)
	add_child(body)

	# Slanted cantilever / roof arch brace
	var brace = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.42, 2.8, 0.35)
	brace.mesh = b_box
	brace.position = Vector3(0.85, pillar_height - 0.75, 0.0)
	brace.rotation_degrees = Vector3(0, 0, -38.0)
	brace.material_override = dark_mat
	add_child(brace)

	# Glowing neon vertical accent strip on column face
	var strip = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.08, pillar_height * 0.85, 0.04)
	strip.mesh = s_box
	strip.position = Vector3(0.0, pillar_height * 0.48, 0.24)
	strip.material_override = neon_mat
	add_child(strip)

	# Glowing neon accent on brace
	var b_strip = MeshInstance3D.new()
	var bs_box = BoxMesh.new()
	bs_box.size = Vector3(0.06, 2.2, 0.04)
	b_strip.mesh = bs_box
	b_strip.position = Vector3(0.85, pillar_height - 0.75, 0.18)
	b_strip.rotation_degrees = Vector3(0, 0, -38.0)
	b_strip.material_override = neon_mat
	add_child(b_strip)
