class_name DashboardCamera3D
extends Camera3D

## Cinematic camera controller for the 3D Operations Deck.
## Supports smooth tweened preset transitions and interactive mouse orbit.

enum ViewPreset {
	OPERATOR_FRONT,
	RACK_TELEMETRY,
	HASHRATE_WAVE,
	WIDE_OVERVIEW
}

var current_preset: ViewPreset = ViewPreset.OPERATOR_FRONT

var _preset_transforms: Dictionary = {
	ViewPreset.OPERATOR_FRONT: {
		"position": Vector3(0.0, 1.38, 2.85),
		"rotation_degrees": Vector3(-4.0, 0.0, 0.0)
	},
	ViewPreset.RACK_TELEMETRY: {
		"position": Vector3(-2.6, 1.15, 1.9),
		"rotation_degrees": Vector3(-4.0, 22.0, 0.0)
	},
	ViewPreset.HASHRATE_WAVE: {
		"position": Vector3(2.7, 1.25, 2.0),
		"rotation_degrees": Vector3(-6.0, -18.0, 0.0)
	},
	ViewPreset.WIDE_OVERVIEW: {
		"position": Vector3(0.0, 2.2, 4.2),
		"rotation_degrees": Vector3(-18.0, 0.0, 0.0)
	}
}

var _is_orbiting: bool = false
var _orbit_sensitivity: float = 0.25
var _zoom_speed: float = 0.25
var _tween: Tween = null

func _ready() -> void:
	switch_preset(ViewPreset.OPERATOR_FRONT, 0.0)

func switch_preset(preset: ViewPreset, duration: float = 0.5) -> void:
	current_preset = preset
	var target = _preset_transforms[preset]

	if _tween and _tween.is_valid():
		_tween.kill()

	if duration <= 0.0:
		position = target["position"]
		rotation_degrees = target["rotation_degrees"]
		return

	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position", target["position"], duration)
	_tween.tween_property(self, "rotation_degrees", target["rotation_degrees"], duration)

func _unhandled_input(event: InputEvent) -> void:
	# Preset Keys: 1/F1, 2/F2, 3/F3, 4/F4
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1, KEY_F1:
				switch_preset(ViewPreset.OPERATOR_FRONT)
			KEY_2, KEY_F2:
				switch_preset(ViewPreset.RACK_TELEMETRY)
			KEY_3, KEY_F3:
				switch_preset(ViewPreset.HASHRATE_WAVE)
			KEY_4, KEY_F4:
				switch_preset(ViewPreset.WIDE_OVERVIEW)

	# Right click orbit drag
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_is_orbiting = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			translate(Vector3(0.0, 0.0, -_zoom_speed))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			translate(Vector3(0.0, 0.0, _zoom_speed))

	elif event is InputEventMouseMotion and _is_orbiting:
		rotation_degrees.y -= event.relative.x * _orbit_sensitivity
		rotation_degrees.x = clamp(rotation_degrees.x - event.relative.y * _orbit_sensitivity, -60.0, 60.0)
