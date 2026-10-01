extends Node3D
# Árbitro de Caricas em Godot 4: primeiro lance 3D (entrada para amarelo), com o mesmo corpo, equipamentos e animações da versão browser.

const W := 105.0
const H := 68.0
const TC := 2.2           # instante do contacto
const DUR := 4.6
const PLAYER := preload("res://assets/jogador.glb")
const KIT := preload("res://shaders/kit.gdshader")
const SKINS := ["light", "mid", "brown", "dark"]

var t := 0.0
var speed := 1.0
var paused := false
var cam_mode := 0         # 0 = a tua vista, 1 = vista ideal, 2 = atrás da baliza
var cam: Camera3D
var ball: MeshInstance3D
var att: Dictionary
var def: Dictionary
var extras: Array = []
var ui: Label
var P := Vector2(60, 30)
var A := Vector2(-1, 0)
var D := Vector2.ZERO
var REF := Vector2(70, 46)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_world()
	_stadium()
	var phi := deg_to_rad(52.0)
	D = A.rotated(-phi)
	att = _player({"color": Color("ee7d2c"), "dark": Color("a4521a"), "shorts": Color("23242a"), "sock": Color("ee7d2c"), "pat": 1.0, "shirt2": Color("23242a")}, 9, 3)
	def = _player({"color": Color("3569dc"), "dark": Color("1d3f8f"), "shorts": Color("f1f1f1"), "sock": Color("1d3f8f"), "pat": 0.0, "shirt2": Color("f1f1f1")}, 4, 8)
	var spots := [Vector2(68, 22), Vector2(52, 40), Vector2(75, 33), Vector2(48, 24)]
	for i in spots.size():
		var home := i % 2 == 0
		var e := _player({"color": Color("3569dc") if home else Color("ee7d2c"), "dark": Color("1d3f8f") if home else Color("a4521a"), "shorts": Color("f1f1f1") if home else Color("23242a"), "sock": Color("1d3f8f") if home else Color("ee7d2c"), "pat": 0.0 if home else 1.0, "shirt2": Color("f1f1f1") if home else Color("23242a")}, [2, 7, 5, 10][i], 20 + i)
		e["spot"] = spots[i]
		extras.append(e)
	ball = MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.11; sm.height = 0.22
	ball.mesh = sm
	var bm := StandardMaterial3D.new(); bm.albedo_color = Color(0.96, 0.96, 0.96); bm.roughness = 0.4
	ball.material_override = bm
	add_child(ball)
	cam = Camera3D.new(); cam.fov = 55; cam.near = 0.05; cam.far = 600
	add_child(cam); cam.current = true
	_ui()
	_restart()

