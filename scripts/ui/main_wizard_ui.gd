class_name MainWizardUI
extends Control

## Modern Container-First Wizard & Sidebar Controller for Hashcat Intelligence Studio Pro.
## Features Sidebar navigation, 2-step Setup Wizard, Dedicated Monitoring View with 2D Live Graph,
## Resilient SplitContainers, NUMA-protected Hardware Rack, and Full Localization.

const HashcatBridgeScript = preload("res://scripts/bridge/hashcat_bridge.gd")
const ThemeBuilderScript = preload("res://scripts/utils/theme_builder.gd")
const HashDatabaseScript = preload("res://scripts/utils/hash_database.gd")
const AttackDatabaseScript = preload("res://scripts/utils/attack_database.gd")
const FlagDatabaseScript = preload("res://scripts/utils/flag_database.gd")
const HashcatToolsScript = preload("res://scripts/utils/hashcat_tools.gd")
const HardwareInspectorScript = preload("res://scripts/utils/hardware_inspector.gd")
const RawIngestEngineScript = preload("res://scripts/utils/raw_ingest_engine.gd")

# Sidebar Nodes
@onready var logo_label: Label = $MainLayout/SidebarPanel/SidebarVBox/LogoLabel
@onready var btn_new_attack: Button = $MainLayout/SidebarPanel/SidebarVBox/BtnNewAttack
@onready var btn_sessions: Button = $MainLayout/SidebarPanel/SidebarVBox/BtnSessions
@onready var btn_hardware: Button = $MainLayout/SidebarPanel/SidebarVBox/BtnHardware
@onready var btn_monitoring: Button = $MainLayout/SidebarPanel/SidebarVBox/BtnMonitoring
@onready var btn_3d_ops_deck: Button = get_node_or_null("MainLayout/SidebarPanel/SidebarVBox/Btn3DOpsDeck")
@onready var btn_flags_guide: Button = $MainLayout/SidebarPanel/SidebarVBox/BtnFlagsGuide
@onready var btn_settings: Button = $MainLayout/SidebarPanel/SidebarVBox/BtnSettings
@onready var btn_fullscreen: Button = $MainLayout/SidebarPanel/SidebarVBox/BtnFullscreen
@onready var sys_telemetry: Label = $MainLayout/SidebarPanel/SidebarVBox/SysTelemetry
@onready var btn_emergency: Button = $MainLayout/SidebarPanel/SidebarVBox/BtnEmergency

# Workspace Split Nodes
@onready var workspace_split: VSplitContainer = $MainLayout/WorkspaceSplit
@onready var top_workspace: PanelContainer = $MainLayout/WorkspaceSplit/TopWorkspace
@onready var wizard_tabs: TabContainer = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs
@onready var step1_hashes: MarginContainer = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes
@onready var step2_attack_type: MarginContainer = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step2_AttackType
@onready var monitoring_view: PanelContainer = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/MonitoringView
@onready var live_status: Label = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/MonitoringView/MonitorVBox/MonitorHeader/LiveStatus
@onready var btn_abort_attack: Button = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/MonitoringView/MonitorVBox/MonitorHeader/BtnAbortAttack
@onready var btn_back_to_setup: Button = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/MonitoringView/MonitorVBox/MonitorHeader/BtnBackToSetup
@onready var hashrate_graph: PerformanceGraph = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/MonitoringView/MonitorVBox/HashrateGraph

# Step 1 Hashes & Inputs Nodes
@onready var edit_hash: LineEdit = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/HashGroup/HBox/EditHash
@onready var btn_browse_hash: Button = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/HashGroup/HBox/BtnBrowseHash
@onready var btn_quick_example: Button = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/HashGroup/HBox/BtnQuickExample
@onready var edit_wordlist: LineEdit = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/WordlistGroup/HBox/EditWordlist
@onready var btn_browse_wordlist: Button = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/WordlistGroup/HBox/BtnBrowseWordlist
@onready var edit_rules: LineEdit = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/RuleGroup/EditRules

@onready var btn_preset_md5: Button = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/PresetsGroup/GridPresets/BtnPresetMD5
@onready var btn_preset_ntlm: Button = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/PresetsGroup/GridPresets/BtnPresetNTLM
@onready var btn_preset_wpa2: Button = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/PresetsGroup/GridPresets/BtnPresetWPA2
@onready var btn_preset_bcrypt: Button = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/PresetsGroup/GridPresets/BtnPresetBcrypt

@onready var edit_raw_hash: LineEdit = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/HashDetectorBox/VBox/HBoxDetector/EditRawHash
@onready var btn_detect: Button = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/HashDetectorBox/VBox/HBoxDetector/BtnDetect
@onready var text_detector_results: RichTextLabel = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step1_Hashes/ScrollHashes/VBox/HashDetectorBox/VBox/TextDetectorResults

# Step 2 Attack & Hardware Nodes
@onready var opt_attack_mode: OptionButton = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step2_AttackType/VBoxMain/ScrollAttack/VBox/RowModeWorkload/ModeGroup/OptAttackMode
@onready var opt_workload: OptionButton = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step2_AttackType/VBoxMain/ScrollAttack/VBox/RowModeWorkload/WorkloadGroup/OptWorkload
@onready var opt_category: OptionButton = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step2_AttackType/VBoxMain/ScrollAttack/VBox/RowHashSelect/CatGroup/OptCategory
@onready var opt_hash_type: OptionButton = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step2_AttackType/VBoxMain/ScrollAttack/VBox/RowHashSelect/AlgorithmGroup/OptHashType
@onready var gpu_rack: GpuRack = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step2_AttackType/VBoxMain/ScrollAttack/VBox/GpuRack
@onready var edit_custom_flags: LineEdit = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step2_AttackType/VBoxMain/ScrollAttack/VBox/FlagsGroup/EditCustomFlags
@onready var edit_cli_preview: TextEdit = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step2_AttackType/VBoxMain/ScrollAttack/VBox/CLIBox/EditCLIPreview
@onready var btn_start_attack: Button = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step2_AttackType/VBoxMain/HBoxActions/BtnStart
@onready var btn_run_benchmark: Button = $MainLayout/WorkspaceSplit/TopWorkspace/TopVBox/WizardTabs/Step2_AttackType/VBoxMain/HBoxActions/BtnRunBenchmark

