class_name FlagDatabase
extends RefCounted

## Exhaustive Knowledge Base & Catalog of Hashcat Command Line Flags and Options.
## Provides categorized entries with plain-language Bulgarian and English explanations,
## parameter types, hardware impact warnings, and copy-paste ready practical examples.

static func get_categories(lang: String = "bg") -> Array[Dictionary]:
	var is_bg: bool = (lang == "bg")
	return [
		{"id": "all", "name": "Всички категории (Всички опции)" if is_bg else "All Categories (All Flags)"},
		{"id": "modes", "name": "1. Режими и алгоритми (-m, -a...)" if is_bg else "1. Modes & Algorithms (-m, -a...)"},
		{"id": "hardware", "name": "2. Хардуер и производителност (-w, -O, -d...)" if is_bg else "2. Hardware & Performance (-w, -O, -d...)"},
		{"id": "thermal", "name": "3. Температура, защита и статус (--hwmon...)" if is_bg else "3. Thermals, Safety & Status (--hwmon...)"},
		{"id": "rules", "name": "4. Речници, правила и мутации (-r, -j, -k...)" if is_bg else "4. Wordlists, Rules & Mutations (-r, -j, -k...)"},
		{"id": "masks", "name": "5. Маски и символни набори (-1..-8, -i...)" if is_bg else "5. Masks & Charsets (-1..-8, -i...)"},
		{"id": "wireless", "name": "6. Безжични мрежи Wi-Fi 22000 (--nonce...)" if is_bg else "6. Wireless Wi-Fi 22000 (--nonce...)"},
		{"id": "crypto", "name": "7. Криптовалути и памет (--scrypt-tmto...)" if is_bg else "7. Crypto Wallets & Scrypt (--scrypt-tmto...)"},
		{"id": "sessions", "name": "8. Сесии, файлове и Potfile (--session, -o...)" if is_bg else "8. Sessions, Files & Potfile (--session, -o...)"},
		{"id": "brain", "name": "9. Brain Server и клъстери (-z, -S...)" if is_bg else "9. Brain Server & Clusters (-z, -S...)"},
		{"id": "debug", "name": "10. Дебъг и вътрешни настройки (--debug...)" if is_bg else "10. Debug & Internals (--debug...)"}
	]

