class_name Campo2D
extends Control
# Desenha o jogo de caricas visto de cima e lê os comandos do árbitro (WASD/setas, Shift, clicar no campo).
# Em cima: marcador, relógio, vermelhos e as barras de controlo, energia, público e nervos.
# Tocar numa carica abre a ficha do jogador.

var jogo: Partida
var main: Node
var sc := 8.0
var org := Vector2.ZERO
var font: Font
const TOP := 64.0
var relva: ImageTexture          # relvado pintado uma vez: faixas de corte, variação e zonas gastas
var rasto: Array = []            # últimas posições da bola (rasto quando vai rápida)
var dentes := PackedVector2Array()   # contorno serrilhado de uma carica (raio 1)

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = ThemeDB.fallback_font
	for i in 42:
		var a := i * TAU / 42.0
		dentes.append(Vector2(cos(a), sin(a)) * (1.0 if i % 2 == 0 else 0.9))
	_pinta_relva()

func _pinta_relva() -> void:
	var k := 4
	var w := int((Partida.W + 8) * k); var h := int((Partida.H + 8) * k)
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var nz := FastNoiseLite.new(); nz.frequency = 0.035; nz.seed = 7
	var nz2 := FastNoiseLite.new(); nz2.frequency = 0.4; nz2.seed = 3
	var base := Color("217129")
	for y in h:
		for x in w:
			var wx := x / float(k) - 4.0; var wy := y / float(k) - 4.0
			var c := base
			# faixas de corte (mais suaves do que antes) e quadrados na zona das balizas
			if int(floor(wx / 5.25)) % 2 == 0: c = c.lightened(0.07)
			c = c.lerp(Color("2b7d2f"), 0.25 + 0.25 * nz.get_noise_2d(x, y))
			c = c.darkened(0.06 * nz2.get_noise_2d(x, y))
			# relva gasta: pequena área, marca de penálti e meio-campo
			for g in [Vector2(5.5, Partida.H / 2), Vector2(Partida.W - 5.5, Partida.H / 2), Vector2(Partida.W / 2, Partida.H / 2)]:
				var d := Vector2(wx, wy).distance_to(g)
				if d < 6.0: c = c.lerp(Color("6f6a3a"), (1.0 - d / 6.0) * 0.35 * (0.6 + 0.4 * nz2.get_noise_2d(x * 2, y * 2)))
			if wx < 0 or wy < 0 or wx > Partida.W or wy > Partida.H: c = c.darkened(0.12)
			img.set_pixel(x, y, c)
	relva = ImageTexture.create_from_image(img)

# carica de cima: sombra, bordo serrilhado, tampo com brilho; virada (no chão) mostra a cortiça
func _carica(c: Vector2, r: float, col: Color, dark: Color, virada: bool, sel: bool) -> void:
	var sh := PackedVector2Array(); var bd := PackedVector2Array()
	for v in dentes:
		sh.append(c + Vector2(r * 0.22, r * 0.3) + v * r * (1.05 if not virada else 0.9) * Vector2(1.0, 0.75 if virada else 1.0))
		bd.append(c + v * r * Vector2(1.0, 0.75 if virada else 1.0))
	draw_colored_polygon(sh, Color(0, 0, 0, 0.32))
	if virada:
		draw_colored_polygon(bd, Color("9aa0a6"))
		draw_set_transform(c, 0, Vector2(1, 0.75)); draw_circle(Vector2.ZERO, r * 0.74, Color("c8a46a")); draw_circle(Vector2(-r * 0.15, -r * 0.15), r * 0.3, Color(1, 1, 1, 0.12))
		draw_set_transform(Vector2.ZERO)
		draw_arc(c, r * 1.2, 0, TAU, 20, Color(1, 1, 1, 0.55), 2)
		return
	draw_colored_polygon(bd, dark)
	draw_circle(c, r * 0.82, col.darkened(0.12))
	draw_circle(c, r * 0.74, col)
	draw_circle(c + Vector2(-r * 0.12, -r * 0.14), r * 0.5, col.lightened(0.12))
	draw_arc(c, r * 0.78, PI * 1.05, PI * 1.6, 10, Color(1, 1, 1, 0.45), maxf(1.0, r * 0.12))
	if sel: draw_arc(c, r * 1.35, 0, TAU, 24, Color(1, 1, 1, 0.5 + 0.3 * sin(Time.get_ticks_msec() / 160.0)), 2)

