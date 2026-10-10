extends SceneTree

func _init():
	print("Project stretch mode:", ProjectSettings.get_setting("display/window/stretch/mode"))
	print("Project stretch aspect:", ProjectSettings.get_setting("display/window/stretch/aspect"))
	print("Project stretch scale_mode:", ProjectSettings.get_setting("display/window/stretch/scale_mode"))
	quit(0)
