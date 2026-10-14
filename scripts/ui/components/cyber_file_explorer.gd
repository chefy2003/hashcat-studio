class_name CyberFileExplorer
extends PanelContainer

## Cyberpunk In-Terminal File Explorer & Browser.
## Provides seamless 3D SubViewport file navigation with zero parallax,
## single-click folder browsing, direct address bar, bookmarks,
## hash preview auto-detection, and native OS desktop explorer bridge.

signal file_selected(path: String)
signal cancelled()

const HashDatabaseScript = preload("res://scripts/utils/hash_database.gd")

enum Mode {
	HASH_FILE,
	WORDLIST_FILE
}

var current_mode: Mode = Mode.HASH_FILE
var current_dir: String = ""
var selected_file_path: String = ""

# UI References
var _lbl_title: Label
var _edit_path: LineEdit
var _edit_search: LineEdit
var _list_folders: ItemList
var _list_files: ItemList
var _lbl_folder_count: Label
var _lbl_file_count: Label
var _lbl_selected_info: RichTextLabel
var _lbl_preview: RichTextLabel
var _btn_confirm: Button
var _btn_cancel: Button
var _btn_native_os: Button

var _folders: Array[String] = []
var _files: Array[Dictionary] = []

func _ready() -> void:
	_build_ui()
	visible = false

func open_for_hash(initial_path: String = "") -> void:
	current_mode = Mode.HASH_FILE
	if _lbl_title:
		_lbl_title.text = "🎯 КИБЕР ЕКСПЛОРЪР: ИЗБОР НА ХЕШ ФАЙЛ"
	_init_and_show(initial_path)

func open_for_wordlist(initial_path: String = "") -> void:
	current_mode = Mode.WORDLIST_FILE
	if _lbl_title:
		_lbl_title.text = "📚 КИБЕР ЕКСПЛОРЪР: ИЗБОР НА РЕЧНИК"
	if initial_path.is_empty() and DirAccess.dir_exists_absolute("/usr/share/wordlists"):
		initial_path = "/usr/share/wordlists"
	_init_and_show(initial_path)

func _init_and_show(target_path: String) -> void:
	if not _lbl_title:
		_build_ui()
	if current_mode == Mode.HASH_FILE and _lbl_title:
		_lbl_title.text = "🎯 КИБЕР ЕКСПЛОРЪР: ИЗБОР НА ХЕШ ФАЙЛ"
	elif current_mode == Mode.WORDLIST_FILE and _lbl_title:
		_lbl_title.text = "📚 КИБЕР ЕКСПЛОРЪР: ИЗБОР НА РЕЧНИК"
	visible = true
	selected_file_path = ""
	_update_preview("")

	if not target_path.is_empty():
		if DirAccess.dir_exists_absolute(target_path):
			current_dir = target_path
		elif FileAccess.file_exists(target_path):
			current_dir = target_path.get_base_dir()
			selected_file_path = target_path
		else:
			current_dir = OS.get_environment("HOME")
	else:
		if current_dir.is_empty() or not DirAccess.dir_exists_absolute(current_dir):
			current_dir = OS.get_environment("HOME")
			if current_dir.is_empty():
				current_dir = "/"

	_load_directory(current_dir)

func close() -> void:
	visible = false
	cancelled.emit()