func _layout() -> void:
	var sz := size
	sc = min((sz.x - 24) / (Partida.W + 8), (sz.y - TOP - 40) / (Partida.H + 8))
	org = Vector2((sz.x - Partida.W * sc) / 2, TOP + (sz.y - TOP - 36 - Partida.H * sc) / 2)

func w2s(p: Vector2) -> Vector2: return org + p * sc

func _process(_dt: float) -> void:
	if not visible or jogo == null: return
	var d := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): d.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): d.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): d.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): d.y += 1
	jogo.move_in = d
	if d != Vector2.ZERO or Input.is_key_pressed(KEY_SHIFT): jogo.sprint = Input.is_key_pressed(KEY_SHIFT)
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if jogo == null: return
	var at = null
	var tap := false
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: at = e.position; tap = true
	if e is InputEventScreenTouch and e.pressed: at = e.position; tap = true
	if e is InputEventScreenDrag: at = e.position
	if at == null: return
	var w: Vector2 = (at - org) / sc
	# tocar numa carica: ficha do jogador
	if tap:
		var best = null
		var bd := 1.6
		for p in jogo.players:
			if p.off: continue
			var dd: float = p.p.distance_to(w)
			if dd < bd: bd = dd; best = p
		if best != null and main:
			main.on_ui("cap", best); return
	jogo.ref_target = w
	# toque longe do árbitro = corrida
	jogo.sprint = jogo.ref.distance_to(w) > 18

func _star(c: Vector2, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	draw_colored_polygon(pts, Color("f2cf3a"))

func _bar(x: float, y: float, w: float, v: float, col: Color, label: String) -> void:
	draw_rect(Rect2(x, y, w, 7), Color(1, 1, 1, 0.12))
	draw_rect(Rect2(x, y, w * clamp(v / 100.0, 0, 1), 7), col)
	draw_string(font, Vector2(x, y - 3), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.88, 0.85))

