extends SceneTree

func _init():
	var vsplit = VSplitContainer.new()
	vsplit.size = Vector2(1000, 1000)
	var c1 = Control.new()
	c1.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var c2 = Control.new()
	c2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vsplit.add_child(c1)
	vsplit.add_child(c2)
	root.add_child(vsplit)
	
	vsplit.split_offset = 0
	await process_frame
	print("offset 0: c1=", c1.size.y, " c2=", c2.size.y)
	
	vsplit.split_offset = 200
	await process_frame
	print("offset +200: c1=", c1.size.y, " c2=", c2.size.y)
	
	vsplit.split_offset = -200
	await process_frame
	print("offset -200: c1=", c1.size.y, " c2=", c2.size.y)
	
	quit(0)
