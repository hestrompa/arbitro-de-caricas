extends SceneTree
# relatório: estatísticas do jogo em barras
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
	J.est = {"posse": [160.0, 110.0], "remates": [9, 5], "alvo": [4, 2], "passes": [60, 50], "passes_ok": [45, 37], "desarmes": [17, 18], "faltas": [4, 6], "cantos": [3, 1],
		"xg": [1.2, 0.6], "ocasioes": [2, 1], "rem_area": [4, 2], "cruz": [2, 1], "na_area": [2, 1], "primeira": [1, 1]}
	J.score = [2, 1]
	J.end_match("fim")
	for i in 30: await process_frame
	var sc: ScrollContainer = null
	for n in m.ui.report.find_children("*", "ScrollContainer", true, false): sc = n
	if sc: sc.scroll_vertical = 100000
	for i in 10: await process_frame
	root.get_viewport().get_texture().get_image().save_png(OUT + "estat.png")
	print(m.modo)
	quit()