# Bottom Deck Nodes
@onready var bottom_console_split: HSplitContainer = $MainLayout/WorkspaceSplit/BottomConsoleSplit
@onready var console_panel: PanelContainer = $MainLayout/WorkspaceSplit/BottomConsoleSplit/ConsolePanel
@onready var btn_clear_console: Button = $MainLayout/WorkspaceSplit/BottomConsoleSplit/ConsolePanel/ConsoleVBox/ConsoleHeader/BtnClearConsole
@onready var btn_maximize_console: Button = $MainLayout/WorkspaceSplit/BottomConsoleSplit/ConsolePanel/ConsoleVBox/ConsoleHeader/BtnMaximizeConsole
@onready var btn_toggle_help: Button = $MainLayout/WorkspaceSplit/BottomConsoleSplit/ConsolePanel/ConsoleVBox/ConsoleHeader/BtnToggleHelp
@onready var console_log: RichTextLabel = $MainLayout/WorkspaceSplit/BottomConsoleSplit/ConsolePanel/ConsoleVBox/ConsoleLog

@onready var help_panel: PanelContainer = $MainLayout/WorkspaceSplit/BottomConsoleSplit/HelpPanel
@onready var btn_collapse_help: Button = $MainLayout/WorkspaceSplit/BottomConsoleSplit/HelpPanel/HelpVBox/HelpHeader/BtnCollapseHelp
@onready var help_tabs: TabContainer = $MainLayout/WorkspaceSplit/BottomConsoleSplit/HelpPanel/HelpVBox/HelpTabs
@onready var text_cracked: RichTextLabel = $MainLayout/WorkspaceSplit/BottomConsoleSplit/HelpPanel/HelpVBox/HelpTabs/CrackedTab/TextCracked

@onready var opt_flag_category: OptionButton = $MainLayout/WorkspaceSplit/BottomConsoleSplit/HelpPanel/HelpVBox/HelpTabs/FlagsTab/VBox/Toolbar/OptFlagCategory
@onready var edit_flag_search: LineEdit = $MainLayout/WorkspaceSplit/BottomConsoleSplit/HelpPanel/HelpVBox/HelpTabs/FlagsTab/VBox/Toolbar/EditFlagSearch
@onready var label_flag_count: Label = $MainLayout/WorkspaceSplit/BottomConsoleSplit/HelpPanel/HelpVBox/HelpTabs/FlagsTab/VBox/Toolbar/LabelFlagCount
@onready var tree_flags: Tree = $MainLayout/WorkspaceSplit/BottomConsoleSplit/HelpPanel/HelpVBox/HelpTabs/FlagsTab/VBox/Split/TreeFlags
@onready var text_flag_intel: RichTextLabel = $MainLayout/WorkspaceSplit/BottomConsoleSplit/HelpPanel/HelpVBox/HelpTabs/FlagsTab/VBox/Split/PanelDetails/VBox/TextFlagIntel
@onready var btn_insert_flag: Button = $MainLayout/WorkspaceSplit/BottomConsoleSplit/HelpPanel/HelpVBox/HelpTabs/FlagsTab/VBox/Split/PanelDetails/VBox/Actions/BtnInsertFlag
@onready var btn_copy_flag: Button = $MainLayout/WorkspaceSplit/BottomConsoleSplit/HelpPanel/HelpVBox/HelpTabs/FlagsTab/VBox/Split/PanelDetails/VBox/Actions/BtnCopyFlag

@onready var file_dialog: FileDialog = $FileDialog

var _bridge: Node = null
var _current_lang: String = "bg"
var _telemetry_timer: float = 0.0
var _active_file_target: String = ""
var _is_console_maximized: bool = false
var _is_help_collapsed: bool = false
var _selected_flag_data: Dictionary = {}

func _ready() -> void:
	_setup_bridge()
	_apply_theme()
	_populate_categories()
	_populate_workload_profiles()
	_populate_attack_modes()
	_populate_hash_algorithms()
	_setup_flags_guide()
	_connect_signals()
	_update_cli_preview()
	_update_hardware_telemetry()
	_apply_localization(_current_lang)

	# Terminal greeting
	console_log.clear()
	console_log.append_text("[color=#10B981][b]⚡ HASHCAT INTELLIGENCE STUDIO PRO v2.4[/b][/color] [color=#64748B]// READY[/color]\n")
	console_log.append_text("[color=#38BDF8]• Топология: Защитен NUMA профил (CPU активен, GPU изолирани за защита).[/color]\n")
	console_log.append_text("[color=#94A3B8]• Интелигентен ингест: Влачете .cap/.pcap, .7z, .pdf, .zip, .hash за 1-клик автоматичен анализ.[/color]\n")
	console_log.append_text("[color=#64748B]──────────────────────────────────────────────────────────────────────────────[/color]\n")

	# Placeholder for cracked passwords
	text_cracked.clear()
	text_cracked.append_text("[color=#64748B]🔓 Няма намерени пароли в текущата сесия.\nСтартирайте атака за да наблюдавате резултатите тук.[/color]\n")

	# Responsive resize signal
	if not get_tree().root.size_changed.is_connected(_on_viewport_size_changed):
		get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

	# Drag & Drop for 1-click Raw File Ingestion
	if not get_tree().root.files_dropped.is_connected(_on_window_files_dropped):
		get_tree().root.files_dropped.connect(_on_window_files_dropped)