func _build_ui() -> void:
	custom_minimum_size = Vector2(1160, 720)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.045, 0.09, 0.96)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color("#00f0ff")
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 16
	sb.content_margin_top = 12
	sb.content_margin_right = 16
	sb.content_margin_bottom = 12
	add_theme_stylebox_override("panel", sb)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	add_child(main_vbox)

	# 1. Header Bar
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)

	_lbl_title = Label.new()
	_lbl_title.text = "📁 КИБЕР ЕКСПЛОРЪР"
	_lbl_title.add_theme_font_size_override("font_size", 17)
	_lbl_title.add_theme_color_override("font_color", Color("#00f0ff"))
	_lbl_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_lbl_title)

	_btn_native_os = Button.new()
	_btn_native_os.text = "🖥️ СИСТЕМЕН ДИАЛОГ (OS)"
	_btn_native_os.tooltip_text = "Отвори системния файлов мениджър на операционната система"
	_style_btn(_btn_native_os, Color("#38bdf8"), Color("#0284c7"))
	_btn_native_os.pressed.connect(_open_native_os_dialog)
	header.add_child(_btn_native_os)

	var btn_close = Button.new()
	btn_close.text = "✕ ЗАТВОРИ"
	_style_btn(btn_close, Color("#ef4444"), Color("#991b1b"))
	btn_close.pressed.connect(close)
	header.add_child(btn_close)
	main_vbox.add_child(header)

	# 2. Bookmarks / Quick Shortcuts Bar
	var bookmarks_bar = HBoxContainer.new()
	bookmarks_bar.add_theme_constant_override("separation", 6)

	var lbl_bm = Label.new()
	lbl_bm.text = "Бърз достъп:"
	lbl_bm.add_theme_color_override("font_color", Color("#94a3b8"))
	bookmarks_bar.add_child(lbl_bm)

	var home_dir = OS.get_environment("HOME")
	_add_bookmark_btn(bookmarks_bar, "🏠 HOME", home_dir)
	_add_bookmark_btn(bookmarks_bar, "📚 WORDLISTS", "/usr/share/wordlists")
	_add_bookmark_btn(bookmarks_bar, "💾 ПРОЕКТ", ProjectSettings.globalize_path("res://"))
	_add_bookmark_btn(bookmarks_bar, "📥 DOWNLOADS", home_dir.path_join("Downloads"))
	_add_bookmark_btn(bookmarks_bar, "📄 DOCUMENTS", home_dir.path_join("Documents"))

	var btn_up = Button.new()
	btn_up.text = "⬆ НАГОРЕ (..)"
	_style_btn(btn_up, Color("#00f0ff"), Color("#0e7490"))
	btn_up.pressed.connect(_navigate_up)
	bookmarks_bar.add_child(btn_up)

	var btn_refresh = Button.new()
	btn_refresh.text = "🔄 ОБНОВИ"
	_style_btn(btn_refresh, Color("#38bdf8"), Color("#1e293b"))
	btn_refresh.pressed.connect(func(): _load_directory(current_dir))
	bookmarks_bar.add_child(btn_refresh)

	main_vbox.add_child(bookmarks_bar)

	# 3. Path & Search Bar
	var path_bar = HBoxContainer.new()
	path_bar.add_theme_constant_override("separation", 8)

	var lbl_p = Label.new()
	lbl_p.text = "Път:"
	lbl_p.add_theme_color_override("font_color", Color("#38bdf8"))
	path_bar.add_child(lbl_p)

	_edit_path = LineEdit.new()
	_edit_path.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_edit_path.text_submitted.connect(_on_path_entered)
	path_bar.add_child(_edit_path)

	var btn_go = Button.new()
	btn_go.text = "ОТИДИ"
	_style_btn(btn_go, Color("#10b981"), Color("#047857"))
	btn_go.pressed.connect(func(): _on_path_entered(_edit_path.text))
	path_bar.add_child(btn_go)

	var lbl_s = Label.new()
	lbl_s.text = "Филтър:"
	lbl_s.add_theme_color_override("font_color", Color("#94a3b8"))
	path_bar.add_child(lbl_s)

	_edit_search = LineEdit.new()
	_edit_search.placeholder_text = "Търси име..."
	_edit_search.custom_minimum_size = Vector2(180, 0)
	_edit_search.text_changed.connect(func(_t): _render_lists())
	path_bar.add_child(_edit_search)

	main_vbox.add_child(path_bar)

	# 4. Main Split: Left (Folders) | Right (Files)
	var split = HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 380
	main_vbox.add_child(split)

	# Left Column: Folders
	var left_vbox = VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vbox.add_theme_constant_override("separation", 4)

	_lbl_folder_count = Label.new()
	_lbl_folder_count.text = "📁 Папки (0):"
	_lbl_folder_count.add_theme_color_override("font_color", Color("#38bdf8"))
	left_vbox.add_child(_lbl_folder_count)

	_list_folders = ItemList.new()
	_list_folders.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_folders.item_selected.connect(_on_folder_selected)
	_list_folders.item_activated.connect(_on_folder_selected)
	_list_folders.gui_input.connect(func(ev): _handle_list_wheel_input(ev, _list_folders))
	left_vbox.add_child(_list_folders)
	split.add_child(left_vbox)

	# Right Column: Files
	var right_vbox = VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 4)

	_lbl_file_count = Label.new()
	_lbl_file_count.text = "📄 Файлове (0):"
	_lbl_file_count.add_theme_color_override("font_color", Color("#10b981"))
	right_vbox.add_child(_lbl_file_count)

	_list_files = ItemList.new()
	_list_files.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_files.item_selected.connect(_on_file_selected)
	_list_files.item_activated.connect(func(_idx): _on_confirm_pressed())
	_list_files.gui_input.connect(func(ev): _handle_list_wheel_input(ev, _list_files))
	right_vbox.add_child(_list_files)
	split.add_child(right_vbox)

	# 5. Bottom Info & Preview Panel
	var bottom_panel = PanelContainer.new()
	var b_sb = StyleBoxFlat.new()
	b_sb.bg_color = Color("#071224cc")
	b_sb.border_width_top = 1
	b_sb.border_color = Color("#00f0ff")
	b_sb.set_corner_radius_all(6)
	b_sb.content_margin_left = 12
	b_sb.content_margin_top = 8
	b_sb.content_margin_right = 12
	b_sb.content_margin_bottom = 8
	bottom_panel.add_theme_stylebox_override("panel", b_sb)

	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 16)
	bottom_panel.add_child(bottom_hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)

	_lbl_selected_info = RichTextLabel.new()
	_lbl_selected_info.bbcode_enabled = true
	_lbl_selected_info.fit_content = true
	_lbl_selected_info.text = "[color=#94a3b8]Няма избран файл.[/color]"
	info_vbox.add_child(_lbl_selected_info)

	_lbl_preview = RichTextLabel.new()
	_lbl_preview.bbcode_enabled = true
	_lbl_preview.custom_minimum_size = Vector2(0, 48)
	_lbl_preview.text = ""
	info_vbox.add_child(_lbl_preview)
	bottom_hbox.add_child(info_vbox)

	# Actions
	var actions_vbox = VBoxContainer.new()
	actions_vbox.custom_minimum_size = Vector2(220, 0)
	actions_vbox.add_theme_constant_override("separation", 6)

	_btn_confirm = Button.new()
	_btn_confirm.text = "✓ ИЗБЕРИ И ЗАРЕДИ"
	_btn_confirm.custom_minimum_size = Vector2(0, 38)
	_style_btn(_btn_confirm, Color("#10b981"), Color("#047857"))
	_btn_confirm.pressed.connect(_on_confirm_pressed)
	actions_vbox.add_child(_btn_confirm)

	_btn_cancel = Button.new()
	_btn_cancel.text = "ОТКАЗ"
	_btn_cancel.custom_minimum_size = Vector2(0, 32)
	_style_btn(_btn_cancel, Color("#64748b"), Color("#1e293b"))
	_btn_cancel.pressed.connect(close)
	actions_vbox.add_child(_btn_cancel)

	bottom_hbox.add_child(actions_vbox)
	main_vbox.add_child(bottom_panel)

