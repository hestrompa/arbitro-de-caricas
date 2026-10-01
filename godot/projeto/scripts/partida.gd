class_name Partida
extends RefCounted
# O jogo de caricas (vista de cima): 22 jogadores em 4-3-3, bola, foras de jogo com os assistentes,
# e o árbitro (tu). As entradas mais duras viram lances 3D que tens de decidir.
# Port do núcleo da versão browser (game.js).

const W := 105.0
const H := 68.0
const GOAL_W := 7.32
const BOX_D := 16.5
const BOX_W := 40.3
const SPOT := 11.0
const G := 9.8
const MATCH_SECONDS := 300.0       # 5 minutos reais = 90 minutos de jogo
const NAMES := ["Azuis", "Laranjas"]
const ART := ["os Azuis", "os Laranjas"]
const DE := ["dos Azuis", "dos Laranjas"]
const ROLES := [
	["gk", 34.0, "g", 1], ["lb", 9.0, "d", 3], ["lcb", 26.0, "d", 4], ["rcb", 42.0, "d", 5], ["rb", 59.0, "d", 2],
	["lcm", 21.0, "m", 8], ["cm", 34.0, "m", 6], ["rcm", 47.0, "m", 10], ["lw", 8.0, "f", 11], ["st", 34.0, "f", 9], ["rw", 60.0, "f", 7],
]
const LABEL := {"siga": "Lance limpo", "falta": "Falta", "amarelo": "Falta para amarelo", "vermelho": "Falta para vermelho", "simulacao": "Simulação"}
const DEC_LABEL := {"siga": "Siga", "falta": "Falta", "amarelo": "Amarelo", "vermelho": "Vermelho", "simulacao": "Simulação"}
const SEV := {"siga": 0, "falta": 1, "amarelo": 2, "vermelho": 3}

class Pl:
	var id := 0
	var team := 0
	var role := ""
	var line := ""
	var lane := 0.0
	var num := 0
	var p := Vector2.ZERO
	var v := Vector2.ZERO
	var spd := 7.0
	var yellow := 0
	var off := false
	var cd := 0.0
	var tackle_cd := 0.0
	var down := 0.0
	var dribble := Vector2.ZERO
	var set_piece := false
	var penalty := false
	var mark: Pl = null
	var run := 0.0
	var line_off := -1.5
	var fouls := 0

var dirs := [1, -1]
var players: Array = []
var t := 0.0
var score := [0, 0]
var control := 70.0
var stamina := 100.0
var aggr := [0.1, 0.1]
# bola
var bp := Vector2(W / 2, H / 2)
var bv := Vector2.ZERO
var bz := 0.0
var bvz := 0.0
var owner: Pl = null
var last := 0
var no_pick: Pl = null
var no_pick_t := 0.0
var target: Pl = null
var bpen := false
var off_info := {}
# árbitro
var ref := Vector2(W / 2, H / 2 + 7)
var ref_target = null
var move_in := Vector2.ZERO
var sprint := false
# assistentes: 0 em cima (metade esquerda), 1 em baixo (metade direita)
var ast := [Vector2(W / 4, -1.6), Vector2(W * 3 / 4, H + 1.6)]
var ast_flag := [0.0, 0.0]
var pause := 0.0
var lance_cd := 10.0
var mark_t := 0.0
var incidents: Array = []
var half := 0
var over := false
var offsides := 0
var dist_sum := 0.0
var lance: Dictionary = {}
var on_lance: Callable          # chamada quando há um lance para decidir
var on_msg: Callable            # mensagens curtas para o ecrã
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()
	for ti in 2:
		for i in ROLES.size():
			var r: Array = ROLES[i]
			var p := Pl.new()
			p.id = ti * ROLES.size() + i; p.team = ti; p.role = r[0]; p.lane = r[1]; p.line = r[2]; p.num = r[3]
			p.spd = rng.randf_range(6.3, 7.3)
			players.append(p)
	kickoff(0)

func rand(a: float, b: float) -> float: return rng.randf_range(a, b)
func rel(ti: int, x: float) -> float: return x if dirs[ti] > 0 else W - x
func abs_x(ti: int, r: float) -> float: return r if dirs[ti] > 0 else W - r
func own_goal_x(ti: int) -> float: return 0.0 if dirs[ti] > 0 else W
func opp_goal_x(ti: int) -> float: return W if dirs[ti] > 0 else 0.0
func in_own_box(ti: int, q: Vector2) -> bool: return rel(ti, q.x) < BOX_D and absf(q.y - H / 2) < BOX_W / 2
func active() -> Array: return players.filter(func(p): return not p.off)
func minute() -> int: return mini(90, int(t / MATCH_SECONDS * 90.0) + 1)
func msg(s: String, d := 2.0) -> void:
	if on_msg.is_valid(): on_msg.call(s, d)