func _setup_bridge() -> void:
	_bridge = HashcatBridgeScript.new()
	add_child(_bridge)
	_bridge.stdout_line_received.connect(_on_stdout_line)
	_bridge.stderr_line_received.connect(_on_stderr_line)
	_bridge.status_updated.connect(_on_status_updated)
	_bridge.hashrate_sample_received.connect(_on_hashrate_sample_received)
	_bridge.password_cracked.connect(_on_password_cracked)
	_bridge.process_finished.connect(_on_process_finished)
	_bridge.emergency_stopped.connect(_on_emergency_stopped)

# ==============================================================================
#  NEXT-GEN CYBERPUNK THEME GENERATOR - GODOT 4
# ==============================================================================
# Цветова схема (Obsidian / Neon Emerald / Deep Steel)
const COLOR_MAIN_BG      = Color("#07090e") # Цялостен фон на програмата
const COLOR_PANEL_BG     = Color("#0d1321") # Фон на заоблените карти и панели
const COLOR_PANEL_BORDER = Color("#1e293b") # Контур на картите
const COLOR_ACCENT       = Color("#10b981") # Светещ изумруден акцент
const COLOR_TEXT_PRIMARY = Color("#f1f5f9") # Чисто бял зачетлив текст
const COLOR_TEXT_MUTED   = Color("#64748b") # Приглушен сив за детайли

## 1. Заоблени картички с мека подсветка (Shadow Glow)
func _create_panel_style(t: Theme) -> void:
	var style_panel = StyleBoxFlat.new()
	style_panel.bg_color = COLOR_PANEL_BG
	style_panel.set_corner_radius_all(14) # Ключът към "не-квадратната" визия!
	style_panel.border_width_left = 1
	style_panel.border_width_top = 1
	style_panel.border_width_right = 1
	style_panel.border_width_bottom = 1
	style_panel.border_color = COLOR_PANEL_BORDER
	style_panel.set_content_margin_all(20.0) # Padding: 20px за да не е притиснат текстът до ръба
	
	# Мека сянка, за да изглежда сякаш панелът "плува" над черния фон
	style_panel.shadow_color = Color(0, 0, 0, 0.4)
	style_panel.shadow_size = 12
	style_panel.shadow_offset = Vector2(0, 6)
	
	t.set_stylebox("panel", "PanelContainer", style_panel)
	t.set_stylebox("panel", "Panel", style_panel)

## 2. Модерни капсуловидни бутони с анимация
func _create_button_style(t: Theme) -> void:
	var btn_normal = StyleBoxFlat.new()
	btn_normal.bg_color = Color("#151f32")
	btn_normal.set_corner_radius_all(10)
	btn_normal.border_width_bottom = 2
	btn_normal.border_color = COLOR_PANEL_BORDER
	btn_normal.content_margin_left = 18
	btn_normal.content_margin_right = 18
	btn_normal.content_margin_top = 10
	btn_normal.content_margin_bottom = 10
	
	# Hover състояние - светва в неоново зелено по контура
	var btn_hover = btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = Color("#1e2e4a")
	btn_hover.border_color = COLOR_ACCENT
	
	# Pressed състояние - леко потъмнява
	var btn_pressed = btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = Color("#0d1321")
	btn_pressed.border_width_bottom = 0
	
	t.set_stylebox("normal", "Button", btn_normal)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_pressed)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	
	t.set_color("font_color", "Button", COLOR_TEXT_PRIMARY)
	t.set_color("font_hover_color", "Button", Color.WHITE)

## 3. Трансформация на сивите Checkboxes в модерни Toggle ключове
func _create_checkbox_style(t: Theme) -> void:
	var check_normal = StyleBoxFlat.new()
	check_normal.bg_color = COLOR_MAIN_BG
	check_normal.set_corner_radius_all(8)
	check_normal.border_width_left = 1
	check_normal.border_width_top = 1
	check_normal.border_width_right = 1
	check_normal.border_width_bottom = 1
	check_normal.border_color = COLOR_PANEL_BORDER
	
	var check_checked = check_normal.duplicate() as StyleBoxFlat
	check_checked.bg_color = COLOR_ACCENT
	check_checked.border_color = COLOR_ACCENT
	
	t.set_stylebox("normal", "CheckBox", check_normal)
	t.set_stylebox("pressed", "CheckBox", check_checked)
	t.set_color("font_color", "CheckBox", COLOR_TEXT_PRIMARY)

## 4. Скриване на грозните сиви разделители (Tabs) и замяната им с минималистични плочки
func _create_tab_style(t: Theme) -> void:
	var tab_selected = StyleBoxFlat.new()
	tab_selected.bg_color = COLOR_PANEL_BG
	tab_selected.set_corner_radius_all(10)
	tab_selected.border_width_bottom = 3
	tab_selected.border_color = COLOR_ACCENT # Светеща черта под активния таб
	tab_selected.content_margin_left = 16
	tab_selected.content_margin_right = 16
	
	var tab_unselected = StyleBoxFlat.new()
	tab_unselected.bg_color = Color(0, 0, 0, 0) # Напълно прозрачен
	tab_unselected.content_margin_left = 16
	tab_unselected.content_margin_right = 16
	
	t.set_stylebox("tab_selected", "TabContainer", tab_selected)
	t.set_stylebox("tab_unselected", "TabContainer", tab_unselected)

func _setup_console_frosted_panel() -> void:
	if console_panel != null:
		var sb_console: StyleBoxFlat = StyleBoxFlat.new()
		sb_console.bg_color = Color(0.05, 0.07, 0.13, 0.35) # Полупрозрачен фон за красив blur ефект
		sb_console.set_corner_radius_all(14)
		sb_console.set_border_width_all(1)
		sb_console.border_color = COLOR_PANEL_BORDER
		sb_console.shadow_color = Color(0, 0, 0, 0.4)
		sb_console.shadow_size = 12
		sb_console.shadow_offset = Vector2(0, 6)
		sb_console.set_content_margin_all(15.0) # Padding: 15px
		console_panel.add_theme_stylebox_override("panel", sb_console)