func _world() -> void:
	var env := Environment.new()
	var sky := Sky.new(); var sk := ProceduralSkyMaterial.new()
	sk.sky_top_color = Color(0.32, 0.5, 0.78); sk.sky_horizon_color = Color(0.72, 0.8, 0.9); sk.ground_horizon_color = Color(0.5, 0.55, 0.5)
	sky.sky_material = sk
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.05
	env.glow_enabled = true; env.glow_intensity = 0.4; env.glow_bloom = 0.05
	env.fog_enabled = false; env.fog_light_color = Color(0.7, 0.76, 0.85); env.fog_density = 0.0012
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -35, 0); sun.light_energy = 1.45; sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0; sun.shadow_blur = 1.5
	add_child(sun)
	var pitch := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(W + 24, H + 24)
	pitch.mesh = pm; pitch.position = Vector3(W / 2, 0, H / 2)
	var mat := ShaderMaterial.new(); mat.shader = preload("res://shaders/pitch.gdshader")
	pitch.material_override = mat
	add_child(pitch)
	var ground := StaticBody3D.new(); ground.collision_layer = L_GROUND; ground.collision_mask = 0
	var gpm := PhysicsMaterial.new(); gpm.friction = 0.9; ground.physics_material_override = gpm
	var gcs := CollisionShape3D.new(); gcs.shape = WorldBoundaryShape3D.new(); ground.add_child(gcs); add_child(ground)
	# balizas
	for gx in [0.0, W]:
		var goal := Node3D.new(); goal.position = Vector3(gx, 0, H / 2); add_child(goal)
		var post := StandardMaterial3D.new(); post.albedo_color = Color(0.97, 0.97, 0.97); post.roughness = 0.3
		for s in [-1.0, 1.0]:
			var p := MeshInstance3D.new(); var c := CylinderMesh.new(); c.top_radius = 0.06; c.bottom_radius = 0.06; c.height = 2.44
			p.mesh = c; p.material_override = post; p.position = Vector3(0, 1.22, s * 3.66); goal.add_child(p)
		var bar := MeshInstance3D.new(); var cb := CylinderMesh.new(); cb.top_radius = 0.06; cb.bottom_radius = 0.06; cb.height = 7.32
		bar.mesh = cb; bar.material_override = post; bar.rotation_degrees = Vector3(90, 0, 0); bar.position = Vector3(0, 2.44, 0); goal.add_child(bar)
		var net := MeshInstance3D.new(); var nb := BoxMesh.new(); nb.size = Vector3(2.0, 2.44, 7.32)
		var nm := StandardMaterial3D.new(); nm.albedo_color = Color(1, 1, 1, 0.18); nm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		net.mesh = nb; net.material_override = nm; net.position = Vector3(-1.0 if gx == 0.0 else 1.0, 1.22, 0); goal.add_child(net)

func _stadium() -> void:
	var crowd := ShaderMaterial.new(); crowd.shader = preload("res://shaders/crowd.gdshader")
	var roofm := StandardMaterial3D.new(); roofm.albedo_color = Color(0.14, 0.15, 0.18)
	var boardm := StandardMaterial3D.new(); boardm.albedo_color = Color(0.08, 0.1, 0.12)
	var sides := [[Vector3(W / 2, 0, -9), 0.0, W + 30], [Vector3(W / 2, 0, H + 9), 180.0, W + 30], [Vector3(-11, 0, H / 2), 90.0, H + 30], [Vector3(W + 11, 0, H / 2), -90.0, H + 30]]
	for s in sides:
		var root := Node3D.new(); root.position = s[0]; root.rotation_degrees.y = s[1]; add_child(root)
		var stand := MeshInstance3D.new(); var bx := BoxMesh.new(); bx.size = Vector3(s[2], 0.6, 24)
		stand.mesh = bx; stand.material_override = crowd
		stand.rotation_degrees.x = 31; stand.position = Vector3(0, 6.5, -10.5); root.add_child(stand)
		var roof := MeshInstance3D.new(); var rb := BoxMesh.new(); rb.size = Vector3(s[2], 0.5, 18)
		roof.mesh = rb; roof.material_override = roofm; roof.position = Vector3(0, 19.5, -14); roof.rotation_degrees.x = -8; root.add_child(roof)
		var board := MeshInstance3D.new(); var bb := BoxMesh.new(); bb.size = Vector3(s[2] - 30, 0.9, 0.12)
		board.mesh = bb; board.material_override = boardm; board.position = Vector3(0, 0.45, 3.2); root.add_child(board)
		var txt := Label3D.new(); txt.text = "ÁRBITRO DE CARICAS      APITO DOURADO      RELVADO VERDE      TAÇA DAS CARICAS"
		txt.font_size = 64; txt.pixel_size = 0.009; txt.modulate = Color(0.95, 0.82, 0.25); txt.position = Vector3(0, 0.45, 3.27)
		root.add_child(txt)
	for corner in [Vector3(-14, 0, -12), Vector3(W + 14, 0, -12), Vector3(-14, 0, H + 12), Vector3(W + 14, 0, H + 12)]:
		var pole := MeshInstance3D.new(); var pc := CylinderMesh.new(); pc.top_radius = 0.4; pc.bottom_radius = 0.6; pc.height = 34
		pole.mesh = pc; pole.material_override = roofm; pole.position = corner + Vector3(0, 17, 0); add_child(pole)
		var lamp := MeshInstance3D.new(); var lb := BoxMesh.new(); lb.size = Vector3(5, 3, 0.6)
		var lm := StandardMaterial3D.new(); lm.albedo_color = Color(1, 1, 0.95); lm.emission_enabled = true; lm.emission = Color(1, 0.98, 0.9); lm.emission_energy_multiplier = 3.0
		lamp.mesh = lb; lamp.material_override = lm; lamp.position = corner + Vector3(0, 34, 0); lamp.look_at_from_position(lamp.position, Vector3(W / 2, 0, H / 2)); add_child(lamp)

