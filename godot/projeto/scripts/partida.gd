class_name Partida
extends RefCounted
# O jogo de caricas (vista de cima) com toda a lógica da versão browser (game.js):
# 22 jogadores em 4-3-3 com qualidade e manias, foras de jogo, lances de todos os tipos,
# VAR, protestos, público, nervos, capitães, banco, vantagem, livres diretos, antijogo,
# descontos, intervalo, critério do árbitro, relato e rádio.
# A interface (main.gd, ui.gd) recebe eventos por `ev` e responde com decide(), ask_pick(), etc.

const W := 105.0
const H := 68.0
const GOAL_W := 7.32
const BOX_D := 16.5
const BOX_W := 40.3
const SPOT := 11.0
const G := 9.8
const MATCH_SECONDS := 270.0       # 90 minutos de jogo; com as caricas a 1,5x são 3 minutos reais
const HOME := 0                    # a equipa da casa
const LINE_IN := 0.17              # centro da bola a 17 cm da linha: passou toda
const ROLES := [
	["gk", 34.0, "g", 1], ["lb", 9.0, "d", 3], ["lcb", 26.0, "d", 4], ["rcb", 42.0, "d", 5], ["rb", 59.0, "d", 2],
	["lcm", 21.0, "m", 8], ["cm", 34.0, "m", 6], ["rcm", 47.0, "m", 10], ["lw", 8.0, "f", 11], ["st", 34.0, "f", 9], ["rw", 60.0, "f", 7],
]
const LABEL := {"siga": "Lance limpo", "falta": "Falta", "amarelo": "Falta para amarelo", "vermelho": "Falta para vermelho", "simulacao": "Simulação",
	"fora": "Fora de jogo", "emjogo": "Em jogo", "mao": "Mão na bola", "maoAmarelo": "Mão na bola para amarelo", "penalti": "Falta do defesa",
	"ataque": "Falta do atacante", "vantagem": "Vantagem", "valido": "Golo limpo", "anular": "Falta do atacante antes do golo",
	"entrou": "A bola entrou toda", "naoEntrou": "A bola não entrou toda"}
const DEC_LABEL := {"siga": "Siga", "falta": "Falta", "amarelo": "Amarelo", "vermelho": "Vermelho", "simulacao": "Simulação", "fora": "Fora de jogo",
	"emjogo": "Em jogo", "mao": "Mão", "maoAmarelo": "Mão + amarelo", "penalti": "Penálti", "ataque": "Falta atacante", "vantagem": "Vantagem",
	"nenhum": "Sem cartão", "valido": "Golo válido", "anular": "Golo anulado", "entrou": "Golo", "naoEntrou": "Não entrou"}
const SEV := {"siga": 0, "falta": 1, "amarelo": 2, "vermelho": 3}
const WHY := {"reiterada": "faltas repetidas", "tatica": "falta tática"}
# decisões possíveis por tipo de lance (teclas 1..6)
const KEYS := {
	"foul": ["siga", "falta", "amarelo", "vermelho", "simulacao", "vantagem"],
	"offside": ["emjogo", "fora"],
	"mao": ["siga", "mao", "maoAmarelo"],
	"canto": ["siga", "penalti", "ataque"],
	"golo": ["valido", "anular"],
	"linha": ["entrou", "naoEntrou"],
	"aereo": ["siga", "falta", "amarelo", "vermelho"],
	"agarrao": ["siga", "falta", "amarelo", "vermelho"],
	"pisao": ["siga", "falta", "amarelo", "vermelho"],
}
const PAIR_UP := {"falta": "amarelo", "amarelo": "vermelho"}
const PAIR_DN := {"amarelo": "falta", "vermelho": "amarelo"}
const ROLE_PT := {"gk": "Guarda-redes", "lb": "Lateral esquerdo", "rb": "Lateral direito", "lcb": "Central", "rcb": "Central", "cm": "Médio", "lcm": "Médio", "rcm": "Médio", "lw": "Extremo esquerdo", "rw": "Extremo direito", "st": "Avançado"}

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
	# qualidade (à Football Manager) e manias
	var name := ""
	var short := ""
	var ovr := 70.0
	var rel := 70.0
	var tr: Array = []
	var pac := 70.0
	var pas := 70.0
	var fin := 70.0
	var tck := 70.0
	var drb := 70.0
	var foul_k := 1.0
	var hard_k := 1.0
	var sim_k := 1.0
	var reserve := false
	var banned := ""
	var grudge := false

var ev: Callable                  # ev.call(nome, dados)
var teams: Array = []             # [{name, art, color, dark, sock, shorts, gk, dir, rating, text, pat, shirt2}]
var players: Array = []
var mode := "play"                # play | lance | pergunta | protesto | gesto | intervalo | fim
var t := 0.0
var score := [0, 0]
var control := 70.0
var stamina := 100.0
var aggr := [0.1, 0.1]
var crowd := 35.0
var crowd_base := 35.0
var stress := 15.0
var stress_base := 15.0
var cap_trust := [0.5, 0.5]
# bola
var bp := Vector2(W / 2, H / 2)
var bv := Vector2.ZERO
var bz := 0.0
var bvz := 0.0
var owner: Pl = null
var last := 0
var kicker: Pl = null
var shot_from = null
var no_pick: Pl = null
var no_pick_t := 0.0
var target: Pl = null
var bpen := false
var off_info := {}
var trail: Array = []
# árbitro e assistentes
var ref := Vector2(W / 2, H / 2 + 7)
var ref_target = null
var move_in := Vector2.ZERO
var sprint := false
var ast := [Vector2(W / 4, -1.6), Vector2(W * 3 / 4, H + 1.6)]
var ast_flag := [0.0, 0.0]
# estado do jogo
var pause := 0.0
var lance_cd := 10.0
var mark_t := 0.0
var incidents: Array = []
var lance: Dictionary = {}
var half := 0
var over := ""
var offsides := 0
var protest: Dictionary = {}
var protests: Array = []
var var_n := 0
var manage: Array = []
var crit: Array = []
var crit_flips := 0
var fk: Dictionary = {}
var coach: Dictionary = {}
var coach_w := [0, 0]
var coach_off := [false, false]
var coach_n := 0
var last_off: Dictionary = {}
var anulados := 0
var added := 0.0
var add_min := 0
var stall: Dictionary = {}
var stall_n := 0
var warned := [false, false]
var pend_card: Dictionary = {}
var ask: Dictionary = {}
var feed_list: Array = []
var pending_after: Callable
var half_talk := ""
var ast_boost := false
var paper: Dictionary = {}
# modos especiais
var career: Dictionary = {}       # {tier, round, attrs, wrong, h, a} quando é jogo da carreira
var no_var := false
var lance_k := 1.0
var sim_k := 1.0
var training: Dictionary = {}     # treino do VAR
var tut := false                  # primeiro jogo guiado
var tut_done := false
var force_w: Dictionary = {}
var timers: Array = []
var rng := RandomNumberGenerator.new()

func _init(tms: Array) -> void:
	rng.randomize()
	teams = tms
	teams[0].dir = 1; teams[1].dir = -1
	for ti in 2:
		for i in ROLES.size():
			var r: Array = ROLES[i]
			var p := Pl.new()
			p.id = ti * ROLES.size() + i; p.team = ti; p.role = r[0]; p.lane = r[1]; p.line = r[2]; p.num = r[3]
			p.spd = rng.randf_range(6.3, 7.3)
			players.append(p)
	squad_setup()
	kickoff(0)

# ---------- utilitários ----------
func rand(a: float, b: float) -> float: return rng.randf_range(a, b)
func pick(a: Array): return a[rng.randi() % a.size()]
func dirs(ti: int) -> int: return teams[ti].dir
func rel(ti: int, x: float) -> float: return x if dirs(ti) > 0 else W - x
func abs_x(ti: int, r: float) -> float: return r if dirs(ti) > 0 else W - r
func own_goal_x(ti: int) -> float: return 0.0 if dirs(ti) > 0 else W
func opp_goal_x(ti: int) -> float: return W if dirs(ti) > 0 else 0.0
func in_own_box(ti: int, q: Vector2) -> bool: return rel(ti, q.x) < BOX_D and absf(q.y - H / 2) < BOX_W / 2
func active() -> Array: return players.filter(func(p): return not p.off)
func minute() -> int: return mini(90, int(t / MATCH_SECONDS * 90.0) + 1)
func clock_txt() -> String:
	if t <= MATCH_SECONDS: return "%d'" % int(t / MATCH_SECONDS * 90.0)
	return "90+%d'" % int(ceil((t - MATCH_SECONDS) / MATCH_SECONDS * 90.0))
func art_t(i: int) -> String: return str(teams[i].get("art", "os")) + " " + str(teams[i].name)
func de_t(i: int) -> String: return "d" + art_t(i)
func f1(x: float) -> String: return ("%.1f" % x).replace(".", ",")
func p_name(p: Pl) -> String:
	if p == null: return ""
	return (p.short + " (%d)" % p.num) if p.short != "" else "o %d" % p.num
func who(num: int, team: int) -> String:
	for q in players:
		if q.team == team and q.num == num and q.short != "": return q.short + " (%d) " % num + de_t(team)
	return "o %d " % num + de_t(team)
func emit(nm: String, d := {}) -> void:
	if ev.is_valid(): ev.call(nm, d)
func toast(s: String, secs := 2.0) -> void: emit("toast", {"txt": s, "secs": secs})
func sfx(k: String, a = null) -> void: emit("sfx", {"k": k, "a": a})
func radio(w: String, txt: String, voz := "") -> void:
	if training.is_empty(): emit("radio", {"who": w, "txt": txt, "voz": voz if voz != "" else txt})
func later(secs: float, f: Callable) -> void: timers.append([secs, f])
func pinfo(p: Pl) -> Dictionary: return {"id": p.id, "team": p.team, "num": p.num, "role": p.role}
func snap_of(p: Pl) -> Dictionary: return {"id": p.id, "team": p.team, "role": p.role, "num": p.num, "p": p.p, "v": p.v}
func pick_truth(w: Dictionary) -> String:
	var tot := 0.0
	for k in w: tot += float(w[k])
	var r := rng.randf() * tot
	for k in w:
		r -= float(w[k])
		if r <= 0: return k
	return w.keys()[0]
func ref_attr(k: String) -> float: return float(career.attrs[k]) if not career.is_empty() else 5.0
func auth_k() -> float: return 1.1 - ref_attr("aut") * 0.02
func decision_time() -> float:
	var c := ref_attr("calma")
	var tier: float = float(career.tier) if not career.is_empty() else 0.0
	return maxf(7.0, round(15 - crowd / 25 * (1.4 - 0.08 * c) + (c - 5) * 0.4 - stress / 25 - tier * 0.5))
func add_stress(v: float) -> void:
	if not training.is_empty(): return
	if v > 0: v *= 1.25 - 0.05 * ref_attr("calma")
	stress = clamp(stress + v, 0, 100)
func ctrl(dc: float) -> void:
	if dc < 0: dc *= auth_k()
	control = clamp(control + dc, 0, 100)

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

# ---------- plantéis: cada carica recebe o seu jogador ----------
func squad_setup() -> void:
	var base: float = (float(teams[0].get("rating", 70)) + float(teams[1].get("rating", 70))) / 2.0
	for ti in 2:
		var tm: Dictionary = teams[ti]
		var sq: Array = Carreira.squad_for(tm.name, float(tm.get("rating", 70)))
		var list: Array = players.filter(func(q): return q.team == ti)
		for i in list.size():
			var p: Pl = list[i]
			var q: Dictionary = sq[i]
			var r := Carreira.Seeded.new(Carreira.hash_s(tm.name) + p.num * 97)
			p.name = q.name; p.short = q.short; p.ovr = q.ovr; p.rel = q.ovr - base + 72; p.tr = q.tr
			var vf := func(k: float) -> float: return clamp(q.ovr - base + 72 + (r.next() - 0.5) * 16 + k, 30, 99)
			p.pac = vf.call(5.0 if p.line == "f" else 0.0); p.pas = vf.call(5.0 if p.line == "m" else 0.0)
			p.fin = vf.call(6.0 if p.line == "f" else -8.0); p.tck = vf.call(6.0 if p.line == "d" else -6.0); p.drb = vf.call(4.0 if p.line == "f" else 0.0)
			p.spd = 5.7 + p.pac / 100.0 * 2.1
			p.foul_k = 1.6 if "duro" in p.tr else 1.0
			p.hard_k = 1.7 if "duro" in p.tr else 1.0
			p.sim_k = 2.6 if "simulador" in p.tr else 1.0
func pass_err(p: Pl, d: float) -> Vector2:
	var e := (100 - p.pas) / 100.0 * d * 0.11
	return Vector2(rand(-1, 1), rand(-1, 1)) * e
func shot_spread(p: Pl) -> float: return 0.5 + (100 - p.fin) / 100.0 * 0.45
func tackle_p(d: Pl, a: Pl) -> float: return clamp(0.5 + (d.tck - a.drb) / 160.0, 0.25, 0.75)
func gk_bonus(gk: Pl) -> float: return (gk.rel - 70) * 0.004

func formation_pos(p: Pl) -> Vector2:
	var r := 4.0 if p.line == "g" else (20.0 if p.line == "d" else (36.0 if p.line == "m" else 48.0))
	return Vector2(abs_x(p.team, r), p.lane)

func reset_ball(at: Vector2) -> void:
	bp = at; bv = Vector2.ZERO; bz = 0; bvz = 0; target = null; off_info = {}; trail = []; bpen = false

func kickoff(team: int) -> void:
	for p in players:
		p.p = formation_pos(p); p.v = Vector2.ZERO; p.down = 0; p.set_piece = false; p.penalty = false; p.run = 0
	reset_ball(Vector2(W / 2, H / 2))
	var taker: Pl = null
	for p in active():
		if p.team == team and p.role == "st": taker = p
	if taker == null:
		for p in active():
			if p.team == team and p.role != "gk": taker = p; break
	taker.p = Vector2(W / 2 - dirs(team) * 1.1, H / 2)
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
		choices.append({"type": "pass", "m": m, "lofted": lofted or cross, "cross": cross, "sc": sc})
	if p.role != "gk" and not p.set_piece:
		for k in range(-3, 4):
			var dir := to_goal.rotated(k * PI / 6)
			var a := p.p + dir * 4
			if a.x < 1.5 or a.x > W - 1.5 or a.y < 1.5 or a.y > H - 1.5: continue
			var pr := 0.0
			for q in opps: pr += max(0.0, 1 - q.p.distance_to(a) / 5)
			var sc: float = dir.x * dirs(p.team) * 0.65 + (1 - min(pr, 1.0)) * 0.75 + rand(0, 0.2) - (0.4 if press < 1.9 else 0.0) + (0.25 if press > 4 else 0.0)
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
			if c.cross and not was_set: corner_check(p.team, p, true)
			elif c.lofted and not was_set: aerial_check(p, c.m)
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
	owner = null; kicker = p; bv = n * sp; bvz = vz; bz = max(bz, 0.05); last = p.team; no_pick = p; no_pick_t = 0.3
	if mode == "play": sfx("kick", clamp(1 - bp.distance_to(ref) / 45, 0, 1) * (0.9 if lofted else 0.6))
	p.dribble = Vector2.ZERO

