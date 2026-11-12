extends SceneTree
# Ida ao monitor depois de um lance normal: o VAR chama, vê-se o árbitro a ir ao monitor em 3D e a cena do lance
# volta igual (mesmos jogadores, mesmos equipamentos) quando a revisão abre. Imagens em OUT.
var m
var OUT := OS.get_environment("OUT")
var falhas := 0
func ok(c: bool, txt: String) -> void:
	print(("  ok  " if c else "  FALHOU  ") + txt)
	if not c: falhas += 1
func foto(nome: String) -> void:
	if OUT != "": root.get_viewport().get_texture().get_image().save_png(OUT + nome)
func quem() -> Array:
	var o: Array = []
	for j in [m.att, m.def] + m.extras: o.append([j.num, j.team, j.node.visible, j.gr])
	return o
func _initialize():
	if OUT != "": DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 30: await process_frame
	while m.modo != "jogo" or m.jogo.mode != "play" or m.jogo.pause > 0: await process_frame
	var J: Partida = m.jogo
	J.no_var = false; J.lance_cd = 0
	var a = J.active().filter(func(p): return p.role == "st" and p.team == 0)[0]
	var d = J.active().filter(func(p): return p.role == "lcb" and p.team == 1)[0]
	a.p = Vector2(J.abs_x(0, 92.0), 31.0); d.p = a.p + Vector2(0.8, 0.6); J.bp = a.p; J.owner = a
	J.start_lance(a, d)
	while m.modo != "lance" or not m.dec_shown: await process_frame
	var antes := quem()
	foto("a_lance.png")
	J.start_var(m.L, "siga")
	ok(m.modo == "ir_var", "o VAR chama: começa a ida ao monitor (modo %s)" % m.modo)
	var k := 0
	while m.modo == "ir_var":
		if m.IV.t >= k * 0.5: foto("b_ir_%02d.png" % k); k += 1
		await process_frame
	ok(m.modo == "var", "a revisão abre no monitor")
	ok(quem() == antes, "os jogadores do lance voltam vestidos como estavam")
	while m.t < m.TC + 0.3: await process_frame
	foto("c_monitor.png")
	ok(not m.monitor.visible and m.ball.visible, "o monitor da linha lateral sai de cena e a bola volta")
	m._decide(str(m.L.truth))
	for i in 20: await process_frame
	ok(m.modo == "gesto", "decide-se no monitor e o árbitro anuncia")
	while m.modo == "gesto":
		if m.G.get("t", 0.0) > 0.7 and k < 99: foto("d_gesto.png"); k = 99
		if m.G.get("t", 0.0) > 2.0: m._end_gesture()
		await process_frame
	print("PASSOU" if falhas == 0 else "FALHOU (%d)" % falhas)
	quit()