# ---- corpo físico: cada jogador tem cápsulas nos ossos (bacia, tronco, cabeça, braços, pernas, pés)
# [osso, alvo (osso ou deslocamento), raio, massa, limites x, y, z (graus)]
const SEG := [
	["root", "box", 0.0, 12.0, [-30, 30], [-30, 30], [-30, 30]],
	["spine03", "neck01", 0.13, 18.0, [-35, 25], [-25, 25], [-20, 20]],
	["head", Vector3(0, 0.2, 0.05), 0.105, 5.0, [-35, 35], [-50, 50], [-25, 25]],
	["upperarm01_L", "lowerarm01_L", 0.05, 2.2, [-110, 60], [-60, 60], [-80, 80]],
	["lowerarm01_L", "wrist_L", 0.042, 1.6, [-140, 0], [-5, 5], [-5, 5]],
	["upperarm01_R", "lowerarm01_R", 0.05, 2.2, [-110, 60], [-60, 60], [-80, 80]],
	["lowerarm01_R", "wrist_R", 0.042, 1.6, [-140, 0], [-5, 5], [-5, 5]],
	["upperleg01_L", "lowerleg01_L", 0.085, 8.0, [-100, 30], [-30, 30], [-35, 35]],
	["lowerleg01_L", "foot_L", 0.06, 3.5, [0, 140], [-5, 5], [-5, 5]],
	["foot_L", "foot", 0.0, 1.0, [-30, 30], [-10, 10], [-15, 15]],
	["upperleg01_R", "lowerleg01_R", 0.085, 8.0, [-100, 30], [-30, 30], [-35, 35]],
	["lowerleg01_R", "foot_R", 0.06, 3.5, [0, 140], [-5, 5], [-5, 5]],
	["foot_R", "foot", 0.0, 1.0, [-30, 30], [-10, 10], [-15, 15]],
]
# pontos usados para não deixar dois jogadores ocuparem o mesmo espaço e para manter os pés acima da relva
const PTS := [["root", 0.15, 0.0], ["spine01", 0.16, 0.0], ["head", 0.11, 0.0], ["lowerleg01_L", 0.07, 0.0], ["lowerleg01_R", 0.07, 0.0], ["foot_L", 0.065, 0.075], ["foot_R", 0.065, 0.075]]
const L_GROUND := 1
const L_PROXY := 2
const L_RAG := 4

func _shape_for(skel: Skeleton3D, seg: Array) -> Array:
	# devolve [forma, transformação no espaço do osso]
	var bi := skel.find_bone(seg[0])
	var o := skel.get_bone_global_rest(bi).origin
	var tgt = seg[1]
	if tgt is String and tgt == "box":
		var b := BoxShape3D.new(); b.size = Vector3(0.32, 0.22, 0.2)
		return [b, Transform3D(Basis(), Vector3(0, -0.03, 0.04))]
	if tgt is String and tgt == "foot":
		var f := BoxShape3D.new(); f.size = Vector3(0.1, 0.07, 0.25)
		return [f, Transform3D(Basis(), Vector3(0, -0.04, 0.06))]
	var v: Vector3
	if tgt is Vector3: v = tgt
	else:
		v = skel.get_bone_global_rest(skel.find_bone(tgt)).origin - o
		if seg[0].begins_with("lowerarm"): v *= 1.3
	var c := CapsuleShape3D.new(); c.radius = seg[2]; c.height = max(v.length() + seg[2] * 0.6, seg[2] * 2.01)
	if tgt is Vector3:
		var sp := SphereShape3D.new(); sp.radius = seg[2]
		return [sp, Transform3D(Basis(), v * 0.5)]
	var y := v.normalized()
	var x := y.cross(Vector3(0, 0, 1)); if x.length() < 0.1: x = y.cross(Vector3(1, 0, 0))
	x = x.normalized(); var z := x.cross(y).normalized()
	return [c, Transform3D(Basis(x, y, z), v * 0.5)]

