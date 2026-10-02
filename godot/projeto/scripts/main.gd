extends Node3D
# Árbitro de Caricas em Godot 4. O jogo de caricas visto de cima (Partida + Campo2D) e, em cada lance,
# o momento em 3D com corpos físicos (Jolt), visto de onde o árbitro estava: entradas, empurrões, puxões,
# ombro a ombro, pisões, disputas no ar, mão na bola, cantos, golos em análise, bola na linha e foras de jogo
# vistos pelo assistente. Depois da decisão o árbitro 3D comunica-a (cartão, apontar, vantagem).
# Ecrãs em ui.gd, carreira em carreira.gd, sons e voz em som.gd.

const W := 105.0
const H := 68.0
const LANCES := ["Entrada", "Empurrão nas costas", "Puxão de camisola", "Ombro a ombro"]
const AZUL := {"color": Color("3569dc"), "dark": Color("1d3f8f"), "shorts": Color("f1f1f1"), "sock": Color("1d3f8f"), "pat": 0.0, "shirt2": Color("f1f1f1")}
const LARANJA := {"color": Color("ee7d2c"), "dark": Color("a4521a"), "shorts": Color("23242a"), "sock": Color("ee7d2c"), "pat": 1.0, "shirt2": Color("23242a")}
const GK_KITS := [{"color": Color("2fa36b"), "dark": Color("1c6b45"), "shorts": Color("1c6b45"), "sock": Color("2fa36b"), "pat": 0.0, "shirt2": Color("2fa36b")},
	{"color": Color("8a5bd6"), "dark": Color("5a3a92"), "shorts": Color("23242a"), "sock": Color("8a5bd6"), "pat": 0.0, "shirt2": Color("8a5bd6")}]
const REF_KIT := {"color": Color("1a1b20"), "dark": Color("0c0c0e"), "shorts": Color("1a1b20"), "sock": Color("1a1b20"), "pat": 0.0, "shirt2": Color("1a1b20")}
const REF_KIT2 := {"color": Color("f2cf3a"), "dark": Color("17181c"), "shorts": Color("17181c"), "sock": Color("17181c"), "pat": 0.0, "shirt2": Color("f2cf3a")}
const N_EXTRAS := 6

var t := 0.0
var speed := 1.0
var paused := false
var cam_mode := 1         # 0 = a tua vista, 1 = vista ideal, 2 = atrás, 3 = de perto
var cam: Camera3D
var ball: MeshInstance3D
var att: Jogador
var def: Jogador
var refj: Jogador         # o árbitro em 3D (vista ideal e gestos)
var card: MeshInstance3D
var extras: Array = []
var lab1: Label
var lab2: Label
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
var clean := false         # corte limpo: o pé do defesa vai só à bola
var stamp := false         # pisão: entra por trás ao calcanhar
var cur := {}              # parâmetros do lance atual (para repetir igual)
var grass_mi: MultiMeshInstance3D
# bola 3D livre (cenas com bola no ar)
var b3 := Vector3.ZERO
var bv3 := Vector3.ZERO
var b3_free := false
var b3_net := 0.0          # x da rede quando a bola vai para a baliza (0 = sem rede)
var sc := {}               # dados da cena atual
# partida
var modo := "menu"         # menu | carreira | jogo | flash | lance | var | gesto | intervalo | rever | treino | fim
var jogo: Partida
var campo: Campo2D
var ui: UI
var som: Som
var car := Carreira.new()
var L := {}                # lance mostrado
var flash_t := 0.0
var dec_shown := false
var dec_left := 0.0
var replays := 0
var G := {}                # gesto do árbitro
var rever_de := ""         # painel a que se volta depois de "Ver lance"
var var_line := [0.0, 0.0]
var var_sel := 0
var var_mesh: Array = []
var match_paused := false
var end_data := {}
var is_career := false
# televisão: repetição com vários ângulos e câmara lenta; jogos à noite com luz artificial
const TV_SHOTS := [[4, -1.4, 1.6, 1.0, "Câmara principal"], [2, -0.9, 1.1, 0.4, "Atrás do lance"], [3, -0.55, 0.8, 0.22, "De perto"]]
var tv := {}
var tv_look := Vector3.ZERO
var tv_layer: CanvasLayer
var tv_wipe: ColorRect
var tv_tag: Label
var tv_bars: Array = []
var env: Environment
var sun: DirectionalLight3D
var sky_mat: ProceduralSkyMaterial
var floods: Array = []
var night := false
var slp := {}              # plano do carrinho capturado
var min_contact := 99.0    # menor distância entre as pernas do defesa e as do atacante à volta do contacto
var contact_checked := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hi_q = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	rng.randomize()
	_world()
	_stadium()
	if hi_q: _grass()
	att = Jogador.new(self, LARANJA, 9, 3, 1)
	def = Jogador.new(self, AZUL, 4, 8, 0)
	for i in N_EXTRAS:
		var home := i % 2 == 0
		var e := Jogador.new(self, AZUL if home else LARANJA, [2, 7, 5, 10, 3, 8][i], 20 + i, 0 if home else 1)
		e.set_meta("spot", Vector2(50 + i * 4, 20 + i * 3))
		extras.append(e)
	refj = Jogador.new(self, REF_KIT, 0, 77, 2)
	refj.label.visible = false
	var ca := BoneAttachment3D.new(); ca.bone_name = "wrist_R"; refj.skel.add_child(ca)
	card = MeshInstance3D.new(); var cb := BoxMesh.new(); cb.size = Vector3(0.075, 0.105, 0.006); card.mesh = cb
	var cm := StandardMaterial3D.new(); cm.albedo_color = Color("f2cf3a"); cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; card.material_override = cm
	card.position = Vector3(0, 0.12, 0.02); card.visible = false; ca.add_child(card)
	ball = MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = 0.11; sm.height = 0.22
	ball.mesh = sm
	var bm := StandardMaterial3D.new(); bm.albedo_color = Color(0.96, 0.96, 0.96); bm.roughness = 0.4
	ball.material_override = bm
	add_child(ball)
	for i in 2:
		var lm := MeshInstance3D.new(); var lb := BoxMesh.new(); lb.size = Vector3(0.025, 0.01, H + 4); lm.mesh = lb
		var mm := StandardMaterial3D.new(); mm.albedo_color = Color("ff3b2f") if i == 0 else Color("2a7dff"); mm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mm.no_depth_test = true
		lm.material_override = mm; lm.position = Vector3(0, 0.02, H / 2); lm.visible = false
		add_child(lm); var_mesh.append(lm)
	cam = Camera3D.new(); cam.fov = 55; cam.near = 0.05; cam.far = 600
	add_child(cam); cam.current = true
	_labels()
	_tv_ui()
	som = Som.new(); add_child(som)
	ui = UI.new(self); add_child(ui)
	var layer := CanvasLayer.new(); layer.layer = 1; add_child(layer)
	campo = Campo2D.new(); campo.main = self; layer.add_child(campo); campo.visible = false
	_restart()
	_show_menu()

func _labels() -> void:
	var layer := CanvasLayer.new(); layer.layer = 4; add_child(layer)
	lab1 = Label.new(); lab1.position = Vector2(14, 10)
	lab2 = Label.new(); lab2.position = Vector2(14, 34)
	for l in [lab1, lab2]:
		l.add_theme_font_size_override("font_size", 15)
		l.add_theme_color_override("font_color", Color(0.97, 0.97, 0.94))
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8)); l.add_theme_constant_override("outline_size", 6)
		layer.add_child(l)
	lab2.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))


func _world() -> void:
	env = Environment.new()
	var sky := Sky.new(); var sk := ProceduralSkyMaterial.new(); sky_mat = sk
	sk.sky_top_color = Color(0.32, 0.5, 0.78); sk.sky_horizon_color = Color(0.72, 0.8, 0.9); sk.ground_horizon_color = Color(0.5, 0.55, 0.5)
	sky.sky_material = sk
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.05
	env.glow_enabled = true; env.glow_intensity = 0.4; env.glow_bloom = 0.05
	env.fog_enabled = false; env.fog_light_color = Color(0.7, 0.76, 0.85); env.fog_density = 0.0012
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	sun = DirectionalLight3D.new()
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
		# projetor no topo: painel que brilha e luz (só acesa nos jogos à noite)
		var head := MeshInstance3D.new(); var hb := BoxMesh.new(); hb.size = Vector3(5.0, 3.0, 0.4); head.mesh = hb
		var hm := StandardMaterial3D.new(); hm.albedo_color = Color(0.9, 0.92, 0.95); hm.emission_enabled = true; hm.emission = Color(1, 0.98, 0.9); hm.emission_energy_multiplier = 0.0
		head.material_override = hm; head.position = corner + Vector3(0, 34.5, 0); add_child(head)
		head.look_at(Vector3(W / 2, 0, H / 2), Vector3.UP)
		var lamp := OmniLight3D.new(); lamp.position = corner + Vector3(0, 33, 0); lamp.omni_range = 150.0; lamp.omni_attenuation = 0.6
		lamp.light_energy = 0.0; lamp.light_color = Color(1.0, 0.97, 0.9); lamp.shadow_enabled = false; add_child(lamp)
		floods.append([hm, lamp])

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
		var p := Vector2(r.randf_range(-16, 16), r.randf_range(-11, 11))
		var b := Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(1, r.randf_range(0.6, 1.5), 1))
		mm.set_instance_transform(i, Transform3D(b, Vector3(p.x, 0, p.y)))
	var mi := MultiMeshInstance3D.new(); mi.multimesh = mm
	var gm := ShaderMaterial.new(); gm.shader = preload("res://shaders/grass.gdshader")
	mi.material_override = gm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	grass_mi = mi


# ---------- equipamentos ----------
func _kit(team: int, role: String) -> Dictionary:
	if jogo == null or team > 1: return [AZUL, LARANJA][clampi(team, 0, 1)]
	var tm: Dictionary = jogo.teams[team]
	if role == "gk":
		var g: Color = tm.gk
		return {"color": g, "dark": g.darkened(0.35), "shorts": g.darkened(0.35), "sock": g, "pat": 0.0, "shirt2": g}
	return {"color": tm.color, "dark": tm.dark, "shorts": tm.shorts, "sock": tm.sock, "pat": tm.get("pat", 0.0), "shirt2": tm.get("shirt2", tm.dark)}
func _dress(j: Jogador, info: Dictionary) -> void:
	var tm := int(info.team)
	j.set_kit(_kit(tm, str(info.get("role", ""))), int(info.num), tm)
	j.label.modulate = jogo.teams[tm].get("text", Color(0.97, 0.97, 0.95)) if jogo else Color(0.97, 0.97, 0.95)
	j.node.visible = true
# o árbitro muda de equipamento quando uma equipa joga de escuro
func _ref_kit() -> Dictionary:
	if jogo:
		for tm in jogo.teams:
			if (tm.color as Color).get_luminance() < 0.22: return REF_KIT2
	return REF_KIT

