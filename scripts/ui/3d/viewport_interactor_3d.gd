class_name ViewportInteractor3D
extends Area3D

## Translates 3D Raycast mouse events into 2D SubViewport input coordinates.
## Enables seamless clicks, dragging, and hover effects on 3D projected UI.

@export var target_viewport: SubViewport
@export var mesh_width: float = 3.6
@export var mesh_height: float = 2.05

var _is_mouse_inside: bool = false
var _last_uv_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	input_event.connect(_on_area_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	_is_mouse_inside = true

func _on_mouse_exited() -> void:
	_is_mouse_inside = false

func _on_area_input_event(_camera: Camera3D, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not target_viewport:
		return

	# Transform hit point into local mesh space
	var local_pos = global_transform.affine_inverse() * event_position
	
	# Calculate normalized UV (0.0 to 1.0)
	var uv = Vector2(
		(local_pos.x / mesh_width) + 0.5,
		0.5 - (local_pos.y / mesh_height)
	)

	uv.x = clamp(uv.x, 0.0, 1.0)
	uv.y = clamp(uv.y, 0.0, 1.0)
	_last_uv_pos = uv

	# Convert to SubViewport pixel coordinates
	var vp_size = Vector2(target_viewport.size)
	var viewport_pos = Vector2(uv.x * vp_size.x, uv.y * vp_size.y)

	var forward_event = event.duplicate()
	if forward_event is InputEventMouse:
		forward_event.position = viewport_pos
		forward_event.global_position = viewport_pos
		target_viewport.push_input(forward_event)
