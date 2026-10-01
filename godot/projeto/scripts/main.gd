extends Node3D
# Árbitro de Caricas em Godot 4: lances 3D com corpo físico (Jolt), queda ativa, IK de pés e mãos, levantar-se.
# Teclas: N lance seguinte · R repetir (novo toque, nova força) · 1-4 câmaras · Espaço pausa · S lento

const W := 105.0
const H := 68.0
const LANCES := ["Entrada", "Empurrão nas costas", "Puxão de camisola", "Ombro a ombro"]
const AZUL := {"color": Color("3569dc"), "dark": Color("1d3f8f"), "shorts": Color("f1f1f1"), "sock": Color("1d3f8f"), "pat": 0.0, "shirt2": Color("f1f1f1")}
const LARANJA := {"color": Color("ee7d2c"), "dark": Color("a4521a"), "shorts": Color("23242a"), "sock": Color("ee7d2c"), "pat": 1.0, "shirt2": Color("23242a")}

var t := 0.0
var speed := 1.0
var paused := false
var cam_mode := 1         # 0 = a tua vista, 1 = vista ideal, 2 = atrás, 3 = de perto
var cam: Camera3D
var ball: MeshInstance3D
var att: Jogador
var def: Jogador
var extras: Array = []
var ui: Label
var ui2: Label
var rng := RandomNumberGenerator.new()
var lance := 0
var hi_q := false          # computador (Forward+): sombras suaves, relva com volume

var P := Vector2(60, 30)   # ponto do contacto
var A := Vector2(-1, 0)    # direção do atacante
var D := Vector2.ZERO      # direção do defesa
var REF := Vector2(70, 46)
var TC := 2.2
var DUR := 9.0
var vA := 5.4
var vD := 8.2
var force := 1.0           # força do toque (0,5 leve … 1,5 muito forte)
var sim_dive := false      # simulação: atira-se sem toque que o justifique
var outcome := ""
var verdict := ""
var side := 1.0
var hit_done := false
var bpos := Vector2.ZERO   # bola
var bvel := Vector2.ZERO
var free_ball := false
var touchT := 0.0
var dbg := {"pen": 0.0}
var ps := 0.0              # distância percorrida pelo atacante no puxão

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hi_q = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	rng.randomize()
	_world()
	_stadium()
	if hi_q: _grass()
	att = Jogador.new(self, LARANJA, 9, 3, 1)
	def = Jogador.new(self, AZUL, 4, 8, 0)
	var spots := [Vector2(68, 22), Vector2(52, 40), Vector2(75, 33), Vector2(48, 24)]
	for i in spots.size():
		var home := i % 2 == 0
		var e := Jogador.new(self, AZUL if home else LARANJA, [2, 7, 5, 10][i], 20 + i, 0 if home else 1)
		e.set_meta("spot", spots[i])
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
	if hi_q:
		# computador: sombra suave (penumbra real), oclusão de ambiente e luz indireta no ecrã
		sun.light_angular_distance = 0.6; sun.shadow_blur = 1.0
		env.ssao_enabled = true; env.ssao_radius = 0.6; env.ssao_intensity = 1.6
		env.ssil_enabled = true; env.ssil_intensity = 0.6
		env.tonemap_mode = Environment.TONE_MAPPER_ACES; env.tonemap_exposure = 1.0
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
	add_child(sun)
	var pitch := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(W + 24, H + 24)
	pitch.mesh = pm; pitch.position = Vector3(W / 2, 0, H / 2)
	var mat := ShaderMaterial.new(); mat.shader = preload("res://shaders/pitch.gdshader")
	pitch.material_override = mat
	add_child(pitch)
	var ground := StaticBody3D.new(); ground.collision_layer = Jogador.L_GROUND; ground.collision_mask = 0
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

# relva com volume (só na versão de computador): tufos com vento à volta do lance
func _grass() -> void:
	var blade := ArrayMesh.new()
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var a := k * PI / 3.0
		var dx := Vector3(cos(a), 0, sin(a)) * 0.0045
		st.set_uv(Vector2(0, 0)); st.add_vertex(-dx)
		st.set_uv(Vector2(1, 0)); st.add_vertex(dx)
		st.set_uv(Vector2(0.5, 1)); st.add_vertex(Vector3(0, 0.032, 0))
	st.generate_normals(); blade = st.commit()
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.mesh = blade
	var n := 420000
	mm.instance_count = n
	var r := RandomNumberGenerator.new(); r.seed = 7
	for i in n:
		var p := P + Vector2(r.randf_range(-16, 16), r.randf_range(-11, 11))
		# as linhas pintadas ficam à vista
		if abs(p.x - W * 0.5) < 0.2 or abs(p.distance_to(Vector2(W * 0.5, H * 0.5)) - 9.15) < 0.2: p.y = -50.0
		var b := Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(1, r.randf_range(0.6, 1.5), 1))
		mm.set_instance_transform(i, Transform3D(b, Vector3(p.x, 0, p.y)))
	var mi := MultiMeshInstance3D.new(); mi.multimesh = mm
	var gm := ShaderMaterial.new(); gm.shader = preload("res://shaders/grass.gdshader")
	mi.material_override = gm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