# ---------- montar o lance 3D a partir do lance da partida ----------
func _setup_scene(l: Dictionary) -> void:
	var k := jogo.kind_of(l)
	sc = {"kind": k, "truth": l.truth, "approach": true}
	P = l.P; A = l.get("A", Vector2(1, 0)); REF = l.ref
	if A == Vector2.ZERO: A = Vector2(1, 0)
	for j in [att, def, refj] + extras: j.reset(); j.node.visible = true
	_dress(att, l.att)
	if l.has("def") and int(l.def.id) >= 0: _dress(def, l.def)
	refj.set_kit(_ref_kit(), 0, 2)
	var T: String = l.truth
	var c: Dictionary
	if l.has("cur"): c = l.cur
	else:
		match k:
			"foul":
				if l.get("light", false):
					c = {"lance": 0, "force": 0.92 if T == "falta" else (0.84 if T == "siga" else 0.6), "side": l.side, "sim": T == "simulacao", "clean": false, "phi": rng.randf_range(55, 75), "vD": 7.2}
				else:
					c = _params_for(T, l.side)
					if c.lance == 0 and T in ["falta", "amarelo", "vermelho"]: c.phi = clamp(float(l.phi), 18.0, 85.0)
			"agarrao": c = {"lance": 2, "force": 1.15 if l.get("fall", false) else (0.55 if T == "siga" else 0.9), "side": l.s, "sim": false, "clean": false}
			"pisao": c = {"lance": 4, "force": {"siga": 0.6, "falta": 0.95, "amarelo": 1.2, "vermelho": 1.5}[T], "side": l.s, "clean": T == "siga", "sim": false, "phi": 172.0, "vD": 5.6}
			"aereo": c = {"lance": 5, "side": l.s}
			"mao": c = {"lance": 6, "side": l.side}
			"canto": c = {"lance": 7, "side": l.s}
			"linha": c = {"lance": 8}
			"offside": c = {"lance": 9}
			"golo": c = {"lance": 10, "side": l.s}
		l.cur = c
	cur = c
	# quem está à volta: os mais perto do lance
	var others: Array = l.get("others", []).duplicate()
	var used := [int(l.att.id), int(l.def.id) if l.has("def") else -1]
	var first: Array = []
	if k == "canto" and l.has("taker"): first.append({"id": l.taker.id, "team": l.taker.team, "role": l.taker.role, "num": l.taker.num, "p": l.corner, "v": Vector2.ZERO})
	if k == "golo" and l.has("taker"): first.append({"id": l.taker.id, "team": l.taker.team, "role": "gk", "num": l.taker.num, "p": Vector2(l.gx - l.dir_in * 0.7, l.G.y * 0.4 + 34 * 0.6), "v": Vector2.ZERO})
	others = others.filter(func(o): return not (int(o.id) in used) and not first.any(func(f): return int(f.id) == int(o.id)))
	others.sort_custom(func(a, b): return a.p.distance_to(P) < b.p.distance_to(P))
	var list: Array = first + others
	if k == "offside": list = []
	for i in extras.size():
		var e: Jogador = extras[i]
		if i < list.size():
			var o: Dictionary = list[i]
			_dress(e, o)
			e.set_meta("spot", o.p); e.set_meta("v", o.get("v", Vector2.ZERO))
		else:
			e.node.visible = false; e.set_meta("spot", Vector2(-40, -40)); e.set_meta("v", Vector2.ZERO)
	sc.n_extras = mini(list.size(), extras.size())
	if k in ["canto", "golo", "linha", "mao", "offside", "aereo"]: sc.approach = false
	match k:
		"aereo": sc.K = l.K
		"mao": sc.K = l.K; sc.Sd = l.Sd; sc.arm = l.arm_out; sc.s = l.side
		"canto": sc.Q = l.Q; sc.V = l.V; sc.s = l.s; sc.corner = l.corner; sc.fall = l.get("fall", false); A = l.V
		"linha": sc.B = l.B; sc.bh = l.bh; sc.Pk = l.Pk; sc.gx = l.gx; sc.dir_in = l.dir_in
		"golo": sc.C = l.C; sc.Pk = l.Pk; sc.G = l.G; sc.s = l.s; sc.gx = l.gx; sc.dir_in = l.dir_in; sc.fall = l.get("fall", false); P = l.C
		"offside": _setup_offside(l)

func _setup_offside(l: Dictionary) -> void:
	var oi: Dictionary = l.oi
	var snap: Array = oi.snap
	var by := {}
	for s in snap: by[int(s.id)] = s
	sc.line_x = oi.line_x; sc.recv = oi.recv; sc.ast = oi.ast; sc.dir = jogo.dirs(oi.team)
	P = Vector2(oi.line_x, oi.recv.y)
	var lst: Array = []
	var r: Dictionary = by.get(int(oi.receiver), {})
	if not r.is_empty(): lst.append([att, r])
	if by.has(int(oi.line_def)): _dress(def, by[int(oi.line_def)]); lst.append([def, by[int(oi.line_def)]])
	else: def.node.visible = false
	var ex: Array = []
	if by.has(int(oi.passer)): ex.append(by[int(oi.passer)])
	var defs: Array = snap.filter(func(s): return int(s.team) != int(oi.team) and s.role != "gk" and int(s.id) != int(oi.line_def))
	defs.sort_custom(func(a, b): return absf(a.p.x - oi.line_x) < absf(b.p.x - oi.line_x))
	var atts: Array = snap.filter(func(s): return int(s.team) == int(oi.team) and int(s.id) != int(oi.receiver) and int(s.id) != int(oi.passer) and s.role != "gk")
	atts.sort_custom(func(a, b): return a.p.distance_to(oi.recv) < b.p.distance_to(oi.recv))
	ex.append_array(defs.slice(0, 3)); ex.append_array(atts.slice(0, 2))
	for i in extras.size():
		var e: Jogador = extras[i]
		if i < ex.size(): _dress(e, ex[i]); lst.append([e, ex[i]])
		else: e.node.visible = false
	sc.list = lst
	sc.passer = extras[0] if by.has(int(oi.passer)) else null
	sc.target = oi.recv + (r.get("v", Vector2.ZERO) as Vector2) * 1.2 if not r.is_empty() else oi.recv

# ---------- lance de treino (sem partida) ----------
func _random_params() -> Dictionary:
	var c := {"lance": lance, "force": rng.randf_range(0.45, 1.55), "side": 1.0 if rng.randf() < 0.5 else -1.0, "sim": false, "clean": false, "phi": 50.0, "vD": 8.2}
	if lance == 0:
		c.sim = rng.randf() < 0.25
		c.phi = rng.randf_range(25.0, 75.0)
		c.vD = rng.randf_range(6.2, 9.6)
		c.force = c.vD / 8.2 * (0.55 + 0.6 * sin(deg_to_rad(c.phi))) * rng.randf_range(0.85, 1.15)
	return c

# partida: o lance 3D mostra a verdade decidida pelo jogo (falta, cartão, simulação ou nada)
func _params_for(truth: String, sd: float) -> Dictionary:
	var r := rng.randf()
	var c := {"lance": 0, "force": 1.0, "side": sd, "sim": false, "clean": false, "phi": rng.randf_range(40, 75), "vD": rng.randf_range(6.8, 8.8)}
	match truth:
		"siga":
			if r < 0.6: c.clean = true; c.force = 0.6
			else: c.lance = 3; c.force = rng.randf_range(0.6, 1.05)
		"falta":
			if r < 0.5: c.force = rng.randf_range(0.82, 1.08)
			elif r < 0.7: c.lance = 1; c.force = rng.randf_range(0.5, 0.9)
			elif r < 0.85: c.lance = 2; c.force = rng.randf_range(0.6, 1.0)
			else: c.lance = 3; c.force = rng.randf_range(1.25, 1.5)
		"amarelo":
			if r < 0.6: c.force = rng.randf_range(1.15, 1.4); c.phi = rng.randf_range(30, 60); c.vD = rng.randf_range(8.0, 9.4)
			elif r < 0.8: c.lance = 1; c.force = rng.randf_range(1.05, 1.4)
			else: c.lance = 2; c.force = rng.randf_range(1.1, 1.4)
		"vermelho":
			c.force = rng.randf_range(1.45, 1.7); c.phi = rng.randf_range(18, 35); c.vD = rng.randf_range(9.0, 9.8)
		"simulacao":
			c.sim = true; c.force = 0.6
	return c

func _restart() -> void:
	t = 0.0
	min_contact = 99.0; contact_checked = false; slp = {}
	hit_done = false
	free_ball = false
	b3_free = false; b3_net = 0.0; bv3 = Vector3.ZERO
	outcome = ""; verdict = ""
	for p in [att, def, refj] + extras: p.reset()
	if cur.is_empty(): cur = _random_params()
	lance = cur.lance
	force = cur.get("force", 1.0)
	sim_dive = cur.get("sim", false)
	clean = cur.get("clean", false)
	side = cur.get("side", 1.0)
	stamp = lance == 4
	TC = 2.2; vA = 5.4
	if grass_mi: grass_mi.position = Vector3(P.x, 0, P.y)
	ball.visible = true; card.visible = false
	for m in var_mesh: m.visible = false
	match lance:
		0:
			var phi := deg_to_rad(cur.phi)
			D = A.rotated(-phi * side)
			vD = cur.vD
			verdict = "ângulo %d°, defesa a %.1f m/s" % [int(cur.phi), vD]
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
		4:
			D = A.rotated(deg_to_rad(8) * side); vD = 6.0; vA = 2.6
		5: TC = 2.0
		6: TC = 1.7
		7: TC = 2.4
		8: TC = 1.7
		9: TC = 1.8
		10: TC = 1.8
	DUR = TC + 7.8
	if modo != "treino": DUR = 1e9
	att.play("run", 0.0); def.play("run", 0.0)
	for e in extras: e.play("jog", 0.0)
	bpos = P - A * vA * TC + A * 0.7
	ps = -vA * TC
	touchT = 0.0
	b3 = Vector3(bpos.x, 0.11, bpos.y)
	if lance == 8: def.play("idle", 0.0)
	if lance == 6: def.play("idle", 0.0)
	for i in extras.size():
		var e: Jogador = extras[i]
		e.set_meta("cur", e.get_meta("spot"))
	refj.node.visible = modo != "treino"
	refj.play("idle", 0.0)

# ---------- ciclo ----------
func _process(delta: float) -> void:
	if not tv.is_empty() and not (modo in ["var", "rever", "treino"]): _tv_end()
	match modo:
		"jogo", "flash", "intervalo", "fim":
			_match_process(delta)
		"lance", "var", "rever", "treino":
			_scene_process(delta)
		"gesto":
			_gesture_process(delta)
		_:
			get_tree().paused = false; Engine.time_scale = 1.0
			_menu_cam(delta)
	if jogo and modo in ["jogo", "flash"]: som.set_crowd(jogo.crowd / 100.0)

func _match_process(delta: float) -> void:
	get_tree().paused = false; Engine.time_scale = 1.0
	if modo == "flash":
		flash_t -= delta
		if flash_t <= 0: _enter_lance()
		return
	if modo == "jogo" and not match_paused and jogo: jogo.tick(delta)

func _menu_cam(delta: float) -> void:
	t += delta
	var a := t * 0.05
	cam.fov = 50
	cam.look_at_from_position(Vector3(W / 2 + cos(a) * 62, 22, H / 2 + sin(a) * 50), Vector3(W / 2, 0, H / 2))

