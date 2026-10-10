extends SceneTree

func _init():
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	await process_frame
	
	var z1 = inst.get_node("VBox/WorkSplit/MainSplit/Zone1_Left")
	var z2 = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone2_Center")
	var z3 = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit/Zone3_Right")
	var cr_split = inst.get_node("VBox/WorkSplit/MainSplit/CenterRightSplit")
	var main_split = inst.get_node("VBox/WorkSplit/MainSplit")
	var bd = inst.get_node("VBox/WorkSplit/BottomDeck")
	var vbox = inst.get_node("VBox")
	var header = inst.get_node("VBox/Header")
	
	print("Header min_size: ", header.get_combined_minimum_size())
	print("Zone 1 min_size: ", z1.get_combined_minimum_size())
	print("Zone 2 min_size: ", z2.get_combined_minimum_size())
	print("Zone 3 min_size: ", z3.get_combined_minimum_size())
	print("CenterRightSplit min_size: ", cr_split.get_combined_minimum_size())
	print("MainSplit min_size: ", main_split.get_combined_minimum_size())
	print("BottomDeck min_size: ", bd.get_combined_minimum_size())
	print("VBox min_size: ", vbox.get_combined_minimum_size())
	
	quit(0)