func _add_bookmark_btn(parent: Control, label_text: String, target_path: String) -> void:
	if not DirAccess.dir_exists_absolute(target_path):
		return
	var b = Button.new()
	b.text = label_text
	_style_btn(b, Color("#0284c7"), Color("#082f49"))
	b.pressed.connect(func(): _load_directory(target_path))
	parent.add_child(b)

func _navigate_up() -> void:
	var parent_dir = current_dir.get_base_dir()
	if not parent_dir.is_empty() and parent_dir != current_dir:
		_load_directory(parent_dir)

func _on_path_entered(new_path: String) -> void:
	var clean = new_path.strip_edges()
	if clean.is_empty():
		return
	if DirAccess.dir_exists_absolute(clean):
		_load_directory(clean)
	elif FileAccess.file_exists(clean):
		selected_file_path = clean
		_on_confirm_pressed()
	else:
		_lbl_selected_info.text = "[color=#ef4444]Невалиден път: %s[/color]" % clean

func _load_directory(dir_path: String) -> void:
	var da = DirAccess.open(dir_path)
	if not da:
		_lbl_selected_info.text = "[color=#ef4444]Няма права за достъп до: %s[/color]" % dir_path
		return

	current_dir = dir_path
	if _edit_path:
		_edit_path.text = current_dir

	_folders.clear()
	_files.clear()

	da.list_dir_begin()
	var item_name = da.get_next()
	while not item_name.is_empty():
		if not item_name.begins_with("."):
			if da.current_is_dir():
				_folders.append(item_name)
			else:
				var ext = item_name.get_extension().to_lower()
				var full_item_path = dir_path.path_join(item_name)
				var sz = _get_file_size(full_item_path)
				
				# Filter by mode
				if _matches_filter(ext):
					_files.append({
						"name": item_name,
						"path": full_item_path,
						"size": sz,
						"ext": ext
					})
		item_name = da.get_next()
	da.list_dir_end()

	_folders.sort_custom(func(a, b): return a.to_lower() < b.to_lower())
	_files.sort_custom(func(a, b): return a["name"].to_lower() < b["name"].to_lower())

	_render_lists()