func pass_to(p: Pl, m: Pl, lofted: bool) -> void:
	var d := m.p.distance_to(p.p)
	var lead := 0.8 if lofted else d / 16
	kick(p, m.p + m.v * lead + pass_err(p, d), lofted)
	target = m

func shoot(p: Pl, pen: bool) -> void:
	var gx: float = opp_goal_x(p.team) + dirs(p.team) * 1.0
	var gy := H / 2 + (-1.0 if rng.randf() < 0.5 else 1.0) * rand(0.3, 1) * GOAL_W * (0.45 if pen else shot_spread(p))
	var n := (Vector2(gx, gy) - bp).normalized()
	var sp := 22.0 if pen else rand(19, 26) + (p.fin - 70) * 0.05
	owner = null; kicker = p; shot_from = p.p; bv = n * sp; bvz = rand(0, 2.5) if pen else rand(0, 4.2); bz = 0.1; last = p.team
	no_pick = p; no_pick_t = 0.4; target = null; bpen = pen
	if mode == "play":
		sfx("kick", clamp(1.2 - bp.distance_to(ref) / 45, 0.2, 1)); sfx("react", 0.35)
		later(0.7, func(): if owner == null and mode == "play": sfx("ooh"))
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
		if owner == p and (gk_chance(p, dt) or gk_out_check(p, dt)): return
		if owner == p:
			if p.role == "gk": p.v *= 0.8
			on_ball(p, dt)
			if mode != "play": return
			continue
		if p in chasers: continue
		if p.role == "gk":
			var own := own_goal_x(p.team)
			var dist := absf(bp.x - own)
			var gy: float = clamp(H / 2 + (bp.y - H / 2) * 0.35, H / 2 - GOAL_W / 2 + 0.4, H / 2 + GOAL_W / 2 - 0.4)
			var out := 1.2 + (16 - dist) * 0.08 if dist < 16 else 3.5
			move_to(p, Vector2(own + dirs(p.team) * out, gy), 5.5, dt)
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
				if mode != "play": return

func tackle(def: Pl, att: Pl) -> void:
	def.tackle_cd = rand(0.7, 1.3)
	if rng.randf() > tackle_p(def, att): return                         # não chega à bola
	var ag: float = aggr[def.team]
	if lance_cd <= 0 and (light_check(att, def) or stamp_check(att, def) or grab_check(att, def)): return
	if lance_cd <= 0 and rng.randf() < (0.3 + ag * 0.4) * def.foul_k:
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
	if sp > 6:
		trail.append(bp)
		if trail.size() > 10: trail.pop_front()
	elif not trail.is_empty(): trail.pop_front()
	if no_pick_t > 0: no_pick_t -= dt
	else: no_pick = null
	if bp.y < 0 or bp.y > H:
		throw_in(); return
	if bp.x < 0 or bp.x > W:
		var side := 0 if own_goal_x(0) == (0.0 if bp.x < 0 else W) else 1   # equipa que defende esta baliza
		if absf(bp.y - H / 2) < GOAL_W / 2 and bz < 2.4:
			goal(1 - side); return
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
	if not oi.is_empty() and best.id == oi.receiver and oi.margin > -1.8 and oi.margin <= 1.2 and not best.off:
		last_off = {"oi": oi, "t": t, "n": incidents.size(), "o": offsides}
	if not oi.is_empty() and best.id == oi.receiver and oi.margin > -1.0 and not best.off:
		if oi.margin > 1.2:
			flag_offside(oi); return
		if lance_cd <= 0:
			start_offside(oi); return
		if assistant_call(oi):
			flag_offside(oi); return
	if hand_check(best, sp): return
	if line_check(best, sp): return
	if best.role == "gk" and sp > 12 and last != best.team:
		var save_p: float = 0.28 if bpen else clamp(0.95 - (sp - 12) * 0.03 + gk_bonus(best), 0.5, 0.93)
		if rng.randf() > save_p:
			no_pick = best; no_pick_t = 0.5; return
		if sp > 20 and rng.randf() < 0.45:
			var n := Vector2(-bv.x * 0.3, (-1.0 if rng.randf() < 0.5 else 1.0) * 8).normalized()
			bv = n * 9 + Vector2(dirs(best.team) * 3, 0); bvz = 2; no_pick = best; no_pick_t = 0.4; last = best.team; bpen = false
			toast("Defesa do guarda-redes", 1.2)
			return
	owner = best; last = best.team; target = null; bpen = false; trail = []
	best.cd = rand(0.9, 1.4) if best.role == "gk" else rand(0.7, 1.4); best.dribble = Vector2.ZERO
	if best.role == "gk" and mode == "play": stall_check(best)

func throw_in() -> void:
	var team := 1 - last
	var at := Vector2(clamp(bp.x, 1, W - 1), -0.4 if bp.y < 0 else H + 0.4)
	var p: Pl = nearest(active().filter(func(q): return q.team == team and q.role != "gk"), at)[0]
	reset_ball(at)
	if p:
		p.p = at; p.v = Vector2.ZERO; owner = p; p.cd = 0.7; p.set_piece = true; last = team
	pause = 0.7

func goal_kick(side: int) -> void:
	var gk: Pl = null
	for p in active():
		if p.team == side and p.role == "gk": gk = p
	reset_ball(Vector2(own_goal_x(side) + dirs(side) * 4.0, H / 2))
	if gk:
		gk.p = Vector2(own_goal_x(side) + dirs(side) * 3.0, H / 2); owner = gk; gk.cd = 1.2; gk.set_piece = true; last = side
		stall_check(gk)
	pause = 0.9

func corner(team: int, y: float) -> void:
	var x := W - 0.5 if dirs(team) > 0 else 0.5
	var p: Pl = nearest(active().filter(func(q): return q.team == team and q.role != "gk"), Vector2(x, y))[0]
	reset_ball(Vector2(x, y))
	if p:
		p.p = Vector2(x + (-0.6 if x < 1 else 0.6), y); owner = p; p.cd = 1.1; p.set_piece = true; last = team
	toast("Canto para " + art_t(team), 1.4)
	pause = 1.1
	if p: corner_check(team, p, false)

func goal(team: int) -> void:
	if goal_check(team): return
	goal_award(team)
	if not no_var and training.is_empty():
		later(1.4, func(): if mode == "play": radio("VAR", "Golo verificado. Pode recomeçar."))

func goal_award(team: int) -> void:
	score[team] += 1; added += 0.4
	toast("Golo " + de_t(team) + "!", 2.2)
	sfx("cheer", 1.0 if team == HOME else 0.4); sfx("whistle", "short")
	feed_goal(team)
	crowd = clamp(crowd + (-18 if team == HOME else 8), 0, 100)
	kickoff(1 - team)
	pause = 2.2

# ---------- fora de jogo ----------
func offside_snap(p: Pl, m: Pl) -> void:
	var ti := p.team
	var opps: Array = active().filter(func(q): return q.team != ti)
	opps.sort_custom(func(a, c): return rel(ti, a.p.x) > rel(ti, c.p.x))
	var line_def: Pl = opps[1] if opps.size() > 1 else (opps[0] if opps.size() else null)
	var line_rel: float = max(rel(ti, line_def.p.x) if line_def else W, W / 2)
	var line_x: float = max(line_rel, rel(ti, bp.x))
	var a: Vector2 = ast[1 if dirs(ti) > 0 else 0]
	var snap: Array = []
	for q in active(): snap.append(snap_of(q))
	off_info = {"passer": p.id, "receiver": m.id, "team": ti, "margin": rel(ti, m.p.x) - line_x, "line_x": abs_x(ti, line_x), "recv": m.p,
		"line_def": line_def.id if line_def else -1, "ast": a, "ball": bp, "snap": snap, "minute": minute()}

func assistant_call(oi: Dictionary) -> bool:
	var mis: float = absf(oi.ast.x - oi.line_x)
	var acc: float = clamp((0.92 if absf(oi.margin) > 0.5 else 0.7) - min(0.3, mis * 0.05), 0.5, 0.95)
	var truth: bool = oi.margin > 0
	return truth if rng.randf() < acc else not truth

func flag_offside(oi: Dictionary) -> void:
	var def_t: int = 1 - oi.team
	ast_flag[1 if dirs(oi.team) > 0 else 0] = 1.8
	var at := Vector2(clamp(oi.recv.x, 1, W - 1), clamp(oi.recv.y, 1, H - 1))
	var p: Pl = nearest(active().filter(func(q): return q.team == def_t and q.role != "gk"), at)[0]
	reset_ball(at)
	if p:
		p.p = at - Vector2(dirs(def_t) * 0.8, 0); owner = p; last = def_t; p.cd = 0.9; p.set_piece = true
	offsides += 1
	feed("Bandeira no ar: fora de jogo " + de_t(oi.team) + ".", "info")
	toast("Fora de jogo: bandeira do assistente", 1.8)
	pause = 1.2

func ast_step(dt: float) -> void:
	for i in 2:
		# o assistente de cima cobre a metade esquerda: segue quem ataca para a esquerda
		var att_t := 0 if dirs(0) < 0 else 1
		if i == 1: att_t = 1 - att_t
		var line_x := abs_x(att_t, offside_line(att_t))
		var tx: float = minf(line_x, bp.x) if i == 0 else maxf(line_x, bp.x)
		tx = clamp(tx, 0.5, W / 2) if i == 0 else clamp(tx, W / 2, W - 0.5)
		ast[i].x += clamp((tx - ast[i].x) * 3, -7.5, 7.5) * dt
		if ast_flag[i] > 0: ast_flag[i] -= dt

func start_offside(oi: Dictionary) -> void:
	lance_cd = rand(11, 16) * lance_k
	var mis: float = absf(oi.ast.x - oi.line_x)
	var flag := assistant_call(oi)
	lance = {"kind": "offside", "oi": oi, "truth": "fora" if oi.margin > 0 else "emjogo", "flag": flag, "mis": mis, "dist": mis,
		"clarity": clamp(1 - mis / 6, 0.1, 1), "dist_score": 1.0, "minute": oi.minute, "ref": ref, "decide_t": decision_time(), "stress": stress,
		"att": {"id": oi.receiver, "team": oi.team, "num": players[oi.receiver].num, "role": players[oi.receiver].role},
		"def": {"id": oi.line_def, "team": 1 - oi.team, "num": players[oi.line_def].num if oi.line_def >= 0 else 0, "role": "lcb"},
		"in_box": false, "flash": "Fora de jogo?", "P": oi.recv}
	mode = "lance"
	for p in players: p.v *= 0.2
	emit("lance", {"L": lance})

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
	var fa := ref_attr("fis")
	var speed := 8.3 + fa * 0.06 if run else 5.8 + fa * 0.04
	if moving: ref += d.normalized() * speed * dt
	ref = Vector2(clamp(ref.x, -2, W + 2), clamp(ref.y, -2, H + 2))
	stamina = clamp(stamina + ((-16.0 * (1.25 - 0.05 * fa)) if run else ((3.0 if moving else 7.0) * (0.75 + 0.05 * fa))) * dt, 0, 100)

func stress_step(dt: float) -> void:
	var tgt: float = stress_base + max(0.0, crowd - 55) * 0.4
	stress += (tgt - stress) * 0.03 * dt

# ---------- passo ----------
func tick(dt: float) -> void:
	# temporizadores correm sempre (como os setTimeout do browser)
	var i := 0
	while i < timers.size():
		timers[i][0] -= dt
		if timers[i][0] <= 0:
			var f: Callable = timers[i][1]
			timers.remove_at(i)
			f.call()
		else: i += 1
	match mode:
		"play": _play_step(dt)
		"pergunta":
			ask.t += dt
			if ask.t > 10: ask_pick(int(ask.def))
			physics(0)
		"protesto":
			_protest_step(dt); physics(0)

func _play_step(dt: float) -> void:
	t += dt
	if add_min and t >= MATCH_SECONDS * (1 + add_min / 90.0):
		end_match("fim"); return
	lance_cd -= dt
	for k in 2: aggr[k] = max(0.05, aggr[k] - 0.012 * dt)
	control = min(100.0, control + 0.05 * dt)
	ref_step(dt)
	ast_step(dt)
	crowd += (crowd_base - crowd) * 0.02 * dt
	stress_step(dt)
	if tut: tut_step()
	half_check(); added_time_check(); pend_step(dt); stall_step(dt); fk_step(dt); coach_step(dt)
	if mode != "play": return
	if not training.is_empty():
		lance_cd = 1e9; training.next -= dt
		if training.next <= 0 and pause <= 0: train_next()
		if mode != "play": return
	if pause > 0:
		pause -= dt; physics(0)
	else:
		ai_step(dt)
		if mode != "play": return
		physics(dt)

# ---------- lances ----------
func kind_of(L: Dictionary) -> String: return str(L.get("kind", "foul"))
func choices_for(L: Dictionary) -> Array:
	var k := kind_of(L)
	var out: Array = KEYS.get(k, KEYS.foul).duplicate()
	if k == "foul" and L.get("in_box", false): out.erase("vantagem")
	return out
func is_foul(d: String) -> bool: return d == "falta" or d == "amarelo" or d == "vermelho"

# o que o árbitro vê: distância, ângulo e quem está à frente
func sight_of(r: Vector2, P: Vector2, dir_act: Vector2, others: Array) -> Dictionary:
	var dist := P.distance_to(r)
	var dist_score: float = clamp(1 - (dist - 8) / 28, 0.1, 1)
	var view := (P - r).normalized()
	var angle_score := 0.55 + 0.45 * absf(view.cross(dir_act))
	var blockers := 0
	for o in others:
		var rp: Vector2 = o.p - r
		var proj := rp.dot(view)
		if proj <= 0.6 or proj >= dist - 1: continue
		if absf(rp.cross(view)) < 0.85: blockers += 1
	return {"dist": dist, "dist_score": dist_score, "blockers": blockers, "clarity": clamp(dist_score * angle_score * (1 - 0.3 * blockers), 0.05, 1)}

# leitura de jogo: o árbitro antecipa e chega uns metros mais perto (ou mais longe, se ainda for fraco)
func ref_spot(P: Vector2) -> Vector2:
	var r := ref
	var dd := P.distance_to(r)
	var m: float = clamp((ref_attr("leit") - 5) * 0.8, -3, max(0.0, dd - 6))
	return r + (P - r).normalized() * m

func others_near(P: Vector2, exclude: Array, rad := 38.0) -> Array:
	var out: Array = []
	for p in active():
		if p in exclude: continue
		if p.p.distance_to(P) < rad: out.append(snap_of(p))
	return out

