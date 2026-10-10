# ==============================================================================
#  WIZARD ANIMATOR - УПРАВЛЕНИЕ НА ПРЕХОДИТЕ МЕЖДУ СТЪПКИТЕ В GODOT 4
# ==============================================================================
class_name WizardAnimator
extends Control

# Референции към контролните бутони (Scene Unique Nodes)
@onready var btn_back: Button = get_node_or_null("%BtnBack") as Button
@onready var btn_next: Button = get_node_or_null("%BtnNext") as Button
@onready var stepper_header: HBoxContainer = get_node_or_null("%StepperHeader") as HBoxContainer

# Конфигурация на анимацията
const STEP_WIDTH: float = 800.0 # Ширината на една стъпка (трябва да съвпада с viewport размера)
const TRANSITION_DURATION: float = 0.35 # Продължителност на анимацията в секунди

var current_step_index: int = 0
var total_steps: int = 3
var is_animating: bool = false

func _ready() -> void:
	# Подсигуряваме резолюцията на Scene Unique Nodes
	if btn_back == null:
		btn_back = get_node_or_null("%BtnBack") as Button
	if btn_next == null:
		btn_next = get_node_or_null("%BtnNext") as Button
	if stepper_header == null:
		stepper_header = get_node_or_null("%StepperHeader") as HBoxContainer

	# Свързваме сигналите от бутоните програмно ако са налични
	if btn_back and not btn_back.pressed.is_connected(_on_btn_back_pressed):
		btn_back.pressed.connect(_on_btn_back_pressed)
	if btn_next and not btn_next.pressed.is_connected(_on_btn_next_pressed):
		btn_next.pressed.connect(_on_btn_next_pressed)

	# 1. Задаваме стартова позиция и прозрачност на стъпките
	_initialize_steps_layout()
	# 2. Обновяваме визуалното състояние на бутоните и индикаторите
	_update_ui_state()
	_update_stepper_indicators()

## Инициализира позициите на стъпките хоризонтално в редица
func _initialize_steps_layout() -> void:
	var children = get_children()
	total_steps = children.size()
	
	# Подсигуряваме, че pivot точката на родителя е нулирана за коректно местене
	position = Vector2.ZERO
	
	for i in range(total_steps):
		var step_panel = children[i] as Control
		if step_panel:
			# Подреждаме ги една след друга по хоризонтала: 0, 800, 1600 и т.н.
			step_panel.position.x = i * STEP_WIDTH
			step_panel.position.y = 0
			step_panel.size = Vector2(STEP_WIDTH, step_panel.size.y)
			
			# Задаваме pivot точката в центъра на панела за правилно мащабиране
			step_panel.pivot_offset = step_panel.size / 2.0
			
			# Само първата стъпка е напълно видима в началото, другите са приглушени
			if i == 0:
				step_panel.modulate.a = 1.0
			else:
				step_panel.modulate.a = 0.0

## Сменя стъпката с плавна анимация тип "Slide & Cross-fade"
func transition_to_step(target_index: int) -> void:
	if is_animating or target_index < 0 or target_index >= total_steps:
		return
		
	is_animating = true
	
	var old_step_node = get_child(current_step_index) as Control
	var new_step_node = get_child(target_index) as Control
	
	current_step_index = target_index
	_update_stepper_indicators()
	
	# Изчисляваме целевата хоризонтална позиция на контейнера
	var target_x: float = -float(current_step_index) * STEP_WIDTH
	
	# Инициализираме паралелен Tween в Godot 4 за синхронни ефекти
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
	# АНИМАЦИЯ 1: Плавно плъзгане по Х оста на цялата редица от стъпки
	tween.tween_property(self, "position:x", target_x, TRANSITION_DURATION)
	
	# АНИМАЦИЯ 2: Избледняване на старата стъпка (Fade-out)
	if old_step_node:
		tween.tween_property(old_step_node, "modulate:a", 0.0, TRANSITION_DURATION * 0.7)
	
	# АНИМАЦИЯ 3: Появяване на новата стъпка (Fade-in)
	if new_step_node:
		tween.tween_property(new_step_node, "modulate:a", 1.0, TRANSITION_DURATION)
		# АНИМАЦИЯ 4: Лек "Zoom-In" ефект (Scale Pop) за обемност на новия панел
		new_step_node.scale = Vector2(0.97, 0.97) # Леко свиваме
		tween.tween_property(new_step_node, "scale", Vector2.ONE, TRANSITION_DURATION) # Разпъваме до 100%
	
	# След като завърши Tween анимацията, отключваме контролите
	tween.chain().tween_callback(func():
		is_animating = false
		_update_ui_state()
	)

## Актуализира състоянието на бутоните за управление
func _update_ui_state() -> void:
	if btn_back:
		# Бутонът Назад се показва само след първата стъпка
		btn_back.visible = (current_step_index > 0)
	
	if btn_next:
		# Бутонът Напред се превръща в "СТАРТИРАЙ АТАКА" на последната стъпка
		if current_step_index == total_steps - 1:
			btn_next.text = "⚡ СТАРТИРАЙ АТАКА"
			# Преминаваме към светещ неоново-зелен цвят на бутона
			btn_next.modulate = Color("#10B981")
		else:
			btn_next.text = "Напред ➡"
			btn_next.modulate = Color.WHITE

## Обновява визуалното състояние на сферичните индикатори в заглавната част
func _update_stepper_indicators() -> void:
	if not stepper_header:
		return
		
	var indicators = stepper_header.get_children()
	for i in range(indicators.size()):
		var indicator = indicators[i] as Control
		if not indicator:
			continue
			
		var indicator_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		if i == current_step_index:
			# Активната стъпка светва ярко и се уголемява леко
			indicator_tween.tween_property(indicator, "modulate", Color("#10B981"), 0.2)
			indicator_tween.parallel().tween_property(indicator, "scale", Vector2(1.15, 1.15), 0.2)
		elif i < current_step_index:
			# Изминалите стъпки светят в по-меко тъмнозелено
			indicator_tween.tween_property(indicator, "modulate", Color("#059669"), 0.2)
			indicator_tween.parallel().tween_property(indicator, "scale", Vector2.ONE, 0.2)
		else:
			# Бъдещите стъпки са приглушено сиви
			indicator_tween.tween_property(indicator, "modulate", Color("#334155"), 0.2)
			indicator_tween.parallel().tween_property(indicator, "scale", Vector2.ONE, 0.2)

# СИГНАЛИ ОТ БУТОНИТЕ (Завързани през Godot Editor)
func _on_btn_back_pressed() -> void:
	if current_step_index > 0 and not is_animating:
		transition_to_step(current_step_index - 1)

func _on_btn_next_pressed() -> void:
	if current_step_index < total_steps - 1 and not is_animating:
		transition_to_step(current_step_index + 1)
	elif current_step_index == total_steps - 1 and not is_animating:
		_on_launch_requested()

func _on_launch_requested() -> void:
	# Извикваме превключването към екрана за мониторинг
	var main_ui = get_tree().current_scene
	if main_ui and main_ui.has_method("toggle_view"):
		main_ui.toggle_view(true)
	elif main_ui and main_ui.has_method("show_monitoring_view"):
		main_ui.show_monitoring_view()
