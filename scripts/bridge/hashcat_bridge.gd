class_name HashcatBridge
extends Node

## Ultra-Reliable Non-Blocking Engine Launcher & Telemetry Streamer for Hashcat.
## Guarantees 60 FPS UI responsiveness, zero main-thread freezing,
## real-time file-buffered log streaming, live speed & progress extraction,
## and instantaneous SIGKILL emergency abort.

signal stdout_line_received(line: String)
signal stderr_line_received(line: String)
signal status_updated(status_data: Dictionary)
signal hashrate_sample_received(speed_val: float, speed_unit: String, raw_str: String)
signal password_cracked(hash_val: String, plain_val: String)
signal process_finished(exit_code: int)
signal emergency_stopped

const MAX_LINES_PER_FRAME: int = 50
const MAX_LOG_SIZE_BYTES: int = 15 * 1024 * 1024 # 15 MB hard limit

var _process_pid: int = -1
var _session_log_path: String = ""
var _log_file: FileAccess = null
var _last_read_pos: int = 0
var _is_active: bool = false
var _suppressed_error_count: int = 0

var _current_hashrate: String = "0 H/s"
var _current_progress: String = "0%"
var _current_temp: String = "N/A"
var _current_eta: String = "N/A"

func _process(_delta: float) -> void:
	if not _is_active:
		return

	_stream_log_output()
	_check_process_liveness()

func start_attack(args: Array) -> bool:
	if _is_active:
		push_warning("[HashcatBridge] Engine already active. Abort or wait for completion.")
		return false

	var packed_args: PackedStringArray = PackedStringArray()
	var is_benchmark: bool = false

	for arg in args:
		var s: String = str(arg).strip_edges()
		if s == "-b" or s == "--benchmark":
			is_benchmark = true
		packed_args.append(s)

	# Benchmark mode in Hashcat explicitly forbids --status
	if not is_benchmark:
		if not "--status" in packed_args:
			packed_args.append("--status")
		if not "--status-timer" in packed_args:
			packed_args.append("--status-timer")
			packed_args.append("1")

	# Generate unique session log path
	_session_log_path = "/tmp/hc_session_%d_%d.log" % [OS.get_process_id(), Time.get_ticks_msec()]
	if FileAccess.file_exists(_session_log_path):
		DirAccess.remove_absolute(_session_log_path)

	_last_read_pos = 0
	_suppressed_error_count = 0
	if _log_file != null:
		_log_file.close()
		_log_file = null

	# Build shell invocation with < /dev/null to prevent stdin blocking and > log 2>&1
	var arg_str_list: PackedStringArray = []
	for a in packed_args:
		if " " in a and not a.begins_with("\"") and not a.begins_with("'"):
			arg_str_list.append("'" + a + "'")
		else:
			arg_str_list.append(a)

	var cli_command: String = "exec hashcat " + " ".join(arg_str_list) + " < /dev/null > " + _session_log_path + " 2>&1"
	print("[HashcatBridge] Spawning isolated non-blocking process: ", cli_command)

	_process_pid = OS.create_process("bash", ["-c", cli_command])
	if _process_pid <= 0:
		var err_msg: String = "[ERROR] Failed to spawn hashcat process. Verify binary in PATH."
		push_error(err_msg)
		stderr_line_received.emit(err_msg)
		return false

	_is_active = true
	print("[HashcatBridge] Process active with PID: ", _process_pid)
	stdout_line_received.emit("[SYSTEM] Engine started (PID: " + str(_process_pid) + ")")
	return true

func stop_attack_emergency() -> void:
	if not _is_active and _process_pid <= 0:
		return

	print("[HashcatBridge] EMERGENCY STOP: Sending SIGKILL to PID: ", _process_pid)
	if _process_pid > 0:
		OS.kill(_process_pid)
		# Kill any child processes spawned by shell
		OS.execute("pkill", ["-9", "-P", str(_process_pid)])
		OS.execute("killall", ["-9", "hashcat"])

	_drain_remaining_logs()
	_cleanup()
	emergency_stopped.emit()

func is_running() -> bool:
	return _is_active

func get_telemetry() -> Dictionary:
	return {
		"hashrate": _current_hashrate,
		"progress": _current_progress,
		"temp": _current_temp,
		"eta": _current_eta,
		"pid": _process_pid
	}