func _player(kit: Dictionary, num: int, id: int) -> Dictionary:
	var node: Node3D = PLAYER.instantiate()
	node.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(node)
	var r := RandomNumberGenerator.new(); r.seed = id * 7919 + 13
	var mat := ShaderMaterial.new(); mat.shader = KIT
	mat.set_shader_parameter("skin_tex", load("res://assets/skin_%s.jpg" % SKINS[r.randi() % SKINS.size()]))
	mat.set_shader_parameter("shirt", kit.color); mat.set_shader_parameter("shirt2", kit.shirt2)
	mat.set_shader_parameter("shorts", kit.shorts); mat.set_shader_parameter("sock", kit.sock); mat.set_shader_parameter("trim", kit.dark)
	mat.set_shader_parameter("pat", kit.pat)
	mat.set_shader_parameter("hair", [Color("161310"), Color("2a1a10"), Color("4a2f1a"), Color("6b4a2b"), Color("b08850")][r.randi() % 5])
	for m in node.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_override = mat
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var skel: Skeleton3D = node.find_children("*", "Skeleton3D", true, false)[0]
	var bootm := StandardMaterial3D.new(); bootm.albedo_color = [Color("141414"), Color("f4f4f4"), Color("d8f23a"), Color("ff5a2c"), Color("2a7dff")][r.randi() % 5]; bootm.roughness = 0.35
	for f in ["foot_L", "foot_R"]:
		var ba := BoneAttachment3D.new(); ba.bone_name = f; skel.add_child(ba)
		var up := MeshInstance3D.new(); var sp := SphereMesh.new(); sp.radius = 1.0; sp.height = 2.0
		up.mesh = sp; up.scale = Vector3(0.052, 0.045, 0.14); up.position = Vector3(0, -0.035, 0.05); up.material_override = bootm; ba.add_child(up)
		var so := MeshInstance3D.new(); var sb := BoxMesh.new(); sb.size = Vector3(0.098, 0.014, 0.27)
		so.mesh = sb; so.position = Vector3(0, -0.07, 0.05); so.material_override = bootm; ba.add_child(so)
	# número nas costas
	var nb := BoneAttachment3D.new(); nb.bone_name = "spine02"; skel.add_child(nb)
	var lab := Label3D.new(); lab.text = str(num); lab.font_size = 160; lab.pixel_size = 0.0011; lab.outline_size = 10
	lab.modulate = Color(0.97, 0.97, 0.95); lab.outline_modulate = Color(0.05, 0.05, 0.08, 0.6)
	lab.position = Vector3(0, 0.05, -0.14); lab.rotation_degrees.y = 180; lab.double_sided = false
	nb.add_child(lab)
	var ap: AnimationPlayer = node.find_children("*", "AnimationPlayer", true, false)[0]
	ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	# esqueleto físico (fica parado até haver uma queda) e colisores que seguem a animação
	var sim := PhysicalBoneSimulator3D.new(); skel.add_child(sim)
	var bones: Array = []
	var proxies: Array = []
	var pm := PhysicsMaterial.new(); pm.friction = 0.9; pm.bounce = 0.0
	for seg in SEG:
		var sh := _shape_for(skel, seg)
		var pb := PhysicalBone3D.new(); pb.name = "pb_" + seg[0]
		sim.add_child(pb)
		pb.bone_name = seg[0]
		pb.mass = seg[3]; pb.friction = 0.9; pb.bounce = 0.0
		pb.linear_damp = 0.1; pb.angular_damp = 1.5
		pb.collision_layer = L_RAG; pb.collision_mask = L_GROUND | L_PROXY | L_RAG
		pb.joint_type = PhysicalBone3D.JOINT_TYPE_6DOF
		for ax_i in 3:
			var ax: String = ["x", "y", "z"][ax_i]
			var lim: Array = seg[4 + ax_i]
			pb.set("joint_constraints/%s/angular_limit_enabled" % ax, true)
			pb.set("joint_constraints/%s/angular_limit_lower" % ax, deg_to_rad(lim[0]))
			pb.set("joint_constraints/%s/angular_limit_upper" % ax, deg_to_rad(lim[1]))
		var cs := CollisionShape3D.new(); cs.shape = sh[0]; cs.transform = sh[1]
		pb.add_child(cs)
		bones.append(pb)
		# colisor animado (empurra quem estiver em queda)
		var ba2 := BoneAttachment3D.new(); ba2.bone_name = seg[0]; skel.add_child(ba2)
		var ab := AnimatableBody3D.new()
		ab.collision_layer = L_PROXY; ab.collision_mask = 0
		var cs2 := CollisionShape3D.new(); cs2.shape = sh[0]; cs2.transform = sh[1]
		ab.add_child(cs2); ba2.add_child(ab); ab.sync_to_physics = true
		proxies.append(ab)
	for i in bones.size():
		for j in range(i + 1, bones.size()): bones[i].add_collision_exception_with(bones[j])
	# para cada parte: parte-mãe física e a cadeia de ossos entre as duas (para o corpo seguir a animação de queda)
	var segp: Array = []
	for i in SEG.size():
		var bi := skel.find_bone(SEG[i][0])
		var chain: Array = [bi]
		var pi := -1
		var b := skel.get_bone_parent(bi)
		while b >= 0 and pi < 0:
			for j in SEG.size():
				if skel.find_bone(SEG[j][0]) == b: pi = j
			if pi < 0: chain.push_front(b); b = skel.get_bone_parent(b)
		segp.append([pi, chain])
	var pts: Array = []
	for q in PTS: pts.append([skel.find_bone(q[0]), q[1], q[2]])
	return {"node": node, "anim": ap, "state": "", "skel": skel, "sim": sim, "bones": bones, "proxies": proxies, "pts": pts,
		"segp": segp, "off": Vector2.ZERO, "rag": false, "ragT": 0.0, "sp": Vector3.ZERO, "sv": Vector3.ZERO, "lift": 0.0}

