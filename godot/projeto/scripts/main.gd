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
# vista do árbitro: corre para o sítio do lance (REF_FIM), com passada, respiração e cansaço
var REF_FIM := Vector2(70, 46)
var ref_ini := Vector2(70, 46)
var ref_cansaco := 0.0        # 0 fresco .. 1 esgotado (energia da partida)
var ref_vel := 0.0
var ref_ph := 0.0             # fase da passada
var ref_olhar := Vector3.ZERO # para onde a cabeça está virada (segue o lance com atraso)
var fp_vig: ColorRect         # vinheta do cansaço
var ref_foco := 0.0
var ref_resp := 0.0           # fase da respiração (soa a cada volta)
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
# contacto real (pele com pele): o lance reage no instante em que os corpos se tocam, não num tempo fixo
var toque := {}               # {"t": instante, "pt": ponto, "g": folga} quando houve toque
var sim_off := 0.0
var desvio := Vector3.ZERO     # quanto o atacante foi afastado para os corpos não se atravessarem
var hitstop := 0.0            # segundos reais do "frame de impacto": imagem quase parada, depois câmara lenta
const HIT_CONGELA := 0.42     # quase parado (como num desenho animado): vê-se bem onde tocou
const HIT_LENTO := 0.4        # depois volta devagar à velocidade normal
var brilhos: Array = []       # membros (e bola) que tocaram, a brilhar por cima de tudo: [{mi, j, i, vida}]
var _estrela: ArrayMesh = null
const PARTES_TOQUE := {0: [["perna", "pe", "tronco"], ["perna", "pe", "tronco", "braco"]], 4: [["perna", "pe", "tronco"], ["perna", "pe", "tronco", "braco"]], 1: [["mao", "braco"], ["tronco"]], 3: [["tronco", "braco"], ["tronco", "braco"]]}
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
var t2d := -1.0            # instante da cena que corresponde ao flash das caricas (antes disso repete o rasto 2D)
# partida
var modo := "menu"         # menu | carreira | jogo | flash | lance | var | gesto | intervalo | rever | treino | fim
var jogo: Partida
var campo: Campo2D
var ui: UI
var radar: Radar          # mini-campo do lance 3D (mesma orientação das caricas)
var pip_box: Panel        # câmara do passe no fora de jogo: quem passa e o instante em que a bola parte
var pip_cam: Camera3D
var pip_lbl: Label
var pip_estilo: StyleBoxFlat
var pip_alvo := Vector3.ZERO
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
const RITMO := 1.5          # velocidade das caricas (com MATCH_SECONDS = 270, o jogo dura 3 minutos reais)
var tv := {}
# vídeo do observador: os lances mal decididos, cada um visto de quatro maneiras
const OBS_SHOTS := [[0, -2.2, 1.4, 1.0, "A tua vista"], [4, -1.2, 1.2, 0.5, "Câmara principal"], [3, -0.5, 0.8, 0.25, "De perto"], [5, -1.4, 1.4, 0.6, "Onde devias estar"]]
const OBS_SHOTS_OFF := [[0, -2.2, 0.6, 1.0, "A vista do assistente"], [1, -1.0, 0.5, 0.4, "Câmara da linha"]]
var obs: Array = []
var obs_i := 0
var obs_cap: Label
var obs_marcas: Array = []      # anéis: onde estavas (vermelho) e onde devias estar (verde)
var social := {}
var entrevista := {}
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
var chuva_p: CPUParticles3D      # chuva à volta da câmara
var fumo_p: CPUParticles3D       # fumo das tochas
var slp := {}              # plano do carrinho capturado
var fan_mesh: ArrayMesh
var nets: Array = []              # materiais das duas redes (abanam com golo)
var rede_abana := 0.0
var fan_mat: ShaderMaterial
var fan_mms: Array = []
var fan_festa := 0.0
var fan_protesto := 0.0
var flags: Array = []             # [ShaderMaterial, lado, x]
var kp := {}               # capturas planeadas por jogador (cabeceamento, remates)
var min_contact := 99.0    # menor distância entre as pernas do defesa e as do atacante à volta do contacto
var contact_checked := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hi_q = RenderingServer.get_current_rendering_method() != "gl_compatibility"
	rng.randomize()
	_world()
	_clima_nodes()
	var corretor := Corretor.new(); corretor.main = self; corretor.process_priority = 1000; add_child(corretor)
	_stadium()
	_fans_colors(AZUL.color, LARANJA.color)
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
	# cartão: colocado a cada frame entre os dedos (ver _card_in_hand), não preso ao pulso
	card = MeshInstance3D.new(); var cb := BoxMesh.new(); cb.size = Vector3(0.075, 0.105, 0.004); card.mesh = cb
	var cm := StandardMaterial3D.new(); cm.albedo_color = Color("f2cf3a"); cm.roughness = 0.35; cm.emission_enabled = true; cm.emission = Color("f2cf3a"); cm.emission_energy_multiplier = 0.25; card.material_override = cm
	card.visible = false; add_child(card)
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
	radar = Radar.new(); radar.main = self; radar.visible = false; layer.add_child(radar)
	pip_box = Panel.new(); pip_box.size = Vector2(358, 204); pip_box.visible = false; pip_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pip_estilo = StyleBoxFlat.new(); pip_estilo.bg_color = Color(0, 0, 0, 0.6); pip_estilo.set_border_width_all(3); pip_estilo.border_color = Color(1, 1, 1, 0.6)
	pip_box.add_theme_stylebox_override("panel", pip_estilo)
	var pc := SubViewportContainer.new(); pc.stretch = true; pc.position = Vector2(3, 3); pc.size = Vector2(352, 198); pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sv := SubViewport.new(); sv.size = Vector2i(352, 198); sv.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	pc.add_child(sv); pip_box.add_child(pc)
	pip_cam = Camera3D.new(); pip_cam.fov = 32.0; sv.add_child(pip_cam)
	pip_lbl = Label.new(); pip_lbl.position = Vector2(10, 6); pip_lbl.add_theme_font_size_override("font_size", 15)
	pip_lbl.add_theme_color_override("font_outline_color", Color.BLACK); pip_lbl.add_theme_constant_override("outline_size", 5)
	pip_box.add_child(pip_lbl)
	layer.add_child(pip_box)
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
		var net := MeshInstance3D.new(); net.mesh = _net_mesh(-1.0 if gx == 0.0 else 1.0)
		var nm := ShaderMaterial.new(); nm.shader = preload("res://shaders/rede.gdshader")
		net.material_override = nm; net.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; goal.add_child(net)
		nets.append(nm)
		# apoios da rede atrás da baliza
		for s in [-1.0, 1.0]:
			var dd := -1.0 if gx == 0.0 else 1.0
			var ap := MeshInstance3D.new(); var ac := CylinderMesh.new(); ac.top_radius = 0.025; ac.bottom_radius = 0.025; ac.height = 2.68
			ap.mesh = ac; ap.material_override = post; ap.position = Vector3(dd * 1.45, 1.22, s * 3.68); ap.rotation.z = dd * 0.423; goal.add_child(ap)

# Rede: teto curto, fundo inclinado até ao chão a 2 m e dois lados; UV em metros para a malha,
# UV2.x = quanto cede (0 junto aos ferros).
func _net_mesh(d: float) -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := 0.9; var fundo := 2.0; var hh := 2.44; var zz := 3.66
	var quad := func(a: Vector3, b: Vector3, c: Vector3, e: Vector3, nx: int, ny: int) -> void:
		# grelha de nx*ny entre os 4 cantos (a-b em cima, e-c em baixo)
		for i in nx:
			for j in ny:
				var pts := []
				for k in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
					var u := float(k[0]) / nx; var v := float(k[1]) / ny
					var p: Vector3 = a.lerp(b, u).lerp(e.lerp(c, u), v)
					pts.append(p)
				var ordem := [0, 1, 2, 0, 2, 3]
				for o in ordem:
					var p: Vector3 = pts[o]
					var ce := minf(minf(absf(p.z + zz), absf(p.z - zz)), minf(p.y, absf(p.x))) 
					st.set_uv(Vector2(p.z + p.x * 0.7, p.y + absf(p.x) * 0.5))
					st.set_uv2(Vector2(clampf(ce / 1.2, 0.0, 1.0), 0.0))
					st.add_vertex(p)
	# teto (da barra até ao topo do fundo)
	quad.call(Vector3(0, hh, -zz), Vector3(0, hh, zz), Vector3(d * top, hh, zz), Vector3(d * top, hh, -zz), 1, 12)
	# fundo inclinado
	quad.call(Vector3(d * top, hh, -zz), Vector3(d * top, hh, zz), Vector3(d * fundo, 0, zz), Vector3(d * fundo, 0, -zz), 6, 12)
	# lados
	for s in [-1.0, 1.0]:
		quad.call(Vector3(0, hh, s * zz), Vector3(d * top, hh, s * zz), Vector3(d * fundo, 0, s * zz), Vector3(0, 0, s * zz), 4, 4)
	st.generate_normals()
	return st.commit()

func _stadium() -> void:
	# bancada: degraus de betão e cadeiras; os adeptos são 3D (_fans)
	if fan_mat == null:
		fan_mat = ShaderMaterial.new(); fan_mat.shader = preload("res://shaders/adeptos.gdshader")
	var seatm := StandardMaterial3D.new(); seatm.albedo_color = Color(0.2, 0.22, 0.26); seatm.roughness = 0.95
	var roofm := StandardMaterial3D.new(); roofm.albedo_color = Color(0.14, 0.15, 0.18)
	var boardm := StandardMaterial3D.new(); boardm.albedo_color = Color(0.08, 0.1, 0.12)
	var wallm := StandardMaterial3D.new(); wallm.albedo_color = Color(0.3, 0.31, 0.34); wallm.roughness = 1.0
	var ledm := StandardMaterial3D.new(); ledm.albedo_color = Color(0.1, 0.25, 0.6); ledm.emission_enabled = true; ledm.emission = Color(0.2, 0.45, 1.0); ledm.emission_energy_multiplier = 0.9
	var sides := [[Vector3(W / 2, 0, -9), 0.0, W + 30], [Vector3(W / 2, 0, H + 9), 180.0, W + 30], [Vector3(-11, 0, H / 2), 90.0, H + 30], [Vector3(W + 11, 0, H / 2), -90.0, H + 30]]
	for s in sides:
		var root := Node3D.new(); root.position = s[0]; root.rotation_degrees.y = s[1]; add_child(root)
		var stand := MeshInstance3D.new(); var bx := BoxMesh.new(); bx.size = Vector3(s[2], 0.6, 24)
		stand.mesh = bx; stand.material_override = seatm
		stand.rotation_degrees.x = 31; stand.position = Vector3(0, 6.5, -10.5); root.add_child(stand)
		_fans(root, stand, float(s[2]), sides.find(s))
		var roof := MeshInstance3D.new(); var rb := BoxMesh.new(); rb.size = Vector3(s[2], 0.5, 18)
		roof.mesh = rb; roof.material_override = roofm; roof.position = Vector3(0, 19.5, -14); roof.rotation_degrees.x = -8; root.add_child(roof)
		var board := MeshInstance3D.new(); var bb := BoxMesh.new(); bb.size = Vector3(s[2] - 30, 0.9, 0.12)
		board.mesh = bb; board.material_override = boardm; board.position = Vector3(0, 0.45, 3.2); root.add_child(board)
		var txt := Label3D.new(); txt.text = "ÁRBITRO DE CARICAS      APITO DOURADO      RELVADO VERDE      TAÇA DAS CARICAS"
		txt.font_size = 64; txt.pixel_size = 0.009; txt.modulate = Color(0.95, 0.82, 0.25); txt.position = Vector3(0, 0.45, 3.27)
		root.add_child(txt)
		_stand_shell(root, float(s[2]), wallm, ledm)
	# cantos: bancadas em diagonal que fecham o estádio
	var cantos := [[Vector3(-15, 0, -13), 45.0], [Vector3(W + 15, 0, -13), -45.0], [Vector3(-15, 0, H + 13), 135.0], [Vector3(W + 15, 0, H + 13), -135.0]]
	for i in cantos.size():
		var cn: Array = cantos[i]
		var root := Node3D.new(); root.position = cn[0]; root.rotation_degrees.y = cn[1]; add_child(root)
		var stand := MeshInstance3D.new(); var bx := BoxMesh.new(); bx.size = Vector3(30, 0.6, 24)
		stand.mesh = bx; stand.material_override = seatm
		stand.rotation_degrees.x = 31; stand.position = Vector3(0, 6.5, -10.5); root.add_child(stand)
		_fans(root, stand, 30.0, 4 + i, 3.0)
		var roof := MeshInstance3D.new(); var rb := BoxMesh.new(); rb.size = Vector3(30, 0.5, 18)
		roof.mesh = rb; roof.material_override = roofm; roof.position = Vector3(0, 19.5, -14); roof.rotation_degrees.x = -8; root.add_child(roof)
		_stand_shell(root, 30.0, wallm, ledm)
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