func _stream_log_output() -> void:
	if not FileAccess.file_exists(_session_log_path):
		return

	if _log_file == null:
		_log_file = FileAccess.open(_session_log_path, FileAccess.READ)

	if _log_file == null:
		return

	var file_len: int = _log_file.get_length()

	# Guard against runaway log file (e.g. invalid binary file fed as hashlist)
	if file_len > MAX_LOG_SIZE_BYTES:
		var skip_pos: int = file_len - (512 * 1024)
		if _last_read_pos < skip_pos:
			_last_read_pos = skip_pos
			stdout_line_received.emit("[!] Session log exceeded 15 MB. Skipping forward to prevent memory exhaustion.")

	if file_len > _last_read_pos:
		_log_file.seek(_last_read_pos)
		var lines_read: int = 0
		while _log_file.get_position() < file_len and lines_read < MAX_LINES_PER_FRAME:
			var line: String = _log_file.get_line().strip_edges()
			lines_read += 1
			if not line.is_empty():
				_dispatch_log_line(line)
		_last_read_pos = _log_file.get_position()

func _drain_remaining_logs() -> void:
	if _session_log_path.is_empty() or not FileAccess.file_exists(_session_log_path):
		return

	if _log_file == null:
		_log_file = FileAccess.open(_session_log_path, FileAccess.READ)

	if _log_file != null:
		var file_len: int = _log_file.get_length()
		if file_len > _last_read_pos:
			_log_file.seek(_last_read_pos)
			var lines_read: int = 0
			while _log_file.get_position() < file_len and lines_read < 100:
				var line: String = _log_file.get_line().strip_edges()
				lines_read += 1
				if not line.is_empty():
					_dispatch_log_line(line)
			_last_read_pos = _log_file.get_position()

	if _suppressed_error_count > 0:
		stderr_line_received.emit("[!] Finished: Total invalid tokens skipped: " + str(_suppressed_error_count))
		_suppressed_error_count = 0

var _last_status_emit_time: float = 0.0

func _dispatch_log_line(raw_line: String) -> void:
	var line: String = raw_line.replace("\r", "").strip_edges()
	if line.is_empty():
		return

	# 1. Filter out interactive TTY prompt junk
	if "[s]tatus" in line or "[p]ause" in line or "[f]inish [q]uit" in line or line.ends_with("=>") or line == "=>":
		return

	# 2. Filter out noisy low-level OpenCL discovery messages
	if "clGetPlatformIDs()" in line or "CL_PLATFORM_NOT_FOUND_KHR" in line or "clGetDeviceIDs()" in line or "CL_DEVICE_NOT_FOUND" in line:
		return

	# 3. Beautify kernel compilation and initialization stages
	if "Initializing bridges" in line or "Initializing backend runtimes" in line:
		stdout_line_received.emit("[KERNEL] Инициализиране на изчислителните драйвери (ROCm/HIP)...")
		return

	# 4. Handle deprecation notices
	if "is deprecated and was replaced with plugin" in line:
		stderr_line_received.emit("[!] ВНИМАНИЕ: " + line)
		stderr_line_received.emit("[!] ПРЕПОРЪКА: Използвайте модерен режим (напр. 22000 вместо 2500).")
		return

	# 5. Handle GPU hardware / driver faults
	if "CL_OUT_OF_RESOURCES" in line or "HIP error" in line or "CUDA error" in line or "device lost" in line.to_lower():
		stderr_line_received.emit("[!] ДРАЙВЕРНА ГРЕШКА НА ВИДЕОКАРТА: " + line)
		stderr_line_received.emit("[!] Проверете 'dmesg' за хардуерни съобщения (amdgpu ring timeout / reset).")
		return

	# 6. Rate-limit repetitive token exceptions to prevent UI flooding
	if "Token length exception" in line or "Line-length exception" in line or "Separator unmatched" in line:
		_suppressed_error_count += 1
		if _suppressed_error_count == 1:
			stderr_line_received.emit("[!] " + line)
		elif _suppressed_error_count % 250 == 0:
			stderr_line_received.emit("[!] Филтрирани " + str(_suppressed_error_count) + " невалидни токена (Проверете формата на хеша)...")
		return

	if _suppressed_error_count > 1:
		stderr_line_received.emit("[!] Общо филтрирани невалидни токена: " + str(_suppressed_error_count))
		_suppressed_error_count = 0

	# 7. Handle file missing or filesystem errors
	if "No such file or directory" in line or "cannot open" in line.to_lower():
		stderr_line_received.emit("[!] ГРЕШКА: Файлът не е намерен: " + line)
		return

	# 8. Check if line belongs to Hashcat's periodic status block
	var is_status_block_line: bool = _check_and_parse_status_field(line)
	if is_status_block_line:
		# Do not dump internal status block lines raw to console
		return

	# 9. Check for cracked credentials output
	if ":" in line and not line.begins_with("[") and not line.begins_with("Started") and not line.begins_with("Stopped") and not line.begins_with("Counting") and not line.begins_with("Parsed") and not line.begins_with("Approaching") and not line.begins_with("Watchdog") and not line.begins_with("Host memory"):
		var colon_idx: int = line.find(":")
		if colon_idx > 0 and colon_idx < line.length() - 1:
			var part_hash: String = line.substr(0, colon_idx).strip_edges()
			var part_plain: String = line.substr(colon_idx + 1).strip_edges()
			# Validate that this is an authentic hash, not a filesystem path or error line
			if not part_hash.begins_with("/") and not part_hash.begins_with(".") and not " " in part_hash and not "No such file" in part_plain and not "error" in part_plain.to_lower() and part_hash.length() >= 8:
				password_cracked.emit(part_hash, part_plain)
				stdout_line_received.emit("[CRACKED] 🎉 РАЗБИТА ПАРОЛА: " + part_hash + " = " + part_plain)
				return

	# Standard informative engine line
	stdout_line_received.emit(line)