func _play(p: Dictionary, name: String, blend := 0.15, from := 0.0) -> void:
	if p.state == name: return
	p.state = name
	p.anim.play(name, blend)
	if from > 0.0: p.anim.seek(from, true)

func _place(p: Dictionary, pos: Vector2, dir: Vector2) -> void:
	pos += p.off
	p.node.position = Vector3(pos.x, p.lift, pos.y)
	p.node.rotation.y = atan2(dir.x, dir.y)

func _ragdoll(p: Dictionary, on: bool) -> void:
	p.rag = on; p.ragT = 0.0
	for ab in p.proxies: ab.collision_layer = 0 if on else L_PROXY
	if on:
		p.sim.influence = 0.0
		p.sim.physical_bones_start_simulation()
	else:
		p.sim.physical_bones_stop_simulation()
		p.sim.influence = 0.0

# pancada: o corpo de quem toca/é tocado reage (mola no tronco)
func _hit(p: Dictionary, ang: Vector3) -> void:
	p.sv += ang

func _restart() -> void:
	t = 0.0
	hit_done = false
	for p in [att, def] + extras:
		p.state = ""; p.off = Vector2.ZERO; p.sp = Vector3.ZERO; p.sv = Vector3.ZERO; p.lift = 0.0
		if p.rag: _ragdoll(p, false)
	_play(att, "run", 0.0); _play(def, "run", 0.0)
	for e in extras: _play(e, "jog", 0.0)