func _draw() -> void:
	if jogo == null: return
	_layout()
	var W := Partida.W
	var H := Partida.H
	draw_rect(Rect2(Vector2.ZERO, size), Color("0f2a12"))
	draw_texture_rect(relva, Rect2(w2s(Vector2(-4, -4)), Vector2(W + 8, H + 8) * sc), false)
	var lc := Color(1, 1, 1, 0.75)
	var lw: float = max(1.0, sc * 0.14)
	draw_rect(Rect2(w2s(Vector2.ZERO), Vector2(W, H) * sc), lc, false, lw)
	draw_line(w2s(Vector2(W / 2, 0)), w2s(Vector2(W / 2, H)), lc, lw)
	draw_arc(w2s(Vector2(W / 2, H / 2)), 9.15 * sc, 0, TAU, 48, lc, lw)
	for s in [0, 1]:
		var gx := 0.0 if s == 0 else W
		var dr := 1.0 if s == 0 else -1.0
		var bx := gx if s == 0 else gx - 16.5
		draw_rect(Rect2(w2s(Vector2(bx, H / 2 - 20.15)), Vector2(16.5, 40.3) * sc), lc, false, lw)
		draw_rect(Rect2(w2s(Vector2(gx if s == 0 else gx - 5.5, H / 2 - 9.15)), Vector2(5.5, 18.3) * sc), lc, false, lw)
		draw_circle(w2s(Vector2(gx + dr * 11, H / 2)), sc * 0.25, lc)
		draw_arc(w2s(Vector2(gx + dr * 11, H / 2)), 9.15 * sc, (-0.93 if s == 0 else PI - 0.93), (0.93 if s == 0 else PI + 0.93), 20, lc, lw)
		draw_rect(Rect2(w2s(Vector2(gx - (1.6 if s == 0 else 0.0), H / 2 - 3.66)), Vector2(1.6, 7.32) * sc), Color(1, 1, 1, 0.35))
	# spray do livre: barreira a 9,15 m
	if not jogo.fk.is_empty() and jogo.fk.has("spot"):
		var fs: Vector2 = jogo.fk.spot
		draw_arc(w2s(fs), 9.15 * sc, 0, TAU, 40, Color(1, 1, 1, 0.35), 1.5)
	# assistentes com bandeira
	for i in 2:
		var a: Vector2 = jogo.ast[i]
		_carica(w2s(a), sc * 0.9, Color("e9d23c"), Color("2a2a2a"), false, false)
		if jogo.ast_flag[i] > 0:
			draw_rect(Rect2(w2s(a) + Vector2(sc * 0.5, -sc * 2.2), Vector2(sc * 1.4, sc * 0.9)), Color("ff3b2f"))
	# expulsos, junto ao banco
	for ti in 2:
		var k := 0
		for p in jogo.players:
			if p.team != ti or not p.off: continue
			var c := w2s(Vector2(W / 2 + (-3 - k * 1.7 if ti == 0 else 3 + k * 1.7), H + 1.75))
			draw_rect(Rect2(c - Vector2(0.5, 0.7) * sc, Vector2(1.0, 1.4) * sc), Color("d8322f"))
			draw_string(font, c + Vector2(-sc, sc * 0.35), str(p.num), HORIZONTAL_ALIGNMENT_CENTER, sc * 2, int(max(8.0, sc * 0.9)), Color.WHITE)
			k += 1
	# o que o árbitro vê: cone até à bola (verde perto, amarelo, vermelho longe) e quem está a tapar (as mesmas regras da nota)
	var tapam: Array = []
	if jogo.mode == "play":
		var rr: Vector2 = jogo.ref
		var vb: Vector2 = jogo.bp - rr
		var dist := vb.length()
		if dist > 1.0:
			var view := vb / dist
			for p in jogo.players:
				if p.off: continue
				var rp: Vector2 = p.p - rr
				var proj := rp.dot(view)
				if proj > 0.6 and proj < dist - 1 and absf(rp.cross(view)) < 0.85 and p.p.distance_to(jogo.bp) > 1.5: tapam.append(p)
			var q := clampf((dist - 8.0) / 28.0, 0.0, 1.0)
			var cc := Color(0.4, 1.0, 0.45).lerp(Color(1.0, 0.85, 0.3), minf(q * 2.0, 1.0)).lerp(Color(1.0, 0.35, 0.3), maxf(q * 2.0 - 1.0, 0.0))
			var lado := Vector2(-view.y, view.x) * (2.2 + dist * 0.12)
			var cone := PackedVector2Array([w2s(rr), w2s(jogo.bp + lado), w2s(jogo.bp - lado)])
			draw_colored_polygon(cone, Color(cc.r, cc.g, cc.b, 0.1))
			draw_dashed_line(w2s(rr), w2s(jogo.bp), Color(cc.r, cc.g, cc.b, 0.45), 1.5, 6.0)
	# caricas
	var fsz := int(max(9.0, sc * 1.6))
	for p in jogo.players:
		if p.off: continue
		var tm: Dictionary = jogo.teams[p.team]
		var c: Vector2 = w2s(p.p)
		var r := sc * 1.45
		var col: Color = tm.gk if p.role == "gk" else tm.color
		var dark: Color = (tm.gk as Color).darkened(0.35) if p.role == "gk" else tm.dark
		var tapa: bool = tapam.has(p)
		if tapa: draw_circle(c, r * 1.5, Color(1, 0.3, 0.2, 0.28))
		_carica(c, r, col, dark, p.down > 0, p == jogo.owner and jogo.mode == "play")
		if p.down > 0: continue
		var txc: Color = tm.get("text", Color.WHITE) if p.role != "gk" else Color.WHITE
		draw_string(font, c + Vector2(-r, fsz * 0.36), str(p.num), HORIZONTAL_ALIGNMENT_CENTER, r * 2, fsz, txc)
		if p.yellow > 0: draw_rect(Rect2(c + Vector2(r * 0.6, -r * 1.25), Vector2(sc * 0.55, sc * 0.8)), Color("ffd52e"))
		if "estrela" in p.tr: _star(c + Vector2(r * 0.95, -r * 0.95), sc * 0.6)
	# quem tem a bola
	var o = jogo.owner
	if o != null and o.short != "" and jogo.mode == "play":
		var c2: Vector2 = w2s(o.p) + Vector2(0, sc * 2.6)
		var tw := font.get_string_size(o.short, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_rect(Rect2(c2 - Vector2(tw / 2 + 3, 11), Vector2(tw + 6, 15)), Color(0.03, 0.06, 0.04, 0.6))
		draw_string(font, c2 - Vector2(tw / 2, 0), o.short, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.97, 0.97, 0.95))
	# bola (com sombra quando vai no ar)
	var b := w2s(jogo.bp)
	rasto.push_front(jogo.bp)
	if rasto.size() > 10: rasto.pop_back()
	for i in range(1, rasto.size()):
		var a1: Vector2 = rasto[i - 1]; var a2: Vector2 = rasto[i]
		if a1.distance_to(a2) > 0.12 and a1.distance_to(a2) < 4.0:
			draw_line(w2s(a1), w2s(a2), Color(1, 1, 1, 0.35 * (1.0 - i / 10.0)), maxf(1.0, sc * 0.5 * (1.0 - i / 10.0)))
	draw_circle(b + Vector2(jogo.bz * sc * 0.4 + sc * 0.12, jogo.bz * sc * 0.5 + sc * 0.15), sc * 0.45, Color(0, 0, 0, 0.35))
	var br := sc * (0.5 + jogo.bz * 0.05)
	draw_circle(b, br, Color.WHITE)
	draw_circle(b, br * 0.38, Color(0.15, 0.15, 0.18))
	draw_arc(b, br, 0, TAU, 12, Color(0, 0, 0, 0.35), 1.0)
	# árbitro
	var rp := w2s(jogo.ref)
	_carica(rp, sc * 1.3, Color("f4e04d"), Color("111111"), false, false)
	draw_string(font, rp + Vector2(-sc * 2, sc * 0.45), "Á", HORIZONTAL_ALIGNMENT_CENTER, sc * 4, int(max(8.0, sc * 1.2)), Color("111111"))
	if jogo.ref_target != null: draw_arc(w2s(jogo.ref_target), sc * 0.8, 0, TAU, 16, Color(1, 1, 0.4, 0.6), 2)
	# marcador e barras
	draw_rect(Rect2(0, 0, size.x, TOP - 6), Color(0, 0, 0, 0.55))
	var t0: Dictionary = jogo.teams[0]
	var t1: Dictionary = jogo.teams[1]
	draw_rect(Rect2(14, 12, 14, 14), t0.color); draw_rect(Rect2(14, 32, 14, 14), t1.color)
	draw_string(font, Vector2(34, 25), "%s  %d" % [t0.name, jogo.score[0]], HORIZONTAL_ALIGNMENT_LEFT, 260, 17, Color(0.97, 0.97, 0.94))
	draw_string(font, Vector2(34, 45), "%s  %d" % [t1.name, jogo.score[1]], HORIZONTAL_ALIGNMENT_LEFT, 260, 17, Color(0.97, 0.97, 0.94))
	var clk := jogo.clock_txt() + ("  2.ª parte" if jogo.half == 2 else ("  1.ª parte" if jogo.half == 0 else ""))
	if jogo.add_min > 0: clk += "  +%d'" % jogo.add_min
	draw_string(font, Vector2(310, 36), clk, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(1.0, 0.86, 0.35))
	var bx := maxf(500.0, size.x - 560)
	_bar(bx, 24, 120, jogo.control, Color("4fd16b") if jogo.control > 40 else Color("e24b3b"), "Controlo")
	_bar(bx + 135, 24, 120, jogo.stamina, Color("6fb7e8"), "Energia")
	_bar(bx + 270, 24, 120, jogo.crowd, Color("ee7d2c"), "Público")
	_bar(bx + 405, 24, 120, jogo.stress, Color("c05bd6"), "Nervos")
	draw_string(font, Vector2(bx, 50), "WASD/setas ou clicar: mover · Shift: correr · clicar numa carica: ficha · Espaço: pausa", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.8, 0.76))
	if not jogo.career.is_empty():
		draw_string(font, Vector2(310, 54), str(Carreira.TIERS[jogo.career.tier].name), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.8, 0.76))
