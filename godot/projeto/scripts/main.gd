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

func _player(kit: Dictionary, num: int, id: int) -> Dictionary:
	var node: Node3D = PLAYER.instantiate()
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
	node.scale = Vector3.ONE * (0.95 + r.randf() * 0.08)
	var ap: AnimationPlayer = node.find_children("*", "AnimationPlayer", true, false)[0]
	return {"node": node, "anim": ap, "state": ""}

func _play(p: Dictionary, name: String, blend := 0.15, from := 0.0) -> void:
	if p.state == name: return
	p.state = name
	p.anim.play(name, blend)
	if from > 0.0: p.anim.seek(from, true)

func _place(p: Dictionary, pos: Vector2, dir: Vector2) -> void:
	p.node.position = Vector3(pos.x, 0, pos.y)
	p.node.rotation.y = atan2(dir.x, dir.y)

func _restart() -> void:
	t = 0.0
	for p in [att, def] + extras: p.state = ""
	_play(att, "run", 0.0); _play(def, "run", 0.0)
	for e in extras: _play(e, "jog", 0.0)

func _process(delta: float) -> void:
	var dt := 0.0 if paused else delta * speed
	t += dt
	if t > DUR + 0.8: _restart()
	for p in [att, def] + extras: p.anim.speed_scale = 0.0 if paused else speed
	# atacante: corre, é tocado no tornozelo e cai para a frente
	var vA := 5.4
	var ap: Vector2
	if t < TC: ap = P + A * vA * (t - TC)
	else:
		var u := t - TC
		ap = P + A * 1.7 * (1.0 - exp(-u * 2.6))
	_place(att, ap, A)
	if t > TC + 0.04: _play(att, "dive", 0.12)
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
	# bola
	var bp: Vector2
	if t < TC: bp = ap + A * (0.6 + 0.2 * abs(sin(t * 5.0)))
	else: bp = P + A * 0.6 + (A * 0.6 + D * 0.8).normalized() * 6.0 * (1.0 - exp(-(t - TC) * 1.4))
	ball.position = Vector3(bp.x, 0.11, bp.y)
	if not paused: ball.rotate_x(dt * 9.0)
	_camera()
	ui.text = "GODOT 4 · protótipo do lance 3D   |   %s   |   %s s   |   1 a tua vista · 2 vista ideal · 3 atrás · Espaço pausa · S lento · R repetir" % [["A TUA VISTA", "VISTA IDEAL", "ATRÁS DO LANCE"][cam_mode], ("%+.2f" % (t - TC)).replace(".", ",")]

func _camera() -> void:
	var look := Vector3(P.x, 0.9, P.y)
	if cam_mode == 0:
		var shake := Vector3(sin(t * 3.1) * 0.02, sin(t * 4.3) * 0.015, 0)
		cam.fov = 38
		cam.look_at_from_position(Vector3(REF.x, 1.75, REF.y) + shake, look)
	elif cam_mode == 1:
		var side := Vector2(-A.y, A.x)
		var a3: Vector3 = att.node.position
		var d3: Vector3 = def.node.position
		var mid := Vector2((a3.x + d3.x) * 0.5, (a3.z + d3.z) * 0.5)
		var gap := Vector2(a3.x - d3.x, a3.z - d3.z).length()
		var c2 := mid + side * (6.0 + gap * 0.6)
		cam.fov = 45
		cam.look_at_from_position(Vector3(c2.x, 1.4, c2.y), Vector3(mid.x, 0.7, mid.y))
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
		cam_mode = (cam_mode + 1) % 3
	if e is InputEventScreenTouch and e.pressed:
		cam_mode = (cam_mode + 1) % 3
