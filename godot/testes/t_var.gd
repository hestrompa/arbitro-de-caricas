extends SceneTree
# modo VAR: um jogo inteiro; nas verificações escolhe a verdade (ou confirma sempre com CONFIRMA=1)
var m
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("modo_var", null)
	var o := OS.get_environment("OUT")
	var shots := 0
	var tt := Time.get_ticks_msec()
	while m.modo != "fim" and Time.get_ticks_msec() - tt < 300000:
		if m.modo == "jogo" and m.jogo.mode == "play": m.jogo.tick(0.25)
		if m.modo == "gesto": m._end_gesture()
		if m.modo == "intervalo": m.on_ui("second_half", "descanso")
		if m.modo == "var" and m.dec_shown:
			if o != "" and shots < 2:
				for i in 20: await process_frame
				root.get_viewport().get_texture().get_image().save_png(o + "/var%d.png" % shots); shots += 1
			var d: String = m.L.var_campo if OS.get_environment("CONFIRMA") == "1" else (m.L.truth if m.jogo.kind_of(m.L) != "offside" else ("fora" if m.L.truth == "fora" else "emjogo"))
			print("  verificação %d': campo %s  verdade %s  escolho %s" % [m.L.minute, m.L.var_campo, m.L.truth, d])
			m._decide(d)
		await process_frame
	await process_frame
	print("FIM modo=", m.modo, "  nota ", m.jogo.grade, "  checks ", m.jogo.var_checks.size(), "  ia ", m.jogo.ia_n, "  incidents ", m.jogo.incidents.size())
	for r in m.jogo.report_rows(): print("   ", r.cells)
	quit()
