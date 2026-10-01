extends SceneTree
# Mede a distância entre pernas em entradas de treino: simulação, limpa e falta.
var m
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("treino3d", null)
	for k in 12:
		var c := {"lance": 0, "force": [0.6, 0.6, 1.0, 1.3][k % 4], "side": 1.0 if k % 2 == 0 else -1.0, "sim": k % 4 == 0, "clean": k % 4 == 1, "phi": 30.0 + k * 4, "vD": 8.0}
		m.cur = c; m._restart()
		while m.t < m.TC + 1.4: await process_frame
	quit()
