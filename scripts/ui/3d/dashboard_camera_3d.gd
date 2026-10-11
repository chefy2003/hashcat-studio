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
@export var crouch_multiplier: float = 0.55

var current_preset: ViewPreset = ViewPreset.OPERATOR_FRONT
var camera_mode: CameraMode = CameraMode.FREE_FLIGHT
var is_terminal_fullscreen: bool = false

const EYE_HEIGHT: float = 1.72
const CROUCH_HEIGHT: float = 1.05
const JUMP_VELOCITY: float = 4.2
const GRAVITY: float = 13.5

var _current_base_height: float = EYE_HEIGHT
var _vertical_velocity: float = 0.0
var _jump_offset: float = 0.0
var _is_jumping: bool = false
var _is_crouching: bool = false

var _preset_transforms: Dictionary = {
	ViewPreset.OPERATOR_FRONT: {
		"position": Vector3(0.0, EYE_HEIGHT, 5.8),
		"rotation_degrees": Vector3(-6.0, 0.0, 0.0)
	},
	ViewPreset.RACK_TELEMETRY: {
		"position": Vector3(-2.80, EYE_HEIGHT, -1.90),
		"rotation_degrees": Vector3(-4.0, 35.0, 0.0)
	},
	ViewPreset.HOLO_TERMINAL: {
		"position": Vector3(2.80, EYE_HEIGHT, -1.90),
		"rotation_degrees": Vector3(-2.0, -55.0, 0.0)
	},
	ViewPreset.HASHRATE_WAVE: {
		"position": Vector3(0.0, EYE_HEIGHT, -2.90),
		"rotation_degrees": Vector3(-4.0, 0.0, 0.0)
	},
	ViewPreset.WIDE_OVERVIEW: {
		"position": Vector3(0.0, 5.2, 9.8),
		"rotation_degrees": Vector3(-20.0, 0.0, 0.0)
	}
}

# First-Person realistic centered terminal position (ergonomic ~30% zoom approach)
const FP_TERMINAL_POS = Vector3(3.05, 1.40, -2.14)
const FP_TERMINAL_ROT = Vector3(-1.0, -55.0, 0.0)
const FULLSCREEN_TERMINAL_POS = Vector3(3.20, 1.40, -2.25)
const FULLSCREEN_FOV = 66.0
const DEFAULT_FOV = 68.0

var _pre_focus_pos: Vector3 = Vector3(0.0, EYE_HEIGHT, 5.8)
var _pre_focus_rot: Vector3 = Vector3(-6.0, 0.0, 0.0)
var _is_orbiting: bool = false
var _orbit_sensitivity: float = 0.25
var _step_timer: float = 0.0
var _tween: Tween = null

func _ready() -> void:
	fov = DEFAULT_FOV
	switch_preset(ViewPreset.OPERATOR_FRONT, 0.0)