func _apply_theme() -> void:
	var custom_theme: Theme = Theme.new()
	
	# Изграждаме модерните компоненти
	_create_panel_style(custom_theme)
	_create_button_style(custom_theme)
	_create_checkbox_style(custom_theme)
	_create_tab_style(custom_theme)
	ThemeBuilderScript.apply_extended_styles(custom_theme)
	
	# Прилагаме темата глобално на целия прозорец
	self.theme = custom_theme
	
	_setup_console_frosted_panel()
	ThemeBuilderScript.style_action_buttons(btn_start_attack, btn_abort_attack, btn_emergency, btn_run_benchmark)
	ThemeBuilderScript.style_preset_buttons([btn_preset_md5, btn_preset_ntlm, btn_preset_wpa2, btn_preset_bcrypt])
	_update_active_sidebar_btn(btn_new_attack)
	
	if logo_label != null:
		logo_label.text = "⚡ HASHCAT STUDIO PRO"
		logo_label.add_theme_color_override("font_color", COLOR_ACCENT)
	if sys_telemetry != null:
		sys_telemetry.add_theme_color_override("font_color", COLOR_TEXT_MUTED)

	for opt in [opt_category, opt_attack_mode, opt_workload, opt_hash_type, opt_flag_category]:
		if opt != null:
			opt.fit_to_longest_item = false

func _update_active_sidebar_btn(active_btn: Button) -> void:
	var sidebar_buttons: Array[Button] = [
		btn_new_attack, btn_sessions, btn_hardware, btn_monitoring,
		btn_flags_guide, btn_settings, btn_fullscreen
	]
	if btn_3d_ops_deck != null:
		sidebar_buttons.append(btn_3d_ops_deck)
	ThemeBuilderScript.style_sidebar_buttons(sidebar_buttons, active_btn)


func _connect_signals() -> void:
	# Sidebar
	btn_new_attack.pressed.connect(func():
		show_wizard_view()
		wizard_tabs.current_tab = 0
		_update_active_sidebar_btn(btn_new_attack)
	)
	btn_sessions.pressed.connect(func():
		show_wizard_view()
		wizard_tabs.current_tab = 0
		edit_hash.grab_focus()
		_update_active_sidebar_btn(btn_sessions)
	)
	btn_hardware.pressed.connect(func():
		show_wizard_view()
		wizard_tabs.current_tab = 1
		_update_active_sidebar_btn(btn_hardware)
	)
	btn_monitoring.pressed.connect(func():
		show_monitoring_view()
		_update_active_sidebar_btn(btn_monitoring)
	)
	if btn_3d_ops_deck:
		btn_3d_ops_deck.pressed.connect(func():
			_update_active_sidebar_btn(btn_3d_ops_deck)
			get_tree().change_scene_to_file("res://scenes/dashboard_3d.tscn")
		)
	btn_flags_guide.pressed.connect(func():
		ensure_help_panel_visible()
		help_tabs.current_tab = 1
		_update_active_sidebar_btn(btn_flags_guide)
	)
	btn_settings.pressed.connect(_toggle_language)
	btn_fullscreen.pressed.connect(toggle_fullscreen)
	btn_emergency.pressed.connect(_on_emergency_pressed)

	# Wizard Actions
	btn_start_attack.pressed.connect(_on_start_attack)
	btn_abort_attack.pressed.connect(_on_abort_attack)
	btn_back_to_setup.pressed.connect(show_wizard_view)
	btn_run_benchmark.pressed.connect(_on_run_benchmark)

	# File Browsers & Example
	btn_browse_hash.pressed.connect(func(): _open_file_dialog("hash"))
	btn_browse_wordlist.pressed.connect(func(): _open_file_dialog("wordlist"))
	btn_quick_example.pressed.connect(_load_quick_example)
	file_dialog.file_selected.connect(_on_file_selected)

	# Presets
	btn_preset_md5.pressed.connect(func(): _apply_preset(0, 0, "", "-O"))
	btn_preset_ntlm.pressed.connect(func(): _apply_preset(0, 1000, "c $1 $!", "-O"))
	btn_preset_wpa2.pressed.connect(func(): _apply_preset(0, 22000, "", "-O"))
	btn_preset_bcrypt.pressed.connect(func(): _apply_preset(0, 3200, "", ""))

	# Detector
	btn_detect.pressed.connect(_on_detect_hash)

	# CLI Update triggers
	edit_hash.text_changed.connect(func(_t): _update_cli_preview())
	edit_wordlist.text_changed.connect(func(_t): _update_cli_preview())
	edit_rules.text_changed.connect(func(_t): _update_cli_preview())
	edit_custom_flags.text_changed.connect(func(_t): _update_cli_preview())
	opt_attack_mode.item_selected.connect(func(_idx): _update_cli_preview())
	opt_workload.item_selected.connect(func(_idx): _update_cli_preview())
	opt_hash_type.item_selected.connect(func(_idx): _update_cli_preview())

	opt_category.item_selected.connect(func(_idx):
		_populate_hash_algorithms()
		_update_cli_preview()
	)

	if gpu_rack != null:
		gpu_rack.devices_selection_changed.connect(func(_ids, _flag): _update_cli_preview())

	# Console & Help controls
	btn_clear_console.pressed.connect(func(): console_log.clear())
	btn_maximize_console.pressed.connect(_toggle_maximize_console)
	btn_collapse_help.pressed.connect(_toggle_collapse_help)
	btn_toggle_help.pressed.connect(_toggle_collapse_help)

	# Flags guide
	opt_flag_category.item_selected.connect(func(_idx): _filter_flags_tree())
	edit_flag_search.text_changed.connect(func(_txt): _filter_flags_tree())
	tree_flags.item_selected.connect(_on_flag_tree_selected)
	btn_insert_flag.pressed.connect(_on_insert_flag_pressed)
	btn_copy_flag.pressed.connect(_on_copy_flag_pressed)

