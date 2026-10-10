class_name GpuRack
extends VBoxContainer

## Dynamic Multi-Compute Channel Strip Component for Hashcat Intelligence Studio.
## Automatically probes real system topology (HIP, CUDA, OpenCL) with zero hardcoded devices.
## Supports 1-click Operator switching between:
## - [ 🖥️ САМО CPU ] (Protected mode, zero GPU stress)
## - [ ⚡ САМО GPU ] (Compute accelerators)
## - [ ⚡+🖥️ ХИБРИДЕН ] (All available devices)

signal devices_selection_changed(active_ids: Array[int], cli_device_flag: String)

var _slots: Array[Dictionary] = []
var _btn_mode_gpu: Button = null
var _btn_mode_cpu: Button = null
var _btn_mode_all: Button = null
var _lbl_mode_status: Label = null

func _ready() -> void:
	_build_rack_ui()

func _build_rack_ui() -> void:
	for child in get_children():
		child.queue_free()
	_slots.clear()

	# 1. Header with Live Topology Notice
	var label_header: Label = Label.new()
	label_header.text = "COMPUTE TOPOLOGY & CHANNEL STRIPS"
	label_header.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label_header.add_theme_color_override("font_color", Color("#00F0FF"))
	add_child(label_header)

	# 2. Operator Target Selection Bar (CPU / GPU / ALL)
	var mode_bar: HBoxContainer = HBoxContainer.new()
	mode_bar.custom_minimum_size = Vector2(0, 32)
	mode_bar.add_theme_constant_override("separation", 6)

	_btn_mode_cpu = Button.new()
	_btn_mode_cpu.text = "🖥️ САМО CPU"
	_btn_mode_cpu.tooltip_text = "Активира само процесора през OpenCL (PoCL). Изолира всички видеокарти."
	_btn_mode_cpu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_mode_cpu.clip_text = true
	_btn_mode_cpu.pressed.connect(func(): set_compute_mode("CPU"))
	mode_bar.add_child(_btn_mode_cpu)

	_btn_mode_gpu = Button.new()
	_btn_mode_gpu.text = "⚡ САМО GPU"
	_btn_mode_gpu.tooltip_text = "Активира изчислителните видеокарти. Изолира процесора."
	_btn_mode_gpu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_mode_gpu.clip_text = true
	_btn_mode_gpu.pressed.connect(func(): set_compute_mode("GPU"))
	mode_bar.add_child(_btn_mode_gpu)

	_btn_mode_all = Button.new()
	_btn_mode_all.text = "⚡+🖥️ ХИБРИДЕН"
	_btn_mode_all.tooltip_text = "Активира всички изчислителни устройства (GPU + CPU)."
	_btn_mode_all.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn_mode_all.clip_text = true
	_btn_mode_all.pressed.connect(func(): set_compute_mode("ALL"))
	mode_bar.add_child(_btn_mode_all)

	add_child(mode_bar)

	# 3. Active Mode Status Label
	_lbl_mode_status = Label.new()
	_lbl_mode_status.text = "РЕЖИМ: 🖥️ САМО CPU (NUMA PROTECT - ВСИЧКИ GPU СА ИЗОЛИРАНИ)"
	_lbl_mode_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_lbl_mode_status.clip_text = true
	_lbl_mode_status.add_theme_color_override("font_color", Color("#00FF66"))
	add_child(_lbl_mode_status)

	# 4. Probe Real Hardware Dynamically (Zero Hardcoding)
	var detected_devices: Array[Dictionary] = HardwareInspector.probe_compute_devices()

	var has_gpu: bool = false
	var has_cpu: bool = false
	for dev in detected_devices:
		if dev.get("type", "") == "GPU":
			has_gpu = true
		elif dev.get("type", "") == "CPU":
			has_cpu = true

	if not has_gpu:
		_btn_mode_gpu.disabled = true
		_btn_mode_gpu.tooltip_text = "Няма открити видеокарти на тази система."
	if not has_cpu:
		_btn_mode_cpu.disabled = true
		_btn_mode_cpu.tooltip_text = "Няма открит OpenCL CPU драйвер (инсталирайте pocl-opencl-icd)."

	# 5. Build Dynamic Channel Strips for each detected hardware device
	for dev in detected_devices:
		var dev_id: int = dev.get("id", 1)
		var dev_name: String = dev.get("name", "Device #" + str(dev_id))
		var dev_type: String = dev.get("type", "GPU")
		var dev_backend: String = dev.get("backend", "")
		var is_cpu: bool = (dev_type == "CPU")
		var is_display: bool = dev.get("is_display", false)

		# Default state: CPU is ACTIVE, GPUs start ISOLATED for NUMA/system protection
		var default_enabled: bool = is_cpu

		var strip: PanelContainer = PanelContainer.new()
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color("#1E293B")
		sb.set_corner_radius_all(10)
		sb.border_width_left = 3
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color("#10B981") if default_enabled else Color("#334155")
		sb.set_content_margin_all(8.0)
		strip.add_theme_stylebox_override("panel", sb)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER

		# Hardware Toggle CheckBox
		var chk: CheckBox = CheckBox.new()
		chk.button_pressed = default_enabled
		chk.text = "ACTIVE" if default_enabled else "ISOLATED"
		chk.custom_minimum_size = Vector2(85, 0)
		chk.toggled.connect(func(pressed: bool): _on_device_toggled(dev_id, pressed, chk, sb, strip))
		hbox.add_child(chk)

		# Device Icon & Name Label
		var icon_str: String = "🖥️ " if is_cpu else "⚡ "
		var display_title: String = "%s#%d: %s [%s]" % [icon_str, dev_id, dev_name, dev_backend]
		var lbl_name: Label = Label.new()
		lbl_name.text = display_title
		lbl_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl_name.clip_text = true
		lbl_name.tooltip_text = display_title
		lbl_name.add_theme_color_override("font_color", Color("#FFFFFF") if not is_cpu else Color("#00F0FF"))
		hbox.add_child(lbl_name)

		# Metric Label (Temp / Load / Cores)
		var lbl_temp: Label = Label.new()
		var cores_num: int = dev.get("processors", 0)
		if is_cpu:
			lbl_temp.text = "%d Cores | CPU" % cores_num
		else:
			lbl_temp.text = "38°C | 0%"
		lbl_temp.custom_minimum_size = Vector2(95, 0)
		lbl_temp.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl_temp.add_theme_color_override("font_color", Color("#FFB800"))
		hbox.add_child(lbl_temp)

		# Status Tag Label
		var lbl_status: Label = Label.new()
		if default_enabled:
			lbl_status.text = "[CPU ACTIVE]" if is_cpu else "[GPU COMPUTE]"
		else:
			lbl_status.text = "[ISOLATED]"
		lbl_status.custom_minimum_size = Vector2(110, 0)
		lbl_status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl_status.clip_text = false
		lbl_status.add_theme_color_override("font_color", Color("#00FF66") if default_enabled else Color("#8B949E"))
		hbox.add_child(lbl_status)

		strip.add_child(hbox)
		add_child(strip)

		_slots.append({
			"id": dev_id,
			"name": dev_name,
			"type": dev_type,
			"backend": dev_backend,
			"is_cpu": is_cpu,
			"is_display": is_display,
			"enabled": default_enabled,
			"checkbox": chk,
			"stylebox": sb,
			"strip": strip,
			"lbl_temp": lbl_temp,
			"lbl_status": lbl_status
		})

	_update_mode_label_text()
	_emit_device_selection()