# Adeptos 3D: um boneco simples (tronco, cabeça, braços) repetido em MultiMesh pelos degraus da bancada,
# com a cor da equipa que apoiam. A animação (levantar, saltar, protestar) é toda no adeptos.gdshader.
func _fan_mesh() -> ArrayMesh:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var caixa := func(c: Vector3, h: Vector3, col: Color) -> void:
		st.set_uv(Vector2(col.r, col.g)); st.set_uv2(Vector2(col.b, 0.0))   # marcas da peça (o COLOR não chega ao shader no MultiMesh)
		var bm := BoxMesh.new(); bm.size = h * 2.0
		var arr := bm.get_mesh_arrays()
		var vv: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]; var nn: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]; var ii: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		for k in ii: st.set_normal(nn[k]); st.add_vertex(vv[k] + c)
	caixa.call(Vector3(0, 0.78, 0), Vector3(0.19, 0.27, 0.12), Color(0, 0, 0))           # tronco
	caixa.call(Vector3(0, 1.17, 0.01), Vector3(0.095, 0.11, 0.1), Color(0, 1, 0))         # cabeça
	if hi_q: caixa.call(Vector3(0, 1.29, -0.01), Vector3(0.1, 0.03, 0.1), Color(0, 0, 0))   # boné (cor da camisola)
	for sx in [-1.0, 1.0]:
		caixa.call(Vector3(0.25 * sx, 0.8, 0.02), Vector3(0.05, 0.22, 0.05), Color(1, 0, 0))  # braço
		caixa.call(Vector3(0.25 * sx, 0.55, 0.03), Vector3(0.045, 0.04, 0.045), Color(1, 0, 1)) # mão
	st.index()    # vértices partilhados: menos trabalho por adepto
	return st.commit()

# frente da bancada (muro com faixa LED), parede de trás até ao teto e pilares que seguram o teto
func _stand_shell(root: Node3D, comp: float, wallm: Material, ledm: Material) -> void:
	var muro := MeshInstance3D.new(); var mb := BoxMesh.new(); mb.size = Vector3(comp, 1.6, 0.4)
	muro.mesh = mb; muro.material_override = wallm; muro.position = Vector3(0, 0.8, 0.6); root.add_child(muro)
	var led := MeshInstance3D.new(); var lb := BoxMesh.new(); lb.size = Vector3(comp, 0.5, 0.05)
	led.mesh = lb; led.material_override = ledm; led.position = Vector3(0, 1.25, 0.82); root.add_child(led)
	var tras := MeshInstance3D.new(); var tb := BoxMesh.new(); tb.size = Vector3(comp, 20.0, 0.6)
	tras.mesh = tb; tras.material_override = wallm; tras.position = Vector3(0, 10.0, -21.5); root.add_child(tras)
	var n := maxi(1, int(comp / 30.0))
	for k in n + 1:
		var px := lerpf(-comp / 2.0 + 1.0, comp / 2.0 - 1.0, float(k) / n)
		var pil := MeshInstance3D.new(); var pb := BoxMesh.new(); pb.size = Vector3(0.6, 20.0, 0.6)
		pil.mesh = pb; pil.material_override = wallm; pil.position = Vector3(px, 10.0, -20.8); root.add_child(pil)

func _fans(root: Node3D, stand: MeshInstance3D, comp: float, lado: int, margem := 4.0) -> void:
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D; mm.use_custom_data = true
	mm.mesh = fan_mesh if fan_mesh else _fan_mesh()
	fan_mesh = mm.mesh
	var passo_x := 0.62 if hi_q else 0.95
	var passo_z := 0.85 if hi_q else 1.2
	var r := RandomNumberGenerator.new(); r.seed = 101 + lado
	var xf: Transform3D = stand.transform
	var pts: Array = []
	var x := -comp / 2.0 + margem
	while x < comp / 2.0 - margem:
		var z := -11.5
		while z < 11.5:
			if r.randf() < 0.82: pts.append(Vector3(x + r.randf_range(-0.08, 0.08), 0.3, z))
			z += passo_z
		x += passo_x
	# ordem baralhada: mostrar só os primeiros N (computador fraco) tira adeptos espalhados, não meia bancada
	for i in range(pts.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var tmp = pts[i]; pts[i] = pts[j]; pts[j] = tmp
	mm.instance_count = pts.size()
	# metade da bancada de cada clube, com alguns neutros; a cor real entra em _fans_colors
	for i in pts.size():
		var p: Vector3 = xf * pts[i]
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, r.randf_range(-0.25, 0.25)).scaled(Vector3.ONE * r.randf_range(0.92, 1.08)), p - Vector3(0, 0.05, 0)))
		mm.set_instance_custom_data(i, Color(0.5, 0.5, 0.5, r.randf()))
	var mi := MultiMeshInstance3D.new(); mi.multimesh = mm; mi.material_override = fan_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	fan_mms.append([mm, lado, pts])
	# bandeiras: mastro e pano a ondular, nas filas da frente e do meio
	var n_b := int(comp / 22.0) if lado < 4 else 0
	for k in n_b:
		var bx := lerpf(-comp / 2.0 + 20.0, comp / 2.0 - 20.0, (k + 0.5) / n_b) + r.randf_range(-3, 3)
		var p: Vector3 = xf * Vector3(bx, 0.3, r.randf_range(-4.0, 9.0))
		var mastro := MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = 0.025; cm.bottom_radius = 0.025; cm.height = 3.2
		mastro.mesh = cm; mastro.position = p + Vector3(0, 1.6 + 0.8, 0); root.add_child(mastro)
		var pano := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(2.2, 1.4); pm.subdivide_width = 14; pm.subdivide_depth = 6
		pm.orientation = PlaneMesh.FACE_Z
		var fm := ShaderMaterial.new(); fm.shader = preload("res://shaders/bandeira.gdshader")
		fm.set_shader_parameter("fase", r.randf() * TAU); fm.set_shader_parameter("vento", r.randf_range(0.8, 1.2))
		fm.set_shader_parameter("faixas", float(r.randi_range(2, 4)))
		pano.mesh = pm; pano.material_override = fm; pano.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		pano.position = p + Vector3(1.1, 3.35, 0); pano.rotation.y = r.randf_range(-0.5, 0.5)
		root.add_child(pano)
		flags.append([fm, lado, bx])

# pinta os adeptos com as cores dos clubes do jogo (casa em maioria; topo visitante numa ponta)
func _fans_colors(home: Color, away: Color) -> void:
	for f in fan_mms:
		var mm: MultiMesh = f[0]; var lado: int = f[1]; var pts: Array = f[2]
		var r := RandomNumberGenerator.new(); r.seed = 55 + lado
		for i in mm.instance_count:
			var x: float = (pts[i] as Vector3).x
			var visitantes := lado == 3 or (lado == 1 and x > 30.0)
			var q := r.randf()
			var c: Color = (away if q < 0.8 else home) if visitantes else (home if q < 0.78 else (away if q < 0.86 else Color.from_hsv(r.randf(), 0.15, r.randf_range(0.2, 0.9))))
			c = c.darkened(r.randf_range(0.0, 0.25))
			var old: Color = mm.get_instance_custom_data(i)
			mm.set_instance_custom_data(i, Color(c.r, c.g, c.b, old.a))
	for f in flags:
		var lado: int = f[1]
		var vis := lado == 3 or (lado == 1 and float(f[2]) > 30.0)
		var c: Color = away if vis else home
		f[0].set_shader_parameter("cor1", c)
		f[0].set_shader_parameter("cor2", Color(0.96, 0.96, 0.94) if c.get_luminance() < 0.6 else Color(0.1, 0.12, 0.2))

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
	j.set_meta("pid", int(info.get("id", -1)))
	j.gr = str(info.get("role", "")) == "gk"
	j.label.modulate = jogo.teams[tm].get("text", Color(0.97, 0.97, 0.95)) if jogo else Color(0.97, 0.97, 0.95)
	j.mat.set_shader_parameter("numcol", j.label.modulate)
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
	_ref_corrida(REF, float(jogo.stamina) if jogo else 100.0)
	if A == Vector2.ZERO: A = Vector2(1, 0)
	for j in [att, def, refj] + extras: j.reset(); j.gr = false; j.node.visible = true
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
					# toque leve na área, sempre de pé (nunca carrinho): na falta o pé apanha o tornozelo;
					# no siga o defesa toca primeiro na bola e o atacante cai com facilidade
					c = {"lance": 0, "force": 0.8 if T == "falta" else 0.6, "side": l.side, "sim": T == "simulacao", "clean": T == "siga", "de_pe": true, "phi": rng.randf_range(55, 75), "vD": 7.2}
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
			"pen": c = {"lance": 11, "side": l.lado}
			"atraso": c = {"lance": 12, "side": l.s}
		l.cur = c
	cur = c
	# quem está à volta: os mais perto do lance
	var others: Array = l.get("others", []).duplicate()
	var used := [int(l.att.id), int(l.def.id) if l.has("def") else -1]
	var first: Array = []
	if k == "canto" and l.has("taker"): first.append({"id": l.taker.id, "team": l.taker.team, "role": l.taker.role, "num": l.taker.num, "p": l.corner, "v": Vector2.ZERO})
	if k == "aereo" and l.has("passer"): first.append({"id": l.passer.id, "team": l.passer.team, "role": l.passer.role, "num": l.passer.num, "p": l.K, "v": Vector2.ZERO})
	if k == "atraso" and l.has("rival"): first.append({"id": l.rival.id, "team": l.rival.team, "role": l.rival.role, "num": l.rival.num, "p": l.R, "v": Vector2.ZERO})
	if k == "pen" and l.has("inv"): first.append({"id": l.inv.id, "team": l.inv.team, "role": l.inv.role, "num": l.inv.num, "p": l.inv_p, "v": Vector2.ZERO})
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
	if k in ["canto", "golo", "linha", "mao", "offside", "aereo", "pen", "atraso"]: sc.approach = false
	match k:
		"aereo": sc.K = l.K; sc.passer = l.has("passer") and list.size() > 0
		"mao": sc.K = l.K; sc.Sd = l.Sd; sc.arm = l.arm_out; sc.s = l.side
		"canto": sc.Q = l.Q; sc.V = l.V; sc.s = l.s; sc.corner = l.corner; sc.fall = l.get("fall", false); A = l.V
		"linha": sc.B = l.B; sc.bh = l.bh; sc.Pk = l.Pk; sc.gx = l.gx; sc.dir_in = l.dir_in
		"pen":
			sc.gx = l.gx; sc.dir_in = l.dir_in; sc.infr = l.infr; sc.golo = l.golo; sc.lado = l.lado; sc.gk_lado = l.gk_lado; sc.inv = l.has("inv")
			# no penálti o árbitro coloca-se ao lado, entre a marca e a entrada da área
			var pd := Vector2(-A.y, A.x) * (1.0 if REF.y > P.y else -1.0)
			_ref_corrida(P - A * 5.5 + pd * 7.0, float(jogo.stamina) if jogo else 100.0)
		"atraso": sc.G = l.G; sc.K = l.K; sc.R = l.R; sc.como = l.como; sc.gx = l.gx; sc.dir_in = l.dir_in; sc.rival = l.has("rival") and list.size() > 0
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
	pip_alvo = Vector3.ZERO
	t = 0.0
	REF = ref_ini; ref_vel = 0.0; ref_olhar = Vector3.ZERO; ref_foco = 0.0
	min_contact = 99.0; contact_checked = false; slp = {}; kp = {}
	hit_done = false
	toque = {}; hitstop = 0.0; sim_off = 0.0
	_limpa_brilhos()
	_desfaz_desvio()
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
		11: TC = 2.8
		12: TC = 2.6
	DUR = TC + 7.8
	if modo != "treino": DUR = 1e9
	t2d = _t2d()
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
	if fp_vig and fp_vig.visible and not (modo in ["lance", "treino"]): fp_vig.visible = false
	if pip_box and pip_box.visible and not (modo in ["lance", "var", "rever"]): pip_box.visible = false   # câmara do passe só no lance
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
	_fans_step(delta)
	if rede_abana > 0.0 or delta > 10.0:
		rede_abana = maxf(0.0, rede_abana - delta * 0.7)
		for nm in nets: nm.set_shader_parameter("abana", rede_abana * rede_abana)

