class_name HoloTerminalUI
extends Control

## Spatial Holographic Terminal GUI.
## Hosts the complete Hashcat intelligence suite (Hardware Topology, Attack Config,
## Hash Detector, Live Console, Cracked Passwords, and Flags Guide)
## inside a 3D in-world SubViewport with full interactive mouse raycast support.

signal device_toggled_in_terminal(dev_id: int, enabled: bool)
signal compute_mode_selected(mode: String)
signal request_exit_to_2d()
signal attack_requested(args: Array)
signal benchmark_requested()
signal stop_requested()

const HardwareInspectorScript = preload("res://scripts/utils/hardware_inspector.gd")
const HashDatabaseScript = preload("res://scripts/utils/hash_database.gd")
const FlagDatabaseScript = preload("res://scripts/utils/flag_database.gd")

var _tab_container: TabContainer
var _slots: Array[Dictionary] = []
var _lbl_mode_status: Label
var _lbl_cli_preview: Label
var _lbl_engine_status: Label
var _lbl_speed_val: Label
var _lbl_progress_val: Label

func set_active_tab(idx: int) -> void:
	if _tab_container and idx >= 0 and idx < _tab_container.get_tab_count():
		_tab_container.current_tab = idx

# Attack Configuration Controls
var _edit_hash: LineEdit
var _edit_wordlist: LineEdit
var _edit_mask_rules: LineEdit
var _edit_custom_flags: LineEdit
var _opt_attack_mode: OptionButton
var _opt_workload: OptionButton
var _opt_hash_category: OptionButton
var _opt_hash_algo: OptionButton

# Hash Detector Controls
var _edit_detector_input: LineEdit
var _lbl_detector_results: RichTextLabel
var _detected_mode_id: int = -1
var _btn_apply_detected: Button

# Console & Monitoring Controls
var _console_log: RichTextLabel
var _cracked_log: RichTextLabel
var _lbl_cracked_count: Label
var _cracked_count: int = 0
var _btn_start: Button
var _btn_stop: Button
var _btn_bench: Button
var _is_running: bool = false

# Flags Guide Controls
var _opt_flag_category: OptionButton
var _edit_flag_search: LineEdit
var _tree_flags: Tree
var _lbl_flag_details: RichTextLabel
var _btn_add_flag: Button
var _selected_flag_str: String = ""

func _ready() -> void:
	custom_minimum_size = Vector2(1280, 800)
	size = Vector2(1280, 800)
	_build_ui()

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_slots.clear()

	var root_panel = PanelContainer.new()
	root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var root_sb = StyleBoxFlat.new()
	root_sb.bg_color = Color("#070d18f4")
	root_sb.border_width_left = 2
	root_sb.border_width_top = 2
	root_sb.border_width_right = 2
	root_sb.border_width_bottom = 2
	root_sb.border_color = Color("#00f0ff")
	root_sb.set_corner_radius_all(10)
	root_sb.content_margin_left = 18
	root_sb.content_margin_top = 14
	root_sb.content_margin_right = 18
	root_sb.content_margin_bottom = 14
	root_panel.add_theme_stylebox_override("panel", root_sb)
	add_child(root_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	root_panel.add_child(main_vbox)

	# 1. Header Bar
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)

	var lbl_title = Label.new()
	lbl_title.text = "💠 HASHCAT QUANTUM OPERATOR TERMINAL"
	lbl_title.add_theme_color_override("font_color", Color("#00f0ff"))
	lbl_title.add_theme_font_size_override("font_size", 20)
	header.add_child(lbl_title)

	var header_spacer = Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)

	var btn_exit_2d = Button.new()
	btn_exit_2d.text = "⬅ ВЪРНИ СЕ В 2D"
	btn_exit_2d.custom_minimum_size = Vector2(160, 36)
	_style_btn(btn_exit_2d, Color("#334155"), Color("#94a3b8"))
	btn_exit_2d.pressed.connect(func():
		request_exit_to_2d.emit()
		get_tree().change_scene_to_file("res://scenes/main_wizard.tscn")
	)
	header.add_child(btn_exit_2d)

	main_vbox.add_child(header)

	# 2. Main Tabs
	var tabs = TabContainer.new()
	tabs.name = "TabContainer"
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.current_tab = 0
	_tab_container = tabs
	main_vbox.add_child(tabs)

	# Tab 1: Hardware & Topology
	var tab_hw = VBoxContainer.new()
	tab_hw.name = "🎛️ ХАРДУЕР И ТОПОЛОГИЯ"
	tab_hw.add_theme_constant_override("separation", 10)
	tabs.add_child(tab_hw)
	_build_hardware_tab(tab_hw)

	# Tab 2: Attack Configuration & Hash Detector
	var tab_atk = VBoxContainer.new()
	tab_atk.name = "🎯 НАСТРОЙКА НА АТАКА"
	tab_atk.add_theme_constant_override("separation", 10)
	tabs.add_child(tab_atk)
	_build_attack_tab(tab_atk)

	# Tab 3: Execution, Live Console & Cracked Passwords
	var tab_con = VBoxContainer.new()
	tab_con.name = "💻 КОНЗОЛА & ИЗПЪЛНЕНИЕ"
	tab_con.add_theme_constant_override("separation", 10)
	tabs.add_child(tab_con)
	_build_console_tab(tab_con)

	# Tab 4: Flags Guide
	var tab_flg = VBoxContainer.new()
	tab_flg.name = "📖 СЪВЕТНИК ЗА ФЛАГОВЕ"
	tab_flg.add_theme_constant_override("separation", 10)
	tabs.add_child(tab_flg)
	_build_flags_guide_tab(tab_flg)

	_update_cli_preview()

