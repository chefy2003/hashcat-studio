class_name DashboardCamera3D
extends Camera3D

## Cinematic & Free-Flight WASD camera controller for the 3D Operations Deck.
## Supports WASD 6-DOF keyboard navigation, right-click mouse look, and quick presets.

signal request_exit_3d()
signal terminal_focus_changed(is_focused: bool)

enum ViewPreset {
	OPERATOR_FRONT,
	RACK_TELEMETRY,
	HOLO_TERMINAL,
	HASHRATE_WAVE,
	WIDE_OVERVIEW
}

enum CameraMode {
	FREE_FLIGHT,
	TERMINAL_FOCUS
}

@export var move_speed: float = 4.5
@export var sprint_multiplier: float = 2.2

var current_preset: ViewPreset = ViewPreset.OPERATOR_FRONT
var camera_mode: CameraMode = CameraMode.FREE_FLIGHT
var is_terminal_fullscreen: bool = false

var _preset_transforms: Dictionary = {
	ViewPreset.OPERATOR_FRONT: {
		"position": Vector3(0.0, 1.8, 5.8),
		"rotation_degrees": Vector3(-6.0, 0.0, 0.0)
	},
	ViewPreset.RACK_TELEMETRY: {
		"position": Vector3(-1.56, 1.35, -0.61),
		"rotation_degrees": Vector3(-2.0, 32.0, 0.0)
	},
	ViewPreset.HOLO_TERMINAL: {
		"position": Vector3(4.0, 1.35, 1.7),
		"rotation_degrees": Vector3(-2.0, -48.0, 0.0)
	},
	ViewPreset.HASHRATE_WAVE: {
		"position": Vector3(2.2, 1.35, -1.0),
		"rotation_degrees": Vector3(-4.0, -28.0, 0.0)
	},
	ViewPreset.WIDE_OVERVIEW: {
		"position": Vector3(0.0, 4.8, 11.0),
		"rotation_degrees": Vector3(-18.0, 0.0, 0.0)
	}
}

# First-Person realistic centered terminal position (ergonomic ~30% zoom approach)
const FP_TERMINAL_POS = Vector3(4.20, 1.35, 1.50)
const FP_TERMINAL_ROT = Vector3(-1.0, -48.0, 0.0)
const FULLSCREEN_TERMINAL_POS = Vector3(4.35, 1.36, 1.37)
const FULLSCREEN_FOV = 66.0
const DEFAULT_FOV = 68.0

var _pre_focus_pos: Vector3 = Vector3(0.0, 1.8, 6.2)
var _pre_focus_rot: Vector3 = Vector3(-6.0, 0.0, 0.0)
var _is_orbiting: bool = false
var _orbit_sensitivity: float = 0.25
var _zoom_speed: float = 0.35
var _tween: Tween = null

func _ready() -> void:
	fov = DEFAULT_FOV
	switch_preset(ViewPreset.OPERATOR_FRONT, 0.0)

func enter_terminal_focus(duration: float = 0.5) -> void:
	camera_mode = CameraMode.TERMINAL_FOCUS
	_is_orbiting = false
	is_terminal_fullscreen = false

	# Save pre-focus state to return smoothly later
	_pre_focus_pos = position
	_pre_focus_rot = rotation_degrees

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", FP_TERMINAL_POS, duration)
	_tween.tween_property(self, "rotation_degrees", FP_TERMINAL_ROT, duration)
	_tween.tween_property(self, "fov", DEFAULT_FOV, duration)

	terminal_focus_changed.emit(true)

func set_terminal_fullscreen(is_full: bool, duration: float = 0.4) -> void:
	if camera_mode != CameraMode.TERMINAL_FOCUS:
		return
	is_terminal_fullscreen = is_full

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if is_full:
		_tween.tween_property(self, "position", FULLSCREEN_TERMINAL_POS, duration)
		_tween.tween_property(self, "fov", FULLSCREEN_FOV, duration)
	else:
		_tween.tween_property(self, "position", FP_TERMINAL_POS, duration)
		_tween.tween_property(self, "fov", DEFAULT_FOV, duration)

func exit_terminal_focus(duration: float = 0.5) -> void:
	camera_mode = CameraMode.FREE_FLIGHT
	is_terminal_fullscreen = false
	_is_orbiting = false

	if _tween and _tween.is_valid():
		_tween.kill()

	var target_pos = _pre_focus_pos if _pre_focus_pos != Vector3.ZERO else _preset_transforms[ViewPreset.OPERATOR_FRONT]["position"]
	var target_rot = _pre_focus_rot if _pre_focus_rot != Vector3.ZERO else _preset_transforms[ViewPreset.OPERATOR_FRONT]["rotation_degrees"]

	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target_pos, duration)
	_tween.tween_property(self, "rotation_degrees", target_rot, duration)
	_tween.tween_property(self, "fov", DEFAULT_FOV, duration)

	terminal_focus_changed.emit(false)

func switch_preset(preset: ViewPreset, duration: float = 0.6) -> void:
	if camera_mode == CameraMode.TERMINAL_FOCUS:
		camera_mode = CameraMode.FREE_FLIGHT
		terminal_focus_changed.emit(false)

	current_preset = preset
	var target = _preset_transforms.get(preset, _preset_transforms[ViewPreset.OPERATOR_FRONT])

	if _tween and _tween.is_valid():
		_tween.kill()

	if duration <= 0.0:
		position = target["position"]
		rotation_degrees = target["rotation_degrees"]
		fov = DEFAULT_FOV
		return

	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target["position"], duration)
	_tween.tween_property(self, "rotation_degrees", target["rotation_degrees"], duration)
	_tween.tween_property(self, "fov", DEFAULT_FOV, duration)

func _process(delta: float) -> void:
	# While locked in Terminal Focus mode, WASD is disabled!
	if camera_mode == CameraMode.TERMINAL_FOCUS:
		return

	# WASD + Space/Ctrl Keyboard Navigation in Free Flight
	var input_dir: Vector3 = Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		input_dir -= transform.basis.z
	if Input.is_key_pressed(KEY_S):
		input_dir += transform.basis.z
	if Input.is_key_pressed(KEY_A):
		input_dir -= transform.basis.x
	if Input.is_key_pressed(KEY_D):
		input_dir += transform.basis.x
	if Input.is_key_pressed(KEY_SPACE):
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
	# If in Terminal Focus, allow ESC or E to exit focus
	if camera_mode == CameraMode.TERMINAL_FOCUS:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE:
				exit_terminal_focus()
				get_viewport().set_input_as_handled()
		return

	# Quick Preset Hotkeys in Free Flight: 1/F1, 2/F2, 3/F3, 4/F4, 5/F5
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

	# Right-click mouse look (only active in Free Flight)
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
