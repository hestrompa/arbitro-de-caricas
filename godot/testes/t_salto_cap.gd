extends SceneTree
# Saltos capturados nos lances aéreos e nos cantos: imprime a altura da cabeça de quem salta à volta de TC e,
# com OUT=pasta (com ecrã), grava imagens de TC-0,6 a TC+0,6 s. CASO=aereo|canto, CAM=modo da câmara.
var m
var n := 0
var feito := false
var caso := OS.get_environment("CASO") if OS.get_environment("CASO") != "" else "aereo"
var out := OS.get_environment("OUT")
var marcas := [-0.6, -0.4, -0.2, 0.0, 0.2, 0.4, 0.6]
var k := 0
var h0 := {}
var hmax := {}
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(_dt: float) -> bool:
	n += 1
	if n < 5: return false
	if m.modo == "menu" and not feito: m.on_ui("partida", null); return false
	var j = m.jogo
	if m.modo == "jogo" and j.mode == "play" and not feito and n > 40:
		if not j.ask.is_empty(): j.ask_pick(0); return false
		for i in 200:
			j.lance_cd = 0
			if caso == "canto": j.corner(0, 0.5)
			else:
				var p = null; var r = null; var o = null
				for q in j.active():
					if q.team == 0 and q.role == "lcb": p = q
					if q.team == 0 and q.role == "st": r = q
					if q.team == 1 and q.role == "rcb": o = q
				o.p = r.p + Vector2(1.5, 0)
				j.aerial_check(p, r)
			if j.mode == "lance" or m.modo == "flash" or m.modo == "lance": break
		feito = true
	if m.modo == "lance":
		if m.cam_mode != int(OS.get_environment("CAM") if OS.get_environment("CAM") != "" else "4"): m.cam_mode = int(OS.get_environment("CAM") if OS.get_environment("CAM") != "" else "4")
		for nm in ["att", "def"]:
			var jj: Jogador = m.get(nm)
			var hy: float = jj.bone_world("head").y
			if not h0.has(nm) and m.t < m.TC - 0.8: h0[nm] = hy
			if absf(m.t - m.TC) < 0.3: hmax[nm] = maxf(float(hmax.get(nm, 0.0)), hy)
		if k < marcas.size() and m.t >= m.TC + marcas[k]:
			if out != "": root.get_texture().get_image().save_png("%s/%s_%d.png" % [out, caso, k])
			print("t-TC %+.1f  atacante %s cabeça %.2f · defesa %s cabeça %.2f" % [marcas[k], m.att.state, m.att.bone_world("head").y, m.def.state, m.def.bone_world("head").y])
			k += 1
		if m.t > m.TC + 0.7:
			print("verdade ", m.sc.truth, " · cabeça antes ", h0, " · mais alta perto do instante da bola ", hmax)
			var sobe: float = float(hmax.get("def", 0.0)) - float(h0.get("def", 9.0))
			print("PASSOU" if sobe > 0.15 else "FALHOU (o defesa não saltou)")
			quit(); return true
	if n > 6000: print("FALHOU: sem lance"); quit(); return true
	return false