func seg_dist(a: Vector2, b: Vector2, q: Vector2) -> Vector2:
	var v := b - a
	var l2: float = max(v.length_squared(), 0.0001)
	var k: float = clamp((q - a).dot(v) / l2, 0.0, 1.0)
	return Vector2((a + v * k - q).length(), k)

func nearest(list: Array, q: Vector2) -> Array:
	var best: Pl = null
	var d := 1e9
	for p in list:
		var dd: float = p.p.distance_to(q)
		if dd < d: d = dd; best = p
	return [best, d]

func formation_pos(p: Pl) -> Vector2:
	var r := 4.0 if p.line == "g" else (20.0 if p.line == "d" else (36.0 if p.line == "m" else 48.0))
	return Vector2(abs_x(p.team, r), p.lane)

func kickoff(team: int) -> void:
	for p in players:
		p.p = formation_pos(p); p.v = Vector2.ZERO; p.down = 0; p.set_piece = false; p.penalty = false; p.run = 0
	bp = Vector2(W / 2, H / 2); bv = Vector2.ZERO; bz = 0; bvz = 0; target = null; bpen = false; off_info = {}
	var taker: Pl = null
	for p in active():
		if p.team == team and p.role == "st": taker = p
	if taker == null:
		for p in active():
			if p.team == team and p.role != "gk": taker = p; break
	taker.p = Vector2(W / 2 - dirs[team] * 1.1, H / 2)
	owner = taker; last = team; taker.cd = 0.6; pause = 1.0

func move_to(p: Pl, tg: Vector2, speed: float, dt: float) -> void:
	var d := tg - p.p
	var dl := d.length()
	var sp: float = min(speed, dl * 2.5 + 0.3)
	var n := d / dl if dl > 0.001 else Vector2.ZERO
	var k: float = min(1.0, dt * 7.0)
	p.v += (n * sp - p.v) * k
	if dl < 0.25: p.v *= 0.8

func lane_open(a: Vector2, b: Vector2, opps: Array) -> float:
	var m := 99.0
	for q in opps:
		var s := seg_dist(a, b, q.p)
		if s.y > 0.04 and s.y < 0.97: m = min(m, s.x)
	return m

func offside_line(ti: int) -> float:
	var opp: Array = []
	for q in active():
		if q.team != ti: opp.append(rel(ti, q.p.x))
	opp.sort(); opp.reverse()
	return max(opp[1] if opp.size() > 1 else W, W / 2)

func shape_target(p: Pl, poss: bool) -> Vector2:
	var bx := rel(p.team, bp.x)
	var line := offside_line(p.team)
	var d: float; var m: float; var f: float
	if poss:
		d = clamp(bx - 30, 14, 52); m = clamp(bx - 8, d + 14, 78); f = clamp(max(bx + 8, line + p.line_off), m + 10, W - 7)
	else:
		d = clamp(bx - 22, 10, 42); m = clamp(bx - 9, d + 10, 62); f = clamp(bx + 5, m + 10, 78)
	var r := d if p.line == "d" else (m if p.line == "m" else f)
	var y := p.lane
	if poss:
		y = p.lane + (bp.y - H / 2) * 0.25
		if (p.role == "lb" or p.role == "rb") and absf(bp.y - p.lane) < 26 and bx > 40: r += 16
		if p.role == "lw" or p.role == "rw": y = 6.0 if p.lane < H / 2 else H - 6
		if p.role == "st": y = H / 2 + (bp.y - H / 2) * 0.3
		if p.line == "f" and p.run > 0: r = max(r, line + 6)
		if p.line == "f": r = min(r, max(line + (6.0 if p.run > 0 else p.line_off), bx + 4))
	else:
		y = H / 2 + (p.lane - H / 2) * 0.7 + (bp.y - H / 2) * 0.4
	return Vector2(abs_x(p.team, clamp(r, 3, W - 3)), clamp(y, 2, H - 2))

