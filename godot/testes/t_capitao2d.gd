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
	J.aggr[1] = 1.0
	J.protest_after(1, 1.0, true)
	for i in 40: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "capitao_a.png")
	print("modo ", J.mode, " ids ", J.protest.get("ids", []))
	seed(3)
	J.rng.seed = 5
	m.on_ui("protest", "so_capitao")
	var tt := Time.get_ticks_msec()
	while Time.get_ticks_msec() - tt < 4000 and J.mode != "pergunta": await process_frame
	for i in 10: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "capitao_b.png")
	print("depois ", J.mode, " feed ", J.feed_list.back().txt)
	quit()