func start_lance(att: Pl, def: Pl) -> void:
	lance_cd = rand(11, 16) * lance_k
	var ag: float = aggr[def.team]
	var wts: Dictionary
	if not force_w.is_empty(): wts = force_w
	elif def.role == "gk": wts = {"siga": 0.4, "falta": 0.22, "amarelo": 0.14, "simulacao": 0.24}
	else: wts = {"siga": 0.24, "falta": 0.34, "amarelo": 0.2 * (1 + ag * 2) * def.hard_k, "vermelho": 0.06 * (1 + ag * 3) * def.hard_k, "simulacao": 0.16 * sim_k * att.sim_k}
	var truth := pick_truth(wts)
	var to_goal := (Vector2(opp_goal_x(att.team), H / 2) - att.p).normalized()
	var mv := att.v.normalized() if att.v.length() > 0.5 else to_goal
	var A := (mv * 0.7 + to_goal * 0.3).normalized()
	var phi: float = {"siga": rand(115, 160), "falta": rand(75, 115), "amarelo": rand(40, 75), "vermelho": rand(5, 30), "simulacao": rand(85, 135)}[truth]
	if def.role == "gk": phi = rand(140, 170)
	var side := 1.0 if A.cross(def.p - att.p) > 0 else -1.0
	var D := A.rotated(-side * deg_to_rad(phi))
	var P := att.p
	var r := ref_spot(P)
	var others := others_near(P, [att, def])
	var L := {"kind": "foul", "truth": truth, "P": P, "A": A, "D": D, "phi": phi, "side": side, "ref": r, "others": others, "minute": minute(),
		"fall": truth != "siga" or rng.randf() < 0.6, "in_box": in_own_box(def.team, P), "att": pinfo(att), "def": pinfo(def),
		"decide_t": decision_time(), "stress": stress, "flash": "Lance!"}
	L.merge(sight_of(r, P, D, others), true)
	L.merge(foul_extras(att, def, truth, P, A, L.in_box), true)
	lance = L
	mode = "lance"
	att.v = Vector2.ZERO; def.v = Vector2.ZERO
	sfx("ooh")
	emit("lance", {"L": L})

func counter_attack(att: Pl) -> bool:
	var ti := att.team
	var r := rel(ti, att.p.x)
	if r < W * 0.45: return false
	var behind := 0
	for q in active():
		if q.team != ti and q.role != "gk" and rel(ti, q.p.x) > r: behind += 1
	return behind <= 2

func foul_extras(att: Pl, def: Pl, truth: String, P: Vector2, A: Vector2, in_box: bool) -> Dictionary:
	var o := {"look": truth, "why": "", "adv": false, "counter": def.role != "gk" and counter_attack(att)}
	if def.role == "gk":
		o.truth = truth; return o
	# vantagem: a bola sobra para um colega com espaço?
	var E := Vector2(clamp(P.x + A.x * 9, 2, W - 2), clamp(P.y + A.y * 9, 2, H - 2))
	var act: Array = active().filter(func(q): return q != att and q != def and q.role != "gk")
	var nm: Array = nearest(act.filter(func(q): return q.team == att.team), E)
	var no: Array = nearest(act.filter(func(q): return q.team != att.team), E)
	var mate: Pl = nm[0]; var dm: float = nm[1]
	var opp: Pl = no[0]; var dop: float = no[1]
	if is_foul(truth):
		if (truth == "falta" or truth == "amarelo") and not in_box and mate and dm < 16 and (opp == null or dm + 1.5 < dop) and rng.randf() < 0.8:
			o.adv = true; o.get_id = mate.id; o.ball_to = E.lerp(mate.p, 0.5)
		elif opp and dop < 22:
			o.get_id = opp.id; o.ball_to = E
	var tr := truth
	if tr == "falta" and def.fouls >= 2: tr = "amarelo"; o.why = "reiterada"
	elif tr == "falta" and o.counter and not o.adv: tr = "amarelo"; o.why = "tatica"
	o.truth = tr
	return o

# lance com pesos próprios
func forced_lance(att: Pl, def: Pl, wts: Dictionary, extra: Dictionary) -> Dictionary:
	force_w = wts; start_lance(att, def); force_w = {}
	if lance.is_empty(): return {}
	lance.merge(extra, true)
	return lance

# lances com cena própria (mão, canto, golo, linha, aéreo, agarrão, pisão)
func start_scene(L0: Dictionary, dir_act: Vector2, exclude: Array, flash: String, scene := true) -> void:
	lance_cd = rand(11, 16) * lance_k
	var r := ref_spot(L0.P)
	var others: Array = L0.get("others", others_near(L0.P, exclude))
	var L := {"scene": scene, "ref": r, "others": others, "minute": minute(), "decide_t": decision_time(), "stress": stress, "fall": false, "flash": flash}
	L.merge(L0, true)
	L.merge(sight_of(r, L.P, dir_act, others), true)
	lance = L
	mode = "lance"
	owner = null; bv = Vector2.ZERO; bvz = 0; target = null; trail = []; off_info = {}
	for p in players: p.v *= 0.2
	sfx("ooh")
	emit("lance", {"L": L})

# ---- mão na bola: remate ou cruzamento que bate num defesa
func hand_check(p: Pl, sp: float) -> bool:
	var k := kicker
	if mode != "play" or not training.is_empty() or tut or lance_cd > 0 or p.role == "gk" or last == p.team or k == null or k.off or k.team == p.team or sp < 8 or bz > 2.2: return false
	var box := in_own_box(p.team, p.p)
	if rng.randf() > (0.22 if box else 0.05): return false
	start_hand(k, p)
	return true
func start_hand(k: Pl, d: Pl) -> void:
	var truth := pick_truth({"siga": 0.45, "mao": 0.38, "maoAmarelo": 0.17})
	var Sd := (d.p - k.p).normalized()
	if Sd == Vector2.ZERO: Sd = Vector2(dirs(k.team), 0)
	var dist0: float = clamp(d.p.distance_to(k.p), 7, 15)
	var P := d.p
	var arm_out: float
	if truth == "mao": arm_out = rand(1.15, 1.45)
	elif truth == "maoAmarelo": arm_out = rand(2.3, 2.7)
	else: arm_out = rand(0.25, 0.4) if rng.randf() < 0.5 else 0.0
	start_scene({"kind": "mao", "truth": truth, "P": P, "Sd": Sd, "K": P - Sd * dist0, "dist0": dist0, "arm_out": arm_out, "side": 1.0 if rng.randf() < 0.5 else -1.0,
		"in_box": in_own_box(d.team, d.p), "att": pinfo(k), "def": pinfo(d), "A": Sd, "D": -Sd}, Vector2(-Sd.y, Sd.x), [k, d], "Mão?")

# ---- canto ou cruzamento: empurrões na área
func corner_check(team: int, tk: Pl, cross: bool) -> void:
	if mode != "play" or not training.is_empty() or tut or lance_cd > (3.0 if cross else 9.0) or rng.randf() > (0.6 if cross else 0.75): return
	var dir := dirs(team)
	var gx := opp_goal_x(team)
	var near := -1.0 if bp.y < H / 2 else 1.0
	var Q := Vector2(gx - dir * rand(5.5, 8.5), H / 2 + near * rand(0, 3.5))
	var atts: Array = active().filter(func(p): return p.team == team and p != tk and p.role != "gk")
	if atts.is_empty(): return
	atts.sort_custom(func(a, b): return a.p.distance_to(Q) < b.p.distance_to(Q))
	var att: Pl = atts[0]
	var defs: Array = active().filter(func(p): return p.team != team and p.role != "gk")
	if defs.is_empty(): return
	defs.sort_custom(func(a, b): return a.p.distance_to(att.p) < b.p.distance_to(att.p))
	var def: Pl = defs[0]
	var start := Vector2(gx - dir * 14, H / 2 - near * 3)
	var V := (Q - start).normalized()
	var truth := pick_truth({"siga": 0.45, "penalti": 0.33, "ataque": 0.22})
	# quem sobra vai para a área: atacantes perto da marca de penálti, defesas entre eles e a baliza
	var others: Array = []
	for p in active():
		if p == att or p == def or p == tk: continue
		if p.role == "gk":
			if p.team != team: others.append({"id": p.id, "team": p.team, "role": p.role, "num": p.num, "p": Vector2(gx - dir * 0.8, H / 2 + near * 0.6), "v": Vector2.ZERO})
			continue
		var mine: bool = p.team == team
		if mine and p.line == "d" and p.role != "lcb" and p.role != "rcb": continue
		var x := gx - dir * (rand(6, 14) if mine else rand(2.5, 10))
		var y := H / 2 + rand(-9, 9)
		var v := (Q - Vector2(x, y)).normalized() * rand(0, 1.8)
		others.append({"id": p.id, "team": p.team, "role": p.role, "num": p.num, "p": Vector2(x, y), "v": v})
	start_scene({"kind": "canto", "truth": truth, "P": Q, "Q": Q, "V": V, "s": 1.0 if rng.randf() < 0.5 else -1.0, "in_box": true, "corner": bp, "gx": gx, "dir": dir,
		"fall": truth == "penalti" or (truth == "siga" and rng.randf() < 0.4), "att": pinfo(att), "def": pinfo(def), "taker": pinfo(tk), "others": others,
		"A": V, "D": V, "cross": cross}, Vector2(-V.y, V.x), [att, def, tk], "Cruzamento" if cross else "Canto")

# ---- guarda-redes: saída aos pés de quem entra na área
func gk_chance(p: Pl, dt: float) -> bool:
	if mode != "play" or not training.is_empty() or tut or lance_cd > 0 or p.role == "gk" or not in_own_box(1 - p.team, p.p): return false
	var gk: Pl = null
	for q in active():
		if q.team != p.team and q.role == "gk": gk = q
	if gk == null or gk.p.distance_to(p.p) > 5 or rng.randf() > dt * 2.5: return false
	start_lance(p, gk)
	return true

# ---- guarda-redes sai da área ao encontro de um avançado isolado: último homem?
func gk_out_check(p: Pl, dt: float) -> bool:
	if mode != "play" or not training.is_empty() or tut or lance_cd > 0 or p.role == "gk" or rng.randf() > dt * 1.1: return false
	var r := rel(p.team, p.p.x)
	if r < W - 34 or r > W - BOX_D - 3.5 or absf(p.p.y - H / 2) > 18 or not counter_attack(p): return false
	var gk: Pl = null
	for q in active():
		if q.team != p.team and q.role == "gk": gk = q
	if gk == null: return false
	var g := (Vector2(opp_goal_x(p.team), H / 2) - p.p).normalized()
	gk.p = p.p + g * 2.6
	var L := forced_lance(p, gk, {"siga": 0.3, "falta": 0.12, "amarelo": 0.2, "vermelho": 0.38}, {"gk_out": true})
	if not L.is_empty(): L.why = ""
	return not L.is_empty()

# ---- toque leve na área: chega para penálti?
func light_check(att: Pl, def: Pl) -> bool:
	if tut or not in_own_box(def.team, att.p) or def.role == "gk" or rng.randf() > 0.18: return false
	var L := forced_lance(att, def, {"siga": 0.36, "falta": 0.4, "simulacao": 0.24}, {"light": true, "fall": true})
	if L.is_empty(): return false
	if L.why == "tatica" or L.why == "reiterada": L.truth = "falta"; L.why = ""
	L.look = L.truth
	return true

# ---- pisão: o avançado protege a bola de costas e o defesa entra por trás
func stamp_check(att: Pl, def: Pl) -> bool:
	if tut or def.role == "gk" or rng.randf() > 0.035 * def.foul_k: return false
	var A := att.v.normalized() if att.v.length() > 0.5 else (Vector2(opp_goal_x(att.team), H / 2) - att.p).normalized()
	var truth := pick_truth({"siga": 0.25, "falta": 0.3, "amarelo": 0.3 * def.hard_k, "vermelho": 0.15 * def.hard_k})
	start_scene({"kind": "pisao", "truth": truth, "P": att.p, "A": A, "D": A, "s": 1.0 if rng.randf() < 0.5 else -1.0, "in_box": in_own_box(def.team, att.p),
		"att": pinfo(att), "def": pinfo(def), "fall": truth != "siga"}, Vector2(-A.y, A.x), [att, def], "Lance!", false)
	return true

# ---- bola longa: dois jogadores saltam à bola e um deles pode usar o braço
func aerial_check(p: Pl, m: Pl) -> void:
	if mode != "play" or not training.is_empty() or tut or lance_cd > 0 or rng.randf() > 0.14: return
	var no: Array = nearest(active().filter(func(q): return q.team != m.team and q.role != "gk"), m.p)
	var opp: Pl = no[0]
	if opp == null or float(no[1]) > 7: return
	var Q := Vector2(clamp(m.p.x, 4, W - 4), clamp(m.p.y, 4, H - 4))
	var V := (Q - p.p).normalized()
	var truth := pick_truth({"siga": 0.38, "falta": 0.3, "amarelo": 0.17 * opp.hard_k, "vermelho": 0.12 * opp.hard_k})
	start_scene({"kind": "aereo", "truth": truth, "P": Q, "Q": Q, "V": V, "s": 1.0 if rng.randf() < 0.5 else -1.0, "K": p.p, "in_box": in_own_box(opp.team, Q),
		"att": pinfo(m), "def": pinfo(opp), "A": V, "D": -V, "fall": truth != "siga" or rng.randf() < 0.3}, Vector2(-V.y, V.x), [m, opp], "Lance!", false)

# ---- contra-ataque: o defesa fica para trás e agarra a camisola
func grab_check(att: Pl, def: Pl) -> bool:
	if tut or not counter_attack(att) or rng.randf() > 0.45 * def.foul_k: return false
	var A := (Vector2(opp_goal_x(att.team), H / 2) - att.p).normalized()
	var truth := pick_truth({"siga": 0.3, "falta": 0.3, "amarelo": 0.4})
	start_scene({"kind": "agarrao", "truth": truth, "P": att.p, "A": A, "D": A, "s": 1.0 if rng.randf() < 0.5 else -1.0, "in_box": in_own_box(def.team, att.p),
		"att": pinfo(att), "def": pinfo(def), "counter": true, "fall": truth == "amarelo" or (truth == "falta" and rng.randf() < 0.5)}, Vector2(-A.y, A.x), [att, def], "Lance!", false)
	return true

# ---------- lances de golo ----------
func goal_check(team: int) -> bool:
	var lo := last_off
	last_off = {}
	if mode != "play" or not training.is_empty() or tut or bpen or lance_cd > 9: return false
	var k: Pl = kicker if kicker and kicker.team == team and not kicker.off else null
	if k == null: return false
	if not lo.is_empty() and t - lo.t < 6 and lo.oi.team == team and lo.n == incidents.size() and lo.o == offsides and rng.randf() < 0.85:
		start_goal_offside(lo.oi, team); return true
	var r := rng.randf()
	if r < 0.3 and shot_from != null and start_goal_foul(team, k): return true
	if r > 0.85 and start_line(team, k, "entrou", false): return true
	return false

# fora de jogo no passe que deu o golo: o assistente não levantou a bandeira
func start_goal_offside(oi: Dictionary, team: int) -> void:
	start_offside(oi)
	lance.merge({"flag": false, "goal": team, "goal_ctx": true, "dflt": "emjogo", "flash": "Golo?"}, true)