func _scene_process(delta: float) -> void:
	_tv_step()
	get_tree().paused = paused
	Engine.time_scale = speed
	var dt := 0.0 if paused else delta
	if modo in ["lance", "var"] and jogo:
		jogo.tick(delta)          # temporizadores da partida (o VAR do treino)
		if not (modo in ["lance", "var"]): return
	# fora de jogo: o momento do passe cai sempre exatamente em TC (é essa a imagem que se mede e se vê no VAR)
	var snap_tc := lance == 9 and t < TC and t + dt >= TC
	if snap_tc: dt = TC - t
	# ao rever: para 3 s no passe, com as linhas certas
	if modo == "rever" and lance == 9 and is_equal_approx(t, TC) and sc.get("held", 0.0) < 3.0:
		sc.held = sc.get("held", 0.0) + dt; dt = 0.0
	t += dt
	if snap_tc: t = TC
	# VAR no fora de jogo: a imagem para no momento do passe
	if modo == "var" and lance == 9 and t >= TC:
		if not sc.has("lines"):
			sc.lines = true
			var_line = [att.node.position.x, def.node.position.x]; var_sel = 0
		t = TC; dt = 0.0
	if t > DUR:
		if modo == "treino": cur = {}
		_restart()
	match lance:
		0: _tackle(dt)
		1: _push(dt)
		2: _pull(dt)
		3: _shoulder(dt)
		4: _tackle(dt)
		5: _aerial(dt)
		6: _hand(dt)
		7: _corner(dt)
		8: _line(dt)
		9: _offside(dt)
		10: _goalfoul(dt)
	if sc.get("approach", true): _extras_step(dt)
	elif lance != 9: _extras_idle(dt)
	var all: Array = [att, def] + extras
	all = all.filter(func(p): return p.node.visible)
	for p in all:
		p.update(dt, t)
		p.ground()
		p.mat.set_shader_parameter("flutter", clamp(p.speed / 6.0, 0.0, 1.0) if not p.rag else 0.3)
	_separate(all)
	if lance <= 4 and t > TC - 0.4 and t < TC + 1.3: _track_contact()
	if lance <= 4 and t >= TC + 1.3 and not contact_checked: _check_contact()
	if lance == 9 and is_equal_approx(t, TC) and sc.get("measured_t", -1.0) != t: _measure_offside()
	# o árbitro (só se vê fora da tua vista)
	if refj.node.visible:
		var rd := (P - REF).normalized()
		refj.move(REF, rd if rd != Vector2.ZERO else Vector2(0, 1), 0.0); refj.play("idle", 0.3)
		refj.update(dt, t); refj.ground()
	# levanta-se quando já não está queixoso
	for p in [att, def]:
		if (p.phase == "chao" or p.phase == "chao_k") and p.groundT > 1.4 + p.hurt * 2.2: p.get_up()
	if lance <= 4: _ball(dt)
	else: _ball3_step(dt)
	_var_lines()
	_camera()
	if modo == "treino":
		var info := ""
		if hit_done and t > TC + 1.2: info = "Verdade do lance: " + outcome + ("  ·  " + verdict if verdict != "" else "")
		lab1.text = "GODOT 4 · %s   |   %s   |   %s s   |   N lance seguinte · R repetir (outro toque) · 1-4 câmaras · Espaço pausa · S lento · Esc menu" % [LANCES[lance], ["A TUA VISTA", "VISTA IDEAL", "ATRÁS DO LANCE", "DE PERTO"][cam_mode], ("%+.2f" % (t - TC)).replace(".", ",")]
		lab2.text = info
	else:
		lab1.text = ""; lab2.text = ""
		_lance_ui(delta)

func _physics_process(pdt: float) -> void:
	for p in [att, def] + extras: p.physics_step(pdt, t)

# os outros vêm a correr com a jogada (chegam ao sítio onde estavam no momento do lance),
# travam quando há o contacto e depois aproximam-se do lance, uns a correr, outros a trote
func _extras_step(dt: float) -> void:
	var ab := att.body_pos()
	var hit := Vector2(ab.x, ab.z)
	for i in extras.size():
		var e: Jogador = extras[i]
		if not e.node.visible or e.rag or e.phase != "anim": continue
		var spot: Vector2 = e.get_meta("spot")
		var vv: Vector2 = e.get_meta("v", Vector2.ZERO)
		if vv.length() < 1.5:
			var to0 := P - spot
			vv = to0.normalized() * clamp(to0.length() / 2.5, 1.5, 4.5) if to0.length() > 3.0 else A * 2.0
		vv = vv.limit_length(7.5)
		var cu: Vector2
		var sp: float
		var face: Vector2
		if t < TC:
			cu = spot + vv * (t - TC)
			sp = vv.length(); face = vv.normalized()
			e.set_meta("cur", cu); e.set_meta("vel", vv)
		else:
			cu = e.get_meta("cur")
			var vel: Vector2 = e.get_meta("vel", vv)
			var to := hit - cu
			var stop := 2.6 + float(i) * 0.9
			if t < TC + 0.5 + float(i) * 0.12:
				vel *= exp(-dt * 2.5)
			else:
				var want := Vector2.ZERO
				if to.length() > stop: want = to.normalized() * min(5.5 - float(i) * 0.5, (to.length() - stop) * 2.0)
				vel = vel.lerp(want, clamp(dt * 3.0, 0.0, 1.0))
			cu += vel * dt
			e.set_meta("cur", cu); e.set_meta("vel", vel)
			sp = vel.length()
			face = vel.normalized() if sp > 1.2 else (to.normalized() if to.length() > 0.1 else e.dir)
		e.move(cu, face, sp)
		e.play("run" if sp > 4.2 else ("jog" if sp > 0.7 else "idle"), 0.3)
# nas cenas paradas (cantos, golos) os outros mexem-se pouco, de frente para a bola
func _extras_idle(dt: float) -> void:
	for i in extras.size():
		var e: Jogador = extras[i]
		if not e.node.visible or e.rag or e.phase != "anim": continue
		if lance == 10 and i == 0: continue
		if lance == 7 and i == 0: continue
		var cu: Vector2 = e.get_meta("cur")
		var v: Vector2 = e.get_meta("v")
		if v.length() > 0.2 and t < TC + 0.6: cu += v * dt * 0.6
		e.set_meta("cur", cu)
		var to := Vector2(b3.x, b3.z) - cu
		e.move(cu, to.normalized() if to.length() > 0.1 else Vector2(0, 1), v.length() * 0.6 if t < TC + 0.6 else 0.0)
		e.play("jog" if v.length() > 1.0 and t < TC + 0.6 else "idle", 0.4)

# ---------- bola no ar ----------
func _arc(a: Vector3, b: Vector3, h: float, k: float) -> Vector3:
	k = clamp(k, 0.0, 1.0)
	var p := a.lerp(b, k)
	p.y += 4.0 * h * k * (1.0 - k)
	return p
func _set_ball(p: Vector3) -> void:
	var d := p - ball.position
	ball.position = p
	var hz := Vector2(d.x, d.z)
	if hz.length() > 0.0005: ball.rotate(Vector3(hz.y, 0, -hz.x).normalized(), hz.length() / 0.11)
func _ball3_step(dt: float) -> void:
	if b3_free and dt > 0:
		bv3.y -= 9.8 * dt
		b3 += bv3 * dt
		if b3.y < 0.11:
			b3.y = 0.11
			if absf(bv3.y) > 1.0: bv3.y = -bv3.y * 0.5
			else: bv3.y = 0
			bv3.x *= 0.92; bv3.z *= 0.92
		if absf(bv3.y) < 0.01 and b3.y <= 0.111: bv3 *= exp(-dt * 0.9)
		if b3_net != 0.0 and (b3.x - b3_net) * sc.get("dir_in", 1.0) > 0:
			b3.x = b3_net; bv3 = Vector3(0, min(bv3.y, 0.0), bv3.z * 0.2)
	_set_ball(b3)

# ---------- cenas ----------
# 5) disputa no ar: os dois saltam à bola; o defesa pode usar o braço (empurrão, alavanca, cotovelada)
func _aerial(dt: float) -> void:
	var perp := Vector2(-A.y, A.x) * side
	var v := 3.4
	var jt := t - (TC - 0.34)
	var jmp: float = 0.0 if jt < 0 or jt > 0.72 else 0.5 * sin(PI * jt / 0.72)
	var T: String = sc.truth
	if t < TC + 0.35:
		if not att.rag: att.move(P + A * v * (t - TC), A, v); att.play("jog", 0.2)
		if not def.rag: def.move(P + A * v * (t - TC) - A * 0.5 + perp * 0.38, A, v); def.play("jog", 0.2)
	else:
		_settle(att, dt, A); _settle(def, dt, A)
	att.jump = jmp; def.jump = jmp * 0.92
	var w: float = clamp(jt / 0.2, 0.0, 1.0) * clamp((0.9 - jt) / 0.25, 0.0, 1.0)
	var up := Vector3(0, 0.38, 0)
	if not att.rag: att.ik = {"wrist_L": [att.bone_world("head") + up - Vector3(perp.x, 0, perp.y) * 0.18, w * 0.6], "wrist_R": [att.bone_world("head") + up + Vector3(perp.x, 0, perp.y) * 0.18, w * 0.6]}
	var ab := att.body_pos()
	var hn := "wrist_L" if def.bone_world("wrist_L").distance_to(ab) < def.bone_world("wrist_R").distance_to(ab) else "wrist_R"
	var tgt: Vector3
	match T:
		"vermelho": tgt = att.bone_world("head")
		"amarelo": tgt = att.bone_world("spine03") + Vector3(0, 0.12, 0)
		"falta": tgt = att.bone_world("spine02") - Vector3(A.x, 0, A.y) * 0.12
		_: tgt = def.bone_world("head") + up
	def.ik = {hn: [tgt, w]}
	if T == "falta": def.ik["wrist_R" if hn == "wrist_L" else "wrist_L"] = [tgt - Vector3(perp.x, 0, perp.y) * 0.2, w]
	if T == "amarelo": def.lean = Vector3(0, 0, 0.25 * w * side)
	if not hit_done and t >= TC:
		hit_done = true
		var v3 := Vector3(A.x, 0, A.y) * v
		var p3 := Vector3(perp.x, 0, perp.y)
		b3_free = true
		match T:
			"siga":
				att.hit(Vector3(0.6, 0, 0.3 * side)); bv3 = Vector3(A.x * 7, 3.0, A.y * 7)
				if L.get("fall", false): att.hurt = 0.2; att.fall(v3 * 0.6 + Vector3(0, 0.4, 0), [], Vector3.ZERO, "dive", 0.8)
			"falta":
				att.hurt = 0.2; bv3 = Vector3(A.x * 3, 2.5, A.y * 3) - p3 * 2
				att.fall(v3 + Vector3(0, 0.5, 0), ["spine03", "spine02"], v3 * 1.3 + Vector3(A.x, 0.3, A.y) * 2.6, "dive", 0.6)
			"amarelo":
				att.hurt = 0.5; bv3 = Vector3(-A.x * 2, 2.5, -A.y * 2) - p3 * 3
				att.fall(v3 * 0.8 - p3 * 1.6 + Vector3(0, 0.5, 0), ["spine03", "upperarm01_L", "upperarm01_R"], -p3 * 3.4 + Vector3(0, 0.2, 0), "dive", 0.5)
			_:
				att.hurt = 1.0; bv3 = Vector3(-A.x * 2, 3.0, -A.y * 2) - p3 * 3
				att.fall(v3 * 0.5 + Vector3(0, 0.4, 0), ["head", "spine03"], -Vector3(A.x, 0, A.y) * 2.0 - p3 * 2.6 + Vector3(0, 0.6, 0), "fallback", 0.45, Vector3(0, 2.0 * side, 0))
		outcome = {"siga": "os dois saltam à bola, sem braço", "falta": "empurra-o nas costas durante o salto", "amarelo": "usa o braço como alavanca no ombro", "vermelho": "cotovelada na cara"}.get(T, "")
	if not b3_free:
		var K: Vector2 = sc.K
		var from := Vector3(K.x, 0.11, K.y)
		var k := (t - (TC - 1.5)) / 1.5
		b3 = _arc(from, Vector3(P.x + A.x * 0.15, 2.3, P.y + A.y * 0.15), 6.5, k) if k > 0 else from