# ---------- lances ----------
func _restart() -> void:
	t = 0.0
	hit_done = false
	free_ball = false
	outcome = ""; verdict = ""
	for p in [att, def] + extras: p.reset()
	force = rng.randf_range(0.45, 1.55)
	sim_dive = false
	side = 1.0 if rng.randf() < 0.5 else -1.0
	TC = 2.2; vA = 5.4
	match lance:
		0:
			sim_dive = rng.randf() < 0.25
			var phi := deg_to_rad(rng.randf_range(25.0, 75.0))
			D = A.rotated(-phi * side)
			vD = rng.randf_range(6.2, 9.6)
			force = vD / 8.2 * (0.55 + 0.6 * sin(phi)) * rng.randf_range(0.85, 1.15)
			verdict = "ângulo %d°, defesa a %.1f m/s" % [int(rad_to_deg(phi)), vD]
		1:
			D = A
			vD = 6.8
		2:
			D = A
			vD = vA
			TC = 2.6
		3:
			D = A
			vD = vA
	DUR = TC + 7.8
	att.play("run", 0.0); def.play("run", 0.0)
	for e in extras: e.play("jog", 0.0)
	bpos = P - A * vA * TC + A * 0.7
	ps = -vA * TC
	touchT = 0.0

func _process(delta: float) -> void:
	get_tree().paused = paused
	Engine.time_scale = speed
	var dt := 0.0 if paused else delta
	t += dt
	if t > DUR: _restart()
	match lance:
		0: _tackle(dt)
		1: _push(dt)
		2: _pull(dt)
		3: _shoulder(dt)
	# os outros aproximam-se do lance e param a uns metros
	var ab := att.body_pos()
	for e in extras:
		var s: Vector2 = e.get_meta("spot")
		if t < 0.05: e.set_meta("cur", s)
		var stop := 3.6 + float(extras.find(e)) * 1.1
		var cur: Vector2 = e.get_meta("cur", s)
		var to := Vector2(ab.x, ab.z) - cur
		var dist := to.length()
		var v := 0.0
		if t > 0.4 and dist > stop: v = min(3.0, (dist - stop) * 1.5)
		if v > 0.0: cur += to.normalized() * v * dt
		e.set_meta("cur", cur)
		e.move(cur, to.normalized(), v)
		e.play("jog" if v > 0.6 else "idle", 0.4)
	var all: Array = [att, def] + extras
	for p in all:
		p.update(dt, t)
		p.ground()
		p.mat.set_shader_parameter("flutter", clamp(p.speed / 6.0, 0.0, 1.0) if not p.rag else 0.3)
	_separate(all)
	# levanta-se quando já não está queixoso
	if att.phase == "chao" and att.groundT > 1.4 + att.hurt * 2.2: att.get_up()
	_ball(dt)
	_camera()
	var info := ""
	if hit_done and t > TC + 1.2: info = "Verdade do lance: " + outcome + ("  ·  " + verdict if verdict != "" else "")
	ui.text = "GODOT 4 · %s   |   %s   |   %s s   |   N lance seguinte · R repetir (outro toque) · 1-4 câmaras · Espaço pausa · S lento" % [LANCES[lance], ["A TUA VISTA", "VISTA IDEAL", "ATRÁS DO LANCE", "DE PERTO"][cam_mode], ("%+.2f" % (t - TC)).replace(".", ",")]
	ui2.text = info

func _physics_process(pdt: float) -> void:
	for p in [att, def] + extras: p.physics_step(pdt, t)

# atacante a correr com a bola até ao contacto
func _att_run(dt: float, v: float) -> void:
	var ap := P + A * v * (t - TC)
	att.move(ap, A, v)

