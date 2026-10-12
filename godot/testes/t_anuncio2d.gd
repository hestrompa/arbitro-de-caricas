extends SceneTree
# ecrã do anúncio ao estádio (texto longo nos botões)
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/shots/motor/"
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("partida", null)
	for i in 60: await process_frame
	var J = m.jogo
	J.lance_cd = 99
	var a = J.players[8]; var d = J.players[14]
	var L := {"kind": "foul", "var_first": "falta", "decided": "amarelo", "att": {"num": a.num, "team": a.team}, "def": {"num": d.num, "team": d.team}}
	J.anuncio_ask(L, "amarelo", func(): print("depois do anúncio"))
	for i in 30: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "anuncio.png")
	m.on_ui("ask", 0)
	for i in 10: await process_frame
	print("manage: ", J.manage.back())
	quit()
