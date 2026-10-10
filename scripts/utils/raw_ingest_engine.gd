class_name RawIngestEngine
extends RefCounted

## Automated Raw Ingestion Pipeline for Hashcat Intelligence Studio.
## Automatically detects, converts, and prepares raw files (Wi-Fi .cap/.pcap, Ethereum keystores,
## 7z, PDF, Zip, SSH, or raw hashes) for 1-click execution.

const HashDatabaseScript = preload("res://scripts/utils/hash_database.gd")

static func get_hashes_storage_dir() -> String:
	var home: String = OS.get_environment("HOME")
	if home.is_empty():
		home = "/tmp"
	var base_dir: String = home + "/.hashcat_studio/hashes"
	if not DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)
	return base_dir

static func ingest_file(file_path: String, lang: String = "bg") -> Dictionary:
	var is_bg: bool = (lang == "bg")
	if not FileAccess.file_exists(file_path):
		return {
			"success": false,
			"error": "Файлът не съществува: " + file_path if is_bg else "File does not exist: " + file_path
		}

	var hashes_dir: String = get_hashes_storage_dir()
	var ext: String = file_path.get_extension().to_lower()
	var filename: String = file_path.get_file()

	# 1. Wi-Fi Packet Capture (.cap, .pcap, .pcapng)
	if ext in ["cap", "pcap", "pcapng"]:
		return _convert_wifi_capture(file_path, hashes_dir, lang)

	# 2. Ethereum UTC / Keystore JSON file
	if filename.begins_with("UTC--") or ext == "json":
		if _is_ethereum_json(file_path):
			return _convert_ethereum_keystore(file_path, hashes_dir, lang)

	# 3. 7-Zip Archive (.7z)
	if ext == "7z":
		return _convert_7z(file_path, hashes_dir, lang)

	# 4. PDF Document (.pdf)
	if ext == "pdf":
		return _convert_pdf(file_path, hashes_dir, lang)

	# 5. ZIP Archive (.zip)
	if ext == "zip":
		return _convert_zip(file_path, hashes_dir, lang)

	# 6. SSH Key (.key, id_rsa, id_ed25519)
	if filename.begins_with("id_") or ext in ["key", "pem"]:
		if _is_ssh_private_key(file_path):
			return _convert_ssh(file_path, hashes_dir, lang)

	# 7. Check if file is already a text hash file (.hc22000, .hash, .txt)
	return _detect_plain_hash_file(file_path, lang)

static func _is_ethereum_json(file_path: String) -> bool:
	var f: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return false
	var head: String = f.get_as_text().substr(0, 1500)
	f.close()
	var lower_head: String = head.to_lower()
	return ("crypto" in lower_head or "ciphertext" in lower_head) and ("kdf" in lower_head or "cipher" in lower_head)

static func _is_ssh_private_key(file_path: String) -> bool:
	var f: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return false
	var head: String = f.get_line()
	f.close()
	return head.begins_with("-----BEGIN") and "PRIVATE KEY" in head

static func _find_executable(cmd: String) -> String:
	for candidate in ["/usr/bin/" + cmd, "/usr/local/bin/" + cmd, "/usr/sbin/" + cmd, cmd]:
		var check_out: Array = []
		if OS.execute("which", [candidate], check_out, false) == 0:
			return candidate
	return ""

