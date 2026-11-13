extends SceneTree
# Jogadas ensaiadas vistas nas caricas (com ecrã): grava a área antes do pontapé e com a bola no ar.
# uso: OUT=pasta TIPO=segundo DE=canto|livre xvfb-run -a godot --rendering-driver opengl3 --resolution 1280x720 -s ../testes/t_ensaio2d.gd
var m
var n := 0
var fase := ""
var espera := 0
var tk := 0.0
var out := OS.get_environment("OUT")
var tipo := OS.get_environment("TIPO")
var de := OS.get_environment("DE")
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _grava(nm: String) -> void:
	if out == "": return
	root.get_texture().get_image().save_png("%s/%s_%s_%s.png" % [out, de if de != "" else "canto", tipo, nm])
func _process(_dt: float) -> bool:
	n += 1
	if n < 5: return false
	if n > 3000: quit(1); return true
	var J = m.jogo
	if m.modo == "menu":
		m.on_ui("partida", null); espera = 0; return false
	if m.modo != "jogo" or J == null: return false
	if not J.ask.is_empty(): J.ask_pick(int(J.ask.get("def", 0))); return false
	if fase == "" and J.mode == "play":
		espera += 1
		if espera > 120 and J.parado_dono == null:
			J.lance_cd = 99.0
			if tipo != "": J.af["ensaio_tipo"] = tipo
			if de == "livre": J.af["ensaio_longe"] = 99.0
			if de == "livre":
				var at := Vector2(J.abs_x(0, 76.0), J.H / 2 + 24.0)
				var p = J.nearest(J.active().filter(func(q): return q.team == 0 and q.role != "gk"), at)[0]
				J.reset_ball(at); p.p = at - Vector2(J.dirs(0) * 0.8, 0)
				J.owner = p; J.last = 0; p.cd = 0.9; p.set_piece = true; J.parado_dono = p
				J.ensaio_livre(0, p)
			else: J.corner(0, 0.5)
			J.lance_cd = 99.0
			fase = "espera"
			print("jogada: ", J.ensaio.get("tipo", "nenhuma"))
	elif fase == "espera":
		if J.parado_dono != null and not J.a_caminho() and J.pause <= 0.0: _grava("1_antes"); fase = "antes"
		if J.parado_dono == null: fase = "voo"; tk = J.t
	elif fase == "antes":
		if J.parado_dono == null: fase = "voo"; tk = J.t
	elif fase == "voo":
		if J.t - tk > 0.7: _grava("2_voo"); fase = "fim"; espera = 0
	elif fase == "fim":
		espera += 1
		if espera == 50: _grava("3_depois")
		if espera > 55: quit(); return true
	return false