var fan_lento := 0.0     # segundos seguidos abaixo de 24 fps com o 3D à vista
var fan_nivel := 0       # 0 todos, 1 metade, 2 sem adeptos

func _fans_step(delta: float) -> void:
	if fan_mat == null or not visible: return
	# computador fraco: menos adeptos (metade, depois nenhum) para o lance não ficar aos soluços
	if fan_nivel < 2 and Engine.get_frames_per_second() < 24 and modo in ["lance", "var", "rever", "gesto", "menu"]:
		fan_lento += delta
		if fan_lento > 4.0:
			fan_lento = 0.0; fan_nivel += 1
			for f in fan_mms:
				var mm: MultiMesh = f[0]
				mm.visible_instance_count = mm.instance_count / 2 if fan_nivel == 1 else 0
			print("adeptos reduzidos: nível ", fan_nivel)
	else:
		fan_lento = maxf(0.0, fan_lento - delta)
	fan_festa = move_toward(fan_festa, 0.0, delta * 0.18)
	fan_protesto = move_toward(fan_protesto, 0.0, delta * 0.22)
	fan_mat.set_shader_parameter("festa", smoothstep(0.0, 0.6, fan_festa))
	fan_mat.set_shader_parameter("protesto", smoothstep(0.0, 0.5, fan_protesto))
	fan_mat.set_shader_parameter("pressao", clampf(0.15 + som._nivel * 0.8, 0.0, 1.0))
	fan_mat.set_shader_parameter("canto", clampf(som._canto * 1.6, 0.0, 1.0))

func _match_process(delta: float) -> void:
	get_tree().paused = false; Engine.time_scale = 1.0
	if modo == "flash":
		flash_t -= delta
		if flash_t <= 0: _enter_lance()
		return
	# caricas a 1,5x: o jogo corre mais depressa; perguntas, protestos e o tutorial ficam ao ritmo normal
	if modo == "jogo" and not match_paused and jogo: jogo.tick(delta * (RITMO if jogo.mode == "play" and not jogo.tut else 1.0))

func _menu_cam(delta: float) -> void:
	t += delta
	var a := t * 0.05
	cam.fov = 50
	cam.look_at_from_position(Vector3(W / 2 + cos(a) * 62, 22, H / 2 + sin(a) * 50), Vector3(W / 2, 0, H / 2))

func _scene_process(delta: float) -> void:
	_tv_step()
	if not (modo in ["lance", "var", "rever", "treino"]): return    # o vídeo do observador pode ter acabado agora
	get_tree().paused = paused
	# no toque, o tempo abranda um instante (como num desenho animado) para se ver bem o contacto
	var real_dt := delta / maxf(Engine.time_scale, 0.001)
	if hitstop > 0.0 and not paused: hitstop = maxf(0.0, hitstop - real_dt)
	Engine.time_scale = speed * _hit_escala()
	var dt := 0.0 if paused else delta
	_desfaz_desvio()
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
		11: _penalty(dt)
		12: _atraso(dt)
	if sc.get("approach", true): _extras_step(dt)
	elif lance != 9 and lance != 11: _extras_idle(dt)
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
	# o árbitro corre para o sítio do lance (só se vê fora da tua vista)
	_ref_step(dt)
	if refj.node.visible:
		var rd := (P - REF).normalized()
		refj.move(REF, rd if rd != Vector2.ZERO else Vector2(0, 1), ref_vel)
		refj.play("run" if ref_vel > 4.5 else ("jog" if ref_vel > 0.8 else "idle"), 0.3)
		refj.update(dt, t); refj.ground()
	# levanta-se quando já não está queixoso
	for p in [att, def]:
		if (p.phase == "chao" or p.phase == "chao_k") and p.groundT > 1.4 + p.hurt * 2.2: p.get_up()
	if lance <= 4: _ball(dt)
	else: _ball3_step(dt)
	_var_lines()
	_camera()
	# no frame de impacto a câmara aperta um pouco sobre o lance
	if hitstop > 0.0 and cam_mode != 5: cam.fov *= 1.0 - 0.14 * clampf((hitstop - HIT_LENTO * 0.5) / HIT_CONGELA, 0.0, 1.0)
	_brilhos_step(0.0 if paused else real_dt)
	radar.visible = modo in ["lance", "var", "rever"] and jogo != null
	if radar.visible: radar.position = Vector2(14, get_viewport().get_visible_rect().size.y - radar.size.y - 14)
	_pip_step()
	if modo == "treino":
		var info := ""
		if hit_done and t > TC + 1.2: info = "Verdade do lance: " + outcome + ("  ·  " + verdict if verdict != "" else "")
		lab1.text = "GODOT 4 · %s   |   %s   |   %s s   |   N lance seguinte · R repetir (outro toque) · 1-4 câmaras · Espaço pausa · S lento · Esc menu" % [LANCES[lance] if lance < LANCES.size() else str(lance), ["A TUA VISTA", "VISTA IDEAL", "ATRÁS DO LANCE", "DE PERTO"][cam_mode], ("%+.2f" % (t - TC)).replace(".", ",")]
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
		if _segue_2d(e): continue
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
			# reagem ao lance: os da equipa do derrubado pedem falta ao árbitro, os outros protestam a inocência
			if not e.has_meta("reac"): e.set_meta("reac", _reacao(e, to.length()))
			if e.gesto != "" and e.gesto_t > 0.0 and sp < 1.2 and (REF - cu).length() > 0.5: face = (REF - cu).normalized()
		e.move(cu, face, sp)
		e.play("run" if sp > 4.2 else ("jog" if sp > 0.7 else "idle"), 0.3)
func _reacao(e: Jogador, dist: float) -> String:
	if not (lance <= 4 or lance == 6) or dist > 28.0: return ""
	var r := rng.randf()
	var g := ""
	if e.team == att.team:
		if r < 0.45: g = "braco"
		elif r < 0.62: g = "bracos"
		elif r < 0.72: g = "cabeca"
	else:
		if r < 0.4: g = "abre"
		elif r < 0.5: g = "cabeca"
	if g != "": e.reage(g, 0.25 + rng.randf() * 0.6 + dist * 0.02, 1.2 + rng.randf() * 1.0)
	return g

# nas cenas paradas (cantos, golos) os outros mexem-se pouco, de frente para a bola
func _extras_idle(dt: float) -> void:
	for i in extras.size():
		var e: Jogador = extras[i]
		if not e.node.visible or e.rag or e.phase != "anim": continue
		if lance == 10 and i == 0: continue
		if lance == 7 and i == 0: continue
		if lance == 5 and i == 0 and sc.get("passer", false): continue
		if lance == 12 and i == 0 and sc.get("rival", false): continue
		if _segue_2d(e): continue
		var cu: Vector2 = e.get_meta("cur")
		var v: Vector2 = e.get_meta("v")
		if v.length() > 0.2 and t < TC + 0.6: cu += v * dt * 0.6
		e.set_meta("cur", cu)
		var to := Vector2(b3.x, b3.z) - cu
		e.move(cu, to.normalized() if to.length() > 0.1 else Vector2(0, 1), v.length() * 0.6 if t < TC + 0.6 else 0.0)
		e.play("jog" if v.length() > 1.0 and t < TC + 0.6 else "idle", 0.4)

# ---------- o 3D continua as caricas ----------
# em que instante da cena estava o jogo 2D quando parou (o flash); antes disso os outros repetem o rasto 2D
func _t2d() -> float:
	if modo == "treino" or not L.has("hist"): return -1.0
	match lance:
		0, 1, 2, 3, 4, 6, 8, 12: return TC
		5: return TC - 1.5
		7: return TC - 1.3
	return -1.0
# posição de um jogador nas caricas tau segundos antes do flash (null se não houver rasto)
func _hist_pos(id: int, tau: float) -> Variant:
	var h: Array = L.get("hist", [])
	if h.is_empty() or id < 0: return null
	var prev = null
	var pt := 0.0
	for s in h:
		if not s.ps.has(id): continue
		var q: Vector2 = s.ps[id]
		if s.tau >= tau:
			if prev == null: return q
			return (prev as Vector2).lerp(q, clamp((tau - pt) / maxf(s.tau - pt, 0.001), 0.0, 1.0))
		prev = q; pt = s.tau
	return prev
# antes do instante do flash, quem está à volta faz exatamente o que fez nas caricas
func _segue_2d(e: Jogador) -> bool:
	if t2d < 0.0 or t >= t2d: return false
	var id := int(e.get_meta("pid", -1))
	var a = _hist_pos(id, t - t2d)
	if a == null: return false
	var b = _hist_pos(id, minf(t - t2d + 0.15, 0.0))
	var vel: Vector2 = ((b as Vector2) - (a as Vector2)) / maxf(minf(0.15, t2d - t), 0.02)
	var sp := vel.length()
	var face: Vector2 = vel / sp if sp > 0.6 else e.dir
	e.set_meta("cur", a); e.set_meta("vel", vel)
	e.move(a, face, sp)
	e.play("run" if sp > 4.2 else ("jog" if sp > 0.7 else "idle"), 0.3)
	return true

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
			if not sc.get("rede_abanou", false):
				sc.rede_abanou = true; rede_abana = 1.0
	_set_ball(b3)

# ---------- cenas ----------
# 5) disputa no ar: os dois saltam à bola; o defesa pode usar o braço (empurrão, alavanca, cotovelada)
func _aerial(dt: float) -> void:
	var perp := Vector2(-A.y, A.x) * side
	var v := 3.4
	var jt := t - (TC - 0.34)
	var jmp: float = 0.0 if jt < 0 or jt > 0.72 else 0.5 * sin(PI * jt / 0.72)
	var T: String = sc.truth
	# o atacante faz o cabeceamento capturado (salto real, cabeça na bola no instante TC);
	# o defesa chega por trás e salta com ele
	var hb := P + A * 0.05
	var cab := _kin_run(att, "cab", "header", 1.13, "head", hb, A, 0.55, TC, v, true)
	if not cab and not att.rag: _settle(att, dt, A)
	var ts: float = kp["cab"].ts
	if t < TC + 0.35:
		if not def.rag: def.move(hb + A * v * minf(t - ts, 0.0) - A * 0.55 + perp * 0.38, A, v if t < ts else 0.6); def.play("jog", 0.2)
	else:
		_settle(def, dt, A)
	def.jump = jmp * 0.92
	var w: float = clamp(jt / 0.2, 0.0, 1.0) * clamp((0.9 - jt) / 0.25, 0.0, 1.0)
	var up := Vector3(0, 0.38, 0)
	if not att.rag and not cab: att.ik = {"wrist_L": [att.bone_world("head") + up - Vector3(perp.x, 0, perp.y) * 0.18, w * 0.6], "wrist_R": [att.bone_world("head") + up + Vector3(perp.x, 0, perp.y) * 0.18, w * 0.6]}
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
				att.fall(v3 + Vector3(0, 0.5, 0), ["spine03", "spine02"], v3 * 1.3 + Vector3(A.x, 0.3, A.y) * 2.6, "trip", 0.6, Vector3.ZERO, 0.3)
			"amarelo":
				att.hurt = 0.5; bv3 = Vector3(-A.x * 2, 2.5, -A.y * 2) - p3 * 3
				att.fall(v3 * 0.8 - p3 * 1.6 + Vector3(0, 0.5, 0), ["spine03", "upperarm01_L", "upperarm01_R"], -p3 * 3.4 + Vector3(0, 0.2, 0), "trip", 0.5, Vector3.ZERO, 0.3)
			_:
				att.hurt = 1.0; bv3 = Vector3(-A.x * 2, 3.0, -A.y * 2) - p3 * 3
				att.fall(v3 * 0.5 + Vector3(0, 0.4, 0), ["head", "spine03"], -Vector3(A.x, 0, A.y) * 2.0 - p3 * 2.6 + Vector3(0, 0.6, 0), "fallback", 0.45, Vector3(0, 2.0 * side, 0))
		outcome = {"siga": "os dois saltam à bola, sem braço", "falta": "empurra-o nas costas durante o salto", "amarelo": "usa o braço como alavanca no ombro", "vermelho": "cotovelada na cara"}.get(T, "")
	# quem fez o passe longo: chuta no sítio onde estava nas caricas
	var psr: Jogador = extras[0]
	if sc.get("passer", false) and psr.node.visible and not psr.rag:
		var K0: Vector2 = sc.K
		var tp := (P - K0).normalized()
		if not _kin_run(psr, "passe", "m_kick", 0.4, "foot_R", K0, tp, 0.0, TC - 1.5, 1.5) and t > TC - 1.5: _settle(psr, dt, tp)
	if not b3_free:
		var K: Vector2 = sc.K
		var from := Vector3(K.x, 0.11, K.y)
		var k := (t - (TC - 1.5)) / 1.5
		var hy: float = att.clip_bone("header", 1.13, "head").y + 0.12
		b3 = _arc(from, Vector3(P.x + A.x * 0.05, hy, P.y + A.y * 0.05), 6.5, k) if k > 0 else from

