extends SceneTree
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/shots/motor/"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 10: await process_frame
	var J = m.jogo
	J.ask = {}; J.mode = "play"; J.lance_cd = 99
	for i in 60:
		if J.mode == "pergunta": m.on_ui("ask", 0)
		await process_frame
	for i in 30: await process_frame
	J._molho_inicio(1)
	var tt := Time.get_ticks_msec()
	var f := false
	while Time.get_ticks_msec() - tt < 20000:
		if not J.molho.is_empty() and J.molho.t > 0.9 and not f:
			root.get_viewport().get_texture().get_image().save_png(OUT + "molho_a.png"); f = true
		if J.mode == "pergunta": break
		await process_frame
	for i in 10: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "molho_b.png")
	m.on_ui("ask", 1)
	for i in 60: await process_frame
	print("depois ", J.mode, " molho ", J.molho, " manage ", J.manage.back() if J.manage.size() else null)
	quit()
