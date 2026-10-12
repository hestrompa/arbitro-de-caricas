extends SceneTree
# ecrãs: vistoria no túnel e descontos
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/shots/motor/"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 40: await process_frame
	var J = m.jogo
	J.lance_cd = 99
	if J.ask.is_empty(): J.vistoria()
	for i in 20: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "vistoria.png")
	m.on_ui("ask", 1)
	for i in 20: await process_frame
	J.desc_base = J._contagens(); J.half = 2
	J.t = J.MATCH_SECONDS + 0.1
	for i in 30: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "descontos.png")
	m.on_ui("ask", 2)
	for i in 40: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "placa.png")
	print("ask: ", J.mode, " manage: ", J.manage, " placa ", J.placa)
	quit()