# ==============================================================================
# TAB 1: HARDWARE & TOPOLOGY
# ==============================================================================
func _build_hardware_tab(parent: VBoxContainer) -> void:
	var mode_bar = HBoxContainer.new()
	mode_bar.add_theme_constant_override("separation", 10)

	var btn_cpu = Button.new()
	btn_cpu.text = "🖥️ САМО CPU"
	btn_cpu.custom_minimum_size = Vector2(180, 38)
	_style_btn(btn_cpu, Color("#10b981"), Color("#10b981"))
	btn_cpu.pressed.connect(func(): set_compute_mode("CPU"))
	mode_bar.add_child(btn_cpu)

	var btn_gpu = Button.new()
	btn_gpu.text = "⚡ САМО GPU"
	btn_gpu.custom_minimum_size = Vector2(180, 38)
	_style_btn(btn_gpu, Color("#00f0ff"), Color("#00f0ff"))
	btn_gpu.pressed.connect(func(): set_compute_mode("GPU"))
	mode_bar.add_child(btn_gpu)

	var btn_all = Button.new()
	btn_all.text = "⚡+🖥️ ХИБРИДЕН"
	btn_all.custom_minimum_size = Vector2(180, 38)
	_style_btn(btn_all, Color("#a855f7"), Color("#c084fc"))
	btn_all.pressed.connect(func(): set_compute_mode("ALL"))
	mode_bar.add_child(btn_all)

	parent.add_child(mode_bar)

	_lbl_mode_status = Label.new()
	_lbl_mode_status.text = "РЕЖИМ: САМО CPU (NUMA PROTECT - GPU СА ИЗОЛИРАНИ)"
	_lbl_mode_status.add_theme_color_override("font_color", Color("#10b981"))
	parent.add_child(_lbl_mode_status)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)

	var cards_vbox = VBoxContainer.new()
	cards_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(cards_vbox)

	var detected_devices = HardwareInspectorScript.probe_compute_devices()
	for dev in detected_devices:
		var dev_id: int = dev.get("id", 1)
		var dev_name: String = dev.get("name", "Device #" + str(dev_id))
		var dev_type: String = dev.get("type", "GPU")
		var dev_backend: String = dev.get("backend", "")
		var is_cpu: bool = (dev_type == "CPU")
		var is_en: bool = dev.get("enabled", is_cpu)

		var card = PanelContainer.new()
		var card_sb = StyleBoxFlat.new()
		card_sb.bg_color = Color("#0f172a")
		card_sb.border_width_left = 3
		card_sb.border_width_top = 1
		card_sb.border_width_right = 1
		card_sb.border_width_bottom = 1
		card_sb.border_color = Color("#10b981") if is_en else Color("#334155")
		card_sb.set_corner_radius_all(8)
		card_sb.content_margin_left = 12
		card_sb.content_margin_right = 12
		card_sb.content_margin_top = 8
		card_sb.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", card_sb)

		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)

		var chk = CheckBox.new()
		chk.button_pressed = is_en
		chk.text = "ACTIVE" if is_en else "ISOLATED"
		chk.custom_minimum_size = Vector2(90, 0)
		row.add_child(chk)

		var icon_str = "🖥️ " if is_cpu else "⚡ "
		var lbl_name = Label.new()
		lbl_name.text = "%s#%d: %s [%s]" % [icon_str, dev_id, dev_name, dev_backend]
		lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_name.add_theme_color_override("font_color", Color("#e2e8f0"))
		row.add_child(lbl_name)

		var lbl_metric = Label.new()
		lbl_metric.text = "38°C | LOAD 15%" if is_cpu else "48°C | LOAD 0%"
		lbl_metric.custom_minimum_size = Vector2(140, 0)
		lbl_metric.add_theme_color_override("font_color", Color("#f59e0b"))
		row.add_child(lbl_metric)

		var lbl_badge = Label.new()
		lbl_badge.text = "[CPU ACTIVE]" if (is_en and is_cpu) else ("[GPU ACTIVE]" if is_en else "[STANDBY]")
		lbl_badge.custom_minimum_size = Vector2(110, 0)
		lbl_badge.add_theme_color_override("font_color", Color("#10b981") if is_en else Color("#64748b"))
		row.add_child(lbl_badge)

		card.add_child(row)
		cards_vbox.add_child(card)

		var slot_info = {
			"id": dev_id,
			"is_cpu": is_cpu,
			"enabled": is_en,
			"checkbox": chk,
			"stylebox": card_sb,
			"card": card,
			"lbl_metric": lbl_metric,
			"lbl_badge": lbl_badge
		}
		_slots.append(slot_info)

		chk.toggled.connect(func(pressed: bool):
			_on_device_toggled(dev_id, pressed)
		)

