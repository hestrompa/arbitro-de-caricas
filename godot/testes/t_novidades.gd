extends SceneTree
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/shots/motor/"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 20: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "menu.png")
	m.on_ui("novidades", null)
	for i in 20: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "novidades.png")
	m.on_ui("menu", null)
	for i in 5: await process_frame
	print("ok ", m.modo)
	quit()
