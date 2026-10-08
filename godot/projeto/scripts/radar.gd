class_name Radar
extends Control
# Mini-campo no canto do lance 3D, com a mesma orientação das caricas: onde é o lance (anel vermelho),
# de onde estás a ver (cone amarelo) e onde estão os jogadores agora. Liga o 3D ao que se viu em 2D.
var main
const W := 105.0
const H := 68.0
const ESC := 2.0     # píxeis por metro

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(W, H) * ESC + Vector2(8, 8)
	size = custom_minimum_size

func _process(_dt: float) -> void:
	if visible: queue_redraw()

func m2p(p: Vector2) -> Vector2: return Vector2(4, 4) + p * ESC

func _draw() -> void:
	if main == null: return
	var lc := Color(1, 1, 1, 0.7)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
	draw_rect(Rect2(m2p(Vector2.ZERO), Vector2(W, H) * ESC), Color(0.16, 0.42, 0.18, 0.85))
	draw_rect(Rect2(m2p(Vector2.ZERO), Vector2(W, H) * ESC), lc, false, 1.0)
	draw_line(m2p(Vector2(W / 2, 0)), m2p(Vector2(W / 2, H)), lc, 1.0)
	draw_arc(m2p(Vector2(W / 2, H / 2)), 9.15 * ESC, 0, TAU, 32, lc, 1.0)
	for s in [0, 1]:
		var bx := 0.0 if s == 0 else W - 16.5
		draw_rect(Rect2(m2p(Vector2(bx, H / 2 - 20.15)), Vector2(16.5, 40.3) * ESC), lc, false, 1.0)
		draw_rect(Rect2(m2p(Vector2(0.0 if s == 0 else W - 1.5, H / 2 - 3.66)), Vector2(1.5, 7.32) * ESC), Color(1, 1, 1, 0.9))
	# de onde se está a ver: cone com o ângulo real da câmara
	var cam: Camera3D = main.cam
	var o := Vector2(cam.global_position.x, cam.global_position.z)
	var f3 := -cam.global_transform.basis.z
	var f := Vector2(f3.x, f3.z)
	if f.length() > 0.05:
		f = f.normalized()
		var asp: float = main.get_viewport().get_visible_rect().size.aspect()
		var hf := atan(tan(deg_to_rad(cam.fov) * 0.5) * asp)
		var lg := 30.0
		var pts := PackedVector2Array([m2p(o), m2p(o + f.rotated(-hf) * lg), m2p(o + f.rotated(hf) * lg)])
		draw_colored_polygon(pts, Color(1.0, 0.86, 0.2, 0.28))
		draw_polyline(PackedVector2Array([pts[1], pts[0], pts[2]]), Color(1.0, 0.86, 0.2, 0.8), 1.0)
	# onde é o lance
	var P: Vector2 = main.P
	var pul := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)
	draw_arc(m2p(P), 4.0 * ESC + pul * 2.0, 0, TAU, 24, Color(1, 0.2, 0.15, 0.9), 2.0)
	# jogadores (posição 3D de agora) e bola
	var js: Array = [main.att, main.def] + main.extras
	for j in js:
		if not j.node.visible: continue
		var bp: Vector3 = j.body_pos()
		var c := Color(0.9, 0.9, 0.9)
		if main.jogo: c = main.jogo.teams[j.team].color
		draw_circle(m2p(Vector2(bp.x, bp.z)), 2.6, Color(0, 0, 0, 0.7))
		draw_circle(m2p(Vector2(bp.x, bp.z)), 2.0, c)
	var b: Vector3 = main.ball.global_position
	draw_circle(m2p(Vector2(b.x, b.z)), 1.6, Color.WHITE)
	# o árbitro (tu)
	var r: Vector2 = main.REF
	draw_circle(m2p(r), 3.2, Color(0, 0, 0, 0.8))
	draw_circle(m2p(r), 2.5, Color(1.0, 0.86, 0.2))
