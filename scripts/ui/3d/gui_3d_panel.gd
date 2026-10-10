class_name Gui3DPanel
extends StaticBody3D

## Reusable 3D Raycast Transfer Component for Interactive SubViewport GUI Panels.
## Projects camera 3D raycast collision points to 2D SubViewport UV coordinates
## and forwards mouse clicks, motion, and scrolling into the 2D Control tree.

@export var target_viewport: SubViewport
@export var mesh_instance: MeshInstance3D

var is_mouse_inside: bool = false
var last_mouse_pos_2d: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_exited.connect(_on_mouse_exited)
	if not mesh_instance and get_parent() is MeshInstance3D:
		mesh_instance = get_parent() as MeshInstance3D
	if not target_viewport:
		var p = get_parent()
		while p != null:
			var vp = p.get_node_or_null("SubViewport")
			if vp is SubViewport:
				target_viewport = vp
				break
			p = p.get_parent()

func _input_event(_camera: Camera3D, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not target_viewport or not mesh_instance:
		return

	var quad_mesh = mesh_instance.mesh as QuadMesh
	if not quad_mesh:
		return

	var mesh_size = quad_mesh.size
	var local_pos = mesh_instance.global_transform.affine_inverse() * event_position

	var uv = Vector2(
		(local_pos.x / mesh_size.x) + 0.5,
		0.5 - (local_pos.y / mesh_size.y)
	)

	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		return

	var viewport_pos = uv * Vector2(target_viewport.size)
	var forwarded_event = event.duplicate()

	if forwarded_event is InputEventMouse:
		forwarded_event.position = viewport_pos
		forwarded_event.global_position = viewport_pos

		if forwarded_event is InputEventMouseMotion:
			forwarded_event.relative = viewport_pos - last_mouse_pos_2d
			last_mouse_pos_2d = viewport_pos

		target_viewport.push_input(forwarded_event)
		is_mouse_inside = true

func _on_mouse_exited() -> void:
	if is_mouse_inside and target_viewport:
		var exit_event = InputEventMouseMotion.new()
		exit_event.position = Vector2(-1000, -1000)
		target_viewport.push_input(exit_event)
		is_mouse_inside = false
