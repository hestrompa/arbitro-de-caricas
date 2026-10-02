extends SceneTree
# Lances de golo (linha e falta antes do golo) gerados num jogo, filmados para ver o guarda-redes.
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/f/"
func _initialize():
	DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 30: await process_frame
	for nome in ["linha", "golo"]:
		var J = m.jogo
		var k = J.active().filter(func(p): return p.team == 0 and p.role != "gk")[0]
		var gx: float = J.opp_goal_x(0)
		J.bp = Vector2(gx - (1.0 if gx > J.W / 2 else -1.0) * 14.0, J.H / 2 + 3.0); J.shot_from = J.bp
		var ok = J.start_line(0, k, "entrou", true) if nome == "linha" else J.start_goal_foul(0, k)
		print(nome, " ok=", ok)
		for i in 600:
			if m.modo == "lance": break
			await process_frame
		print("modo ", m.modo, " lance ", m.lance)
		if m.modo != "lance": continue
		m.cam_mode = 1
		var n := 0
		for dt in [-0.6, -0.2, 0.1, 0.4, 0.8, 1.5]:
			while m.t < m.TC + dt: await process_frame
			await process_frame
			root.get_viewport().get_texture().get_image().save_png(OUT + "%s_%d.png" % [nome, n]); n += 1
		if OS.get_environment("TV") != "":
			m.tv_start()
			for i in [40, 120, 200]:
				for f in i: await process_frame
				root.get_viewport().get_texture().get_image().save_png(OUT + "%s_tv%d.png" % [nome, i])
		m.on_ui("decide", 0) if false else null
		for i in 10: await process_frame
		m.modo = "jogo"
	quit()