# falta do atacante antes do remate: empurra o defesa com o braço ou é só ombro com ombro
func start_goal_foul(team: int, k: Pl) -> bool:
	var gx := opp_goal_x(team)
	var dir_in := 1.0 if gx > W / 2 else -1.0
	var Gp := Vector2(gx + dir_in * 0.3, clamp(bp.y, H / 2 - GOAL_W / 2 + 0.5, H / 2 + GOAL_W / 2 - 0.5))
	var Pk: Vector2 = shot_from
	var want: float = clamp(Gp.distance_to(Pk), 9, 22)
	Pk = Gp + (Pk - Gp).normalized() * want
	var defs: Array = active().filter(func(p): return p.team != team and p.role != "gk")
	var gk: Pl = null
	for p in active():
		if p.team != team and p.role == "gk": gk = p
	if defs.is_empty() or gk == null: return false
	defs.sort_custom(func(a, b): return a.p.distance_to(Pk) < b.p.distance_to(Pk))
	var def: Pl = defs[0]
	var A := (Gp - Pk).normalized()
	var truth := pick_truth({"valido": 0.55, "anular": 0.45})
	var C := Pk - A * 6 * 0.4
	start_scene({"kind": "golo", "truth": truth, "P": C, "C": C, "Pk": Pk, "G": Gp, "A": A, "D": A, "s": 1.0 if rng.randf() < 0.5 else -1.0, "dir_in": dir_in, "gx": gx,
		"in_box": in_own_box(1 - team, Pk), "att": pinfo(k), "def": pinfo(def), "taker": pinfo(gk), "others": others_near(Pk, [k, def, gk], 32), "goal": team, "goal_ctx": true,
		"dflt": "valido", "fall": truth == "anular" or rng.randf() < 0.45}, Vector2(-A.y, A.x), [k, def, gk], "Golo?")
	return true

# bola em cima da linha: o guarda-redes tira-a de lá; passou toda ou não?
func start_line(team: int, k: Pl, truth: String, save: bool) -> bool:
	var gx := opp_goal_x(team)
	var dir_in := 1.0 if gx > W / 2 else -1.0
	var gk: Pl = null
	for p in active():
		if p.team != team and p.role == "gk": gk = p
	if gk == null: return false
	var m := rand(0.2, 0.31) if truth == "entrou" else rand(0.0, 0.14)
	var Y: float = clamp(bp.y, H / 2 - GOAL_W / 2 + 0.7, H / 2 + GOAL_W / 2 - 0.7)
	var B := Vector2(gx + dir_in * m, Y)
	var sf: Vector2 = shot_from if shot_from != null else Vector2(gx - dir_in * 15, H / 2 + rand(-7, 7))
	var dd: float = clamp(sf.distance_to(B), 8, 20)
	var Pk := B + (sf - B).normalized() * dd
	start_scene({"kind": "linha", "truth": truth, "P": Vector2(gx - dir_in * 0.6, Y), "B": B, "bh": rand(0.2, 0.45), "Pk": Pk, "A": (B - Pk).normalized(), "D": (B - Pk).normalized(),
		"dir_in": dir_in, "gx": gx, "m": m, "in_box": true, "att": pinfo(k), "def": pinfo(gk), "others": others_near(B, [k, gk], 30), "goal": team, "goal_ctx": true,
		"dflt": "naoEntrou" if save else "entrou", "save": save}, Vector2(0, 1), [k, gk], "Entrou?" if save else "Golo?")
	return true

# defesa do guarda-redes em cima da linha
func line_check(gk: Pl, sp: float) -> bool:
	var k := kicker
	if mode != "play" or not training.is_empty() or tut or lance_cd > 0 or gk.role != "gk" or last == gk.team or k == null or k.team == gk.team or sp < 12 or bpen: return false
	if absf(bp.x - own_goal_x(gk.team)) > 2.2 or absf(bp.y - H / 2) > GOAL_W / 2 or rng.randf() > 0.3: return false
	return start_line(k.team, k, pick_truth({"naoEntrou": 0.65, "entrou": 0.35}), true)

# ---------- VAR ----------
func scene_pen(L: Dictionary, x: String) -> bool: return x == "penalti" or ((x == "mao" or x == "maoAmarelo") and L.get("in_box", false))
func needs_var(L: Dictionary, d: String) -> bool:
	if interp_ok(L, d): return false
	if L.get("goal_ctx", false) and kind_of(L) != "offside": return d != L.truth
	if L.get("scene", false): return L.in_box and scene_pen(L, d) != scene_pen(L, L.truth)
	if kind_of(L) == "offside": return (d == "fora") != (L.truth == "fora") and absf(L.oi.margin) > 0.03
	if d == L.truth: return false
	if d == "vermelho" or L.truth == "vermelho": return true
	if L.in_box and is_foul(d) != is_foul(L.truth): return true
	return false
func var_eligible(L: Dictionary, d: String) -> bool:
	if L.get("goal_ctx", false): return true
	if L.get("scene", false): return L.in_box and (scene_pen(L, d) or scene_pen(L, L.truth))
	return kind_of(L) == "offside" or d == "vermelho" or L.truth == "vermelho" or (L.in_box and (is_foul(d) or is_foul(L.truth)))
func var_call_text(L: Dictionary, d: String) -> String:
	if kind_of(L) == "offside": return "Golo em verificação: possível fora de jogo no passe. Recomendo revisão." if L.has("goal") else "Possível erro no fora de jogo. Recomendo revisão no monitor."
	if L.get("goal_ctx", false): return "Tenho imagens da linha de golo. Recomendo revisão." if kind_of(L) == "linha" else "Golo em verificação: possível falta antes do remate."
	if d == "vermelho" or L.truth == "vermelho": return "Possível vermelho. Recomendo revisão no monitor."
	return "Possível penálti. Recomendo revisão no monitor."
func start_var(L: Dictionary, d: String) -> void:
	L.var_first = d; L.var_done = true
	if not L.get("training", false):
		var_n += 1; added += 0.7
		feed("O VAR chama o árbitro ao monitor.", "var")
		radio("VAR", var_call_text(L, d))
		ctrl(-4); add_stress(10)
	sfx("beep")
	toast("Treino: revê a decisão de campo" if L.get("training", false) else "O VAR chama-te ao monitor: ir ver custa autoridade", 1.8)
	L.decide_t = 20.0
	L.var_review = true
	emit("var", {"L": L})

# ---------- decisões ----------
func decide(d: String, timed_out := false) -> void:
	var L := lance
	if mode != "lance" or L.is_empty() or L.has("decided"): return
	if L.get("training", false) and not L.get("var_done", false): return      # no treino decide-se no monitor
	if not no_var and not L.get("var_done", false) and not timed_out and needs_var(L, d) and rng.randf() < 0.9:
		start_var(L, d); return
	L.decided = d; L.timed_out = timed_out
	if kind_of(L) == "offside": _decide_offside(L, d, timed_out); return
	if L.get("scene", false) and L.get("goal_ctx", false): _decide_goal(L, d, timed_out); return
	if L.get("scene", false): _decide_scene(L, d, timed_out); return
	var pts := 0.0
	var dc := 0.0
	var atk_t: int = L.att.team
	var def_t: int = L.def.team
	if L.truth == "simulacao":
		if d == "simulacao": pts = 1; dc = 4
		elif d == "siga": pts = 0.4; dc = -3
		else: pts = 0; dc = -10; aggr[def_t] += 0.25
	elif d == "vantagem":
		var o := adv_score(L); pts = o.x; dc = o.y
	elif d == "simulacao":
		pts = 0; dc = -11; aggr[atk_t] += 0.3
	else:
		var ok2: bool = interp_ok(L, d) or (d == L.truth and interp_of(L).size() > 0)
		var diff: int = 0 if ok2 else int(SEV[d]) - int(SEV[L.truth])
		if ok2: crit_note(L, d)
		if diff == 0: pts = 1; dc = 4
		elif absi(diff) == 1: pts = 0.4; dc = -5
		else: pts = 0; dc = -12
		if diff < 0: aggr[atk_t] += 0.12 * -diff
		if diff > 0: aggr[def_t] += 0.12 * diff
	# dar ou não vantagem é critério do árbitro: parar o jogo com a decisão certa não tira pontos (só fica a nota)
	if L.get("adv", false) and d != "vantagem" and is_foul(d) and pts == 1: L.miss_adv = true; dc = 2
	if timed_out: dc -= 4
	if L.get("training", false):
		pts = 1.0 if pts == 1 else 0.0; dc = 0
	elif L.has("var_first"):
		if pts == 1: pts = 0.7; dc = 1
		else: pts = 0; dc = -15
	ctrl(dc)
	L.pts = pts
	incidents.append(L); stress_after(L); added += 0.2
	var att: Pl = players[L.att.id]
	var def: Pl = players[L.def.id]
	var m := ""
	var foul := is_foul(d)
	if foul:
		def.fouls += 1
		if d == "amarelo":
			def.yellow += 1
			m = "Amarelo ao %d %s" % [def.num, de_t(def.team)]
			if def.yellow >= 2:
				def.off = true; m = "Segundo amarelo: %d %s expulso" % [def.num, de_t(def.team)]
		elif d == "vermelho":
			def.off = true; m = "Vermelho direto ao %d %s" % [def.num, de_t(def.team)]
		if L.in_box: penalty(att)
		else:
			owner = att; last = att.team; att.cd = 0.9; att.set_piece = true; target = null
			for p in active():
				if p.team != att.team and p.p.distance_to(att.p) < 6: p.p = att.p + (p.p - att.p).normalized() * 6
			if m == "": m = "Livre para " + art_t(att.team)
			fk_check(att)
		if L.in_box: m = (m + " · " if m != "" else "") + "Penálti para " + art_t(att.team)
	elif d == "vantagem":
		m = adv_play(L)
	elif d == "simulacao":
		att.yellow += 1; owner = def; last = def.team; def.cd = 0.8; target = null
		m = "Amarelo por simulação ao %d %s" % [att.num, de_t(att.team)]
		if att.yellow >= 2: att.off = true; m = "Segundo amarelo: %d %s expulso" % [att.num, de_t(att.team)]
	else:
		owner = def; last = def.team; def.cd = 0.5; target = null
		if L.fall: att.down = 1.2
		m = "Hesitaste: o jogo seguiu" if timed_out else "Siga o jogo"
	if owner and owner.off: owner = nearest(active().filter(func(q): return q.team == owner.team), bp)[0]
	if L.get("training", false): m = ("Certo · " if pts == 1 else "Errado, era " + str(LABEL[L.truth]).to_lower() + " · ") + m
	elif L.has("var_first"): m = ("Corrigido com o VAR · " if pts > 0 else "Mantiveste contra o VAR · ") + m
	elif not no_var and var_eligible(L, d) and not timed_out: m += " · VAR confirmou"
	if foul or d == "simulacao": sfx("whistle", "long" if d == "vermelho" or d == "amarelo" or d == "simulacao" else "short")
	var against = def_t if foul else (atk_t if d == "simulacao" else (atk_t if L.fall else null))
	L.against = against
	if against != null: crowd_react(against, pts < 1)
	var sev := 0.6 if d == "vermelho" else (0.35 if d == "amarelo" or d == "simulacao" else ((0.5 if L.in_box else 0.12) if foul else 0.18))
	feed_decision(L, d, m)
	_finish(L, d, m, func(): protest_after(against, sev, pts < 1))

func _finish(L: Dictionary, d: String, m: String, then: Callable) -> void:
	L.msg = m
	pending_after = func():
		toast(m, 2.6)
		mode = "play"; pause = max(pause, 1.2); lance = {}
		then.call()
		if control <= 10: end_match("abandonado")
	mode = "gesto"
	if m.contains("VAR confirmou"): radio("VAR", "Check completo. Decisão confirmada.")
	emit("decided", {"L": L, "d": d, "msg": m, "gest": gest_of(L, d), "say": ref_says(L, d)})

# a interface chama isto quando o gesto do árbitro acaba
func finish_after() -> void:
	if mode != "gesto": return
	var f := pending_after
	pending_after = Callable()
	if f.is_valid(): f.call()

func adv_score(L: Dictionary) -> Vector2:
	var T: String = L.truth
	if T == "falta" or T == "amarelo": return Vector2(1, 4) if L.adv else Vector2(0.4, -4)
	if T == "vermelho": return Vector2(0.4, -6)
	if T == "siga": return Vector2(0.4, -3)
	return Vector2(0, -8)
func adv_play(L: Dictionary) -> String:
	var g: Pl = players[L.get_id] if L.has("get_id") else null
	var def: Pl = players[L.def.id]
	var to: Pl = g if g and not g.off else def
	if L.has("ball_to"): to.p = L.ball_to
	owner = to; last = to.team; target = null; to.cd = 0.5
	def.fouls += 1
	pend_card = {"L": L, "t": 3.5}
	return "Vantagem! O jogo segue"

func _decide_offside(L: Dictionary, d: String, timed_out: bool) -> void:
	var ok: bool = (d == "fora") == (L.truth == "fora")
	L.pts = 1.0 if ok else 0.0
	var dc := 3.0 if ok else -7.0
	if timed_out: dc -= 4
	if L.get("training", false): dc = 0
	elif L.has("var_first"):
		L.pts = 0.7 if ok else 0.0; dc = 1.0 if ok else -15.0
	if not ok: aggr[L.oi.team if d == "fora" else 1 - L.oi.team] += 0.2
	ctrl(dc)
	incidents.append(L); stress_after(L); added += 0.2
	var m: String
	if L.has("goal"): m = goal_verdict(L, d != "fora")
	elif d == "fora":
		flag_offside(L.oi); m = "Fora de jogo: livre para " + art_t(1 - L.oi.team)
	else:
		var r: Pl = players[L.oi.receiver]
		owner = r; last = r.team; target = null; r.cd = 0.4
		m = "Hesitaste: o jogo seguiu" if timed_out else "Em jogo, siga"
	if L.get("training", false): m = ("Certo · " if ok else "Errado, era " + str(LABEL[L.truth]).to_lower() + " por " + ("%.2f" % absf(L.oi.margin)).replace(".", ",") + " m · ") + m
	elif L.has("var_first"): m = ("Corrigido com o VAR · " if ok else "Mantiveste contra o VAR · ") + m
	elif not timed_out and not no_var: m += " · VAR confirmou"
	if d == "fora": sfx("whistle", "short")
	var against: int = L.oi.team if d == "fora" else 1 - L.oi.team
	L.against = against
	crowd_react(against, not ok)
	feed_decision(L, d, m)
	_finish(L, d, m, func(): protest_after(against, 0.28 if d == "fora" else 0.18, not ok))

