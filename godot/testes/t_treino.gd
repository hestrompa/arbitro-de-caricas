extends SceneTree
# treino entre jogos: sessão de vídeo (decide sempre a verdade, menos uma) e teste físico com toques a tempo
var m
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Carreira.PATH))
	m.on_ui("carreira", null)
	for i in 5: await process_frame
	var o := OS.get_environment("OUT")
	m.on_ui("treino_video", null)
	var k := 0
	var tt := Time.get_ticks_msec()
	while m.modo != "fim" and Time.get_ticks_msec() - tt < 240000:
		if m.modo == "gesto": m._end_gesture()
		if m.modo == "lance" and m.dec_shown:
			k += 1
			if k == 1: root.get_viewport().get_texture().get_image().save_png(o + "/video_lance.png")
			m._decide(m.L.truth if k != 3 else ("siga" if m.L.truth != "siga" else "falta"))
		if m.jogo.mode == "pergunta": m.on_ui("ask", 0)
		if Engine.get_process_frames() % 120 == 0: print("  modo ", m.modo, " jogo ", m.jogo.mode, " n ", m.jogo.training.get("n", -1), " dec ", m.dec_shown, " L ", m.L.get("kind", ""), " var_done ", m.L.get("var_done", false))
		await process_frame
	for i in 10: await process_frame
	print("vídeo: decisões ", k, "  nota: ", m.car.C.get("treino_txt", ""))
	root.get_viewport().get_texture().get_image().save_png(o + "/video_fim.png")
	# o teste físico só se pode fazer uma vez por jornada: apaga a marca para testar
	m.car.C.erase("treino_k")
	m.on_ui("treino_fisico", null)
	for i in 5: await process_frame
	var tf: TesteFisico = m.ui.root.get_children().filter(func(c): return c is TesteFisico)[0]
	tf._carrega()
	var feitos := 0
	while tf.estado != "fim":
		if tf.estado == "corre" and tf.t >= tf.dur - 0.03:
			# acerta os primeiros 9 percursos, depois deixa passar
			if feitos < 9: tf._carrega(); feitos += 1
		if feitos == 3 and tf.estado == "corre" and tf.t > tf.dur * 0.5: root.get_viewport().get_texture().get_image().save_png(o + "/yoyo.png")
		await process_frame
	for i in 120: await process_frame
	print("físico: ", m.car.C.get("treino_txt", ""), "  xp ", m.car.C.get("xp", {}), " attrs ", m.car.C.attrs)
	root.get_viewport().get_texture().get_image().save_png(o + "/carreira_treino.png")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Carreira.PATH))
	quit()
