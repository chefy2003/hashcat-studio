class_name DashboardCamera3D
extends Camera3D

## Cinematic & First-Person physical player/camera controller for the 3D Operations Deck.
## Features:
## - True physical collision solidity via CharacterBody3D and move_and_slide()
## - First-person mouse capture (Input.MOUSE_MODE_CAPTURED) with free look
## - Cursor release (Input.MOUSE_MODE_VISIBLE) during active terminal/interaction focus
## - Minimalist cyberpunk central reticle and dynamic [E] prompt HUD
## - Integrated RayCast3D detecting Interactable3D objects in front of the player

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
@export var player_collision_radius: float = 0.35
@export var player_collision_height: float = 1.6
@export var mouse_sensitivity: float = 0.18

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

# First-Person realistic centered terminal position
const FP_TERMINAL_POS = Vector3(3.05, 1.40, -2.14)
const FP_TERMINAL_ROT = Vector3(-1.0, -55.0, 0.0)
const FULLSCREEN_TERMINAL_POS = Vector3(3.20, 1.40, -2.25)
const FULLSCREEN_FOV = 66.0
const DEFAULT_FOV = 68.0

var _pre_focus_pos: Vector3 = Vector3(0.0, EYE_HEIGHT, 5.8)
var _pre_focus_rot: Vector3 = Vector3(-6.0, 0.0, 0.0)
var _step_timer: float = 0.0
var _tween: Tween = null

# Physics & Interaction Components
var _char_body: CharacterBody3D = null
var _raycast: RayCast3D = null
var _hud_layer: CanvasLayer = null
var _hud_prompt_label: Label = null
var _hud_reticle: Control = null
var current_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED


func set_mouse_mode(mode: Input.MouseMode) -> void:
	current_mouse_mode = mode
	Input.mouse_mode = mode

func get_target_mouse_mode() -> Input.MouseMode:
	return current_mouse_mode

func _ready() -> void:
	fov = DEFAULT_FOV
	set_process(false) # Let engine run _physics_process; _process is kept for manual test invocations
	_setup_physics_body()
	_setup_interaction_hud()
	switch_preset(ViewPreset.OPERATOR_FRONT, 0.0)
	# Lock mouse cursor on entry to FPS walking mode
	set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _exit_tree() -> void:
	set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _char_body and is_instance_valid(_char_body):
		_char_body.queue_free()


func _setup_physics_body() -> void:
	_char_body = CharacterBody3D.new()
	_char_body.name = "PlayerBody3D"
	_char_body.collision_layer = 1
	_char_body.collision_mask = 1

	var col_shape = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = player_collision_radius
	capsule.height = player_collision_height
	col_shape.shape = capsule
	col_shape.position = Vector3(0.0, player_collision_height * 0.5, 0.0)
	_char_body.add_child(col_shape)

	if get_parent():
		get_parent().add_child.call_deferred(_char_body)
	else:
		add_child(_char_body)

	var px = global_position.x if is_inside_tree() else position.x
	var pz = global_position.z if is_inside_tree() else position.z
	_char_body.position = Vector3(px, 0.0, pz)


