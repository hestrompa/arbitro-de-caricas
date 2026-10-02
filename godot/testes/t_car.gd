extends SceneTree
# Ecrã da carreira (atributos, escalões) para verificar que todas as letras aparecem.
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("carreira", null)
	for i in 20: await process_frame
	var sc = m.ui.find_children("*", "ScrollContainer", true, false)
	root.get_viewport().get_texture().get_image().save_png("/tmp/car0.png")
	for s in sc: s.scroll_vertical = 100000
	for i in 5: await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/car1.png")
	quit()
