extends SceneTree

func _init():
	print("Testing stretch modes...")
	ProjectSettings.set_setting("display/window/stretch/mode", "disabled")
	ProjectSettings.set_setting("display/window/stretch/aspect", "ignore")
	
	var scene = load("res://scenes/main.tscn")
	var inst = scene.instantiate()
	root.add_child(inst)
	await process_frame
	
	print("Instantiate success with disabled stretch!")
	quit(0)
