class_name Campo2D
extends Control
# Desenha o jogo de caricas visto de cima e lê os comandos do árbitro (WASD/setas, Shift, clicar no campo).

const COL := [Color("3569dc"), Color("ee7d2c")]
const DARK := [Color("1d3f8f"), Color("a4521a")]
const GK := [Color("2fa36b"), Color("8a5bd6")]

var jogo: Partida
var sc := 8.0
var org := Vector2.ZERO
var font: Font
var toast := ""
var toast_t := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	font = ThemeDB.fallback_font

func say(s: String, d := 2.0) -> void:
	toast = s; toast_t = d

func _layout() -> void:
	var sz := size
	var top := 46.0
	sc = min((sz.x - 24) / (Partida.W + 8), (sz.y - top - 16) / (Partida.H + 8))
	org = Vector2((sz.x - Partida.W * sc) / 2, top + (sz.y - top - Partida.H * sc) / 2)

func w2s(p: Vector2) -> Vector2: return org + p * sc

func _process(dt: float) -> void:
	if not visible or jogo == null: return
	var d := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): d.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): d.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): d.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): d.y += 1
	jogo.move_in = d
	jogo.sprint = Input.is_key_pressed(KEY_SHIFT)
	if toast_t > 0: toast_t -= dt
	queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if jogo == null: return
	var at = null
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: at = e.position
	if e is InputEventScreenTouch and e.pressed: at = e.position
	if e is InputEventScreenDrag: at = e.position
	if at != null:
		jogo.ref_target = (at - org) / sc
		# toque longe do árbitro = corrida
		jogo.sprint = jogo.ref.distance_to(jogo.ref_target) > 18

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
	# assistentes com bandeira
	for i in 2:
		var a: Vector2 = jogo.ast[i]
		draw_circle(w2s(a), sc * 0.7, Color("e9d23c"))
		if jogo.ast_flag[i] > 0:
			draw_rect(Rect2(w2s(a) + Vector2(sc * 0.5, -sc * 2.2), Vector2(sc * 1.4, sc * 0.9)), Color("ff3b2f"))
	# caricas
	for p in jogo.players:
		if p.off: continue
		var c: Vector2 = w2s(p.p)
		var r := sc * 1.45
		var col: Color = GK[p.team] if p.role == "gk" else COL[p.team]
		draw_circle(c + Vector2(sc * 0.18, sc * 0.25), r, Color(0, 0, 0, 0.3))
		draw_circle(c, r, DARK[p.team])
		draw_circle(c, r * 0.8, col)
		if p.down > 0: draw_arc(c, r * 1.1, 0, TAU, 16, Color(1, 1, 1, 0.6), 2)
		var txt := str(p.num)
		var fs := int(max(9.0, sc * 1.6))
		draw_string(font, c + Vector2(-r, fs * 0.36), txt, HORIZONTAL_ALIGNMENT_CENTER, r * 2, fs, Color.WHITE)
		if p.yellow > 0: draw_rect(Rect2(c + Vector2(r * 0.6, -r * 1.25), Vector2(sc * 0.55, sc * 0.8)), Color("ffd52e"))
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
	# placar
	var m := jogo.minute()
	var top := "Azuis  %d - %d  Laranjas      %d'%s      Controlo %d%%      Fôlego %d%%" % [jogo.score[0], jogo.score[1], m, ("  (2.ª parte)" if jogo.half == 1 else ""), int(jogo.control), int(jogo.stamina)]
	draw_rect(Rect2(0, 0, size.x, 40), Color(0, 0, 0, 0.55))
	draw_string(font, Vector2(14, 27), top, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.97, 0.97, 0.94))
	draw_string(font, Vector2(size.x - 470, 27), "WASD/setas ou clicar: mover · Shift: correr", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.8, 0.85, 0.8))
	draw_rect(Rect2(14, 34, 160 * jogo.control / 100.0, 3), Color("4fd16b") if jogo.control > 40 else Color("e24b3b"))
	if toast_t > 0:
		var tw := font.get_string_size(toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var tp := Vector2((size.x - tw) / 2, size.y - 40)
		draw_rect(Rect2(tp + Vector2(-14, -28), Vector2(tw + 28, 40)), Color(0, 0, 0, 0.65))
		draw_string(font, tp, toast, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.92, 0.5))