# o pé certo vai à bola de tempos a tempos (condução)
func _dribble(dt: float) -> void:
	if free_ball: return
	touchT -= dt
	var ap := att.body_pos()
	var ahead := Vector2(bpos.x - ap.x, bpos.y - ap.z).dot(A)
	if touchT <= 0.0 and ahead < 0.75:
		touchT = 0.5
		bvel = A * (vA * 1.35)
	# o pé que está à frente desce até à bola no momento do toque
	var fk := "foot_R" if att.bone_world("foot_R").distance_to(Vector3(bpos.x, 0.1, bpos.y)) < att.bone_world("foot_L").distance_to(Vector3(bpos.x, 0.1, bpos.y)) else "foot_L"
	var w: float = clamp(1.0 - abs(touchT - 0.45) / 0.08, 0.0, 1.0) * 0.8
	att.ik = {fk: [Vector3(bpos.x, 0.11, bpos.y) - Vector3(A.x, 0, A.y) * 0.16, w]}

func _ball(dt: float) -> void:
	if not free_ball:
		_dribble(dt)
		var ap := att.body_pos()
		var ahead := Vector2(bpos.x - ap.x, bpos.y - ap.z).dot(A)
		if ahead < 0.35: bpos = Vector2(ap.x, ap.z) + A * 0.35 + (bpos - Vector2(ap.x, ap.z) - A * (bpos - Vector2(ap.x, ap.z)).dot(A))
	bvel *= exp(-dt * (1.6 if not free_ball else 0.9))
	bpos += bvel * dt
	if not free_ball and bvel.length() < vA: bvel = A * vA
	ball.position = Vector3(bpos.x, 0.11, bpos.y)
	if not paused and bvel.length() > 0.05: ball.rotate(Vector3(bvel.y, 0, -bvel.x).normalized(), bvel.length() / 0.11 * dt)

func _leg_of(p: Jogador, near: Vector3) -> String:
	return "L" if p.bone_world("lowerleg01_L").distance_to(near) + p.bone_world("foot_L").distance_to(near) < p.bone_world("lowerleg01_R").distance_to(near) + p.bone_world("foot_R").distance_to(near) else "R"

# depois do lance quem está de pé abranda e para
func _settle(p: Jogador, dt: float, _d: Vector2) -> void:
	if p.phase != "anim": return
	var d := p.dir
	var v: float = max(0.0, p.speed - 3.0 * dt)
	p.move(p.pos + d * v * dt, d, v)
	if v < 1.0: p.play("idle", 0.4)
	elif v < 3.5: p.play("jog", 0.3)

# 1) entrada: a força e o ângulo do toque decidem o que acontece ao atacante; ou simula
func _tackle(dt: float) -> void:
	if not hit_done: _att_run(dt, vA)
	var C := P - D * 0.8
	var dp: Vector2
	if t < TC: dp = C - D * vD * (TC - t)
	else: dp = C + D * 1.6 * (1.0 - exp(-(t - TC) * 3.0))
	def.move(dp, D, vD if t < TC else max(0.0, vD * exp(-(t - TC) * 3.0)))
	if t > TC - 0.62: def.play("kick", 0.1)
	if t > TC + 0.9: def.play("jog", 0.3)
	# o pé do defesa vai mesmo ao tornozelo (ou à bola, na simulação)
	var leg := _leg_of(att, def.bone_world("foot_R"))
	var tgt := att.bone_world("foot_" + leg) + Vector3(0, 0.05, 0) if not sim_dive else Vector3(bpos.x, 0.11, bpos.y)
	var w: float = clamp(1.0 - abs(t - TC) / 0.28, 0.0, 1.0)
	def.ik = {"foot_R": [tgt, w]}
	if not hit_done and t >= TC:
		hit_done = true
		att.hurt_leg = leg
		var v3 := Vector3(A.x, 0, A.y) * vA
		if sim_dive:
			free_ball = true; bvel = A * 3.0
			outcome = "SIMULAÇÃO: o defesa só toca na bola; o atacante atira-se"
			await get_tree().create_timer(0.14).timeout
			att.hurt = 1.0
			att.fall(v3 * 1.1 + Vector3(0, 1.6, 0), [], Vector3.ZERO, "dive", 0.9)
			return
		free_ball = true; bvel = (A * 0.6 + D * 0.8).normalized() * 6.0
		if force < 0.78:
			outcome = "toque leve no tornozelo: desequilibra, não cai (falta discutível)"
			att.push(D * 2.2 * force); att.hit(Vector3(0.0, 0.0, 1.2 * side))
			att.play("jog", 0.2)
		elif force < 1.12:
			outcome = "falta: toque claro, cai pelo impacto"
			att.hurt = 0.4
			att.fall(v3, ["lowerleg01_" + leg, "foot_" + leg], Vector3(D.x, 0.0, D.y) * 2.3 * force, "dive", 0.55)
		else:
			outcome = "falta forte (amarelo/vermelho): entrada a varrer com força"
			att.hurt = 1.0
			att.fall(v3 * 1.05, ["lowerleg01_" + leg, "foot_" + leg, "upperleg01_" + leg], Vector3(D.x, 0.15, D.y) * 3.4 * force, "dive", 0.45, Vector3(A.x, 0, A.y).cross(Vector3.UP) * -2.0 * side)
		def.hit(Vector3(-1.6 * force, 1.0, 0.0))
	if hit_done: _settle(att, dt, A)