func _decide_scene(L: Dictionary, d: String, timed_out: bool) -> void:
	var ok: bool = d == L.truth
	var near: bool = (d != "siga" and L.truth != "siga") if kind_of(L) == "mao" else (d != "penalti" and L.truth != "penalti")
	var pts := 1.0 if ok else (0.4 if near else 0.0)
	var dc := 4.0 if ok else (-5.0 if near else -12.0)
	if timed_out: dc -= 4
	if L.get("training", false): pts = 1.0 if ok else 0.0; dc = 0
	elif L.has("var_first"):
		if pts == 1: pts = 0.7; dc = 1
		else: pts = 0; dc = -15
	ctrl(dc)
	L.pts = pts; incidents.append(L); stress_after(L); added += 0.2
	var att: Pl = players[L.att.id]
	var def: Pl = players[L.def.id]
	var atk_t := att.team
	var def_t := def.team
	reset_ball(bp)
	var m: String
	var against = null
	var sev := 0.2
	var pen := scene_pen(L, d)
	if kind_of(L) == "canto":
		att.p = L.Q; def.p = L.Q - L.V * 0.4 + Vector2(-L.V.y, L.V.x) * L.s * 0.7
	if d == "maoAmarelo":
		def.yellow += 1
		if def.yellow >= 2: def.off = true
	if d == "ataque":
		bp = def.p; owner = def; last = def_t; def.cd = 0.9; def.set_piece = true
		m = "Falta do atacante: livre para " + art_t(def_t); against = atk_t; sev = 0.3
	elif pen:
		var tk := att
		if att.off:
			for p in active():
				if p.team == atk_t and p.role != "gk": tk = p; break
		penalty(tk)
		m = "Penálti para " + art_t(atk_t) + (" por mão na bola" if kind_of(L) == "mao" else ""); against = def_t; sev = 0.5
	elif d == "mao" or d == "maoAmarelo":
		var tk: Pl = nearest(active().filter(func(p): return p.team == atk_t and p.role != "gk"), L.P)[0]
		bp = L.P; tk.p = L.P - Vector2(dirs(atk_t) * 0.8, 0); owner = tk; last = atk_t; tk.cd = 0.9; tk.set_piece = true
		m = "Mão na bola: livre para " + art_t(atk_t); against = def_t; fk_check(tk)
	else:
		var keep := def
		if def.off:
			for p in active():
				if p.team == def_t: keep = p; break
		bp = keep.p; owner = keep; last = def_t; keep.cd = 0.5
		m = "Hesitaste: o jogo seguiu" if timed_out else "Siga o jogo"; against = atk_t
		sev = 0.35 if kind_of(L) == "canto" and L.fall else 0.22
	if d == "maoAmarelo": m = "Amarelo ao %d %s · " % [def.num, de_t(def_t)] + m
	if L.get("training", false): m = ("Certo · " if pts == 1 else "Errado, era " + str(LABEL[L.truth]).to_lower() + " · ") + m
	elif L.has("var_first"): m = ("Corrigido com o VAR · " if pts > 0 else "Mantiveste contra o VAR · ") + m
	elif not no_var and var_eligible(L, d) and not timed_out: m += " · VAR confirmou"
	if d != "siga": sfx("whistle", "long" if d == "maoAmarelo" or pen else "short")
	L.against = against
	if against != null: crowd_react(against, pts < 1)
	feed_decision(L, d, m)
	_finish(L, d, m, func(): protest_after(against, sev, pts < 1))

func goal_verdict(L: Dictionary, allowed: bool) -> String:
	var team: int = L.goal
	reset_ball(bp)
	if allowed:
		goal_award(team)
		return "A bola entrou toda: golo " + de_t(team) if kind_of(L) == "linha" and L.get("save", false) else "Golo validado"
	anulados += 1
	if kind_of(L) == "offside":
		flag_offside(L.oi); return "Golo anulado por fora de jogo"
	if kind_of(L) == "golo":
		var d0: Pl = players[L.def.id]
		var tk := d0
		if d0.off:
			for p in active():
				if p.team == d0.team and p.role != "gk": tk = p; break
		tk.p = Vector2(clamp(L.C.x, 1, W - 1), clamp(L.C.y, 1, H - 1))
		bp = tk.p; owner = tk; last = tk.team; tk.cd = 0.9; tk.set_piece = true
		return "Golo anulado: falta do %d %s" % [L.att.num, de_t(team)]
	var gk: Pl = players[L.def.id]
	gk.p = Vector2(L.gx - L.dir_in * 1.2, L.B.y)
	bp = gk.p; owner = gk; last = gk.team; gk.cd = 1.1
	return "Não entrou toda: o guarda-redes salvou" if L.get("save", false) else "Golo anulado: a bola não entrou toda"

func _decide_goal(L: Dictionary, d: String, timed_out: bool) -> void:
	var ok: bool = d == L.truth
	var pts := 1.0 if ok else 0.0
	var dc := 4.0 if ok else -12.0
	if timed_out: dc -= 4
	if L.has("var_first"):
		if pts == 1: pts = 0.7; dc = 1
		else: pts = 0; dc = -15
	ctrl(dc)
	L.pts = pts; incidents.append(L); stress_after(L); added += 0.3
	var allowed := d == "valido" or d == "entrou"
	var m := goal_verdict(L, allowed)
	var against: int = 1 - L.goal if allowed else L.goal
	if L.has("var_first"): m = ("Corrigido com o VAR · " if pts > 0 else "Mantiveste contra o VAR · ") + m
	elif not no_var and not timed_out: m += " · VAR confirmou"
	if not allowed: sfx("whistle", "short")
	L.against = against
	crowd_react(against, pts < 1)
	feed_decision(L, d, m)
	_finish(L, d, m, func(): protest_after(against, 0.4 if allowed else 0.5, pts < 1))

func penalty(att: Pl) -> void:
	var team := att.team
	var dir := dirs(team)
	var spot_x := opp_goal_x(team) - dir * SPOT
	var taker := att
	if att.off:
		for p in active():
			if p.team == team and p.role == "st": taker = p
		if taker.off:
			for p in active():
				if p.team == team and p.role != "gk": taker = p; break
	for p in active():
		if p.role == "gk" and p.team != team:
			p.p = Vector2(opp_goal_x(team) - dir * 0.6, H / 2); continue
		if p == taker: continue
		if in_own_box(1 - team, p.p) or p.p.distance_to(Vector2(spot_x, H / 2)) < 9:
			p.p = Vector2(opp_goal_x(team) - dir * (BOX_D + rand(1, 4)), H / 2 + rand(-10, 10))
	taker.p = Vector2(spot_x - dir * 1.2, H / 2); taker.v = Vector2.ZERO
	reset_ball(Vector2(spot_x, H / 2))
	owner = taker; last = team; taker.cd = 1.8; taker.penalty = true
	pause = 1.8

# ---------- público, nervos, capitães ----------
func crowd_react(against, wrong: bool) -> void:
	if against == null: return
	if wrong and not career.is_empty(): career.wrong[against] += 1
	if training.is_empty(): cap_trust[against] = clamp(cap_trust[against] + (-0.12 if wrong else 0.03), 0, 1)
	if not training.is_empty(): return
	if against == HOME:
		crowd = clamp(crowd + 9 + (12 if wrong else 0), 0, 100); sfx("boo", 0.5 + crowd / 200)
	else:
		crowd = clamp(crowd - 4, 0, 100)
		if wrong: sfx("cheer", 0.35)
func stress_after(L: Dictionary) -> void:
	if L.get("training", false): return
	add_stress(-6.0 if L.pts == 1 else (6.0 if L.pts > 0 else 12.0))
	if L.get("timed_out", false): add_stress(6)
func captain_of(team: int) -> Pl:
	var a: Array = active().filter(func(p): return p.team == team and p.role != "gk")
	for r in ["cm", "rcb"]:
		for p in a:
			if p.role == r: return p
	return a[0] if a.size() else null

# ---------- protestos: os jogadores prejudicados vão ter com o árbitro ----------
func protest_after(team, sev: float, wrong: bool) -> void:
	if team == null or mode != "play" or not training.is_empty() or tut: return
	coach_check(team, sev, wrong)
	var I: float = clamp(sev - (ref_attr("aut") - 5) * 0.04 + (0.35 if wrong else 0.0) + aggr[team] * 0.3 + (crowd / 100 * 0.15 if team == HOME else 0.0) + rand(-0.1, 0.1), 0, 1)
	if I < 0.3: return
	var ps: Array = active().filter(func(p): return p.team == team and p.role != "gk")
	ps.sort_custom(func(a, b): return a.p.distance_to(ref) < b.p.distance_to(ref))
	ps = ps.slice(0, 1 + int(round(I * 3)))
	var ids: Array = []
	for p in ps: ids.append(p.id)
	protest = {"team": team, "ids": ids, "I": I, "t": 0.0}
	add_stress(I * 8)
	mode = "protesto"
	var txt := ("%d jogadores " % ps.size() if ps.size() > 1 else "Um jogador ") + de_t(team) + (" vêm" if ps.size() > 1 else " vem") + " protestar" + (", muito exaltados" if I > 0.7 else (", exaltados" if I > 0.5 else ""))
	emit("protest", {"msg": txt, "I": I, "trust": cap_trust[team]})
	if team == HOME: sfx("boo", 0.4 + I * 0.4)
func _protest_step(dt: float) -> void:
	protest.t += dt
	for p in players: p.v *= 0.9
	var n: int = protest.ids.size()
	for i in n:
		var p: Pl = players[protest.ids[i]]
		var a: float = float(i) / max(1, n) * PI * 1.4 - 0.7 + (p.p - ref).angle()
		move_to(p, ref + Vector2(cos(a), sin(a)) * 1.9, 6.5, dt)
		p.p += p.v * dt
	if protest.t > 8: resolve_protest("ignorar", true)
func resolve_protest(choice: String, timed_out := false) -> void:
	if protest.is_empty() or mode != "protesto": return
	var P := protest
	var I: float = P.I
	var team: int = P.team
	var dc := 0.0
	var m := ""
	if choice == "ignorar":
		dc = -8.0 if I > 0.6 else (-3.0 if I > 0.4 else 1.0); aggr[team] += I * 0.15
		m = ("Deixaste-os falar: " if timed_out else "Ignoraste os protestos: ") + ("o ambiente aquece" if dc < 0 else "acalmaram")
	elif choice == "afastar":
		dc = -3.0 if I > 0.75 else 2.0; aggr[team] = max(0.05, aggr[team] - 0.05)
		m = "Afastaste os jogadores com firmeza" if dc > 0 else "Afastaste-os, mas continuam a reclamar"
	elif choice == "capitao":
		var cap := captain_of(team)
		var tr: float = cap_trust[team]
		var ok: bool = rng.randf() < clamp(0.25 + tr * 0.6 - I * 0.25 + (ref_attr("aut") - 5) * 0.03, 0.1, 0.9)
		var w := "o capitão " + de_t(team) + (" (%d)" % cap.num if cap else "")
		if ok:
			aggr[team] = max(0.05, aggr[team] - 0.1); cap_trust[team] = clamp(tr + 0.08, 0, 1); add_stress(-6); dc = 4; m = "Falaste com " + w + ": acalmou os colegas"
		else:
			cap_trust[team] = clamp(tr - 0.1, 0, 1); add_stress(3); dc = -2; m = "Falaste com " + w + ", mas não te deu ouvidos"
	else:
		var p: Pl = players[P.ids[0]]
		if p == captain_of(p.team): cap_trust[p.team] = clamp(cap_trust[p.team] - 0.25, 0, 1)
		p.yellow += 1; dc = 6.0 if I > 0.55 else -5.0
		if I > 0.55: aggr[team] = max(0.05, aggr[team] - 0.2)
		m = "Amarelo por protestos ao %d %s" % [p.num, de_t(p.team)]
		if p.yellow >= 2:
			p.off = true; m = "Segundo amarelo por protestos: %d expulso" % p.num
			if owner == p: owner = null
		if dc < 0: m += " · pareceu exagerado"
		sfx("whistle", "short")
	ctrl(dc)
	feed(m + ".", "info")
	protests.append({"minute": minute(), "choice": choice, "I": I, "dc": dc})
	protest = {}
	toast(m, 2.4)
	mode = "play"; pause = max(pause, 0.8)
	emit("protest_end")
	if control <= 10: end_match("abandonado")

# ---------- perguntas curtas a meio do jogo ----------
func ask_open(msg_: String, tag: String, opts: Array, cb: Callable, def := 0) -> void:
	ask = {"opts": opts, "cb": cb, "t": 0.0, "def": def}
	mode = "pergunta"
	emit("ask", {"msg": msg_, "tag": tag, "opts": opts})
func ask_pick(i: int) -> void:
	if ask.is_empty() or mode != "pergunta" or i < 0 or i >= ask.opts.size(): return
	var A := ask
	ask = {}
	mode = "play"; pause = max(pause, 0.8)
	emit("ask_end")
	var cb: Callable = A.cb
	cb.call(A.opts[i].d)
	if control <= 10: end_match("abandonado")

# cartão depois da vantagem, na paragem seguinte
func pend_step(dt: float) -> void:
	if pend_card.is_empty() or pause > 0: return
	pend_card.t -= dt
	if pend_card.t > 0: return
	var L: Dictionary = pend_card.L
	pend_card = {}
	var p: Pl = players[L.def.id]
	ask_open("Jogo parado. Deste vantagem na falta do %d %s%s. Mostras cartão?" % [p.num, de_t(p.team), " (já tem amarelo)" if p.yellow else ""], "Depois da vantagem",
		[{"d": "nenhum", "label": "Sem cartão", "small": "foi só falta"}, {"d": "amarelo", "label": "Amarelo", "small": "entrada imprudente", "sw": "amarelo"}, {"d": "vermelho", "label": "Vermelho", "small": "jogo violento", "sw": "vermelho"}],
		func(c):
			L.card_later = c
			var want := "amarelo" if L.truth == "amarelo" else ("vermelho" if L.truth == "vermelho" else "nenhum")
			if c != want: L.pts = max(0.0, L.pts - 0.5)
			ctrl(2.0 if c == want else -4.0)
			var m := ("Sem cartão para o %d" % p.num) if c == "nenhum" else ("Amarelo" if c == "amarelo" else "Vermelho") + " ao %d %s pela falta anterior" % [p.num, de_t(p.team)]
			if c == "amarelo":
				p.yellow += 1
				if p.yellow >= 2: p.off = true; m = "Segundo amarelo: %d %s expulso" % [p.num, de_t(p.team)]
			if c == "vermelho": p.off = true
			if p.off and owner == p: owner = nearest(active().filter(func(x): return x.team == p.team), p.p)[0]
			if c != "nenhum":
				sfx("whistle", "long"); feed(m + ".", "card")
			toast(m, 2.2), 0)

# antijogo: o guarda-redes que está a ganhar demora a repor a bola
func stall_check(gk: Pl) -> void:
	if not training.is_empty() or tut or not stall.is_empty() or stall_n >= 2 or t < MATCH_SECONDS * 0.5 or score[gk.team] <= score[1 - gk.team] or rng.randf() > 0.7: return
	stall = {"id": gk.id, "team": gk.team, "t": 0.0}; stall_n += 1