func assign_marks(ti: int) -> void:
	var defs: Array = active().filter(func(p): return p.team == ti and p.role != "gk")
	var atks: Array = active().filter(func(p): return p.team != ti and p.role != "gk")
	defs.sort_custom(func(a, b): return rel(ti, a.p.x) < rel(ti, b.p.x))
	var taken := {}
	for d in defs:
		var base := shape_target(d, false)
		var best: Pl = null
		var bd := 22.0
		for a in atks:
			if taken.has(a.id): continue
			var dd: float = a.p.distance_to(base)
			if dd < bd: bd = dd; best = a
		d.mark = best
		if best: taken[best.id] = true

# ---------- decisões com bola ----------
func on_ball(p: Pl, dt: float) -> void:
	var gx := opp_goal_x(p.team)
	var goal := Vector2(gx, H / 2)
	var act := active()
	var opps: Array = act.filter(func(q): return q.team != p.team)
	var mates: Array = act.filter(func(q): return q.team == p.team and q != p)
	var press: float = nearest(opps, p.p)[1]
	if p.cd > 0 and not (press < 1.25 and p.cd > 0.2):
		var dir := p.dribble if p.dribble != Vector2.ZERO else (goal - p.p).normalized()
		var sp := 0.0 if p.role == "gk" else p.spd * 0.8
		var tg := Vector2(clamp(p.p.x + dir.x * 3, 1.2, W - 1.2), clamp(p.p.y + dir.y * 3, 1.2, H - 1.2))
		move_to(p, tg, sp, dt)
		return
	p.cd = rand(0.45, 0.9)
	if p.penalty:
		p.penalty = false; shoot(p, true); return
	var to_goal := (goal - p.p).normalized()
	var choices: Array = []
	var dg := p.p.distance_to(goal)
	if dg < 28 and p.role != "gk" and not p.set_piece:
		var ang := absf(p.p.y - goal.y) / dg
		var blk := 0
		for q in opps:
			if q.role == "gk": continue
			var s := seg_dist(p.p, goal, q.p)
			if s.x < 1.1 and s.y < 0.95: blk += 1
		choices.append({"type": "shoot", "sc": (1 - dg / 28) * 1.8 - ang * 0.7 - blk * 0.3 + rand(0, 0.35) + (0.55 if in_own_box(1 - p.team, p.p) else 0.0)})
	var was_set := p.set_piece
	var wide := absf(p.p.y - H / 2) > 18 and rel(p.team, p.p.x) > W - 32
	for m in mates:
		var d: float = m.p.distance_to(p.p)
		if d < 4 or d > 50: continue
		if m.run > 0 and m.role != "gk":
			var tg := Vector2(clamp(m.p.x + m.v.x * 1.2, 2, W - 2), clamp(m.p.y + m.v.y * 1.2, 2, H - 2))
			var open_t := lane_open(p.p, tg, opps)
			if open_t > 1.2 and tg.distance_to(p.p) < 42:
				choices.append({"type": "through", "m": m, "tg": tg, "sc": 1.15 + clamp((open_t - 1.2) / 3, 0, 0.4) + rand(0, 0.35)})
		var open := lane_open(p.p, m.p, opps)
		var spc: float = nearest(opps, m.p)[1]
		var lofted := open < 1.5 or d > 26
		if lofted and (d < 16 or spc < 3): continue
		var open_k: float = clamp(0.5 - d / 100 + (spc - 3) * 0.05, 0.1, 0.55) if lofted else clamp((open - 1.0) / 2.2, 0, 1)
		if open_k < 0.12: continue
		var space: float = clamp(spc / 7, 0, 1)
		var prog := (rel(p.team, m.p.x) - rel(p.team, p.p.x)) / 24
		var sc := open_k * 0.6 + space * 0.45 + prog * 0.9 + rand(0, 0.3) - 0.25
		if m.role == "gk": sc -= 0.8
		if press < 2.6: sc += 0.45
		if p.role == "gk": sc += 0.6 - (0.0 if m.line == "d" else 0.3)
		if p.set_piece: sc += 1
		var cross: bool = wide and in_own_box(1 - p.team, m.p)
		if cross: sc += 0.5
		choices.append({"type": "pass", "m": m, "lofted": lofted or cross, "sc": sc})
	if p.role != "gk" and not p.set_piece:
		for k in range(-3, 4):
			var dir := to_goal.rotated(k * PI / 6)
			var a := p.p + dir * 4
			if a.x < 1.5 or a.x > W - 1.5 or a.y < 1.5 or a.y > H - 1.5: continue
			var pr := 0.0
			for q in opps: pr += max(0.0, 1 - q.p.distance_to(a) / 5)
			var sc: float = dir.x * dirs[p.team] * 0.65 + (1 - min(pr, 1.0)) * 0.75 + rand(0, 0.2) - (0.4 if press < 1.9 else 0.0) + (0.25 if press > 4 else 0.0)
			choices.append({"type": "dribble", "dir": dir, "sc": sc})
	p.set_piece = false
	if choices.is_empty(): choices.append({"type": "clear", "sc": 0.0})
	choices.sort_custom(func(a, b): return a.sc > b.sc)
	var c: Dictionary = choices[0]
	match c.type:
		"shoot": shoot(p, false)
		"pass":
			pass_to(p, c.m, c.lofted)
			if not was_set: offside_snap(p, c.m)
		"through":
			kick(p, c.tg, false); target = c.m
			offside_snap(p, c.m)
		"dribble": p.dribble = c.dir
		_:
			kick(p, Vector2(abs_x(p.team, rel(p.team, p.p.x) + 30), H / 2 + rand(-12, 12)), true)

