extends SceneTree
# Ecrã da carreira com a tabela do campeonato depois de 3 jornadas
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Carreira.PATH))
	m.car.new_career()
	for k in 3:
		var B: Dictionary = m.car.match_brief()
		var S := Partida.new(m.car.career_teams(B))
		m.car.setup_match(S)
		S.score = [randi() % 3, randi() % 3]
		m.car.after(S, 7.0, "fim")
	m.on_ui("carreira", null)
	for i in 20: await process_frame
	var sc = m.ui.find_children("*", "ScrollContainer", true, false)
	var o := OS.get_environment("OUT")
	for k in 3:
		for s in sc: s.scroll_vertical = k * 520
		for i in 5: await process_frame
		root.get_viewport().get_texture().get_image().save_png(o + "/car%d.png" % k)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Carreira.PATH))
	quit()