func stall_step(dt: float) -> void:
	if stall.is_empty(): return
	var St := stall
	var p: Pl = players[St.id]
	if owner != p or p.off:
		stall = {}; return
	St.t += dt; p.cd = max(p.cd, 0.5)
	if St.t < 3.2 or pause > 0: return
	var team: int = St.team
	var was: bool = warned[team]
	stall = {}
	ask_open("O guarda-redes " + de_t(team) + " está a demorar a repor a bola" + (" outra vez" if was else "") + ".", "Antijogo",
		[{"d": "deixar", "label": "Deixar", "small": "ainda é cedo"}, {"d": "avisar", "label": "Mandar jogar", "small": "aviso verbal"}, {"d": "amarelo", "label": "Amarelo", "small": "por antijogo", "sw": "amarelo"}],
		func(c):
			var best := "amarelo" if was else "avisar"
			var pts := 1.0 if c == best else (0.5 if c != "deixar" else (0.0 if was else 0.2))
			ctrl(3.0 if pts == 1 else (-1.0 if pts >= 0.5 else -4.0))
			if c == "deixar" and team != HOME:
				crowd = clamp(crowd + 10, 0, 100); sfx("boo", 0.5)
			if c != "deixar": warned[team] = true
			var m: String = "Deixaste o guarda-redes demorar" if c == "deixar" else ("Mandaste o guarda-redes jogar" if c == "avisar" else "Amarelo ao guarda-redes " + de_t(team) + " por antijogo")
			if c == "amarelo":
				p.yellow += 1; sfx("whistle", "short")
				if p.yellow >= 2: p.off = true; m = "Segundo amarelo: guarda-redes " + de_t(team) + " expulso"
			manage.append({"minute": minute(), "what": "Guarda-redes a queimar tempo" + (" (já avisado)" if was else ""), "dec": {"deixar": "Deixar", "avisar": "Mandar jogar", "amarelo": "Amarelo"}[c], "pts": pts,
				"why": "Certo" if pts == 1 else ("Já tinha sido avisado: era amarelo" if was else ("Devias ter mandado jogar" if c == "deixar" else "Primeira vez: bastava um aviso"))})
			added += 0.5; p.cd = 0.3
			feed(m + ".", "card" if c == "amarelo" else "info")
			toast(m, 2.2), 0)

# descontos
func added_time_check() -> void:
	if t < MATCH_SECONDS or add_min: return
	add_min = clampi(int(round(added)), 1, 6)
	toast("O 4.º árbitro mostra +%d' de descontos" % add_min, 2.6)
	radio("4.º árbitro", "Tempo cumprido. Vou mostrar +%d." % add_min)
	feed("Descontos: mais %d %s" % [add_min, "minutos." if add_min > 1 else "minuto."], "info")

# treinador fora da área técnica: aviso, amarelo e, se insistir, vermelho
func coach_name(team: int) -> String: return Carreira.coach_name(teams[team].name)
func coach_check(team: int, sev: float, wrong: bool) -> void:
	if not training.is_empty() or not coach.is_empty() or coach_off[team] or coach_n >= 2: return
	if rng.randf() > 0.04 + (0.15 if wrong else 0.0) + sev * 0.08 + aggr[team] * 0.1: return
	coach = {"team": team, "t": 0.0}
func coach_step(dt: float) -> void:
	if coach.is_empty() or pause > 0 or not fk.is_empty(): return
	coach.t += dt
	if coach.t < 1.5: return
	var team: int = coach.team
	coach = {}; coach_n += 1
	var lv: int = coach_w[team]
	var nm := coach_name(team)
	var card_d := "vermelho" if lv >= 2 else "amarelo"
	radio("4.º árbitro", "O treinador " + de_t(team) + " está fora da área técnica!", "O treinador está fora da área técnica!")
	ask_open("O treinador " + de_t(team) + ", " + nm + ", sai da área técnica aos gritos" + ((" outra vez" + (", já com amarelo" if lv >= 2 else ", depois do aviso")) if lv else "") + ".", "Banco",
		[{"d": "ignorar", "label": "Ignorar", "small": "deixa-o falar"}, {"d": "avisar", "label": "Mandar sentar", "small": "aviso ao 4.º árbitro"},
		{"d": card_d, "label": "Vermelho" if lv >= 2 else "Amarelo", "small": "expulso para a bancada" if lv >= 2 else "cartão ao treinador", "sw": card_d}],
		func(c):
			var best := "avisar" if lv == 0 else card_d
			var pts := 1.0 if c == best else ((0.3 if lv == 0 else 0.0) if c == "ignorar" else 0.5)
			ctrl(3.0 if pts == 1 else (-1.0 if pts >= 0.5 else -4.0))
			var m: String
			if c == "ignorar":
				aggr[team] += 0.1; m = "Deixaste o treinador " + de_t(team) + " protestar"
			elif c == "avisar":
				coach_w[team] = max(lv, 1); m = "O 4.º árbitro manda sentar o treinador " + de_t(team)
			elif c == "amarelo":
				coach_w[team] = 2; m = "Amarelo ao treinador " + de_t(team) + ", " + nm; sfx("whistle", "short")
			else:
				coach_off[team] = true; m = "Vermelho: " + nm + " vai para a bancada"; sfx("whistle", "long")
				if team == HOME:
					crowd = clamp(crowd + 12, 0, 100); sfx("boo", 0.6)
			manage.append({"minute": minute(), "what": "Treinador " + de_t(team) + " a protestar" + (" (já avisado)" if lv == 1 else (" (já com amarelo)" if lv >= 2 else "")),
				"dec": {"ignorar": "Ignorar", "avisar": "Mandar sentar", "amarelo": "Amarelo", "vermelho": "Vermelho"}[c], "pts": pts,
				"why": "Certo" if pts == 1 else ("O banco também se gere: devias ter agido" if c == "ignorar" else ("Primeira vez: bastava mandá-lo sentar" if lv == 0 else ("Já tinha sido avisado: era amarelo" if lv == 1 else "Com amarelo e a insistir: era vermelho")))})
			feed(m + ".", "card" if c == "amarelo" or c == "vermelho" else "info")
			toast(m, 2.2), 0)

# ---------- livres diretos: barreira a 9,15 m ----------
func fk_check(tk: Pl) -> void:
	if not training.is_empty() or tk == null or tk.off or mode == "fim": return
	var team := tk.team
	var gx := opp_goal_x(team)
	var d := tk.p.distance_to(Vector2(gx, H / 2))
	if d < 17 or d > 31 or absf(tk.p.y - H / 2) > 17 or in_own_box(1 - team, tk.p): return
	var spot := tk.p
	var to_g := (Vector2(gx, H / 2) - spot).normalized()
	var perp := Vector2(-to_g.y, to_g.x)
	var short := rng.randf() < 0.6
	var wd := rand(6.3, 8.2) if short else rand(9.05, 9.6)
	var n := 4 if d < 23 else 3
	var C0 := spot + to_g * wd
	var defs: Array = active().filter(func(p): return p.team != team and p.role != "gk")
	defs.sort_custom(func(a, b): return a.p.distance_to(C0) < b.p.distance_to(C0))
	var wall: Array = []
	for p in defs.slice(0, n): wall.append(p.id)
	fk = {"team": team, "tk": tk.id, "spot": spot, "to_g": to_g, "perp": perp, "d": d, "wd": wd, "d0": wd, "tgt": wd, "wall": wall, "t": 0.0, "phase": "set",
		"short": short, "creep": short and rng.randf() < 0.45, "creep_id": -1, "creep_d": 0.0, "sprayed": false}
	tk.p = spot - to_g * 1.0; tk.v = Vector2.ZERO; tk.cd = 99
	fk_place()
func fk_place() -> void:
	var n: int = fk.wall.size()
	for i in n:
		var p: Pl = players[fk.wall[i]]
		if p.off: continue
		var dd: float = fk.wd - (fk.creep_d if fk.creep_id == p.id else 0.0)
		p.p = fk.spot + fk.to_g * dd + fk.perp * (i - (n - 1) / 2.0) * 0.85; p.v = Vector2.ZERO
func fk_step(dt: float) -> void:
	if fk.is_empty(): return
	var F := fk
	var tk: Pl = players[F.tk]
	if tk.off or owner != tk:
		fk = {}; return
	F.t += dt; pause = max(pause, 0.05)
	F.wd += clamp(F.tgt - F.wd, -2.5 * dt, 2.5 * dt)
	if F.creep_id >= 0 and F.creep_d < 1.2: F.creep_d += dt * 0.8
	fk_place()
	if F.phase == "set" and F.t > 1.6:
		F.phase = "ask"
		ask_open("Livre direto " + de_t(F.team) + " a %d m da baliza. Olha para a barreira: está a 9,15 m?" % int(round(F.d)), "Livre direto",
			[{"d": "bater", "label": "Mandar bater", "small": "a barreira está bem"}, {"d": "medir", "label": "Medir 9,15 m", "small": "spray e recuar"}, {"d": "amarelo", "label": "Amarelo", "small": "a quem não recua", "sw": "amarelo"}],
			func(c): _fk_first(c), 0)
	elif F.phase == "creep" and F.t > F.creep_at:
		F.phase = "ask2"
		var p: Pl = players[F.creep_id]
		ask_open("Já com o spray no chão, o %d %s volta a adiantar-se na barreira." % [p.num, de_t(p.team)], "Livre direto",
			[{"d": "deixar", "label": "Deixar", "small": "é só um passo"}, {"d": "afastar", "label": "Afastar outra vez", "small": "mais um aviso"}, {"d": "amarelo", "label": "Amarelo", "small": "não respeita a distância", "sw": "amarelo"}],
			func(c): _fk_second(c, p), 0)
	elif F.phase == "kick" and F.t > F.kick_at: _fk_kick(F, tk)
func _fk_first(c: String) -> void:
	if fk.is_empty(): return
	var F := fk
	var ok: bool = not F.short
	var best := "bater" if ok else "medir"
	var pts := 1.0 if c == best else (0.5 if (not ok and c == "amarelo") else (0.6 if (ok and c == "medir") else 0.0))
	ctrl(2.0 if pts == 1 else (-1.0 if pts >= 0.5 else -5.0))
	var m: String
	if c == "medir":
		F.sprayed = true; F.tgt = 9.15; added += 0.2; m = "Spray no chão: barreira a 9,15 m"
		ref_target = Vector2(clamp(F.spot.x + F.to_g.x * 9.15 + F.perp.x * 3, -2, W + 2), clamp(F.spot.y + F.to_g.y * 9.15 + F.perp.y * 3, -2, H + 2))
	elif c == "amarelo":
		var p: Pl = players[F.wall[0]]
		F.tgt = 9.15; F.sprayed = true
		p.yellow += 1; m = "Amarelo ao %d %s por não respeitar a distância" % [p.num, de_t(p.team)]
		if p.yellow >= 2:
			p.off = true; m = "Segundo amarelo: %d %s expulso" % [p.num, de_t(p.team)]; F.wall.erase(p.id)
		sfx("whistle", "long"); feed(m + ".", "card")
	else:
		m = ("Mandaste bater com a barreira a " + f1(F.wd) + " m") if F.short else "Barreira no sítio: pode bater"
		if F.short: protest_after_soon(F.team)
	manage.append({"minute": minute(), "what": "Livre direto: barreira a " + f1(F.d0) + " m", "dec": {"bater": "Mandar bater", "medir": "Medir 9,15 m", "amarelo": "Amarelo"}[c], "pts": pts,
		"why": "Certo" if pts == 1 else (("A barreira já estava bem: perdeste tempo" if c == "medir" else "Cartão sem razão: a barreira estava bem") if ok else ("Primeiro mede e afasta; o cartão é para quem insiste" if c == "amarelo" else "A barreira estava perto demais"))})
	toast(m, 2)
	if c == "medir" and F.creep:
		F.phase = "creep"; F.creep_at = F.t + 2.2; F.creep_id = pick(F.wall); F.creep_d = 0.0
	else:
		F.phase = "kick"; F.kick_at = F.t + (0.8 if c == "bater" else 1.8)
func _fk_second(c: String, p: Pl) -> void:
	if fk.is_empty(): return
	var F := fk
	var pts := 1.0 if c == "amarelo" else (0.5 if c == "afastar" else 0.0)
	ctrl(2.0 if pts == 1 else (-1.0 if pts > 0 else -4.0))
	var m: String = ("Deixaste o %d adiantado" % p.num) if c == "deixar" else (("Voltaste a afastar o %d" % p.num) if c == "afastar" else "Amarelo ao %d %s: não respeitou a distância" % [p.num, de_t(p.team)])
	if c == "amarelo":
		p.yellow += 1
		if p.yellow >= 2:
			p.off = true; m = "Segundo amarelo: %d %s expulso" % [p.num, de_t(p.team)]; F.wall.erase(p.id)
		sfx("whistle", "long"); feed(m + ".", "card")
	if c != "deixar": F.creep_id = -1
	manage.append({"minute": minute(), "what": "Jogador volta a adiantar-se na barreira", "dec": {"deixar": "Deixar", "afastar": "Afastar outra vez", "amarelo": "Amarelo"}[c], "pts": pts,
		"why": "Certo: depois do spray, quem avança leva amarelo" if pts == 1 else ("Já tinha sido avisado: era amarelo" if c == "afastar" else "Deixaste a barreira encurtar")})
	toast(m, 2)
	F.phase = "kick"; F.kick_at = F.t + 1.2
func protest_after_soon(team: int) -> void:
	pause = max(pause, 0.3)
	later(2.6, func(): if mode == "play" and fk.is_empty(): protest_after(team, 0.3, true))
func _fk_kick(F: Dictionary, tk: Pl) -> void:
	fk = {}; tk.cd = 0
	shoot(tk, false)
	# remate por cima da barreira: desce a tempo de entrar (ou não)
	var sp: float = max(14.0, bv.length())
	var tg: float = F.d / sp
	var zg := rand(0.5, 2.6)
	bvz = (zg + 0.5 * G * tg * tg) / tg
	pause = 0
	feed("Livre direto " + de_t(F.team) + ": o %d bate por cima da barreira." % tk.num, "info")

# ---------- interpretação: lances no limite em que as duas decisões são aceitáveis ----------
func promising(L: Dictionary) -> bool:
	if not L.has("A") or not L.has("att"): return false
	var a: Pl = players[L.att.id]
	var r := rel(a.team, L.P.x)
	var to_goal: float = L.A.x * dirs(a.team)
	return L.get("counter", false) or (r > W * 0.62 and to_goal > 0.35 and absf(L.P.y - H / 2) < 24)

func interp_of(L: Dictionary) -> Array:
	if L.has("interp"): return L.interp
	L.interp = []
	var T: String = L.truth
	if L.get("light", false) and not L.get("training", false) and (T == "falta" or T == "siga"):
		L.interp = ["siga" if T == "falta" else "falta"]; L.interp_why = "toque leve"; return L.interp
	if L.get("training", false) or L.get("tut_l", false) or L.get("scene", false) or kind_of(L) == "offside" or not (PAIR_UP.has(T) or PAIR_DN.has(T)) or L.get("why", "") == "reiterada":
		return L.interp
	var up := false
	var dn := false
	var why := ""
	var k := kind_of(L)
	if k == "foul" and not L.get("gk_out", false) and L.def.role != "gk":
		# o ângulo da entrada decide a gravidade: perto da fronteira entre dois níveis, os dois servem
		var phi := rad_to_deg(acos(clamp(L.A.dot(L.D), -1.0, 1.0)))
		if T == "falta" and phi < 86: up = true
		if T == "amarelo" and phi > 64 and L.get("why", "") != "tatica": dn = true
		if T == "amarelo" and phi < 48: up = true
		if T == "vermelho" and phi > 21: dn = true
	elif L.get("gk_out", false):
		var r := rng.randf()
		if T == "vermelho" and r < 0.3: dn = true
		elif T == "amarelo" and r < 0.35: up = true
	elif k == "aereo" or k == "agarrao" or k == "pisao":
		var r := rng.randf()
		if r < 0.3 and T != "vermelho": up = true
		elif r > 0.72 and T != "falta": dn = true
	# falta que corta um ataque prometedor: o amarelo também se aceita
	if T == "falta" and not up and promising(L): up = true; why = "ataque prometedor"
	var acc: Array = []
	if up and PAIR_UP.has(T): acc.append(PAIR_UP[T])
	if dn and PAIR_DN.has(T): acc.append(PAIR_DN[T])
	if acc.size(): L.interp = acc; L.interp_why = why
	return L.interp