func kick(p: Pl, tg: Vector2, lofted: bool) -> void:
	var d := bp.distance_to(tg)
	var n := (tg - bp).normalized()
	var sp: float
	var vz := 0.0
	if lofted:
		vz = clamp(3 + d * 0.16, 4, 9); var T := 2 * vz / G; sp = d / T * 0.92
	else: sp = clamp(6 + d * 0.72, 9, 26)
	owner = null; bv = n * sp; bvz = vz; bz = max(bz, 0.05); last = p.team; no_pick = p; no_pick_t = 0.3
	p.dribble = Vector2.ZERO

func pass_to(p: Pl, m: Pl, lofted: bool) -> void:
	var d := m.p.distance_to(p.p)
	var lead := 0.8 if lofted else d / 16
	var err := Vector2(rand(-1, 1), rand(-1, 1)) * d * 0.03
	kick(p, m.p + m.v * lead + err, lofted)
	target = m

func shoot(p: Pl, pen: bool) -> void:
	var gx: float = opp_goal_x(p.team) + dirs[p.team] * 1.0
	var gy := H / 2 + (-1.0 if rng.randf() < 0.5 else 1.0) * rand(0.3, 1) * GOAL_W * (0.45 if pen else 0.62)
	var n := (Vector2(gx, gy) - bp).normalized()
	var sp := 22.0 if pen else rand(19, 26)
	owner = null; bv = n * sp; bvz = rand(0, 2.5) if pen else rand(0, 4.2); bz = 0.1; last = p.team
	no_pick = p; no_pick_t = 0.4; target = null; bpen = pen
	p.dribble = Vector2.ZERO

# ---------- IA por passo ----------
func ai_step(dt: float) -> void:
	var act := active()
	var owner_team := owner.team if owner else -1
	var poss_team := owner_team if owner_team >= 0 else (target.team if target else -1)
	mark_t -= dt
	if mark_t <= 0:
		mark_t = 0.5; assign_marks(0); assign_marks(1)
	var chasers: Array = []
	for ti in 2:
		if owner_team == ti: continue
		if owner == null and target and target.team == ti and target.down <= 0 and not target.off:
			chasers.append(target); continue
		var field: Array = act.filter(func(p): return p.team == ti and p.role != "gk" and p.down <= 0)
		var c: Pl = nearest(field, bp + bv * 0.35)[0]
		if c: chasers.append(c)
	for p in act:
		p.cd -= dt; p.tackle_cd -= dt; p.run -= dt
		if rng.randf() < dt * 0.4: p.line_off = rand(-2.8, 0.9)
		if p.line == "f" and poss_team == p.team and p.run <= -1 and owner and owner != p and rng.randf() < dt * 0.35: p.run = rand(1.4, 2.2)
		if p.down > 0:
			p.down -= dt; p.v *= 0.9; continue
		if owner == p:
			if p.role == "gk": p.v *= 0.8
			on_ball(p, dt); continue
		if p in chasers: continue
		if p.role == "gk":
			var own := own_goal_x(p.team)
			var dist := absf(bp.x - own)
			var gy: float = clamp(H / 2 + (bp.y - H / 2) * 0.35, H / 2 - GOAL_W / 2 + 0.4, H / 2 + GOAL_W / 2 - 0.4)
			var out := 1.2 + (16 - dist) * 0.08 if dist < 16 else 3.5
			move_to(p, Vector2(own + dirs[p.team] * out, gy), 5.5, dt)
			continue
		var poss: bool = poss_team == p.team
		var tg := shape_target(p, poss)
		if not poss and p.mark and not p.mark.off:
			var m: Pl = p.mark
			var n := (Vector2(own_goal_x(p.team), H / 2) - m.p).normalized()
			var mm := m.p + n * 1.8
			if p.line == "d":
				tg = Vector2(tg.x, lerp(tg.y, mm.y, 0.5))
				if rel(p.team, m.p.x) < rel(p.team, tg.x) - 3: tg.x = lerp(tg.x, mm.x, 0.7)
			elif mm.distance_to(tg) < 18: tg = tg.lerp(mm, 0.6)
		var urgent := tg.distance_to(p.p) > 6
		move_to(p, tg, p.spd * (0.95 if urgent else 0.65), dt)
	for c in chasers:
		var q := bp + bv * 0.35
		if owner == null and target == c:
			var n := bv.normalized()
			var along: float = max(0.0, (c.p - bp).dot(n))
			q = bp + n * along * 0.8
		if owner: q = owner.p + owner.v * 0.3
		move_to(c, q, c.spd, dt)
		if owner and owner.team != c.team and owner.role != "gk":
			if c.p.distance_to(owner.p) < 1.9 and c.tackle_cd <= 0:
				tackle(c, owner)
				if not lance.is_empty(): return