## --- DYNAMIC VIEW SWITCHING (Key requirement) ---
func show_monitoring_view() -> void:
	wizard_tabs.visible = false
	monitoring_view.visible = true
	if hashrate_graph != null:
		hashrate_graph.queue_redraw()

func show_wizard_view() -> void:
	wizard_tabs.visible = true
	monitoring_view.visible = false

func toggle_view(show_monitor: bool = true) -> void:
	if show_monitor:
		show_monitoring_view()
	else:
		show_wizard_view()

func _toggle_maximize_console() -> void:
	var screen_h: float = workspace_split.size.y
	if screen_h <= 10.0:
		screen_h = 720.0

	if not _is_console_maximized:
		workspace_split.split_offset = -int(screen_h * 0.25)
		_is_console_maximized = true
		btn_maximize_console.text = "🗗 Свий" if _current_lang == "bg" else "🗗 Restore"
	else:
		workspace_split.split_offset = int(clamp(screen_h * 0.12, 60.0, 140.0))
		_is_console_maximized = false
		btn_maximize_console.text = "🗖 80%" if _current_lang == "bg" else "🗖 80%"

func _toggle_collapse_help() -> void:
	if not _is_help_collapsed:
		help_panel.visible = false
		bottom_console_split.split_offset = int(bottom_console_split.size.x)
		_is_help_collapsed = true
		btn_collapse_help.text = "⇤ Покажи" if _current_lang == "bg" else "⇤ Show"
		btn_toggle_help.text = "💡 +Помощ" if _current_lang == "bg" else "💡 +Help"
	else:
		help_panel.visible = true
		bottom_console_split.split_offset = 0
		_is_help_collapsed = false
		btn_collapse_help.text = "⇥ Свий" if _current_lang == "bg" else "⇥ Hide"
		btn_toggle_help.text = "💡 Помощ" if _current_lang == "bg" else "💡 Help"

func ensure_help_panel_visible() -> void:
	if _is_help_collapsed:
		_toggle_collapse_help()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			toggle_fullscreen()
			get_viewport().set_input_as_handled()

func toggle_fullscreen() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		btn_fullscreen.text = "⛶ Цял Екран (F11)" if _current_lang == "bg" else "⛶ Fullscreen (F11)"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		btn_fullscreen.text = "🗗 Прозорец (F11)" if _current_lang == "bg" else "🗗 Windowed (F11)"

func _on_viewport_size_changed() -> void:
	pass



func _process(delta: float) -> void:
	_telemetry_timer += delta
	if _telemetry_timer >= 1.0:
		_telemetry_timer = 0.0
		_update_hardware_telemetry()

func _update_hardware_telemetry() -> void:
	var telem: Dictionary = HardwareInspectorScript.get_system_telemetry()
	var cpu_pct: float = telem.get("cpu_usage_pct", 0.0)
	var ram_used: int = telem.get("ram_used_mb", 0)
	var ram_total: int = telem.get("ram_total_mb", 0)
	var ram_used_gb: float = float(ram_used) / 1024.0
	var ram_total_gb: float = float(ram_total) / 1024.0
	var ram_pct: float = (float(ram_used) / maxf(float(ram_total), 1.0)) * 100.0
	sys_telemetry.text = "CPU: %.1f%%\nRAM: %.1f / %.1f GB (%.0f%%)" % [cpu_pct, ram_used_gb, ram_total_gb, ram_pct]
	if gpu_rack != null:
		gpu_rack.update_telemetry_sensors(telem)

## --- DATA POPULATION ---
func _populate_categories() -> void:
	opt_category.clear()
	opt_category.add_item("Всички Категории (All)", 0)
	opt_category.add_item("Hashes & Checksums", 1)
	opt_category.add_item("Windows & Active Directory", 2)
	opt_category.add_item("Linux / Unix", 3)
	opt_category.add_item("Wireless / Network", 4)
	opt_category.add_item("Archives & Encryption", 5)
	opt_category.add_item("Cryptocurrency Wallets", 6)
	opt_category.add_item("Web & Databases", 7)

func _populate_attack_modes() -> void:
	opt_attack_mode.clear()
	opt_attack_mode.add_item("0 | Пряка атака (Речник)", 0)
	opt_attack_mode.add_item("1 | Комбинационна (Речник + Речник)", 1)
	opt_attack_mode.add_item("3 | Брутфорс / Маска", 3)
	opt_attack_mode.add_item("6 | Хибридна Речник + Маска", 6)
	opt_attack_mode.add_item("7 | Хибридна Маска + Речник", 7)

func _populate_workload_profiles() -> void:
	opt_workload.clear()
	opt_workload.add_item("-w 1 | Нисък / Десктоп", 1)
	opt_workload.add_item("-w 2 | Балансиран", 2)
	opt_workload.add_item("-w 3 | Висок / Производителност", 3)
	opt_workload.add_item("-w 4 | Максимален / Nightmare", 4)
	opt_workload.select(2)

func _populate_hash_algorithms() -> void:
	var all_modes: Array[Dictionary] = HashDatabaseScript.get_all_modes()
	var selected_cat_idx: int = opt_category.selected
	var cat_filter: String = ""
	if selected_cat_idx > 0:
		cat_filter = opt_category.get_item_text(selected_cat_idx)

	opt_hash_type.clear()
	for mode in all_modes:
		if cat_filter.is_empty() or mode["cat"] == cat_filter:
			var item_text: String = "%d | %s [%s]" % [mode["id"], mode["name"], mode["cat"]]
			opt_hash_type.add_item(item_text, mode["id"])

