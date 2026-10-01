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

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = ThemeDB.fallback_font

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
	draw_rect(Rect2(w2s(Vector2(-4, -4)), Vector2(W + 8, H + 8) * sc), Color("1f6a26"))
	for i in 20:
		if i % 2 == 0: draw_rect(Rect2(w2s(Vector2(i * 5.25, 0)), Vector2(5.25, H) * sc), Color("25782c"))
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
		draw_circle(w2s(a), sc * 0.7, Color("e9d23c"))
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
	# caricas
	var fsz := int(max(9.0, sc * 1.6))
	for p in jogo.players:
		if p.off: continue
		var tm: Dictionary = jogo.teams[p.team]
		var c: Vector2 = w2s(p.p)
		var r := sc * 1.45
		var col: Color = tm.gk if p.role == "gk" else tm.color
		var dark: Color = (tm.gk as Color).darkened(0.35) if p.role == "gk" else tm.dark
		draw_circle(c + Vector2(sc * 0.18, sc * 0.25), r, Color(0, 0, 0, 0.3))
		draw_circle(c, r, dark)
		draw_circle(c, r * 0.8, col)
		if p.down > 0: draw_arc(c, r * 1.1, 0, TAU, 16, Color(1, 1, 1, 0.6), 2)
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
	draw_circle(b + Vector2(jogo.bz * sc * 0.4, jogo.bz * sc * 0.5), sc * 0.45, Color(0, 0, 0, 0.35))
	draw_circle(b, sc * (0.5 + jogo.bz * 0.05), Color.WHITE)
	# árbitro
	var rp := w2s(jogo.ref)
	draw_circle(rp, sc * 1.25, Color("111111"))
	draw_circle(rp, sc * 0.95, Color("f4e04d"))
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