# ==============================================================================
# TAB 2: ATTACK CONFIGURATION & HASH DETECTOR
# ==============================================================================
func _build_attack_tab(parent: VBoxContainer) -> void:
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	# 1. Target Hash Input & Quick Presets
	var hash_box = VBoxContainer.new()
	hash_box.add_theme_constant_override("separation", 6)
	var lbl_hash_title = Label.new()
	lbl_hash_title.text = "🎯 Целеви Хаш или Път до Файл:"
	lbl_hash_title.add_theme_color_override("font_color", Color("#38bdf8"))
	hash_box.add_child(lbl_hash_title)

	var h_row = HBoxContainer.new()
	h_row.add_theme_constant_override("separation", 8)
	_edit_hash = LineEdit.new()
	_edit_hash.text = "098f6bcd4621d373cade4e832627b4f6"
	_edit_hash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit_hash.text_changed.connect(func(_t): _update_cli_preview())
	h_row.add_child(_edit_hash)

	var presets_bar = HBoxContainer.new()
	presets_bar.add_theme_constant_override("separation", 6)
	var presets = [
		{"name": "MD5", "hash": "098f6bcd4621d373cade4e832627b4f6", "mode": 0},
		{"name": "NTLM", "hash": "b4b9b02e6f09a9bd760f388b67351e2b", "mode": 1000},
		{"name": "SHA-256", "hash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "mode": 1400},
		{"name": "bcrypt", "hash": "$2a$10$abcdefghijklmnopqrstuu", "mode": 3200}
	]
	for p in presets:
		var btn_p = Button.new()
		btn_p.text = p["name"]
		_style_btn(btn_p, Color("#334155"), Color("#94a3b8"))
		btn_p.pressed.connect(func():
			_edit_hash.text = p["hash"]
			_select_hash_algo_id(p["mode"])
			_update_cli_preview()
		)
		presets_bar.add_child(btn_p)
	h_row.add_child(presets_bar)
	hash_box.add_child(h_row)
	vbox.add_child(hash_box)

	# 2. Automated Hash Detector Panel
	var det_panel = PanelContainer.new()
	var det_sb = StyleBoxFlat.new()
	det_sb.bg_color = Color("#0b1329")
	det_sb.border_width_left = 2
	det_sb.border_width_top = 1
	det_sb.border_width_right = 1
	det_sb.border_width_bottom = 1
	det_sb.border_color = Color("#38bdf8")
	det_sb.set_corner_radius_all(6)
	det_sb.content_margin_left = 10
	det_sb.content_margin_right = 10
	det_sb.content_margin_top = 8
	det_sb.content_margin_bottom = 8
	det_panel.add_theme_stylebox_override("panel", det_sb)

	var det_vbox = VBoxContainer.new()
	det_vbox.add_theme_constant_override("separation", 6)

	var det_header = HBoxContainer.new()
	det_header.add_theme_constant_override("separation", 8)
	var lbl_det_title = Label.new()
	lbl_det_title.text = "🔍 Интелигентен Анализатор на Хаш Формати:"
	lbl_det_title.add_theme_color_override("font_color", Color("#38bdf8"))
	det_header.add_child(lbl_det_title)

	_edit_detector_input = LineEdit.new()
	_edit_detector_input.placeholder_text = "Поставете непознат хаш за автоматичен анализ..."
	_edit_detector_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	det_header.add_child(_edit_detector_input)

	var btn_detect = Button.new()
	btn_detect.text = "🔍 АНАЛИЗИРАЙ"
	_style_btn(btn_detect, Color("#38bdf8"), Color("#38bdf8"))
	btn_detect.pressed.connect(_on_detect_hash_pressed)
	det_header.add_child(btn_detect)

	_btn_apply_detected = Button.new()
	_btn_apply_detected.text = "✓ ПРИЛОЖИ РЕЖИМ"
	_btn_apply_detected.visible = false
	_style_btn(_btn_apply_detected, Color("#10b981"), Color("#10b981"))
	_btn_apply_detected.pressed.connect(_on_apply_detected_pressed)
	det_header.add_child(_btn_apply_detected)

	det_vbox.add_child(det_header)

	_lbl_detector_results = RichTextLabel.new()
	_lbl_detector_results.bbcode_enabled = true
	_lbl_detector_results.text = "[color=#64748b]Поставете хеш низ за мигновен анализ на битова дължина и сигнатура.[/color]"
	_lbl_detector_results.fit_content = true
	det_vbox.add_child(_lbl_detector_results)

	det_panel.add_child(det_vbox)
	vbox.add_child(det_panel)

	# 3. Mode, Algorithm, Workload Grid
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	vbox.add_child(grid)

	# Row 1: Attack Mode (-a) & Workload (-w)
	var lbl_atk_mode = Label.new()
	lbl_atk_mode.text = "Режим на атаката (-a):"
	grid.add_child(lbl_atk_mode)

	_opt_attack_mode = OptionButton.new()
	_opt_attack_mode.add_item("0 - Straight (Речник / Wordlist)", 0)
	_opt_attack_mode.add_item("1 - Combination (Комбинация от 2 речника)", 1)
	_opt_attack_mode.add_item("3 - Brute-force / Mask (Маска)", 3)
	_opt_attack_mode.add_item("6 - Hybrid Wordlist + Mask (Речник + Маска)", 6)
	_opt_attack_mode.add_item("7 - Hybrid Mask + Wordlist (Маска + Речник)", 7)
	_opt_attack_mode.item_selected.connect(func(_idx): _update_cli_preview())
	grid.add_child(_opt_attack_mode)

	var lbl_workload = Label.new()
	lbl_workload.text = "Натоварване (-w Workload Profile):"
	grid.add_child(lbl_workload)

	_opt_workload = OptionButton.new()
	_opt_workload.add_item("-w 1: Low (Нормален десктоп)", 1)
	_opt_workload.add_item("-w 2: Default (Балансиран)", 2)
	_opt_workload.add_item("-w 3: High (Специализиран риг)", 3)
	_opt_workload.add_item("-w 4: Nightmare (100% GPU Сатурация)", 4)
	_opt_workload.select(2) # Default to -w 3 High
	_opt_workload.item_selected.connect(func(_idx): _update_cli_preview())
	grid.add_child(_opt_workload)

	# Row 2: Hash Algorithm Category & Algorithm (-m)
	var lbl_cat = Label.new()
	lbl_cat.text = "Категория алгоритми:"
	grid.add_child(lbl_cat)

	_opt_hash_category = OptionButton.new()
	_populate_hash_categories()
	_opt_hash_category.item_selected.connect(_on_hash_category_selected)
	grid.add_child(_opt_hash_category)

	var lbl_algo = Label.new()
	lbl_algo.text = "Криптографски режим (-m):"
	grid.add_child(lbl_algo)

	_opt_hash_algo = OptionButton.new()
	_populate_hash_algorithms("Всички")
	_opt_hash_algo.item_selected.connect(func(_idx): _update_cli_preview())
	grid.add_child(_opt_hash_algo)

	# Row 3: Wordlist & Rules / Mask
	var lbl_wl = Label.new()
	lbl_wl.text = "Речник (Wordlist):"
	grid.add_child(lbl_wl)

	_edit_wordlist = LineEdit.new()
	_edit_wordlist.text = "/usr/share/wordlists/rockyou.txt"
	_edit_wordlist.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit_wordlist.text_changed.connect(func(_t): _update_cli_preview())
	grid.add_child(_edit_wordlist)

	var lbl_mask = Label.new()
	lbl_mask.text = "Маска / Файл с правила (-r / Mask):"
	grid.add_child(lbl_mask)

	_edit_mask_rules = LineEdit.new()
	_edit_mask_rules.placeholder_text = "напр. ?u?l?l?d?d?s или best64.rule"
	_edit_mask_rules.text_changed.connect(func(_t): _update_cli_preview())
	grid.add_child(_edit_mask_rules)

	# Row 4: Custom Flags
	var lbl_flags = Label.new()
	lbl_flags.text = "Потребителски флагове (Custom Flags):"
	grid.add_child(lbl_flags)

	_edit_custom_flags = LineEdit.new()
	_edit_custom_flags.placeholder_text = "-O --status --status-timer 1"
	_edit_custom_flags.text = "-O"
	_edit_custom_flags.text_changed.connect(func(_t): _update_cli_preview())
	grid.add_child(_edit_custom_flags)

	# 4. Live CLI Command Preview
	var cli_panel = PanelContainer.new()
	var cli_sb = StyleBoxFlat.new()
	cli_sb.bg_color = Color("#050811")
	cli_sb.border_width_left = 1
	cli_sb.border_width_top = 1
	cli_sb.border_width_right = 1
	cli_sb.border_width_bottom = 1
	cli_sb.border_color = Color("#00f0ff")
	cli_sb.set_corner_radius_all(6)
	cli_sb.content_margin_left = 14
	cli_sb.content_margin_right = 14
	cli_sb.content_margin_top = 10
	cli_sb.content_margin_bottom = 10
	cli_panel.add_theme_stylebox_override("panel", cli_sb)

	_lbl_cli_preview = Label.new()
	_lbl_cli_preview.text = "CLI: hashcat -m 0 -a 0 -d 5 ..."
	_lbl_cli_preview.add_theme_color_override("font_color", Color("#00f0ff"))
	cli_panel.add_child(_lbl_cli_preview)

	vbox.add_child(cli_panel)

# ==============================================================================
# TAB 3: LIVE CONSOLE, TELEMETRY & CRACKED PASSWORDS
# ==============================================================================
func _build_console_tab(parent: VBoxContainer) -> void:
	# Action Toolbar
	var action_bar = HBoxContainer.new()
	action_bar.add_theme_constant_override("separation", 12)

	_btn_start = Button.new()
	_btn_start.text = "🚀 СТАРТИРАЙ АТАКА"
	_btn_start.custom_minimum_size = Vector2(190, 40)
	_style_btn(_btn_start, Color("#10b981"), Color("#10b981"))
	_btn_start.pressed.connect(_on_start_pressed)
	action_bar.add_child(_btn_start)

	_btn_bench = Button.new()
	_btn_bench.text = "⏱️ БЕНЧМАРК (-b)"
	_btn_bench.custom_minimum_size = Vector2(160, 40)
	_style_btn(_btn_bench, Color("#38bdf8"), Color("#38bdf8"))
	_btn_bench.pressed.connect(_on_benchmark_pressed)
	action_bar.add_child(_btn_bench)

	_btn_stop = Button.new()
	_btn_stop.text = "🛑 АВАРИЕН СТОП"
	_btn_stop.custom_minimum_size = Vector2(160, 40)
	_style_btn(_btn_stop, Color("#ef4444"), Color("#ef4444"))
	_btn_stop.pressed.connect(_on_stop_pressed)
	action_bar.add_child(_btn_stop)

	var btn_clear = Button.new()
	btn_clear.text = "🧹 ИЗЧИСТИ ЛОГ"
	btn_clear.custom_minimum_size = Vector2(130, 40)
	_style_btn(btn_clear, Color("#334155"), Color("#94a3b8"))
	btn_clear.pressed.connect(func(): if _console_log: _console_log.clear())
	action_bar.add_child(btn_clear)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_bar.add_child(spacer)

	_lbl_engine_status = Label.new()
	_lbl_engine_status.text = "СТАТУС: ГОТОВ"
	_lbl_engine_status.add_theme_color_override("font_color", Color("#10b981"))
	action_bar.add_child(_lbl_engine_status)

	parent.add_child(action_bar)

	# Live Metrics Strip
	var metrics_panel = PanelContainer.new()
	var m_sb = StyleBoxFlat.new()
	m_sb.bg_color = Color("#09101d")
	m_sb.set_corner_radius_all(6)
	m_sb.content_margin_left = 12
	m_sb.content_margin_right = 12
	m_sb.content_margin_top = 6
	m_sb.content_margin_bottom = 6
	metrics_panel.add_theme_stylebox_override("panel", m_sb)

	var m_hbox = HBoxContainer.new()
	m_hbox.add_theme_constant_override("separation", 24)

	_lbl_speed_val = Label.new()
	_lbl_speed_val.text = "СКОРОСТ: 0.0 MH/s"
	_lbl_speed_val.add_theme_color_override("font_color", Color("#00f0ff"))
	m_hbox.add_child(_lbl_speed_val)

	_lbl_progress_val = Label.new()
	_lbl_progress_val.text = "ПРОГРЕС: 0.00%"
	_lbl_progress_val.add_theme_color_override("font_color", Color("#f59e0b"))
	m_hbox.add_child(_lbl_progress_val)

	_lbl_cracked_count = Label.new()
	_lbl_cracked_count.text = "РАЗБИТИ ПАРОЛИ: 0"
	_lbl_cracked_count.add_theme_color_override("font_color", Color("#10b981"))
	m_hbox.add_child(_lbl_cracked_count)

	metrics_panel.add_child(m_hbox)
	parent.add_child(metrics_panel)

	# Split container between Console Log and Cracked Passwords
	var split = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 800
	parent.add_child(split)

	# Left: Console Output
	var con_box = VBoxContainer.new()
	con_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lbl_con_title = Label.new()
	lbl_con_title.text = "💻 Hashcat Live Log:"
	lbl_con_title.add_theme_color_override("font_color", Color("#94a3b8"))
	con_box.add_child(lbl_con_title)

	_console_log = RichTextLabel.new()
	_console_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_console_log.scroll_following = true
	_console_log.bbcode_enabled = true
	_console_log.text = "[color=#00f0ff]=== HASHCAT QUANTUM OPERATIONS CONSOLE INITIALIZED ===[/color]\n[color=#10b981][INFO] System topology verified. 5 compute nodes ready.[/color]\n"
	con_box.add_child(_console_log)
	split.add_child(con_box)

	# Right: Cracked Passwords Panel
	var cracked_box = VBoxContainer.new()
	cracked_box.custom_minimum_size = Vector2(300, 0)
	var cracked_header = HBoxContainer.new()
	var lbl_crk_title = Label.new()
	lbl_crk_title.text = "🔓 Намерени Пароли:"
	lbl_crk_title.add_theme_color_override("font_color", Color("#10b981"))
	lbl_crk_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cracked_header.add_child(lbl_crk_title)

	var btn_copy_cracked = Button.new()
	btn_copy_cracked.text = "📋 КОПИРАЙ"
	_style_btn(btn_copy_cracked, Color("#334155"), Color("#94a3b8"))
	btn_copy_cracked.pressed.connect(func():
		if _cracked_log:
			DisplayServer.clipboard_set(_cracked_log.get_parsed_text())
	)
	cracked_header.add_child(btn_copy_cracked)
	cracked_box.add_child(cracked_header)

	_cracked_log = RichTextLabel.new()
	_cracked_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cracked_log.scroll_following = true
	_cracked_log.bbcode_enabled = true
	_cracked_log.text = "[color=#64748b]Няма намерени пароли в текущата сесия.\nСтартирайте атака за да наблюдавате резултатите тук.[/color]\n"
	cracked_box.add_child(_cracked_log)
	split.add_child(cracked_box)

# ==============================================================================
# TAB 4: FLAGS GUIDE
# ==============================================================================
func _build_flags_guide_tab(parent: VBoxContainer) -> void:
	var toolbar = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 10)

	var lbl_c = Label.new()
	lbl_c.text = "Категория:"
	toolbar.add_child(lbl_c)

	_opt_flag_category = OptionButton.new()
	var cats = FlagDatabaseScript.get_categories("bg")
	for c in cats:
		_opt_flag_category.add_item(c["name"])
	_opt_flag_category.item_selected.connect(_on_flag_category_selected)
	toolbar.add_child(_opt_flag_category)

	var lbl_s = Label.new()
	lbl_s.text = "Търсене:"
	toolbar.add_child(lbl_s)

	_edit_flag_search = LineEdit.new()
	_edit_flag_search.placeholder_text = "Търси флаг (напр. -O, -w, --hwmon)..."
	_edit_flag_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit_flag_search.text_changed.connect(func(_t): _populate_flags_tree())
	toolbar.add_child(_edit_flag_search)

	parent.add_child(toolbar)

	var split = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 650
	parent.add_child(split)

	# Left: Flags Tree
	_tree_flags = Tree.new()
	_tree_flags.columns = 3
	_tree_flags.set_column_title(0, "Флаг / Опция")
	_tree_flags.set_column_title(1, "Тип")
	_tree_flags.set_column_title(2, "Описание")
	_tree_flags.column_titles_visible = true
	_tree_flags.item_selected.connect(_on_flag_tree_selected)
	split.add_child(_tree_flags)

	# Right: Flag Details Card
	var details_vbox = VBoxContainer.new()
	details_vbox.custom_minimum_size = Vector2(340, 0)
	details_vbox.add_theme_constant_override("separation", 10)

	var lbl_dt = Label.new()
	lbl_dt.text = "📘 Детайли и Синтаксис:"
	lbl_dt.add_theme_color_override("font_color", Color("#38bdf8"))
	details_vbox.add_child(lbl_dt)

	_lbl_flag_details = RichTextLabel.new()
	_lbl_flag_details.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lbl_flag_details.bbcode_enabled = true
	_lbl_flag_details.text = "[color=#64748b]Изберете опция от списъка вляво за подробна справка и синтаксис.[/color]"
	details_vbox.add_child(_lbl_flag_details)

	_btn_add_flag = Button.new()
	_btn_add_flag.text = "➕ ДОБАВИ КЪМ КОМАНДАТА"
	_btn_add_flag.custom_minimum_size = Vector2(0, 38)
	_style_btn(_btn_add_flag, Color("#10b981"), Color("#10b981"))
	_btn_add_flag.pressed.connect(_on_add_flag_to_cli)
	details_vbox.add_child(_btn_add_flag)

	split.add_child(details_vbox)

	_populate_flags_tree()

