extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame

	# 1. Test Header fixes
	var btn_setup = inst.get_node("VBox/Header/HBox/BtnViewSetup")
	var btn_cockpit = inst.get_node("VBox/Header/HBox/BtnViewCockpit")
	var btn_flags = inst.get_node("VBox/Header/HBox/BtnOpenFlagsGuide")
	var btn_lang = inst.get_node("VBox/Header/HBox/BtnLang")
	var btn_fs = inst.get_node("VBox/Header/HBox/BtnFullscreen")
	var btn_em = inst.get_node("VBox/Header/HBox/BtnEmergency")
	var title = inst.get_node("VBox/Header/HBox/Title")
	var status = inst.get_node("VBox/Header/HBox/StatusBadge")
	var telem = inst.get_node("VBox/Header/HBox/TelemetryBadge")

	btn_setup.text = "🛠️ Setup"
	btn_setup.clip_text = false
	btn_setup.custom_minimum_size = Vector2(80, 32)

	btn_cockpit.text = "🎛️ Cockpit"
	btn_cockpit.clip_text = false
	btn_cockpit.custom_minimum_size = Vector2(85, 32)

	btn_flags.text = "📖 Флагове"
	btn_flags.clip_text = false
	btn_flags.custom_minimum_size = Vector2(95, 32)

	btn_lang.text = "🌐 БГ"
	btn_lang.clip_text = false
	btn_lang.custom_minimum_size = Vector2(65, 32)

	btn_fs.text = "⛶ F11"
	btn_fs.clip_text = false
	btn_fs.custom_minimum_size = Vector2(65, 32)

	btn_em.text = "⚠️ СТОП"
	btn_em.clip_text = false
	btn_em.custom_minimum_size = Vector2(75, 32)

	title.custom_minimum_size = Vector2(180, 0)
	status.custom_minimum_size = Vector2(140, 0)
	telem.custom_minimum_size = Vector2(140, 0)

	# 2. Test Zone 1 fixes
	var btn_browse = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left/Scroll1/VBox/HashGroup/HBox/BtnBrowseHash")
	var btn_quick = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left/Scroll1/VBox/HashGroup/HBox/BtnQuickExample")
	btn_browse.text = "📁"
	btn_browse.clip_text = false
	btn_browse.custom_minimum_size = Vector2(38, 36)

	btn_quick.text = "💡"
	btn_quick.clip_text = false
	btn_quick.custom_minimum_size = Vector2(38, 36)

	await process_frame
	await process_frame

	print("=== PROTOTYPE HEADER AND BUTTON SIZES ===")
	print("Title size:", title.size)
	print("Status size:", status.size)
	print("Telem size:", telem.size)
	print("BtnViewSetup size:", btn_setup.size, " text:", btn_setup.text)
	print("BtnViewCockpit size:", btn_cockpit.size, " text:", btn_cockpit.text)
	print("BtnOpenFlagsGuide size:", btn_flags.size, " text:", btn_flags.text)
	print("BtnLang size:", btn_lang.size, " text:", btn_lang.text)
	print("BtnFullscreen size:", btn_fs.size, " text:", btn_fs.text)
	print("BtnEmergency size:", btn_em.size, " text:", btn_em.text)
	print("BtnBrowseHash size:", btn_browse.size, " text:", btn_browse.text)
	print("BtnQuickExample size:", btn_quick.size, " text:", btn_quick.text)

	quit(0)