# 6) mão na bola: remate de frente para um defesa; o braço junto ao corpo, aberto ou levantado
func _hand(dt: float) -> void:
	var tk := TC - 0.45
	var K: Vector2 = sc.K
	var Sd: Vector2 = sc.Sd
	if not _kin_run(att, "remate", "kick_run", 0.52, "foot_R", K, Sd, 0.0, tk, 4.0): _settle(att, dt, Sd)
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
	var dof := V * 0.15 + perp * 0.6 if T == "ataque" else -V * 0.55 + perp * 0.35
	# em jogo corrido os dois partem de onde estavam nas caricas e juntam-se ao lance antes do salto
	if not sc.has("off_a"):
		var a2 = _hist_pos(int(L.att.id), 0.0) if L.has("att") else null
		var d2 = _hist_pos(int(L.def.id), 0.0) if L.has("def") else null
		var a_tk := Q - V * v * (TC - tk)
		sc.off_a = ((a2 as Vector2) - a_tk).limit_length(4.0) if a2 != null else Vector2.ZERO
		sc.off_d = ((d2 as Vector2) - a_tk - dof).limit_length(4.0) if d2 != null else Vector2.ZERO
	var wo := 1.0 - smoothstep(tk, TC - 0.35, t)
	if t < TC + 0.4:
		var a_at: Vector2 = ap + (sc.off_a as Vector2) * wo
		if not att.rag: att.move(a_at, V, v if t < TC + 0.25 else 0.5); att.play("jog", 0.3)
		var dp: Vector2 = ap + dof + (sc.off_d as Vector2) * wo
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
				att.hurt = 0.3; att.fall(v3 + Vector3(0, 0.3, 0), ["spine03", "spine02"], v3 * 1.2 + Vector3(V.x, 0.25, V.y) * 2.6, "trip", 0.6, Vector3.ZERO, 0.3)
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
		if not _kin_run(tkr, "canto", "m_kick", 0.4, "foot_R", cpos, to, 0.0, tk, 1.5) and t > tk: tkr.play("idle", 0.4)
	if not b3_free:
		var cp: Vector2 = sc.corner
		var c3 := Vector3(cp.x, 0.11, cp.y)
		var k := (t - tk) / (TC + 0.05 - tk)
		b3 = _arc(c3, Vector3(Q.x, 2.1, Q.y), 5.0, k) if k > 0 else c3
		if k >= 1.0:
			b3_free = true
			bv3 = Vector3(-V.x * 6, 2.0, -V.y * 6) if T != "ataque" else Vector3(V.x * 4, 1.0, V.y * 4)

# 12) atraso ao guarda-redes: passe com o pé (livre indireto), de cabeça ou num corte falhado (pode agarrar).
# O guarda-redes agarra a bola em TC: rasteira baixa-se (gk_catch, mãos no chão aos 0,72 s), alta à altura do peito (gk_catch2, 0,40 s)
func _atraso(dt: float) -> void:
	var G: Vector2 = sc.G
	var K: Vector2 = sc.K
	var como: String = sc.como
	var kg := (G - K).normalized()
	var alta := como != "pe"
	var fly := clampf(K.distance_to(G) / 11.0, 1.1, 1.8) if not alta else 1.05
	var tk := TC - fly
	var gclip := "gk_catch2" if alta else "gk_catch"
	var gkey := 0.40 if alta else 0.72
	if not sc.has("gk_at"):
		# o guarda-redes coloca-se de modo a que as mãos fiquem em G no instante TC
		var R := Basis(Vector3.UP, atan2(-kg.x, -kg.y))
		var mid := R * ((def.clip_bone(gclip, gkey, "wrist_L") + def.clip_bone(gclip, gkey, "wrist_R")) * 0.5)
		var r0 := R * def.clip_bone(gclip, 0.0, "root")
		sc.gk_at = G - Vector2(mid.x, mid.z) + Vector2(r0.x, r0.z)
		sc.mao_y = maxf(mid.y, 0.11)
	var gk_at: Vector2 = sc.gk_at
	if not def.rag:
		if t < TC - gkey: def.move(gk_at, -kg, 0.0); def.play("idle", 0.3)
		elif not sc.get("gk_on", false):
			sc.gk_on = true; def.kin(gclip, 0.0, -kg, gk_at, 1.0, "anim", 0.15)
	var C3: Vector3                         # onde o defesa toca na bola
	match como:
		"pe":
			# tem a bola controlada, olha para o guarda-redes e passa com o pé
			if not _kin_run(att, "atraso", "m_kick", 0.4, "foot_R", K, kg, 0.0, tk, 2.4) and t > tk: _settle(att, dt, kg)
			C3 = Vector3(K.x, 0.11, K.y)
			if t < tk: b3 = Vector3(K.x - kg.x * 2.4 * (tk - t), 0.11, K.y - kg.y * 2.4 * (tk - t))
		"cabeca":
			# bola longa do adversário a cair; o defesa recua e cabeceia para trás, para o guarda-redes
			if not _kin_run(att, "cab", "header", 1.13, "head", K, kg, 0.55, tk, 3.0, true) and t > tk: _settle(att, dt, kg)
			var hy: float = att.clip_bone("header", 1.13, "head").y + 0.12
			C3 = Vector3(K.x, hy, K.y)
			if t < tk:
				var S3 := Vector3(K.x - kg.x * 30.0, 0.11, K.y - kg.y * 30.0)
				var k := (t - (tk - 1.7)) / 1.7
				b3 = _arc(S3, C3, 11.0, k) if k > 0 else S3
		_:
			# o adversário remata ou cruza; o defesa tenta aliviar, a bola sai-lhe mal do pé e sobe para o guarda-redes
			var Rp: Vector2 = sc.R
			var tr := tk - 0.45
			var rd := (K - Rp).normalized()
			var riv: Jogador = extras[0]
			if sc.get("rival", false) and riv.node.visible and not riv.rag:
				if not _kin_run(riv, "rem", "m_kick", 0.4, "foot_R", Rp, rd, 0.0, tr, 2.0) and t > tr: _settle(riv, dt, rd)
			if not _kin_run(att, "corte", "m_kick", 0.4, "foot_R", K, -rd, 0.0, tk, 1.5) and t > tk: _settle(att, dt, -rd)
			C3 = Vector3(K.x, 0.25, K.y)
			if t < tr: b3 = Vector3(Rp.x - rd.x * 2.0 * (tr - t), 0.11, Rp.y - rd.y * 2.0 * (tr - t))
			elif t < tk: b3 = Vector3(Rp.x, 0.11, Rp.y).lerp(C3, (t - tr) / 0.45)
	if como != "corte" and sc.get("rival", false):
		# o adversário vem a pressionar quem tem a bola
		var rv: Jogador = extras[0]
		var Rq: Vector2 = sc.R
		if rv.node.visible and not rv.rag:
			var kk := clampf(t / (TC + 0.6), 0.0, 0.65)
			rv.move(Rq.lerp(K, kk), (K - Rq).normalized(), 3.5 if kk < 0.65 else 0.0)
			rv.play("jog" if kk < 0.65 else "idle", 0.3)
	if t >= tk and not hit_done:
		var k := clampf((t - tk) / fly, 0.0, 1.0)
		# as mãos do guarda-redes (vivas) são o destino: a bola chega mesmo às mãos
		var mao := Vector3(G.x, sc.mao_y, G.y)
		if sc.get("gk_on", false): mao = (def.bone_world("wrist_L") + def.bone_world("wrist_R")) * 0.5
		if alta: b3 = _arc(C3, mao, 2.6 if como == "cabeca" else 3.4, k)
		else: b3 = C3.lerp(Vector3(mao.x, 0.11, mao.z), 1.0 - pow(1.0 - k, 1.5))
		if t >= TC:
			hit_done = true
			outcome = {"pe": "passe deliberado com o pé para o guarda-redes, que agarra com as mãos", "cabeca": "atraso de cabeça: o guarda-redes pode agarrar",
				"corte": "corte falhado do defesa (não é passe): o guarda-redes pode agarrar"}.get(como, "")
	if hit_done:
		b3 = (def.bone_world("wrist_L") + def.bone_world("wrist_R")) * 0.5 + Vector3(0, 0.02, 0)
		b3.y = maxf(b3.y, 0.11)

# 8) bola na linha: o guarda-redes agarra-a em cima da linha
func _line(dt: float) -> void:
	var B: Vector2 = sc.B
	var Pk: Vector2 = sc.Pk
	var gx: float = sc.gx
	var di: float = sc.dir_in
	var tk := TC - 0.55
	var sd := (B - Pk).normalized()
	# remate em corrida capturado: o pé direito chega à bola em tk
	if not _kin_run(att, "remate", "kick_run", 0.52, "foot_R", Pk, sd, 0.0, tk, 4.0): _settle(att, dt, sd)
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
		if sc.get("passer") != null and modo != "var": som.kick(0.7)   # ouve-se o passe

# câmara do passe: o assistente não vê quem passa (está a olhar para a linha), por isso mostra-se numa janela
# à parte o jogador com a bola, vista da linha lateral; quando a bola parte a moldura fica amarela.
func _pip_step() -> void:
	var on: bool = lance == 9 and modo in ["lance", "var", "rever"] and sc.get("passer") != null and cam_mode != 5
	pip_box.visible = on
	if not on: return
	var vs := get_viewport().get_visible_rect().size
	pip_box.position = Vector2(vs.x - pip_box.size.x - 14, 146)   # por baixo do rádio do assistente
	var pj: Jogador = sc.passer
	var pp: Vector3 = pj.node.global_position
	var bp: Vector3 = ball.global_position
	var foco: Vector3 = pp.lerp(bp, clampf((t - TC) / 1.6, 0.0, 0.55)) if t >= TC else pp.lerp(bp, 0.3)
	foco.y = 0.8
	pip_alvo = foco if pip_alvo == Vector3.ZERO or pip_alvo.distance_to(foco) > 25.0 else pip_alvo.lerp(foco, clampf(get_process_delta_time() * 5.0, 0.0, 1.0))
	var lado := -1.0 if float(sc.ast.y) < H / 2 else 1.0     # do lado do assistente
	var aberto: float = clampf((t - TC) / 1.2, 0.0, 1.0)        # depois do passe abre um pouco para se ver a bola a ir
	var eye := pip_alvo + Vector3(-float(sc.dir) * 3.0, 2.6 + aberto * 1.5, lado * (8.5 + aberto * 5.0))
	pip_cam.look_at_from_position(eye, pip_alvo)
	var partiu: bool = t >= TC - 0.001 and t < TC + 0.9
	pip_estilo.border_color = Color(1.0, 0.85, 0.2) if partiu else Color(1, 1, 1, 0.6)
	pip_lbl.text = "A BOLA PARTIU" if partiu else ("Câmara do passe" if t < TC else "Câmara do passe · depois do passe")
	pip_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.3) if partiu else Color(0.97, 0.97, 0.94))

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
			if sc.fall: def.hurt = 0.2; def.fall(Vector3(A.x, 0, A.y) * v * 0.6 + p3 * 2.4 + Vector3(0, 0.3, 0), ["spine03", "upperarm01_L", "upperarm01_R"], p3 * 3.2, "trip", 0.5, Vector3.ZERO, 0.3)
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
# ---------- vista do árbitro ----------
# O árbitro começa alguns metros atrás e chega ao sítio do lance pouco antes do contacto;
# cansado, chega mais devagar e fica mais longe (vê pior).
func _ref_corrida(fim: Vector2, energia: float) -> void:
	REF_FIM = fim
	ref_cansaco = clampf(1.0 - energia / 100.0, 0.0, 1.0)
	var longe := (fim - P).normalized()
	if longe == Vector2.ZERO: longe = Vector2(0, 1)
	var lado := Vector2(-longe.y, longe.x) * rng.randf_range(-2.0, 2.0)
	ref_ini = fim + longe * rng.randf_range(5.0, 8.0) + lado
	ref_ini = Vector2(clampf(ref_ini.x, -1.5, W + 1.5), clampf(ref_ini.y, -1.5, H + 1.5))
	REF = ref_ini; ref_vel = 0.0; ref_olhar = Vector3.ZERO