func _matches_filter(ext: String) -> bool:
	if current_mode == Mode.HASH_FILE:
		var valid_hash_exts = ["txt", "hash", "hashes", "pot", "hccapx", "cap", "22000", "pcapng", "log", "lst", ""]
		return ext in valid_hash_exts or ext.is_empty()
	elif current_mode == Mode.WORDLIST_FILE:
		var valid_wl_exts = ["txt", "dict", "lst", "words", "rule", "dic", "wordlist", ""]
		return ext in valid_wl_exts or ext.is_empty()
	return true

func _render_lists() -> void:
	if not _list_folders or not _list_files:
		return

	_list_folders.clear()
	_list_files.clear()

	var search = _edit_search.text.strip_edges().to_lower() if _edit_search else ""

	# Add folders
	var f_count = 0
	for f in _folders:
		if search.is_empty() or search in f.to_lower():
			_list_folders.add_item("📁 " + f)
			f_count += 1
	_lbl_folder_count.text = "📁 Папки (%d):" % f_count

	# Add files
	var file_count = 0
	for fl in _files:
		var fname: String = fl["name"]
		if search.is_empty() or search in fname.to_lower():
			var sz_str = _format_size(fl["size"])
			_list_files.add_item("📄 %s  [%s]" % [fname, sz_str])
			_list_files.set_item_metadata(_list_files.get_item_count() - 1, fl["path"])
			file_count += 1
	_lbl_file_count.text = "📄 Файлове (%d):" % file_count

func _format_size(bytes: int) -> String:
	if bytes < 1024:
		return "%d B" % bytes
	elif bytes < 1024 * 1024:
		return "%.1f KB" % (float(bytes) / 1024.0)
	elif bytes < 1024 * 1024 * 1024:
		return "%.1f MB" % (float(bytes) / (1024.0 * 1024.0))
	else:
		return "%.2f GB" % (float(bytes) / (1024.0 * 1024.0 * 1024.0))

func _get_file_size(path: String) -> int:
	if not FileAccess.file_exists(path):
		return 0
	var f = FileAccess.open(path, FileAccess.READ)
	if f:
		var sz = f.get_length()
		f.close()
		return sz
	return 0

func _on_folder_selected(idx: int) -> void:
	if idx < 0 or idx >= _folders.size():
		return
	var folder_name = _folders[idx]
	var next_dir = current_dir.path_join(folder_name)
	_load_directory(next_dir)

func _on_file_selected(idx: int) -> void:
	if idx < 0 or idx >= _list_files.get_item_count():
		return
	var path: String = _list_files.get_item_metadata(idx)
	selected_file_path = path
	_update_preview(path)