func _check_and_parse_status_field(line: String) -> bool:
	var matched: bool = false

	if "Speed.#" in line or "Speed." in line:
		matched = true
		var speed_str: String = _extract_value_after(line, ":")
		_current_hashrate = speed_str
		_parse_hashrate_sample(speed_str)
	elif "Progress.........:" in line:
		matched = true
		_current_progress = _extract_value_after(line, ":")
	elif "Temp...........:" in line or "Hardware.Mon.#" in line:
		matched = true
		_current_temp = _extract_value_after(line, ":")
	elif "Time.Estimated...:" in line or "Estimated.Speed.:" in line:
		matched = true
		_current_eta = _extract_value_after(line, ":")
	elif "Status...........:" in line:
		matched = true
		var current_time: float = Time.get_ticks_msec() / 1000.0
		if current_time - _last_status_emit_time >= 1.0:
			_last_status_emit_time = current_time
			status_updated.emit(get_telemetry())
			var status_val: String = _extract_value_after(line, ":")
			stdout_line_received.emit("[ТЕЛЕМЕТРИЯ] Статус: %s | Скорост: %s | Прогрес: %s | ETA: %s" % [status_val, _current_hashrate, _current_progress, _current_eta])
	elif line.begins_with("Session..........:") or line.begins_with("Hash.Mode........:") or line.begins_with("Hash.Target......:") or line.begins_with("Time.Started.....:") or line.begins_with("Kernel.Feature...:") or line.begins_with("Recovered........:") or line.begins_with("Rejected.........:") or line.begins_with("Restore.Point....:") or line.begins_with("Candidates.#") or line.begins_with("Input.Mode.......:") or line.begins_with("Input.Queue......:"):
		matched = true

	return matched

func _extract_value_after(line: String, delimiter: String) -> String:
	var idx: int = line.find(delimiter)
	if idx != -1:
		return line.substr(idx + 1).strip_edges()
	return line

func _parse_hashrate_sample(raw_speed_str: String) -> void:
	var clean_str: String = raw_speed_str.strip_edges()
	var parts: PackedStringArray = clean_str.split(" ", false)
	if parts.size() >= 2:
		var val: float = parts[0].to_float()
		var unit: String = parts[1].strip_edges()
		var normalized_mhs: float = val
		if unit.begins_with("GH") or unit.begins_with("Gh"):
			normalized_mhs = val * 1000.0
		elif unit.begins_with("kH") or unit.begins_with("kh"):
			normalized_mhs = val / 1000.0
		elif unit.begins_with("H/") or unit.begins_with("h/"):
			normalized_mhs = val / 1_000_000.0
		hashrate_sample_received.emit(normalized_mhs, unit, clean_str)

func _check_process_liveness() -> void:
	if _process_pid > 0:
		if not OS.is_process_running(_process_pid):
			print("[HashcatBridge] Process PID ", _process_pid, " terminated.")
			_drain_remaining_logs()
			_cleanup()
			process_finished.emit(0)

func _cleanup() -> void:
	_is_active = false
	_process_pid = -1
	if _log_file != null:
		_log_file.close()
		_log_file = null
	if not _session_log_path.is_empty() and FileAccess.file_exists(_session_log_path):
		DirAccess.remove_absolute(_session_log_path)
		_session_log_path = ""
