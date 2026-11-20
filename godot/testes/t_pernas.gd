extends SceneTree
# Jogadores que deslizam: em lances 3D a sério (jogo normal), mede para cada jogador visível a velocidade do corpo
# e quanto os pés se mexem em relação ao corpo. Quem anda a mais de 1,5 m/s com os pés quase parados em relação
# ao corpo durante 0,4 s está a "patinar". Conta por clip (state) e fase. N lances (6 por omissão).
# uso (escrever para um ficheiro: com pipe o Godot só despeja no fim):
#   xvfb-run -a $GODOT --rendering-driver opengl3 --resolution 640x400 -s ../testes/t_pernas.gd > out.txt
var m
var n := 0
var fase := ""
var feitos := 0
var k := 0
var N := int(OS.get_environment("N")) if OS.get_environment("N") != "" else 6
var mem := {}        # id do nó -> {ant_pe, ant_pos, janela}
var por_estado := {} # state -> [frames a patinar, frames em movimento]
var casos: Array = []
var t_lance := 0.0
func _initialize():
	m = load("res://main.tscn").instantiate()
	root.add_child(m)
func todos() -> Array:
	var js: Array = []
	if m.att: js.append(m.att)
	if m.def: js.append(m.def)
	for e in m.extras: js.append(e)
	return js.filter(func(j): return j != null and j.node.visible)
func mede(dt: float) -> void:
	for j in todos():
		var key: int = j.node.get_instance_id()
		var pc: Vector3 = j.node.global_position
		var fl: Vector3 = j.bone_world("foot_L") - pc
		var fr: Vector3 = j.bone_world("foot_R") - pc
		var M: Dictionary = mem.get(key, {})
		if M.has("fl") and dt > 0.0:
			var vb: float = Vector2(pc.x - M.pc.x, pc.z - M.pc.z).length() / dt
			var vp: float = maxf((fl - M.fl).length(), (fr - M.fr).length()) / dt
			var W: Array = M.get("w", [])
			if vb > 12.0: W = []          # o lance começa com os jogadores colocados de repente: não conta
			else: W.append([vb, vp])
			if W.size() > 12: W.pop_front()
			M.w = W
			var sb := 0.0; var sp := 0.0
			for x in W: sb += x[0]; sp += x[1]
			sb /= W.size(); sp /= W.size()
			if W.size() >= 12 and sb > 1.5 and not j.rag and vb <= 12.0:
				var st: String = str(j.state) + ("" if j.phase == "anim" else " [" + j.phase + "]")
				var c: Array = por_estado.get(st, [0, 0])
				c[1] += 1
				if sp < 0.45 * sb:
					c[0] += 1
					if casos.size() < 60 and str(M.get("avisado", "")) != st:
						M.avisado = st
						casos.append("lance %d (%s) t=%.2f: %s · corpo %.1f m/s, pés %.1f m/s · %s" % [feitos + 1, str(m.L.get("kind", "?")), m.t - m.TC, st, sb, sp, "atacante" if j == m.att else ("defesa" if j == m.def else "extra")])
				por_estado[st] = c
		M.pc = pc; M.fl = fl; M.fr = fr
		mem[key] = M
func _process(dt: float) -> bool:
	n += 1
	if n == 5: m.on_ui("partida", null); return false
	if n < 60: return false
	var J = m.jogo
	if m.modo == "jogo":
		mem = {}
		if J.mode == "pergunta": m.on_ui("ask", 0)
		elif J.mode == "protesto": m.on_ui("protest", "afastar")
		elif J.mode == "play": J.lance_cd = minf(J.lance_cd, 0.5)
		if fase == "dec": fase = ""
	if m.modo == "lance" or m.modo == "gesto": mede(1.0 / 30.0)
	if m.modo == "lance" and fase == "" and m.t > m.TC + 3.0:
		m._decide(str(m.L.truth)); fase = "dec"; feitos += 1; k = 0
	if fase == "dec" and m.modo == "var":
		k += 1
		if k > 20: m._decide(str(m.L.truth)); k = 0
	if m.modo == "ir_var": m.IV.t = 99.0
	if m.modo == "gesto" and m.G.get("t", 0.0) > 3.0: m._end_gesture()
	if feitos >= N and m.modo == "jogo":
		print("== por clip: frames a patinar / frames a mais de 1,5 m/s")
		var ks: Array = por_estado.keys()
		ks.sort_custom(func(a, b): return por_estado[a][0] > por_estado[b][0])
		for s in ks: print("  %-28s %4d / %4d  (%d%%)" % [s, por_estado[s][0], por_estado[s][1], int(100.0 * por_estado[s][0] / maxf(por_estado[s][1], 1))])
		print("== casos")
		for c in casos: print("  " + c)
		quit(); return true
	if n > 40000: print("tempo esgotado"); quit(1); return true
	return false
