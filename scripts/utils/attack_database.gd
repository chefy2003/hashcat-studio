class_name AttackDatabase
extends RefCounted

## Comprehensive Attack Mode & Algorithm Intelligence Database for Hashcat Studio.
## Provides deep technical descriptions, required input specifications, real-world command examples,
## and expert tuning tips in Bulgarian and English.

static func get_attack_mode_intel(mode_id: int, lang: String = "bg") -> Dictionary:
	var is_bg: bool = (lang == "bg")
	match mode_id:
		0:
			return {
				"id": 0,
				"name": "0 | Straight / Dictionary" if not is_bg else "0 | Пряка атака с речник (Dictionary)",
				"short_desc": "Sequential testing of candidate words from one or more dictionaries." if not is_bg else "Последователно тестване на думи от един или повече текстови речници.",
				"mechanism": (
					"Hashcat reads words line-by-line from the specified wordlist file, applies any optional rule mutations (-r / -j / -k), hashes the candidates, and compares them with the target hash."
					if not is_bg else
					"Hashcat чете думи ред по ред от посочения речник (wordlist), прилага опционални правила за модификация (-r / -j / -k), изчислява хеша и го сравнява с целта."
				),
				"required_inputs": (
					"• Target: Raw hash or file with hashes (.hash / .txt / .hc22000)\n• Wordlist: Path to a plain text dictionary file (e.g. rockyou.txt)"
					if not is_bg else
					"• Цел: Хеш низ или файл с хешове (.hash / .txt / .hc22000)\n• Речник: Път до текстов файл с думи (напр. /path/to/rockyou.txt)"
				),
				"example_cli": "hashcat -a 0 -m {MODE} target.hash rockyou.txt",
				"pro_tip": (
					"Combine with rules (-r rules/best64.rule) to multiply candidates with common character substitutions (e.g. password -> P@ssw0rd!)."
					if not is_bg else
					"Комбинирайте с правила (-r rules/best64.rule), за да генерирате вариации (напр. password -> P@ssw0rd123)."
				)
			}
		1:
			return {
				"id": 1,
				"name": "1 | Combination" if not is_bg else "1 | Комбинационна атака (Dict + Dict)",
				"short_desc": "Combines every word from Wordlist #1 with every word from Wordlist #2." if not is_bg else "Комбинира всяка дума от Речник #1 с всяка дума от Речник #2 (напр. Име + Година).",
				"mechanism": (
					"Performs a Cartesian product of two dictionaries: for every word in list 1, it concatenates every word in list 2 (e.g., 'admin' + '2024' = 'admin2024'). Highly effective against compound passphrases."
					if not is_bg else
					"Извършва декартово произведение на два речника: всяка дума от Речник 1 се залепя към всяка дума от Речник 2 (напр. 'admin' + '2024' = 'admin2024'). Изключително ефективно за съставни пароли."
				),
				"required_inputs": (
					"• Target: Target hash or hash file\n• Wordlist: Path to Wordlist #1\n• Extra Flags: Path to Wordlist #2 (added as second dictionary argument)"
					if not is_bg else
					"• Цел: Целеви хеш или файл\n• Основен речник: Път до Речник #1\n• Допълнителен речник: Път до Речник #2 (посочва се в полето за допълнителни флагове)"
				),
				"example_cli": "hashcat -a 1 -m {MODE} target.hash words1.txt words2.txt",
				"pro_tip": (
					"Use small, targeted wordlists (e.g. names + common suffixes) to keep the search space manageable."
					if not is_bg else
					"Използвайте малки профилирани речници (напр. имена + чести суфикси), за да избегнете експлозия в обема на търсене."
				)
			}
		3:
			return {
				"id": 3,
				"name": "3 | Mask / Brute-force" if not is_bg else "3 | Маска / Brute-force (Mask Attack)",
				"short_desc": "Generates candidates mathematically using pattern charsets (?d, ?l, ?u, ?s, ?a)." if not is_bg else "Математическо генериране на кандидати по шаблон (?d, ?l, ?u, ?s, ?a).",
				"mechanism": (
					"Instead of reading disk files, Hashcat's GPU compute kernels synthesize keys directly in hardware memory according to a mask string. Charsets: ?l (a-z), ?u (A-Z), ?d (0-9), ?s (special symbols), ?a (all printable)."
					if not is_bg else
					"Вместо четене от диска, видеокартите генерират кандидатите директно във VRAM по зададена маска. Набори: ?l (малки букви a-z), ?u (главни A-Z), ?d (цифри 0-9), ?s (символи), ?a (всички)."
				),
				"required_inputs": (
					"• Target: Target hash or handshake (.hc22000)\n• Mask Pattern: Placed in the Wordlist field (e.g. ?d?d?d?d?d?d?d?d for 8-digit PINs, or ?u?l?l?l?l?d?d?d)"
					if not is_bg else
					"• Цел: Целеви хеш или WPA handshake\n• Маска / Шаблон: Въвежда се в полето за речник (напр. ?d?d?d?d?d?d?d?d за 8-цифрени PIN кодове на рутери)"
				),
				"example_cli": "hashcat -a 3 -m {MODE} target.hc22000 ?d?d?d?d?d?d?d?d",
				"pro_tip": (
					"For standard Wi-Fi router defaults, ?d?d?d?d?d?d?d?d (8 digits) searches 100M keys and completes in seconds on MI25 GPUs!"
					if not is_bg else
					"За фабрични Wi-Fi пароли: ?d?d?d?d?d?d?d?d (8 цифри = 100 милиона комбинации) се разбива за секунди на MI25 карти!"
				)
			}
		6:
			return {
				"id": 6,
				"name": "6 | Hybrid Dict + Mask" if not is_bg else "6 | Хибрид: Речник + Маска (Dict + Suffix)",
				"short_desc": "Takes words from dictionary and appends a mask pattern to the end (suffix)." if not is_bg else "Взема думи от речника и добавя маска накрая им (суфикс).",
				"mechanism": (
					"Appends characters defined by a mask directly to the end of each dictionary word. Perfect for passwords like 'Password2024', 'Summer2023!', 'Admin123'."
					if not is_bg else
					"Добавя символи от зададената маска в края на всяка дума от речника. Идеален за пароли от типа 'Password2024', 'Admin123', 'Sofia!?'."
				),
				"required_inputs": (
					"• Target: Target hash\n• Wordlist: Plaintext dictionary\n• Mask: Added in Custom Flags as suffix mask (e.g. ?d?d?d?d for 4-digit years)"
					if not is_bg else
					"• Цел: Целеви хеш\n• Речник: Текстов файл с думи\n• Маска: Въвежда се като допълнителен параметър (напр. ?d?d?d?d за 4-цифрени години)"
				),
				"example_cli": "hashcat -a 6 -m {MODE} target.hash rockyou.txt ?d?d?d?d",
				"pro_tip": (
					"High-yield attack: Most humans use a dictionary word followed by numbers (1..4 digits) or an exclamation mark."
					if not is_bg else
					"Изключително висок процент на успех: огромна част от паролите са базова дума + 1 до 4 цифри или удивителен знак."
				)
			}
		7:
			return {
				"id": 7,
				"name": "7 | Hybrid Mask + Dict" if not is_bg else "7 | Хибрид: Маска + Речник (Prefix + Dict)",
				"short_desc": "Prepends a mask pattern to the beginning of dictionary words (prefix)." if not is_bg else "Добавя маска отпред (префикс) към думите от речника.",
				"mechanism": (
					"Prepends characters from a mask before each word from the dictionary (e.g., mask '?d?d' + 'Summer' = '01Summer')."
					if not is_bg else
					"Генерира префикс от маската и го слага пред всяка дума от речника (напр. маска '?d?d' + 'Password' = '23Password')."
				),
				"required_inputs": (
					"• Target: Target hash\n• Mask: Prefix mask string\n• Wordlist: Plaintext dictionary path"
					if not is_bg else
					"• Цел: Целеви хеш\n• Маска: Маска за префикс\n• Речник: Текстов файл с думи"
				),
				"example_cli": "hashcat -a 7 -m {MODE} target.hash ?d?d?d?d rockyou.txt",
				"pro_tip": (
					"Useful when targets prepend corporate codes, years, or symbols before common words."
					if not is_bg else
					"Подходящо за фирмени среди, където се изисква код на отдел или година отпред."
				)
			}
		_:
			return {
				"id": mode_id,
				"name": "Mode " + str(mode_id),
				"short_desc": "Standard Hashcat attack mode.",
				"mechanism": "Executes candidate generation based on specified mode.",
				"required_inputs": "Target hash + dictionary / mask.",
				"example_cli": "hashcat -a " + str(mode_id) + " -m {MODE} target.hash wordlist.txt",
				"pro_tip": "Refer to Hashcat documentation for advanced options."
			}