func _setup_interaction_hud() -> void:
	# CanvasLayer for minimalist cyberpunk crosshair reticle and prompt
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "InteractionHUDLayer"
	_hud_layer.layer = 5
	add_child(_hud_layer)

	var hud_root = Control.new()
	hud_root.name = "HUDRoot"
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(hud_root)

	# 1. Subtle central reticle dot/ring
	_hud_reticle = Control.new()
	_hud_reticle.name = "Reticle"
	_hud_reticle.set_anchors_preset(Control.PRESET_CENTER)
	_hud_reticle.custom_minimum_size = Vector2(24, 24)
	_hud_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_reticle.set_meta("is_focused", false)
	_hud_reticle.draw.connect(func():
		var center = Vector2(12, 12)
		var is_foc: bool = _hud_reticle.get_meta("is_focused", false)
		if is_foc:
			# Expanded neon cyan diamond/ring on active focus
			_hud_reticle.draw_arc(center, 7.0, 0, TAU, 16, Color("#00f0ff", 0.95), 1.6, true)
			_hud_reticle.draw_circle(center, 2.0, Color("#38bdf8", 1.0))
		else:
			# Subtle resting dot
			_hud_reticle.draw_circle(center, 2.2, Color("#00f0ff", 0.60))
			_hud_reticle.draw_arc(center, 4.5, 0, TAU, 12, Color("#00f0ff", 0.25), 1.0, true)
	)
	hud_root.add_child(_hud_reticle)

	# 2. Sleek dynamic interaction prompt label
	_hud_prompt_label = Label.new()
	_hud_prompt_label.name = "PromptLabel"
	_hud_prompt_label.anchor_left = 0.5
	_hud_prompt_label.anchor_right = 0.5
	_hud_prompt_label.anchor_top = 0.5
	_hud_prompt_label.anchor_bottom = 0.5
	_hud_prompt_label.offset_left = -160.0
	_hud_prompt_label.offset_right = 160.0
	_hud_prompt_label.offset_top = 22.0
	_hud_prompt_label.offset_bottom = 54.0
	_hud_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hud_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_prompt_label.visible = false

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.15, 0.85)
	style.border_color = Color(0.0, 0.94, 1.0, 0.80)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	_hud_prompt_label.add_theme_stylebox_override("normal", style)
	_hud_prompt_label.add_theme_color_override("font_color", Color("#00f0ff"))
	_hud_prompt_label.add_theme_font_size_override("font_size", 13)
	hud_root.add_child(_hud_prompt_label)

	# 3. RayCast3D attached directly to Camera3D
	var ray_script = preload("res://scripts/ui/3d/player_interaction_raycast_3d.gd")
	_raycast = RayCast3D.new()
	_raycast.name = "InteractionRayCast"
	_raycast.set_script(ray_script)
	_raycast.set("prompt_label", _hud_prompt_label)
	_raycast.set("reticle_node", _hud_reticle)
	add_child(_raycast)

func enter_terminal_focus(duration: float = 0.5) -> void:
	camera_mode = CameraMode.TERMINAL_FOCUS
	is_terminal_fullscreen = false
	_is_jumping = false
	_vertical_velocity = 0.0
	_jump_offset = 0.0
	_current_base_height = EYE_HEIGHT

	# Free cursor for terminal GUI interaction
	set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if _hud_layer:
		_hud_layer.visible = false

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
	_is_jumping = false
	_vertical_velocity = 0.0
	_jump_offset = 0.0
	_current_base_height = EYE_HEIGHT

	# Lock cursor again for FPS walking navigation
	set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if _hud_layer:
		_hud_layer.visible = true

	if _tween and _tween.is_valid():
		_tween.kill()

	var target_pos = _pre_focus_pos if _pre_focus_pos != Vector3.ZERO else _preset_transforms[ViewPreset.OPERATOR_FRONT]["position"]
	var target_rot = _pre_focus_rot if _pre_focus_rot != Vector3.ZERO else _preset_transforms[ViewPreset.OPERATOR_FRONT]["rotation_degrees"]

	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target_pos, duration)
	_tween.tween_property(self, "rotation_degrees", target_rot, duration)
	_tween.tween_property(self, "fov", DEFAULT_FOV, duration)

	if _char_body and is_instance_valid(_char_body):
		_char_body.global_position = Vector3(target_pos.x, 0.0, target_pos.z)
		_char_body.velocity = Vector3.ZERO

	terminal_focus_changed.emit(false)

