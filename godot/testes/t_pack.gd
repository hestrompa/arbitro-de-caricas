extends SceneTree
# Lances que usam capturas do pack, gerados num jogo: aéreo (cabeceamento), mão (remate em corrida), canto (marcador).
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/p/"
func _initialize():
	DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 30: await process_frame
	for nome in ["aereo", "canto", "mao"]:
		var J = m.jogo
		for i in 900:
			if J.mode == "play" and m.modo == "jogo": break
			if J.mode == "pergunta": m.on_ui("ask", 0)
			await process_frame
		for tent in 400:
			if J.mode != "play": break
			J.lance_cd = 0.0
			var a = J.active().filter(func(p): return p.team == 0 and p.role != "gk")
			var b = J.active().filter(func(p): return p.team == 1 and p.role != "gk")
			match nome:
				"aereo":
					b[2].p = a[5].p + Vector2(1.5, 0.5)
					J.aerial_check(a[3], a[5])
				"mao": J.start_hand(a[5], b[2])
				"canto": J.corner_check(0, a[1], false)
		for i in 600:
			if m.modo == "lance": break
			await process_frame
		print(nome, " modo ", m.modo, " lance ", m.lance)
		if m.modo != "lance": continue
		m.cam_mode = 1
		var k := 0
		for dt in [-1.3, -0.6, -0.3, -0.1, 0.0, 0.3, 0.9]:
			while m.t < m.TC + dt: await process_frame
			await process_frame
			root.get_viewport().get_texture().get_image().save_png(OUT + "%s_%d.png" % [nome, k]); k += 1
		print("feito ", nome, " ", m.outcome)
		J.decide(J.lance.truth, true)
		for i in 400:
			if m.modo == "jogo" and J.mode == "play": break
			if m.modo == "gesto": m._end_gesture()
			if J.mode == "pergunta": m.on_ui("ask", 0)
			await process_frame
	quit()
