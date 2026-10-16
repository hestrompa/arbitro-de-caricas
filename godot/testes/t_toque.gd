extends SceneTree
# Fumo: que reação de tronco (toque sem queda) aparece em cada tipo de contacto.
var m
var CASES = [
	["ombro", {"lance": 3, "force": 1.0, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["ombro_limpo", {"lance": 3, "force": 0.8, "side": -1.0, "sim": false, "clean": true, "phi": 50.0, "vD": 8.0}],
	["ombro_forte", {"lance": 3, "force": 1.4, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["empurrao", {"lance": 1, "force": 1.1, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["empurrao_leve", {"lance": 1, "force": 0.6, "side": -1.0, "sim": false, "clean": true, "phi": 50.0, "vD": 8.0}],
	["puxao", {"lance": 2, "force": 0.9, "side": 1.0, "sim": false, "clean": false}],
	["entrada", {"lance": 0, "force": 1.0, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
]
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("treino3d", null)
	for i in 5: await process_frame
	for c in CASES:
		m.cur = c[1].duplicate()
		m._restart()
		var vistos := {}
		var lev := {}
		var perto := 99.0
		while m.t < m.TC + 6.0:
			await process_frame
			for j in [m.att, m.def]:
				if j.toque != "": vistos[j.toque] = true
				if j.phase == "levantar": lev[j.getup_anim] = true
				if j.rag or j.phase in ["queda", "chao", "chao_k", "levantar"]:
					var jb: Vector3 = j.body_pos()
					for e in m.extras:
						if e.node.visible: perto = minf(perto, Vector2(e.body_pos().x - jb.x, e.body_pos().z - jb.z).length())
		print(c[0], " toques=", vistos.keys(), " levantar=", lev.keys(), " outro mais perto de quem caiu=%.2f m" % perto)
	quit()