# 2) empurrão nas costas: o defesa chega por trás e empurra com as duas mãos
func _push(dt: float) -> void:
	if not hit_done: _att_run(dt, vA)
	var gap: float = lerp(1.6, 0.55, clamp(t / TC, 0.0, 1.0))
	if not hit_done: def.move(att.pos - A * gap, A, vA)
	else: _settle(def, dt, A)

	var back := att.bone_world("spine01") - Vector3(A.x, 0, A.y) * 0.16
	var w: float = clamp(1.0 - abs(t - TC) / 0.3, 0.0, 1.0)
	def.ik = {"wrist_L": [back + Vector3(-A.y, 0, A.x) * 0.13, w], "wrist_R": [back - Vector3(-A.y, 0, A.x) * 0.13, w]}
	def.lean = Vector3(0.25 * w, 0, 0)
	if not hit_done and t >= TC:
		hit_done = true
		free_ball = true; bvel = A * 6.0
		var v3 := Vector3(A.x, 0, A.y) * vA
		if force < 0.95:
			outcome = "empurrão: perde o equilíbrio mas fica de pé (falta)"
			att.push(A * 3.0 * force); att.hit(Vector3(1.5 * force, 0, 0))
		else:
			outcome = "empurrão forte: projetado para a frente (falta, pode ser amarelo)"
			att.hurt = 0.3
			att.fall(v3 + Vector3(A.x, 0.3, A.y) * 2.6 * force, ["spine03", "head"], v3 * 1.3 + Vector3(A.x, 0.2, A.y) * 3.0 * force, "dive", 0.6)
		def.hit(Vector3(-0.8, 0, 0))
	if hit_done: _settle(att, dt, A)

# 3) puxão de camisola: corre ao lado, agarra e trava; ao largar, o atacante desequilibra-se
func _pull(dt: float) -> void:
	var grab0 := TC - 1.3
	var held: bool = t > grab0 and not hit_done
	var v := vA
	if held: v = lerp(vA, 3.6, clamp((t - grab0) / 0.8, 0.0, 1.0))
	var perp := Vector2(-A.y, A.x) * side
	if not hit_done:
		ps += v * dt
		att.move(P + A * ps, A, v)
		def.move(att.pos - A * 0.38 + perp * 0.52, A, v)
	else:
		_settle(att, dt, A); _settle(def, dt, A)
	var gw: float = clamp((t - grab0) / 0.25, 0.0, 1.0) * (1.0 if not hit_done else clamp(1.0 - (t - TC) / 0.15, 0.0, 1.0))
	var shoulder := att.bone_world("spine01") - Vector3(A.x, 0, A.y) * 0.12 + Vector3(perp.x, 0, perp.y) * 0.12
	var hand := "wrist_L" if side > 0 else "wrist_R"
	def.ik = {hand: [shoulder, gw]}
	def.layer = "pull"; def.layer_w = 0.45 * gw
	att.layer = "held"; att.layer_w = 0.5 * gw
	att.lean = Vector3(-0.25 * gw, 0, -0.15 * gw * side)
	if not hit_done and t >= TC:
		hit_done = true
		if force < 1.05:
			outcome = "puxão de camisola: travado, ao largar dá um esticão (falta)"
			att.push(A * 2.0); att.hit(Vector3(1.2, 0, 0))
		else:
			outcome = "puxão forte: cai para trás (falta, amarelo)"
			free_ball = true; bvel = A * 3.0
			att.hurt = 0.3
			att.fall(Vector3(A.x, 0, A.y) * 1.5 - Vector3(perp.x, 0, perp.y) * 1.8, ["spine03"], -Vector3(A.x, 0, A.y) * 1.0 + Vector3(perp.x, 0, perp.y) * 2.4, "fallback", 0.5)
	if hit_done and att.phase == "anim":
		att.lean = Vector3.ZERO

