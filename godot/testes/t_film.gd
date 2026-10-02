extends SceneTree
# Sequências de imagens de lances de treino (vista ideal), para julgar a naturalidade.
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/f/"
var CASES = [
	["sim", {"lance": 0, "force": 0.6, "side": 1.0, "sim": true, "clean": false, "phi": 50.0, "vD": 8.0}],
	["limpo", {"lance": 0, "force": 0.6, "side": 1.0, "sim": false, "clean": true, "phi": 50.0, "vD": 8.0}],
	["falta", {"lance": 0, "force": 1.0, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["forte", {"lance": 0, "force": 1.4, "side": -1.0, "sim": false, "clean": false, "phi": 35.0, "vD": 9.2}],
	["empurrao", {"lance": 1, "force": 1.1, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["linha", {"lance": 8, "force": 1.0, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["golo", {"lance": 10, "force": 1.0, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["ombro", {"lance": 3, "force": 1.0, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
]
func _initialize():
	DirAccess.make_dir_recursive_absolute(OUT)
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("treino3d", null)
	for i in 5: await process_frame
	var only = OS.get_environment("CASOS")
	for c in CASES:
		if only != "" and not (c[0] in only.split(",")): continue
		m.cur = c[1].duplicate()
		if OS.get_environment("ENERGIA") != "": m._ref_corrida(m.REF_FIM, float(OS.get_environment("ENERGIA")))
		m._restart()
		if OS.get_environment("NOITE") != "": m._set_night(true)
		if OS.get_environment("TV") != "": m.tv_start()
		m.cam_mode = int(OS.get_environment("CAM")) if OS.get_environment("CAM") != "" else 1
		var k := 0
		for dt in [-0.6, -0.25, 0.0, 0.15, 0.35, 0.7, 1.3]:
			while m.t < m.TC + dt: await process_frame
			await process_frame
			root.get_viewport().get_texture().get_image().save_png(OUT + "%s_%d.png" % [c[0], k])
			k += 1
		print("feito ", c[0])
	quit()
