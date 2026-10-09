extends SceneTree
# Quedas de perto: imagens de TC-0.1 até TC+2.4, para julgar se parecem naturais. CASOS, CAM, DT.
var m
const OUT = "/tmp/claude-0/-home-claude/03cb57f4-a453-5d33-87b7-2efcd6ebbd73/scratchpad/godot/t/q/"
var CASES = [
	["falta", {"lance": 0, "force": 1.0, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["forte", {"lance": 0, "force": 1.4, "side": -1.0, "sim": false, "clean": false, "phi": 35.0, "vD": 9.2}],
	["sim", {"lance": 0, "force": 0.6, "side": 1.0, "sim": true, "clean": false, "phi": 50.0, "vD": 8.0}],
	["empurrao", {"lance": 1, "force": 1.1, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
	["puxao", {"lance": 2, "force": 0.9, "side": 1.0, "sim": false, "clean": false}],
	["ombro_forte", {"lance": 3, "force": 1.4, "side": 1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.0}],
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
	var step := float(OS.get_environment("DT")) if OS.get_environment("DT") != "" else 0.2
	var fim := float(OS.get_environment("FIM")) if OS.get_environment("FIM") != "" else 2.4
	for c in CASES:
		if only != "" and not (c[0] in only.split(",")): continue
		m.cur = c[1].duplicate()
		m._restart()
		m.cam_mode = int(OS.get_environment("CAM")) if OS.get_environment("CAM") != "" else 1
		var k := 0
		var dt := -0.1
		while dt <= fim:
			while m.t < m.TC + dt: await process_frame
			await process_frame
			root.get_viewport().get_texture().get_image().save_png(OUT + "%s_%02d.png" % [c[0], k])
			k += 1; dt += step
		print("feito ", c[0], " ", k)
	quit()
