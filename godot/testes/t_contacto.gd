extends SceneTree
# Mede o contacto real (pele com pele) à volta do instante TC em cada tipo de lance.
var m
const PARTES := {0: [["perna", "pe", "tronco"], ["perna", "pe", "tronco", "braco"]], 1: [["mao", "braco"], ["tronco"]], 2: [["mao"], ["tronco", "braco"]], 3: [["tronco", "braco"], ["tronco", "braco"]], 4: [["perna", "pe"], ["perna", "pe"]]}
var CASES = [
	["sim", {"lance": 0, "force": 0.6, "sim": true, "clean": false, "phi": 50.0, "vD": 8.0}],
	["limpo", {"lance": 0, "force": 0.6, "sim": false, "clean": true, "phi": 50.0, "vD": 8.0}],
	["area_siga", {"lance": 0, "force": 0.6, "sim": false, "clean": true, "de_pe": true, "phi": 65.0, "vD": 7.2}],
	["area_falta", {"lance": 0, "force": 0.8, "sim": false, "clean": false, "de_pe": true, "phi": 65.0, "vD": 7.2}],
	["leve", {"lance": 0, "force": 0.7, "sim": false, "clean": false, "phi": 60.0, "vD": 7.0}],
	["falta", {"lance": 0, "force": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["forte", {"lance": 0, "force": 1.4, "sim": false, "clean": false, "phi": 30.0, "vD": 9.2}],
	["empurrao", {"lance": 1, "force": 0.8, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["empurrao_f", {"lance": 1, "force": 1.2, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["puxao", {"lance": 2, "force": 0.8, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["puxao_f", {"lance": 2, "force": 1.2, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["ombro", {"lance": 3, "force": 0.9, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["ombro_f", {"lance": 3, "force": 1.4, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
]
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("treino3d", null)
	for i in 5: await process_frame
	var only = OS.get_environment("CASOS")
	for c in CASES:
		if only != "" and not (c[0] in only.split(",")): continue
		for sd in [1.0, -1.0]:
			var cc: Dictionary = c[1].duplicate(); cc.side = sd
			m.cur = cc; m._restart()
			var pr: Array = PARTES[int(cc.lance)]
			var first := 99.0; var gmin := 99.0; var tmin := 0.0; var gtc := 99.0
			var react := -99.0
			while m.t < m.TC + 0.7:
				await process_frame
				if m.t < m.TC - 0.7: continue
				var f: Array = Jogador.folga(m.def, m.att, pr[0], pr[1])
				var g: float = f[0]
				if OS.get_environment("DBGT") != "": print("TST t=%+.3f g=%.3f" % [m.t - m.TC, Jogador.folga(m.def, m.att, ["perna", "pe", "tronco", "braco", "mao"], ["perna", "pe", "tronco", "braco", "mao"])[0]])
				if g < gmin: gmin = g; tmin = m.t - m.TC
				if g <= 0.03 and first > 50: first = m.t - m.TC
				if absf(m.t - m.TC) < 0.009: gtc = g
				if m.hit_done and react < -50: react = m.t - m.TC
				m.hitstop = 0.0
			print("%-11s lado %+d  contacto %s  folga_min %.2f m em %+.2f s  reação %+.2f s" % [c[0], int(sd), ("%+.2f s" % first) if first < 50 else "NUNCA", gmin, tmin, react])
	quit()