static func _convert_wifi_capture(cap_path: String, hashes_dir: String, lang: String) -> Dictionary:
	var is_bg: bool = (lang == "bg")
	var base_name: String = cap_path.get_file().get_basename()
	var out_path: String = hashes_dir + "/" + base_name + ".hc22000"

	var hcx_bin: String = _find_executable("hcxpcapngtool")
	if hcx_bin.is_empty():
		return {
			"success": false,
			"error": "Инструментът hcxpcapngtool липсва. Инсталирайте: sudo apt install hcxtools" if is_bg else "Tool hcxpcapngtool missing. Install: sudo apt install hcxtools"
		}

	var output: Array = []
	var exit_code: int = OS.execute(hcx_bin, ["-o", out_path, cap_path], output, true)

	if FileAccess.file_exists(out_path) and FileAccess.get_file_as_string(out_path).strip_edges().length() > 0:
		var raw_hashes: String = FileAccess.get_file_as_string(out_path).strip_edges()
		var hash_count: int = raw_hashes.split("\n").size()
		var essid: String = ""
		var bssid: String = ""

		var parts: PackedStringArray = raw_hashes.split("\n")[0].split("*")
		if parts.size() >= 6:
			bssid = parts[3].to_upper()
			var essid_hex: String = parts[5]
			var bytes: PackedByteArray = []
			var j: int = 0
			while j < essid_hex.length() - 1:
				bytes.append(("0x" + essid_hex.substr(j, 2)).hex_to_int())
				j += 2
			essid = bytes.get_string_from_utf8()

		var meta: Dictionary = {
			"essid": essid,
			"bssid": bssid,
			"handshake_count": hash_count
		}

		var summary: String = ""
		if is_bg:
			summary = "📡 [WI-FI CAPTURE] Конвертиран към Hashcat Mode 22000!\n"
			if not essid.is_empty():
				summary += "• Мрежа (ESSID): %s (BSSID: %s)\n" % [essid, bssid]
			summary += "• Намерени Handshakes/PMKID: %d бр.\n" % hash_count
			summary += "• Хеш файл: %s" % out_path
		else:
			summary = "📡 [WI-FI CAPTURE] Converted to Hashcat Mode 22000!\n"
			if not essid.is_empty():
				summary += "• Network (ESSID): %s (BSSID: %s)\n" % [essid, bssid]
			summary += "• Found Handshakes/PMKID: %d\n" % hash_count
			summary += "• Hash file: %s" % out_path

		return {
			"success": true,
			"format_label": "Wi-Fi Packet Capture (.cap/.pcap)",
			"target_hash_path": out_path,
			"hash_mode": 22000,
			"hash_mode_name": "WPA-PBKDF2-PMKID+EAPOL",
			"recommended_flags": "-O",
			"metadata": meta,
			"summary_message": summary
		}
	else:
		return {
			"success": false,
			"error": "Във файла %s не беше открит валиден WPA Handshake или PMKID!" % cap_path if is_bg else "No valid WPA Handshake or PMKID found in %s!" % cap_path
		}