func interp_ok(L: Dictionary, d: String) -> bool: return d in interp_of(L)
func interp_txt(l: Dictionary) -> String:
	var a: Array = [l.truth] + l.interp
	a.sort_custom(func(x, y): return SEV.get(x, 0) < SEV.get(y, 0))
	return " ou ".join(a.map(func(x): return str(DEC_LABEL[x]).to_lower()))

# ---------- critério: nos lances no limite, foi pelo mais duro ou pelo mais brando? E sempre igual? ----------
func crit_note(L: Dictionary, d: String) -> void:
	if interp_of(L).is_empty() or L.get("training", false): return
	var lo := 99
	for x in [L.truth] + L.interp: lo = mini(lo, int(SEV[x]))
	var s := 1 if int(SEV[d]) > lo else 0
	var pair := ""
	for k in SEV:
		if SEV[k] == lo: pair = k
	L.interp_good = true; L.strict = s
	var prev = null
	for c in crit:
		if c.pair == pair and c.s != s: prev = c
	crit.append({"s": s, "pair": pair, "m": L.minute, "team": L.def.team})
	if prev != null:
		# mudou de critério no mesmo jogo: quem levou o mais duro lembra-se do outro lance
		L.crit_flip = prev.m
		var hurt: int = L.def.team if s else prev.team
		crit_flips += 1
		ctrl(-3); aggr[hurt] += 0.06
		var pm: int = prev.m
		later(2.6, func():
			if mode == "play":
				feed(str(teams[hurt].name) + " queixam-se do critério: no lance aos %d' a decisão foi outra." % pm, "protest")
				toast("Critério diferente do lance aos %d'" % pm, 2.4))
func crit_mean() -> float:
	if crit.is_empty(): return -1.0
	var s := 0.0
	for c in crit: s += c.s
	return s / crit.size()
static func crit_label(m: float) -> String:
	if m < 0: return ""
	return "rigoroso" if m >= 0.67 else ("permissivo" if m <= 0.33 else "equilibrado")
func crit_txt() -> String:
	if crit.is_empty(): return ""
	var f := crit_flips
	return " Critério nos lances no limite: " + crit_label(crit_mean()) + ((", mas mudaste de critério " + ("%d vezes" % f if f > 1 else "uma vez") + ".") if f else ", igual o jogo todo.")
func crit_penalty() -> float: return minf(1.0, 0.3 * crit_flips)

# ---------- intervalo ----------
func half_check() -> void:
	if half or not training.is_empty() or tut or mode != "play" or t < MATCH_SECONDS / 2 or pause > 0 or not ask.is_empty() or not fk.is_empty() or not pend_card.is_empty() or bpen: return
	half = 1; half_time()
func half_time() -> void:
	mode = "intervalo"
	sfx("whistle", "end")
	feed("Intervalo: %s %d–%d %s." % [teams[0].name, score[0], score[1], teams[1].name], "info")
	var inc: Array = incidents.filter(func(l): return not l.get("training", false))
	var right := inc.filter(func(l): return l.pts == 1).size()
	var txt := ("%d de %d decisões certas na 1.ª parte." % [right, inc.size()] if inc.size() else "Primeira parte sem lances para rever.") + crit_txt() + " Na 2.ª parte as equipas trocam de campo."
	var rows: Array = []
	for l in inc:
		var what: String = LABEL[l.truth] if kind_of(l) == "offside" else str(LABEL.get(l.truth, DEC_LABEL.get(l.truth, l.truth))) + (" · no limite" if interp_of(l).size() else "")
		var res: String = verdict_txt(l)
		rows.append({"L": l, "cells": ["%d'" % l.minute, what, dec_txt(l), res], "cls": "ok" if l.pts == 1 else ("half" if l.pts > 0 else "bad")})
	half_talk = ""
	emit("half", {"title": "Intervalo · %d–%d" % [score[0], score[1]], "txt": txt, "rows": rows})
func second_half(talk := "descanso") -> void:
	if mode != "intervalo": return
	var msg := ""
	match talk:
		"capitaes":
			for k in 2: cap_trust[k] = clamp(cap_trust[k] + 0.12, 0, 1); aggr[k] = max(0.05, aggr[k] - 0.05)
			msg = "Falaste com os capitães: confiam mais em ti e os jogadores acalmam."
		"assist":
			ast_boost = true
			msg = "Acertaste o posicionamento com os assistentes: na 2.ª parte as indicações deles são mais certeiras."
		_:
			stamina = 100; stress = max(stress_base, stress - 12)
			msg = "Descansaste no balneário: energia cheia e menos nervos."
	for tm in teams: tm.dir = -int(tm.dir)
	half = 2; lance = {}
	kickoff(1)
	pause = 0.8
	mode = "play"; sfx("whistle", "long")
	feed("Começa a 2.ª parte. As equipas trocaram de campo.", "info"); toast(msg, 3)

# ---------- relato ----------
func feed(txt: String, kind := "info") -> void:
	var f := {"min": clock_txt(), "txt": txt, "kind": kind}
	feed_list.append(f)
	emit("feed", f)
func feed_goal(team: int) -> void:
	var k := kicker
	var n := k.num if k and k.team == team else -1
	var lines: Array
	if bpen: lines = ["Golo " + de_t(team) + "! Penálti bem batido" + (" pelo %d" % n if n >= 0 else "") + ".", "Golo " + de_t(team) + " de penálti, guarda-redes para um lado e bola para o outro."]
	elif n >= 0: lines = ["Golo %s! Remate do %d que só para no fundo da baliza." % [de_t(team), n], "Golo %s! O %d não perdoa." % [de_t(team), n], "Golo %s! O %d encosta e festeja." % [de_t(team), n]]
	else: lines = ["Golo " + de_t(team) + "!"]
	feed(str(pick(lines)) + " %d–%d." % [score[0], score[1]], "goal")
func feed_decision(L: Dictionary, d: String, msg_: String) -> void:
	if L.get("training", false): return
	var kind := "card" if d in ["amarelo", "vermelho", "simulacao", "maoAmarelo"] else ("pen" if msg_.contains("Penálti") else "info")
	var k := kind_of(L)
	var an: int = L.att.num if L.has("att") else 0
	var dn: int = L.def.num if L.has("def") else 0
	var intro: String
	if L.get("goal_ctx", false) and k != "offside": intro = pick(["Revisão do golo: ", "Antes de validar o golo: ", "Golo em análise: "])
	elif k == "aereo": intro = pick(["Disputa no ar entre o %d e o %d: " % [an, dn], "Bola longa e choque de cabeças: "])
	elif k == "pisao": intro = pick(["Entrada por trás do %d %s: " % [dn, de_t(L.def.team)], "O %d protege a bola e leva com o pé do %d: " % [an, dn]])
	elif L.get("gk_out", false): intro = pick(["O guarda-redes sai da área ao encontro do %d: " % an, "Saída arriscada do guarda-redes fora da área: "])
	elif L.get("light", false): intro = pick(["Contacto ligeiro na área e o %d vai ao chão: " % an, "Toque na área, o %d cai: " % an])
	elif k == "agarrao": intro = pick(["O %d %s agarra a camisola do %d: " % [dn, de_t(L.def.team), an], "Contra-ataque travado com a mão na camisola: "])
	elif k == "offside": intro = pick(["Passe em profundidade para " + who(players[L.oi.receiver].num, L.oi.team) + ": ", "Bola nas costas da defesa: "])
	elif k == "mao": intro = pick(["Remate do %d e a bola bate no %d: " % [an, dn], "A bola bate no %d %s: " % [dn, de_t(L.def.team)]])
	elif k == "canto": intro = pick(["Muita luta na área no canto: ", "Empurrões na área no canto " + de_t(L.att.team) + ": "])
	elif L.def.role == "gk": intro = "O guarda-redes sai aos pés do %d: " % an
	else: intro = pick(["Duelo entre " + who(an, L.att.team) + " e " + who(dn, L.def.team) + ": ", "Entrada do %d %s sobre o %d: " % [dn, de_t(L.def.team), an], "Choque a meio-campo: "])
	feed(intro + msg_.substr(0, 1).to_lower() + msg_.substr(1) + ".", kind)

# ---------- o árbitro comunica a decisão ----------
func ref_says(L: Dictionary, d: String) -> String:
	var tag := "Vi as imagens. " if L.has("var_first") and L.var_first != d else ""
	var p: Pl = players[L.def.id] if L.has("def") and int(L.def.id) >= 0 else null
	var second := p != null and p.off and (d == "amarelo" or d == "maoAmarelo")
	var k := kind_of(L)
	var s: String
	if k == "offside":
		if L.has("goal"): s = "Golo anulado: estavas em fora de jogo no passe." if d == "fora" else "Estava em jogo. O golo conta!"
		else: s = "Fora de jogo: estavas à frente do penúltimo defesa." if d == "fora" else "Estava em jogo, siga!"
	elif k == "aereo": s = {"siga": "Os dois foram à bola. Siga!", "falta": "Empurraste-o nas costas no salto. Falta.", "amarelo": "Usaste o braço como alavanca. Amarelo.", "vermelho": "Cotovelada na cara. Vermelho!"}.get(d, "Siga!")
	elif k == "pisao": s = {"siga": "Tocaste na bola. Siga!", "falta": "Pisaste-lhe o calcanhar. Falta.", "amarelo": "Pitões no tendão. Amarelo.", "vermelho": "Pisão com força, por trás. Vermelho!"}.get(d, "Siga!")
	elif L.get("gk_out", false) and d == "vermelho": s = "Último homem, fora da área e sem tocar na bola. Vermelho!"
	elif L.get("gk_out", false) and d == "siga": s = "O guarda-redes chegou primeiro à bola. Siga!"
	elif L.get("light", false) and d == "siga": s = "Houve toque, mas não chega para penálti. Siga!"
	elif L.get("light", false) and d == "falta": s = "Tocou-lhe no pé, é penálti!"
	elif k == "agarrao": s = {"siga": "Foi só um toque. Siga!", "falta": "Agarraste a camisola. Falta.", "amarelo": "Agarraste e paraste o contra-ataque. Amarelo.", "vermelho": "Agarrão a impedir um golo. Vermelho!"}.get(d, "Siga!")
	elif k == "golo": s = "Foi ombro com ombro. O golo conta!" if d == "valido" else "Empurraste o defesa antes do remate. Golo anulado."
	elif k == "linha": s = "A bola passou toda a linha. É golo!" if d == "entrou" else "Não passou toda a linha. Não há golo."
	elif k == "mao": s = "Braço junto ao corpo, posição natural. Siga!" if d == "siga" else ("Braço aberto, a fazer o corpo maior. É mão." if d == "mao" else "Mão deliberada a cortar o remate: amarelo.")
	elif k == "canto": s = "Disputa normal na área. Siga, levanta-te!" if d == "siga" else ("Empurrou-o pelas costas. Penálti!" if d == "penalti" else "Afastaste o defesa com o braço. Falta atacante.")
	else:
		var why: String = L.get("why", "")
		s = {"siga": "Jogou a bola primeiro. Siga!",
			"falta": "Chegaste atrasado e derrubaste-o. Penálti!" if L.get("in_box", false) else "Chegaste atrasado. Falta.",
			"amarelo": "Já são faltas a mais. Amarelo." if why == "reiterada" else ("Cortaste o contra-ataque. Amarelo." if why == "tatica" else "Entrada imprudente. Amarelo."),
			"vermelho": "Entrada com força excessiva, pões o adversário em risco. Vermelho!",
			"simulacao": "Atiraste-te para o chão. Amarelo por simulação.",
			"vantagem": "Vantagem! Joguem, joguem!"}.get(d, "Siga!")
	if second: s += " É o segundo: rua!"
	return tag + s

# que gesto fazer e quem fica à frente do árbitro (who = id do jogador ou -1)
func gest_of(L: Dictionary, d: String) -> Dictionary:
	var k := kind_of(L)
	var att_id: int = int(L.att.id) if L.has("att") else -1
	var def_id: int = int(L.def.id) if L.has("def") else -1
	var atk_t: int = int(L.oi.team) if k == "offside" else (int(L.goal) if L.has("goal") else (int(L.att.team) if L.has("att") else 0))
	var pen := Vector2(opp_goal_x(atk_t) - dirs(atk_t) * SPOT, H / 2)
	var g := {"type": "siga", "who": att_id, "spot": gest_spot(L)}
	if d == "vermelho": g.merge({"type": "card", "col": "red", "who": def_id}, true)
	elif d == "amarelo" or d == "maoAmarelo" or d == "simulacao":
		var w: int = att_id if d == "simulacao" else def_id
		g.merge({"type": "card", "col": "yellow", "second": w >= 0 and players[w].off, "who": w}, true)
	elif d == "fora": g.merge({"type": "up", "who": att_id}, true)
	elif d == "vantagem": g.merge({"type": "adv", "who": -1}, true)
	elif d == "valido" or d == "entrou" or (L.has("goal") and d == "emjogo"): g.merge({"type": "point", "to": Vector2(W / 2, H / 2), "elev": -0.12, "who": -1, "run": true}, true)
	elif d == "anular" or d == "ataque": g.merge({"type": "point", "dir": Vector2(dirs(1 - atk_t), 0), "elev": 0.12, "who": att_id}, true)
	elif (L.get("scene", false) and scene_pen(L, d)) or (not L.get("scene", false) and k != "offside" and is_foul(d) and L.get("in_box", false)): g.merge({"type": "point", "to": pen, "elev": -0.55, "who": def_id}, true)
	elif is_foul(d) or d == "mao": g.merge({"type": "point", "dir": Vector2(dirs(atk_t), 0), "elev": 0.12, "who": def_id}, true)
	g.dur = 3.2 if g.type == "card" and g.get("second", false) else 2.6
	return g
func gest_spot(L: Dictionary) -> Vector2:
	var k := kind_of(L)
	var p: Vector2 = L.oi.recv if k == "offside" else (Vector2(L.gx - L.dir_in * 4, L.B.y) if k == "linha" else (L.C if k == "golo" else L.P))
	return Vector2(clamp(p.x, 3, W - 3), clamp(p.y, 3, H - 3))