static func get_all_flags(lang: String = "bg") -> Array[Dictionary]:
	var is_bg: bool = (lang == "bg")
	var flags: Array[Dictionary] = [
		# 1. Modes & Algorithms
		{
			"flag": "-m, --hash-type",
			"cat_id": "modes",
			"type": "Num",
			"example": "-m 22000",
			"title": "Хеш алгоритъм / Режим" if is_bg else "Hash Algorithm Mode",
			"desc": (
				"Указва на Hashcat кой точно криптографски алгоритъм да изпълняват изчислителните ядра на видеокартата. " +
				"Ако не е посочен, Hashcat се опитва да го познае автоматично (autodetect). " +
				"Поддържа над 400 режима: -m 22000 (WPA2/WPA3 Wi-Fi), -m 1000 (NTLM), -m 0 (MD5), -m 15700 (Ethereum Scrypt), -m 3200 (Bcrypt)."
				if is_bg else
				"Specifies the cryptographic hash algorithm for GPU compute kernels to execute. " +
				"If omitted, Hashcat attempts autodetect. Supports over 400 modes."
			)
		},
		{
			"flag": "-a, --attack-mode",
			"cat_id": "modes",
			"type": "Num",
			"example": "-a 0",
			"title": "Режим на атаката" if is_bg else "Attack Mode Strategy",
			"desc": (
				"Определя стратегията за генериране на кандидати за пароли:\n" +
				"• 0 (Straight): Чете речник ред по ред (+ опционални мутационни правила).\n" +
				"• 1 (Combination): Залепя думи от два речника (Cartesian product: дума1 + дума2).\n" +
				"• 3 (Brute-force / Mask): Хардуерен синтез на кандидати директно във VRAM по маска (?d, ?l, ?u, ?s, ?a).\n" +
				"• 6 (Hybrid Dict + Mask): Дума от речник + маска като суфикс накрая (напр. Sofia?d?d?d?d).\n" +
				"• 7 (Hybrid Mask + Dict): Маска като префикс отпред + дума от речник (напр. ?d?d?d?dSofia)."
				if is_bg else
				"Defines the candidate generation strategy: 0=Straight Wordlist, 1=Combination, 3=Mask/Brute-force, 6=Wordlist+Mask, 7=Mask+Wordlist."
			)
		},
		{
			"flag": "-h, --help / -hh",
			"cat_id": "modes",
			"type": "None",
			"example": "-hh",
			"title": "Помощ и списък с всички поддържани алгоритми" if is_bg else "Help & Full Hash Modes List",
			"desc": (
				"Извежда помощния екран. Флагът -h показва базовите опции, а -hh извежда пълния списък с всички стотици поддържани хеш режими и техните номера."
				if is_bg else
				"Displays help. Use -hh to print all supported hash modes and their IDs."
			)
		},
		{
			"flag": "-H, --hash-info / --example-hashes",
			"cat_id": "modes",
			"type": "None",
			"example": "-H -m 22000",
			"title": "Техническа информация и примерен хеш за режим" if is_bg else "Hash Info & Test Vector",
			"desc": (
				"Показва подробна криптографска справка за посочения режим (-m): формат на хеша, примерна парола, тестови хеш, бенчмарк маска и дали е бавен/бърз."
				if is_bg else
				"Displays detailed technical info and test vector for the selected hash mode."
			)
		},
		{
			"flag": "--identify",
			"cat_id": "modes",
			"type": "File",
			"example": "--identify my.hash",
			"title": "Автоматично разпознаване на алгоритъма от файл" if is_bg else "Auto-Identify Hash Algorithm",
			"desc": (
				"Анализира подадения файл с хеш и показва всички възможни съвпадащи Hashcat алгоритми с процент на съответствие."
				if is_bg else
				"Analyzes input hash file and lists all supported matching algorithms."
			)
		},

		# 2. Hardware & Performance
		{
			"flag": "-w, --workload-profile",
			"cat_id": "hardware",
			"type": "Num",
			"example": "-w 3",
			"title": "Профил на изчислително натоварване (1..4)" if is_bg else "Workload Profile (1..4)",
			"desc": (
				"Контролира продължителността на един изчислителен цикъл върху GPU ядрото и баланса между скорост и GUI отзивчивост:\n" +
				"• -w 1 (Low / 2 ms): Икономичен. Екранът не замръзва, идеален при ползване на компютъра за работа/видео.\n" +
				"• -w 2 (Default / 12 ms): Балансиран режим за ежедневна употреба.\n" +
				"• -w 3 (High / 96 ms): Препоръчителен за ферми и максимална скорост. Графичният десктоп може леко да лагва, ако дисплеят е на същата карта.\n" +
				"• -w 4 (Nightmare / 480 ms): Максимална екстремна мощност. Предназначен само за чисти сървъри без монитор (Headless)."
				if is_bg else
				"Controls GPU kernel runtime step size. 1=Low (desktop friendly), 2=Default, 3=High (rig recommended), 4=Nightmare (pure headless)."
			)
		},
		{
			"flag": "-O, --optimized-kernel-enable",
			"cat_id": "hardware",
			"type": "None",
			"example": "-O",
			"title": "Оптимизирани хардуерни ядра (Boost +20% до +300%)" if is_bg else "Optimized GPU Kernels",
			"desc": (
				"Включва силно оптимизирани GPU ядра. Ограничава максималната дължина на паролата (до 32 символа), " +
				"за да побере всички междинни състояния в свръхбързите хардуерни регистри на чипа. " +
				"Дава драстичен прираст в hashrate при NTLM, MD5, SHA1 и WPA2!"
				if is_bg else
				"Enables optimized kernels by limiting password length (typically <= 32 chars). Yields massive speedup on NTLM, MD5, WPA2."
			)
		},
		{
			"flag": "-d, --backend-devices",
			"cat_id": "hardware",
			"type": "Str",
			"example": "-d 1,2,3",
			"title": "Избор на активни видеокарти (Устройства)" if is_bg else "Select Compute Backend Devices",
			"desc": (
				"Задава списък с номера на физическите устройства, които да извършват изчисленията. " +
				"Изключително полезно за оставяне на дисплейната карта (напр. RX 480) свободна за десктопа, " +
				"докато изчислителните карти (напр. Instinct MI25 #1, #2, #3) работят на 100%."
				if is_bg else
				"Comma-separated list of OpenCL/HIP devices to use. Essential to isolate desktop display GPUs from heavy compute cards."
			)
		},
		{
			"flag": "-D, --opencl-device-types",
			"cat_id": "hardware",
			"type": "Str",
			"example": "-D 2",
			"title": "Филтър по тип устройство (1=CPU, 2=GPU, 3=FPGA)" if is_bg else "OpenCL Device Type Filter",
			"desc": (
				"Ограничава изчисленията само до конкретен тип хардуер. Използвайте '-D 2', за да сте сигурни, че се ползват само видеокарти и процесорът няма да се товари."
				if is_bg else
				"Restricts devices by type (1=CPU, 2=GPU, 3=FPGA/DSP). Use '-D 2' to strictly target GPUs."
			)
		},
		{
			"flag": "-n, --kernel-accel",
			"cat_id": "hardware",
			"type": "Num",
			"example": "-n 64",
			"title": "Ръчно ядро ускорение (Външен цикъл)" if is_bg else "Manual Kernel Acceleration Step Size",
			"desc": (
				"Ръчна фина настройка за брой нишки на външния цикъл на OpenCL/HIP ядрата. Препоръчва се само за напреднали оператори."
				if is_bg else
				"Manual workload tuning: sets outer loop step size."
			)
		},
		{
			"flag": "-u, --kernel-loops",
			"cat_id": "hardware",
			"type": "Num",
			"example": "-u 256",
			"title": "Вътрешен цикъл на ядрото (Innerloop)" if is_bg else "Manual Kernel Loops Step Size",
			"desc": (
				"Определя броя итерации, които ядрото прави във вътрешния си цикъл преди да докладва обратно на драйвера."
				if is_bg else
				"Manual workload tuning: sets inner loop step size."
			)
		},
		{
			"flag": "--backend-devices-keepfree",
			"cat_id": "hardware",
			"type": "Num",
			"example": "--backend-devices-keepfree=5",
			"title": "Запазване на свободна видеопамет (% VRAM)" if is_bg else "Keep Percentage of Device Memory Free",
			"desc": (
				"Задава какъв процент от паметта на видеокартата да остане свободна, за да не се допуска забиване на графичния драйвер или дисплей сървъра."
				if is_bg else
				"Leaves a percentage of device VRAM free to prevent driver crashes and out-of-memory errors."
			)
		},

		# 3. Thermals & Safety
		{
			"flag": "--hwmon-temp-abort",
			"cat_id": "thermal",
			"type": "Num",
			"example": "--hwmon-temp-abort=90",
			"title": "Аварийно температурно изключване (°C)" if is_bg else "Emergency Thermal Shutdown (°C)",
			"desc": (
				"КРИТИЧЕН ФЛАГ ЗА СИГУРНОСТ: Ако температурата на която и да е видеокарта достигне посочената стойност (напр. 90°C), " +
				"Hashcat незабавно прекратява атаката, спасявайки хардуера от термичен шок или прегряване."
				if is_bg else
				"Critical hardware safety flag: terminates Hashcat immediately if any GPU reaches the target temperature threshold."
			)
		},
		{
			"flag": "--hwmon-disable",
			"cat_id": "thermal",
			"type": "None",
			"example": "--hwmon-disable",
			"title": "Изключване на хардуерния мониторинг" if is_bg else "Disable Hardware Temperature Reads",
			"desc": (
				"Спира четенето на температури и обороти на вентилаторите. Ползва се при виртуални машини или стари драйвери, които зависват при запитване на сензорите."
				if is_bg else
				"Disables sensor reading. Useful on VMs or buggy drivers that hang on hwmon queries."
			)
		},
		{
			"flag": "--status-timer",
			"cat_id": "thermal",
			"type": "Num",
			"example": "--status-timer=1",
			"title": "Период на обновяване на телеметрията (секунди)" if is_bg else "Telemetry Heartbeat Interval (Seconds)",
			"desc": (
				"Задава през колко секунди Hashcat да опреснява статуса, температурата и моментния hashrate (напр. всяка 1 секунда за жив графичен дисплей)."
				if is_bg else
				"Interval in seconds between telemetry and hashrate status updates."
			)
		},
		{
			"flag": "--spin-damp",
			"cat_id": "thermal",
			"type": "Num",
			"example": "--spin-damp=10",
			"title": "Намаляване на натоварването на процесора (CPU Damp %)" if is_bg else "CPU Device Synchronization Dampening (%)",
			"desc": (
				"Намалява активното въртене на CPU нишките при синхронизация с видеокартите, спестявайки процесорно време и топлина."
				if is_bg else
				"Uses CPU sleep cycles for device synchronization to lower CPU heat and utilization."
			)
		},

		# 4. Wordlists, Rules & Mutations
		{
			"flag": "-r, --rules-file",
			"cat_id": "rules",
			"type": "File",
			"example": "-r rules/best64.rule",
			"title": "Таблица с правила за мутация на речника" if is_bg else "Rule-based Mutation Table",
			"desc": (
				"Прилага серия от мутации върху всяка дума от речника (напр. първа главна буква, добавяне на '123' накрая, замяна на 'a' с '@', огледално обръщане). " +
				"Увеличава шанса за успех в пъти без нужда от гигантски речници."
				if is_bg else
				"Applies transformation rules to wordlist candidates (capitalization, leet-speak, suffix digits, reversing)."
			)
		},
		{
			"flag": "-j, --rule-left",
			"cat_id": "rules",
			"type": "Rule",
			"example": "-j 'c'",
			"title": "Единично бързо правило за левия речник" if is_bg else "Single In-line Rule for Left Wordlist",
			"desc": (
				"Прилага едно конкретно правило за всяка дума в движение. Пример: -j 'c' автоматично прави първата буква главна (admin -> Admin)."
				if is_bg else
				"Single mutation rule applied on-the-fly to each candidate from left wordlist (e.g. -j 'c' for capitalize)."
			)
		},
		{
			"flag": "-k, --rule-right",
			"cat_id": "rules",
			"type": "Rule",
			"example": "-k '$!'",
			"title": "Единично правило за десния речник (Комбинация)" if is_bg else "Single Rule for Right Wordlist",
			"desc": (
				"При комбинационна атака (-a 1) прилага правило върху десния речник. Пример: -k '$!' добавя удивителен знак накрая."
				if is_bg else
				"In combination attack (-a 1), applies an in-line rule to the right dictionary word (e.g. -k '$!' appends '!')."
			)
		},
		{
			"flag": "-s, --skip",
			"cat_id": "rules",
			"type": "Num",
			"example": "-s 10000000",
			"title": "Прескачане на първите X думи от речника" if is_bg else "Skip First X Candidates",
			"desc": (
				"Пропуска посочения брой думи от началото на речника. Използва се при разпределяне на работа между различни машини или при възобновяване."
				if is_bg else
				"Skips the first X words from wordlist/keyspace. Useful for manual job splitting between rigs."
			)
		},
		{
			"flag": "-l, --limit",
			"cat_id": "rules",
			"type": "Num",
			"example": "-l 5000000",
			"title": "Ограничаване на атаката до X думи" if is_bg else "Limit Attack to X Candidates",
			"desc": (
				"Тества само посочения брой думи и след това спира работа. Позволява тестване на къси отрязъци от големи речници."
				if is_bg else
				"Limits attack candidate count to X words from the start (or after -s skip)."
			)
		},
		{
			"flag": "-g, --generate-rules",
			"cat_id": "rules",
			"type": "Num",
			"example": "-g 10000",
			"title": "Генериране на X случайни правила (Random Rules)" if is_bg else "Generate X Random Mutation Rules",
			"desc": (
				"Hashcat автоматично синтезира X на брой произволни нови правила в движение за изпробване на неочаквани комбинации."
				if is_bg else
				"Generates X random rule mutations on the fly for exploratory password cracking."
			)
		},

		# 5. Masks & Charsets
		{
			"flag": "-1, -2, -3, -4",
			"cat_id": "masks",
			"type": "Str",
			"example": "-1 ?l?d -2 ?u?s",
			"title": "Потребителски символен набор (Custom Charset)" if is_bg else "User-Defined Custom Charset",
			"desc": (
				"Дефинира собствен набор от позволени символи, който след това се използва в маската като ?1, ?2 и т.н.\n" +
				"Пример: -1 ?l?d дефинира ?1 като само малки букви и цифри (a-z0-9). Маска: ?1?1?1?1?1?1?1?1."
				if is_bg else
				"Defines custom character set variable ?1..?4. Example: '-1 ?l?d' contains only lowercase letters and digits."
			)
		},
		{
			"flag": "-i, --increment",
			"cat_id": "masks",
			"type": "None",
			"example": "-i --increment-min 6 --increment-max 8",
			"title": "Инкрементен режим (Постепенно удължаване)" if is_bg else "Mask Increment Mode (Gradual Length)",
			"desc": (
				"Вместо да тества само фиксирана дължина, започва от минимална дължина (--increment-min) и постепенно увеличава символите до максимума (--increment-max). " +
				"Пример: тества първо 6-цифрени, после 7-цифрени, накрая 8-цифрени PIN кодове."
				if is_bg else
				"Incrementally increases mask length from --increment-min to --increment-max instead of only testing fixed length."
			)
		},
		{
			"flag": "--increment-min / --increment-max",
			"cat_id": "masks",
			"type": "Num",
			"example": "--increment-min=8 --increment-max=12",
			"title": "Минимална и максимална дължина при инкремент" if is_bg else "Increment Range Bounds",
			"desc": (
				"Задава границите на дължината при включен флаг -i (--increment)."
				if is_bg else
				"Specifies lower and upper bounds for increment mode."
			)
		},

		# 6. Wireless Wi-Fi 22000
		{
			"flag": "--nonce-error-corrections",
			"cat_id": "wireless",
			"type": "Num",
			"example": "--nonce-error-corrections=8",
			"title": "Корекция на часовниково отклонение на AP (Wi-Fi Nonce)" if is_bg else "AP Nonce Clock Skew Correction",
			"desc": (
				"ФУНДАМЕНТАЛЕН ФЛАГ ЗА WPA HANDSHAKES: При 4-way EAPOL handshakes, ако рутерът (AP) има разминаване в таймера, " +
				"изпуснат фрейм или нестандартен брояч, Hashcat коригира последните байтове на Nonce-а, " +
				"за да се разбие handshake, който иначе би бил обявен за счупен или невалиден!"
				if is_bg else
				"Corrects clock drift and frame drop discrepancies in Access Point nonces during 4-way handshakes."
			)
		},
		{
			"flag": "--hccapx-message-pair",
			"cat_id": "wireless",
			"type": "Num",
			"example": "--hccapx-message-pair=2",
			"title": "Филтър по тип на EAPOL двойката (0, 1, 2, 3)" if is_bg else "EAPOL Message Pair Filter",
			"desc": (
				"Филтрира само съобщенията от двойка M1+M2 или M2+M3 в handshake записа, за да избегне подправени deauth пакети."
				if is_bg else
				"Loads only message pairs matching the specified EAPOL structure."
			)
		},

		# 7. Crypto Wallets & Scrypt
		{
			"flag": "--scrypt-tmto",
			"cat_id": "crypto",
			"type": "Num",
			"example": "--scrypt-tmto=3",
			"title": "Time-Memory Trade-Off за Scrypt (Ethereum Mode 15700)" if is_bg else "Scrypt Time-Memory Trade-Off",
			"desc": (
				"КЛЮЧОВ ЗА ETHEREUM GETH KEYSTORES: Scrypt е паметно-интензивен алгоритъм (N=262144, r=8). " +
				"Този флаг намалява обема на изискваната VRAM за сметка на леко увеличение на преизчисленията, " +
				"предотвратявайки грешки за липса на памет (Out of Memory / Alloc Error) при работа с няколко видеокарти."
				if is_bg else
				"Essential for Ethereum Scrypt keystores: trades VRAM usage for compute steps to avoid Out-of-Memory crashes."
			)
		},

		# 8. Sessions, Files & Potfile
		{
			"flag": "--session",
			"cat_id": "sessions",
			"type": "Str",
			"example": "--session=wpa_target1",
			"title": "Име на сесията за запазване на прогреса" if is_bg else "Named Session for Checkpointing",
			"desc": (
				"Задава уникално име на сесията. Позволява спиране на Hashcat и последващо продължаване от същата секунда чрез флага --restore."
				if is_bg else
				"Defines a named session. Allows stopping and resuming jobs exactly where they left off via --restore."
			)
		},
		{
			"flag": "--restore",
			"cat_id": "sessions",
			"type": "None",
			"example": "--restore --session=wpa_target1",
			"title": "Възобновяване на прекъсната сесия" if is_bg else "Restore Interrupted Session",
			"desc": (
				"Продължава изпълнението на сесия, която е била спряна с Ctrl+C, аварийно прекратена или рестартирана."
				if is_bg else
				"Resumes an interrupted attack session using its saved restore file."
			)
		},
		{
			"flag": "-o, --outfile",
			"cat_id": "sessions",
			"type": "File",
			"example": "-o /path/to/cracked.txt",
			"title": "Файл за запис на разбитите пароли" if is_bg else "Outfile for Recovered Passwords",
			"desc": (
				"Записва намерените пароли в посочения текстов файл веднага щом бъдат намерени."
				if is_bg else
				"Writes recovered plaintexts to the specified text file."
			)
		},
		{
			"flag": "--potfile-disable",
			"cat_id": "sessions",
			"type": "None",
			"example": "--potfile-disable",
			"title": "Изключване на глобалния Potfile" if is_bg else "Disable Global Potfile Cache",
			"desc": (
				"По подразбиране Hashcat помни вече разбити пароли в ~/.local/share/hashcat/hashcat.potfile. " +
				"Този флаг кара Hashcat да тества хеша отново, дори ако вече е бил разбиван в миналото."
				if is_bg else
				"Prevents Hashcat from checking or writing to the potfile cache, forcing a clean re-test."
			)
		},
		{
			"flag": "--remove",
			"cat_id": "sessions",
			"type": "None",
			"example": "--remove",
			"title": "Премахване на разбитите хешове от входния файл" if is_bg else "Remove Cracked Hashes From Input File",
			"desc": (
				"Когато се атакува списък от много хешове, Hashcat автоматично изтрива намерените от оригиналния файл, " +
				"оставяйки вътре само неразбитите."
				if is_bg else
				"Automatically removes cracked hashes from the target hashfile, leaving only pending targets."
			)
		},

		# 9. Brain Server & Clusters
		{
			"flag": "-S, --slow-candidates",
			"cat_id": "brain",
			"type": "None",
			"example": "-S",
			"title": "Бавен кандидат генератор (Офлоуд на тежки правила)" if is_bg else "Slow Candidate Generator Engine",
			"desc": (
				"Прехвърля генерирането на кандидати към по-бавен, но изключително прецизен режим, предотвратяващ глад на GPU от бавен процесор."
				if is_bg else
				"Enables candidate generator optimizations for complex rules or network brain clients."
			)
		},
		{
			"flag": "-z, --brain-client",
			"cat_id": "brain",
			"type": "None",
			"example": "-z --brain-host=192.168.1.50 --brain-port=13743 --brain-password=secret",
			"title": "Включване на Brain Client (Мрежова дедупликация)" if is_bg else "Connect as Hashcat Brain Client",
			"desc": (
				"Свързва машината към централен Hashcat Brain сървър в мрежата. " +
				"Гарантира, че ако друга машина в клъстера вече е тествала дадена парола или позиция, " +
				"вашите карти НЯМА да я смятат повторно!"
				if is_bg else
				"Connects to a centralized Hashcat Brain Server to avoid redundant candidate testing across multiple rigs."
			)
		},

		# 10. Debug & Internals
		{
			"flag": "--stdout",
			"cat_id": "debug",
			"type": "None",
			"example": "--stdout -a 3 ?d?d?d?d",
			"title": "Извеждане на думите в конзолата без атака" if is_bg else "Print Generated Candidates to Stdout Only",
			"desc": (
				"Не изпълнява никаква атака върху хешове, а само отпечатва генерираните думи на екрана. Идеално за тестване на правила и маски."
				if is_bg else
				"Does not crack hashes; simply outputs generated word candidates to stdout for inspection."
			)
		},
		{
			"flag": "--debug-mode",
			"cat_id": "debug",
			"type": "Num",
			"example": "--debug-mode=4 --debug-file=rules.log",
			"title": "Дебъг на правила (Запис кое правило е намерило паролата)" if is_bg else "Rule Debugging Mode",
			"desc": (
				"Записва в лог файл точно кое конкретно правило от таблицата с правила е довело до успешното разбиване на паролата."
				if is_bg else
				"Logs exactly which mutation rule successfully found the password."
			)
		}
	]
	return flags

static func get_flags_by_category(cat_id: String, lang: String = "bg") -> Array[Dictionary]:
	var all_items: Array[Dictionary] = get_all_flags(lang)
	if cat_id == "all" or cat_id.is_empty():
		return all_items
	
	var filtered: Array[Dictionary] = []
	for f in all_items:
		if f.get("cat_id", "") == cat_id:
			filtered.append(f)
	return filtered

static func search_flags(query: String, lang: String = "bg") -> Array[Dictionary]:
	var q: String = query.strip_edges().to_lower()
	var all_items: Array[Dictionary] = get_all_flags(lang)
	if q.is_empty():
		return all_items
	
	var results: Array[Dictionary] = []
	for f in all_items:
		var flag_str: String = f.get("flag", "").to_lower()
		var title_str: String = f.get("title", "").to_lower()
		var desc_str: String = f.get("desc", "").to_lower()
		var ex_str: String = f.get("example", "").to_lower()
		
		if q in flag_str or q in title_str or q in desc_str or q in ex_str:
			results.append(f)
	return results
