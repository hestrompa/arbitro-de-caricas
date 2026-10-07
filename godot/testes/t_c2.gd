extends SceneTree
var m
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	var t0 := Time.get_ticks_msec()
	m.campo._pinta_relva()
	print("RELVA ms=", Time.get_ticks_msec() - t0)
	m.on_ui("partida", null)
	var n := 0
	while n < 900:
		n += 1
		await process_frame
		if m.modo == "lance": m._decide(m.L.truth)
		if m.modo == "gesto": m._end_gesture()
		if m.modo == "jogo" and m.jogo.mode == "pergunta": m.on_ui("ask", 0)
		if m.modo == "jogo" and m.jogo.mode == "protesto": m.on_ui("protest", "afastar")
	m.jogo.players[5].down = 2.0
	m.ui.hide_all()
	await process_frame; await process_frame
	root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/j/c2.png")
	quit()