func _update_preview(path: String) -> void:
	if not _lbl_selected_info or not _lbl_preview:
		return
	if path.is_empty() or not FileAccess.file_exists(path):
		_lbl_selected_info.text = "[color=#94a3b8]Няма избран файл.[/color]"
		_lbl_preview.text = ""
		return

	var sz = _get_file_size(path)
	_lbl_selected_info.text = "[color=#10b981][b]Избран файл:[/b] %s[/color] [color=#38bdf8](%s)[/color]" % [path, _format_size(sz)]

	var ext: String = path.get_extension().to_lower()
	var fname: String = path.get_file()

	if current_mode == Mode.HASH_FILE:
		if ext in ["cap", "pcap", "pcapng"]:
			var bb = "[color=#00f0ff][b]📡 RAW WI-FI PACKET CAPTURE[/b][/color]\n"
			bb += "[color=#cbd5e1]При избор файлът ще се анализира автоматично чрез [b]hcxpcapngtool[/b].\n"
			bb += "• Автоматично извличане на WPA/WPA2 Handshakes и PMKID\n"
			bb += "• Конвертиране към [b].hc22000[/b] в ~/.hashcat_studio/hashes/\n"
			bb += "• Автоматичен Hashcat Режим: [b]-m 22000[/b] (WPA-PBKDF2-PMKID+EAPOL)[/color]\n"
			bb += "[color=#10b981]✓ Готов за автоматично 1-Click ингестиране![/color]"
			_lbl_preview.text = bb
			return

		if ext == "kdbx":
			var bb = "[color=#f59e0b][b]🔐 KEEPASS PASSWORD DATABASE (.kdbx)[/b][/color]\n"
			bb += "[color=#cbd5e1]При избор хешът ще се извлече автоматично чрез [b]keepass2john[/b].\n"
			bb += "• Автоматичен Hashcat Режим: [b]-m 13400[/b] (KeePass 1 / KeePass 2)[/color]\n"
			bb += "[color=#10b981]✓ Готов за автоматично 1-Click ингестиране![/color]"
			_lbl_preview.text = bb
			return

		if ext == "rar":
			var bb = "[color=#f59e0b][b]📦 RAR ENCRYPTED ARCHIVE (.rar)[/b][/color]\n"
			bb += "[color=#cbd5e1]При избор хешът ще се извлече автоматично чрез [b]rar2john[/b].\n"
			bb += "• Автоматичен Hashcat Режим: [b]-m 13000 (RAR5) / -m 12500 (RAR3-hp)[/b][/color]\n"
			bb += "[color=#10b981]✓ Готов за автоматично 1-Click ингестиране![/color]"
			_lbl_preview.text = bb
			return

		if ext == "7z":
			var bb = "[color=#f59e0b][b]📦 7-ZIP ENCRYPTED ARCHIVE (.7z)[/b][/color]\n"
			bb += "[color=#cbd5e1]При избор хешът ще се извлече автоматично чрез [b]7z2john[/b].\n"
			bb += "• Автоматичен Hashcat Режим: [b]-m 11600 (7-Zip)[/b][/color]\n"
			bb += "[color=#10b981]✓ Готов за автоматично 1-Click ингестиране![/color]"
			_lbl_preview.text = bb
			return

		if ext == "zip":
			var bb = "[color=#f59e0b][b]🗜️ ZIP ENCRYPTED ARCHIVE (.zip)[/b][/color]\n"
			bb += "[color=#cbd5e1]При избор хешът ще се извлече автоматично чрез [b]zip2john[/b].\n"
			bb += "• Автоматичен Hashcat Режим: [b]-m 13600 (WinZip) / -m 17220 (PKZIP)[/b][/color]\n"
			bb += "[color=#10b981]✓ Готов за автоматично 1-Click ингестиране![/color]"
			_lbl_preview.text = bb
			return

		if ext == "pdf":
			var bb = "[color=#f59e0b][b]📄 PDF ENCRYPTED DOCUMENT (.pdf)[/b][/color]\n"
			bb += "[color=#cbd5e1]При избор хешът ще се извлече автоматично чрез [b]pdf2john[/b].\n"
			bb += "• Автоматичен Hashcat Режим: [b]-m 10500 (PDF 1.4 - 1.6)[/b][/color]\n"
			bb += "[color=#10b981]✓ Готов за автоматично 1-Click ингестиране![/color]"
			_lbl_preview.text = bb
			return

		if fname.begins_with("UTC--") or (ext == "json" and "utc" in fname.to_lower()):
			var bb = "[color=#38bdf8][b]💎 ETHEREUM KEYSTORE JSON[/b][/color]\n"
			bb += "[color=#cbd5e1]При избор хешът ще се извлече автоматично чрез [b]ethereum2john[/b].\n"
			bb += "• Автоматичен Hashcat Режим: [b]-m 15600 (PBKDF2) / -m 15700 (SCRYPT)[/b][/color]\n"
			bb += "[color=#10b981]✓ Готов за автоматично 1-Click ингестиране![/color]"
			_lbl_preview.text = bb
			return

		if fname.begins_with("id_") or ext in ["key", "pem"]:
			var bb = "[color=#38bdf8][b]🔑 OPENSSH PRIVATE KEY[/b][/color]\n"
			bb += "[color=#cbd5e1]При избор хешът ще се извлече автоматично чрез [b]ssh2john[/b].\n"
			bb += "• Автоматичен Hashcat Режим: [b]-m 22911 (OpenSSH bcrypt)[/b][/color]\n"
			bb += "[color=#10b981]✓ Готов за автоматично 1-Click ингестиране![/color]"
			_lbl_preview.text = bb
			return

	var f = FileAccess.open(path, FileAccess.READ)
	if f:
		var preview_lines = []
		var count = 0
		var first_valid_hash = ""
		while not f.eof_reached() and count < 4:
			var line = f.get_line().strip_edges()
			if not line.is_empty():
				preview_lines.append(line)
				if first_valid_hash.is_empty() and not line.begins_with("#"):
					first_valid_hash = line
				count += 1
		f.close()

		var bb = "[color=#64748b]Преглед на съдържанието:[/color]\n"
		for l in preview_lines:
			bb += "[color=#cbd5e1]  %s[/color]\n" % l

		if current_mode == Mode.HASH_FILE and not first_valid_hash.is_empty():
			var candidates = HashDatabaseScript.auto_detect_hash(first_valid_hash)
			if not candidates.is_empty():
				var best = candidates[0]
				bb += "[color=#10b981]🎯 Открит вероятен формат: [b]%s (-m %d)[/b][/color]" % [best.get("name"), best.get("id")]

		_lbl_preview.text = bb
	else:
		_lbl_preview.text = "[color=#ef4444]Не може да се прочете файлът.[/color]"

