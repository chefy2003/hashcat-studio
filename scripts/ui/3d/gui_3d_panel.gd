class_name Gui3DPanel
extends Interactable3D

## Reusable 3D Raycast Transfer Component for Interactive SubViewport GUI Panels.
## Extends Interactable3D so it integrates directly with the player's RayCast3D,
## responds to [E] key interaction, and projects cursor coordinates to SubViewport 2D UI.

signal hover_state_changed(is_hovered: bool)
signal panel_clicked_in_free_mode()

@export var target_viewport: SubViewport
@export var mesh_instance: MeshInstance3D
@export var is_interaction_enabled: bool = false

var is_mouse_inside: bool = false
var last_mouse_pos_2d: Vector2 = Vector2.ZERO

func _ready() -> void:
	prompt_message = "Влез в терминала"
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

func interact(actor: Node3D) -> void:
	panel_clicked_in_free_mode.emit()
	super.interact(actor)

func on_focus_entered() -> void:
	hover_state_changed.emit(true)
	super.on_focus_entered()

func on_focus_exited() -> void:
	hover_state_changed.emit(false)
	super.on_focus_exited()

func _input_event(_camera: Camera3D, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if not target_viewport or not mesh_instance:
		return

	var quad_mesh = mesh_instance.mesh as QuadMesh
	if not quad_mesh:
		return

	var mesh_size = quad_mesh.size
	var local_pos = mesh_instance.global_transform.affine_inverse() * event_position

	var raw_u = (local_pos.x / mesh_size.x) + 0.5
	var raw_v = 0.5 - (local_pos.y / mesh_size.y)

	if raw_u < -0.05 or raw_u > 1.05 or raw_v < -0.05 or raw_v > 1.05:
		return

	var uv = Vector2(clampf(raw_u, 0.0, 1.0), clampf(raw_v, 0.0, 1.0))

	if not is_mouse_inside:
		is_mouse_inside = true
		hover_state_changed.emit(true)

	# When interaction is disabled (Free-Flight mode), clicking the panel activates focus
	if not is_interaction_enabled:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			panel_clicked_in_free_mode.emit()
		return

	# When interaction is enabled (Terminal Focus mode), forward all mouse events
	var viewport_pos = uv * Vector2(target_viewport.size)
	var forwarded_event = event.duplicate()

	if forwarded_event is InputEventMouse:
		forwarded_event.position = viewport_pos
		forwarded_event.global_position = viewport_pos

		if forwarded_event is InputEventMouseMotion:
			forwarded_event.relative = viewport_pos - last_mouse_pos_2d
			last_mouse_pos_2d = viewport_pos
			target_viewport.push_input(forwarded_event)
		elif forwarded_event is InputEventMouseButton:
			if forwarded_event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
				if forwarded_event.factor <= 0.001:
					forwarded_event.factor = 1.0
			else:
				# Ensure SubViewport updates hover and cursor focus immediately prior to button click
				var motion = InputEventMouseMotion.new()
				motion.position = viewport_pos
				motion.global_position = viewport_pos
				motion.relative = viewport_pos - last_mouse_pos_2d
				last_mouse_pos_2d = viewport_pos
				target_viewport.push_input(motion)

			target_viewport.push_input(forwarded_event)

func _on_mouse_exited() -> void:
	if is_mouse_inside:
		is_mouse_inside = false
		hover_state_changed.emit(false)
		if target_viewport and is_interaction_enabled:
			var exit_event = InputEventMouseMotion.new()
			exit_event.position = Vector2(-1000, -1000)
			target_viewport.push_input(exit_event)