# 6) mão na bola: remate de frente para um defesa; o braço junto ao corpo, aberto ou levantado
func _hand(dt: float) -> void:
	var tk := TC - 0.45
	var K: Vector2 = sc.K
	var Sd: Vector2 = sc.Sd
	if t < tk - 0.35:
		att.move(K - Sd * 0.5 - Sd * 5.0 * (tk - t), Sd, 5.0); att.play("run", 0.2)
	elif t < tk + 0.55:
		att.move(K - Sd * 0.5 + Sd * 2.0 * maxf(0, t - tk), Sd, 2.0); att.play("kick", 0.08)
	else: _settle(att, dt, Sd)
	var f := -Sd
	var latv := Vector3(-f.y, 0, f.x) * float(sc.s)
	if not def.rag: def.move(P + Vector2(latv.x, latv.z) * 0.15 * sin(t * 2.0), f, 0.0); def.play("idle", 0.3)
	var shL := def.bone_world("upperarm01_L")
	var shR := def.bone_world("upperarm01_R")
	var arm_side := "L" if (shL - shR).dot(latv) > 0 else "R"
	var sh := def.bone_world("upperarm01_" + arm_side)
	var ao: float = sc.arm
	var wt: Vector3
	if ao > 2.0: wt = sh + latv * 0.3 + Vector3(0, 0.4, 0) + Vector3(f.x, 0, f.y) * 0.15
	elif ao > 1.0: wt = sh + latv * (0.48 + 0.1 * (ao - 1.15)) + Vector3(0, -0.08, 0) + Vector3(f.x, 0, f.y) * 0.1
	else: wt = sh + latv * 0.1 + Vector3(0, -0.52, 0)
	var aw: float = clamp((t - (tk - 0.3)) / 0.25, 0.0, 1.0) * (1.0 if t < TC + 0.6 else clamp(1.0 - (t - TC - 0.6) / 0.3, 0.0, 1.0))
	if ao > 0.0: def.ik = {"wrist_" + arm_side: [wt, aw]}
	if t < tk: b3 = Vector3(K.x, 0.11, K.y)
	elif not b3_free:
		var hitp: Vector3 = def.bone_world("wrist_" + arm_side) if ao > 1.0 else (def.bone_world("lowerarm01_" + arm_side) if ao > 0.0 else def.bone_world("spine02"))
		hitp.y = maxf(hitp.y, 0.45)
		var k: float = (t - tk) / (TC - tk)
		b3 = Vector3(K.x, 0.11, K.y).lerp(hitp, clamp(k, 0.0, 1.0)) + Vector3(0, sin(clamp(k, 0.0, 1.0) * PI) * 0.35, 0)
		if k >= 1.0:
			b3_free = true; hit_done = true
			bv3 = Vector3(-Sd.x * 2.0, 2.4, -Sd.y * 2.0) + latv * 5.0
			def.hit(Vector3(0.4, 0, 0.6 * float(sc.s)))
			outcome = "a bola bate no " + ("braço levantado" if ao > 2.0 else ("braço aberto" if ao > 1.0 else ("braço junto ao corpo" if ao > 0.0 else "corpo")))

# 7) canto: luta na área à espera da bola
func _corner(dt: float) -> void:
	var Q: Vector2 = sc.Q
	var V: Vector2 = sc.V
	var perp := Vector2(-V.y, V.x) * float(sc.s)
	var T: String = sc.truth
	var v := 3.0
	var ap := Q + V * v * minf(t - TC, 0.25)
	var tk := TC - 1.3
	if t < TC + 0.4:
		if not att.rag: att.move(ap, V, v if t < TC + 0.25 else 0.5); att.play("jog", 0.3)
		var dp := ap - V * 0.55 + perp * 0.35
		if T == "ataque": dp = ap + V * 0.15 + perp * 0.6
		if not def.rag: def.move(dp, V, v); def.play("jog", 0.3)
	else:
		_settle(att, dt, V); _settle(def, dt, V)
	var jt := t - (TC - 0.3)
	var jmp: float = 0.0 if jt < 0 or jt > 0.62 else 0.35 * sin(PI * jt / 0.62)
	if not att.rag: att.jump = jmp
	if not def.rag: def.jump = jmp * 0.8
	var w: float = clamp(1.0 - absf(t - TC + 0.1) / 0.35, 0.0, 1.0)
	if T == "penalti":
		var back := att.bone_world("spine01") - Vector3(V.x, 0, V.y) * 0.15
		def.ik = {"wrist_L": [back + Vector3(perp.x, 0, perp.y) * 0.13, w], "wrist_R": [back - Vector3(perp.x, 0, perp.y) * 0.13, w]}
	elif T == "ataque":
		var db := def.body_pos()
		var hn := "wrist_L" if att.bone_world("wrist_L").distance_to(db) < att.bone_world("wrist_R").distance_to(db) else "wrist_R"
		att.ik = {hn: [def.bone_world("spine02"), w]}
	else:
		def.lean = Vector3(0, 0, -0.2 * w * float(sc.s)); att.lean = Vector3(0, 0, 0.15 * w * float(sc.s))
	if not hit_done and t >= TC - 0.05:
		hit_done = true
		var v3 := Vector3(V.x, 0, V.y) * v
		var p3 := Vector3(perp.x, 0, perp.y)
		match T:
			"penalti":
				att.hurt = 0.3; att.fall(v3 + Vector3(0, 0.3, 0), ["spine03", "spine02"], v3 * 1.2 + Vector3(V.x, 0.25, V.y) * 2.6, "dive", 0.6)
				outcome = "o defesa empurra-o pelas costas"
			"ataque":
				def.push(Vector2(p3.x, p3.z) * 2.6)
				if sc.fall: def.hurt = 0.2; def.fall(Vector3(p3.x, 0.3, p3.z) * 2.2, ["spine03"], Vector3(p3.x, 0.2, p3.z) * 2.8, "fallback", 0.5)
				outcome = "o atacante afasta o defesa com o braço"
			_:
				att.hit(Vector3(0, 0, -0.8 * float(sc.s))); def.hit(Vector3(0, 0, 0.6 * float(sc.s)))
				if sc.fall: att.hurt = 0.1; att.fall(v3 * 0.5 + Vector3(0, 0.3, 0), [], Vector3.ZERO, "dive", 0.85)
				outcome = "disputa normal, ombro com ombro"
	# quem marca o canto
	var tkr: Jogador = extras[0]
	if tkr.node.visible and lance == 7:
		var cpos: Vector2 = sc.corner
		var to := (Q - cpos).normalized()
		if t < tk - 0.35: tkr.move(cpos - to * 1.2 * (tk - 0.35 - t) / (tk - 0.35) - to * 0.5, to, 1.5); tkr.play("jog", 0.3)
		elif t < tk + 0.6: tkr.move(cpos - to * 0.5, to, 0.0); tkr.play("kick", 0.08)
		else: tkr.play("idle", 0.4)
	if not b3_free:
		var cp: Vector2 = sc.corner
		var c3 := Vector3(cp.x, 0.11, cp.y)
		var k := (t - tk) / (TC + 0.05 - tk)
		b3 = _arc(c3, Vector3(Q.x, 2.1, Q.y), 5.0, k) if k > 0 else c3
		if k >= 1.0:
			b3_free = true
			bv3 = Vector3(-V.x * 6, 2.0, -V.y * 6) if T != "ataque" else Vector3(V.x * 4, 1.0, V.y * 4)

# 8) bola na linha: o guarda-redes agarra-a em cima da linha
func _line(dt: float) -> void:
	var B: Vector2 = sc.B
	var Pk: Vector2 = sc.Pk
	var gx: float = sc.gx
	var di: float = sc.dir_in
	var tk := TC - 0.55
	var sd := (B - Pk).normalized()
	if t < tk - 0.35:
		att.move(Pk - sd * 0.5 - sd * 5.0 * (tk - t), sd, 5.0); att.play("run", 0.2)
	elif t < tk + 0.6:
		att.move(Pk - sd * 0.5, sd, 0.0); att.play("kick", 0.08)
	else: _settle(att, dt, sd)
	# guarda-redes: arranca do meio da baliza e atira-se à bola
	var gs := 1.0 if B.y < H / 2 else -1.0
	var g0 := Vector2(gx - di * 1.2, B.y + gs * 2.2)
	if not def.rag and not hit_done:
		var gk := g0.lerp(Vector2(gx - di * 0.9, B.y + gs * 0.9), clamp(t / (TC - 0.3), 0.0, 1.0))
		def.move(gk, Vector2(-di, 0), 1.5 if t < TC - 0.3 else 0.0); def.play("jog" if t < TC - 0.3 else "idle", 0.2)
	if not hit_done and t >= TC - 0.3:
		hit_done = true
		var dvec := Vector3(B.x, 0.5, B.y) - def.body_pos()
		dvec.y = 0
		def.hurt = 0.0
		_gk_dive(def, B, Vector2(-di, 0))
		outcome = "a bola %s a linha (%d cm)" % ["passou toda" if L.get("m", 0.0) >= Partida.LINE_IN else "não passou toda", int(round((float(L.get("m", 0.0)) - Partida.LINE_IN) * 100))]
	var B3 := Vector3(B.x, 0.11 + float(sc.bh), B.y)
	if t < tk: b3 = Vector3(Pk.x, 0.11, Pk.y)
	elif t < TC: b3 = _arc(Vector3(Pk.x, 0.11, Pk.y), B3, 0.6, (t - tk) / (TC - tk))
	elif t < TC + 0.7: b3 = B3.lerp(Vector3(B.x, 0.11, B.y), clamp((t - TC) / 0.3, 0.0, 1.0))
	else: b3 = Vector3(B.x, 0.11, B.y).lerp(Vector3(gx - di * 1.0, 0.25, B.y), clamp((t - TC - 0.7) / 0.4, 0.0, 1.0))

# mergulho do guarda-redes em mocap: escolhe o lado do clip (normal ou espelhado)
# que deixa o guarda-redes mais de frente para o remate e roda-o para a bola
func _gk_dive(j: Jogador, target: Vector2, face: Vector2) -> void:
	var b := j.body_pos()
	var dv := target - Vector2(b.x, b.z)
	if dv.length() < 0.05: dv = Vector2(0, 1)
	var best := ""; var bd := Vector2.ZERO; var bs := -9.0
	for c in ["gk_dive", "gk_dive_m"]:
		var m: Vector3 = (j.fk(c, 1.3)[0] as Transform3D).origin - (j.fk(c, 0.4)[0] as Transform3D).origin
		var yaw := atan2(dv.x, dv.y) - atan2(m.x, m.z)
		var d := Vector2(sin(yaw), cos(yaw))
		if d.dot(face) > bs: bs = d.dot(face); best = c; bd = d
	j.kin(best, 0.25, bd, Vector2(b.x, b.z), 1.3, "fica", 0.1)