# 4) ombro a ombro: correm lado a lado e chocam; quem perde o duelo desequilibra-se (ou cai, se o choque for forte)
func _shoulder(dt: float) -> void:
	var perp := Vector2(-A.y, A.x) * side
	var gap: float = lerp(1.6, 0.4, clamp(t / TC, 0.0, 1.0))
	if not hit_done:
		att.move(P + A * vA * (t - TC), A, vA)
		def.move(P + A * vA * (t - TC) - A * 0.15 + perp * gap, A, vA)
	else:
		_settle(att, dt, A); _settle(def, dt, A)
	var lw: float = clamp(1.0 - abs(t - TC) / 0.35, 0.0, 1.0)
	def.lean = Vector3(0, 0, 0.28 * lw * side)
	att.lean = Vector3(0, 0, -0.2 * lw * side)
	if not hit_done and t >= TC:
		hit_done = true
		if force < 1.2:
			outcome = "carga de ombro legal (lado a lado, bola em disputa): o laranja perde o equilíbrio"
			att.push(-perp * 2.6 * force); att.hit(Vector3(0, 0, -1.6 * side))
			def.push(perp * 1.0); def.hit(Vector3(0, 0, 0.6 * side))
		else:
			outcome = "carga forte e tardia: cai de lado (falta)"
			free_ball = true; bvel = A * 5.0
			att.hurt = 0.4
			att.fall(Vector3(A.x, 0, A.y) * vA - Vector3(perp.x, 0, perp.y) * 2.2 * force, ["spine03", "upperarm01_L", "upperarm01_R"], -Vector3(perp.x, 0, perp.y) * 3.0 * force, "dive", 0.5)

# dois jogadores nunca ocupam o mesmo espaço; quem está caído é um obstáculo (contorna-se)
func _separate(all: Array) -> void:
	var g: Array = []
	for p in all: g.append(p.gpts())
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

func _camera() -> void:
	var look := Vector3(P.x, 0.9, P.y)
	if cam_mode == 0:
		var shake := Vector3(sin(t * 3.1) * 0.02, sin(t * 4.3) * 0.015, 0)
		cam.fov = 38
		cam.look_at_from_position(Vector3(REF.x, 1.75, REF.y) + shake, look)
	elif cam_mode == 1:
		var sd := Vector2(-A.y, A.x)
		var a3: Vector3 = att.body_pos()
		var d3: Vector3 = def.body_pos()
		var mid := Vector2((a3.x + d3.x) * 0.5, (a3.z + d3.z) * 0.5)
		var gap := Vector2(a3.x - d3.x, a3.z - d3.z).length()
		var c2 := mid + sd * (6.5 + gap * 0.6)
		cam.fov = 45
		cam.look_at_from_position(Vector3(c2.x, 1.4, c2.y), Vector3(mid.x, 0.7, mid.y))
	elif cam_mode == 3:
		var bp3 := att.body_pos()
		cam.fov = 40
		cam.look_at_from_position(Vector3(bp3.x - A.y * 4.6 + A.x * 1.2, 1.7, bp3.z + A.x * 4.6 + A.y * 1.2), Vector3(bp3.x, 0.5, bp3.z))
	else:
		var a3: Vector3 = att.body_pos()
		var c3 := Vector2(a3.x, a3.z) - A * 8.0 + Vector2(0, 1.5)
		cam.fov = 40
		cam.look_at_from_position(Vector3(c3.x, 1.6, c3.y), Vector3(a3.x, 0.6, a3.z))

func _ui() -> void:
	var layer := CanvasLayer.new(); add_child(layer)
	ui = Label.new(); ui.position = Vector2(14, 10)
	ui2 = Label.new(); ui2.position = Vector2(14, 34)
	for l in [ui, ui2]:
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", Color(0.97, 0.97, 0.94))
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8)); l.add_theme_constant_override("outline_size", 6)
		layer.add_child(l)
	ui2.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))

func next_lance() -> void:
	lance = (lance + 1) % LANCES.size()
	_restart()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed:
		match e.keycode:
			KEY_1: cam_mode = 0
			KEY_2: cam_mode = 1
			KEY_3: cam_mode = 2
			KEY_4: cam_mode = 3
			KEY_SPACE: paused = not paused
			KEY_S: speed = 0.25 if speed == 1.0 else 1.0
			KEY_R: _restart()
			KEY_N: next_lance()
	if e is InputEventMouseButton and e.pressed:
		cam_mode = (cam_mode + 1) % 4
	if e is InputEventScreenTouch and e.pressed:
		if e.position.x > get_viewport().get_visible_rect().size.x * 0.75: next_lance()
		else: cam_mode = (cam_mode + 1) % 4
