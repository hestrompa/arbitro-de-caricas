extends SceneTree
# Lances de um jogo a sério, vistos pelo árbitro: uma imagem a cada 0,3 s, para julgar a naturalidade.
# N=lances a gravar. Saída em S/godot/t/seq/<n>_<tipo>_<k>.png
var m
var n := 0
var fase := ""
var feitos := 0
var k := 0
var prox := 0.0
var nome := ""
var D := "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/seq"
var N := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 6
func _initialize():
	DirAccess.make_dir_recursive_absolute(D)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(dt: float) -> bool:
	n += 1
	if n < 5: return false
	if m.modo == "menu": m.on_ui("partida", null); return false
	var j = m.jogo
	if m.modo == "flash" and fase == "":
		fase = "flash"; k = 0; prox = float(OS.get_environment("T0")) if OS.get_environment("T0") != "" else 0.0
		nome = "%d_%s_%s" % [feitos, j.kind_of(m.L), str(m.L.truth)]
	if m.modo == "lance" and fase == "flash":
		if OS.get_environment("CAM") != "": m.cam_mode = int(OS.get_environment("CAM"))
		if m.t >= prox:
			root.get_texture().get_image().save_png("%s/%s_%02d.png" % [D, nome, k])
			k += 1; prox += float(OS.get_environment("DT")) if OS.get_environment("DT") != "" else 0.3
		if m.t > m.TC + 1.8: fase = "dec"
	if fase == "dec" and m.modo in ["lance", "var"] and m.dec_shown:
		fase = ""; feitos += 1; m._decide(m.L.truth)
		print("gravado ", nome, " ", k, " imagens")
		if feitos >= N: quit(); return true
	if m.modo == "gesto" and m.G.get("t", 0.0) > 0.4: m._end_gesture()
	if m.modo == "jogo":
		if j.mode == "pergunta": m.on_ui("ask", 0)
		if j.mode == "protesto": m.on_ui("protest", "afastar")
	if m.modo == "intervalo": m.on_ui("second_half", "capitaes")
	if m.modo == "fim": quit(); return true
	return false