var hit_done := false
var dbg := {"minY": 99.0, "pen": 0.0}

func _process(delta: float) -> void:
	# pausa: o mundo físico para por completo (o motor não aceita passos de tempo nulos)
	get_tree().paused = paused
	Engine.time_scale = speed
	var dt := 0.0 if paused else delta
	t += dt
	if t > DUR + 0.8: _restart()
	# atacante: corre até ao toque; a partir daí o corpo é físico
	var vA := 5.4
	var ap: Vector2
	if t < TC: ap = P + A * vA * (t - TC)
	else: ap = P + A * vA * 0.02
	if not att.rag: _place(att, ap, A)
	# defesa: entra de lado, atrasado, com a perna esticada
	var vD := 8.2
	var C := P - D * 0.8
	var dp: Vector2
	if t < TC: dp = C - D * vD * (TC - t)
	else: dp = C + D * 2.0 * (1.0 - exp(-(t - TC) * 4.0))
	_place(def, dp, D)
	if t > TC - 0.62: _play(def, "kick", 0.1)
	if t > TC + 0.9: _play(def, "jog", 0.3)
	# outros: aproximam-se do lance
	for e in extras:
		var s: Vector2 = e.spot
		var to := (P - s).normalized()
		var k: float = clamp(t / DUR, 0.0, 1.0)
		_place(e, s + to * 6.0 * k, to)
	var all: Array = [att, def] + extras
	for p in all:
		if not p.rag: p.anim.advance(dt)
		_springs(p, dt)
	# o toque: o atacante perde o apoio e cai com a velocidade que trazia; o defesa sente a pancada
	if not hit_done and t >= TC:
		hit_done = true
		_ragdoll(att, true)
		_kick_body(att, Vector3(A.x, 0, A.y) * vA, Vector3(D.x, 0.15, D.y) * 3.2)
		_hit(def, Vector3(-2.2, 1.2, 0.0))
	if att.rag:
		att.ragT += dt
		att.sim.influence = clamp(att.ragT / 0.1, 0.0, 1.0)
	_ground(all)
	_separate(all)
	# bola
	var bp: Vector2
	if t < TC: bp = ap + A * (0.6 + 0.2 * abs(sin(t * 5.0)))
	else: bp = P + A * 0.6 + (A * 0.6 + D * 0.8).normalized() * 6.0 * (1.0 - exp(-(t - TC) * 1.4))
	ball.position = Vector3(bp.x, 0.11, bp.y)
	if not paused: ball.rotate_x(dt * 9.0)
	_camera()
	ui.text = "GODOT 4 · protótipo do lance 3D   |   %s   |   %s s   |   1 a tua vista · 2 vista ideal · 3 atrás · 4 perto · Espaço pausa · S lento · R repetir" % [["A TUA VISTA", "VISTA IDEAL", "ATRÁS DO LANCE", "DE PERTO"][cam_mode], ("%+.2f" % (t - TC)).replace(".", ",")]

# dá a cada parte do corpo a velocidade da corrida e empurra a perna tocada
func _kick_body(p: Dictionary, v: Vector3, legv: Vector3) -> void:
	var leg := "R"
	var dpos: Vector3 = def.skel.global_transform * def.skel.get_bone_global_pose(def.skel.find_bone("foot_R")).origin
	var dl: float = (p.skel.global_transform * p.skel.get_bone_global_pose(p.skel.find_bone("lowerleg01_L")).origin).distance_to(dpos)
	var dr: float = (p.skel.global_transform * p.skel.get_bone_global_pose(p.skel.find_bone("lowerleg01_R")).origin).distance_to(dpos)
	if dl < dr: leg = "L"
	p.kv = v; p.legv = legv; p.leg = leg
	await get_tree().physics_frame
	await get_tree().physics_frame
	for pb in p.bones:
		var n: String = pb.bone_name
		var vv: Vector3 = v
		if n.ends_with("_" + leg) and (n.begins_with("lowerleg") or n.begins_with("foot")): vv = v * 0.2 + legv
		pb.linear_velocity = vv
		if n == "spine03" or n == "head": pb.linear_velocity = v * 1.08 + Vector3(0, -0.3, 0)

