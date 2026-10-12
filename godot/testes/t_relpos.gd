extends SceneTree
# relatório com o mapa de posicionamento do árbitro
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/shots/motor/"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	var tt := Time.get_ticks_msec()
	while m.modo != "fim" and Time.get_ticks_msec() - tt < 200000:
		if m.modo == "jogo" and m.jogo.mode == "play":
			var J = m.jogo
			J.lance_cd = 99.0
			if J.t > 90: J.end_match("fim")
			for k in 4:
				J.ref_target = J.bp + Vector2(-6 if J.bp.x < 52 else 6, 12 if J.bp.x < 52 else -12)
				J.tick(1.0 / 30.0)
		if m.modo == "jogo" and m.jogo.mode == "pergunta": m.jogo.ask_pick(int(m.jogo.ask.get("def", 0)))
		if m.modo == "gesto": m._end_gesture()
		if m.modo == "intervalo": m.on_ui("second_half", "descanso")
		if (m.modo == "lance" or m.modo == "var") and m.dec_shown: m._decide(str(m.L.truth))
		await process_frame
	for i in 20: await process_frame
	var sc = m.ui.report_v.get_parent()
	print("modo ", m.modo, " pos ", m.jogo.pos_resumo())
	# desce até ao posicionamento
	for ch in m.ui.report_v.get_children():
		if ch is Label and ch.text == "Posicionamento":
			if sc is ScrollContainer: sc.scroll_vertical = int(ch.position.y) - 20
	for i in 10: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "relatorio_pos.png")
	quit()
