extends SceneTree
# imagem do 2D na Sala do VAR (linha do tempo dos checks e bandeira em espera) e do monitor
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/shots/var2/"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("modo_var", null)
	var tt := Time.get_ticks_msec()
	var feitos := 0
	var flag_shot := false
	var mon := false
	while m.modo != "fim" and Time.get_ticks_msec() - tt < 240000 and feitos < 3:
		if m.modo == "jogo" and m.jogo.mode == "play": m.jogo.tick(0.25)
		if m.modo == "gesto": m._end_gesture()
		if m.modo == "intervalo": m.on_ui("second_half", "descanso")
		if m.modo == "jogo" and not flag_shot and not m.jogo.atraso_band.is_empty():
			flag_shot = true
			for i in 5: await process_frame
			root.get_viewport().get_texture().get_image().save_png(OUT + "espera.png")
		if m.modo == "var" and m.dec_shown:
			if not mon:
				mon = true
				for i in 20: await process_frame
				root.get_viewport().get_texture().get_image().save_png(OUT + "monitor.png")
			m._decide(str(m.L.var_campo)); feitos += 1
		await process_frame
	while m.modo != "jogo": await process_frame
	for i in 30: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "sala2d.png")
	print("feitos ", feitos, " espera ", flag_shot)
	quit()