# 9) fora de jogo: o momento do passe, visto pelo assistente
func _offside(dt: float) -> void:
	for e in sc.list:
		var j: Jogador = e[0]
		var s: Dictionary = e[1]
		var p0: Vector2 = s.p
		var v: Vector2 = s.get("v", Vector2.ZERO)
		var dtt := t - TC
		var k: float = dtt if dtt < 0.9 else 0.9 + (dtt - 0.9) * 0.3
		var sp: float = v.length() if dtt < 0.9 else v.length() * 0.3
		var d := v.normalized() if v.length() > 0.3 else Vector2(float(sc.dir) * (1 if int(s.team) == int(L.oi.team) else -1), 0)
		if j == sc.passer and t > TC - 0.4 and t < TC + 0.5:
			j.move(p0 + v * k, d, sp); j.play("kick", 0.08)
		else:
			j.move(p0 + v * k, d, sp); j.play("run" if sp > 4 else ("jog" if sp > 0.8 else "idle"), 0.3)
	var pas: Dictionary = {}
	for e in sc.list:
		if e[0] == sc.passer: pas = e[1]
	if not pas.is_empty():
		var pv: Vector2 = pas.get("v", Vector2.ZERO)
		var pd := pv.normalized() if pv.length() > 0.3 else Vector2(float(sc.dir), 0)
		var from: Vector2 = pas.p + pd * 0.55
		if t < TC: b3 = Vector3(from.x + pv.x * (t - TC), 0.11, from.y + pv.y * (t - TC))
		else:
			var tg: Vector2 = sc.target
			var q := from.lerp(tg, clamp((t - TC) / 1.2, 0.0, 1.0))
			b3 = Vector3(q.x, 0.11, q.y)
	if not hit_done and t >= TC:
		hit_done = true

# A verdade do fora de jogo mede-se no corpo 3D que se vê, no instante do passe: a parte mais adiantada
# do atacante (sem braços) contra a do penúltimo defesa (o guarda-redes conta-se como último) e a bola.
func _measure_offside() -> void:
	sc.measured_t = t
	var dv := Vector3(float(sc.dir), 0, 0)
	var ax: float = att.extreme(dv).x * float(sc.dir)
	var dx := -INF
	for e in sc.list:
		var s: Dictionary = e[1]
		if int(s.team) == int(L.oi.team) or s.role == "gk": continue
		var x: float = (e[0] as Jogador).extreme(dv).x * float(sc.dir)
		if x > dx: dx = x; sc.line_j = e[0]
	var bx: float = b3.x * float(sc.dir)
	var line: float = maxf(dx, bx)
	var m: float = ax - line
	sc.true_lines = [ax * float(sc.dir), line * float(sc.dir)]
	if L.is_empty() or L.has("decided"): return
	L.oi.margin = m
	L.truth = "fora" if m > 0 else "emjogo"
	outcome = "%s por %d cm" % [Partida.LABEL[L.truth], int(round(absf(m) * 100))]

# 10) golo em análise: o atacante usa o braço (ou só o ombro) antes de rematar
func _goalfoul(dt: float) -> void:
	var C: Vector2 = sc.C
	var Gp: Vector2 = sc.G
	var perp := Vector2(-A.y, A.x) * float(sc.s)
	var T: String = sc.truth
	var v := 5.0
	var TS := TC + 0.48
	var ap := C + A * v * (t - TC)
	if t < TS + 0.35:
		if t > TS - 0.35: att.move(C + A * v * (TS - 0.35 - TC) + A * 1.5 * (t - TS + 0.35), A, 1.5); att.play("kick", 0.08)
		else: att.move(ap, A, v); att.play("run", 0.2)
	else: _settle(att, dt, A)
	var gap: float = lerp(1.4, 0.45, clamp(t / TC, 0.0, 1.0))
	if not def.rag:
		if t < TC: def.move(ap - A * 0.25 + perp * gap, A, v); def.play("run", 0.2)
		else:
			var sl: float = maxf(0.0, v - 5.0 * (t - TC))
			def.move(def.pos + A * sl * dt + perp * (1.2 if T == "anular" else 0.4) * dt, A, sl); def.play("jog" if sl > 1 else "idle", 0.3)
	var w: float = clamp(1.0 - absf(t - TC) / 0.3, 0.0, 1.0)
	if T == "anular":
		var db := def.body_pos()
		var hn := "wrist_L" if att.bone_world("wrist_L").distance_to(db) < att.bone_world("wrist_R").distance_to(db) else "wrist_R"
		att.ik = {hn: [def.bone_world("spine02") + Vector3(0, 0.08, 0), w]}
		att.lean = Vector3(0, 0, 0.2 * w * float(sc.s))
	else:
		att.lean = Vector3(0, 0, 0.25 * w * float(sc.s)); def.lean = Vector3(0, 0, -0.22 * w * float(sc.s))
	if not hit_done and t >= TC:
		hit_done = true
		var p3 := Vector3(perp.x, 0, perp.y)
		if T == "anular":
			def.push(perp * 3.0); def.hit(Vector3(0, 0, 1.2 * float(sc.s)))
			if sc.fall: def.hurt = 0.2; def.fall(Vector3(A.x, 0, A.y) * v * 0.6 + p3 * 2.4 + Vector3(0, 0.3, 0), ["spine03", "upperarm01_L", "upperarm01_R"], p3 * 3.2, "dive", 0.5)
			outcome = "o atacante afasta o defesa com o braço antes de rematar"
		else:
			def.push(perp * 1.2); att.hit(Vector3(0, 0, -0.5 * float(sc.s)))
			if sc.fall: def.hurt = 0.1; def.fall(Vector3(A.x, 0, A.y) * v * 0.6 + p3 * 1.2 + Vector3(0, 0.3, 0), [], Vector3.ZERO, "dive", 0.8)
			outcome = "ombro com ombro, os dois à bola"
	# guarda-redes
	var gk: Jogador = extras[0]
	if gk.node.visible and not gk.rag and gk.phase != "kin" and gk.phase != "chao_k":
		var g0 := Vector2(float(sc.gx) - float(sc.dir_in) * 0.8, lerp(H / 2, Gp.y, 0.3))
		gk.move(g0, Vector2(-float(sc.dir_in), 0), 0.0); gk.play("idle", 0.3)
		if t > TS + 0.15:
			var dv := Vector3(Gp.x, 0.6, Gp.y) - gk.body_pos(); dv.y = 0
			if gk.phase != "kin": _gk_dive(gk, Gp, Vector2(-float(sc.dir_in), 0))
	if not b3_free:
		if t < TS: b3 = Vector3(ap.x + A.x * 0.6, 0.11, ap.y + A.y * 0.6)
		else:
			b3_free = true
			var G3 := Vector3(Gp.x, 0.11 + 0.9, Gp.y)
			bv3 = (G3 - b3) / 0.55 + Vector3(0, 9.8 * 0.55 * 0.5, 0)
			b3_net = float(sc.gx) + float(sc.dir_in) * 1.6

# ---------- câmara ----------
func _focus() -> Vector3:
	match lance:
		5: return Vector3(P.x, 1.5, P.y)
		7: return Vector3(sc.Q.x, 1.0, sc.Q.y)
		8: return Vector3(sc.B.x, 0.4, sc.B.y)
		9: return Vector3(sc.line_x, 0.9, sc.recv.y)
		10: return Vector3(b3.x, 0.8, b3.z).lerp(Vector3(P.x, 0.9, P.y), 0.4)
	return Vector3(P.x, 0.9, P.y)

func _camera() -> void:
	var look := _focus()
	refj.node.visible = modo != "treino" and cam_mode != 0 and lance != 9
	if cam_mode == 0:
		var eye := Vector3(REF.x, 1.75, REF.y)
		if lance == 9: eye = Vector3(sc.ast.x, 1.7, sc.ast.y)
		# nervos: a imagem treme
		var st: float = float(L.get("stress", 0.0)) if modo != "treino" else 0.0
		var amp: float = maxf(0.0, (st - 40.0) / 60.0) * 0.022 * eye.distance_to(look)
		var tm := Time.get_ticks_msec() / 1000.0
		var shake := Vector3(sin(t * 3.1) * 0.02, sin(t * 4.3) * 0.015, 0) + Vector3(amp * (sin(tm * 7.3) + 0.5 * sin(tm * 13.1)), amp * 0.6 * sin(tm * 9.7 + 1), amp * (sin(tm * 6.1 + 2) + 0.5 * sin(tm * 11.3)))
		cam.fov = 38 if eye.distance_to(look) < 25 else 30
		cam.look_at_from_position(eye + shake, look + shake * 0.5)
	elif lance == 9 and modo in ["var", "rever"] and t >= TC - 0.01:
		_var_camera()
	elif cam_mode == 4:
		_tv_camera(look)
	elif cam_mode == 1:
		if lance == 9:
			var sy: float = -7.0 if float(sc.ast.y) < H / 2 else H + 7.0
			cam.fov = 34
			cam.look_at_from_position(Vector3(sc.line_x, 9, sy), Vector3(sc.line_x, 0.3, sc.recv.y))
			return
		if lance == 8:
			var B: Vector2 = sc.B
			var cz := H / 2 - 3.66 - 2.5 if B.y < H / 2 else H / 2 + 3.66 + 2.5
			cam.fov = 28
			cam.look_at_from_position(Vector3(sc.gx, 0.45, cz), Vector3(sc.gx, 0.2, B.y))
			return
		if lance == 6:
			var Sd: Vector2 = sc.Sd
			var dp := def.body_pos()
			var sdv := Vector2(-Sd.y, Sd.x)
			cam.fov = 40
			cam.look_at_from_position(Vector3(dp.x + sdv.x * 5.0 - Sd.x * 1.5, 1.3, dp.z + sdv.y * 5.0 - Sd.y * 1.5), Vector3(dp.x - Sd.x * 1.5, 1.0, dp.z - Sd.y * 1.5))
			return
		var sd := Vector2(-A.y, A.x)
		var a3: Vector3 = att.body_pos()
		var d3: Vector3 = def.body_pos()
		var mid := Vector2((a3.x + d3.x) * 0.5, (a3.z + d3.z) * 0.5)
		var gap := Vector2(a3.x - d3.x, a3.z - d3.z).length()
		var c2 := mid + sd * (6.5 + gap * 0.6)
		cam.fov = 45
		cam.look_at_from_position(Vector3(c2.x, 1.4 + (0.6 if lance == 5 else 0.0), c2.y), Vector3(mid.x, 0.7 + (0.6 if lance == 5 else 0.0), mid.y))
	elif cam_mode == 3:
		var bp3 := att.body_pos()
		cam.fov = 40
		cam.look_at_from_position(Vector3(bp3.x - A.y * 4.6 + A.x * 1.2, 1.7, bp3.z + A.x * 4.6 + A.y * 1.2), Vector3(bp3.x, 0.5, bp3.z))
	else:
		var a3: Vector3 = att.body_pos()
		var c3 := Vector2(a3.x, a3.z) - A * 8.0 + Vector2(0, 1.5)
		cam.fov = 40
		cam.look_at_from_position(Vector3(c3.x, 1.6, c3.y), Vector3(a3.x, 0.6, a3.z))

# câmaras do VAR no fora de jogo (C troca): 1 câmara da linha, de lado e com zoom nos dois;
# 2 de cima, perto; 3 rasante, ao nível da relva
func _var_camera() -> void:
	var a3 := att.body_pos()
	var d3 := (sc.get("line_j", def) as Jogador).body_pos()
	var mx := (a3.x + d3.x) * 0.5
	var my := (a3.z + d3.z) * 0.5
	var span := absf(a3.z - d3.z) + 3.0
	var sy: float = -6.0 if float(sc.ast.y) < H / 2 else H + 6.0
	match cam_mode:
		2:
			cam.fov = 45
			cam.look_at_from_position(Vector3(mx, maxf(6.0, span * 1.1), my + (0.5 if sy > H / 2 else -0.5)), Vector3(mx, 0, my))
		3:
			var eye := Vector3(mx, 1.0, my + (span * 0.5 + 6.0) * (1.0 if sy > H / 2 else -1.0))
			cam.fov = 40
			cam.look_at_from_position(eye, Vector3(mx, 0.7, my))
		_:
			var eye := Vector3(mx, 12.0, sy)
			var look := Vector3(mx, 0.6, my)
			var dist := eye.distance_to(look)
			cam.fov = clamp(rad_to_deg(2.0 * atan((span * 0.5 + 1.2) / dist)), 6.0, 40.0)
			cam.look_at_from_position(eye, look)