static func get_hash_mode_intel(mode_id: int, lang: String = "bg") -> Dictionary:
	var is_bg: bool = (lang == "bg")
	match mode_id:
		22000:
			return {
				"id": 22000,
				"name": "WPA-PBKDF2-PMKID+EAPOL (Modern Wi-Fi WPA/WPA2/WPA3)" if not is_bg else "WPA-PBKDF2-PMKID+EAPOL (Модерен Wi-Fi Handshake)",
				"category": "Wireless / Network Security",
				"description": (
					"The gold-standard modern Hashcat mode for 802.11 Wi-Fi network auditing. Combines both traditional 4-way EAPOL handshakes and clientless PMKID frames into a single unified format. Completely replaces legacy mode 2500."
					if not is_bg else
					"Златният съвременен стандарт за безжична Wi-Fi сигурност. Обединява както класически 4-way EAPOL handshakes, така и PMKID фреймове без нужда от свързан клиент. Напълно заменя остарелия режим 2500."
				),
				"expected_input_format": (
					"Text file (.hc22000 or .22000) containing lines formatted as: WPA*01*PMKID*AP_MAC*CLIENT_MAC*ESSID or WPA*02*EAPOL*..."
					if not is_bg else
					"Текстов файл (.hc22000 или .22000) с редове във формат: WPA*01*PMKID*AP_MAC*CLIENT_MAC*ESSID или WPA*02*MIC*..."
				),
				"how_to_capture": (
					"1. Capture with hcxdumptool: 'hcxdumptool -i wlan0 -w capture.pcapng --rds=1'\n" +
					"2. Convert to Hashcat format: 'hcxpcapngtool -o capture.hc22000 -E essidlist.txt capture.pcapng'"
					if not is_bg else
					"1. Запишете ефира с hcxdumptool: 'hcxdumptool -i wlan0 -w capture.pcapng --rds=1'\n" +
					"2. Конвертирайте до Hashcat формат: 'hcxpcapngtool -o capture.hc22000 -E essidlist.txt capture.pcapng'"
				),
				"speed_profile": "Slow / Compute Heavy (PBKDF2 with 4096 HMAC-SHA1 iterations per candidate)" if not is_bg else "Тежък / Бавен (PBKDF2 с 4096 HMAC-SHA1 итерации за всеки кандидат)",
				"flags_guide": (
					"• -O : Оптимизирани OpenCL ядра (пароли <= 32 символа, дава огромен прираст в скоростта!).\n" +
					"• -w 3 : Високо GPU натоварване (максимален hashrate).\n" +
					"• --nonce-error-corrections=8 : Поправя отклонения в таймера на рутера (AP clock drift) при 4-way handshakes.\n" +
					"• -d 1,2,3 : Използва само изчислителните видеокарти, оставяйки дисплейната свободна.\n" +
					"• -r rules/best64.rule : Мутира думите от речника с чести комбинации."
					if is_bg else
					"• -O : Optimized OpenCL/HIP kernels (passwords <= 32 chars, massive speedup!).\n" +
					"• -w 3 : High GPU workload profile.\n" +
					"• --nonce-error-corrections=8 : Fixes AP clock drift and missing frames.\n" +
					"• -d 1,2,3 : Targets compute cards only, preserving desktop display.\n" +
					"• -r rules/best64.rule : Wordlist candidate mutations."
				),
				"example_syntax": "hashcat -a 0 -m 22000 capture.hc22000 rockyou.txt -w 3 -O --nonce-error-corrections=8"
			}
		15700:
			return {
				"id": 15700,
				"name": "Ethereum Wallet, SCRYPT (Geth UTC JSON / MetaMask)" if not is_bg else "Ethereum Портфейл, SCRYPT (Geth UTC JSON / MetaMask)",
				"category": "Cryptocurrency Wallets",
				"description": (
					"Decrypts Ethereum private keys protected by memory-hard Scrypt key derivation (N=262144, r=8, p=1). " +
					"This is the standard format used by Geth, MyCrypto, MyEtherWallet, and MetaMask keystore JSON backups."
					if not is_bg else
					"Ключов режим за разбиване на криптирани Ethereum частни ключове (Geth / MetaMask). " +
					"Използва паметно-интензивната функция Scrypt (N=262144, r=8, p=1) за деривация на ключ от паролата."
				),
				"expected_input_format": (
					"Extracted string starting with: $ethereum$s*262144*8*1*<salt_hex>*<ciphertext_hex>*<mac_hex>"
					if not is_bg else
					"Хеш ред, извлечен от JSON файла: $ethereum$s*262144*8*1*<salt_hex>*<ciphertext_hex>*<mac_hex>"
				),
				"how_to_capture": (
					"Extract from your UTC--...json keystore file using ethereum2john:\n" +
					"python3 ethereum2john.py UTC--2021-... > eth_wallet.hash"
					if not is_bg else
					"Извлича се от файла UTC--...json чрез ethereum2john:\n" +
					"python3 ethereum2john.py UTC--2021-... > eth_wallet.hash"
				),
				"speed_profile": "Extremely Slow / Memory Bound (Scrypt N=262144 consumes significant GPU scratchpad memory)" if not is_bg else "Изключително бавен / Ограничен от паметта (Scrypt изисква голям VRAM буфер)",
				"flags_guide": (
					"• -w 3 : Високо натоварване за максимално паралелно изчисление.\n" +
					"• --scrypt-tmto=3 : Намалява VRAM консумацията на картата, за да предотврати грешки за памет (Alloc Error).\n" +
					"• ВНИМАНИЕ: Флагът -O НЕ се поддържа при Scrypt (не е съвместим с големия обем памет).\n" +
					"• -r rules/best64.rule : Прилага мутационни правила към вашия речник."
					if is_bg else
					"• -w 3 : High workload profile for compute scaling.\n" +
					"• --scrypt-tmto=3 : Lowers VRAM footprint to prevent out-of-memory errors on multiple cards.\n" +
					"• NOTE: -O is NOT supported for Scrypt (memory bound algorithm).\n" +
					"• -r rules/best64.rule : Mutation rules."
				),
				"example_syntax": "hashcat -a 0 -m 15700 eth_wallet.hash rockyou.txt -w 3 --scrypt-tmto=3"
			}
		15600:
			return {
				"id": 15600,
				"name": "Ethereum Wallet, PBKDF2-HMAC-SHA256" if not is_bg else "Ethereum Портфейл, PBKDF2-HMAC-SHA256",
				"category": "Cryptocurrency Wallets",
				"description": (
					"Ethereum keystore JSON files using PBKDF2-HMAC-SHA256 key derivation (262,144 iterations). " +
					"Used in earlier Geth implementations and custom wallet generators."
					if not is_bg else
					"Ethereum портфейли, използващи PBKDF2-HMAC-SHA256 с голям брой итерации (262144). " +
					"Среща се в по-ранни версии на Geth и алтернативни крипто генератори."
				),
				"expected_input_format": "$ethereum$p*262144*<salt_hex>*<ciphertext_hex>*<mac_hex>",
				"how_to_capture": "python3 ethereum2john.py keystore.json > eth_pbkdf2.hash",
				"speed_profile": "Slow (262,144 SHA256 rounds)" if not is_bg else "Бавен (262,144 SHA-256 итерации за кандидат)",
				"flags_guide": "• -w 3 : Високо натоварване.\n• -O : Оптимизирани ядра (ако паролата е до 32 знака).\n• -d 1,2,3 : Изчислителни GPU карти.",
				"example_syntax": "hashcat -a 0 -m 15600 eth_pbkdf2.hash rockyou.txt -w 3 -O"
			}
		16300:
			return {
				"id": 16300,
				"name": "Ethereum Pre-Sale Wallet" if not is_bg else "Ethereum Pre-Sale Портфейл (Genesis 2014)",
				"category": "Cryptocurrency Wallets",
				"description": (
					"The original Ethereum Genesis presale wallet format from 2014 (PBKDF2-HMAC-SHA256 with 2000 iterations and AES-128-CBC)."
					if not is_bg else
					"Оригиналният формат на Ethereum портфейлите от предварителната продажба през 2014 г. (Genesis ICO)."
				),
				"expected_input_format": "$ethereum$p*2000*<salt_hex>*<encseed_hex>*<mac_hex>",
				"how_to_capture": "python3 ethereum2john.py presale.json > presale.hash",
				"speed_profile": "Medium (2000 iterations)" if not is_bg else "Среден (2000 итерации)",
				"flags_guide": "• -w 3\n• -O : Оптимизирани ядра.\n• -r rules/best64.rule",
				"example_syntax": "hashcat -a 0 -m 16300 presale.hash rockyou.txt -w 3 -O"
			}
		17800:
			return {
				"id": 17800,
				"name": "Keccak-256 (EVM / Ethereum)" if not is_bg else "Keccak-256 (EVM / Смарт контракти)",
				"category": "Hashes & Checksums",
				"description": (
					"The core cryptographic hashing primitive used throughout the Ethereum Virtual Machine (EVM). " +
					"Widely used for reversing 4-byte smart contract function selectors (e.g. transfer(address,uint256)), event topics, and addresses."
					if not is_bg else
					"Основната криптографска хеш функция на Ethereum (EVM). " +
					"Използва се масово за възстановяване на 4-байтови сигнатури на смарт контракт функции (напр. transfer(address,uint256) -> 0xa9059cbb)."
				),
				"expected_input_format": "64-character hexadecimal string (e.g. 203f88777f18bb4ee122...)",
				"how_to_capture": "Extract function selector or hash from transaction bytecode or contract ABI.",
				"speed_profile": "Very Fast (Pure GPU compute, billions of H/s on modern rigs)" if not is_bg else "Много бърз (Чисто GPU изчисление, милиарди хеша в секунда)",
				"flags_guide": "• -O : Оптимизирани ядра (+50% скорост).\n• -w 3 : Висока производителност.\n• -a 3 : Brute-force за 4-байтови сигнатури.",
				"example_syntax": "hashcat -a 3 -m 17800 0xa9059cbb ?a?a?a?a?a?a?a?a -O -w 3"
			}
		0:
			return {
				"id": 0,
				"name": "MD5 (Message Digest 5)" if not is_bg else "MD5 Хеш сума (Message Digest 5)",
				"category": "Hashes & Checksums",
				"description": (
					"128-bit cryptographic hash function widely used in legacy systems, databases, and checksums. Extremely fast on GPU hardware (tens of GH/s per card)."
					if not is_bg else
					"128-битов алгоритъм, използван в уеб системи, бази данни и софтуерни суми. Изключително бърз за видеокарти (десетки гигахеша в секунда)."
				),
				"expected_input_format": "32-character hexadecimal string (e.g. 8743b73db798948206ecb610ce00148a)",
				"how_to_capture": "Extracted from database dumps, web apps, or shadow files.",
				"speed_profile": "Ultra Fast / Pure GPU Raw Speed" if not is_bg else "Ултра бърз / Максимална хардуерна мощност",
				"flags_guide": "• -O : Оптимизирани ядра (до +300% hashrate).\n• -w 3 : High Workload.\n• -r rules/best64.rule",
				"example_syntax": "hashcat -a 0 -m 0 target.hash rockyou.txt -O -w 3"
			}
		1000:
			return {
				"id": 1000,
				"name": "NTLM (Windows NT LAN Manager)" if not is_bg else "NTLM (Windows Active Directory / SAM)",
				"category": "Windows & Active Directory",
				"description": (
					"The primary password hash format in Microsoft Windows Active Directory and local SAM databases (MD4(UTF-16LE(password))). Very fast to audit on modern AMD/NVIDIA GPUs."
					if not is_bg else
					"Основният хеш формат за пароли в Microsoft Windows Active Directory и локални SAM бази. Много висока скорост на изчисление."
				),
				"expected_input_format": "32-character hexadecimal string (e.g. b4b9b02e6f09a9bd760f388b67351e2b)",
				"how_to_capture": "DUMP via secretsdump.py, Mimikatz, or Volume Shadow Copy (ntds.dit).",
				"speed_profile": "Very Fast / Raw Hardware" if not is_bg else "Много бърз / Оптимизиран за GPU",
				"flags_guide": "• -O : Оптимизирани ядра (огромно ускорение!).\n• -w 3 : Високо натоварване.\n• -r rules/best64.rule",
				"example_syntax": "hashcat -a 0 -m 1000 ntlm.hash rockyou.txt -r rules/best64.rule -O -w 3"
			}
		3200:
			return {
				"id": 3200,
				"name": "bcrypt $2a$, $2y$, $2b$" if not is_bg else "bcrypt (Blowfish-базиран уеб хеш)",
				"category": "Linux / Web Security",
				"description": (
					"Adaptive Blowfish-based password hashing algorithm widely used in web applications, OpenBSD, and security frameworks. High CPU/GPU memory cost with configurable rounds."
					if not is_bg else
					"Адаптивен хеш, базиран на Blowfish, с вградена сол и адаптивен брой рундове. Използва се масово в модерни уеб платформи."
				),
				"expected_input_format": "Starts with $2a$, $2b$, or $2y$ followed by cost factor (e.g. $2a$10$abcdef...)",
				"how_to_capture": "Extracted from application databases (Django, Node.js bcrypt, Ruby devise).",
				"speed_profile": "Extremely Slow / Memory Bound" if not is_bg else "Много бавен / Ограничен от паметта",
				"flags_guide": "• -w 3 : High Workload.\n• -d 1,2,3 : GPU изчисления.\n• ВНИМАНИЕ: -O не се поддържа за bcrypt.",
				"example_syntax": "hashcat -a 0 -m 3200 bcrypt.hash rockyou.txt -w 3"
			}
		1800:
			return {
				"id": 1800,
				"name": "sha512crypt $6$" if not is_bg else "sha512crypt $6$ (Linux /etc/shadow)",
				"category": "Linux / Unix",
				"description": (
					"The standard password hashing algorithm for Linux system users in /etc/shadow. Runs 5000 rounds of SHA-512 with salt."
					if not is_bg else
					"Стандартният хеш за системни потребители в Linux (/etc/shadow). Изпълнява 5000 рунда на SHA-512 с уникална сол."
				),
				"expected_input_format": "Starts with $6$ followed by salt and hash string (e.g. $6$rounds=5000$salt$hash...)",
				"how_to_capture": "Read from /etc/shadow on Linux hosts (requires root access).",
				"speed_profile": "Medium / Compute Bound (5000 SHA-512 iterations)" if not is_bg else "Среден / Интензивен (5000 итерации SHA-512)",
				"flags_guide": "• -w 3 : High Workload.\n• -O : Оптимизирани ядра.\n• -r rules/best64.rule",
				"example_syntax": "hashcat -a 0 -m 1800 shadow.hash rockyou.txt -w 3"
			}
		11600:
			return {
				"id": 11600,
				"name": "7-Zip Archive" if not is_bg else "7-Zip Криптиран архив",
				"category": "Archives & Encryption",
				"description": (
					"Encrypted 7-Zip archives protected with AES-256 and key derivation via PBKDF2-HMAC-SHA256 with high iteration counts (up to 2^19 rounds)."
					if not is_bg else
					"Криптирани архиви 7-Zip с AES-256 и ключово извличане през PBKDF2-HMAC-SHA256 с голям брой рундове (до 2^19)."
				),
				"expected_input_format": "Header extracted string starting with $7z$0$19$...",
				"how_to_capture": "Extract using 7z2hashcat.pl script on the target .7z file.",
				"speed_profile": "Slow (High iteration key derivation)" if not is_bg else "Бавен (Висок брой криптографски рундове)",
				"flags_guide": "• -w 3\n• -r rules/best64.rule\n• -d 1,2,3",
				"example_syntax": "hashcat -a 0 -m 11600 archive.7z.hash rockyou.txt -w 3"
			}
		12500:
			return {
				"id": 12500,
				"name": "RAR5 Archive" if not is_bg else "RAR5 Криптиран архив",
				"category": "Archives & Encryption",
				"description": (
					"Modern WinRAR v5+ encrypted archives using AES-256 and PBKDF2-HMAC-SHA256."
					if not is_bg else
					"Модерни криптирани WinRAR v5 архиви с AES-256 и PBKDF2-HMAC-SHA256."
				),
				"expected_input_format": "Starts with $rar5$...",
				"how_to_capture": "Extract from .rar file using rar2john or rar2hashcat.",
				"speed_profile": "Slow" if not is_bg else "Бавен",
				"flags_guide": "• -w 3\n• -r rules/best64.rule",
				"example_syntax": "hashcat -a 0 -m 12500 archive.rar.hash rockyou.txt -w 3"
			}
		_:
			return {
				"id": mode_id,
				"name": "Mode " + str(mode_id),
				"category": "General Hash",
				"description": "Standard Hashcat cryptographic target mode.",
				"expected_input_format": "Format defined by Hashcat specification.",
				"how_to_capture": "Extract from target system.",
				"speed_profile": "Depends on algorithm complexity.",
				"flags_guide": "• -w 3 : Workload\n• -O : Optimized Kernels (if supported)",
				"example_syntax": "hashcat -a 0 -m " + str(mode_id) + " target.hash wordlist.txt"
			}

