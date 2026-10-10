class_name DashboardCamera3D
extends Camera3D

## Cinematic & Free-Flight WASD camera controller for the 3D Operations Deck.
## Supports WASD 6-DOF keyboard navigation, right-click mouse look, and quick presets.

signal request_exit_3d()

enum ViewPreset {
	OPERATOR_FRONT,
	RACK_TELEMETRY,
	HOLO_TERMINAL,
	HASHRATE_WAVE,
	WIDE_OVERVIEW
}

@export var move_speed: float = 4.5
@export var sprint_multiplier: float = 2.2

var current_preset: ViewPreset = ViewPreset.OPERATOR_FRONT

var _preset_transforms: Dictionary = {
	ViewPreset.OPERATOR_FRONT: {
		"position": Vector3(0.0, 1.8, 6.2),
		"rotation_degrees": Vector3(-6.0, 0.0, 0.0)
	},
	ViewPreset.RACK_TELEMETRY: {
		"position": Vector3(-4.5, 1.25, -0.6),
		"rotation_degrees": Vector3(-3.0, 78.5, 0.0)
	},
	ViewPreset.HOLO_TERMINAL: {
		"position": Vector3(4.5, 1.35, -0.6),
		"rotation_degrees": Vector3(-2.0, -78.5, 0.0)
	},
	ViewPreset.HASHRATE_WAVE: {
		"position": Vector3(2.8, 1.3, -3.2),
		"rotation_degrees": Vector3(-6.0, -50.0, 0.0)
	},
	ViewPreset.WIDE_OVERVIEW: {
		"position": Vector3(0.0, 4.8, 11.5),
		"rotation_degrees": Vector3(-18.0, 0.0, 0.0)
	}
}

var _is_orbiting: bool = false
var _orbit_sensitivity: float = 0.25
var _zoom_speed: float = 0.35
var _tween: Tween = null

func _ready() -> void:
	switch_preset(ViewPreset.OPERATOR_FRONT, 0.0)

func switch_preset(preset: ViewPreset, duration: float = 0.6) -> void:
	current_preset = preset
	var target = _preset_transforms.get(preset, _preset_transforms[ViewPreset.OPERATOR_FRONT])

	if _tween and _tween.is_valid():
		_tween.kill()

	if duration <= 0.0:
		position = target["position"]
		rotation_degrees = target["rotation_degrees"]
		return

	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target["position"], duration)
	_tween.tween_property(self, "rotation_degrees", target["rotation_degrees"], duration)

func _process(delta: float) -> void:
	# WASD + QE Keyboard Navigation
	var input_dir: Vector3 = Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		input_dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		input_dir += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		input_dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		input_dir += transform.basis.x
	if Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE):
		input_dir += Vector3.UP
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_CTRL):
		input_dir += Vector3.DOWN

	if input_dir.length_squared() > 0.001:
		if _tween and _tween.is_valid():
			_tween.kill()

		var speed: float = move_speed
		if Input.is_key_pressed(KEY_SHIFT):
			speed *= sprint_multiplier

		global_position += input_dir.normalized() * speed * delta

func _unhandled_input(event: InputEvent) -> void:
	# Quick Preset Hotkeys: 1/F1, 2/F2, 3/F3, 4/F4, 5/F5
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				request_exit_3d.emit()
				get_tree().change_scene_to_file("res://scenes/main_wizard.tscn")
			KEY_1, KEY_F1:
				switch_preset(ViewPreset.OPERATOR_FRONT)
			KEY_2, KEY_F2:
				switch_preset(ViewPreset.RACK_TELEMETRY)
			KEY_3, KEY_F3:
				switch_preset(ViewPreset.HOLO_TERMINAL)
			KEY_4, KEY_F4:
				switch_preset(ViewPreset.HASHRATE_WAVE)
			KEY_5, KEY_F5:
				switch_preset(ViewPreset.WIDE_OVERVIEW)

	# Right-click mouse look
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_orbiting = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			translate(Vector3(0.0, 0.0, -_zoom_speed))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			translate(Vector3(0.0, 0.0, _zoom_speed))

	elif event is InputEventMouseMotion and _is_orbiting:
		rotation_degrees.y -= event.relative.x * _orbit_sensitivity
		rotation_degrees.x = clamp(rotation_degrees.x - event.relative.y * _orbit_sensitivity, -75.0, 75.0)