func tackle(def: Pl, att: Pl) -> void:
	def.tackle_cd = rand(0.7, 1.3)
	if rng.randf() > 0.55: return                                        # não chega à bola
	var ag: float = aggr[def.team]
	if lance_cd <= 0 and rng.randf() < 0.3 + ag * 0.4:
		start_lance(att, def); return
	owner = def; last = def.team; target = null; def.cd = 0.3; att.down = 0.35; def.dribble = Vector2.ZERO

# ---------- física ----------
func physics(dt: float) -> void:
	var act := active()
	for p in act: p.p += p.v * dt
	for i in act.size():
		for j in range(i + 1, act.size()):
			var a: Pl = act[i]; var c: Pl = act[j]
			var d := c.p - a.p
			var dl := d.length()
			if dl < 1.6 and dl > 0.001:
				var push := (1.6 - dl) / 2
				var n := d / dl
				a.p -= n * push; c.p += n * push
	for p in act: p.p = Vector2(clamp(p.p.x, -1.5, W + 1.5), clamp(p.p.y, -1.5, H + 1.5))
	if owner:
		var o := owner
		var n := o.v.normalized() if o.v.length() > 0.4 else (Vector2(opp_goal_x(o.team), H / 2) - o.p).normalized()
		bp = o.p + n * 1.0; bz = 0; bv = o.v; bvz = 0; off_info = {}
		return
	if dt <= 0: return
	bp += bv * dt
	if bz > 0 or bvz > 0:
		bz += bvz * dt; bvz -= G * dt
		if bz <= 0:
			bz = 0; bvz = -bvz * 0.45 if absf(bvz) > 1.5 else 0.0
	bv *= exp((-0.15 if bz > 0.05 else -0.7) * dt)
	var sp := bv.length()
	if no_pick_t > 0: no_pick_t -= dt
	else: no_pick = null
	if bp.y < 0 or bp.y > H:
		throw_in(); return
	if bp.x < 0 or bp.x > W:
		var side := 0 if own_goal_x(0) == (0.0 if bp.x < 0 else W) else 1   # equipa que defende esta baliza
		if absf(bp.y - H / 2) < GOAL_W / 2 and bz < 2.4:
			goal_award(1 - side); return
		if last == side: corner(1 - side, 0.5 if bp.y < H / 2 else H - 0.5)
		else: goal_kick(side)
		return
	var best: Pl = null
	var bd := 1e9
	for p in act:
		if p == no_pick or p.down > 0: continue
		var d: float = p.p.distance_to(bp)
		var gk: bool = p.role == "gk" and in_own_box(p.team, p.p)
		var reach := 1.9 if gk else ((0.8 if sp > 17 else 1.3) if p.team == last else (0.5 if sp > 17 else (0.7 if sp > 9 else 1.1)))
		var z_ok := bz < 2.6 if gk else bz < 1.5
		if z_ok and d < reach and d < bd: bd = d; best = p
	if best == null: return
	var oi := off_info
	off_info = {}
	if not oi.is_empty() and best.id == oi.receiver and oi.margin > -1.0:
		if _assistant_call(oi):
			flag_offside(oi); return
	if best.role == "gk" and sp > 12 and last != best.team:
		var save_p: float = 0.28 if bpen else clamp(0.95 - (sp - 12) * 0.03, 0.5, 0.93)
		if rng.randf() > save_p:
			no_pick = best; no_pick_t = 0.5; return
		if sp > 20 and rng.randf() < 0.45:
			var n := Vector2(-bv.x * 0.3, (-1.0 if rng.randf() < 0.5 else 1.0) * 8).normalized()
			bv = n * 9 + Vector2(dirs[best.team] * 3, 0); bvz = 2; no_pick = best; no_pick_t = 0.4; last = best.team; bpen = false
			msg("Defesa do guarda-redes", 1.2)
			return
	owner = best; last = best.team; target = null; bpen = false
	best.cd = rand(0.9, 1.4) if best.role == "gk" else rand(0.7, 1.4); best.dribble = Vector2.ZERO