## --- EXECUTION & ACTIONS ---
func _on_start_attack() -> void:
	var args: PackedStringArray = _build_cli_args()
	if args.is_empty():
		return
	console_log.append_text("[color=#00F0FF]>>> Стартиране на Hashcat двигател...[/color]\n")
	_bridge.start_attack(args)
	show_monitoring_view()
	live_status.text = "⚡ СТАТУС: ИЗПЪЛНЕНИЕ НА АТАКА..."

func _on_abort_attack() -> void:
	_bridge.stop_attack()
	live_status.text = "⏹ СТАТУС: АТАКА ПРЕКЪСНАТА"

func _on_emergency_pressed() -> void:
	_bridge.emergency_kill()
	live_status.text = "⚠️ СТАТУС: АВАРИЙНО СПРЯН (SIGKILL)"
	console_log.append_text("[color=#FF1744]⚠️ АВАРИЙНО СПИРАНЕ (SIGKILL) ИЗПЪЛНЕНО![/color]\n")

func _on_run_benchmark() -> void:
	var mode_id: int = opt_hash_type.get_selected_id()
	var args: PackedStringArray = ["-b", "-m", str(mode_id)]
	if gpu_rack != null:
		var dev_flag: String = gpu_rack.get_device_cli_flag()
		if not dev_flag.is_empty():
			var parts = dev_flag.split(" ")
			for p in parts:
				if not p.is_empty():
					args.append(p)
	console_log.append_text("[color=#FFB800]>>> Стартиране на бенчмарк за хеш режим %d...[/color]\n" % mode_id)
	_bridge.start_attack(args)
	show_monitoring_view()
	live_status.text = "⚡ СТАТУС: БЕНЧМАРК В ХОД (-b)..."

func _build_cli_args() -> PackedStringArray:
	var args: PackedStringArray = []
	var mode_id: int = opt_hash_type.get_selected_id()
	args.append("-m")
	args.append(str(mode_id))

	var attack_mode: int = opt_attack_mode.get_selected_id()
	args.append("-a")
	args.append(str(attack_mode))

	var workload: int = opt_workload.get_selected_id()
	args.append("-w")
	args.append(str(workload))

	if gpu_rack != null:
		var dev_flag: String = gpu_rack.get_device_cli_flag()
		if not dev_flag.is_empty():
			var parts = dev_flag.split(" ")
			for p in parts:
				if not p.is_empty():
					args.append(p)

	var custom: String = edit_custom_flags.text.strip_edges()
	if not custom.is_empty():
		for f in custom.split(" "):
			if not f.is_empty():
				args.append(f)

	var target_hash: String = edit_hash.text.strip_edges()
	if not target_hash.is_empty():
		args.append(target_hash)

	var wordlist: String = edit_wordlist.text.strip_edges()
	if not wordlist.is_empty():
		args.append(wordlist)

	var rules: String = edit_rules.text.strip_edges()
	if not rules.is_empty():
		args.append("-j")
		args.append(rules)

	return args

func _update_cli_preview() -> void:
	var args: PackedStringArray = _build_cli_args()
	edit_cli_preview.text = "hashcat " + " ".join(args)

## --- PRESETS & DETECTOR ---
func _apply_preset(attack_mode: int, hash_mode: int, rules: String, flags: String) -> void:
	for i in range(opt_attack_mode.item_count):
		if opt_attack_mode.get_item_id(i) == attack_mode:
			opt_attack_mode.select(i)
			break
	for i in range(opt_hash_type.item_count):
		if opt_hash_type.get_item_id(i) == hash_mode:
			opt_hash_type.select(i)
			break
	edit_rules.text = rules
	edit_custom_flags.text = flags
	_update_cli_preview()
	wizard_tabs.current_tab = 1 # Switch to step 2 to confirm attack configuration

func _load_quick_example() -> void:
	edit_hash.text = "8743b52063cd84097a65d1633f5c74f5"
	edit_wordlist.text = "rockyou.txt"
	_apply_preset(0, 0, "", "-O")

func _on_detect_hash() -> void:
	var raw: String = edit_raw_hash.text.strip_edges()
	if raw.is_empty():
		text_detector_results.text = "[color=#FFB800]Моля, въведете хеш низ за анализ.[/color]"
		return
	var matches: Array[Dictionary] = HashDatabaseScript.auto_detect_hash(raw)
	if matches.is_empty():
		text_detector_results.text = "[color=#FF1744]Не е открит сигурен хеш шаблон.[/color]"
	else:
		var best: Dictionary = matches[0]
		var id: int = best.get("id", 0)
		var algo_name: String = best.get("name", "Unknown")
		var conf: String = best.get("confidence", "")
		text_detector_results.text = "[color=#10B981]✓ Разпознат формат: [b]-m %d[/b] (%s)\n[color=#8B949E]Надеждност: %s[/color][/color]" % [id, algo_name, conf]
		for i in range(opt_hash_type.item_count):
			if opt_hash_type.get_item_id(i) == id:
				opt_hash_type.select(i)
				break
		_update_cli_preview()

## --- FILE DIALOG & DRAG AND DROP ---
func _open_file_dialog(target: String) -> void:
	_active_file_target = target
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.popup_centered(Vector2i(750, 500))

func _on_file_selected(path: String) -> void:
	if _active_file_target == "hash":
		edit_hash.text = path
	elif _active_file_target == "wordlist":
		edit_wordlist.text = path
	_update_cli_preview()