## Switch compute target between "CPU", "GPU", and "ALL" dynamically
func set_compute_mode(mode: String) -> void:
	for slot in _slots:
		var activate: bool = false
		if mode == "CPU":
			activate = slot["is_cpu"]
		elif mode == "GPU":
			activate = (not slot["is_cpu"]) and (not slot["is_display"])
		elif mode == "ALL":
			activate = true

		slot["enabled"] = activate
		slot["checkbox"].button_pressed = activate
		slot["checkbox"].text = "ACTIVE" if activate else "ISOLATED"
		slot["stylebox"].border_color = Color("#10B981") if activate else Color("#334155")
		if activate:
			slot["lbl_status"].text = "[CPU ACTIVE]" if slot["is_cpu"] else "[GPU COMPUTE]"
			slot["lbl_status"].add_theme_color_override("font_color", Color("#10B981"))
		else:
			slot["lbl_status"].text = "[ISOLATED]"
			slot["lbl_status"].add_theme_color_override("font_color", Color("#64748B"))
		slot["strip"].queue_redraw()

	_update_mode_label_text()
	_emit_device_selection()

func _on_device_toggled(dev_id: int, pressed: bool, chk: CheckBox, sb: StyleBoxFlat, strip: PanelContainer) -> void:
	for slot in _slots:
		if slot["id"] == dev_id:
			slot["enabled"] = pressed
			chk.text = "ACTIVE" if pressed else "ISOLATED"
			sb.border_color = Color("#10B981") if pressed else Color("#334155")
			if pressed:
				slot["lbl_status"].text = "[CPU ACTIVE]" if slot["is_cpu"] else "[GPU COMPUTE]"
				slot["lbl_status"].add_theme_color_override("font_color", Color("#10B981"))
			else:
				slot["lbl_status"].text = "[ISOLATED]"
				slot["lbl_status"].add_theme_color_override("font_color", Color("#64748B"))
			strip.queue_redraw()
			break
	_update_mode_label_text()
	_emit_device_selection()