func switch_preset(preset: ViewPreset, duration: float = 0.6) -> void:
	if camera_mode == CameraMode.TERMINAL_FOCUS:
		camera_mode = CameraMode.FREE_FLIGHT
		terminal_focus_changed.emit(false)
		set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		if _hud_layer:
			_hud_layer.visible = true

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
		if _char_body and is_instance_valid(_char_body):
			if _char_body.is_inside_tree():
				_char_body.global_position = Vector3(position.x, 0.0, position.z)
			else:
				_char_body.position = Vector3(position.x, 0.0, position.z)
			_char_body.velocity = Vector3.ZERO

		return

	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target["position"], duration)
	_tween.tween_property(self, "rotation_degrees", target["rotation_degrees"], duration)
	_tween.tween_property(self, "fov", DEFAULT_FOV, duration)

	if _char_body and is_instance_valid(_char_body):
		_char_body.global_position = Vector3(target["position"].x, 0.0, target["position"].z)
		_char_body.velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
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

	# Jump vertical arc physics
	if _is_jumping:
		_vertical_velocity -= GRAVITY * delta
		_jump_offset += _vertical_velocity * delta
		if _jump_offset <= 0.0:
			_jump_offset = 0.0
			_vertical_velocity = 0.0
			_is_jumping = false

	# First-Person Grounded Walking Navigation (XZ Floor Plane only)
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

	var pos_x = global_position.x if is_inside_tree() else position.x
	var pos_z = global_position.z if is_inside_tree() else position.z

	if _char_body and is_instance_valid(_char_body) and _char_body.is_inside_tree():
		if is_moving:
			if current_preset == ViewPreset.WIDE_OVERVIEW:
				current_preset = ViewPreset.OPERATOR_FRONT

			_char_body.velocity = input_dir.normalized() * current_speed
			_char_body.move_and_slide()
			pos_x = _char_body.global_position.x
			pos_z = _char_body.global_position.z
			_step_timer += delta * (10.0 if not Input.is_key_pressed(KEY_SHIFT) else 14.0)
		else:
			_char_body.velocity = Vector3.ZERO
			_step_timer = lerpf(_step_timer, 0.0, delta * 8.0)
	else:
		if is_moving:
			var move_step: Vector3 = input_dir.normalized() * current_speed * delta
			var resolved_step: Vector3 = _move_with_collision(move_step)
			pos_x += resolved_step.x
			pos_z += resolved_step.z
			_step_timer += delta * (10.0 if not Input.is_key_pressed(KEY_SHIFT) else 14.0)
		else:
			_step_timer = lerpf(_step_timer, 0.0, delta * 8.0)

	# Clamp player walking bounds within arena deck
	pos_x = clampf(pos_x, -8.5, 8.5)
	pos_z = clampf(pos_z, -5.5, 8.5)

	if is_inside_tree():
		global_position.x = pos_x
		global_position.z = pos_z
	else:
		position.x = pos_x
		position.z = pos_z

	if _char_body and is_instance_valid(_char_body) and _char_body.is_inside_tree():
		_char_body.global_position.x = pos_x
		_char_body.global_position.z = pos_z

	# Enforce human eye height + crouch + jump + organic subtle walking head bob
	if current_preset != ViewPreset.WIDE_OVERVIEW:
		var bob_offset: float = (sin(_step_timer) * 0.022) if (not _is_jumping) else 0.0
		var pos_y = _current_base_height + _jump_offset + bob_offset
		if is_inside_tree():
			global_position.y = pos_y
		else:
			position.y = pos_y

func _process(delta: float) -> void:
	_physics_process(delta)


func _move_with_collision(motion: Vector3) -> Vector3:
	if not _char_body or not is_instance_valid(_char_body) or not _char_body.is_inside_tree():
		return motion

	_char_body.global_position = Vector3(global_position.x, 0.0, global_position.z)

	var col = KinematicCollision3D.new()
	var hit = _char_body.test_move(_char_body.global_transform, motion, col)
	if not hit:
		return motion

	var travel = col.get_travel()
	var remainder = col.get_remainder()
	var normal = col.get_normal()
	normal.y = 0.0
	if normal.length_squared() > 0.001:
		normal = normal.normalized()
		var slide = remainder.slide(normal)
		var slide_col = KinematicCollision3D.new()
		var test_transform = _char_body.global_transform.translated(travel)
		if not _char_body.test_move(test_transform, slide, slide_col):
			travel += slide
		else:
			travel += slide_col.get_travel()
	return travel

func _unhandled_input(event: InputEvent) -> void:
	# In Terminal Focus, allow ESC to exit focus and re-capture cursor
	if camera_mode == CameraMode.TERMINAL_FOCUS:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_ESCAPE:
				exit_terminal_focus()
				get_viewport().set_input_as_handled()
		return

	# Re-capture mouse on left click if focus was lost in free flight
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_mouse_mode != Input.MOUSE_MODE_CAPTURED:
			set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_viewport().set_input_as_handled()
			return

	# First-person mouse look (pitch and yaw directly from mouse motion)
	if event is InputEventMouseMotion and (current_mouse_mode == Input.MOUSE_MODE_CAPTURED or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		rotation_degrees.x = clamp(rotation_degrees.x - event.relative.y * mouse_sensitivity, -75.0, 75.0)

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
				set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