func _restart_ball(at: Vector2) -> void:
	bp = at; bv = Vector2.ZERO; bz = 0; bvz = 0; target = null; off_info = {}

func throw_in() -> void:
	var team := 1 - last
	var at := Vector2(clamp(bp.x, 1, W - 1), -0.4 if bp.y < 0 else H + 0.4)
	var p: Pl = nearest(active().filter(func(q): return q.team == team and q.role != "gk"), at)[0]
	_restart_ball(at)
	if p:
		p.p = at; p.v = Vector2.ZERO; owner = p; p.cd = 0.7; p.set_piece = true; last = team
	pause = 0.7

func goal_kick(side: int) -> void:
	var gk: Pl = null
	for p in active():
		if p.team == side and p.role == "gk": gk = p
	_restart_ball(Vector2(own_goal_x(side) + dirs[side] * 4.0, H / 2))
	if gk:
		gk.p = Vector2(own_goal_x(side) + dirs[side] * 3.0, H / 2); owner = gk; gk.cd = 1.2; gk.set_piece = true; last = side
	pause = 0.9

func corner(team: int, y: float) -> void:
	var x := W - 0.5 if dirs[team] > 0 else 0.5
	var p: Pl = nearest(active().filter(func(q): return q.team == team and q.role != "gk"), Vector2(x, y))[0]
	_restart_ball(Vector2(x, y))
	if p:
		p.p = Vector2(x + (-0.6 if x < 1 else 0.6), y); owner = p; p.cd = 1.1; p.set_piece = true; last = team
	msg("Canto para " + ART[team], 1.4)
	pause = 1.1

func goal_award(team: int) -> void:
	score[team] += 1
	msg("Golo " + DE[team] + "!", 2.2)
	kickoff(1 - team)
	pause = 2.2

# ---------- fora de jogo (os assistentes levantam a bandeira) ----------
func offside_snap(p: Pl, m: Pl) -> void:
	var ti := p.team
	var opps: Array = active().filter(func(q): return q.team != ti)
	opps.sort_custom(func(a, c): return rel(ti, a.p.x) > rel(ti, c.p.x))
	var line_def: Pl = opps[1] if opps.size() > 1 else (opps[0] if opps.size() else null)
	var line_rel: float = max(rel(ti, line_def.p.x) if line_def else W, W / 2)
	var line_x: float = max(line_rel, rel(ti, bp.x))
	var a: Vector2 = ast[1 if dirs[ti] > 0 else 0]
	off_info = {"receiver": m.id, "team": ti, "margin": rel(ti, m.p.x) - line_x, "line_x": abs_x(ti, line_x), "recv": m.p, "ast_x": a.x}

func _assistant_call(oi: Dictionary) -> bool:
	var mis: float = absf(oi.ast_x - oi.line_x)
	var acc: float = clamp((0.92 if absf(oi.margin) > 0.5 else 0.7) - min(0.3, mis * 0.05), 0.5, 0.95)
	var truth: bool = oi.margin > 0
	return truth if rng.randf() < acc else not truth

func flag_offside(oi: Dictionary) -> void:
	var def_t: int = 1 - oi.team
	ast_flag[1 if dirs[oi.team] > 0 else 0] = 1.8
	var at := Vector2(clamp(oi.recv.x, 1, W - 1), clamp(oi.recv.y, 1, H - 1))
	var p: Pl = nearest(active().filter(func(q): return q.team == def_t and q.role != "gk"), at)[0]
	_restart_ball(at)
	if p:
		p.p = at - Vector2(dirs[def_t] * 0.8, 0); owner = p; last = def_t; p.cd = 0.9; p.set_piece = true
	offsides += 1
	msg("Fora de jogo: bandeira do assistente", 1.8)
	pause = 1.2