# mola de reação no tronco (quem leva ou dá a pancada balança e recupera)
func _springs(p: Dictionary, dt: float) -> void:
	if p.rag or (p.sv.length() < 0.001 and p.sp.length() < 0.001): return
	p.sv += (-60.0 * p.sp - 9.0 * p.sv) * dt
	p.sp += p.sv * dt
	var sk: Skeleton3D = p.skel
	for b in [["spine03", 0.5], ["spine01", 0.35], ["neck01", 0.25]]:
		var i := sk.find_bone(b[0])
		sk.set_bone_pose_rotation(i, sk.get_bone_pose_rotation(i) * Quaternion.from_euler(p.sp * b[1]))

func _gpts(p: Dictionary) -> Array:
	var sk: Skeleton3D = p.skel
	var gt := sk.global_transform
	var out: Array = []
	for q in p.pts: out.append([gt * sk.get_bone_global_pose(q[0]).origin, q[1], q[2]])
	return out

# nenhuma parte do corpo animado fica abaixo da relva
func _ground(all: Array) -> void:
	for p in all:
		if p.rag: continue
		var low := 99.0
		for q in _gpts(p): low = min(low, q[0].y - (q[2] if q[2] > 0.0 else q[1]))
		var base: float = low - p.lift
		var want: float = max(0.0, -base)
		p.lift = want if want > p.lift else lerp(p.lift, want, 0.3)
		p.node.position.y = p.lift

# dois jogadores não ocupam o mesmo espaço: afastam-se; quem está caído é um obstáculo físico (contorna-se, não se atravessa)
func _rag_pts(p: Dictionary) -> Array:
	var out: Array = []
	for i in p.bones.size():
		var pb: PhysicalBone3D = p.bones[i]
		var cs: CollisionShape3D = pb.get_child(0)
		var r := 0.13 if i < 3 else 0.08
		out.append([pb.global_transform * cs.position, r, 0.0])
	return out

func _separate(all: Array) -> void:
	var g: Array = []
	for p in all: g.append(_rag_pts(p) if p.rag else _gpts(p))
	dbg.pen = 0.0
	for i in all.size():
		for j in range(i + 1, all.size()):
			if all[i].rag and all[j].rag: continue
			var push := Vector2.ZERO
			for a in g[i]:
				for b in g[j]:
					var dy: float = abs(a[0].y - b[0].y)
					var rr: float = a[1] + b[1]
					if dy > rr: continue
					var h := Vector2(a[0].x - b[0].x, a[0].z - b[0].z)
					var need := sqrt(max(rr * rr - dy * dy, 0.0))
					var d := h.length()
					if d < need:
						var n := h / d if d > 0.001 else Vector2(1, 0)
						var o := need - d
						dbg.pen = max(dbg.pen, o)
						if o > push.length(): push = n * o
			if push == Vector2.ZERO: continue
			var wi := 0.0 if all[i].rag else (1.0 if all[j].rag else 0.5)
			var wj := 0.0 if all[j].rag else (1.0 if all[i].rag else 0.5)
			all[i].off += push * wi; all[j].off -= push * wj
			all[i].node.position += Vector3(push.x, 0, push.y) * wi
			all[j].node.position -= Vector3(push.x, 0, push.y) * wj

# corpo ativo: durante a queda cada parte tenta seguir a pose da animação (braços à frente para amparar, cabeça levantada),
# mas é a física que manda: o chão e os outros jogadores travam o corpo
func _physics_process(pdt: float) -> void:
	if att.rag: _drive(att, "dive", att.ragT, 0.55 if att.ragT < 0.9 else 0.3)