func _on_window_files_dropped(files: PackedStringArray) -> void:
	if files.is_empty():
		return
	var path: String = files[0]
	var ingest_res: Dictionary = RawIngestEngineScript.ingest_file(path, _current_lang)
	if ingest_res.get("success", false):
		var target_file: String = ingest_res.get("target_hash_path", path)
		edit_hash.text = target_file
		var detected_mode: int = ingest_res.get("hash_mode", -1)
		if detected_mode >= 0:
			for i in range(opt_hash_type.item_count):
				if opt_hash_type.get_item_id(i) == detected_mode:
					opt_hash_type.select(i)
					break
		var rec_flags: String = ingest_res.get("recommended_flags", "")
		if not rec_flags.is_empty() and edit_custom_flags.text.find(rec_flags) == -1:
			edit_custom_flags.text = (edit_custom_flags.text + " " + rec_flags).strip_edges()
		console_log.append_text("[color=#10B981]✓ Успешно зареден файл чрез Drag & Drop: %s[/color]\n" % target_file)
		var summary: String = ingest_res.get("summary_message", "")
		if not summary.is_empty():
			console_log.append_text("[color=#00F0FF]%s[/color]\n" % summary)
		_update_cli_preview()
	else:
		var err_msg: String = ingest_res.get("error", "Неуспешно разпознаване на файла.")
		console_log.append_text("[color=#FF1744]❌ Грешка при зареждане на файл: %s[/color]\n" % err_msg)


## --- FLAGS GUIDE CATALOG ---
func _setup_flags_guide() -> void:
	opt_flag_category.clear()
	var cats: Array[Dictionary] = FlagDatabaseScript.get_categories(_current_lang)
	for i in range(cats.size()):
		var c: Dictionary = cats[i]
		opt_flag_category.add_item(c["name"], i)
		opt_flag_category.set_item_metadata(i, c["id"])
	opt_flag_category.select(0)
	_filter_flags_tree()

func _filter_flags_tree() -> void:
	if tree_flags == null:
		return
	tree_flags.clear()
	var root: TreeItem = tree_flags.create_item()

	var selected_cat_idx: int = opt_flag_category.selected
	var cat_id: String = "all"
	if selected_cat_idx >= 0 and opt_flag_category.get_item_metadata(selected_cat_idx) != null:
		cat_id = str(opt_flag_category.get_item_metadata(selected_cat_idx))

	var query: String = edit_flag_search.text.strip_edges()
	var flags: Array[Dictionary] = []
	if not query.is_empty():
		flags = FlagDatabaseScript.search_flags(query, _current_lang)
		if cat_id != "all":
			var filtered: Array[Dictionary] = []
			for f in flags:
				if f.get("cat_id", "") == cat_id:
					filtered.append(f)
			flags = filtered
	else:
		flags = FlagDatabaseScript.get_flags_by_category(cat_id, _current_lang)

	label_flag_count.text = ("%d опции" if _current_lang == "bg" else "%d flags") % flags.size()

	var cat_dict: Dictionary = {}
	for cat in FlagDatabaseScript.get_categories(_current_lang):
		cat_dict[cat["id"]] = cat["name"]

	var cat_groups: Dictionary = {}
	for f in flags:
		var c_id: String = f.get("cat_id", "misc")
		if not cat_groups.has(c_id):
			cat_groups[c_id] = []
		cat_groups[c_id].append(f)

	var first_item: TreeItem = null
	for c_id in cat_groups.keys():
		var cat_name: String = cat_dict.get(c_id, c_id)
		var cat_header: TreeItem = tree_flags.create_item(root)
		cat_header.set_text(0, "📁 " + cat_name)
		cat_header.set_selectable(0, false)
		cat_header.collapsed = false

		for f in cat_groups[c_id]:
			var item: TreeItem = tree_flags.create_item(cat_header)
			var short_f: String = f.get("flag", "").split(",")[0].strip_edges()
			item.set_text(0, short_f + " · " + f.get("title", ""))
			item.set_tooltip_text(0, f.get("flag", "") + " - " + f.get("title", ""))
			item.set_metadata(0, f)
			if first_item == null:
				first_item = item

	if first_item != null:
		first_item.select(0)
		_display_flag_details(first_item.get_metadata(0))
	else:
		_selected_flag_data = {}
		text_flag_intel.clear()
		text_flag_intel.append_text("[color=#FFD700]Няма намерени опции по зададените критерии.[/color]" if _current_lang == "bg" else "[color=#FFD700]No flags found matching criteria.[/color]")

func _on_flag_tree_selected() -> void:
	var selected = tree_flags.get_selected()
	if selected != null and selected.get_metadata(0) != null:
		_display_flag_details(selected.get_metadata(0))

func _display_flag_details(f: Dictionary) -> void:
	_selected_flag_data = f
	if f.is_empty():
		text_flag_intel.clear()
		return

	var is_bg: bool = (_current_lang == "bg")
	var bbcode: String = ""
	bbcode += "[b][color=#00F0FF]" + ("⚡ ОПЦИЯ: " if is_bg else "⚡ FLAG: ") + "[/color][color=#00FF66]" + f.get("flag", "") + "[/color][/b]\n"
	bbcode += "[b][color=#FFD700]" + f.get("title", "") + "[/color][/b]  [color=#8B949E](" + ("Тип: " if is_bg else "Type: ") + f.get("type", "") + ")[/color]\n\n"
	bbcode += "[b][color=#00E5FF]" + ("🔍 КАКВО ПРАВИ И ЗАЩО СЕ ИЗПОЛЗВА: " if is_bg else "🔍 DESCRIPTION & USAGE: ") + "[/color][/b]\n"
	bbcode += "[color=#E6EDF3]" + f.get("desc", "") + "[/color]\n\n"
	bbcode += "[b][color=#00F0FF]" + ("💻 ГОТОВ ПРИМЕРЕН СИНТАКСИС: " if is_bg else "💻 PRACTICAL CLI EXAMPLE: ") + "[/color][/b]\n"
	bbcode += "[bgcolor=#0B0E14][color=#00FF66] " + f.get("example", "") + " [/color][/bgcolor]\n"

	text_flag_intel.clear()
	text_flag_intel.append_text(bbcode)

func _on_insert_flag_pressed() -> void:
	if _selected_flag_data.is_empty():
		return
	var flag: String = _selected_flag_data.get("flag", "")
	if not flag.is_empty():
		if not edit_custom_flags.text.is_empty():
			edit_custom_flags.text += " " + flag
		else:
			edit_custom_flags.text = flag
		_update_cli_preview()
		console_log.append_text("[color=#00F0FF]Добавен флаг: %s[/color]\n" % flag)