# ==============================================================================
# HASH ALGORITHM & CATEGORY POPULATION
# ==============================================================================
func _populate_hash_categories() -> void:
	if not _opt_hash_category:
		return
	_opt_hash_category.clear()
	_opt_hash_category.add_item("Всички")
	var all_modes = HashDatabaseScript.get_all_modes()
	var cats: Dictionary = {}
	for m in all_modes:
		var c = m.get("cat", "Общи")
		cats[c] = true
	for c in cats.keys():
		_opt_hash_category.add_item(c)

func _on_hash_category_selected(idx: int) -> void:
	var cat_name = _opt_hash_category.get_item_text(idx)
	_populate_hash_algorithms(cat_name)

func _populate_hash_algorithms(filter_cat: String) -> void:
	if not _opt_hash_algo:
		return
	_opt_hash_algo.clear()
	var all_modes = HashDatabaseScript.get_all_modes()
	for m in all_modes:
		var mode_id: int = m.get("id", 0)
		var mode_name: String = m.get("name", "Unknown")
		var mode_cat: String = m.get("cat", "General")
		if filter_cat == "Всички" or mode_cat == filter_cat:
			_opt_hash_algo.add_item("%s (-m %d)" % [mode_name, mode_id], mode_id)
	_update_cli_preview()

