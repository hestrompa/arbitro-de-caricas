extends SceneTree
# jogo completo com o main (2D + lances 3D): verifica que corre sem erros e tira imagens do 2D
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/shots/motor/"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	var tt := Time.get_ticks_msec()
	var n := 0
	var lances := 0
	var prox := 20.0
	while m.modo != "fim" and Time.get_ticks_msec() - tt < 300000:
		if m.modo == "jogo" and m.jogo.mode == "play":
			for k in 3: m.jogo.tick(1.0 / 30.0)
			if m.jogo.t > prox and n < 6:
				prox += 40.0
				await process_frame
				root.get_viewport().get_texture().get_image().save_png(OUT + "j%d.png" % n); n += 1
		if m.modo == "jogo" and m.jogo.mode == "pergunta": m.on_ui("ask", int(m.jogo.ask.get("def", 0)))
		if m.modo == "gesto": m._end_gesture()
		if m.modo == "intervalo": m.on_ui("second_half", "descanso")
		if (m.modo == "lance" or m.modo == "var") and m.dec_shown:
			m._decide(str(m.L.truth)); lances += 1
		await process_frame
	print("FIM modo ", m.modo, " t ", m.jogo.t if m.jogo else -1, " lances ", lances, " resultado ", m.jogo.score if m.jogo else [], " est ", m.jogo.est if m.jogo else {})
	quit()
