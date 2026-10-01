class_name Jogador
extends RefCounted
# Um jogador 3D: corpo MakeHuman com animações CMU, corpo físico (cápsulas nos ossos), queda ativa
# (a física manda, mas o corpo tenta seguir uma pose), pés e mãos com IK, levantar-se do chão.

const PLAYER := preload("res://assets/jogador.glb")
const KIT := preload("res://shaders/kit.gdshader")
const SKINS := ["light", "mid", "brown", "dark"]
const L_GROUND := 1
const L_PROXY := 2
const L_RAG := 4

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
# pontos para não ocupar o espaço de outro jogador e para os pés ficarem em cima da relva
const PTS := [["root", 0.15, 0.0], ["spine01", 0.16, 0.0], ["head", 0.11, 0.0], ["lowerleg01_L", 0.07, 0.0], ["lowerleg01_R", 0.07, 0.0], ["foot_L", 0.065, 0.075], ["foot_R", 0.065, 0.075],
	["upperarm01_L", 0.06, 0.0], ["upperarm01_R", 0.06, 0.0], ["lowerarm01_L", 0.05, 0.0], ["lowerarm01_R", 0.05, 0.0], ["wrist_L", 0.05, 0.0], ["wrist_R", 0.05, 0.0]]

static var clip_speed := {}       # velocidade a que cada ciclo de corrida anda no chão (para os pés não deslizarem)

var node: Node3D
var skel: Skeleton3D
var anim: AnimationPlayer
var sim: PhysicalBoneSimulator3D
var mat: ShaderMaterial
var bones: Array = []
var proxies: Array = []
var segp: Array = []
var pts: Array = []
var bi := {}                      # nome do osso -> índice
var team := 0
var num := 0

var state := ""
var phase := "anim"               # anim | queda | chao | levantar
var pos := Vector2.ZERO
var dir := Vector2(0, 1)
var speed := 0.0
var off := Vector2.ZERO
var lift := 0.0
var rag := false
var ragT := 0.0
var drive_anim := "dive"
var drive_k := 0.55
var hurt := 0.0                   # 0 = nada, 1 = muito queixoso
var hurt_leg := "R"
var groundT := 0.0
var getupT := 0.0
var getup_anim := ""
var sp := Vector3.ZERO            # mola do tronco (pancadas)
var sv := Vector3.ZERO
var stag := Vector2.ZERO          # desequilíbrio (o corpo é empurrado e recupera)
var stagv := Vector2.ZERO
var ik := {}                      # "foot_R" -> [alvo global, peso]
var layer := ""                   # animação só do tronco por cima da corrida (puxar, ser puxado)
var layer_w := 0.0
var lean := Vector3.ZERO          # inclinação extra do tronco (ombro a ombro)
var label: Label3D

