# ==============================================================================
#  WIZARD ANIMATOR С ШЕЙДЪРЕН ЕФЕКТ - GODOT 4
# ==============================================================================
class_name WizardAnimatorWithShader
extends Control

# Референции към контролните бутони (Scene Unique Nodes)
@onready var btn_back: Button = get_node_or_null("%BtnBack") as Button
@onready var btn_next: Button = get_node_or_null("%BtnNext") as Button
@onready var stepper_header: HBoxContainer = get_node_or_null("%StepperHeader") as HBoxContainer

# Път до шейдъра
const TRANSITION_SHADER = preload("res://transition_blur_glitch.gdshader")

# Конфигурация на анимацията
const STEP_WIDTH: float = 800.0
const TRANSITION_DURATION: float = 0.45 # Малко по-дълга за по-добро виждане на шейдъра

var current_step_index: int = 0
var total_steps: int = 3
var is_animating: bool = false

func _ready() -> void:
	if btn_back == null:
		btn_back = get_node_or_null("%BtnBack") as Button
	if btn_next == null:
		btn_next = get_node_or_null("%BtnNext") as Button
	if stepper_header == null:
		stepper_header = get_node_or_null("%StepperHeader") as HBoxContainer

	if btn_back and not btn_back.pressed.is_connected(_on_btn_back_pressed):
		btn_back.pressed.connect(_on_btn_back_pressed)
	if btn_next and not btn_next.pressed.is_connected(_on_btn_next_pressed):
		btn_next.pressed.connect(_on_btn_next_pressed)

	_initialize_steps_layout()
	_update_ui_state()
	_update_stepper_indicators()

## Инициализира позициите на стъпките и им закача шейдъра програмно
func _initialize_steps_layout() -> void:
	var children = get_children()
	total_steps = children.size()
	position = Vector2.ZERO
	
	for i in range(total_steps):
		var step_panel = children[i] as Control
		if step_panel:
			step_panel.position.x = i * STEP_WIDTH
			step_panel.position.y = 0
			step_panel.size = Vector2(STEP_WIDTH, step_panel.size.y)
			step_panel.pivot_offset = step_panel.size / 2.0
			
			# Създаваме и прилагаме ShaderMaterial програмно
			var mat = ShaderMaterial.new()
			mat.shader = TRANSITION_SHADER
			mat.set_shader_parameter("transition_progress", 0.0)
			step_panel.material = mat
			
			if i == 0:
				step_panel.modulate.a = 1.0
			else:
				step_panel.modulate.a = 0.0

## Смяна на стъпката с хоризонтален преход и шейдърно изкривяване
func transition_to_step(target_index: int) -> void:
	if is_animating or target_index < 0 or target_index >= total_steps:
		return
		
	is_animating = true
	
	var old_step_node = get_child(current_step_index) as Control
	var new_step_node = get_child(target_index) as Control
	
	var old_material = old_step_node.material as ShaderMaterial if old_step_node else null
	var new_material = new_step_node.material as ShaderMaterial if new_step_node else null
	
	current_step_index = target_index
	_update_stepper_indicators()
	
	var target_x: float = -float(current_step_index) * STEP_WIDTH
	
	# Главен Tween за физическото движение и прозрачността
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:x", target_x, TRANSITION_DURATION)
	if old_step_node:
		tween.tween_property(old_step_node, "modulate:a", 0.0, TRANSITION_DURATION * 0.5)
	if new_step_node:
		tween.tween_property(new_step_node, "modulate:a", 1.0, TRANSITION_DURATION)
	
	# Вторичен Tween за шейдърното изкривяване (достига пик в средата и угасва)
	var shader_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Пулс анимация на шейдъра от 0.0 -> 1.0 -> 0.0
	if old_material:
		shader_tween.tween_property(old_material, "shader_parameter/transition_progress", 1.0, TRANSITION_DURATION * 0.4)
		shader_tween.tween_property(old_material, "shader_parameter/transition_progress", 0.0, TRANSITION_DURATION * 0.6).set_delay(TRANSITION_DURATION * 0.4)
		
	if new_material:
		shader_tween.tween_property(new_material, "shader_parameter/transition_progress", 1.0, TRANSITION_DURATION * 0.4)
		shader_tween.tween_property(new_material, "shader_parameter/transition_progress", 0.0, TRANSITION_DURATION * 0.6).set_delay(TRANSITION_DURATION * 0.4)
	
	# Финализиране на прехода
	tween.chain().tween_callback(func():
		is_animating = false
		_update_ui_state()
	)

func _update_ui_state() -> void:
	if btn_back:
		btn_back.visible = (current_step_index > 0)
	if btn_next:
		if current_step_index == total_steps - 1:
			btn_next.text = "⚡ СТАРТИРАЙ АТАКА"
			btn_next.modulate = Color("#10B981")
		else:
			btn_next.text = "Напред ➡"
			btn_next.modulate = Color.WHITE

func _update_stepper_indicators() -> void:
	if not stepper_header:
		return
	var indicators = stepper_header.get_children()
	for i in range(indicators.size()):
		var indicator = indicators[i] as Control
		if not indicator: continue
		var indicator_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if i == current_step_index:
			indicator_tween.tween_property(indicator, "modulate", Color("#10B981"), 0.2)
			indicator_tween.parallel().tween_property(indicator, "scale", Vector2(1.15, 1.15), 0.2)
		elif i < current_step_index:
			indicator_tween.tween_property(indicator, "modulate", Color("#059669"), 0.2)
			indicator_tween.parallel().tween_property(indicator, "scale", Vector2.ONE, 0.2)
		else:
			indicator_tween.tween_property(indicator, "modulate", Color("#334155"), 0.2)
			indicator_tween.parallel().tween_property(indicator, "scale", Vector2.ONE, 0.2)

func _on_btn_back_pressed() -> void:
	if current_step_index > 0 and not is_animating:
		transition_to_step(current_step_index - 1)

func _on_btn_next_pressed() -> void:
	if current_step_index < total_steps - 1 and not is_animating:
		transition_to_step(current_step_index + 1)
	elif current_step_index == total_steps - 1 and not is_animating:
		var main_ui = get_tree().current_scene
		if main_ui and main_ui.has_method("toggle_view"):
			main_ui.toggle_view(true)
		elif main_ui and main_ui.has_method("show_monitoring_view"):
			main_ui.show_monitoring_view()