func _ref_step(dt: float) -> void:
	if dt <= 0.0: return
	# chega ao destino em TC - 0.3 s (fresco) ou fica a 25% do caminho quando esgotado
	var fim := ref_ini.lerp(REF_FIM, 1.0 - ref_cansaco * ref_cansaco * 0.25)
	var dur := maxf(TC - 0.3, 0.6)
	var k := clampf(t / dur, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 2.2)
	var novo := ref_ini.lerp(fim, e)
	ref_vel = lerpf(ref_vel, novo.distance_to(REF) / dt, clampf(dt * 3.0, 0.0, 1.0))
	REF = novo
	ref_ph += dt * (5.0 + ref_vel * 0.6) * (1.0 if ref_vel > 0.4 else 0.0)

func _fp_vinheta(on: bool) -> void:
	if fp_vig == null:
		var lay := CanvasLayer.new(); lay.layer = 0; add_child(lay)
		fp_vig = ColorRect.new(); fp_vig.set_anchors_preset(Control.PRESET_FULL_RECT); fp_vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sh := Shader.new()
		sh.code = """shader_type canvas_item;
uniform float forca = 0.0;
uniform float pulso = 0.0;
void fragment() {
	vec2 d = UV - 0.5; d.x *= 1.6;
	float r = length(d);
	float v = smoothstep(0.35 - forca * 0.12, 0.95, r) * (0.35 + forca * 0.55) * (0.85 + 0.15 * pulso);
	COLOR = vec4(0.0, 0.0, 0.0, v);
}"""
		var m := ShaderMaterial.new(); m.shader = sh; fp_vig.material = m
		lay.add_child(fp_vig)
	fp_vig.visible = on
	if not on: return
	var tm := Time.get_ticks_msec() / 1000.0
	var f := clampf(ref_cansaco * 1.2 - 0.15, 0.0, 1.0)
	(fp_vig.material as ShaderMaterial).set_shader_parameter("forca", f)
	(fp_vig.material as ShaderMaterial).set_shader_parameter("pulso", sin(tm * TAU * (1.0 + ref_cansaco)))

func _focus() -> Vector3:
	match lance:
		5: return Vector3(P.x, 1.5, P.y)
		7: return Vector3(sc.Q.x, 1.0, sc.Q.y)
		8: return Vector3(sc.B.x, 0.4, sc.B.y)
		9: return Vector3(sc.line_x, 0.9, sc.recv.y)
		10: return Vector3(b3.x, 0.8, b3.z).lerp(Vector3(P.x, 0.9, P.y), 0.4)
		11: return Vector3(P.x, 0.8, P.y).lerp(Vector3(float(sc.gx), 0.9, H / 2), 0.25)
		12: return Vector3(b3.x, 0.8, b3.z).lerp(Vector3(P.x, 0.9, P.y), 0.5)
	return Vector3(P.x, 0.9, P.y)

func _camera() -> void:
	var look := _focus()
	if chuva_p.visible: chuva_p.global_position = cam.global_position + Vector3(0, 9, 0)
	refj.node.visible = modo != "treino" and cam_mode != 0 and lance != 9
	_fp_vinheta(cam_mode == 0 and modo in ["lance", "treino"] and lance != 9)
	if cam_mode != 5:
		for r in obs_marcas: r.visible = false
	if cam_mode == 0:
		var eye := Vector3(REF.x, 1.75, REF.y)
		if lance == 9: eye = Vector3(sc.ast.x, 1.7, sc.ast.y)
		# nervos: a imagem treme
		var st: float = float(L.get("stress", 0.0)) if modo != "treino" else 0.0
		var amp: float = maxf(0.0, (st - 40.0) / 60.0) * 0.008 * eye.distance_to(look)
		var tm := Time.get_ticks_msec() / 1000.0
		# nervos: uma deriva lenta da imagem (não um tremor)
		var shake := Vector3(sin(t * 1.3) * 0.01, sin(t * 1.7) * 0.008, 0) + Vector3(amp * (sin(tm * 2.3) + 0.4 * sin(tm * 3.7)), amp * 0.5 * sin(tm * 2.9 + 1), amp * (sin(tm * 1.9 + 2) + 0.4 * sin(tm * 3.3)))
		# corpo a correr: a cabeça sobe e desce a cada passo e balança de lado; parado, respira
		var fw := Vector3(look.x - eye.x, 0, look.z - eye.z).normalized()
		var lado := fw.cross(Vector3.UP)
		var corre := clampf(ref_vel / 5.0, 0.0, 1.0)
		var resp_f := 0.25 + ref_cansaco * 0.45 + corre * 0.2           # respirações por segundo
		var resp := sin(tm * TAU * resp_f) * (0.004 + ref_cansaco * 0.012) * (1.0 - corre * 0.6)
		# sem som de respiração do árbitro a correr (o arfar era demasiado)
		# os olhos compensam a passada (como na vida real): balanço pequeno e suave
		var bob := Vector3.UP * (absf(sin(ref_ph)) * 0.018 - 0.009) * corre + lado * sin(ref_ph) * 0.008 * corre
		eye += bob + Vector3.UP * resp + shake
		# a cabeça segue o lance com algum atraso (mais quando está cansado)
		if lance == 9 or ref_olhar == Vector3.ZERO: ref_olhar = look
		ref_olhar = ref_olhar.lerp(look, clampf(get_process_delta_time() * (7.0 - 3.5 * ref_cansaco), 0.0, 1.0))
		var alvo := ref_olhar + shake * 0.5 + Vector3.UP * resp + bob
		# foco: como o olho se fixa no lance, o enquadramento aperta com a distância (o lance ocupa ~14 m de altura)
		var dl := eye.distance_to(look)
		var foco := clampf(rad_to_deg(2.0 * atan(6.0 / maxf(dl, 1.0))), 15.0, 52.0 if lance == 11 else 40.0)
		if ref_foco == 0.0: ref_foco = foco
		ref_foco = lerpf(ref_foco, foco, clampf(get_process_delta_time() * 2.0, 0.0, 1.0))
		cam.fov = ref_foco + corre * 1.5 - ref_cansaco * 1.0
		cam.look_at_from_position(eye, alvo)
		# inclina com o balanço da passada
		cam.rotate_object_local(Vector3(0, 0, 1), sin(ref_ph) * 0.002 * corre + sin(tm * 0.7) * 0.002 * ref_cansaco)
	elif lance == 9 and modo in ["var", "rever"] and t >= TC - 0.01:
		_var_camera()
	elif cam_mode == 4:
		_tv_camera(look)
	elif cam_mode == 5:
		_obs_camera(look)
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
		if lance == 11:
			# de lado, na linha da área de baliza: vê-se o guarda-redes na linha e o marcador
			var gx2: float = float(sc.gx) - float(sc.dir_in) * 5.5
			cam.fov = 58
			cam.look_at_from_position(Vector3(gx2, 1.4, H / 2 + 10.5), Vector3(gx2, 0.7, H / 2))
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

# ---------- noites difíceis em 3D: chuva, nevoeiro, fumo das tochas e apagão ----------
func _clima_nodes() -> void:
	chuva_p = CPUParticles3D.new()
	var gm := QuadMesh.new(); gm.size = Vector2(0.007, 0.4)
	var rm := StandardMaterial3D.new(); rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; rm.albedo_color = Color(0.82, 0.88, 0.96, 0.28); rm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	gm.material = rm
	chuva_p.mesh = gm; chuva_p.amount = 2600; chuva_p.lifetime = 0.75; chuva_p.preprocess = 0.75
	chuva_p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; chuva_p.emission_box_extents = Vector3(14, 0.5, 14)
	chuva_p.direction = Vector3(0.12, -1, 0.05); chuva_p.spread = 3.0; chuva_p.initial_velocity_min = 16.0; chuva_p.initial_velocity_max = 20.0
	chuva_p.gravity = Vector3(0, -12, 0); chuva_p.local_coords = false; chuva_p.emitting = false; chuva_p.visible = false
	add_child(chuva_p)
	fumo_p = CPUParticles3D.new()
	var fm := QuadMesh.new(); fm.size = Vector2(7, 7)
	var sm := StandardMaterial3D.new(); sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sm.albedo_texture = _fumo_tex(); sm.albedo_color = Color(0.86, 0.84, 0.82, 0.55); sm.vertex_color_use_as_albedo = true
	fm.material = sm
	fumo_p.mesh = fm; fumo_p.amount = 70; fumo_p.lifetime = 7.0; fumo_p.preprocess = 7.0
	fumo_p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE; fumo_p.emission_sphere_radius = 8.0
	fumo_p.direction = Vector3(0.3, 1, 0.1); fumo_p.spread = 40.0; fumo_p.initial_velocity_min = 0.3; fumo_p.initial_velocity_max = 0.9
	fumo_p.gravity = Vector3(0.25, 0.12, 0.08); fumo_p.scale_amount_min = 0.7; fumo_p.scale_amount_max = 1.6
	fumo_p.local_coords = false; fumo_p.emitting = false; fumo_p.visible = false
	add_child(fumo_p)
# nuvem redonda e suave (sem ficheiro)
func _fumo_tex() -> ImageTexture:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(x - n / 2.0 + 0.5, y - n / 2.0 + 0.5).length() / (n / 2.0)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a * (3.0 - 2.0 * a)))
	return ImageTexture.create_from_image(img)
# aplica o tempo do jogo ao lance 3D (sem jogo, tudo limpo)
func _clima_3d(limpo := false) -> void:
	var ativo: bool = jogo != null and not limpo and modo in ["lance", "var", "rever", "gesto", "flash"]
	var c: String = jogo.clima if ativo else ""
	env.fog_enabled = c != ""
	env.fog_density = 0.04 if c == "nevoeiro" else 0.009
	env.fog_light_color = (Color(0.3, 0.32, 0.36) if night else Color(0.74, 0.77, 0.8)) if c == "nevoeiro" else (Color(0.2, 0.22, 0.26) if night else Color(0.5, 0.55, 0.62))
	env.fog_sky_affect = 0.9 if c == "nevoeiro" else 0.4
	chuva_p.visible = c == "chuva"; chuva_p.emitting = c == "chuva"
	var fz: Dictionary = jogo.fumo if ativo else {}
	var com_fumo: bool = not fz.is_empty() and float(fz.a) > 0.15
	fumo_p.visible = com_fumo; fumo_p.emitting = com_fumo
	if com_fumo:
		fumo_p.global_position = Vector3(fz.c.x, 2.5, fz.c.y); fumo_p.emission_sphere_radius = float(fz.r) * 0.6
		(fumo_p.mesh.material as StandardMaterial3D).albedo_color.a = 0.55 * float(fz.a)
	# apagão: metade dos projetores apagados (só faz sentido à noite)
	var lz: float = jogo.luz if ativo else 1.0
	if night:
		sun.light_energy = 1.05 * (0.35 + 0.65 * lz)
		env.ambient_light_energy = 0.3 * (0.4 + 0.6 * lz)
		for i in floods.size():
			var on: bool = lz >= 1.0 or i % 2 == 0
			(floods[i][0] as StandardMaterial3D).emission_energy_multiplier = 6.0 if on else 0.0
			(floods[i][1] as OmniLight3D).light_energy = 0.9 if on else 0.0
	elif c == "chuva" or c == "nevoeiro":
		sun.light_energy = 0.9; env.ambient_light_energy = 0.5
	else:
		sun.light_energy = 1.45; env.ambient_light_energy = 0.55

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
	var sh: Array = tv.get("shots", TV_SHOTS)[tv.i]
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
			if tv.i < tv.get("shots", TV_SHOTS).size(): _tv_shot()
			elif tv.has("obs"): obs_i += 1; _obs_next()
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
# Fala de relato gravada para um acontecimento do jogo (os nomes ficam só no texto).
func _relato(d: Dictionary) -> String:
	var t: String = str(d.txt).to_lower()
	var k := "golo"
	if d.kind == "pen" or t.contains("penálti"): k = "penalti"
	if d.kind == "card": k = "vermelho" if (t.contains("vermelho") or t.contains("expuls")) else "amarelo"
	if d.kind == "goal": k = "golo"
	return "relato_%s_%d" % [k, rng.randi_range(1, 3 if k == "golo" else 2)]

