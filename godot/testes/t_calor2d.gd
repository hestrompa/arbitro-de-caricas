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
	J.clima = "calor"; J.temp = 36
	J.t = J.MATCH_SECONDS * 31.0 / 90.0
	var tt := Time.get_ticks_msec()
	while J.mode != "pergunta" and Time.get_ticks_msec() - tt < 60000: await process_frame
	for i in 10: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "calor.png")
	print(J.minute(), " ", J.mode)
	quit()