func _on_confirm_pressed() -> void:
	if selected_file_path.is_empty():
		_lbl_selected_info.text = "[color=#ef4444]Моля, изберете файл от списъка вдясно![/color]"
		return
	visible = false
	file_selected.emit(selected_file_path)

var _native_thread: Thread = null

func _open_native_os_dialog() -> void:
	if _native_thread and _native_thread.is_started():
		return
	_native_thread = Thread.new()
	_native_thread.start(_thread_run_native_dialog.bind(current_dir))

func _thread_run_native_dialog(dir_to_open: String) -> void:
	var py_script = """
import sys, os
try:
    import tkinter as tk
    from tkinter import filedialog
    root = tk.Tk()
    root.withdraw()
    init_dir = "%s"
    if not os.path.exists(init_dir):
        init_dir = os.path.expanduser("~")
    fp = filedialog.askopenfilename(initialdir=init_dir, title="Избери файл за Hashcat Studio")
    if fp:
        print("SELECTED:" + fp)
except Exception as e:
    pass
""" % dir_to_open.replace("\\", "/")

	var output = []
	var exit_code = OS.execute("python3", ["-c", py_script], output)
	if exit_code == 0 and not output.is_empty():
		var out_str = output[0] as String
		for line in out_str.split("\n"):
			line = line.strip_edges()
			if line.begins_with("SELECTED:"):
				var picked_path = line.substr(9).strip_edges()
				if FileAccess.file_exists(picked_path):
					call_deferred("_on_native_dialog_picked", picked_path)
					return

func _on_native_dialog_picked(picked_path: String) -> void:
	if _native_thread and _native_thread.is_started():
		_native_thread.wait_to_finish()
	selected_file_path = picked_path
	visible = false
	file_selected.emit(picked_path)

func _style_btn(btn: Button, border_col: Color, bg_col: Color) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 2
	sb.border_color = border_col
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_color_override("font_color", Color("#ffffff"))

func _handle_list_wheel_input(event: InputEvent, list: ItemList) -> void:
	if event is InputEventMouseButton and event.pressed:
		var vbar = list.get_v_scroll_bar()
		if vbar:
			var step = 45.0
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				vbar.value += step
				list.accept_event()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				vbar.value -= step
				list.accept_event()

