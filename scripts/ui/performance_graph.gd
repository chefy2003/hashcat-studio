class_name PerformanceGraph
extends Control

## Dynamic Hashrate Real-Time Vector Graph for Godot 4.
## Hardware-accelerated 2D vector drawing via _draw().
## Modern Cyberpunk Emerald polyline, translucent gradient fill, and live pulsing glow point.

@export var max_data_points: int = 50
@export var line_color: Color = Color("#10B981") # Modern Emerald Green
@export var fill_color: Color = Color(0.063, 0.725, 0.506, 0.18) # Translucent Emerald Fill
@export var bg_color: Color = Color("#070B12") # Deep Cyber Obsidian
@export var border_color: Color = Color("#1E293B") # Crisp Slate Border
@export var grid_color: Color = Color(0.18, 0.24, 0.35, 0.35) # Subtle Slate Grid
@export var text_color: Color = Color("#F8FAFC") # Crisp White Slate 50

var data_points: Array[float] = []
var max_value: float = 10.0
var _current_value: float = 0.0
var _peak_value: float = 0.0
var _current_raw_str: String = "0 H/s"
var _pulse_phase: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(250, 130)
	for i in range(max_data_points):
		data_points.append(0.0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _process(delta: float) -> void:
	_pulse_phase += delta * 4.0
	if _pulse_phase > TAU:
		_pulse_phase -= TAU
	if _current_value > 0.0:
		queue_redraw()

## Add new real-time hashrate value from Hashcat engine
func add_new_hashrate_value(value: float, raw_str: String = "") -> void:
	_current_value = value
	if not raw_str.is_empty():
		_current_raw_str = raw_str
	elif value > 0.0:
		_current_raw_str = str(snapped(value, 0.01)) + " MH/s"

	if value > _peak_value:
		_peak_value = value

	data_points.append(value)
	if data_points.size() > max_data_points:
		data_points.pop_front()

	# Dynamic scale adaptation with 20% headroom
	max_value = 10.0
	for val in data_points:
		if val > max_value:
			max_value = val * 1.2

	queue_redraw()

## Backward-compatible method called by MainUI and HashcatBridge
func push_sample(value: float, raw_str: String) -> void:
	add_new_hashrate_value(value, raw_str)

func reset_graph() -> void:
	data_points.clear()
	for i in range(max_data_points):
		data_points.append(0.0)
	max_value = 10.0
	_peak_value = 0.0
	_current_value = 0.0
	_current_raw_str = "0 H/s"
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 10 or h <= 10:
		return

	# 1. Dark Slate Background with clean border
	draw_rect(Rect2(Vector2.ZERO, size), bg_color)
	draw_rect(Rect2(Vector2.ZERO, size), border_color, false, 1.0)

	# 2. Subtle horizontal & vertical cyber grid guidelines
	for pct in [0.25, 0.50, 0.75]:
		var gy: float = h * (1.0 - pct)
		draw_line(Vector2(0, gy), Vector2(w, gy), grid_color, 1.0, true)

	for v_pct in [0.2, 0.4, 0.6, 0.8]:
		var gx: float = w * v_pct
		draw_line(Vector2(gx, 0), Vector2(gx, h), Color(grid_color.r, grid_color.g, grid_color.b, 0.15), 1.0, true)

	if data_points.size() < 2:
		return

	var step: float = w / float(max_data_points - 1)
	var points: PackedVector2Array = []
	var fill_points: PackedVector2Array = []

	# Bottom-left origin for fill polygon
	fill_points.append(Vector2(0, h))

	for i in range(data_points.size()):
		var x: float = float(i) * step
		var norm_y: float = data_points[i] / maxf(max_value, 1.0)
		var y: float = h - (norm_y * (h - 24.0)) - 6.0
		y = clampf(y, 10.0, h - 2.0)

		var pt: Vector2 = Vector2(x, y)
		points.append(pt)
		fill_points.append(pt)

	# Bottom-right corner for fill polygon
	fill_points.append(Vector2(float(data_points.size() - 1) * step, h))

	# 3. Translucent Emerald fill polygon underneath curve (only when active)
	if _peak_value > 0.0 and fill_points.size() > 3:
		draw_polygon(fill_points, [fill_color])

	# 4. Smooth 3.0px Anti-Aliased Emerald Polyline
	if points.size() > 1:
		draw_polyline(points, line_color, 3.0, true)

	# 5. Pulsing Glow Indicator at current point
	if points.size() > 0:
		var last_pt: Vector2 = points[-1]
		var pulse_radius: float = 7.0 + sin(_pulse_phase) * 2.0
		var pulse_alpha: float = 0.35 + sin(_pulse_phase) * 0.15

		draw_circle(last_pt, 4.5, line_color)
		draw_arc(last_pt, pulse_radius, 0, TAU, 32, Color(line_color.r, line_color.g, line_color.b, pulse_alpha), 2.0, true)

	# 6. High-Contrast Typography Labels
	var default_font: Font = ThemeDB.fallback_font
	var font_size: int = 11

	var label_current: String = "⚡ SPEED: " + _current_raw_str
	draw_string(default_font, Vector2(12, 18), label_current, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, line_color)

	if _peak_value > 0.0:
		var label_peak: String = "★ PEAK: " + str(snapped(_peak_value, 0.01)) + " MH/s"
		draw_string(default_font, Vector2(w - 150, 18), label_peak, HORIZONTAL_ALIGNMENT_RIGHT, 140, font_size, Color("#F59E0B"))
	else:
		draw_string(default_font, Vector2(w - 150, 18), "STANDBY // READY", HORIZONTAL_ALIGNMENT_RIGHT, 140, font_size, Color("#64748B"))

