class_name PlayerInteractionRayCast3D
extends RayCast3D

## First-person interaction raycast controller attached to Camera3D.
## Detects Interactable3D objects within reach (2.5m along -Z), displays
## HUD prompt [E] <action>, triggers visual focus highlights, and executes interaction on [E].

@export var prompt_label: Label
@export var reticle_node: Control

var current_interactable: Node = null

func _ready() -> void:
	target_position = Vector3(0.0, 0.0, -2.5)
	enabled = true
	collide_with_areas = true
	collide_with_bodies = true
	_ensure_interact_action()

func _ensure_interact_action() -> void:
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var event = InputEventKey.new()
		event.keycode = KEY_E
		event.physical_keycode = KEY_E
		InputMap.action_add_event("interact", event)

func _physics_process(_delta: float) -> void:
	var cam = get_parent() as Camera3D
	# While locked in active terminal focus, interaction raycast is idle
	if cam and "camera_mode" in cam:
		if cam.get("camera_mode") == 1: # DashboardCamera3D.CameraMode.TERMINAL_FOCUS
			_clear_focused()
			return

	if is_colliding():
		var collider = get_collider()
		if collider is Interactable3D or (collider != null and collider.has_method("interact")):
			if current_interactable != collider:
				_set_focused(collider)
			return

	_clear_focused()

func _unhandled_input(event: InputEvent) -> void:
	var cam = get_parent() as Camera3D
	if cam and "camera_mode" in cam:
		if cam.get("camera_mode") == 1: # TERMINAL_FOCUS
			return

	var is_interact_pressed: bool = false
	if event.is_action_pressed("interact"):
		is_interact_pressed = true
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		is_interact_pressed = true

	if is_interact_pressed and current_interactable != null:
		var actor: Node3D = owner as Node3D
		if not actor:
			actor = get_parent() as Node3D
		current_interactable.interact(actor)
		get_viewport().set_input_as_handled()

func _set_focused(target: Node) -> void:
	_clear_focused()
	current_interactable = target
	if current_interactable.has_method("on_focus_entered"):
		current_interactable.on_focus_entered()

	if prompt_label:
		var prompt_str: String = "Взаимодействие"
		if current_interactable.has_method("get_prompt"):
			prompt_str = current_interactable.get_prompt()
		prompt_label.text = "[E] " + prompt_str
		prompt_label.visible = true

	if reticle_node:
		reticle_node.set("is_focused", true)
		if reticle_node.has_method("queue_redraw"):
			reticle_node.queue_redraw()

func _clear_focused() -> void:
	if current_interactable != null:
		if is_instance_valid(current_interactable) and current_interactable.has_method("on_focus_exited"):
			current_interactable.on_focus_exited()
		current_interactable = null

	if prompt_label:
		prompt_label.visible = false

	if reticle_node:
		reticle_node.set("is_focused", false)
		if reticle_node.has_method("queue_redraw"):
			reticle_node.queue_redraw()