func _update_mode_label_text() -> void:
	if _lbl_mode_status == null:
		return
	var active_gpus: int = 0
	var active_cpus: int = 0
	for slot in _slots:
		if slot["enabled"]:
			if slot["is_cpu"]:
				active_cpus += 1
			else:
				active_gpus += 1

	if active_cpus > 0 and active_gpus == 0:
		_lbl_mode_status.text = "РЕЖИМ: 🖥️ САМО CPU (NUMA PROTECT - ВСИЧКИ GPU СА ИЗОЛИРАНИ)"
		_lbl_mode_status.add_theme_color_override("font_color", Color("#00FF66"))
	elif active_gpus > 0 and active_cpus == 0:
		_lbl_mode_status.text = "РЕЖИМ: ⚡ САМО GPU (%d бр. активни видеокарти)" % active_gpus
		_lbl_mode_status.add_theme_color_override("font_color", Color("#FFD700"))
	elif active_cpus > 0 and active_gpus > 0:
		_lbl_mode_status.text = "РЕЖИМ: ⚡+🖥️ ХИБРИДЕН (CPU + %d GPU)" % active_gpus
		_lbl_mode_status.add_theme_color_override("font_color", Color("#00F0FF"))
	else:
		_lbl_mode_status.text = "РЕЖИМ: ⚠️ ВСИЧКИ УСТРОЙСТВА СА ИЗОЛИРАНИ"
		_lbl_mode_status.add_theme_color_override("font_color", Color("#FF1744"))

func update_telemetry_sensors(telem_data: Dictionary) -> void:
	var cpu_usage: float = telem_data.get("cpu_usage_pct", 0.0)
	var gpus: Array = telem_data.get("gpus", [])

	for slot in _slots:
		if slot["is_cpu"]:
			slot["lbl_temp"].text = "%.1f%% Load" % cpu_usage
			if cpu_usage >= 85.0:
				slot["lbl_temp"].add_theme_color_override("font_color", Color("#FF1744"))
			else:
				slot["lbl_temp"].add_theme_color_override("font_color", Color("#00F0FF"))
		else:
			for g in gpus:
				var card_id: int = g.get("card_id", -1)
				if slot["id"] == (card_id + 1):
					var t: int = g.get("temp_c", 0)
					var u: int = g.get("util_pct", 0)
					if t > 0:
						slot["lbl_temp"].text = str(t) + "°C | " + str(u) + "%"
						if t >= 80:
							slot["lbl_temp"].add_theme_color_override("font_color", Color("#FF1744"))
						elif t >= 65:
							slot["lbl_temp"].add_theme_color_override("font_color", Color("#FF9100"))
						else:
							slot["lbl_temp"].add_theme_color_override("font_color", Color("#FFB800"))

func get_active_device_ids() -> Array[int]:
	var active_ids: Array[int] = []
	for slot in _slots:
		if slot["enabled"]:
			active_ids.append(slot["id"])
	return active_ids

func get_device_cli_flag() -> String:
	var active_ids: Array[int] = get_active_device_ids()
	if active_ids.is_empty():
		return ""
	var str_ids: PackedStringArray = []
	for id in active_ids:
		str_ids.append(str(id))
	return "-d " + ",".join(str_ids)

func _emit_device_selection() -> void:
	var active_ids: Array[int] = get_active_device_ids()
	var flag: String = get_device_cli_flag()
	devices_selection_changed.emit(active_ids, flag)