func _select_hash_algo_id(target_id: int) -> void:
	if not _opt_hash_algo:
		return
	for i in range(_opt_hash_algo.item_count):
		if _opt_hash_algo.get_item_id(i) == target_id:
			_opt_hash_algo.select(i)
			return

# ==============================================================================
# HASH DETECTOR LOGIC
# ==============================================================================
func _on_detect_hash_pressed() -> void:
	if not _edit_detector_input or not _lbl_detector_results:
		return
	var raw_hash: String = _edit_detector_input.text.strip_edges()
	if raw_hash.is_empty():
		_lbl_detector_results.text = "[color=#ef4444]Моля, въведете хеш низ за анализ.[/color]"
		_btn_apply_detected.visible = false
		return

	var candidates: Array[Dictionary] = HashDatabaseScript.auto_detect_hash(raw_hash)
	if candidates.is_empty():
		_lbl_detector_results.text = "[color=#ef4444]Не беше открит алгоритъм за дължина %d символа.[/color]" % raw_hash.length()
		_btn_apply_detected.visible = false
		return

	var best = candidates[0]
	_detected_mode_id = best.get("id", 0)
	var bb = "[color=#10b981][b]Разпознат алгоритъм:[/b] %s (-m %d)[/color]\n[color=#38bdf8]Намерени съответствия:[/color] " % [best.get("name"), _detected_mode_id]
	for i in range(candidates.size()):
		var c = candidates[i]
		bb += "%s (-m %d)%s" % [c.get("name"), c.get("id"), ", " if i < candidates.size() - 1 else ""]

	_lbl_detector_results.text = bb
	_btn_apply_detected.text = "✓ Приложи: -m %d (%s)" % [_detected_mode_id, best.get("name")]
	_btn_apply_detected.visible = true

