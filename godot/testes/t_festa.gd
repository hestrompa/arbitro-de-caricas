extends SceneTree
# festejos de golo no 2D: imagens a meio do festejo e depois o pontapé de saída
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/shots/motor/"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 10: await process_frame
	var J = m.jogo
	J.ask = {}; J.mode = "play"; J.lance_cd = 99; J.pause = 0
	var st = null
	for p in J.active():
		if p.team == 0 and p.role == "st": st = p
	st.p = Vector2(J.W - 12, J.H / 2 + 6)
	J.kicker = st; J.last = 0; J.owner = null
	J.bp = Vector2(J.W + 0.5, J.H / 2)
	J.goal(0)
	print("festa ", not J.festa.is_empty(), " score ", J.score)
	var fotos := [0.9, 2.2, 3.6]
	var tt := Time.get_ticks_msec()
	while (not J.festa.is_empty() or J.mode != "play") and Time.get_ticks_msec() - tt < 30000:
		if J.mode == "pergunta": m.on_ui("ask", 0)
		if fotos.size() and not J.festa.is_empty() and J.festa.t > fotos[0]:
			root.get_viewport().get_texture().get_image().save_png(OUT + "festa_%d.png" % (3 - fotos.size())); fotos.pop_front()
		await process_frame
	print("depois: owner ", J.owner.num if J.owner else -1, " pause ", J.pause, " mode ", J.mode)
	quit()
