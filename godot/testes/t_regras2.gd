extends SceneTree
# imagens: placa de substituição e atacante encostado à barreira
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/shots/regras/"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 30: await process_frame
	m.on_ui("partida", null)
	while m.modo != "jogo": await process_frame
	for i in 30: await process_frame
	m.jogo.lance_cd = 999
	m.jogo._substitui(0, 2)
	for i in 10: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "placa.png")
	# livre direto com atacante encostado
	var J = m.jogo
	var tk = J.players.filter(func(q): return q.team == 0 and q.role == "st")[0]
	J.reset_ball(Vector2(J.opp_goal_x(0) - J.dirs(0) * 22, J.H / 2 + 4))
	tk.p = J.bp; J.owner = tk; tk.set_piece = true; J.parado_dono = tk
	J.rng.seed = 5
	for s in 40:
		J.fk = {}
		J.fk_check(tk)
		if J.fk.get("enc", false): break
	print("enc ", J.fk.get("enc", false))
	J.fk.short = false
	for i in 70: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "barreira.png")
	quit()