func _on_apply_detected_pressed() -> void:
	if _detected_mode_id >= 0:
		_select_hash_algo_id(_detected_mode_id)
		if _edit_hash and not _edit_detector_input.text.strip_edges().is_empty():
			_edit_hash.text = _edit_detector_input.text.strip_edges()
		_update_cli_preview()
		_append_log("[color=#10b981][ИНТЕЛЕКТ] Приложен разпознат крипто режим: -m %d[/color]" % _detected_mode_id)

# ==============================================================================
# FLAGS GUIDE LOGIC
# ==============================================================================
func _on_flag_category_selected(_idx: int) -> void:
	_populate_flags_tree()

func _populate_flags_tree() -> void:
	if not _tree_flags:
		return
	_tree_flags.clear()
	var root = _tree_flags.create_item()

	var selected_cat_idx = _opt_flag_category.selected if _opt_flag_category else 0
	var cats = FlagDatabaseScript.get_categories("bg")
	var active_cat_id = cats[selected_cat_idx]["id"] if selected_cat_idx < cats.size() else "all"
	var search_text = _edit_flag_search.text.to_lower().strip_edges() if _edit_flag_search else ""

	var all_flags = FlagDatabaseScript.get_all_flags("bg")
	for f in all_flags:
		var cat_id = f.get("cat_id", "")
		var flag_str = f.get("flag", "")
		var title_str = f.get("title", "")
		var desc_str = f.get("desc", "")

		if active_cat_id != "all" and cat_id != active_cat_id:
			continue

		if not search_text.is_empty():
			var match_flag = flag_str.to_lower().contains(search_text)
			var match_title = title_str.to_lower().contains(search_text)
			var match_desc = desc_str.to_lower().contains(search_text)
			if not (match_flag or match_title or match_desc):
				continue

		var item = _tree_flags.create_item(root)
		item.set_text(0, flag_str)
		item.set_text(1, f.get("type", ""))
		item.set_text(2, title_str)
		item.set_metadata(0, f)

