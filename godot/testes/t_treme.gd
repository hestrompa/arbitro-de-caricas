extends SceneTree
# Procura jogadores 3D a tremer: trocas de animação muito seguidas (idle/andar/trote/corrida) ou recuos de posição.
var m
var n := 0
var fase := ""
var lances := 0
var hist := {}      # jogador -> [[t, estado, speed]]
var maus := []
var N_LANCES := int(OS.get_environment("NL")) if OS.get_environment("NL") != "" else 8
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func _process(dt: float) -> bool:
	n += 1
	if n == 5: m.on_ui("partida", null); return false
	if n < 60: return false
	if m.modo == "lance":
		if fase != "lance":
			fase = "lance"; hist = {}
			if OS.get_environment("DH") != "":
				var h: Array = m.L.get("hist", [])
				print("HIST lance=", m.lance, " amostras ", h.size(), " t2d ", m._t2d(), " TC ", m.TC)
				for e in m.extras:
					var id := int(e.get_meta("pid", -1))
					var seq := []
					var prev = null
					for smp in h:
						if not smp.ps.has(id): seq.append("x"); continue
						var q: Vector2 = smp.ps[id]
						if prev != null and (q - prev).length() > 1.2: seq.append("SALTO %.2f:%.1fm" % [smp.tau, (q - prev).length()])
						prev = q
					print("  pid ", id, " ", " ".join(seq))
		var js: Array = [m.att, m.def, m.refj] + m.extras
		for k in js.size():
			var j: Jogador = js[k]
			if not j.node.visible: continue
			if not hist.has(k): hist[k] = []
			var h: Array = hist[k]
			if h.is_empty() or h[-1][1] != j.state: h.append([m.t, j.state, j.speed])
		if m.t > m.TC + 4.0:
			_analisa()
			m._decide(m.L.truth); fase = "dec"; lances += 1
			if lances >= N_LANCES: return _fim()
	elif fase == "dec" and m.modo == "jogo": fase = ""
	if n > 40000: return _fim()
	return false
func _analisa() -> void:
	var nomes := ["att", "def", "arb"]
	for k in hist:
		var h: Array = hist[k]
		for i in h.size():
			# 4 trocas em menos de 1 s
			if i + 4 < h.size() and float(h[i + 4][0]) - float(h[i][0]) < 1.0:
				var seq := []
				for q in range(i, mini(i + 8, h.size())): seq.append("%s@%.2f(v%.1f)" % [h[q][1], h[q][0] - m.TC, h[q][2]])
				var quem: String = nomes[k] if k < 3 else "extra%d" % (k - 3)
				print("TREME lance=", m.lance, " ", quem, " ", " ".join(seq))
				maus.append(m.lance)
				break
func _fim() -> bool:
	print("lances ", lances, " com tremor ", maus.size(), " ", maus)
	quit(); return true
