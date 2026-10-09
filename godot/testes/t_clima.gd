extends SceneTree
# noites difíceis: força o tempo/acontecimento (CLIMA, EV) e tira fotografias do 2D e de um lance 3D
var m
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 5: await process_frame
	var J: Partida = m.jogo
	if OS.get_environment("NOITE") == "1": m._set_night(true)
	J.clima = OS.get_environment("CLIMA")
	var ev := OS.get_environment("EV")
	J.evento = {"k": ev, "min": 2, "estado": "espera"} if ev != "" else {}
	var o := OS.get_environment("OUT") + "/" + (J.clima if J.clima != "" else "seco") + "_" + (ev if ev != "" else "nada")
	J.lance_cd = 99.0
	var tt := Time.get_ticks_msec()
	var asked := false
	while Time.get_ticks_msec() - tt < 25000:
		if m.modo == "gesto": m._end_gesture()
		if J.mode == "pergunta":
			if not asked:
				for i in 3: await process_frame
				root.get_viewport().get_texture().get_image().save_png(o + "_pergunta.png"); asked = true
				print("pergunta: ", J.ask.opts.map(func(x): return x.d))
			m.on_ui("ask", int(OS.get_environment("ESCOLHA")) if OS.get_environment("ESCOLHA") != "" else 0)
		if J.mode == "protesto": m.on_ui("protest", "afastar")
		if J.t > 25.0 and (J.evento.is_empty() or J.evento.estado != "espera"): break
		await process_frame
	for i in 30: await process_frame
	root.get_viewport().get_texture().get_image().save_png(o + "_2d.png")
	print("manage: ", J.manage, "  luz ", J.luz, " fumo ", J.fumo)
	# um lance 3D no meio disto
	J.lance_cd = 0
	var tt2 := Time.get_ticks_msec()
	while not (m.modo in ["lance"]) and Time.get_ticks_msec() - tt2 < 60000:
		if m.modo == "gesto": m._end_gesture()
		if J.mode == "pergunta": m.on_ui("ask", 0)
		if J.mode == "protesto": m.on_ui("protest", "afastar")
		await process_frame
	while m.modo == "lance" and m.t < m.TC: await process_frame
	root.get_viewport().get_texture().get_image().save_png(o + "_3d.png")
	print("fps ", Engine.get_frames_per_second())
	quit()