func ast_step(dt: float) -> void:
	for i in 2:
		var att_t := 1 if i == 0 else 0
		var line_x := abs_x(att_t, offside_line(att_t))
		# o assistente de cima acompanha quem ataca para a esquerda
		if dirs[0] < 0: att_t = 1 - att_t; line_x = abs_x(att_t, offside_line(att_t))
		var tx: float = minf(line_x, bp.x) if i == 0 else maxf(line_x, bp.x)
		tx = clamp(tx, 0.5, W / 2) if i == 0 else clamp(tx, W / 2, W - 0.5)
		ast[i].x += clamp((tx - ast[i].x) * 3, -7.5, 7.5) * dt
		if ast_flag[i] > 0: ast_flag[i] -= dt

# ---------- árbitro ----------
func ref_step(dt: float) -> void:
	var d := move_in
	if d != Vector2.ZERO: ref_target = null
	elif ref_target != null:
		d = ref_target - ref
		if d.length() < 0.3:
			ref_target = null; d = Vector2.ZERO
	var moving := d != Vector2.ZERO
	var run := sprint and stamina > 1 and moving
	var speed := 8.6 if run else 6.0
	if moving: ref += d.normalized() * speed * dt
	ref = Vector2(clamp(ref.x, -2, W + 2), clamp(ref.y, -2, H + 2))
	stamina = clamp(stamina + (-16.0 if run else (3.0 if moving else 7.0)) * dt, 0, 100)

# ---------- passo ----------
func step(dt: float) -> void:
	if over or not lance.is_empty(): return
	ref_step(dt)
	ast_step(dt)
	if pause > 0:
		pause -= dt; return
	t += dt
	lance_cd -= dt
	if half == 0 and t >= MATCH_SECONDS / 2:
		half = 1
		dirs = [-1, 1]
		msg("Intervalo: as equipas trocam de campo", 2.6)
		kickoff(1)
		pause = 2.6
		return
	if t >= MATCH_SECONDS:
		over = true
		msg("Apito final", 3.0)
		return
	ai_step(dt)
	if not lance.is_empty(): return
	physics(dt)

# ---------- lance ----------
func start_lance(att: Pl, def: Pl) -> void:
	lance_cd = rand(11, 16)
	var ag: float = aggr[def.team]
	var wts := {"siga": 0.24, "falta": 0.34, "amarelo": 0.2 * (1 + ag * 2), "vermelho": 0.06 * (1 + ag * 3), "simulacao": 0.16}
	var tot := 0.0
	for k in wts: tot += wts[k]
	var r := rng.randf() * tot
	var truth := "siga"
	for k in wts:
		r -= wts[k]
		if r <= 0: truth = k; break
	var to_goal := (Vector2(opp_goal_x(att.team), H / 2) - att.p).normalized()
	var mv := att.v.normalized() if att.v.length() > 0.5 else to_goal
	var A := (mv * 0.7 + to_goal * 0.3).normalized()
	var side := 1.0 if A.x * (def.p.y - att.p.y) - A.y * (def.p.x - att.p.x) > 0 else -1.0
	var P := att.p
	var dist := P.distance_to(ref)
	var view := (P - ref).normalized()
	var others: Array = []
	var blockers := 0
	for o in active():
		if o == att or o == def: continue
		if o.p.distance_to(P) < 14: others.append({"team": o.team, "num": o.num, "p": o.p})
		var rp: Vector2 = o.p - ref
		var proj := rp.dot(view)
		if proj > 0.6 and proj < dist - 1 and absf(rp.cross(view)) < 0.85: blockers += 1
	others.sort_custom(func(a, b): return a.p.distance_to(P) < b.p.distance_to(P))
	var dist_score: float = clamp(1 - (dist - 8) / 28, 0.1, 1)
	lance = {"truth": truth, "P": P, "A": A, "side": side, "ref": ref, "dist": dist, "dist_score": dist_score, "blockers": blockers,
		"clarity": clamp(dist_score * (1 - 0.3 * blockers), 0.05, 1), "minute": minute(), "in_box": in_own_box(def.team, P),
		"att": att, "def": def, "att_team": att.team, "def_team": def.team, "att_num": att.num, "def_num": def.num, "others": others.slice(0, 4)}
	att.v = Vector2.ZERO; def.v = Vector2.ZERO
	for p in players: p.v *= 0.2
	if on_lance.is_valid(): on_lance.call(lance)