func _on_flag_tree_selected() -> void:
	var selected = _tree_flags.get_selected()
	if not selected:
		return
	var data = selected.get_metadata(0)
	if data == null:
		return

	var flag_name = data.get("flag", "")
	var title = data.get("title", "")
	var desc = data.get("desc", "")
	var ex = data.get("example", "")

	_selected_flag_str = ex if not ex.is_empty() else flag_name.split(",")[0].strip_edges()

	var bb = "[color=#00f0ff][b]%s[/b] — %s[/color]\n\n" % [flag_name, title]
	bb += "[color=#e2e8f0]%s[/color]\n\n" % desc
	if not ex.is_empty():
		bb += "[color=#10b981][b]Пример за употреба:[/b][/color]\n[color=#38bdf8]%s[/color]\n" % ex

	if _lbl_flag_details:
		_lbl_flag_details.text = bb

func _on_add_flag_to_cli() -> void:
	if _selected_flag_str.is_empty():
		return
	if _edit_custom_flags:
		var cur = _edit_custom_flags.text.strip_edges()
		if cur.is_empty():
			_edit_custom_flags.text = _selected_flag_str
		else:
			if not _selected_flag_str in cur:
				_edit_custom_flags.text = cur + " " + _selected_flag_str
		_update_cli_preview()
		_append_log("[color=#38bdf8][ФЛАГ] Добавен към командата: %s[/color]" % _selected_flag_str)

# ==============================================================================
# EXECUTION & ACTIONS
# ==============================================================================
func _on_start_pressed() -> void:
	var args: Array = _build_attack_args(false)
	_is_running = true
	_update_engine_state_ui("РАБОТИ / АКТИВЕН", Color("#10b981"))
	_append_log("[color=#00f0ff]>>> ИЗПЪЛНЕНИЕ НА КОМАНДА: hashcat %s[/color]" % " ".join(args))
	attack_requested.emit(args)

func _on_benchmark_pressed() -> void:
	var args: Array = _build_attack_args(true)
	_is_running = true
	_update_engine_state_ui("БЕНЧМАРК", Color("#38bdf8"))
	_append_log("[color=#38bdf8]>>> СТАРТИРАНЕ НА ХАРДУЕРЕН БЕНЧМАРК: hashcat -b %s[/color]" % " ".join(args))
	benchmark_requested.emit()

func _on_stop_pressed() -> void:
	_is_running = false
	_update_engine_state_ui("СПРЯН ОТ ОПЕРАТОР", Color("#ef4444"))
	_append_log("[color=#ef4444][!] АВАРИЕН СТОП: Процесът на атаката е прекъснат.[/color]")
	stop_requested.emit()

func _build_attack_args(is_bench: bool = false) -> Array:
	var args: Array = []
	if is_bench:
		args.append("-b")

	# 1. Mode code
	var m_code: int = 0
	if _opt_hash_algo and _opt_hash_algo.selected >= 0:
		m_code = _opt_hash_algo.get_selected_id()
	args.append("-m")
	args.append(str(m_code))

	# 2. Attack mode
	if not is_bench and _opt_attack_mode:
		var a_code: int = _opt_attack_mode.get_selected_id()
		args.append("-a")
		args.append(str(a_code))

	# 3. Workload
	if _opt_workload:
		var w_code: int = _opt_workload.get_selected_id()
		args.append("-w")
		args.append(str(w_code))

	# 4. Hardware devices flag
	var dev_flag: String = HardwareInspectorScript.get_cli_device_flag()
	if not dev_flag.is_empty():
		var parts = dev_flag.split(" ")
		for p in parts:
			if not p.strip_edges().is_empty():
				args.append(p.strip_edges())

	# 5. Custom flags
	if _edit_custom_flags:
		var cf = _edit_custom_flags.text.strip_edges()
		if not cf.is_empty():
			for item in cf.split(" "):
				if not item.strip_edges().is_empty():
					args.append(item.strip_edges())

	# 6. Target Hash and Wordlist / Mask (if not benchmark)
	if not is_bench:
		var h_str = _edit_hash.text.strip_edges() if _edit_hash else "hash.txt"
		args.append(h_str)

		var wl_str = _edit_wordlist.text.strip_edges() if _edit_wordlist else ""
		if not wl_str.is_empty():
			args.append(wl_str)

		var mask_rules = _edit_mask_rules.text.strip_edges() if _edit_mask_rules else ""
		if not mask_rules.is_empty():
			args.append(mask_rules)

	return args

func _append_log(msg: String) -> void:
	if _console_log:
		_console_log.append_text(msg + "\n")

func append_console_line(line: String) -> void:
	_append_log(line)

func update_engine_telemetry(speed_str: String, progress_str: String, status_str: String) -> void:
	if _lbl_speed_val:
		_lbl_speed_val.text = "СКОРОСТ: " + speed_str
	if _lbl_progress_val:
		_lbl_progress_val.text = "ПРОГРЕС: " + progress_str
	if _lbl_engine_status and not status_str.is_empty():
		_lbl_engine_status.text = "СТАТУС: " + status_str

