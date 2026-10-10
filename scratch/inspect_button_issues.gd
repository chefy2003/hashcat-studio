extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame

	print("=== CURRENT SIZES BEFORE ICON/LABEL COMPACT FIX ===")
	var btn_setup = inst.get_node("VBox/Header/HBox/BtnViewSetup")
	var btn_cockpit = inst.get_node("VBox/Header/HBox/BtnViewCockpit")
	var btn_flags = inst.get_node("VBox/Header/HBox/BtnOpenFlagsGuide")
	var btn_lang = inst.get_node("VBox/Header/HBox/BtnLang")
	var btn_fs = inst.get_node("VBox/Header/HBox/BtnFullscreen")
	var btn_em = inst.get_node("VBox/Header/HBox/BtnEmergency")

	print("BtnViewSetup size:", btn_setup.size)
	print("BtnViewCockpit size:", btn_cockpit.size)
	print("BtnOpenFlagsGuide size:", btn_flags.size)
	print("BtnLang size:", btn_lang.size)
	print("BtnFullscreen size:", btn_fs.size)
	print("BtnEmergency size:", btn_em.size)

	var btn_browse_hash = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left/Scroll1/VBox/HashGroup/HBox/BtnBrowseHash")
	var btn_quick_ex = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left/Scroll1/VBox/HashGroup/HBox/BtnQuickExample")
	print("BtnBrowseHash size:", btn_browse_hash.size, " text:", btn_browse_hash.text)
	print("BtnQuickExample size:", btn_quick_ex.size, " text:", btn_quick_ex.text)

	quit(0)