static func _convert_ethereum_keystore(json_path: String, hashes_dir: String, lang: String) -> Dictionary:
	var is_bg: bool = (lang == "bg")
	var base_name: String = json_path.get_file().get_basename()
	var out_path: String = hashes_dir + "/" + base_name + ".hash"

	var tool_bin: String = _find_executable("ethereum2john")
	if tool_bin.is_empty():
		tool_bin = _find_executable("ethereum2john.py")
	if tool_bin.is_empty():
		if FileAccess.file_exists("/usr/share/john/ethereum2john.py"):
			tool_bin = "python3 /usr/share/john/ethereum2john.py"

	if tool_bin.is_empty():
		return {
			"success": false,
			"error": "Инструментът ethereum2john не е открит." if is_bg else "Tool ethereum2john not found."
		}

	var output: Array = []
	var parts_cmd: PackedStringArray = tool_bin.split(" ")
	var exec_cmd: String = parts_cmd[0]
	var exec_args: PackedStringArray = []
	for k in range(1, parts_cmd.size()):
		exec_args.append(parts_cmd[k])
	exec_args.append(json_path)

	var exit_code: int = OS.execute(exec_cmd, exec_args, output, true)
	if output.is_empty() or exit_code != 0:
		return {
			"success": false,
			"error": "Неуспешно извличане на хеш от Ethereum keystore." if is_bg else "Failed to extract hash from Ethereum keystore."
		}

	var raw_line: String = str(output[0]).strip_edges()
	var hash_str: String = ""
	for l in raw_line.split("\n"):
		l = l.strip_edges()
		if "$ethereum$" in l:
			var idx: int = l.find("$ethereum$")
			hash_str = l.substr(idx).strip_edges()
			break

	if hash_str.is_empty():
		return {
			"success": false,
			"error": "Не е намерен $ethereum$ хеш във файла." if is_bg else "No $ethereum$ hash found in keystore."
		}

	var f: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
	if f != null:
		f.store_string(hash_str + "\n")
		f.close()

	var mode_id: int = 15700
	var mode_name: String = "Ethereum Wallet, SCRYPT"
	var rec_flags: String = "--scrypt-tmto=3"
	if hash_str.begins_with("$ethereum$p*"):
		mode_id = 15600
		mode_name = "Ethereum Wallet, PBKDF2-HMAC-SHA256"
		rec_flags = ""

	var summary: String = ""
	if is_bg:
		summary = "💎 [ETHEREUM KEYSTORE] Разпознат и конвертиран!\n"
		summary += "• Режим: %d | %s\n" % [mode_id, mode_name]
		summary += "• Препоръчан флаг: %s\n" % (rec_flags if not rec_flags.is_empty() else "Няма")
		summary += "• Хеш файл: %s" % out_path
	else:
		summary = "💎 [ETHEREUM KEYSTORE] Recognized and converted!\n"
		summary += "• Mode: %d | %s\n" % [mode_id, mode_name]
		summary += "• Recommended Flag: %s\n" % (rec_flags if not rec_flags.is_empty() else "None")
		summary += "• Hash file: %s" % out_path

	return {
		"success": true,
		"format_label": "Ethereum Keystore (UTC JSON)",
		"target_hash_path": out_path,
		"hash_mode": mode_id,
		"hash_mode_name": mode_name,
		"recommended_flags": rec_flags,
		"metadata": {"raw_hash": hash_str},
		"summary_message": summary
	}

static func _convert_7z(archive_path: String, hashes_dir: String, lang: String) -> Dictionary:
	var is_bg: bool = (lang == "bg")
	var tool_bin: String = _find_executable("7z2john")
	if tool_bin.is_empty():
		return {"success": false, "error": "Липсва 7z2john." if is_bg else "Missing 7z2john."}

	var base_name: String = archive_path.get_file().get_basename()
	var out_path: String = hashes_dir + "/" + base_name + ".hash"

	var output: Array = []
	OS.execute(tool_bin, [archive_path], output, true)
	if output.is_empty():
		return {"success": false, "error": "7z2john не върна резултат." if is_bg else "7z2john returned empty."}

	var hash_str: String = ""
	for l in str(output[0]).split("\n"):
		l = l.strip_edges()
		if "$7z$" in l:
			var idx: int = l.find("$7z$")
			hash_str = l.substr(idx).strip_edges()
			break

	if hash_str.is_empty():
		return {"success": false, "error": "Архивът не е криптиран или няма парола." if is_bg else "Archive is unencrypted."}

	var f: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
	if f != null:
		f.store_string(hash_str + "\n")
		f.close()

	return {
		"success": true,
		"format_label": "7-Zip Encrypted Archive (.7z)",
		"target_hash_path": out_path,
		"hash_mode": 11600,
		"hash_mode_name": "7-Zip",
		"recommended_flags": "-O",
		"metadata": {},
		"summary_message": "📦 [7-ZIP] Извлечен хеш за режим 11600 (7-Zip)!" if is_bg else "📦 [7-ZIP] Extracted hash for Mode 11600!"
	}