func _ev(n: String, d: Dictionary) -> void:
	match n:
		"toast": ui.toast(d.txt, d.secs)
		"radio":
			var fala: String = d.get("voz", d.txt)
			ui.radio(d.who, d.txt)
			if not som.tem_fala(fala) or not som.voice_on: som.radio()   # as falas gravadas já trazem o estalido
			som.say(fala, d.who)
		"feed":
			ui.feed(d)
			if d.kind in ["goal", "card", "pen"]: som.say(_relato(d), "Relato")
		"sfx": _sfx(d.k, d.a)
		"lance":
			L = d.L
			ui.flash(L.get("flash", "Lance!")); som.alerta()
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
		"cheer":
			som.cheer(a if a != null else 0.6)
			fan_festa = maxf(fan_festa, a if a != null else 0.6)
		"boo":
			som.boo(a if a != null else 0.5)
			fan_protesto = maxf(fan_protesto, a if a != null else 0.5)
		"ooh": som.ooh()
		"beep": som.beep()
		"react": som.react(a if a != null else 0.5)

func _new_match(teams: Array, career := false) -> void:
	ui.hide_all()
	jogo = Partida.new(teams)
	jogo.ev = _ev
	_fans_colors(Color(teams[0].color), Color(teams[1].color))
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
	campo.visible = true; radar.visible = false
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
	_clima_3d()
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
		# no monitor do VAR não há relógio: vês o lance as vezes que precisares
		if modo == "var":
			ui.dec_text("Decide: teclas 1–%d   (sem limite de tempo)" % jogo.choices_for(L).size())
			return
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
	if card.visible: _card_in_hand(fwd)
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

# cartão entre o polegar e os dedos: na direção da mão (antebraço -> pulso), virado para a frente
func _card_in_hand(fwd: Vector3) -> void:
	var wr := refj.bone_world("wrist_R")
	var dh := (wr - refj.bone_world("lowerarm01_R")).normalized()
	var z := (fwd - dh * fwd.dot(dh)).normalized()
	if z.length() < 0.1: z = Vector3(0, 0, 1)
	var x := dh.cross(z).normalized()
	card.global_transform = Transform3D(Basis(x, dh, z), wr + dh * 0.125 + z * 0.025)
	(card.material_override as StandardMaterial3D).emission = (card.material_override as StandardMaterial3D).albedo_color

func _end_gesture() -> void:
	if G.is_empty(): return
	G = {}
	card.visible = false
	ui.ref_say("")
	jogo.finish_after()
	if jogo.mode == "fim" or modo == "fim": return
	if modo == "gesto": _back_to_match()

func _entrevista(i: int) -> void:
	if entrevista.is_empty() or i >= entrevista.opts.size(): return
	var o: Dictionary = entrevista.opts[i]
	var txt := ""
	if is_career:
		car.C.imagem = clampi(int(car.C.get("imagem", 50)) + int(o.img), 0, 100)
		car.save_c()
		txt = " Imagem pública: %d/100 (%+d)." % [int(car.C.imagem), int(o.img)]
	ui.entrevista_feita(o, txt)
	entrevista = {}

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
	social = Redes.gerar(jogo, d.grade, d.kind) if d.kind != "treino" else {}
	entrevista = Redes.entrevista(jogo, social.big, d.grade) if not social.is_empty() else {}
	var note := ""
	if is_career: note = car.after(jogo, d.grade, d.kind)
	if is_career and not social.is_empty():
		car.C.trend = social.trend
		car.C.imagem = clampi(int(car.C.get("imagem", 50)) + (3 if d.grade >= 8.0 else (-4 if d.grade < 5.0 else 0)), 0, 100)
		car.save_c()
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
	_obs_limpa()
	ui.dec.visible = false
	_to_2d()
	if rever_de == "half": modo = "intervalo"; ui.half.visible = true
	else: modo = "fim"; ui.report.visible = true
	L = {}

# ---------- vídeo do observador ----------
func _obs_start(lista: Array) -> void:
	if lista.is_empty(): return
	rever_de = "report"
	ui.half.visible = false; ui.report.visible = false
	obs = lista; obs_i = 0
	if obs_cap == null:
		obs_cap = Label.new(); obs_cap.add_theme_font_size_override("font_size", 18)
		obs_cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		obs_cap.anchor_left = 0.0; obs_cap.anchor_right = 1.0; obs_cap.anchor_top = 1.0; obs_cap.anchor_bottom = 1.0
		obs_cap.offset_left = 30; obs_cap.offset_right = -30; obs_cap.offset_top = -190; obs_cap.offset_bottom = -110
		var sb := StyleBoxFlat.new(); sb.bg_color = Color(0.05, 0.07, 0.12, 0.88); sb.set_content_margin_all(12); sb.corner_radius_top_left = 6; sb.corner_radius_top_right = 6; sb.corner_radius_bottom_left = 6; sb.corner_radius_bottom_right = 6
		obs_cap.add_theme_stylebox_override("normal", sb)
		tv_layer.add_child(obs_cap)
		for c in [Color(0.95, 0.25, 0.2), Color(0.3, 0.95, 0.4)]:
			var r := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 1.0; tm.outer_radius = 1.35; r.mesh = tm
			var mt := StandardMaterial3D.new(); mt.albedo_color = c; mt.emission_enabled = true; mt.emission = c; mt.emission_energy_multiplier = 0.8; mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			r.material_override = mt; r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(r)
			var lb := Label3D.new(); lb.font_size = 72; lb.pixel_size = 0.012; lb.modulate = c; lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lb.outline_size = 12
			lb.text = "Estavas aqui" if c.r > 0.5 else "Posição ideal"; lb.position = Vector3(0, 2.6, 0); r.add_child(lb)
			r.visible = false; obs_marcas.append(r)
	ui.show_dec([], "")
	ui.dec_row.add_child(ui._btn("Voltar ao relatório", func(): _end_review(), Color(0.3, 0.2, 0.2), 0, 16))
	_obs_next()

func _obs_next() -> void:
	if obs_i >= obs.size():
		_end_review(); return
	var l: Dictionary = obs[obs_i]
	L = l; modo = "rever"
	_setup_scene(l)
	paused = false; speed = 1.0; replays = 1
	_to_3d()
	ui.dec.visible = true
	tv = {"i": 0, "obs": true, "shots": OBS_SHOTS_OFF if lance == 9 else OBS_SHOTS}
	_tv_shot()
	var linha := ""
	for r in jogo.report_rows():
		if r.L == l:
			var c: Array = r.cells
			linha = "Observador · lance %d de %d · %s · %s\nDecidiste: %s · %s · %s" % [obs_i + 1, obs.size(), c[0], c[1], c[2], c[3], c[4]]
	obs_cap.text = linha; obs_cap.visible = true
	var ideal := _obs_ideal()
	obs_marcas[0].position = Vector3(REF_FIM.x, 0.05, REF_FIM.y)
	obs_marcas[1].position = Vector3(ideal.x, 0.05, ideal.y)

func _obs_limpa() -> void:
	obs = []
	if obs_cap: obs_cap.visible = false
	for r in obs_marcas: r.visible = false
	if not tv.is_empty(): _tv_end()

# onde o observador queria o árbitro: em diagonal, de lado para o contacto e um pouco atrás da jogada
func _obs_ideal() -> Vector2:
	var sd := Vector2(-A.y, A.x)
	if (REF_FIM - P).dot(sd) < 0.0: sd = -sd
	var q := P + sd * 11.0 - A * 6.0
	return Vector2(clampf(q.x, 1.0, W - 1.0), clampf(q.y, 1.0, H - 1.0))

func _obs_camera(look: Vector3) -> void:
	var ideal := _obs_ideal()
	var c := (Vector2(look.x, look.z) + REF_FIM + ideal) / 3.0
	var span := maxf(REF_FIM.distance_to(Vector2(look.x, look.z)), ideal.distance_to(Vector2(look.x, look.z)))
	for r in obs_marcas: r.visible = true
	cam.fov = 50
	cam.look_at_from_position(Vector3(c.x, 10.0 + span * 0.9, c.y + 6.0 + span * 0.7), Vector3(c.x, 0.0, c.y))

# ---------- menu e botões ----------
func _show_menu() -> void:
	_set_night(false)
	if chuva_p: _clima_3d(true)
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
	ui.show_menu(car.exists(), ("%.1f" % b).replace(".", ",") if b > 0 else "", som.voice_on, not som.muted, not som.publico_off)

func on_ui(a: String, v) -> void:
	match a:
		"partida": _new_match(Carreira.default_teams()); jogo.sorteia_ambiente(night); jogo.anuncia_clima()
		"carreira", "career":
			if not car.load_c(): car.new_career()
			modo = "carreira"; _show_menu_bg(); ui.show_career(car)
		"career_play":
			var B := car.match_brief()
			_new_match(car.career_teams(B), true)
			car.setup_match(jogo)
			jogo.sorteia_ambiente(night, str(B.story) == "derby", int(car.C.tier)); jogo.anuncia_clima()
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
		"publico": som.toggle_publico(); _show_menu()
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
		"obs_video": _obs_start(v)
		"entrevista": _entrevista(int(v))
		"again": _new_match(Carreira.default_teams()); jogo.sorteia_ambiente(night); jogo.anuncia_clima()
		"menu": _show_menu()
		"tut_click": if jogo: jogo.tut_click()
		"cap": if jogo: ui.show_card(jogo, v, "")

func _show_menu_bg() -> void:
	_to_3d()
	for j in [att, def, refj] + extras: j.reset(); j.node.visible = false
	ball.visible = false

func _start_training() -> void:
	_set_night(false)
	_clima_3d(true)
	ui.hide_all()
	modo = "treino"
	_to_3d()
	cam_mode = 1
	sc = {"kind": "treino", "approach": true}
	_training_setup()
	cur = {}; _restart()

func _training_setup() -> void:
	P = Vector2(60, 30); A = Vector2(-1, 0); REF = Vector2(70, 46)
	_ref_corrida(REF, 100.0)
	att.set_kit(LARANJA, 9, 1); def.set_kit(AZUL, 4, 0)
	_fans_colors(AZUL.color, LARANJA.color)
	att.label.modulate = Color(0.97, 0.97, 0.95); def.label.modulate = Color(0.97, 0.97, 0.95)
	for j in [att, def]: j.mat.set_shader_parameter("numcol", Color(0.97, 0.97, 0.95))
	att.node.visible = true; def.node.visible = true
	var spots := [Vector2(68, 22), Vector2(52, 40), Vector2(75, 33), Vector2(48, 24)]
	for i in extras.size():
		var home := i % 2 == 0
		extras[i].set_kit(AZUL if home else LARANJA, [2, 7, 5, 10, 3, 8][i], 0 if home else 1)
		extras[i].label.modulate = Color(0.97, 0.97, 0.95)
		extras[i].mat.set_shader_parameter("numcol", Color(0.97, 0.97, 0.95))
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
		bvel = A * (clampf(att.speed, 1.0, vA) * 1.35)
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
	# corte limpo: nos últimos instantes a bola encontra o pé do defesa, que lhe toca primeiro (e só nela)
	if clean and lance in [0, 4] and not hit_done and t > TC - 0.25:
		var pe := _bico_do_pe(def, Vector3(bpos.x, 0.11, bpos.y))
		var k := clampf((t - (TC - 0.25)) / 0.25, 0.0, 1.0)
		bpos = bpos.lerp(Vector2(pe.x, pe.z), k * k)
	# a bola acompanha quem a conduz: se ele abranda (agarrado, a proteger), ela não lhe foge
	var va := clampf(att.speed, 1.0, vA)
	if not free_ball and bvel.length() < va: bvel = A * va
	if not free_ball and ahead_of_att() > 1.6: bvel = A * minf(bvel.length(), va * 0.8)
	ball.position = Vector3(bpos.x, 0.11, bpos.y)
	if not paused and bvel.length() > 0.05: ball.rotate(Vector3(bvel.y, 0, -bvel.x).normalized(), bvel.length() / 0.11 * dt)