func add_cracked_password(hash_val: String, plain_val: String) -> void:
	_cracked_count += 1
	if _lbl_cracked_count:
		_lbl_cracked_count.text = "РАЗБИТИ ПАРОЛИ: %d" % _cracked_count
	if _cracked_log:
		if _cracked_count == 1:
			_cracked_log.clear()
		_cracked_log.append_text("[color=#10b981][b]%s[/b][/color] : [color=#00f0ff]%s[/color]\n" % [hash_val, plain_val])

func set_engine_running(running: bool) -> void:
	_is_running = running
	if running:
		_update_engine_state_ui("РАБОТИ / АКТИВЕН", Color("#10b981"))
	else:
		_update_engine_state_ui("ГОТОВ / ИЗЧАКВАНЕ", Color("#94a3b8"))

func _update_engine_state_ui(state_str: String, col: Color) -> void:
	if _lbl_engine_status:
		_lbl_engine_status.text = "СТАТУС: " + state_str
		_lbl_engine_status.add_theme_color_override("font_color", col)

# ==============================================================================
# HARDWARE MODES & SYNC
# ==============================================================================
func set_compute_mode(mode: String) -> void:
	for slot in _slots:
		var activate: bool = false
		if mode == "CPU":
			activate = slot["is_cpu"]
		elif mode == "GPU":
			activate = not slot["is_cpu"]
		elif mode == "ALL":
			activate = true

		slot["enabled"] = activate
		slot["checkbox"].button_pressed = activate
		_update_slot_visuals(slot)
		HardwareInspectorScript.set_device_enabled(slot["id"], activate)
		device_toggled_in_terminal.emit(slot["id"], activate)

	_update_mode_label()
	_update_cli_preview()
	compute_mode_selected.emit(mode)

func _on_device_toggled(dev_id: int, pressed: bool) -> void:
	for slot in _slots:
		if slot["id"] == dev_id:
			slot["enabled"] = pressed
			_update_slot_visuals(slot)
			HardwareInspectorScript.set_device_enabled(dev_id, pressed)
			device_toggled_in_terminal.emit(dev_id, pressed)
			break
	_update_mode_label()
	_update_cli_preview()

func sync_device_state(dev_id: int, enabled: bool) -> void:
	for slot in _slots:
		if slot["id"] == dev_id:
			slot["enabled"] = enabled
			if slot["checkbox"].button_pressed != enabled:
				slot["checkbox"].button_pressed = enabled
			_update_slot_visuals(slot)
			break
	_update_mode_label()
	_update_cli_preview()

func update_device_metrics(dev_id: int, temp: float, fan: float, util: float) -> void:
	for slot in _slots:
		if slot["id"] == dev_id:
			if slot["enabled"]:
				slot["lbl_metric"].text = "%.0f°C | FAN %.0f%% | LOAD %.0f%%" % [temp, fan, util]
			else:
				slot["lbl_metric"].text = "32°C | STANDBY"
			return

func _update_slot_visuals(slot: Dictionary) -> void:
	var en: bool = slot["enabled"]
	var is_cpu: bool = slot["is_cpu"]
	slot["checkbox"].text = "ACTIVE" if en else "ISOLATED"
	slot["stylebox"].border_color = Color("#10b981") if en else Color("#334155")
	if en:
		slot["lbl_badge"].text = "[CPU ACTIVE]" if is_cpu else "[GPU ACTIVE]"
		slot["lbl_badge"].add_theme_color_override("font_color", Color("#10b981") if is_cpu else Color("#00f0ff"))
	else:
		slot["lbl_badge"].text = "[STANDBY]"
		slot["lbl_badge"].add_theme_color_override("font_color", Color("#64748b"))
	slot["card"].queue_redraw()

func _update_mode_label() -> void:
	if not _lbl_mode_status:
		return
	var active_cpus: int = 0
	var active_gpus: int = 0
	for slot in _slots:
		if slot["enabled"]:
			if slot["is_cpu"]:
				active_cpus += 1
			else:
				active_gpus += 1

	if active_cpus > 0 and active_gpus == 0:
		_lbl_mode_status.text = "РЕЖИМ: САМО CPU (NUMA PROTECT - GPU СА ИЗОЛИРАНИ)"
		_lbl_mode_status.add_theme_color_override("font_color", Color("#10b981"))
	elif active_gpus > 0 and active_cpus == 0:
		_lbl_mode_status.text = "РЕЖИМ: САМО GPU (%d УСКОРИТЕЛЯ АКТИВНИ)" % active_gpus
		_lbl_mode_status.add_theme_color_override("font_color", Color("#00f0ff"))
	elif active_gpus > 0 and active_cpus > 0:
		_lbl_mode_status.text = "РЕЖИМ: ХИБРИДЕН (%d GPU + %d CPU ВЪЗЛИ)" % [active_gpus, active_cpus]
		_lbl_mode_status.add_theme_color_override("font_color", Color("#c084fc"))
	else:
		_lbl_mode_status.text = "РЕЖИМ: ВСИЧКИ УСТРОЙСТВА СА ИЗОЛИРАНИ"
		_lbl_mode_status.add_theme_color_override("font_color", Color("#ef4444"))

func _update_cli_preview() -> void:
	if _lbl_cli_preview:
		var args = _build_attack_args(false)
		_lbl_cli_preview.text = "CLI: hashcat " + " ".join(args)

func _style_btn(btn: Button, border_col: Color, text_col: Color) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color("#0d1726")
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 2
	sb.border_color = border_col
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_color_override("font_color", text_col)
