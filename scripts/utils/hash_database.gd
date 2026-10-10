class_name HashDatabase
extends RefCounted

## Comprehensive Hashcat Algorithm Database & Auto-Detection Engine.
## Maps 50+ key Hashcat modes, categorizes algorithms, and auto-detects pasted hash formats.

static func get_all_modes() -> Array[Dictionary]:
    return [
        # Raw Hashes / Checksums
        {"id": 0, "name": "MD5", "cat": "Hashes & Checksums", "example": "8743b73db798948206ecb610ce00148a"},
        {"id": 100, "name": "SHA1", "cat": "Hashes & Checksums", "example": "b89eaac7e61417341b71070b4f466d38"},
        {"id": 1400, "name": "SHA2-256", "cat": "Hashes & Checksums", "example": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"},
        {"id": 1700, "name": "SHA2-512", "cat": "Hashes & Checksums", "example": "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"},
        {"id": 17800, "name": "SHA3-512", "cat": "Hashes & Checksums", "example": "a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a615b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26"},
        {"id": 600, "name": "BLAKE2b-512", "cat": "Hashes & Checksums", "example": "c76f1..."},

        # Operating Systems & Active Directory
        {"id": 1000, "name": "NTLM", "cat": "Windows & Active Directory", "example": "b4b9b02e6f09a9bd760f388b67351e2b"},
        {"id": 3000, "name": "LM", "cat": "Windows & Active Directory", "example": "2990558197823432"},
        {"id": 5500, "name": "NetNTLMv1 / NetNTLMv1+ESS", "cat": "Windows & Active Directory", "example": "u4-admin::DOMAIN:z:z:z"},
        {"id": 5600, "name": "NetNTLMv2", "cat": "Windows & Active Directory", "example": "admin::DOMAIN:1122334455667788:z:z"},
        {"id": 18200, "name": "Kerberos 5 AS-REP (etype 23)", "cat": "Windows & Active Directory", "example": "$krb5asrep$23$user@domain:..."},
        {"id": 13100, "name": "Kerberos 5 TGS-REP (etype 23 / Kerberoast)", "cat": "Windows & Active Directory", "example": "$krb5tgs$23$*user$domain*..."},

        # Linux / Unix Passwords
        {"id": 500, "name": "md5crypt $1$ / Cisco-MD5", "cat": "Linux / Unix", "example": "$1$salt$16-char-hash"},
        {"id": 1800, "name": "sha512crypt $6$", "cat": "Linux / Unix", "example": "$6$rounds=5000$salt$hash..."},
        {"id": 3200, "name": "bcrypt $2a$, $2y$, $2b$", "cat": "Linux / Unix", "example": "$2a$10$abcdefghijklmnopqrstuu..."},
        {"id": 10900, "name": "PBKDF2-HMAC-SHA256", "cat": "Linux / Unix", "example": "$pbkdf2-sha256$10000$salt$hash"},
        {"id": 16000, "name": "Argon2d / Argon2i / Argon2id", "cat": "Linux / Unix", "example": "$argon2id$v=19$m=65536..."},

        # Wireless / Network Security
        {"id": 2500, "name": "WPA-EAPOL-PBKDF2 (Legacy)", "cat": "Wireless / Network", "example": "wpa-eapol-hash"},
        {"id": 22000, "name": "WPA-PBKDF2-PMKID / EAPOL (Modern)", "cat": "Wireless / Network", "example": "WPA*02*PMKID*..."},

        # Archives & Disk Encryption
        {"id": 11600, "name": "7-Zip (AES-256)", "cat": "Archives & Encryption", "example": "$7z$0$19$0$..."},
        {"id": 12500, "name": "RAR5", "cat": "Archives & Encryption", "example": "$rar5$16$..."},
        {"id": 13600, "name": "WinZip (AES-256)", "cat": "Archives & Encryption", "example": "$zip2$*0*1*0*..."},
        {"id": 10500, "name": "PDF 1.4 - 1.6 (Acrobat 5 - 8)", "cat": "Archives & Encryption", "example": "$pdf$1*2*..."},
        {"id": 10700, "name": "PDF 1.7 Level 8 (Acrobat 9 - 11, AES-256)", "cat": "Archives & Encryption", "example": "$pdf$5*..."},
        {"id": 14600, "name": "LUKS v1 (AES)", "cat": "Archives & Encryption", "example": "$LUKS$1$..."},
        {"id": 29500, "name": "LUKS v2", "cat": "Archives & Encryption", "example": "$LUKS$2$..."},
        {"id": 13700, "name": "VeraCrypt", "cat": "Archives & Encryption", "example": "veracrypt-volume-header"},
        {"id": 22100, "name": "BitLocker (AES)", "cat": "Archives & Encryption", "example": "$bitlocker$0$..."},
        {"id": 26403, "name": "AES-256-ECB NOKDF (Known-Plaintext)", "cat": "Hashes & Checksums", "example": "264a4248c9522cb74d33fe26cb596895:61270210011294880287232432636227"},

        # Cryptocurrency Wallets
        {"id": 11300, "name": "Bitcoin / Litecoin Wallet (AES-256-CBC)", "cat": "Cryptocurrency Wallets", "example": "$bitcoin$64$..."},
        {"id": 15700, "name": "Ethereum Wallet, SCRYPT (Geth UTC JSON / MetaMask)", "cat": "Cryptocurrency Wallets", "example": "$ethereum$s*262144*8*1*..."},
        {"id": 15600, "name": "Ethereum Wallet, PBKDF2-HMAC-SHA256", "cat": "Cryptocurrency Wallets", "example": "$ethereum$p*262144*..."},
        {"id": 16300, "name": "Ethereum Pre-Sale Wallet (Genesis 2014)", "cat": "Cryptocurrency Wallets", "example": "$ethereum$p*2000*..."},
        {"id": 16600, "name": "Electrum Wallet (Salted SHA512)", "cat": "Cryptocurrency Wallets", "example": "$electrum$1$..."},
        {"id": 26600, "name": "MetaMask Wallet (AES-GCM)", "cat": "Cryptocurrency Wallets", "example": "$metamask$..."},
        {"id": 17800, "name": "Keccak-256 (Ethereum / EVM)", "cat": "Hashes & Checksums", "example": "203f88777f18bb4ee1226627b547808f38d90d3e106262b5de9ca943b57137b6"},

        # Web Applications & Databases
        {"id": 12, "name": "PostgreSQL Password", "cat": "Web & Databases", "example": "md5..."},
        {"id": 131, "name": "MSSQL (2000 / 2005 / 2008+)", "cat": "Web & Databases", "example": "0x0100..."},
        {"id": 400, "name": "phpass / WordPress / phpBB3", "cat": "Web & Databases", "example": "$P$91234567890abcdef..."},
        {"id": 1100, "name": "Domain Cached Credentials (DCC / MSCash)", "cat": "Web & Databases", "example": "admin:2134567890abcdef..."},
        {"id": 2100, "name": "Domain Cached Credentials 2 (DCC2 / MSCash2)", "cat": "Web & Databases", "example": "$DCC2$10240#admin#..."},
        {"id": 10000, "name": "Django (PBKDF2-SHA256)", "cat": "Web & Databases", "example": "pbkdf2_sha256$10000$salt$hash"},
        {"id": 22911, "name": "OpenSSH Private Key (bcrypt KDF + AES)", "cat": "Linux / Unix", "example": "$openbsd-bcrypt$..."}
    ]

static func auto_detect_hash(raw_hash: String) -> Array[Dictionary]:
    var matches: Array[Dictionary] = []
    var clean_hash: String = raw_hash.strip_edges()

    if clean_hash.is_empty():
        return matches

    var all_modes: Array[Dictionary] = get_all_modes()

    if clean_hash.begins_with("$2a$") or clean_hash.begins_with("$2y$") or clean_hash.begins_with("$2b$"):
        _add_match(matches, all_modes, 3200, "High (Matches bcrypt structure)")
    elif clean_hash.begins_with("$6$"):
        _add_match(matches, all_modes, 1800, "High (Matches sha512crypt $6$)")
    elif clean_hash.begins_with("$1$"):
        _add_match(matches, all_modes, 500, "High (Matches md5crypt $1$)")
    elif clean_hash.begins_with("WPA*") or clean_hash.begins_with("WPA#"):
        _add_match(matches, all_modes, 22000, "High (Matches WPA PMKID format)")
    elif clean_hash.begins_with("$ethereum$s*"):
        _add_match(matches, all_modes, 15700, "Definitive (Ethereum Scrypt Keystore - Mode 15700)")
    elif clean_hash.begins_with("$ethereum$p*"):
        _add_match(matches, all_modes, 15600, "High (Ethereum PBKDF2 Keystore - Mode 15600)")
        _add_match(matches, all_modes, 16300, "Possible (Ethereum Pre-Sale Wallet - Mode 16300)")
    elif clean_hash.begins_with("$metamask$"):
        _add_match(matches, all_modes, 26600, "Definitive (MetaMask Wallet AES-GCM - Mode 26600)")
    elif clean_hash.begins_with("$bitlocker$"):
        _add_match(matches, all_modes, 22100, "Definitive (BitLocker AES Volume - Mode 22100)")
    elif clean_hash.begins_with("$pdf$5*") or clean_hash.begins_with("$pdf$5$"):
        _add_match(matches, all_modes, 10700, "Definitive (PDF 1.7 Level 8 AES-256 - Mode 10700)")
    elif clean_hash.begins_with("$pdf$"):
        _add_match(matches, all_modes, 10500, "Definitive (PDF 1.4-1.6 - Mode 10500)")
    elif clean_hash.begins_with("$zip2$"):
        _add_match(matches, all_modes, 13600, "Definitive (WinZip AES-256 - Mode 13600)")
    elif clean_hash.begins_with("$LUKS$") or clean_hash.begins_with("$luks$"):
        _add_match(matches, all_modes, 14600, "High (LUKS Disk Encryption AES)")
    elif clean_hash.begins_with("$bitcoin$"):
        _add_match(matches, all_modes, 11300, "Definitive (Bitcoin/Litecoin wallet.dat AES)")
    elif clean_hash.begins_with("$openbsd-bcrypt$"):
        _add_match(matches, all_modes, 22911, "Definitive (OpenSSH Private Key bcrypt - Mode 22911)")
    elif "UTC--" in clean_hash or ("crypto" in clean_hash and "cipher" in clean_hash):
        if "scrypt" in clean_hash.to_lower():
            _add_match(matches, all_modes, 15700, "Detected: Raw Geth Scrypt JSON (Extract with ethereum2john)")
        else:
            _add_match(matches, all_modes, 15600, "Detected: Raw Geth PBKDF2 JSON (Extract with ethereum2john)")
    elif clean_hash.begins_with("0x") and clean_hash.length() == 66 and _is_hex(clean_hash.substr(2)):
        _add_match(matches, all_modes, 17800, "High (Keccak-256 0x-prefixed 32-byte hash)")
        _add_match(matches, all_modes, 1400, "Possible (SHA2-256 0x-prefixed)")
    elif clean_hash.begins_with("$krb5tgs$"):
        _add_match(matches, all_modes, 13100, "High (Matches Kerberos TGS-REP)")
    elif clean_hash.begins_with("$krb5asrep$"):
        _add_match(matches, all_modes, 18200, "High (Matches Kerberos AS-REP)")
    elif clean_hash.begins_with("$7z$"):
        _add_match(matches, all_modes, 11600, "High (Matches 7-Zip AES-256 Archive)")
    elif clean_hash.begins_with("$rar5$"):
        _add_match(matches, all_modes, 12500, "High (Matches RAR5 Archive)")
    elif ":" in clean_hash and clean_hash.split(":").size() == 2 and clean_hash.split(":")[0].length() == 32 and _is_hex(clean_hash.split(":")[0]):
        _add_match(matches, all_modes, 26403, "High (AES-256-ECB Known-Plaintext: Cipher:Plain)")
    elif clean_hash.length() == 32 and _is_hex(clean_hash):
        _add_match(matches, all_modes, 0, "Possible (32-char Hex MD5)")
        _add_match(matches, all_modes, 1000, "Possible (32-char Hex NTLM)")
    elif clean_hash.length() == 40 and _is_hex(clean_hash):
        _add_match(matches, all_modes, 100, "Possible (40-char Hex SHA1)")
    elif clean_hash.length() == 64 and _is_hex(clean_hash):
        _add_match(matches, all_modes, 1400, "High (64-char Hex SHA2-256 / SHA-256)")
        _add_match(matches, all_modes, 17800, "High (64-char Hex Keccak-256 - Ethereum)")
        _add_match(matches, all_modes, 26403, "Possible (256-bit Raw AES Key / Ciphertext)")

    return matches

static func _add_match(matches: Array[Dictionary], all_modes: Array[Dictionary], mode_id: int, confidence: String) -> void:
    for mode in all_modes:
        if mode["id"] == mode_id:
            var match_dict: Dictionary = mode.duplicate()
            match_dict["confidence"] = confidence
            matches.append(match_dict)
            return

static func _is_hex(s: String) -> bool:
    for i in range(s.length()):
        var c: String = s[i].to_lower()
        if not (c >= "0" and c <= "9") and not (c >= "a" and c <= "f"):
            return false
    return true

static var _hash_info_cache: Dictionary = {}

static func get_example_info(mode_id: int) -> Dictionary:
    if _hash_info_cache.has(mode_id):
        return _hash_info_cache[mode_id]

    var output: Array = []
    var exit_code: int = OS.execute("hashcat", ["-m", str(mode_id), "--example-hashes", "--machine-readable"], output, true)
    var ex_hash: String = ""
    var ex_pass: String = ""
    var ex_mask: String = ""
    var name: String = ""
    var is_deprecated: bool = false
    var dep_notice: String = ""
    var replacement_id: int = -1

    if exit_code == 0 and output.size() > 0:
        var raw_out: String = output[0]
        var json_start: int = raw_out.find("{")
        var json_end: int = raw_out.rfind("}")
        if json_start != -1 and json_end != -1 and json_end > json_start:
            var json_text: String = raw_out.substr(json_start, json_end - json_start + 1)
            var parsed: Variant = JSON.parse_string(json_text)
            if parsed is Dictionary and parsed.has(str(mode_id)):
                var data: Dictionary = parsed[str(mode_id)]
                name = data.get("name", "")
                ex_hash = data.get("example_hash", "")
                ex_pass = data.get("example_pass", "")
                ex_mask = data.get("benchmark_mask", "")
                is_deprecated = data.get("is_deprecated", false)
                dep_notice = data.get("deprecated_notice", "")

    # Handle mode 2500 deprecation explicitly
    if mode_id == 2500:
        is_deprecated = true
        replacement_id = 22000
        if dep_notice.is_empty():
            dep_notice = "Mode 2500 (WPA-EAPOL) is deprecated in Hashcat. Use modern Mode 22000 (WPA-PBKDF2-PMKID/EAPOL)."

    if ex_hash.is_empty():
        for m in get_all_modes():
            if m["id"] == mode_id:
                ex_hash = m.get("example", "")
                name = m.get("name", "")
                ex_pass = "hashcat"
                break

    var result: Dictionary = {
        "id": mode_id,
        "name": name,
        "example_hash": ex_hash,
        "example_pass": ex_pass,
        "benchmark_mask": ex_mask,
        "is_deprecated": is_deprecated,
        "deprecated_notice": dep_notice,
        "replacement_id": replacement_id
    }
    _hash_info_cache[mode_id] = result
    return result