func _anim_rot(an: Animation, bone: String, tm: float) -> Quaternion:
	var tr := an.find_track(NodePath("Jogador/Skeleton3D:" + bone), Animation.TYPE_ROTATION_3D)
	if tr < 0: return Quaternion.IDENTITY
	return an.rotation_track_interpolate(tr, tm)

func _drive(p: Dictionary, anim_name: String, tm: float, strength: float) -> void:
	var an: Animation = p.anim.get_animation(anim_name)
	tm = min(tm, an.length - 0.01)
	var sk: Skeleton3D = p.skel
	for i in SEG.size():
		var info: Array = p.segp[i]
		if info[0] < 0: continue
		var nm: String = SEG[i][0]
		var s := strength
		if p.get("leg", "") != "" and nm.ends_with("_" + p.leg) and (nm.begins_with("lowerleg") or nm.begins_with("foot")) and tm < 0.3: s = 0.0
		if s <= 0.0: continue
		var rel := Quaternion.IDENTITY
		for b in info[1]: rel = rel * _anim_rot(an, sk.get_bone_name(b), tm)
		var par: PhysicalBone3D = p.bones[info[0]]
		var ch: PhysicalBone3D = p.bones[i]
		var want := par.global_basis.get_rotation_quaternion() * rel
		var cur := ch.global_basis.get_rotation_quaternion()
		var err := want * cur.inverse()
		if err.w < 0.0: err = -err
		var ang := err.get_angle()
		var w := par.angular_velocity
		if ang > 0.001: w += err.get_axis().normalized() * ang * 14.0
		ch.angular_velocity = ch.angular_velocity.lerp(w, s)

func _body_pos(p: Dictionary) -> Vector3:
	if p.rag: return p.bones[0].global_position
	return p.node.position

func _camera() -> void:
	var look := Vector3(P.x, 0.9, P.y)
	if cam_mode == 0:
		var shake := Vector3(sin(t * 3.1) * 0.02, sin(t * 4.3) * 0.015, 0)
		cam.fov = 38
		cam.look_at_from_position(Vector3(REF.x, 1.75, REF.y) + shake, look)
	elif cam_mode == 1:
		var side := Vector2(-A.y, A.x)
		var a3: Vector3 = _body_pos(att)
		var d3: Vector3 = _body_pos(def)
		var mid := Vector2((a3.x + d3.x) * 0.5, (a3.z + d3.z) * 0.5)
		var gap := Vector2(a3.x - d3.x, a3.z - d3.z).length()
		var c2 := mid + side * (6.0 + gap * 0.6)
		cam.fov = 45
		cam.look_at_from_position(Vector3(c2.x, 1.4, c2.y), Vector3(mid.x, 0.7, mid.y))
	elif cam_mode == 3:
		var bp3 := _body_pos(att)
		cam.fov = 40
		cam.look_at_from_position(Vector3(bp3.x - A.y * 4.6 + A.x * 1.2, 1.7, bp3.z + A.x * 4.6 + A.y * 1.2), Vector3(bp3.x, 0.4, bp3.z))
	else:
		var c3 := P - A * 9.0 + Vector2(0, 1.5)
		cam.fov = 40
		cam.look_at_from_position(Vector3(c3.x, 1.6, c3.y), Vector3(P.x, 0.6, P.y))

func _ui() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	ui = Label.new(); ui.position = Vector2(14, 10)
	ui.add_theme_font_size_override("font_size", 15)
	ui.add_theme_color_override("font_color", Color(0.97, 0.97, 0.94))
	ui.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8)); ui.add_theme_constant_override("outline_size", 6)
	layer.add_child(ui)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed:
		match e.keycode:
			KEY_1: cam_mode = 0
			KEY_2: cam_mode = 1
			KEY_3: cam_mode = 2
			KEY_SPACE: paused = not paused
			KEY_S: speed = 0.25 if speed == 1.0 else 1.0
			KEY_R: _restart()
	if e is InputEventMouseButton and e.pressed:
		cam_mode = (cam_mode + 1) % 4
	if e is InputEventScreenTouch and e.pressed:
		cam_mode = (cam_mode + 1) % 4
