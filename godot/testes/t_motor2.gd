extends SceneTree
# fumo: o jogo corre com o motor novo das caricas escolhido no menu (sem erros), com lances 3D pelo meio
func _initialize():
	var m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.motor_novo = true
	m.on_ui("partida", null)
	for i in 10: await process_frame
	var J = m.jogo
	print("motor2 ", J.m2())
	var tt := Time.get_ticks_msec()
	var modos := {}
	while Time.get_ticks_msec() - tt < 60000:
		if J.mode == "pergunta": m.on_ui("ask", 0)
		modos[J.mode] = modos.get(J.mode, 0) + 1
		await process_frame
	print("t ", J.t, " passes ", J.est.passes, " modos ", modos, " main ", m.modo)
	quit()