static func _convert_pdf(pdf_path: String, hashes_dir: String, lang: String) -> Dictionary:
	var is_bg: bool = (lang == "bg")
	var tool_bin: String = _find_executable("pdf2john")
	if tool_bin.is_empty():
		return {"success": false, "error": "Липсва pdf2john." if is_bg else "Missing pdf2john."}

	var base_name: String = pdf_path.get_file().get_basename()
	var out_path: String = hashes_dir + "/" + base_name + ".hash"

	var output: Array = []
	OS.execute(tool_bin, [pdf_path], output, true)
	if output.is_empty():
		return {"success": false, "error": "pdf2john не върна резултат." if is_bg else "pdf2john empty."}

	var hash_str: String = ""
	for l in str(output[0]).split("\n"):
		l = l.strip_edges()
		if "$pdf$" in l:
			var idx: int = l.find("$pdf$")
			hash_str = l.substr(idx).strip_edges()
			break

	if hash_str.is_empty():
		return {"success": false, "error": "PDF документът няма парола." if is_bg else "PDF has no password."}

	var f: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
	if f != null:
		f.store_string(hash_str + "\n")
		f.close()

	return {
		"success": true,
		"format_label": "PDF Encrypted Document (.pdf)",
		"target_hash_path": out_path,
		"hash_mode": 10500,
		"hash_mode_name": "PDF 1.4 - 1.6 (Acrobat 5 - 8)",
		"recommended_flags": "",
		"metadata": {},
		"summary_message": "📄 [PDF] Извлечен хеш за режим 10500 (PDF)!" if is_bg else "📄 [PDF] Extracted hash for Mode 10500!"
	}

static func _convert_zip(zip_path: String, hashes_dir: String, lang: String) -> Dictionary:
	var is_bg: bool = (lang == "bg")
	var tool_bin: String = _find_executable("zip2john")
	if tool_bin.is_empty():
		return {"success": false, "error": "Липсва zip2john." if is_bg else "Missing zip2john."}

	var base_name: String = zip_path.get_file().get_basename()
	var out_path: String = hashes_dir + "/" + base_name + ".hash"

	var output: Array = []
	OS.execute(tool_bin, [zip_path], output, true)
	if output.is_empty():
		return {"success": false, "error": "zip2john не върна резултат." if is_bg else "zip2john empty."}

	var hash_str: String = ""
	var mode_id: int = 13600
	var mode_name: String = "WinZip"
	for l in str(output[0]).split("\n"):
		l = l.strip_edges()
		if "$zip2$" in l:
			var idx: int = l.find("$zip2$")
			hash_str = l.substr(idx).strip_edges()
			mode_id = 13600
			mode_name = "WinZip"
			break
		elif "$pkzip2$" in l:
			var idx2: int = l.find("$pkzip2$")
			hash_str = l.substr(idx2).strip_edges()
			mode_id = 17220
			mode_name = "PKZIP (Master Key)"
			break

	if hash_str.is_empty():
		return {"success": false, "error": "ZIP архивът не е криптиран." if is_bg else "ZIP is unencrypted."}

	var f: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
	if f != null:
		f.store_string(hash_str + "\n")
		f.close()

	return {
		"success": true,
		"format_label": "ZIP Encrypted Archive (.zip)",
		"target_hash_path": out_path,
		"hash_mode": mode_id,
		"hash_mode_name": mode_name,
		"recommended_flags": "",
		"metadata": {},
		"summary_message": "🗜️ [ZIP] Извлечен хеш за режим %d (%s)!" % [mode_id, mode_name] if is_bg else "🗜️ [ZIP] Extracted hash for Mode %d!" % mode_id
	}

static func _convert_ssh(key_path: String, hashes_dir: String, lang: String) -> Dictionary:
	var is_bg: bool = (lang == "bg")
	var tool_bin: String = _find_executable("ssh2john")
	if tool_bin.is_empty():
		return {"success": false, "error": "Липсва ssh2john." if is_bg else "Missing ssh2john."}

	var base_name: String = key_path.get_file().get_basename()
	var out_path: String = hashes_dir + "/" + base_name + ".hash"

	var output: Array = []
	OS.execute(tool_bin, [key_path], output, true)
	if output.is_empty():
		return {"success": false, "error": "ssh2john не върна резултат." if is_bg else "ssh2john empty."}

	var hash_str: String = ""
	for l in str(output[0]).split("\n"):
		l = l.strip_edges()
		if "$openbsd-bcrypt$" in l or "$ssh" in l:
			var idx: int = l.find(":")
			if idx != -1:
				hash_str = l.substr(idx + 1).strip_edges()
			else:
				hash_str = l
			break

	if hash_str.is_empty():
		return {"success": false, "error": "SSH ключът няма парола (passphrase)." if is_bg else "SSH key has no passphrase."}

	var f: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
	if f != null:
		f.store_string(hash_str + "\n")
		f.close()

	return {
		"success": true,
		"format_label": "SSH Private Key",
		"target_hash_path": out_path,
		"hash_mode": 22911,
		"hash_mode_name": "OpenSSH Private Key (bcrypt)",
		"recommended_flags": "",
		"metadata": {},
		"summary_message": "🔑 [SSH] Извлечен хеш за режим 22911 (OpenSSH)!" if is_bg else "🔑 [SSH] Extracted hash for Mode 22911!"
	}