# linhas do VAR no fora de jogo
func _var_lines() -> void:
	var on := modo == "var" and lance == 9 and sc.has("lines")
	# ao rever depois de decidir: as linhas certas, medidas no corpo
	var real := modo == "rever" and lance == 9 and sc.has("true_lines") and t >= TC
	for i in 2:
		var_mesh[i].visible = on or real
		if real:
			var_mesh[i].position = Vector3(float(sc.true_lines[i]), 0.02, H / 2); var_mesh[i].scale = Vector3(1.6, 1, 1)
		elif on:
			var_mesh[i].position = Vector3(var_line[i], 0.02, H / 2)
			var_mesh[i].scale = Vector3(2.2 if i == var_sel else 1.0, 1, 1)

# ---------- noite: céu escuro, projetores acesos ----------
func _set_night(on: bool) -> void:
	night = on
	if on:
		sky_mat.sky_top_color = Color(0.02, 0.03, 0.07); sky_mat.sky_horizon_color = Color(0.09, 0.1, 0.16); sky_mat.ground_horizon_color = Color(0.06, 0.07, 0.08)
		env.ambient_light_energy = 0.3
		sun.rotation_degrees = Vector3(-68, 25, 0); sun.light_energy = 1.05; sun.light_color = Color(0.93, 0.96, 1.0)
		env.glow_intensity = 0.7; env.glow_bloom = 0.12
	else:
		sky_mat.sky_top_color = Color(0.32, 0.5, 0.78); sky_mat.sky_horizon_color = Color(0.72, 0.8, 0.9); sky_mat.ground_horizon_color = Color(0.5, 0.55, 0.5)
		env.ambient_light_energy = 0.55
		sun.rotation_degrees = Vector3(-48, -35, 0); sun.light_energy = 1.45; sun.light_color = Color(1, 1, 1)
		env.glow_intensity = 0.4; env.glow_bloom = 0.05
	for f in floods:
		(f[0] as StandardMaterial3D).emission_energy_multiplier = 6.0 if on else 0.0
		(f[1] as OmniLight3D).light_energy = 0.9 if on else 0.0

# ---------- televisão ----------
func _tv_ui() -> void:
	tv_layer = CanvasLayer.new(); tv_layer.layer = 6; add_child(tv_layer)
	for i in 2:
		var b := ColorRect.new(); b.color = Color(0, 0, 0, 0.92); b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.anchor_right = 1.0; b.offset_bottom = 46
		if i == 1: b.anchor_top = 1.0; b.anchor_bottom = 1.0; b.offset_top = -46; b.offset_bottom = 0
		b.visible = false; tv_layer.add_child(b); tv_bars.append(b)
	tv_wipe = ColorRect.new(); tv_wipe.color = Color("12305e"); tv_wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv_wipe.anchor_right = 1.0; tv_wipe.anchor_bottom = 1.0; tv_wipe.visible = false; tv_layer.add_child(tv_wipe)
	var stripe := ColorRect.new(); stripe.color = Color("f2cf3a"); stripe.anchor_top = 0.5; stripe.anchor_bottom = 0.5; stripe.anchor_right = 1.0
	stripe.offset_top = 34; stripe.offset_bottom = 40; tv_wipe.add_child(stripe)
	var wl := Label.new(); wl.text = "REPETIÇÃO"; wl.add_theme_font_size_override("font_size", 54); wl.add_theme_color_override("font_color", Color(1, 1, 1))
	wl.anchor_right = 1.0; wl.anchor_top = 0.5; wl.anchor_bottom = 0.5; wl.offset_top = -40; wl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tv_wipe.add_child(wl)
	tv_tag = Label.new(); tv_tag.add_theme_font_size_override("font_size", 17); tv_tag.add_theme_color_override("font_color", Color("f2cf3a"))
	tv_tag.anchor_left = 1.0; tv_tag.anchor_right = 1.0; tv_tag.offset_left = -420; tv_tag.offset_right = -18; tv_tag.offset_top = 12
	tv_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; tv_tag.visible = false; tv_layer.add_child(tv_tag)

func tv_start() -> void:
	if not (modo in ["var", "rever", "treino"]) or lance == 9: return
	tv = {"i": 0}
	_tv_shot()

func _tv_shot() -> void:
	var sh: Array = TV_SHOTS[tv.i]
	cam_mode = sh[0]
	_restart()
	tv.from = TC + float(sh[1]); tv.to = TC + float(sh[2]); tv.slow = float(sh[3]); tv.name = sh[4]; tv.live = false
	tv_wipe.visible = true; tv_wipe.position.x = 0
	for b in tv_bars: b.visible = true
	tv_tag.visible = false

func _tv_end() -> void:
	tv = {}
	speed = 0.75 if modo == "var" else 1.0
	tv_wipe.visible = false; tv_tag.visible = false
	for b in tv_bars: b.visible = false
	cam_mode = 1

# chamado no início de cada imagem do lance: acelera até ao início do plano (com a cortina), depois câmara lenta
func _tv_step() -> void:
	if tv.is_empty(): return
	if t < tv.from:
		speed = 8.0
	else:
		speed = tv.slow
		if not tv.live:
			tv.live = true
			tv_tag.text = "REPETIÇÃO · %s · %sx" % [tv.name, ("%.2f" % tv.slow).replace(".", ",").trim_suffix("0")]
			tv_tag.visible = true
			var tw := create_tween(); tw.set_ignore_time_scale(true)
			tw.tween_property(tv_wipe, "position:x", get_viewport().get_visible_rect().size.x, 0.3)
		if t > tv.to:
			tv.i += 1
			if tv.i < TV_SHOTS.size(): _tv_shot()
			else: _tv_end()

# câmara de transmissão: no alto da bancada principal, segue o lance com zoom
func _tv_camera(look: Vector3) -> void:
	if tv_look == Vector3.ZERO or tv_look.distance_to(look) > 25.0: tv_look = look
	tv_look = tv_look.lerp(look, 0.08)
	var eye := Vector3(clamp(tv_look.x * 0.8 + W * 0.1, 8.0, W - 8.0), 17.0, -15.0)
	var dist := eye.distance_to(tv_look)
	cam.fov = rad_to_deg(2.0 * atan(8.5 / dist))
	cam.look_at_from_position(eye, tv_look)

# ---------- fluxo da partida ----------
func _ev(n: String, d: Dictionary) -> void:
	match n:
		"toast": ui.toast(d.txt, d.secs)
		"radio":
			ui.radio(d.who, d.txt); som.radio(); som.say(d.txt, d.who)
		"feed":
			ui.feed(d)
			if d.kind in ["goal", "card", "pen"]: som.say(d.txt, "Relato")
		"sfx": _sfx(d.k, d.a)
		"lance":
			L = d.L
			ui.flash(L.get("flash", "Lance!"))
			flash_t = 0.7; modo = "flash"
		"var": _enter_var()
		"decided": _start_gesture(d)
		"ask": ui.show_ask(d.msg, d.tag, d.opts)
		"ask_end", "protest_end": ui.hide_ask()
		"protest":
			var tr: float = d.trust
			ui.show_protest(d.msg + ". O capitão " + ("confia em ti." if tr > 0.6 else ("desconfia de ti." if tr < 0.35 else "ainda te ouve.")))
		"half":
			_to_2d(); modo = "intervalo"; ui.show_half(d)
		"end": call_deferred("_end", d)
		"tut": ui.show_tut(d)
		"tut_end": _show_menu()

func _sfx(k: String, a) -> void:
	match k:
		"whistle": som.whistle(a if a != null else "short")
		"kick": som.kick(a if a != null else 0.5)
		"cheer": som.cheer(a if a != null else 0.6)
		"boo": som.boo(a if a != null else 0.5)
		"ooh": som.ooh()
		"beep": som.beep()
		"react": som.react(a if a != null else 0.5)

func _new_match(teams: Array, career := false) -> void:
	ui.hide_all()
	jogo = Partida.new(teams)
	jogo.ev = _ev
	campo.jogo = jogo
	is_career = career
	_set_night(rng.randf() < 0.45)
	L = {}; G = {}; match_paused = false
	_to_2d()
	modo = "jogo"
	som.whistle("long")
	jogo.feed("Apito inicial: %s contra %s." % [teams[0].name, teams[1].name], "info")

func _to_2d() -> void:
	visible = false
	get_viewport().disable_3d = true
	campo.visible = true
	paused = false; speed = 1.0
	get_tree().paused = false; Engine.time_scale = 1.0
	ui.info("", ""); ui.ref_say(""); ui.dec.visible = false; ui.var_frame.visible = false
	lab1.text = ""; lab2.text = ""
	for m in var_mesh: m.visible = false

func _to_3d() -> void:
	campo.visible = false
	visible = true
	get_viewport().disable_3d = false

func _enter_lance() -> void:
	modo = "lance"
	_setup_scene(L)
	replays = 0; dec_shown = false; cam_mode = 0; paused = false; speed = 1.0
	_to_3d()
	_restart()
	jogo.radio_lance(L)

func _seen_t() -> float:
	match lance:
		6: return TC + 1.0
		8: return TC + 1.2
		9: return TC + 1.3
		10: return TC + 1.7
	return TC + 1.4

func _dflt() -> String:
	if L.has("dflt"): return L.dflt
	if jogo.kind_of(L) == "offside": return "fora" if L.flag else "emjogo"
	return "siga" if "siga" in jogo.choices_for(L) else jogo.choices_for(L)[0]

func _lance_ui(delta: float) -> void:
	var k := jogo.kind_of(L) if jogo and not L.is_empty() else ""
	var hint := ""
	if k == "offside": hint = "vista do assistente · bandeira " + ("levantada" if L.flag else "em baixo")
	elif L.has("dist"):
		hint = "estavas a %d m" % int(L.dist)
		if int(L.get("blockers", 0)) > 0: hint += ", com %d jogador%s a tapar" % [L.blockers, "es" if L.blockers > 1 else ""]
	if modo == "rever":
		ui.info("Revisão · %d' · %s" % [L.minute, Partida.LABEL.get(L.truth, L.truth)], (outcome + "  ·  " if outcome != "" else "") + "C câmara · R repetir · Espaço pausa · S lento · Esc voltar")
		return
	if modo == "lance":
		if L.get("training", false):
			ui.info("Treino do VAR · lance %d de %d" % [jogo.training.get("n", 1), jogo.training.get("total", 6)], "Vê o lance: a decisão de campo vai ao monitor")
			return
		var seen := t > _seen_t() or replays > 0
		ui.info("LANCE AOS %d'  ·  %s" % [L.minute, hint], "R rever · Espaço pausa · S lento" if seen else "")
		if not dec_shown and seen:
			dec_shown = true; dec_left = float(L.decide_t)
			ui.show_dec(jogo.choices_for(L), "")
	elif modo == "var":
		var sub := "Decisão de campo: " + str(Partida.DEC_LABEL.get(L.get("var_first", ""), "")) + " · C câmara · R repetir · S lento"
		if lance == 9 and sc.has("lines"):
			var gap: float = (var_line[0] - var_line[1]) * float(sc.dir)
			sub = "Linhas: Tab troca (vermelha = atacante, azul = penúltimo defesa) · setas mexem · C câmara · atacante %s %d cm %s" % ["", int(round(absf(gap) * 100)), "à frente" if gap > 0 else "atrás"]
		ui.info("MONITOR DO VAR · %d'" % L.minute, sub)
	if dec_shown:
		if not paused: dec_left -= delta
		ui.dec_text("Decide: teclas 1–%d   (%d s)" % [jogo.choices_for(L).size(), int(ceil(maxf(dec_left, 0.0)))])
		if dec_left <= 0: _decide(_dflt(), true)