static func build_full_intel_report(attack_mode_id: int, hash_mode_id: int, lang: String = "bg") -> Dictionary:
	var atk: Dictionary = get_attack_mode_intel(attack_mode_id, lang)
	var hsh: Dictionary = get_hash_mode_intel(hash_mode_id, lang)
	var is_bg: bool = (lang == "bg")

	var formatted_cli: String = atk.get("example_cli", "hashcat -a {A} -m {M} target wordlist").replace("{MODE}", str(hash_mode_id))

	var summary_text: String = ""
	if is_bg:
		summary_text += "[b][color=#00F0FF]⚡ РЕЖИМ НА АТАКАТА: [/color]" + atk.get("name", "") + "[/b]\n"
		summary_text += "[color=#E6EDF3]" + atk.get("short_desc", "") + "[/color]\n\n"
		summary_text += "[b][color=#00E5FF]🔍 КАК РАБОТИ ТАЗИ АТАКА: [/color][/b]\n"
		summary_text += "[color=#C9D1D9]" + atk.get("mechanism", "") + "[/color]\n\n"
		summary_text += "[b][color=#00FF66]📋 КАКВИ ВХОДНИ ДАННИ СЕ ИЗИСКВАТ: [/color][/b]\n"
		summary_text += "[color=#E6EDF3]" + atk.get("required_inputs", "") + "[/color]\n\n"
		summary_text += "[b][color=#FFD700]💡 ХАРАКТЕРИСТИКА НА АЛГОРИТЪМА (Режим " + str(hash_mode_id) + " | " + hsh.get("name", "") + "): [/color][/b]\n"
		summary_text += "[color=#C9D1D9]" + hsh.get("description", "") + "[/color]\n"
		summary_text += "[color=#8B949E]• Очакван формат: " + hsh.get("expected_input_format", "") + "[/color]\n"
		summary_text += "[color=#8B949E]• Как се извлича: " + hsh.get("how_to_capture", "") + "[/color]\n"
		summary_text += "[color=#8B949E]• Скоростен профил: " + hsh.get("speed_profile", "") + "[/color]\n\n"
		if hsh.has("flags_guide") and not str(hsh["flags_guide"]).is_empty():
			summary_text += "[b][color=#00E5FF]🛠️ ПРЕПОРЪЧИТЕЛНИ CLI ФЛАГОВЕ ЗА ТОЗИ РЕЖИМ: [/color][/b]\n"
			summary_text += "[color=#80CBC4]" + str(hsh["flags_guide"]) + "[/color]\n\n"
		summary_text += "[b][color=#00F0FF]💻 ПРИМЕРНА РЕАЛНА КОМАНДА ЗА ТАЗИ КОНФИГУРАЦИЯ: [/color][/b]\n"
		summary_text += "[bgcolor=#0B0E14][color=#00FF66] " + formatted_cli + " [/color][/bgcolor]\n\n"
		summary_text += "[b][color=#FF9100]🔥 СЪВЕТ ОТ ЕКСПЕРТ: [/color][/b]\n"
		summary_text += "[color=#E6EDF3]" + atk.get("pro_tip", "") + "[/color]"
	else:
		summary_text += "[b][color=#00F0FF]⚡ ATTACK MODE: [/color]" + atk.get("name", "") + "[/b]\n"
		summary_text += "[color=#E6EDF3]" + atk.get("short_desc", "") + "[/color]\n\n"
		summary_text += "[b][color=#00E5FF]🔍 HOW THIS ATTACK WORKS: [/color][/b]\n"
		summary_text += "[color=#C9D1D9]" + atk.get("mechanism", "") + "[/color]\n\n"
		summary_text += "[b][color=#00FF66]📋 REQUIRED INPUTS: [/color][/b]\n"
		summary_text += "[color=#E6EDF3]" + atk.get("required_inputs", "") + "[/color]\n\n"
		summary_text += "[b][color=#FFD700]💡 ALGORITHM PROFILE (Mode " + str(hash_mode_id) + " | " + hsh.get("name", "") + "): [/color][/b]\n"
		summary_text += "[color=#C9D1D9]" + hsh.get("description", "") + "[/color]\n"
		summary_text += "[color=#8B949E]• Expected Format: " + hsh.get("expected_input_format", "") + "[/color]\n"
		summary_text += "[color=#8B949E]• Extraction Guide: " + hsh.get("how_to_capture", "") + "[/color]\n"
		summary_text += "[color=#8B949E]• Speed Profile: " + hsh.get("speed_profile", "") + "[/color]\n\n"
		if hsh.has("flags_guide") and not str(hsh["flags_guide"]).is_empty():
			summary_text += "[b][color=#00E5FF]🛠️ RECOMMENDED CLI FLAGS: [/color][/b]\n"
			summary_text += "[color=#80CBC4]" + str(hsh["flags_guide"]) + "[/color]\n\n"
		summary_text += "[b][color=#00F0FF]💻 REAL-WORLD CLI COMMAND SYNTAX: [/color][/b]\n"
		summary_text += "[bgcolor=#0B0E14][color=#00FF66] " + formatted_cli + " [/color][/bgcolor]\n\n"
		summary_text += "[b][color=#FF9100]🔥 PRO-TIP: [/color][/b]\n"
		summary_text += "[color=#E6EDF3]" + atk.get("pro_tip", "") + "[/color]"

	return {
		"summary_bbcode": summary_text,
		"example_cli": formatted_cli,
		"attack": atk,
		"hash": hsh
	}