static func _detect_plain_hash_file(file_path: String, lang: String) -> Dictionary:
	var is_bg: bool = (lang == "bg")
	var f: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if f == null:
		return {"success": false, "error": "Не може да се отвори файлът." if is_bg else "Cannot open file."}

	var first_line: String = ""
	var hash_count: int = 0
	while not f.eof_reached():
		var l: String = f.get_line().strip_edges()
		if not l.is_empty():
			if first_line.is_empty():
				first_line = l
			hash_count += 1
	f.close()

	if first_line.is_empty():
		return {"success": false, "error": "Файлът с хешове е празен." if is_bg else "Hash file is empty."}

	if first_line.begins_with("WPA*01*") or first_line.begins_with("WPA*02*"):
		return {
			"success": true,
			"format_label": "Hashcat WPA Handshake (.hc22000)",
			"target_hash_path": file_path,
			"hash_mode": 22000,
			"hash_mode_name": "WPA-PBKDF2-PMKID+EAPOL",
			"recommended_flags": "-O",
			"metadata": {"count": hash_count},
			"summary_message": ("📡 [WPA 22000] Разпознати %d валидни WPA Handshake хеша!" if is_bg else "📡 [WPA 22000] Detected %d valid WPA Handshake hashes!") % hash_count
		}

	var matches: Array[Dictionary] = HashDatabaseScript.auto_detect_hash(first_line)
	if not matches.is_empty():
		var top: Dictionary = matches[0]
		var rec_flag: String = "-O" if top["id"] in [0, 100, 1000, 1400, 22000] else ""
		var summary_text: String = ""
		if hash_count > 1:
			if is_bg:
				summary_text = "📋 [МУЛТИ-ХЕШ СПИСЪК] Разпознати %d бр. хеша във файла!\n• Алгоритъм: Режим %d | %s (%s)\n• Hashcat ще ги атакува ВСИЧКИ ЕДНОВРЕМЕННО в един цикъл!" % [hash_count, top["id"], top["name"], top["confidence"]]
			else:
				summary_text = "📋 [MULTI-HASH BATCH] Detected %d hashes in file!\n• Mode: %d | %s (%s)\n• Hashcat will crack ALL of them SIMULTANEOUSLY in parallel!" % [hash_count, top["id"], top["name"], top["confidence"]]
		else:
			summary_text = ("🔍 [АВТО-ДЕТЕКТИРАН ХЕШ] Режим %d | %s (%s)" if is_bg else "🔍 [AUTO-DETECTED HASH] Mode %d | %s (%s)") % [top["id"], top["name"], top["confidence"]]

		return {
			"success": true,
			"format_label": top["name"],
			"target_hash_path": file_path,
			"hash_mode": top["id"],
			"hash_mode_name": top["name"],
			"recommended_flags": rec_flag,
			"metadata": {"confidence": top["confidence"], "count": hash_count},
			"summary_message": summary_text
		}

	return {
		"success": true,
		"format_label": "Текстов файл с хешове",
		"target_hash_path": file_path,
		"hash_mode": 0,
		"hash_mode_name": "MD5",
		"recommended_flags": "",
		"metadata": {"count": hash_count},
		"summary_message": ("📄 Зареден списък с %d хеша: " if is_bg else "📄 Loaded list with %d hashes: ") % hash_count + file_path
	}