func _decide(d: String, timed_out := false) -> void:
	if not (modo in ["lance", "var"]) or not dec_shown: return
	dec_shown = false
	ui.dec.visible = false
	jogo.decide(d, timed_out)
	if modo == "lance" and not L.has("decided") and not L.get("var_review", false):
		dec_shown = true; ui.dec.visible = true

func _enter_var() -> void:
	modo = "var"
	replays = 1; cam_mode = 1; paused = false; speed = 0.75
	ui.var_frame.visible = true
	sc.erase("lines")
	_restart()
	dec_shown = true; dec_left = float(L.decide_t) + (6.0 if lance != 9 else 0.0)
	ui.show_dec(jogo.choices_for(L), "")
	tv_start()

func _replay() -> void:
	if not tv.is_empty(): _tv_end()
	if not (modo in ["lance", "var", "rever"]): return
	if modo == "lance" and t < TC + 1.0 and replays == 0: return
	replays += 1
	sc.erase("lines")
	_restart()

func _cam_next() -> void:
	if modo == "lance":
		ui.toast("No jogo só vês o que o árbitro viu. As outras câmaras são do VAR e da revisão.", 2.5); return
	if lance == 9 and modo in ["var", "rever"] and t >= TC - 0.01:
		cam_mode = cam_mode % 3 + 1
		ui.toast(["", "Câmara da linha", "De cima", "Rasante"][cam_mode], 1.2); return
	cam_mode = (cam_mode + 1) % 5
	ui.toast(["A tua vista", "Vista ideal", "Atrás do lance", "De perto", "Câmara de televisão"][cam_mode], 1.2)

# ---------- gestos do árbitro ----------
func _start_gesture(d: Dictionary) -> void:
	modo = "gesto"
	ui.dec.visible = false; ui.var_frame.visible = false
	ui.ref_say(d.say)
	som.say(str(d.say).replace("Vi as imagens. ", ""), "Árbitro")
	var g: Dictionary = d.gest
	if g.type == "card": som.whistle("short")
	G = {"g": g, "t": 0.0, "dur": float(g.dur), "d": d.d}
	paused = false; speed = 1.0
	get_tree().paused = false; Engine.time_scale = 1.0
	_to_3d()
	for j in [att, def, refj] + extras: j.reset(); j.node.visible = false
	ball.visible = false
	for m in var_mesh: m.visible = false
	var Pg: Vector2 = g.spot
	var u: Vector2 = (L.ref - Pg).normalized()
	if u == Vector2.ZERO: u = Vector2(0, 1)
	G.P = Pg; G.u = u; G.R = Pg + u * 2.3
	if int(g.who) >= 0:
		var pl = jogo.players[int(g.who)]
		_dress(att, {"team": pl.team, "num": pl.num, "role": pl.role})
		att.move(Pg, u, 0.0); att.play("idle", 0.0)
	refj.set_kit(_ref_kit(), 0, 2); refj.node.visible = true
	refj.move(G.R, -u, 0.0); refj.play("idle", 0.0)
	(card.material_override as StandardMaterial3D).albedo_color = Color("d8322f") if g.get("col", "") == "red" else Color("f2cf3a")
	ui.info(str(Partida.DEC_LABEL.get(d.d, "")), "Decisão do árbitro · Espaço ou clique para continuar")
	if grass_mi: grass_mi.position = Vector3(Pg.x, 0, Pg.y)

func _gesture_process(delta: float) -> void:
	if G.is_empty(): return
	G.t += delta
	var g: Dictionary = G.g
	var rp: Vector2 = G.R
	var face: Vector2 = -G.u
	var running := false
	if g.type == "point" and g.get("run", false):
		var dc: Vector2 = (g.to - G.R).normalized()
		var m: float = minf(G.t, 1.6) * 1.3
		rp = G.R + dc * m; face = face.lerp(dc, 0.6).normalized(); running = G.t < 1.6
	refj.move(rp, face, 1.3 if running else 0.0); refj.play("jog" if running else "idle", 0.3)
	var w: float = smoothstep(0.0, 1.0, (G.t - 0.15) / 0.4)
	var fwd := Vector3(face.x, 0, face.y)
	var rgt := Vector3(-face.y, 0, face.x)
	var upv := Vector3.UP
	var shR := refj.bone_world("upperarm01_R")
	var shL := refj.bone_world("upperarm01_L")
	if (shR - shL).dot(rgt) < 0: rgt = -rgt
	card.visible = false
	match g.type:
		"card", "up":
			refj.ik = {"wrist_R": [shR + upv * 0.62 + fwd * 0.08 + rgt * 0.05, w]}
			if g.type == "card":
				card.visible = w > 0.3
				var red: bool = g.get("col", "") == "red" or (g.get("second", false) and G.t > 1.6)
				(card.material_override as StandardMaterial3D).albedo_color = Color("d8322f") if red else Color("f2cf3a")
		"adv":
			refj.ik = {"wrist_R": [shR + fwd * 0.6 + rgt * 0.12, w], "wrist_L": [shL + fwd * 0.6 - rgt * 0.12, w]}
		"point":
			var dir: Vector2 = (g.to - rp).normalized() if g.has("to") else g.dir
			var el: float = g.elev
			var v3 := Vector3(dir.x * cos(el), -sin(el), dir.y * cos(el)).normalized()
			var right := v3.dot(rgt) >= 0
			refj.ik = {("wrist_R" if right else "wrist_L"): [(shR if right else shL) + v3 * 0.62, w]}
		_:
			refj.ik = {"wrist_R": [shR + fwd * 0.45 + rgt * 0.2 + upv * (-0.3 + 0.25 * sin(G.t * 5.0)), w]}
	for j in [att, refj]:
		if j.node.visible: j.update(delta, G.t); j.ground()
	# câmara de frente para o árbitro, com o jogador ao lado
	var u: Vector2 = G.u
	var sd := Vector2(-u.y, u.x)
	var look := Vector3(lerp(rp.x, G.P.x, 0.3), 1.3, lerp(rp.y, G.P.y, 0.3))
	var c := rp - u * 3.8 + sd * 3.4
	if c.x < -3 or c.x > W + 3 or c.y < -3 or c.y > H + 3: c = rp - u * 3.8 - sd * 3.4
	if running or g.get("run", false):
		var dc2: Vector2 = (g.to - G.R).normalized()
		c = rp + dc2 * 4.5 + Vector2(-dc2.y, dc2.x) * 2.2
		look = refj.node.position + Vector3(0, 1.25, 0)
	cam.fov = 42
	cam.look_at_from_position(Vector3(clamp(c.x, -3, W + 3), 1.6, clamp(c.y, -3, H + 3)), look)
	if G.t >= G.dur: _end_gesture()

func _end_gesture() -> void:
	if G.is_empty(): return
	G = {}
	card.visible = false
	ui.ref_say("")
	jogo.finish_after()
	if jogo.mode == "fim" or modo == "fim": return
	if modo == "gesto": _back_to_match()

func _back_to_match() -> void:
	_to_2d()
	modo = "jogo"
	L = {}

func _end(d: Dictionary) -> void:
	modo = "fim"; G = {}
	_to_2d()
	ui.hide_all()
	end_data = d
	if d.kind != "treino": jogo.paper = Carreira.paper_of(jogo, d.grade, d.kind)
	var note := ""
	if is_career: note = car.after(jogo, d.grade, d.kind)
	var best := _best()
	if d.kind != "treino" and d.grade > best:
		var cf := ConfigFile.new(); cf.set_value("j", "best", d.grade); cf.save("user://melhor.cfg")
	ui.show_report(jogo, d, note, is_career)

func _best() -> float:
	var cf := ConfigFile.new()
	if cf.load("user://melhor.cfg") != OK: return 0.0
	return float(cf.get_value("j", "best", 0.0))

# ---------- rever um lance (intervalo e relatório) ----------
func _review(l: Dictionary) -> void:
	rever_de = "half" if modo == "intervalo" else "report"
	ui.half.visible = false; ui.report.visible = false
	L = l; modo = "rever"
	_setup_scene(l)
	cam_mode = 1; paused = false; speed = 1.0; replays = 1
	_to_3d()
	_restart()
	ui.show_dec([], "")
	ui.dec_row.add_child(ui._btn("Voltar", func(): _end_review(), Color(0.3, 0.2, 0.2), 0, 16))

func _end_review() -> void:
	if modo != "rever": return
	ui.dec.visible = false
	_to_2d()
	if rever_de == "half": modo = "intervalo"; ui.half.visible = true
	else: modo = "fim"; ui.report.visible = true
	L = {}

# ---------- menu e botões ----------
func _show_menu() -> void:
	_set_night(false)
	modo = "menu"; paused = false; speed = 1.0
	get_tree().paused = false; Engine.time_scale = 1.0
	_to_3d()
	for j in [att, def, refj] + extras: j.reset(); j.node.visible = false
	ball.visible = false
	for m in var_mesh: m.visible = false
	lab1.text = ""; lab2.text = ""
	ui.info("", ""); ui.ref_say("")
	som.set_crowd(0.15)
	var b := _best()
	ui.show_menu(car.exists(), ("%.1f" % b).replace(".", ",") if b > 0 else "", som.voice_on, not som.muted)

func on_ui(a: String, v) -> void:
	match a:
		"partida": _new_match(Carreira.default_teams())
		"carreira", "career":
			if not car.load_c(): car.new_career()
			modo = "carreira"; _show_menu_bg(); ui.show_career(car)
		"career_play":
			var B := car.match_brief()
			_new_match(Carreira.teams_for(B.h, B.a, car.C.tier), true)
			car.setup_match(jogo)
		"career_reset": car.new_career(); ui.show_career(car)
		"attr": car.add_attr(v); ui.show_career(car)
		"treino_var": _new_match(Carreira.default_teams()); jogo.start_training()
		"tutorial": _new_match(Carreira.default_teams()); jogo.start_tutorial()
		"treino3d": _start_training()
		"voz":
			var on := som.toggle_voice()
			if on: som.say("Rádio ligado.", "VAR")
			_show_menu()
		"som": som.toggle(); _show_menu()
		"decide": _decide(v)
		"replay": _replay()
		"tv": tv_start()
		"camera": _cam_next()
		"ask": if jogo: jogo.ask_pick(v)
		"protest": if jogo: jogo.resolve_protest(v)
		"second_half":
			ui.half.visible = false
			modo = "jogo"; jogo.second_half(v)
		"ver_lance": _review(v)
		"again": _new_match(Carreira.default_teams())
		"menu": _show_menu()
		"tut_click": if jogo: jogo.tut_click()
		"cap": if jogo: ui.show_card(jogo, v, "")

func _show_menu_bg() -> void:
	_to_3d()
	for j in [att, def, refj] + extras: j.reset(); j.node.visible = false
	ball.visible = false