func ahead_of_att() -> float:
	var ap := att.body_pos()
	return Vector2(bpos.x - ap.x, bpos.y - ap.z).dot(A)

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
	var sl: bool = lance == 0 and not sim_dive and (clean or force >= 0.82) and not cur.get("de_pe", false)
	var dp: Vector2
	if t < TC: dp = C - D * vD * (TC - t)
	else: dp = C + D * 1.6 * (1.0 - exp(-(t - TC) * 3.0))
	if sim_dive: dp -= D * sim_off       # na simulação o defesa nunca chega a menos de 30 cm
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
	# depois do toque o pé fica onde tocou (não atravessa a perna do atacante)
	if not toque.is_empty() and t < toque.t + 0.2: tgt = toque.get("pe", tgt); w = 1.0
	if not sl: def.ik = {"foot_R": [tgt, w]}
	if sim_dive and t > TC - 0.5:
		var gs: float = Jogador.folga(def, att, ["perna", "pe", "tronco"], ["perna", "pe", "tronco", "braco"])[0]
		if gs < 0.32: sim_off = minf(sim_off + (0.32 - gs) * 0.8, 2.0)
	if not hit_done and _toque_agora(not (sim_dive or clean)):
		if not toque.is_empty(): toque.pe = tgt
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
		# na falta ninguém tocou na bola: segue em frente sozinha
		free_ball = true; bvel = A * maxf(bvel.length(), vA * 0.9)
		if clean:
			outcome = "corte limpo: o defesa tira a bola, o atacante só tropeça (siga)"
			var b3 := Vector3(bpos.x, 0.11, bpos.y)
			_impacto(b3, 0.6, true)
			_brilha_bola()
			_brilha(def, b3, ["pe", "perna"], Color(0.3, 0.95, 1.0))
			bvel = (D * 0.9 - A * 0.2).normalized() * 9.0
			att.hit(Vector3(0.3, 0.0, 0.25 * side))
			att.play("jog", 0.2)
		elif force < 0.78 and not L.get("fall", false):
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

# Os corpos não se atravessam: depois do toque encostam (no máximo 2 cm), e sem falta (simulação,
# corte limpo) ficam sempre afastados. Cede o atacante (ou o defesa, se o atacante já estiver em queda livre).
# Corre depois das animações deste frame (nó "Corretor", prioridade alta) e é desfeito no início do seguinte,
# por isso nunca se acumula nem atrasa um frame.
var desvio_j: Jogador = null
func _desfaz_desvio() -> void:
	if desvio_j != null and desvio != Vector3.ZERO: desvio_j.node.position -= desvio
	desvio = Vector3.ZERO; desvio_j = null

func _sem_atravessar() -> void:
	if not (modo in ["lance", "var", "rever", "treino"]) or not (lance in [0, 1, 3, 4]): return
	var minimo := 99.0
	if (sim_dive or clean) and lance in [0, 4] and t > TC - 0.4 and t < TC + 1.5: minimo = 0.15
	elif not toque.is_empty() and t < toque.t + 0.6: minimo = -0.02
	if minimo > 50.0: return
	var j: Jogador = att if not att.rag else def
	if j.rag: return
	var sinal := 1.0 if j == att else -1.0
	for it in 10:
		var f: Array = Jogador.folga(def, att, ["perna", "pe", "tronco", "braco", "mao"], ["perna", "pe", "tronco", "braco", "mao"])
		var g: float = f[0]
		if g >= minimo: break
		var n: Vector3 = f[2]; n.y = 0.0
		if n.length() < 0.2:
			var a3 := att.body_pos(); var d3 := def.body_pos()
			n = Vector3(a3.x - d3.x, 0, a3.z - d3.z)
		n = n.normalized() if n.length() > 0.01 else Vector3(A.x, 0, A.y)
		var dv := n * (minimo - g) * (1.2 if it < 5 else 2.0) * sinal
		desvio += dv; desvio_j = j; j.node.position += dv

# Há toque? Nas faltas o lance reage no primeiro instante em que as peles se tocam (perto de TC);
# se por azar a animação não chegar a tocar, força-se o toque em TC + 0,12 s. Sem toque (simulação, corte limpo): TC.
func _toque_agora(com_toque: bool) -> bool:
	if not com_toque: return t >= TC
	if t < TC - 0.3: return false
	var pr: Array = PARTES_TOQUE.get(lance, [["perna", "pe"], ["perna", "pe"]])
	var f: Array = Jogador.folga(def, att, pr[0], pr[1])
	if float(f[0]) <= 0.03 or t >= TC + 0.12:
		toque = {"t": t, "pt": f[1], "g": f[0]}
		var pa: Array = pr[1]; var pd: Array = pr[0]; var pt: Vector3 = f[1]
		if lance in [0, 4]:
			var fp: Array = Jogador.folga(def, att, ["pe", "perna"], ["perna", "pe"])
			if float(fp[0]) < 0.12: pt = fp[1]; pa = ["perna", "pe"]; pd = ["pe", "perna"]
		_impacto(pt, force)
		_brilha(att, pt, pa, Color(1.0, 0.12, 0.08))
		_brilha(def, pt, pd, Color(1.0, 0.75, 0.1))
		return true
	return false

# marca do impacto: anel que se abre no ponto do toque, um tufo de relva/pó e um instante em câmara lenta
func _impacto(pt: Vector3, f: float, bola := false) -> void:
	if modo in ["lance", "treino", "rever", "var"] and tv.is_empty(): hitstop = HIT_CONGELA + HIT_LENTO + 0.12 * clampf(f - 0.8, 0.0, 1.0)
	_estrela_em(pt, Color(0.35, 0.95, 1.0) if bola else Color(1.0, 0.3, 0.05), Color.WHITE, 0.32 + 0.1 * clampf(f - 0.6, 0.0, 1.0))
	var ring := MeshInstance3D.new(); var tm := TorusMesh.new(); tm.inner_radius = 0.12; tm.outer_radius = 0.16; ring.mesh = tm
	var mt := StandardMaterial3D.new(); mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.albedo_color = Color(1, 0.95, 0.7, 0.9); mt.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	ring.material_override = mt; ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.rotation_degrees.x = 90
	add_child(ring); ring.global_position = pt
	var tw := create_tween(); tw.set_parallel(true)
	tw.tween_property(ring, "scale", Vector3.ONE * (2.2 + f), 0.35)
	tw.tween_property(mt, "albedo_color:a", 0.0, 0.35)
	tw.chain().tween_callback(ring.queue_free)
	if pt.y < 0.6:
		var pf := CPUParticles3D.new(); pf.one_shot = true; pf.amount = 14; pf.lifetime = 0.6; pf.explosiveness = 1.0
		pf.direction = Vector3(0, 1, 0); pf.spread = 70.0; pf.initial_velocity_min = 0.8; pf.initial_velocity_max = 1.8; pf.gravity = Vector3(0, -6, 0)
		pf.scale_amount_min = 0.03; pf.scale_amount_max = 0.06
		var qm := QuadMesh.new(); qm.size = Vector2(1, 1); pf.mesh = qm
		var pm := StandardMaterial3D.new(); pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; pm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES; pm.albedo_color = Color(0.32, 0.5, 0.2)
		qm.material = pm
		add_child(pf); pf.global_position = pt; pf.emitting = true
		get_tree().create_timer(1.2, true, false, true).timeout.connect(pf.queue_free)

# tropeção capturado: o corpo cai para a frente como na captura, depois fica queixoso no chão
func _trip(j: Jogador, d: Vector2, k: float, from := 0.12, blend := 0.08) -> void:
	var bp := j.body_pos()
	j.kin("trip", from, d, Vector2(bp.x, bp.z), k, "chao", blend, false, TRIP_CHAO)
const TRIP_CHAO := -1.0

# quando começar o carrinho, de onde e a que velocidade, para o pé chegar ao alvo no instante TC
# Captura com um momento-chave (cabeça na bola, pé na bola): onde pôr o jogador e quando arrancar,
# para o osso `bone` estar em `target` no instante `when` do lance.
func _kin_plan(j: Jogador, clip: String, key: float, bone: String, target: Vector2, d: Vector2, s0: float, when: float, k := 1.0) -> Dictionary:
	var R := Basis(Vector3.UP, atan2(d.x, d.y))
	var b3 := R * j.clip_bone(clip, key, bone)
	var a3 := R * j.clip_bone(clip, s0, "root")
	return {"ts": when - (key - s0) / k, "at": target - Vector2(b3.x, b3.z) + Vector2(a3.x, a3.z), "s0": s0, "k": k, "on": false}

# corre até ao sítio de arranque e faz a captura (devolve true enquanto a captura manda no jogador)
func _kin_run(j: Jogador, nome: String, clip: String, key: float, bone: String, target: Vector2, d: Vector2, s0: float, when: float, v: float, air := false, k := 1.0) -> bool:
	if not kp.has(nome): kp[nome] = _kin_plan(j, clip, key, bone, target, d, s0, when, k)
	var pl: Dictionary = kp[nome]
	if j.rag: return true
	if t < pl.ts:
		j.move(pl.at - d * v * (pl.ts - t), d, v); j.play("run" if v > 4.0 else "jog", 0.2)
		return true
	if not pl.on:
		pl.on = true; j.kin(clip, pl.s0, d, pl.at, pl.k, "anim", 0.15, air)
	return j.phase == "kin"

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
	# a verdade segue o que o 3D mostra: entrada que acerta na perna sem tocar primeiro na bola nunca é "lance limpo"
	if not sim_dive and not clean and not toque.is_empty() and not L.is_empty() and not L.has("decided") and L.get("truth", "") == "siga":
		L.truth = "falta"; L.erase("interp")
		outcome = "acertou na perna sem tocar na bola: falta"
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
	if not hit_done and _toque_agora(true):
		hit_done = true
		free_ball = true; bvel = A * 6.0
		var v3 := Vector3(A.x, 0, A.y) * vA
		if force < 0.95:
			outcome = "empurrão: perde o equilíbrio mas fica de pé (falta)"
			att.push(A * 3.0 * force); att.hit(Vector3(1.5 * force, 0, 0))
		else:
			outcome = "empurrão forte: projetado para a frente (falta, pode ser amarelo)"
			att.hurt = 0.3
			# dá dois ou três passos aos tropeções, de tronco à frente, e só depois cai de mãos no chão
			att.push(A * 2.4 * force); att.hit(Vector3(2.2 * force, 0, 0))
			sc.cai_em = t + 0.28 / force
		def.hit(Vector3(-0.8, 0, 0))
	if hit_done and sc.has("cai_em") and att.phase == "anim":
		att.lean = Vector3(0.3 * clampf((t - TC) / 0.2, 0.0, 1.0), 0, 0)
		att.move(att.pos + A * att.speed * dt, A, maxf(att.speed - 2.0 * dt, 4.0)); att.play("run", 0.1)
		if t >= sc.cai_em:
			sc.erase("cai_em"); att.lean = Vector3.ZERO
			_trip(att, A, 1.0, 0.3, 0.15)
		return
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
	att.layer = "held"; att.layer_w = 0.35 * gw
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
	if not hit_done and _toque_agora(true):
		hit_done = true
		if force < 1.2:
			outcome = "carga de ombro legal (lado a lado, bola em disputa): o laranja perde o equilíbrio"
			att.push(-perp * 2.6 * force); att.hit(Vector3(0, 0, -1.6 * side))
			def.push(perp * 1.0); def.hit(Vector3(0, 0, 0.6 * side))
		else:
			outcome = "carga forte e tardia: cai de lado (falta)"
			free_ball = true; bvel = A * 5.0
			att.hurt = 0.4
			att.fall(Vector3(A.x, 0, A.y) * vA - Vector3(perp.x, 0, perp.y) * 2.2 * force, ["spine03", "upperarm01_L", "upperarm01_R"], -Vector3(perp.x, 0, perp.y) * 3.0 * force, "trip", 0.5, Vector3.ZERO, 0.3)

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

