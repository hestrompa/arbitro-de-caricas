extends SceneTree
# taça no main: desempate por penáltis (2D com todos no círculo, penálti em 3D e relatório)
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/shots/motor/"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("taca", null)
	for i in 30: await process_frame
	m.jogo.score = [2, 2]; m.jogo.prol = 2; m.jogo.prol_t0 = m.jogo.t
	m.jogo.inicia_desempate()
	var tt := Time.get_ticks_msec()
	var foto2d := false
	var foto3d := false
	while m.modo != "fim" and Time.get_ticks_msec() - tt < 280000:
		if m.modo == "jogo" and m.jogo.mode == "play" and not foto2d and m.jogo.desempate.a_bater:
			for i in 40: await process_frame
			root.get_viewport().get_texture().get_image().save_png(OUT + "taca_2d.png"); foto2d = true
		if m.modo == "jogo" and m.jogo.mode == "pergunta": m.on_ui("ask", 0)
		if m.modo == "gesto": m._end_gesture()
		if (m.modo == "lance" or m.modo == "var") and m.dec_shown:
			if not foto3d:
				for i in 5: await process_frame
				root.get_viewport().get_texture().get_image().save_png(OUT + "taca_3d.png"); foto3d = true
			m._decide(str(m.L.truth))
		await process_frame
	for i in 20: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "taca_fim.png")
	print("FIM ", m.modo, " pen ", m.jogo.desempate.get("g", []), " ", m.jogo.desempate.get("n", []))
	quit()