func _start_training() -> void:
	_set_night(false)
	ui.hide_all()
	modo = "treino"
	_to_3d()
	cam_mode = 1
	sc = {"kind": "treino", "approach": true}
	_training_setup()
	cur = {}; _restart()

func _training_setup() -> void:
	P = Vector2(60, 30); A = Vector2(-1, 0); REF = Vector2(70, 46)
	att.set_kit(LARANJA, 9, 1); def.set_kit(AZUL, 4, 0)
	att.label.modulate = Color(0.97, 0.97, 0.95); def.label.modulate = Color(0.97, 0.97, 0.95)
	att.node.visible = true; def.node.visible = true
	var spots := [Vector2(68, 22), Vector2(52, 40), Vector2(75, 33), Vector2(48, 24)]
	for i in extras.size():
		var home := i % 2 == 0
		extras[i].set_kit(AZUL if home else LARANJA, [2, 7, 5, 10, 3, 8][i], 0 if home else 1)
		extras[i].label.modulate = Color(0.97, 0.97, 0.95)
		extras[i].node.visible = i < spots.size()
		extras[i].set_meta("spot", spots[i] if i < spots.size() else Vector2(-40, -40))

func next_lance() -> void:
	lance = (lance + 1) % LANCES.size()
	cur = {}
	_restart()

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		var kc: int = e.keycode
		if kc == KEY_ESCAPE:
			if modo == "rever": _end_review()
			elif modo in ["jogo", "treino", "carreira", "fim"]: _show_menu()
			return
		match modo:
			"lance", "var":
				if kc >= KEY_1 and kc <= KEY_6 and dec_shown:
					var ch: Array = jogo.choices_for(L)
					var i := kc - KEY_1
					if i < ch.size(): _decide(ch[i])
				elif kc == KEY_R: _replay()
				elif kc == KEY_C: _cam_next()
				elif kc == KEY_T: tv_start()
				elif kc == KEY_SPACE: paused = not paused
				elif kc == KEY_S: speed = 0.3 if speed > 0.5 else (0.75 if modo == "var" else 1.0)
				elif modo == "var" and sc.has("lines"):
					var stp := 0.01 if e.shift_pressed else 0.05
					if kc == KEY_TAB: var_sel = 1 - var_sel
					elif kc == KEY_LEFT or kc == KEY_A: var_line[var_sel] -= stp
					elif kc == KEY_RIGHT or kc == KEY_D: var_line[var_sel] += stp
			"rever":
				if kc == KEY_T: tv_start()
				elif kc == KEY_R: _replay()
				elif kc == KEY_C: _cam_next()
				elif kc == KEY_SPACE: paused = not paused
				elif kc == KEY_S: speed = 0.3 if speed > 0.5 else 1.0
			"gesto":
				if kc == KEY_SPACE or kc == KEY_ENTER: _end_gesture()
			"jogo":
				if jogo.mode == "pergunta" and kc >= KEY_1 and kc <= KEY_4: jogo.ask_pick(kc - KEY_1)
				elif jogo.mode == "protesto" and kc >= KEY_1 and kc <= KEY_4: jogo.resolve_protest(["ignorar", "afastar", "capitao", "amarelo"][kc - KEY_1])
				elif kc == KEY_SPACE:
					match_paused = not match_paused
					ui.toast("Pausa · Espaço para continuar" if match_paused else "Continua", 1.5 if not match_paused else 999.0)
			"treino":
				match kc:
					KEY_1: cam_mode = 0
					KEY_2: cam_mode = 1
					KEY_3: cam_mode = 2
					KEY_4: cam_mode = 3
					KEY_5: cam_mode = 4
					KEY_T: tv_start()
					KEY_SPACE: paused = not paused
					KEY_S: speed = 0.25 if speed == 1.0 else 1.0
					KEY_R: cur = {}; _restart()
					KEY_N: next_lance()
	if e is InputEventMouseButton and e.pressed:
		if modo == "gesto": _end_gesture()
		elif modo == "treino": cam_mode = (cam_mode + 1) % 4
	if e is InputEventScreenTouch and e.pressed:
		if modo == "gesto": _end_gesture()
		elif modo == "treino":
			if e.position.x > get_viewport().get_visible_rect().size.x * 0.75: next_lance()
			else: cam_mode = (cam_mode + 1) % 4


# ---------- lances base (entrada, empurrão, puxão, ombro, pisão) ----------
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
	# na simulação o defesa trava antes: o pé fica a um metro do atacante, que se atira na mesma
	var C := P - D * (0.8 if not sim_dive else 2.5)
	# corte limpo: o atacante empurra a bola um pouco mais e o defesa chega à bola antes de chegar ao homem
	if clean:
		C = P + A * 1.0 - D * 0.75
		if t > TC - 0.5 and t < TC - 0.45 and not free_ball: bvel = A * (vA + 2.4)
	# carrinho: nas faltas a sério e nos cortes limpos o defesa atira-se de pés para a frente e desliza
	var sl := lance == 0 and not sim_dive and (clean or force >= 0.82)
	var dp: Vector2
	if t < TC: dp = C - D * vD * (TC - t)
	else: dp = C + D * 1.6 * (1.0 - exp(-(t - TC) * 3.0))
	if sl:
		# carrinho capturado (Mixamo): o pé da frente chega ao tornozelo (ou à bola) exatamente em TC
		if slp.is_empty(): slp = _slide_plan(P + A * 1.4 if clean else P)
		if t < slp.ts:
			def.move(slp.at - D * vD * (slp.ts - t), D, vD); def.play("run", 0.1)
		elif not slp.get("on", false):
			slp.on = true
			def.kin("tackle", slp.s0, D, slp.at, slp.k, "anim")
		elif def.phase == "anim": _settle(def, dt, D)
	elif def.phase == "anim":
		def.move(dp, D, vD if t < TC else max(0.0, vD * exp(-(t - TC) * 3.0)))
		if t > TC - 0.62: def.play("kick", 0.1)
		if t > TC + 0.9: def.play("jog", 0.3)
	# o pé do defesa vai mesmo ao tornozelo (ou à bola, na simulação)
	var leg := _leg_of(att, def.bone_world("foot_R"))
	var tgt := att.bone_world("foot_" + leg) + Vector3(0, 0.05, 0) if not (sim_dive or clean) else Vector3(bpos.x, 0.11, bpos.y)
	if sim_dive: tgt = Vector3(P.x - D.x * 1.5, 0.1, P.y - D.y * 1.5)
	if stamp and not clean: tgt = att.bone_world("foot_" + leg) - Vector3(A.x, 0, A.y) * 0.1 + Vector3(0, 0.07, 0)
	var w: float = clamp(1.0 - abs(t - TC) / 0.28, 0.0, 1.0)
	if not sl: def.ik = {"foot_R": [tgt, w]}
	if not hit_done and t >= TC:
		hit_done = true
		att.hurt_leg = leg
		var v3 := Vector3(A.x, 0, A.y) * vA
		if sim_dive:
			free_ball = true; bvel = A * 3.0
			outcome = "SIMULAÇÃO: o defesa trava e não lhe toca; o atacante atira-se"
			await get_tree().create_timer(0.18).timeout
			att.hurt = 1.0
			att.fall(v3 * 1.1 + Vector3(0, 1.6, 0), [], Vector3.ZERO, "dive", 0.9)
			return
		free_ball = true; bvel = (A * 0.6 + D * 0.8).normalized() * 6.0
		if clean:
			outcome = "corte limpo: o defesa tira a bola, o atacante só tropeça (siga)"
			bvel = (D * 0.9 - A * 0.2).normalized() * 9.0
			att.hit(Vector3(0.3, 0.0, 0.25 * side))
			att.play("jog", 0.2)
		elif force < 0.78:
			outcome = "toque leve no tornozelo: desequilibra, não cai (falta discutível)"
			att.push(D * 2.2 * force); att.hit(Vector3(0.0, 0.0, 1.2 * side))
			att.play("jog", 0.2)
		elif force < 1.12:
			outcome = "falta: toque claro, cai pelo impacto"
			att.hurt = 0.4
			_trip(att, A, 1.05)
		else:
			outcome = "falta forte (amarelo/vermelho): entrada a varrer com força"
			att.hurt = 1.0
			_trip(att, A, 1.3)
		def.hit(Vector3(-1.6 * force, 1.0, 0.0))
		if def.phase == "desliza": def.slide_hit()
	if hit_done and clean and att.phase == "anim":
		# corte limpo: o atacante perde a bola, trava e desvia-se do carrinho
		var away := (A - D * 0.9).normalized()
		var v: float = maxf(0.0, att.speed - 9.0 * dt)
		att.move(att.pos + away * v * dt, away, v)
		att.play("jog" if v > 1.0 else "idle", 0.25)
	elif hit_done: _settle(att, dt, A)

# tropeção capturado: o corpo cai para a frente como na captura, depois fica queixoso no chão
func _trip(j: Jogador, d: Vector2, k: float) -> void:
	var bp := j.body_pos()
	j.kin("trip", 0.12, d, Vector2(bp.x, bp.z), k, "chao", 0.08)

# quando começar o carrinho, de onde e a que velocidade, para o pé chegar ao alvo no instante TC
func _slide_plan(target: Vector2) -> Dictionary:
	var info: Dictionary = def.slide_key("tackle")
	var key: float = info.key
	var s0: float = maxf(0.0, key - 0.45)
	var r0: Vector3 = def.clip_bone("tackle", s0, "root")
	var rk: Vector3 = def.clip_bone("tackle", key, "root")
	var fkp: Vector3 = def.clip_bone("tackle", key, info.foot)
	var vclip: float = maxf(0.5, (rk.z - r0.z) / maxf(0.05, key - s0))
	var k: float = clamp(vD * 0.75 / vclip, 1.0, 1.7)
	var R := Basis(Vector3.UP, atan2(D.x, D.y))
	var f3 := R * fkp
	var o := target - Vector2(f3.x, f3.z)               # origem do modelo
	var a3 := R * r0
	return {"ts": TC - (key - s0) / k, "s0": s0, "k": k, "at": o + Vector2(a3.x, a3.z)}

# A verdade tem de bater com o que se vê: mede-se a distância real entre as pernas dos dois.
const LEGS := ["foot_L", "foot_R", "lowerleg01_L", "lowerleg01_R"]
func _track_contact() -> void:
	if lance != 0 and lance != 4: return
	for a in LEGS:
		var pa := att.bone_world(a)
		for b in LEGS:
			var pb := def.bone_world(b)
			min_contact = minf(min_contact, pa.distance_to(pb))

func _check_contact() -> void:
	contact_checked = true
	if lance != 0 and lance != 4: return
	# simulação em que, afinal, as pernas se tocaram: é falta
	if sim_dive and min_contact < 0.3:
		outcome = "houve toque na perna: falta"
		if not L.is_empty() and not L.has("decided") and L.truth == "simulacao": L.truth = "falta"
	if OS.is_debug_build(): print("contacto ", "sim" if sim_dive else ("limpo" if clean else "falta"), " %.2f m" % min_contact)

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
	# correm lado a lado e, no último instante, o defesa encosta com o ombro (sem se atravessarem)
	var gap: float = lerp(1.6, 0.9, clamp(t / (TC - 0.35), 0.0, 1.0)) if t < TC - 0.35 else lerp(0.9, 0.5, clamp((t - TC + 0.35) / 0.35, 0.0, 1.0))
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
			if all[i].phase in ["desliza", "kin", "chao_k"] or all[j].phase in ["desliza", "kin", "chao_k"]: continue
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