# ---------- frame de impacto: estrela no ponto do toque e membros que tocaram a brilhar ----------
func _hit_escala() -> float:
	if hitstop <= 0.0: return 1.0
	if hitstop > HIT_LENTO: return 0.03
	return lerpf(1.0, 0.25, hitstop / HIT_LENTO)

# onde fica a bola encostada ao bico do pé do defesa que está mais perto dela
func _bico_do_pe(j: Jogador, b: Vector3) -> Vector3:
	var best := Vector3.ZERO; var bd := 1e9
	for c in j.capsulas():
		if c[3] != "pe": continue
		var tip: Vector3 = c[1]
		var fw: Vector3 = (c[1] - c[0]); fw.y = 0.0
		var p: Vector3 = tip + (fw.normalized() if fw.length() > 0.01 else Vector3.ZERO) * 0.1
		var d := p.distance_to(b)
		if d < bd: bd = d; best = p
	return best

func _estrela_mesh() -> ArrayMesh:
	if _estrela != null: return _estrela
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# coroa de picos à volta do ponto do toque; o meio fica vazio para se ver bem o contacto
	var n := 12
	for i in n * 2:
		var a0 := TAU * i / (n * 2.0); var a1 := TAU * (i + 1) / (n * 2.0)
		var r0 := 1.0 if i % 2 == 0 else 0.74; var r1 := 0.74 if i % 2 == 0 else 1.0
		var i0 := Vector3(cos(a0), sin(a0), 0) * 0.6; var i1 := Vector3(cos(a1), sin(a1), 0) * 0.6
		var o0 := Vector3(cos(a0) * r0, sin(a0) * r0, 0); var o1 := Vector3(cos(a1) * r1, sin(a1) * r1, 0)
		st.add_vertex(i0); st.add_vertex(i1); st.add_vertex(o0)
		st.add_vertex(i1); st.add_vertex(o1); st.add_vertex(o0)
	_estrela = st.commit()
	return _estrela

func _mat_brilho(c: Color, bill := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true; m.cull_mode = BaseMaterial3D.CULL_DISABLED; m.render_priority = 10
	m.albedo_color = c
	if bill: m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	return m

# estrela de banda desenhada: abre de repente e fica enquanto a imagem está quase parada
func _estrela_em(pt: Vector3, fora: Color, dentro: Color, tam: float) -> void:
	var raiz := Node3D.new(); add_child(raiz); raiz.global_position = pt
	# de longe (vista do árbitro) a estrela nunca fica pequena demais
	tam = maxf(tam, cam.global_position.distance_to(pt) * 0.03)
	for k in 2:
		# contorno escuro (traço de banda desenhada) e a coroa de cor: vermelha na perna, ciano na bola
		var mi := MeshInstance3D.new(); mi.mesh = _estrela_mesh()
		var c: Color = Color(0.05, 0.02, 0.0, 0.6) if k == 0 else fora
		if k == 1: c.a = 0.95
		mi.material_override = _mat_brilho(c, true); mi.material_override.render_priority = 10 + k
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.scale = Vector3.ONE * (1.1 if k == 0 else 1.0)
		raiz.add_child(mi)
	raiz.scale = Vector3.ONE * 0.01
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_property(raiz, "scale", Vector3.ONE * tam * 1.25, 0.07)
	tw.tween_property(raiz, "scale", Vector3.ONE * tam, 0.08)
	tw.tween_interval(HIT_CONGELA)
	tw.tween_property(raiz, "scale", Vector3.ONE * tam * 0.2, 0.3)
	tw.tween_callback(raiz.queue_free)
	brilhos.append({"mi": raiz, "j": null, "i": -1, "vida": 99.0, "solta": true})

# o membro que tocou fica a brilhar (vê-se através dos corpos) e acompanha o movimento
func _brilha(j: Jogador, pt: Vector3, partes: Array, c: Color) -> void:
	var caps: Array = j.capsulas()
	var bi := -1; var bd := 1e9
	for i in caps.size():
		var cp: Array = caps[i]
		if not (cp[3] in partes): continue
		var q: Vector3 = Jogador.seg_par(cp[0], cp[1], pt, pt)[0]
		var d := q.distance_to(pt) - float(cp[2])
		if d < bd: bd = d; bi = i
	if bi < 0: return
	var mi := MeshInstance3D.new(); var cm := CapsuleMesh.new()
	cm.radius = float(caps[bi][2]) + 0.03; cm.height = 1.0; cm.radial_segments = 12; cm.rings = 4
	mi.mesh = cm; c.a = 0.6; mi.material_override = _mat_brilho(c)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	brilhos.append({"mi": mi, "j": j, "i": bi, "vida": HIT_CONGELA + HIT_LENTO + 0.6, "a": 0.6})
	_brilhos_step(0.0)

func _brilha_bola() -> void:
	var mi := MeshInstance3D.new(); var sm := SphereMesh.new(); sm.radius = 0.17; sm.height = 0.34
	mi.mesh = sm; mi.material_override = _mat_brilho(Color(0.3, 0.95, 1.0, 0.55))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	brilhos.append({"mi": mi, "j": null, "i": -2, "vida": HIT_CONGELA + HIT_LENTO + 0.6, "a": 0.55})
	_brilhos_step(0.0)

func _brilhos_step(rdt: float) -> void:
	for b in brilhos.duplicate():
		if b.get("solta", false):
			if not is_instance_valid(b.mi): brilhos.erase(b)
			continue
		b.vida -= rdt
		var mi: MeshInstance3D = b.mi
		if b.vida <= 0.0 or not is_instance_valid(mi):
			if is_instance_valid(mi): mi.queue_free()
			brilhos.erase(b); continue
		var al: float = float(b.a) * clampf(b.vida / 0.35, 0.0, 1.0)
		(mi.material_override as StandardMaterial3D).albedo_color.a = al
		if int(b.i) == -2:
			mi.global_position = ball.global_position; continue
		var cp: Array = (b.j as Jogador).capsulas()[int(b.i)]
		var p0: Vector3 = cp[0]; var p1: Vector3 = cp[1]
		var ax := p1 - p0; var ln := maxf(ax.length(), 0.01)
		var y := ax / ln
		var x := y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		var z := x.cross(y)
		(mi.mesh as CapsuleMesh).height = ln + 2.0 * (mi.mesh as CapsuleMesh).radius
		mi.global_transform = Transform3D(Basis(x, y, z), (p0 + p1) * 0.5)

func _limpa_brilhos() -> void:
	for b in brilhos:
		if is_instance_valid(b.mi): b.mi.queue_free()
	brilhos.clear()

# 11) penálti: corrida, pontapé e guarda-redes. O árbitro julga a execução: guarda-redes adiantado,
# paragem ilegal no fim da corrida ou um colega do marcador a entrar na área antes do pontapé.
func _penalty(dt: float) -> void:
	var gx: float = float(sc.gx)
	var di: float = float(sc.dir_in)
	var perp := Vector2(-A.y, A.x)
	var infr: String = sc.infr
	var lado: float = float(sc.lado)
	# marcador: espera, corre (em diagonal, como quase todos) e bate. Na "paradinha" pára no fim da corrida e só depois remata
	var ini := P - A * 3.4 - perp * lado * 1.3
	var fim := P - A * 0.45 - perp * lado * 0.25
	var t_corre := TC - 1.25
	if not att.rag:
		if t < t_corre:
			att.move(ini, (P - ini).normalized(), 0.0); att.play("idle", 0.3)
		elif t < TC + 0.3:
			var dirc := (fim - ini).normalized()
			if infr == "paradinha":
				var k: float = clampf((t - t_corre) / 0.75, 0.0, 1.0)
				var pp := ini.lerp(fim - A * 0.5, k)
				if t < TC - 0.42: att.move(pp, dirc, 3.6 if k < 1.0 else 0.0); att.play("run" if k < 1.0 else "idle", 0.12)
				else:
					att.move((fim - A * 0.5).lerp(fim, clampf((t - (TC - 0.42)) / 0.42, 0.0, 1.0)), dirc, 1.2); att.play("kick", 0.08)
			else:
				var k: float = clampf((t - t_corre) / (TC - t_corre), 0.0, 1.0)
				att.move(ini.lerp(fim, k), dirc, 3.0)
				att.play("kick" if t > TC - 0.35 else "run", 0.1)
		else: _settle(att, dt, A)
	# guarda-redes: na linha até ao pontapé (no "gr" adianta-se antes do pontapé) e depois atira-se
	var linha := Vector2(gx - di * 0.15, H / 2)
	if not def.rag and def.phase != "kin" and def.phase != "chao_k":
		var gp := linha
		if infr == "gr" and t > TC - 0.45: gp = linha - Vector2(di, 0) * clampf((t - (TC - 0.45)) / 0.4, 0.0, 1.0) * 1.3
		def.move(gp, Vector2(-di, 0), 1.5 if gp != linha and t < TC else 0.0)
		def.play("jog" if infr == "gr" and t > TC - 0.45 and t < TC else "idle", 0.2)
		if t > TC + 0.04 and not sc.has("mergulho"):
			sc.mergulho = true
			var cur_gp := Vector2(def.body_pos().x, def.body_pos().z)
			_gk_dive(def, Vector2(cur_gp.x, H / 2 + float(sc.gk_lado) * 2.6), Vector2(-di, 0))
	# os outros esperam fora da área e entram quando a bola é batida (o invasor entra antes)
	var caixa_x := gx - di * 16.5
	for i in extras.size():
		var e: Jogador = extras[i]
		if not e.node.visible or e.rag or e.phase != "anim": continue
		var cu: Vector2 = e.get_meta("cur")
		var arranca := TC - 1.0 if (i == 0 and bool(sc.inv)) else TC + 0.08
		if t > arranca:
			var alvo := Vector2(gx - di * 9.0, lerpf(cu.y, H / 2, 0.4))
			var v: float = 5.5 if (i == 0 and bool(sc.inv)) else 4.5
			var dv := alvo - cu
			if dv.length() > 0.3: cu += dv.normalized() * minf(dv.length(), v * dt)
			e.set_meta("cur", cu)
			e.move(cu, dv.normalized() if dv.length() > 0.3 else Vector2(-di, 0), v if dv.length() > 0.3 else 0.0)
			e.play("run" if dv.length() > 0.3 else "idle", 0.2)
		else:
			var to := P - cu
			e.move(cu, to.normalized() if to.length() > 0.1 else A, 0.0); e.play("idle", 0.3)
	if bool(sc.inv) and not sc.has("inv_marca") and t >= TC:
		# no instante do pontapé fica registado onde estava o invasor (já dentro da área)
		var ip: Vector3 = extras[0].body_pos()
		sc.inv_marca = (ip.x - caixa_x) * di
	# bola: na marca até ao pontapé
	if not b3_free:
		b3 = Vector3(P.x, 0.11, P.y)
		if t >= TC:
			b3_free = true
			var golo: bool = sc.golo
			var poste := H / 2 + lado * 3.66
			var alvo3: Vector3
			if golo: alvo3 = Vector3(gx + di * 0.3, randf_range(0.3, 1.6), H / 2 + lado * randf_range(1.6, 3.0))
			elif float(sc.gk_lado) == lado: alvo3 = Vector3(gx - di * 0.5, 0.6, H / 2 + lado * 2.2); sc.defende = true
			else: alvo3 = Vector3(gx + di * 0.3, 0.9, poste + lado * 0.6)
			var tv := 0.42
			bv3 = (alvo3 - b3) / tv + Vector3(0, 9.8 * tv * 0.5, 0)
			if golo: b3_net = gx + di * 1.6
			sc.t_chega = TC + tv
			som.kick(0.8)
	elif sc.get("defende", false) and t >= float(sc.t_chega) and not sc.has("defendeu"):
		sc.defendeu = true
		bv3 = Vector3(-di * 5.0, 2.2, lado * 4.0)
	outcome = {"nenhuma": "penálti bem batido", "gr": "o guarda-redes saiu da linha antes do pontapé", "paradinha": "o marcador parou no fim da corrida antes de rematar",
		"invasao": "um colega do marcador entrou na área antes do pontapé"}[infr] + (" · golo" if sc.golo else " · sem golo")