func enter_terminal_focus(duration: float = 0.5) -> void:
	camera_mode = CameraMode.TERMINAL_FOCUS
	_is_orbiting = false
	is_terminal_fullscreen = false
	_is_jumping = false
	_vertical_velocity = 0.0
	_jump_offset = 0.0
	_current_base_height = EYE_HEIGHT

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
	_is_jumping = false
	_vertical_velocity = 0.0
	_jump_offset = 0.0
	_current_base_height = EYE_HEIGHT

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

	_is_jumping = false
	_vertical_velocity = 0.0
	_jump_offset = 0.0
	_current_base_height = EYE_HEIGHT

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
	# While locked in Terminal Focus mode, walking movement is disabled
	if camera_mode == CameraMode.TERMINAL_FOCUS:
		return

	# If a preset transition tween is active, don't override camera transform
	if _tween and _tween.is_valid():
		return

	# Handle Crouch input (CTRL)
	_is_crouching = Input.is_key_pressed(KEY_CTRL)
	var target_base_height: float = CROUCH_HEIGHT if _is_crouching else EYE_HEIGHT
	_current_base_height = lerpf(_current_base_height, target_base_height, delta * 12.0)

	# Handle Jump input (SPACE) - only if grounded and not crouching
	if Input.is_key_pressed(KEY_SPACE) and not _is_jumping and not _is_crouching and _jump_offset <= 0.001:
		_is_jumping = true
		_vertical_velocity = JUMP_VELOCITY
		if current_preset == ViewPreset.WIDE_OVERVIEW:
			current_preset = ViewPreset.OPERATOR_FRONT

	# Jump physics (gravity & vertical arc)
	if _is_jumping:
		_vertical_velocity -= GRAVITY * delta
		_jump_offset += _vertical_velocity * delta
		if _jump_offset <= 0.0:
			_jump_offset = 0.0
			_vertical_velocity = 0.0
			_is_jumping = false

	# First-Person Grounded Walking Navigation (XZ Floor Plane only - No flying/diving)
	var yaw_rad: float = deg_to_rad(rotation_degrees.y)
	var forward: Vector3 = Vector3(-sin(yaw_rad), 0.0, -cos(yaw_rad)).normalized()
	var right: Vector3 = Vector3(cos(yaw_rad), 0.0, -sin(yaw_rad)).normalized()

	var input_dir: Vector3 = Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		input_dir += forward
	if Input.is_key_pressed(KEY_S):
		input_dir -= forward
	if Input.is_key_pressed(KEY_A):
		input_dir -= right
	if Input.is_key_pressed(KEY_D):
		input_dir += right

	var is_moving: bool = input_dir.length_squared() > 0.001
	var current_speed: float = move_speed
	if _is_crouching:
		current_speed *= crouch_multiplier
	elif Input.is_key_pressed(KEY_SHIFT):
		current_speed *= sprint_multiplier

	if is_moving:
		# If user starts walking while in WIDE_OVERVIEW preset, reset preset to custom
		if current_preset == ViewPreset.WIDE_OVERVIEW:
			current_preset = ViewPreset.OPERATOR_FRONT

		var move_step: Vector3 = input_dir.normalized() * current_speed * delta
		global_position.x += move_step.x
		global_position.z += move_step.z
		_step_timer += delta * (10.0 if not Input.is_key_pressed(KEY_SHIFT) else 14.0)
	else:
		_step_timer = lerpf(_step_timer, 0.0, delta * 8.0)

	# Clamp player walking bounds within arena deck
	global_position.x = clampf(global_position.x, -8.5, 8.5)
	global_position.z = clampf(global_position.z, -5.5, 8.5)

	# Enforce human eye height + crouch + jump + organic subtle walking head bob (only on deck)
	if current_preset != ViewPreset.WIDE_OVERVIEW:
		var bob_offset: float = (sin(_step_timer) * 0.022) if (not _is_jumping) else 0.0
		global_position.y = _current_base_height + _jump_offset + bob_offset

func _unhandled_input(event: InputEvent) -> void:
	# If in Terminal Focus, allow ESC to exit focus
	if camera_mode == CameraMode.TERMINAL_FOCUS:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE:
				exit_terminal_focus()
				get_viewport().set_input_as_handled()
		return

	# Single-tap Jump trigger via Space
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			if not _is_jumping and not _is_crouching and _jump_offset <= 0.001:
				_is_jumping = true
				_vertical_velocity = JUMP_VELOCITY
				if current_preset == ViewPreset.WIDE_OVERVIEW:
					current_preset = ViewPreset.OPERATOR_FRONT
				get_viewport().set_input_as_handled()
				return

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

	# Right-click mouse look for operator yaw & pitch inspection
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_orbiting = event.pressed

	elif event is InputEventMouseMotion and _is_orbiting:
		rotation_degrees.y -= event.relative.x * _orbit_sensitivity
		rotation_degrees.x = clamp(rotation_degrees.x - event.relative.y * _orbit_sensitivity, -70.0, 70.0)