# ---------- rádio: o assistente diz o que viu nos lances tapados ----------
func radio_lance(L: Dictionary) -> void:
	if L.get("radioed", false): return
	L.radioed = true
	if L.get("training", false) or L.get("tut_l", false): return
	if kind_of(L) == "offside":
		radio("Assistente", "Levantei: para mim o recetor está fora." if L.flag else "Bandeira em baixo: vi-o em linha."); return
	if L.get("goal_ctx", false):
		radio("VAR", "Estamos a ver o golo. Decide tu primeiro."); return
	if L.clarity < 0.5 and rng.randf() < (0.85 if ast_boost else 0.65):
		var right := rng.randf() < (0.92 if ast_boost else 0.8)
		var alt: Array = choices_for(L).filter(func(x): return x != L.truth and x != "vantagem")
		var says: String = L.truth if right or alt.is_empty() else pick(alt)
		L.ast_said = says; L.ast_right = says == L.truth
		var T := {"siga": "Daqui pareceu-me lance limpo.", "falta": "Daqui vi falta.", "amarelo": "Entrada imprudente, eu dava amarelo.", "vermelho": "Foi muito forte, pode ser vermelho.",
			"simulacao": "Para mim atirou-se.", "mao": "Vi mão, braço aberto.", "maoAmarelo": "Mão deliberada.", "penalti": "Vi o empurrão do defesa.", "ataque": "Foi o atacante que empurrou."}
		if T.has(says): radio("Assistente", T[says])

# ---------- fim do jogo e relatório do observador ----------
func big_inc(l: Dictionary) -> bool: return l.get("in_box", false) or l.get("goal_ctx", false) or l.truth == "vermelho" or l.get("decided", "") == "vermelho"
func obs_acc() -> float:
	var w := 0.0
	var p := 0.0
	for l in incidents:
		var k := 2.0 if big_inc(l) else 1.0
		w += k; p += k * float(l.pts)
	for m in manage: w += 0.6; p += 0.6 * float(m.pts)
	return p / w if w > 0 else 0.7

var grade := 0.0
func end_match(kind: String) -> void:
	if mode == "fim": return
	mode = "fim"; protest = {}; ask = {}; pend_card = {}; fk = {}; coach = {}; timers.clear()
	sfx("whistle", "end")
	over = kind
	grade = clamp(obs_acc() * 10 * (0.75 + 0.25 * control / 100), 0, 10)
	grade = clamp(grade - crit_penalty(), 0, 10)
	if kind == "abandonado": grade = minf(grade, 3)
	var right := incidents.filter(func(l): return l.pts == 1).size()
	var verdict: String
	if kind == "treino": verdict = "Treino do VAR terminado."
	elif kind == "abandonado": verdict = "Jogo interrompido: perdeste o controlo aos %d'." % int(t / MATCH_SECONDS * 90)
	elif grade >= 8.5: verdict = "Pronto para jogos grandes."
	elif grade >= 7: verdict = "Boa exibição, com lances a rever."
	elif grade >= 5: verdict = "Exibição irregular."
	else: verdict = "O observador não ficou convencido."
	var pr_good := protests.filter(func(q): return q.dc > 0).size()
	var txt := "%d de %d decisões certas. " % [right, incidents.size()]
	if protests.size(): txt += "Protestos: %d de %d bem geridos. " % [pr_good, protests.size()]
	if var_n: txt += "Foste ao monitor %d %s. " % [var_n, "vezes" if var_n > 1 else "vez"]
	txt += verdict + crit_txt()
	if kind == "fim": feed("Apito final: %s %d–%d %s." % [teams[0].name, score[0], score[1], teams[1].name], "info")
	emit("end", {"kind": kind, "grade": grade, "txt": txt, "title": "Relatório do observador · %d–%d" % [score[0], score[1]]})

# linhas da tabela do relatório
# o mesmo texto no intervalo e no relatório: a mesma decisão certa nunca aparece com avaliações diferentes sem razão
func verdict_txt(l: Dictionary) -> String:
	var off := kind_of(l) == "offside"
	var pts: float = l.pts
	var dec: String = l.get("decided", "")
	var why: String
	if l.get("interp_good", false) and pts == 1: why = "Certo · no limite: " + interp_txt(l) + " serviam" + (" (mas aos %d' foste por outro critério)" % l.crit_flip if l.has("crit_flip") else "")
	elif l.get("miss_adv", false) and pts == 1: why = "Certo (podias ter dado vantagem)"
	elif dec == "vantagem" and l.get("adv", false) and pts < 1: why = "Vantagem certa, cartão errado"
	elif dec == "vantagem" and not l.get("adv", false) and pts < 1: why = "Não havia vantagem: a bola era do adversário"
	elif l.get("training", false): why = (("Certo · confirmaste a decisão de campo" if dec == l.var_first else "Certo · corrigiste a decisão de campo") if pts == 1 else "Errado · decisão de campo era " + str(DEC_LABEL[l.var_first]).to_lower())
	elif l.has("var_first"): why = ("Certo só depois do VAR (no campo: %s)" % str(DEC_LABEL.get(l.var_first, l.var_first)).to_lower()) if pts > 0 else "Errado, mesmo depois do VAR"
	elif pts == 1: why = "Certo"
	elif l.get("timed_out", false): why = "Sem decisão"
	elif off: why = "Errado · a bandeira estava certa" if l.flag == (l.truth == "fora") else "Errado · o assistente enganou-se e seguiste-o"
	elif l.has("card_later") and pts > 0 and pts < 1: why = "Vantagem certa, cartão errado"
	elif pts > 0: why = "Perto: era " + str(LABEL.get(l.truth, l.truth)).to_lower()
	else: why = "Errado · estavas mal colocado" if l.get("clarity", 1.0) < 0.45 else "Errado · viste bem, decidiste mal"
	return why

func dec_txt(l: Dictionary) -> String:
	var dec: String = l.get("decided", "")
	var cl: String = l.get("card_later", "")
	var t: String = str(DEC_LABEL.get(dec, dec if dec != "" else "–")) + (" + " + str(DEC_LABEL[cl]).to_lower() if cl != "" and cl != "nenhum" else "") + (" (tempo)" if l.get("timed_out", false) else "")
	if l.has("var_first") and not l.get("training", false) and l.var_first != dec: t = str(DEC_LABEL.get(l.var_first, l.var_first)) + ", depois " + t.to_lower() + " (VAR)"
	return t

func report_rows() -> Array:
	var out: Array = []
	for l in incidents:
		var off := kind_of(l) == "offside"
		var pts: float = l.pts
		var dec: String = l.get("decided", "")
		var why: String = verdict_txt(l)
		var what: String
		if off: what = str(LABEL[l.truth]) + " por " + f1(absf(l.oi.margin)) + " m" + (" · no golo" if l.has("goal") else "")
		else:
			what = str(LABEL[l.truth]) + (" (" + WHY[l.why] + ")" if WHY.has(l.get("why", "")) else "")
			if kind_of(l) == "linha": what += " · %d cm %s" % [absi(int(round((l.m - LINE_IN) * 100))), "para lá" if l.m >= LINE_IN else "a faltar"]
			if interp_of(l).size(): what += " · no limite" + (", " + l.interp_why if l.get("interp_why", "") != "" else "")
		var seen: String
		if off: seen = "Assistente " + ("alinhado" if l.mis < 0.8 else "a " + f1(l.mis) + " m") + " · bandeira " + ("levantada" if l.flag else "em baixo")
		else: seen = "%d m · clareza %d%%" % [int(round(l.dist)), int(round(l.clarity * 100))]
		var cl: String = l.get("card_later", "")
		var dtxt: String = dec_txt(l)
		out.append({"L": l, "cells": ["%d'" % l.minute + (" · área" if l.get("in_box", false) else ""), what, dtxt, seen, why], "cls": "ok" if pts == 1 else ("half" if pts > 0 else "bad")})
	return out

# ---------- treino do VAR: seis lances em que a decisão de campo vai ao monitor ----------
func start_training() -> void:
	training = {"n": 0, "next": 1.2, "total": 6}
	toast("Treino do VAR: seis lances para rever no monitor", 2.5)
func train_next() -> void:
	training.n += 1
	if training.n > training.total: end_match("treino"); return
	training.next = 2.5
	if int(training.n) % 2 == 0: train_offside()
	else: train_foul()
func _by_role(ti: int, r: String) -> Pl:
	for p in players:
		if p.team == ti and p.role == r: return p
	return null
func train_foul() -> void:
	# ataca a baliza da esquerda (x = 0)
	var ti := 1 if dirs(1) < 0 else 0
	var att := _by_role(ti, "st")
	var def := _by_role(1 - ti, "lcb")
	att.off = false; def.off = false
	att.p = Vector2(rand(7, 14), rand(24, 44)); att.v = Vector2(-5, rand(-1, 1))
	def.p = att.p + Vector2(rand(-2.5, 2), (-1 if rng.randf() < 0.5 else 1) * rand(3, 4.5))
	var a := rng.randf() * PI
	ref = Vector2(clamp(att.p.x + cos(a) * rand(12, 22), 1, W / 2), clamp(att.p.y + sin(a) * rand(10, 20), 1, H - 1))
	start_lance(att, def)
	var L := lance
	L.truth = pick(["vermelho", "falta", "siga", "amarelo", "simulacao"]); L.look = L.truth
	L.fall = L.truth != "siga" or rng.randf() < 0.6; L.training = true; L.adv = false; L.why = ""
	var wrong: Array = ["siga", "falta", "amarelo", "vermelho", "simulacao"].filter(func(x): return x != L.truth)
	var d0: String = pick(wrong) if rng.randf() < 0.65 else L.truth
	later(1.5, func(): if mode == "lance" and is_same(lance, L): start_var(L, d0))
func train_offside() -> void:
	var ti := 0 if dirs(0) > 0 else 1        # quem ataca para a direita
	var line_x := rand(70, 86)
	var margin := rand(-0.7, 0.7)
	for p in players: p.off = false; p.v = Vector2.ZERO
	for p in players:
		if p.team != ti:
			if p.role == "gk": p.p = Vector2(W - 3, H / 2)
			else: p.p.x = minf(p.p.x, line_x - 3)
	var roles := ["lb", "lcb", "rcb", "rb"]
	for i in 4:
		var p := _by_role(1 - ti, roles[i])
		p.p = Vector2(line_x if i == 1 else line_x - rand(0.4, 2.5), [12.0, 27.0, 41.0, 56.0][i] + rand(-2, 2)); p.v = Vector2(-rand(0.5, 2.5), 0)
	for p in players:
		if p.team == ti: p.p.x = minf(p.p.x, line_x - 4)
	var recv := _by_role(ti, "st")
	var passer := _by_role(ti, "cm")
	recv.p = Vector2(line_x + margin, rand(24, 36)); recv.v = Vector2(rand(5, 7), rand(-1, 1))
	passer.p = Vector2(line_x - rand(16, 24), rand(30, 44)); passer.v = Vector2(2, 0)
	reset_ball(passer.p + Vector2(0.5, 0)); owner = null
	ast[1].x = line_x + rand(-1.5, 1.5)
	offside_snap(passer, recv)
	var oi := off_info
	off_info = {}
	start_offside(oi)
	var L := lance
	L.training = true
	later(1.6, func():
		if mode != "lance" or not is_same(lance, L): return
		var right: String = L.truth
		var d0: String = ("emjogo" if right == "fora" else "fora") if rng.randf() < 0.6 else right
		L.flag = d0 == "fora"
		start_var(L, d0))

# ---------- primeiro jogo guiado ----------
const TUT := [
	{"txt": "Tu és a carica preta e amarela com o Á. Move-te com WASD ou as setas (no telemóvel, toca no campo). Aproxima-te da bola.", "until": "perto"},
	{"txt": "Boa. Quando há um lance, o jogo para e vês o momento em 3D a partir de onde estás. Perto e com bom ângulo vês melhor. Vamos ver um.", "btn": "Ver o lance", "go": "falta"},
	{"txt": "Vê o lance e decide: 1 siga, 2 falta, 3 amarelo, 4 vermelho, 5 simulação. Depois da 1.ª vez podes rever (R) e mudar de câmara (C).", "until": "feito"},
	{"txt": "O árbitro comunica a decisão aos jogadores. Nos lances no limite (falta ou amarelo, por exemplo) as duas decisões contam como certas, mas o observador vê se tens o mesmo critério o jogo todo.", "btn": "Seguinte"},
	{"txt": "Foras de jogo: vês o passe pelos olhos do assistente. Quando há dúvida, o VAR chama-te ao monitor: arrastas as linhas no relvado até às partes do corpo que contam e decides.", "btn": "Ver um fora de jogo", "go": "fora"},
	{"txt": "Arrasta as duas linhas até aos pés, ombros ou cabeça do atacante e do penúltimo defesa. Tab troca de linha, as setas afinam.", "until": "feito"},
	{"txt": "Em cima tens o controlo do jogo, a tua energia, a pressão do público e os nervos. Erros e protestos mal geridos baixam o controlo: abaixo de 10 o jogo é interrompido. Ao intervalo revês os lances da 1.ª parte.", "btn": "Seguinte"},
	{"txt": "Estás pronto. Na carreira começas nos distritais e sobes até ao Mundial. No auricular ouves o VAR, os assistentes e o 4.º árbitro.", "btn": "Ir para o menu", "go": "fim"},
]
var tut_i := -1
var tut_wait := ""
func start_tutorial() -> void:
	tut = true; tut_i = -1; lance_cd = 1e9
	tut_next()
func tut_next() -> void:
	tut_i += 1; tut_done = false
	if tut_i >= TUT.size(): return
	var st: Dictionary = TUT[tut_i]
	emit("tut", {"txt": st.txt, "step": "%d / %d" % [tut_i + 1, TUT.size()], "btn": st.get("btn", "")})
func tut_step() -> void:
	if not tut or tut_i < 0 or tut_i >= TUT.size(): return
	lance_cd = 1e9; t = minf(t, 60)
	if tut_wait == "falta" and lance.is_empty() and mode == "play": tut_done = true; tut_wait = ""
	if tut_wait == "fora" and mode == "play" and lance.is_empty(): training = {}; tut_done = true; tut_wait = ""
	var st: Dictionary = TUT[tut_i]
	var u: String = st.get("until", "")
	if u == "perto" and ref.distance_to(bp) < 13: tut_next()
	elif u == "feito" and tut_done: tut_next()
func tut_click() -> void:
	if not tut or tut_i < 0 or tut_i >= TUT.size(): return
	var go: String = TUT[tut_i].get("go", "")
	if go == "fim":
		tut = false; emit("tut_end"); return
	if go == "falta": tut_foul()
	elif go == "fora": tut_offside()
	tut_next()
func tut_foul() -> void:
	var att := _by_role(1, "st")
	var def := _by_role(0, "lcb")
	att.off = false; def.off = false
	att.p = Vector2(clamp(ref.x - 6, 8, W - 8), clamp(ref.y - 7, 6, H - 6)); att.v = Vector2(-5, 0)
	def.p = att.p + Vector2(1, 3.6)
	no_var = true
	var L := forced_lance(att, def, {"amarelo": 1}, {"tut_l": true})
	if not L.is_empty():
		L.why = ""; L.truth = "amarelo"; L.look = "amarelo"; L.adv = false; L.interp = []; L.decide_t = 30.0
	tut_wait = "falta"
func tut_offside() -> void:
	training = {"n": 0, "next": 1e9, "total": 99, "tut": true}; no_var = false
	train_offside()
	tut_wait = "fora"
