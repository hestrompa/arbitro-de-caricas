extends SceneTree
# Quanto escorregam os pés apoiados (cm/s) na pista de locomoção, com e sem a locomoção nova (NATURAL=0)
var m
const C := Vector2(52.5, 34.0)
func caminho(k: int, t: float) -> Vector2:
	match k:
		0:
			if t < 2.0: return C + Vector2(-8 + t * 6.5, -4)
			if t < 2.8: var u := (t - 2.0) / 0.8; return C + Vector2(5 + 6.5 * 0.8 * (u - u * u / 2), -4)
			return C + Vector2(7.6 - (t - 2.8) * 3.2, -4)
		1:
			if t < 3.0: return C + Vector2(4 - t * 2.6, 2)
			return C + Vector2(4 - 3.0 * 2.6, 2 + (t - 3.0) * 2.2)
		_:
			if t < 2.5: return C + Vector2(-6 + t * 1.3, 7)
			if t < 3.5: return C + Vector2(-6 + 2.5 * 1.3, 7)
			return C + Vector2(-6 + 2.5 * 1.3 + (t - 3.5) * 1.3, 7 - (t - 3.5) * 0.6)
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
	for i in 10: await process_frame
	m.on_ui("treino3d", null)
	for i in 5: await process_frame
	m.modo = "clips"; m.set_process(false); m.set_physics_process(false)
	Jogador.natural = OS.get_environment("NATURAL") != "0"
	var js: Array = [m.att, m.def, m.extras[0]]
	var bola := C + Vector2(10, 0)
	for j in js: j.reset(); j.snap = true
	var dt := 1.0 / 30.0
	var t := 0.0
	var soma := [0.0, 0.0, 0.0]; var n := [0, 0, 0]
	var ant: Array = [null, null, null]
	while t < 6.0:
		for i in 3:
			var j: Jogador = js[i]
			var p := caminho(i, t)
			var v := (caminho(i, t + 0.05) - p) / 0.05
			var face: Vector2 = v.normalized() if v.length() > 0.3 else j.dir
			if i == 1: face = (bola - p).normalized()
			j.move(p, face, v.length())
			j.play("run" if v.length() > 4.2 else ("jog" if v.length() > 0.7 else "idle"), 0.3)
			j.update(dt, t)
			j.ground()
			var fl: Vector3 = j.bone_world("foot_L"); var fr: Vector3 = j.bone_world("foot_R")
			var low := "L" if fl.y < fr.y else "R"
			var fp: Vector3 = fl if low == "L" else fr
			if ant[i] != null and ant[i][0] == low and fp.y < 0.09:
				var sv: float = Vector2(fp.x - ant[i][1].x, fp.z - ant[i][1].z).length() / dt
				soma[i] += sv; n[i] += 1
				if OS.get_environment("DET") != "" and i == int(OS.get_environment("DET")): print("t %.2f %s y %.3f desl %.0f estado %s esc %.2f lock %s" % [t, low, fp.y, sv * 100, j.state, j.anim.speed_scale, str(j.pe_lock.keys())])
			ant[i] = [low, fp]
		await process_frame
		t += dt
	print("natural=", Jogador.natural, " deslize (cm/s): corre/trava/vira %.0f  recua/lado %.0f  anda %.0f" % [soma[0] / maxi(n[0], 1) * 100, soma[1] / maxi(n[1], 1) * 100, soma[2] / maxi(n[2], 1) * 100])
	quit()