func _on_copy_flag_pressed() -> void:
	if _selected_flag_data.is_empty():
		return
	var ex: String = _selected_flag_data.get("example", "")
	if not ex.is_empty():
		DisplayServer.clipboard_set(ex)
		console_log.append_text("[color=#10B981]Копиран пример в клипборда: %s[/color]\n" % ex)

## --- BRIDGE SIGNAL HANDLERS ---
func _on_stdout_line(line: String) -> void:
	console_log.append_text(line + "\n")

func _on_stderr_line(line: String) -> void:
	console_log.append_text("[color=#FF1744]" + line + "[/color]\n")

func _on_status_updated(status_dict: Dictionary) -> void:
	var state: String = status_dict.get("state", "")
	if not state.is_empty():
		live_status.text = "⚡ СТАТУС: " + state

func _on_hashrate_sample_received(speed_val: float, speed_fmt: String) -> void:
	if hashrate_graph != null:
		hashrate_graph.push_sample(speed_val, speed_fmt)

func _on_password_cracked(hash_str: String, plain: String) -> void:
	var entry: String = "[color=#10B981]🔓 НАМЕРЕНА ПАРОЛА: [b]%s[/b] -> [color=#FFFFFF]%s[/color][/color]\n" % [hash_str, plain]
	text_cracked.append_text(entry)
	console_log.append_text(entry)

func _on_process_finished(code: int) -> void:
	live_status.text = "✓ АТАКАТА ЗАВЪРШИ (Код: %d)" % code
	console_log.append_text("[color=#10B981]✓ Процесът на Hashcat приключи с код %d.[/color]\n" % code)

func _on_emergency_stopped() -> void:
	live_status.text = "⚠️ АВАРИЙНО СПРЯН (SIGKILL)"

## --- LOCALIZATION ---
func _toggle_language() -> void:
	_current_lang = "en" if _current_lang == "bg" else "bg"
	_apply_localization(_current_lang)

func _apply_localization(lang: String) -> void:
	if lang == "bg":
		wizard_tabs.set_tab_title(0, "🎯 1. Цели & Речници")
		wizard_tabs.set_tab_title(1, "⚙️ 2. Атака & Топология")
		help_tabs.set_tab_title(0, "🔓 Разбити Пароли (0)")
		help_tabs.set_tab_title(1, "📖 Справочник (-h)")

		btn_new_attack.text = "⚡ Нова Атака"
		btn_sessions.text = "📁 Хешове & Речници"
		btn_hardware.text = "🖥️ Хардуерна Топология"
		btn_monitoring.text = "📊 Мониторинг & Графика"
		if btn_3d_ops_deck:
			btn_3d_ops_deck.text = "🪐 3D Ops Deck"
		btn_flags_guide.text = "📖 Справочник (-h)"
		btn_settings.text = "🌐 Език: Български 🇧🇬"
		btn_start_attack.text = "▶ СТАРТИРАЙ АТАКА"
		btn_run_benchmark.text = "⚡ БЕНЧМАРК (-b)"
		btn_abort_attack.text = "⏹ ПРЕКЪСНИ АТАКА"
		btn_back_to_setup.text = "🛠️ ОБРАТНО КЪМ НАСТРОЙКИ"

		btn_clear_console.text = "🗑️ Изчисти"
		btn_maximize_console.text = "🗗 Свий" if _is_console_maximized else "🗖 80%"
		btn_toggle_help.text = "💡 +Помощ" if _is_help_collapsed else "💡 Помощ"
		btn_collapse_help.text = "⇤ Покажи" if _is_help_collapsed else "⇥ Свий"

		btn_preset_md5.text = "⚡ MD5 Речник"
		btn_preset_ntlm.text = "⚡ NTLM + Best64"
		btn_preset_wpa2.text = "⚡ WPA2 Handshake"
		btn_preset_bcrypt.text = "⚡ Bcrypt CPU/GPU"
	else:
		wizard_tabs.set_tab_title(0, "🎯 1. Hashes & Wordlists")
		wizard_tabs.set_tab_title(1, "⚙️ 2. Attack & Topology")
		help_tabs.set_tab_title(0, "🔓 Cracked Passwords (0)")
		help_tabs.set_tab_title(1, "📖 Flags Guide (-h)")

		btn_new_attack.text = "⚡ New Attack"
		btn_sessions.text = "📁 Hashes & Wordlists"
		btn_hardware.text = "🖥️ Compute Topology"
		btn_monitoring.text = "📊 Live Monitoring"
		if btn_3d_ops_deck:
			btn_3d_ops_deck.text = "🪐 3D Ops Deck"
		btn_flags_guide.text = "📖 Options Guide (-h)"
		btn_settings.text = "🌐 Language: English 🇬🇧"
		btn_start_attack.text = "▶ EXECUTE ATTACK"
		btn_run_benchmark.text = "⚡ BENCHMARK (-b)"
		btn_abort_attack.text = "⏹ ABORT ATTACK"
		btn_back_to_setup.text = "🛠️ BACK TO SETUP"

		btn_clear_console.text = "🗑️ Clear"
		btn_maximize_console.text = "🗗 Restore" if _is_console_maximized else "🗖 80%"
		btn_toggle_help.text = "💡 +Help" if _is_help_collapsed else "💡 Help"
		btn_collapse_help.text = "⇤ Show" if _is_help_collapsed else "⇥ Hide"

		btn_preset_md5.text = "⚡ MD5 Wordlist"
		btn_preset_ntlm.text = "⚡ NTLM + Best64"
		btn_preset_wpa2.text = "⚡ WPA2 Handshake"
		btn_preset_bcrypt.text = "⚡ Bcrypt CPU/GPU"
	_setup_flags_guide()
