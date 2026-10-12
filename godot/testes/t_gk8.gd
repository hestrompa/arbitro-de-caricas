extends SceneTree
# imagem: guarda-redes com a bola nas mãos (botão G e contagem) e jogador caído
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/shots/regras/"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	while m.modo != "jogo": await process_frame
	for i in 20: await process_frame
	var J = m.jogo
	J.lance_cd = 999
	var gk = J.players.filter(func(q): return q.team == 1 and q.role == "gk")[0]
	J.reset_ball(gk.p); J.owner = gk; gk.cd = 1.0
	J.gk8 = {"id": gk.id, "team": gk.team, "t": 0.0, "conta": -1.0, "larga": false}
	var att = J.players.filter(func(q): return q.team == 0 and q.role == "st")[0]
	att.down = 30.0
	J.lesao = {"id": att.id, "team": 0, "tipo": "ligeira", "t": -99.0, "fase": "espera", "outro": 0}
	for i in 30: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "gk8_a.png")
	J.conta_mao()
	for i in 40: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "gk8_b.png")
	print("modo ", J.mode, " gk8 ", J.gk8)
	quit()