# devolve a mensagem do que acontece a seguir; pontua a decisão (1 certa, 0,4 perto, 0 errada)
func decide(d: String, timed_out := false) -> Dictionary:
	var L := lance
	var pts := 0.0
	var dc := 0.0
	var att: Pl = L.att
	var def: Pl = L.def
	var truth: String = L.truth
	if truth == "simulacao":
		if d == "simulacao": pts = 1; dc = 4
		elif d == "siga": pts = 0.4; dc = -3
		else: pts = 0; dc = -10; aggr[def.team] += 0.25
	elif d == "simulacao":
		pts = 0; dc = -11; aggr[att.team] += 0.3
	else:
		var diff: int = SEV[d] - SEV[truth]
		if diff == 0: pts = 1; dc = 4
		elif absi(diff) == 1: pts = 0.4; dc = -5
		else: pts = 0; dc = -12
		if diff < 0: aggr[att.team] += 0.12 * -diff
		if diff > 0: aggr[def.team] += 0.12 * diff
	if timed_out: dc -= 4
	control = clamp(control + dc, 0, 100)
	L.decided = d; L.pts = pts; L.timed_out = timed_out
	incidents.append(L)
	dist_sum += L.dist
	var m := ""
	var foul := d == "falta" or d == "amarelo" or d == "vermelho"
	if foul:
		def.fouls += 1
		if d == "amarelo":
			def.yellow += 1
			m = "Amarelo ao %d %s" % [def.num, DE[def.team]]
			if def.yellow >= 2:
				def.off = true; m = "Segundo amarelo: %d %s expulso" % [def.num, DE[def.team]]
		elif d == "vermelho":
			def.off = true; m = "Vermelho direto ao %d %s" % [def.num, DE[def.team]]
		if L.in_box:
			penalty(att)
			m = (m + " · " if m != "" else "") + "Penálti para " + ART[att.team]
		else:
			owner = att; last = att.team; att.cd = 0.9; att.set_piece = true; target = null
			for p in active():
				if p.team != att.team and p.p.distance_to(att.p) < 6:
					p.p = att.p + (p.p - att.p).normalized() * 6
			if m == "": m = "Livre para " + ART[att.team]
	elif d == "simulacao":
		att.yellow += 1; owner = def; last = def.team; def.cd = 0.8; target = null
		m = "Amarelo por simulação ao %d %s" % [att.num, DE[att.team]]
		if att.yellow >= 2:
			att.off = true; m = "Segundo amarelo: %d %s expulso" % [att.num, DE[att.team]]
	else:
		owner = def; last = def.team; def.cd = 0.5; target = null; att.down = 1.2
		m = "Hesitaste: o jogo seguiu" if timed_out else "Siga o jogo"
	if owner and owner.off:
		owner = nearest(active().filter(func(q): return q.team == owner.team), bp)[0]
	lance = {}
	pause = max(pause, 1.2)
	if control <= 10:
		over = true; m += " · Perdeste o controlo do jogo: partida interrompida"
	return {"msg": m, "pts": pts, "truth": truth, "ok": pts >= 1.0}

func penalty(att: Pl) -> void:
	var team := att.team
	var dir: int = dirs[team]
	var spot_x := opp_goal_x(team) - dir * SPOT
	var taker := att
	if att.off:
		for p in active():
			if p.team == team and p.role != "gk": taker = p; break
	for p in active():
		if p.role == "gk" and p.team != team:
			p.p = Vector2(opp_goal_x(team) - dir * 0.6, H / 2); continue
		if p == taker: continue
		if in_own_box(1 - team, p.p) or p.p.distance_to(Vector2(spot_x, H / 2)) < 9:
			p.p = Vector2(opp_goal_x(team) - dir * (BOX_D + rand(1, 4)), H / 2 + rand(-10, 10))
	taker.p = Vector2(spot_x - dir * 1.2, H / 2); taker.v = Vector2.ZERO
	_restart_ball(Vector2(spot_x, H / 2))
	owner = taker; last = team; taker.cd = 1.8; taker.penalty = true
	pause = 1.8

func grade() -> float:
	if incidents.is_empty(): return 0.0
	var s := 0.0
	for L in incidents: s += L.pts
	return s / incidents.size() * 10.0
