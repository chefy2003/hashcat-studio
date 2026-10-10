class_name DynamicGuiController
extends Control

## Dynamic GUI Controller for Hashcat Intelligence Studio Pro.
## Manages intelligent dynamic resizing, SplitContainer offsets,
## smooth Tween animations, Console maximization, and Side Help panel toggling.

# Key container references
@export var main_split: VSplitContainer = null
@export var console_help_split: HSplitContainer = null
@export var console_panel: PanelContainer = null
@export var help_panel: PanelContainer = null
@export var btn_maximize: Button = null
@export var btn_collapse_help: Button = null

# Sizing constants
const TRANSITION_DURATION: float = 0.25
const DEFAULT_SPLIT_OFFSET: int = -80 # Balanced split for normal view

var is_console_maximized: bool = false
var is_help_collapsed: bool = false
var current_lang: String = "bg"

func _ready() -> void:
	# Auto-discover nodes if not explicitly bound via inspector
	if main_split == null:
		main_split = get_node_or_null("../../") as VSplitContainer
	if console_help_split == null:
		console_help_split = get_node_or_null("ConsoleHelpSplit") as HSplitContainer
	if console_panel == null and console_help_split != null:
		console_panel = console_help_split.get_node_or_null("ConsolePanel") as PanelContainer
	if help_panel == null and console_help_split != null:
		help_panel = console_help_split.get_node_or_null("HelpPanel") as PanelContainer

	_bind_buttons()

func init_controller(
	p_main_split: VSplitContainer,
	p_console_help_split: HSplitContainer,
	p_console_panel: PanelContainer,
	p_help_panel: PanelContainer,
	p_btn_maximize: Button,
	p_btn_collapse: Button
) -> void:
	main_split = p_main_split
	console_help_split = p_console_help_split
	console_panel = p_console_panel
	help_panel = p_help_panel
	btn_maximize = p_btn_maximize
	btn_collapse_help = p_btn_collapse
	_bind_buttons()

func _bind_buttons() -> void:
	if btn_maximize != null and not btn_maximize.pressed.is_connected(toggle_console_maximize):
		btn_maximize.pressed.connect(toggle_console_maximize)
	if btn_collapse_help != null and not btn_collapse_help.pressed.is_connected(toggle_help_panel):
		btn_collapse_help.pressed.connect(toggle_help_panel)
	update_button_labels()

func set_language(lang_code: String) -> void:
	current_lang = lang_code
	update_button_labels()

func update_button_labels() -> void:
	if btn_maximize != null:
		if is_console_maximized:
			btn_maximize.text = "🗗 СВИЙ" if current_lang == "bg" else "🗗 RESTORE"
		else:
			btn_maximize.text = "🗖 РАЗПЪНИ (80%)" if current_lang == "bg" else "🗖 MAXIMIZE (80%)"

	if btn_collapse_help != null:
		if is_help_collapsed:
			btn_collapse_help.text = "⇤ ПОКАЖИ" if current_lang == "bg" else "⇤ SHOW"
		else:
			btn_collapse_help.text = "⇥ СВИЙ" if current_lang == "bg" else "⇥ COLLAPSE"

## 1. Функция за мигновено максимизиране на конзолата (заема ~70-80% от екрана)
func toggle_console_maximize(animate: bool = true) -> void:
	if main_split == null:
		return

	var target_offset: int
	var screen_h: float = main_split.size.y
	if screen_h <= 10.0:
		screen_h = 720.0

	if not is_console_maximized:
		# Изтегляме вертикалния разделител нагоре за разширена конзола (~75% за конзолата)
		target_offset = -int(screen_h * 0.25)
		is_console_maximized = true
		if console_panel != null and animate:
			_play_maximize_effect(console_panel)
	else:
		target_offset = -int(clamp(screen_h * 0.08, 40.0, 80.0))
		is_console_maximized = false

	update_button_labels()
	if animate and is_inside_tree():
		_animate_split_offset(main_split, target_offset)
	else:
		main_split.split_offset = target_offset

## Адаптира размерите на панелите динамично при резолюционна промяна (напр. Fullscreen или преоразмеряване)
func adapt_to_viewport_size(viewport_size: Vector2) -> void:
	if main_split == null:
		return
	var screen_h: float = viewport_size.y
	if screen_h <= 10.0:
		screen_h = 720.0

	if is_console_maximized:
		var target_offset: int = -int(screen_h * 0.25)
		main_split.split_offset = target_offset
	else:
		var target_offset: int = -int(clamp(screen_h * 0.08, 40.0, 80.0))
		main_split.split_offset = target_offset

	if is_help_collapsed and console_help_split != null:
		console_help_split.split_offset = int(viewport_size.x)

## 2. Функция за скриване/показване на помощния панел (конзолата заема 100% ширина)
func toggle_help_panel(animate: bool = true) -> void:
	if console_help_split == null or help_panel == null:
		return

	var target_offset: int
	if not is_help_collapsed:
		# Преместваме хоризонталния разделител плътно вдясно
		target_offset = int(console_help_split.size.x)
		is_help_collapsed = true
		help_panel.visible = false
	else:
		target_offset = 0 # Балансирано разделяне
		is_help_collapsed = false
		help_panel.visible = true
		if animate:
			_play_maximize_effect(help_panel)

	update_button_labels()
	if animate and is_inside_tree():
		_animate_split_offset(console_help_split, target_offset)
	else:
		console_help_split.split_offset = target_offset

## Гарантира, че помощният панел е отворен (напр. при клик на Справочник за флагове)
func ensure_help_panel_visible() -> void:
	if is_help_collapsed:
		toggle_help_panel()

## Плавна анимация при промяна на размерите (използва Tween в Godot 4)
func _animate_split_offset(split_container: SplitContainer, target: int) -> void:
	if split_container == null:
		return
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(split_container, "split_offset", target, TRANSITION_DURATION)

## Фина анимация за визуален фокус (леко "светване" / overdrive на активния панел)
func _play_maximize_effect(panel: PanelContainer) -> void:
	if panel == null:
		return
	panel.pivot_offset = panel.size / 2.0
	var tween: Tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	panel.modulate = Color(1.1, 1.1, 1.1)
	tween.tween_property(panel, "modulate", Color.WHITE, 0.2)