func _init(parent: Node3D, kit: Dictionary, n: int, id: int, tm: int) -> void:
	num = n; team = tm
	node = PLAYER.instantiate()
	node.process_mode = Node.PROCESS_MODE_PAUSABLE
	parent.add_child(node)
	var r := RandomNumberGenerator.new(); r.seed = id * 7919 + 13
	mat = ShaderMaterial.new(); mat.shader = KIT
	mat.set_shader_parameter("skin_tex", load("res://assets/skin_%s.jpg" % SKINS[r.randi() % SKINS.size()]))
	mat.set_shader_parameter("shirt", kit.color); mat.set_shader_parameter("shirt2", kit.shirt2)
	mat.set_shader_parameter("shorts", kit.shorts); mat.set_shader_parameter("sock", kit.sock); mat.set_shader_parameter("trim", kit.dark)
	mat.set_shader_parameter("pat", kit.pat)
	mat.set_shader_parameter("hair", [Color("161310"), Color("2a1a10"), Color("4a2f1a"), Color("6b4a2b"), Color("b08850")][r.randi() % 5])
	mat.set_shader_parameter("phase", r.randf() * 10.0)
	for m in node.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_override = mat
		(m as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		# o corpo caído pode afastar-se da origem do nó: não deixar o motor escondê-lo
		(m as MeshInstance3D).custom_aabb = AABB(Vector3(-30, -3, -30), Vector3(60, 8, 60))
	skel = node.find_children("*", "Skeleton3D", true, false)[0]
	for i in skel.get_bone_count(): bi[skel.get_bone_name(i)] = i
	var bootm := StandardMaterial3D.new(); bootm.albedo_color = [Color("141414"), Color("f4f4f4"), Color("d8f23a"), Color("ff5a2c"), Color("2a7dff")][r.randi() % 5]; bootm.roughness = 0.35
	for f in ["foot_L", "foot_R"]:
		var ba := BoneAttachment3D.new(); ba.bone_name = f; skel.add_child(ba)
		var up := MeshInstance3D.new(); var sph := SphereMesh.new(); sph.radius = 1.0; sph.height = 2.0
		up.mesh = sph; up.scale = Vector3(0.052, 0.045, 0.14); up.position = Vector3(0, -0.035, 0.05); up.material_override = bootm; ba.add_child(up)
		var so := MeshInstance3D.new(); var sb := BoxMesh.new(); sb.size = Vector3(0.098, 0.014, 0.27)
		so.mesh = sb; so.position = Vector3(0, -0.07, 0.05); so.material_override = bootm; ba.add_child(so)
	var nb := BoneAttachment3D.new(); nb.bone_name = "spine02"; skel.add_child(nb)
	var lab := Label3D.new(); lab.text = str(n); lab.font_size = 160; lab.pixel_size = 0.0011; lab.outline_size = 10
	lab.modulate = Color(0.97, 0.97, 0.95); lab.outline_modulate = Color(0.05, 0.05, 0.08, 0.6)
	lab.position = Vector3(0, 0.05, -0.14); lab.rotation_degrees.y = 180; lab.double_sided = false
	nb.add_child(lab)
	label = lab
	anim = node.find_children("*", "AnimationPlayer", true, false)[0]
	anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	_build_body()
	for q in PTS: pts.append([bi[q[0]], q[1], q[2]])
	if clip_speed.is_empty():
		for c in ["run", "jog"]: clip_speed[c] = _measure_speed(c)

# muda de equipamento e número (o mesmo corpo serve para qualquer jogador do jogo)
func set_kit(kit: Dictionary, n: int, tm: int) -> void:
	num = n; team = tm; label.text = str(n)
	mat.set_shader_parameter("shirt", kit.color); mat.set_shader_parameter("shirt2", kit.shirt2)
	mat.set_shader_parameter("shorts", kit.shorts); mat.set_shader_parameter("sock", kit.sock); mat.set_shader_parameter("trim", kit.dark)
	mat.set_shader_parameter("pat", kit.pat)

# ---------- corpo físico ----------
func _shape_for(seg: Array) -> Array:
	var o := skel.get_bone_global_rest(bi[seg[0]]).origin
	var tgt = seg[1]
	if tgt is String and tgt == "box":
		var b := BoxShape3D.new(); b.size = Vector3(0.32, 0.22, 0.2)
		return [b, Transform3D(Basis(), Vector3(0, -0.03, 0.04))]
	if tgt is String and tgt == "foot":
		var f := BoxShape3D.new(); f.size = Vector3(0.1, 0.07, 0.25)
		return [f, Transform3D(Basis(), Vector3(0, -0.04, 0.06))]
	if tgt is Vector3:
		var sph := SphereShape3D.new(); sph.radius = seg[2]
		return [sph, Transform3D(Basis(), tgt * 0.5)]
	var v: Vector3 = skel.get_bone_global_rest(bi[tgt]).origin - o
	if seg[0].begins_with("lowerarm"): v *= 1.3
	var c := CapsuleShape3D.new(); c.radius = seg[2]; c.height = max(v.length() + seg[2] * 0.6, seg[2] * 2.01)
	var y := v.normalized()
	var x := y.cross(Vector3(0, 0, 1)); if x.length() < 0.1: x = y.cross(Vector3(1, 0, 0))
	x = x.normalized(); var z := x.cross(y).normalized()
	return [c, Transform3D(Basis(x, y, z), v * 0.5)]

func _build_body() -> void:
	sim = PhysicalBoneSimulator3D.new(); skel.add_child(sim)
	for seg in SEG:
		var sh := _shape_for(seg)
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
		# colisor que segue a animação: empurra quem estiver caído
		var ba2 := BoneAttachment3D.new(); ba2.bone_name = seg[0]; skel.add_child(ba2)
		var ab := AnimatableBody3D.new()
		ab.collision_layer = L_PROXY; ab.collision_mask = 0
		var cs2 := CollisionShape3D.new(); cs2.shape = sh[0]; cs2.transform = sh[1]
		ab.add_child(cs2); ba2.add_child(ab); ab.sync_to_physics = true
		proxies.append(ab)
	for i in bones.size():
		for j in range(i + 1, bones.size()): bones[i].add_collision_exception_with(bones[j])
	# parte-mãe física e a cadeia de ossos entre as duas
	for i in SEG.size():
		var b0: int = bi[SEG[i][0]]
		var chain: Array = [b0]
		var pi := -1
		var b := skel.get_bone_parent(b0)
		while b >= 0 and pi < 0:
			for j in SEG.size():
				if bi[SEG[j][0]] == b: pi = j
			if pi < 0: chain.push_front(b); b = skel.get_bone_parent(b)
		segp.append([pi, chain])

# ---------- animação ----------
func play(name: String, blend := 0.15, from := 0.0) -> void:
	if state == name: return
	state = name
	anim.play(name, blend)
	if from > 0.0: anim.seek(from, true)

func anim_rot(an: Animation, bone: String, tm: float) -> Quaternion:
	var tr := an.find_track(NodePath("Jogador/Skeleton3D:" + bone), Animation.TYPE_ROTATION_3D)
	if tr < 0: return Quaternion.IDENTITY
	return an.rotation_track_interpolate(tr, tm)

# pose de uma animação no espaço do modelo, sem a aplicar (para medir passadas e alinhar o levantar)
func fk(name: String, tm: float) -> Array:
	var an := anim.get_animation(name)
	var out: Array = []
	var ptr := an.find_track(NodePath("Jogador/Skeleton3D:root"), Animation.TYPE_POSITION_3D)
	for i in skel.get_bone_count():
		var p := skel.get_bone_parent(i)
		var loc := Transform3D(Basis(anim_rot(an, skel.get_bone_name(i), tm)), skel.get_bone_rest(i).origin)
		if i == 0 and ptr >= 0: loc.origin = an.position_track_interpolate(ptr, tm)
		out.append(loc if p < 0 else out[p] * loc)
	return out

func _measure_speed(name: String) -> float:
	var an := anim.get_animation(name)
	var n := 40
	var tot := 0.0
	var cnt := 0
	var prev: Array = fk(name, 0.0)
	for k in range(1, n):
		var tm := an.length * k / n
		var cur: Array = fk(name, tm)
		var fl: Vector3 = cur[bi["foot_L"]].origin
		var fr: Vector3 = cur[bi["foot_R"]].origin
		var low := "foot_L" if fl.y < fr.y else "foot_R"
		var dz: float = (prev[bi[low]].origin.z - cur[bi[low]].origin.z) / (an.length / n)
		if dz > 0.0: tot += dz; cnt += 1
		prev = cur
	return tot / max(cnt, 1)

# coloca o jogador (posição, direção, velocidade) e acerta a cadência da passada à velocidade
func move(p: Vector2, d: Vector2, v: float) -> void:
	pos = p; dir = d; speed = v
	if rag: return
	var q := p + off + stag
	node.position = Vector3(q.x, lift, q.y)
	node.rotation.y = atan2(d.x, d.y)
	if clip_speed.has(state) and v > 0.3: anim.speed_scale = clamp(v / clip_speed[state], 0.6, 1.45)
	else: anim.speed_scale = 1.0

func update(dt: float, t: float) -> void:
	if phase == "levantar":
		_getup_step(dt)
		return
	if rag and phase != "levantar":
		ragT += dt
		sim.influence = clamp(ragT / 0.1, 0.0, 1.0)
		var pv: Vector3 = bones[0].linear_velocity
		if phase == "queda" and ragT > 1.0 and pv.length() < 0.6: phase = "chao"; groundT = 0.0
		if phase == "chao": groundT += dt
		return
	anim.advance(dt)
	_layers(t)
	_springs(dt)
	_stagger(dt)
	_ik()

# tronco de outra animação por cima das pernas a correr (puxar a camisola, ser agarrado)
func _layers(t: float) -> void:
	if layer == "" or layer_w <= 0.0: return
	var an := anim.get_animation(layer)
	var tm := fmod(t, an.length * 0.6) + an.length * 0.2
	for b in ["spine03", "spine02", "spine01", "neck01", "clavicle_L", "upperarm01_L", "lowerarm01_L", "clavicle_R", "upperarm01_R", "lowerarm01_R"]:
		var i: int = bi[b]
		skel.set_bone_pose_rotation(i, skel.get_bone_pose_rotation(i).slerp(anim_rot(an, b, tm), layer_w))

func hit(ang: Vector3) -> void:
	sv += ang

func push(v: Vector2) -> void:
	stagv += v

func _springs(dt: float) -> void:
	sv += (-60.0 * sp - 9.0 * sv) * dt
	sp += sv * dt
	var tot := sp + lean
	if tot.length() < 0.001: return
	for b in [["spine03", 0.5], ["spine01", 0.35], ["neck01", 0.15]]:
		var i: int = bi[b[0]]
		skel.set_bone_pose_rotation(i, skel.get_bone_pose_rotation(i) * Quaternion.from_euler(tot * b[1]))

# empurrado: o corpo desloca-se e volta, como quem perde e recupera o equilíbrio
func _stagger(dt: float) -> void:
	stagv += (-14.0 * stag - 5.0 * stagv) * dt
	stag += stagv * dt
	if stagv.length() > 0.05:
		var loc := Vector2(stagv.dot(Vector2(dir.y, -dir.x)), stagv.dot(dir))
		sp += Vector3(-loc.y, 0, loc.x) * 0.06 * dt * 10.0

# IK de duas articulações (anca-joelho-tornozelo ou ombro-cotovelo-pulso), sem mexer na direção do joelho
func two_bone(b0: String, b1: String, b2: String, target_world: Vector3, w: float) -> void:
	if w <= 0.0: return
	var inv := skel.global_transform.affine_inverse()
	var T := inv * target_world
	var i0: int = bi[b0]; var i1: int = bi[b1]; var i2: int = bi[b2]
	var g0 := skel.get_bone_global_pose(i0); var g1 := skel.get_bone_global_pose(i1); var g2 := skel.get_bone_global_pose(i2)
	var H := g0.origin; var K := g1.origin; var A := g2.origin
	T = A.lerp(T, w)
	var a := H.distance_to(K); var b := K.distance_to(A)
	var d: float = clamp(H.distance_to(T), abs(a - b) + 0.01, a + b - 0.002)
	var u := (T - H).normalized()
	var pole := (K - H) - u * (K - H).dot(u)
	if pole.length() < 0.001: pole = Vector3(0, 0, 1) - u * u.z
	pole = pole.normalized()
	var ca: float = clamp((a * a + d * d - b * b) / (2.0 * a * d), -1.0, 1.0)
	var K2 := H + u * (a * ca) + pole * (a * sqrt(1.0 - ca * ca))
	_aim(i0, K - H, K2 - H)
	g1 = skel.get_bone_global_pose(i1); g2 = skel.get_bone_global_pose(i2)
	var T2 := H + u * d
	_aim(i1, g2.origin - g1.origin, T2 - g1.origin)

func _aim(i: int, from: Vector3, to: Vector3) -> void:
	if from.length() < 1e-5 or to.length() < 1e-5: return
	var q := Quaternion(from.normalized(), to.normalized())
	var g := skel.get_bone_global_pose(i)
	var pb := Basis.IDENTITY
	var p := skel.get_bone_parent(i)
	if p >= 0: pb = skel.get_bone_global_pose(p).basis
	var nb := Basis(q) * g.basis
	skel.set_bone_pose_rotation(i, (pb.inverse() * nb).get_rotation_quaternion())

func _ik() -> void:
	for k in ik.keys():
		var e: Array = ik[k]
		if e[1] <= 0.0: continue
		match k:
			"foot_L": two_bone("upperleg01_L", "lowerleg01_L", "foot_L", e[0], e[1])
			"foot_R": two_bone("upperleg01_R", "lowerleg01_R", "foot_R", e[0], e[1])
			"wrist_L": two_bone("upperarm01_L", "lowerarm01_L", "wrist_L", e[0], e[1])
			"wrist_R": two_bone("upperarm01_R", "lowerarm01_R", "wrist_R", e[0], e[1])

func bone_world(name: String) -> Vector3:
	if rag:
		for pb in bones:
			if pb.bone_name == name: return pb.global_position
	return skel.global_transform * skel.get_bone_global_pose(bi[name]).origin

func body_pos() -> Vector3:
	if rag: return bones[0].global_position
	if phase == "levantar": return skel.global_transform * skel.get_bone_global_pose(0).origin * Vector3(1, 0, 1)
	return node.position

# ---------- queda ----------
func fall(v: Vector3, hit_bones: Array, hit_v: Vector3, anim_name := "dive", k := 0.55, spin := Vector3.ZERO) -> void:
	rag = true; ragT = 0.0; phase = "queda"
	drive_anim = anim_name; drive_k = k
	for ab in proxies: ab.collision_layer = 0
	sim.influence = 0.0
	sim.physical_bones_start_simulation()
	await node.get_tree().physics_frame
	await node.get_tree().physics_frame
	for pb in bones:
		var n: String = pb.bone_name
		var vv := v
		if n in hit_bones: vv = v * 0.2 + hit_v
		pb.linear_velocity = vv
		pb.angular_velocity = spin
		if n == "spine03" or n == "head": pb.linear_velocity = v * 1.08 + Vector3(0, -0.3, 0)

# corpo ativo: cada parte tenta seguir a pose alvo; a física (chão, outros jogadores) tem a última palavra
func physics_step(_pdt: float, t: float) -> void:
	if not rag or phase == "levantar": return
	if phase == "queda": _drive(drive_anim, ragT, drive_k if ragT < 0.9 else 0.3, {})
	elif phase == "chao":
		if hurt > 0.0: _drive(drive_anim, 9.0, 0.22, _hurt_pose(t))
		else: _drive(drive_anim, 9.0, 0.15, {})

# queixoso no chão: agarra a perna tocada, encolhe-a e balança
func _hurt_pose(t: float) -> Dictionary:
	var s := hurt_leg
	var o := "L" if s == "R" else "R"
	var rock := sin(t * 2.6) * 0.25 * hurt
	return {
		"upperleg01_" + s: Quaternion.from_euler(Vector3(deg_to_rad(-75), 0, 0)),
		"lowerleg01_" + s: Quaternion.from_euler(Vector3(deg_to_rad(105), 0, 0)),
		"upperleg01_" + o: Quaternion.from_euler(Vector3(deg_to_rad(-35), 0, 0)),
		"lowerleg01_" + o: Quaternion.from_euler(Vector3(deg_to_rad(50), 0, 0)),
		"upperarm01_L": Quaternion.from_euler(Vector3(deg_to_rad(-55), 0, deg_to_rad(-20))),
		"upperarm01_R": Quaternion.from_euler(Vector3(deg_to_rad(-55), 0, deg_to_rad(20))),
		"lowerarm01_L": Quaternion.from_euler(Vector3(deg_to_rad(-70), 0, 0)),
		"lowerarm01_R": Quaternion.from_euler(Vector3(deg_to_rad(-70), 0, 0)),
		"spine03": Quaternion.from_euler(Vector3(deg_to_rad(-25), rock, rock * 0.6)),
		"head": Quaternion.from_euler(Vector3(deg_to_rad(-20), 0, 0)),
	}

func _drive(anim_name: String, tm: float, strength: float, custom: Dictionary) -> void:
	var an: Animation = anim.get_animation(anim_name)
	tm = min(tm, an.length - 0.01)
	for i in SEG.size():
		var info: Array = segp[i]
		if info[0] < 0: continue
		var nm: String = SEG[i][0]
		var s := strength
		if phase == "queda" and nm.ends_with("_" + hurt_leg) and (nm.begins_with("lowerleg") or nm.begins_with("foot")) and tm < 0.3: s = 0.0
		if s <= 0.0: continue
		var rel := Quaternion.IDENTITY
		if custom.has(nm): rel = custom[nm]
		else:
			for b in info[1]: rel = rel * anim_rot(an, skel.get_bone_name(b), tm)
		var par: PhysicalBone3D = bones[info[0]]
		var ch: PhysicalBone3D = bones[i]
		var want := par.global_basis.get_rotation_quaternion() * rel
		var cur := ch.global_basis.get_rotation_quaternion()
		var err := want * cur.inverse()
		if err.w < 0.0: err = -err
		var ang := err.get_angle()
		var w := par.angular_velocity
		if ang > 0.001: w += err.get_axis().normalized() * ang * 14.0
		ch.angular_velocity = ch.angular_velocity.lerp(w, s)

# ---------- levantar-se ----------
func get_up() -> void:
	if phase != "chao": return
	var chest: PhysicalBone3D = bones[1]
	var front := chest.global_basis.z.y < 0.0       # peito virado para o chão
	getup_anim = "getup_front" if front else "getup_back"
	var pel: Vector3 = bones[0].global_position
	var head: Vector3 = bones[2].global_position
	var hw := Vector2(head.x - pel.x, head.z - pel.z)
	var f0: Array = fk(getup_anim, 0.0)
	var hm: Vector3 = f0[bi["head"]].origin - f0[0].origin
	var yaw := atan2(hw.x, hw.y) - atan2(hm.x, hm.z)
	var r0: Vector3 = Basis(Vector3.UP, yaw) * f0[0].origin
	node.rotation.y = yaw
	node.position = Vector3(pel.x - r0.x, 0.0, pel.z - r0.z)
	lift = 0.0; stag = Vector2.ZERO; stagv = Vector2.ZERO; off = Vector2.ZERO
	state = ""
	anim.speed_scale = 1.0
	play(getup_anim, 0.0)
	anim.advance(0.0)
	phase = "levantar"; getupT = 0.0

func _getup_step(dt: float) -> void:
	getupT += dt
	anim.advance(dt)
	# a captura não traz a altura certa: o ponto mais baixo do corpo fica sempre assente na relva
	var low := 99.0
	for i in skel.get_bone_count(): low = min(low, skel.get_bone_global_pose(i).origin.y)
	node.position.y = 0.07 - low
	if rag:
		sim.influence = clamp(1.0 - getupT / 0.45, 0.0, 1.0)
		if getupT >= 0.45:
			sim.physical_bones_stop_simulation()
			rag = false
			for ab in proxies: ab.collision_layer = L_PROXY
	if getupT >= anim.get_animation(getup_anim).length - 0.05:
		# fica de pé onde a animação o deixou
		var f1: Array = fk(getup_anim, anim.get_animation(getup_anim).length)
		var r1: Vector3 = node.global_transform.basis * f1[0].origin
		pos = Vector2(node.position.x + r1.x, node.position.z + r1.z)
		phase = "anim"
		play("idle", 0.3)
		speed = 0.0
		dir = Vector2(sin(node.rotation.y), cos(node.rotation.y))
		node.position = Vector3(pos.x, 0, pos.y)

func reset() -> void:
	if rag: sim.physical_bones_stop_simulation()
	rag = false; phase = "anim"; ragT = 0.0
	sim.influence = 0.0
	for ab in proxies: ab.collision_layer = L_PROXY
	state = ""; off = Vector2.ZERO; lift = 0.0; sp = Vector3.ZERO; sv = Vector3.ZERO
	stag = Vector2.ZERO; stagv = Vector2.ZERO; ik.clear(); layer = ""; layer_w = 0.0; lean = Vector3.ZERO; hurt = 0.0

# ---------- contacto com o chão e com os outros ----------
func gpts() -> Array:
	var out: Array = []
	if rag:
		for i in bones.size():
			var pb: PhysicalBone3D = bones[i]
			var cs: CollisionShape3D = pb.get_child(0)
			out.append([pb.global_transform * cs.position, 0.13 if i < 3 else 0.08, 0.0])
		return out
	var gt := skel.global_transform
	for q in pts: out.append([gt * skel.get_bone_global_pose(q[0]).origin, q[1], q[2]])
	return out

func ground() -> void:
	if rag or phase == "levantar": return
	var low := 99.0
	for q in gpts(): low = min(low, q[0].y - (q[2] if q[2] > 0.0 else q[1]))
	var base: float = low - lift
	var want: float = max(0.0, -base)
	lift = want if want > lift else lerp(lift, want, 0.3)
	node.position.y = lift
