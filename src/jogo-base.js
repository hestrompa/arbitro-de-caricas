(() => {
'use strict';
// ---------- mundo (metros) ----------
const W = 105, H = 68, GOAL_W = 7.32, MARGIN = 3;
const BOX_D = 16.5, BOX_W = 40.3, SIX_D = 5.5, SIX_W = 18.3, SPOT = 11, CIRCLE = 9.15;
const MATCH_SECONDS = 300;           // 5 minutos reais = 90 minutos de jogo
const CAP_R = 1.2, G = 9.8;
const TEAMS = [
  { name: 'Azuis', color: '#3569dc', dark: '#1d3f8f', sock: '#1d3f8f', shorts: '#f1f1f1', gk: '#2fa36b', dir: 1 },
  { name: 'Laranjas', color: '#ee7d2c', dark: '#a4521a', sock: '#ee7d2c', shorts: '#23242a', gk: '#8a5bd6', dir: -1 },
];
// sistema 4-3-3
const ROLES = [
  { k: 'gk', lane: 34, line: 'g', num: 1 },
  { k: 'lb', lane: 9, line: 'd', num: 3 },
  { k: 'lcb', lane: 26, line: 'd', num: 4 },
  { k: 'rcb', lane: 42, line: 'd', num: 5 },
  { k: 'rb', lane: 59, line: 'd', num: 2 },
  { k: 'lcm', lane: 21, line: 'm', num: 8 },
  { k: 'cm', lane: 34, line: 'm', num: 6 },
  { k: 'rcm', lane: 47, line: 'm', num: 10 },
  { k: 'lw', lane: 8, line: 'f', num: 11 },
  { k: 'st', lane: 34, line: 'f', num: 9 },
  { k: 'rw', lane: 60, line: 'f', num: 7 },
];
const LABEL = { siga: 'Lance limpo', falta: 'Falta', amarelo: 'Falta para amarelo', vermelho: 'Falta para vermelho', simulacao: 'Simulação', fora: 'Fora de jogo', emjogo: 'Em jogo' };
const DEC_LABEL = { siga: 'Siga', falta: 'Falta', amarelo: 'Amarelo', vermelho: 'Vermelho', simulacao: 'Simulação', fora: 'Fora de jogo', emjogo: 'Em jogo' };
const SEV = { siga: 0, falta: 1, amarelo: 2, vermelho: 3 };

const $ = id => document.getElementById(id);
const stage = $('stage'), c2d = $('c2d'), c3d = $('c3d'), ctx = c2d.getContext('2d');
const rand = (a, b) => a + Math.random() * (b - a);
const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
const lerp = (a, b, k) => a + (b - a) * k;
const len = (x, y) => Math.hypot(x, y);
const norm = (x, y) => { const l = Math.hypot(x, y) || 1; return { x: x / l, y: y / l }; };
const rot = (v, a) => ({ x: v.x * Math.cos(a) - v.y * Math.sin(a), y: v.x * Math.sin(a) + v.y * Math.cos(a) });
const rel = (ti, x) => TEAMS[ti].dir > 0 ? x : W - x;          // distância à própria baliza
const absX = (ti, r) => TEAMS[ti].dir > 0 ? r : W - r;
function segDist(ax, ay, bx, by, px, py) {
  const vx = bx - ax, vy = by - ay, l2 = vx * vx + vy * vy || 1;
  const t = clamp(((px - ax) * vx + (py - ay) * vy) / l2, 0, 1);
  return { d: len(ax + vx * t - px, ay + vy * t - py), t };
}

// ---------- estado ----------
let S = null;
let mode = 'menu';           // menu | play | lance | fim
const keys = new Set();

function newMatch() {
  const players = [];
  TEAMS.forEach((t, ti) => ROLES.forEach((r, i) => {
    players.push({ id: ti * ROLES.length + i, team: ti, role: r.k, line: r.line, lane: r.lane, num: r.num,
      x: 0, y: r.lane, vx: 0, vy: 0, spd: rand(6.3, 7.3), yellow: 0, off: false, cd: 0, tackleCd: 0,
      down: 0, dribble: null, setPiece: false, penalty: false, mark: null, run: 0, lineOff: -1.5 });
  }));
  S = {
    players, t: 0, score: [0, 0], control: 70, stamina: 100, aggr: [0.1, 0.1],
    ball: { x: W / 2, y: H / 2, z: 0, vx: 0, vy: 0, vz: 0, owner: null, last: 0, noPick: null, noPickT: 0, target: null, penalty: false, trail: [] },
    ref: { x: W / 2, y: H / 2 + 7, tx: null, ty: null },
    pause: 0, lanceCd: 10, incidents: [], lance: null, toastT: 0, over: null, markT: 0,
    // assistentes: 0 na linha de cima cobre a metade esquerda, 1 na de baixo cobre a direita
    ast: [{ x: W / 4, y: -1.6, flagT: 0 }, { x: W * 3 / 4, y: H + 1.6, flagT: 0 }], offsides: 0,
  };
  kickoff(0);
}

function formationPos(p) {
  const r = p.line === 'g' ? 4 : p.line === 'd' ? 20 : p.line === 'm' ? 36 : 48;
  return { x: absX(p.team, r), y: p.lane };
}
function kickoff(team) {
  S.players.forEach(p => { const f = formationPos(p); p.x = f.x; p.y = f.y; p.vx = p.vy = 0; p.down = 0; p.setPiece = p.penalty = false; p.run = 0; });
  const b = S.ball; Object.assign(b, { x: W / 2, y: H / 2, z: 0, vx: 0, vy: 0, vz: 0, target: null, penalty: false, trail: [], offInfo: null });
  const taker = active().find(p => p.team === team && p.role === 'st') || active().find(p => p.team === team && p.role !== 'gk');
  taker.x = W / 2 - TEAMS[team].dir * 1.1; taker.y = H / 2;
  b.owner = taker; b.last = team; taker.cd = 0.6; S.pause = 1;
}

// ---------- utilitários de IA ----------
const active = () => S.players.filter(p => !p.off);
function nearest(list, x, y) { let best = null, d = 1e9; for (const p of list) { const dd = len(p.x - x, p.y - y); if (dd < d) { d = dd; best = p; } } return [best, d]; }
function moveTo(p, tx, ty, speed, dt) {
  const dx = tx - p.x, dy = ty - p.y, d = len(dx, dy);
  const sp = Math.min(speed, d * 2.5 + 0.3), n = norm(dx, dy);
  const k = Math.min(1, dt * 7);
  p.vx += (n.x * sp - p.vx) * k; p.vy += (n.y * sp - p.vy) * k;
  if (d < 0.25) { p.vx *= 0.8; p.vy *= 0.8; }
}
function laneOpen(ax, ay, bx, by, opps) {
  let m = 99;
  for (const q of opps) { const s = segDist(ax, ay, bx, by, q.x, q.y); if (s.t > 0.04 && s.t < 0.97) m = Math.min(m, s.d); }
  return m;
}
function ownGoalX(ti) { return TEAMS[ti].dir > 0 ? 0 : W; }
function oppGoalX(ti) { return TEAMS[ti].dir > 0 ? W : 0; }
function inOwnBox(ti, x, y) { return rel(ti, x) < BOX_D && Math.abs(y - H / 2) < BOX_W / 2; }

// linha do fora de jogo para quem ataca com a equipa ti: penúltimo adversário, nunca antes do meio-campo
function offsideLine(ti) {
  const opp = active().filter(q => q.team !== ti).map(q => rel(ti, q.x)).sort((a, b) => b - a);
  return Math.max(opp.length > 1 ? opp[1] : W, W / 2);
}
// forma da equipa: linhas que sobem e descem com a bola, laterais que sobem, extremos abertos
function shapeTarget(p, poss) {
  const b = S.ball, bx = rel(p.team, b.x), line = offsideLine(p.team);
  let d, m, f;
  if (poss) { d = clamp(bx - 30, 14, 52); m = clamp(bx - 8, d + 14, 78); f = clamp(Math.max(bx + 8, line + p.lineOff), m + 10, W - 7); }
  else { d = clamp(bx - 22, 10, 42); m = clamp(bx - 9, d + 10, 62); f = clamp(bx + 5, m + 10, 78); }
  let r = p.line === 'd' ? d : p.line === 'm' ? m : f;
  let y = p.lane;
  if (poss) {
    y = p.lane + (b.y - H / 2) * 0.25;
    if ((p.role === 'lb' || p.role === 'rb') && Math.abs(b.y - p.lane) < 26 && bx > 40) r += 16;
    if (p.role === 'lw' || p.role === 'rw') y = p.lane < H / 2 ? 6 : H - 6;
    if (p.role === 'st') y = H / 2 + (b.y - H / 2) * 0.3;
    if (p.line === 'f' && p.run > 0) r = Math.max(r, line + 6);        // desmarcação nas costas da defesa
    if (p.line === 'f') r = Math.min(r, Math.max(line + (p.run > 0 ? 6 : p.lineOff), bx + 4));
  } else {
    y = H / 2 + (p.lane - H / 2) * 0.7 + (b.y - H / 2) * 0.4;
  }
  return { x: absX(p.team, clamp(r, 3, W - 3)), y: clamp(y, 2, H - 2) };
}

function assignMarks(ti) {
  const defs = active().filter(p => p.team === ti && p.role !== 'gk');
  const atks = active().filter(p => p.team !== ti && p.role !== 'gk');
  const taken = new Set();
  const order = defs.slice().sort((a, b) => rel(ti, a.x) - rel(ti, b.x));
  for (const d of order) {
    const base = shapeTarget(d, false);
    let best = null, bd = 22;
    for (const a of atks) { if (taken.has(a)) continue; const dd = len(a.x - base.x, a.y - base.y); if (dd < bd) { bd = dd; best = a; } }
    d.mark = best; if (best) taken.add(best);
  }
}

// ---------- decisões com bola ----------
function onBall(p, dt) {
  const b = S.ball, t = TEAMS[p.team], gx = oppGoalX(p.team), gy = H / 2;
  const act = active(), opps = act.filter(q => q.team !== p.team), mates = act.filter(q => q.team === p.team && q !== p);
  const [, press] = nearest(opps, p.x, p.y);
  if (p.cd > 0 && !(press < 1.25 && p.cd > 0.2)) { // continua a conduzir
    const dir = p.dribble || norm(gx - p.x, gy - p.y);
    const sp = p.role === 'gk' ? 0 : p.spd * 0.8;
    const tx = clamp(p.x + dir.x * 3, 1.2, W - 1.2), ty = clamp(p.y + dir.y * 3, 1.2, H - 1.2);
    moveTo(p, tx, ty, sp, dt);
    return;
  }
  p.cd = rand(0.45, 0.9);
  if (p.penalty) { p.penalty = false; shoot(p, true); return; }
  const toGoal = norm(gx - p.x, gy - p.y);
  const choices = [];
  // remate
  const dg = len(gx - p.x, gy - p.y);
  if (dg < 28 && p.role !== 'gk' && !p.setPiece) {
    const ang = Math.abs(p.y - gy) / dg;
    const blk = opps.filter(q => q.role !== 'gk' && segDist(p.x, p.y, gx, gy, q.x, q.y).d < 1.1 && segDist(p.x, p.y, gx, gy, q.x, q.y).t < 0.95).length;
    choices.push({ type: 'shoot', sc: (1 - dg / 28) * 1.8 - ang * 0.7 - blk * 0.3 + rand(0, 0.35) + (inOwnBox(1 - p.team, p.x, p.y) ? 0.55 : 0) });
  }
  // passes
  const wasSetPiece = p.setPiece;
  const wide = Math.abs(p.y - H / 2) > 18 && rel(p.team, p.x) > W - 32;
  for (const m of mates) {
    const d = len(m.x - p.x, m.y - p.y);
    if (d < 4 || d > 50) continue;
    // passe em profundidade para quem vai nas costas
    if (m.run > 0 && m.role !== 'gk') {
      const tx = clamp(m.x + m.vx * 1.2, 2, W - 2), ty = clamp(m.y + m.vy * 1.2, 2, H - 2);
      const openT = laneOpen(p.x, p.y, tx, ty, opps), dT = len(tx - p.x, ty - p.y);
      if (openT > 1.2 && dT < 42) choices.push({ type: 'through', m, tx, ty, sc: 1.15 + clamp((openT - 1.2) / 3, 0, 0.4) + rand(0, 0.35) });
    }
    const open = laneOpen(p.x, p.y, m.x, m.y, opps);
    const [, sp] = nearest(opps, m.x, m.y);
    const lofted = open < 1.5 || d > 26;
    if (lofted && (d < 16 || sp < 3)) continue;           // só se mete a bola no ar para quem está livre
    const openK = lofted ? clamp(0.5 - d / 100 + (sp - 3) * 0.05, 0.1, 0.55) : clamp((open - 1.0) / 2.2, 0, 1);
    if (openK < 0.12) continue;
    const space = clamp(sp / 7, 0, 1);
    const prog = (rel(p.team, m.x) - rel(p.team, p.x)) / 24;
    let sc = openK * 0.6 + space * 0.45 + prog * 0.9 + rand(0, 0.3) - 0.25;
    if (m.role === 'gk') sc -= 0.8;
    if (press < 2.6) sc += 0.45;
    if (p.role === 'gk') sc += 0.6 - (m.line === 'd' ? 0 : 0.3);
    if (p.setPiece) sc += 1;
    const cross = wide && inOwnBox(1 - p.team, m.x, m.y);
    if (cross) sc += 0.5;
    choices.push({ type: 'pass', m, lofted: lofted || cross, sc });
  }
  // condução em 7 direções
  if (p.role !== 'gk' && !p.setPiece) {
    for (let k = -3; k <= 3; k++) {
      const dir = rot(toGoal, k * Math.PI / 6);
      const ax = p.x + dir.x * 4, ay = p.y + dir.y * 4;
      if (ax < 1.5 || ax > W - 1.5 || ay < 1.5 || ay > H - 1.5) continue;
      let pr = 0; for (const q of opps) pr += Math.max(0, 1 - len(q.x - ax, q.y - ay) / 5);
      const sc = (dir.x * t.dir) * 0.65 + (1 - Math.min(pr, 1)) * 0.75 + rand(0, 0.2) - (press < 1.9 ? 0.4 : 0) + (press > 4 ? 0.25 : 0);
      choices.push({ type: 'dribble', dir, sc });
    }
  }
  p.setPiece = false;
  if (!choices.length) { choices.push({ type: 'clear' }); }
  choices.sort((a, b) => (b.sc || 0) - (a.sc || 0));
  const c = choices[0];
  if (c.type === 'shoot') shoot(p, false);
  else if (c.type === 'pass') { passTo(p, c.m, c.lofted); if (!wasSetPiece) offsideSnap(p, c.m); }
  else if (c.type === 'through') { kick(p, c.tx, c.ty, false); S.ball.target = c.m; offsideSnap(p, c.m); }
  else if (c.type === 'dribble') { p.dribble = c.dir; }
  else { // chutão para a frente
    const tx = absX(p.team, rel(p.team, p.x) + 30), ty = H / 2 + rand(-12, 12);
    kick(p, tx, ty, true);
  }
}

function kick(p, tx, ty, lofted) {
  const b = S.ball, d = len(tx - b.x, ty - b.y), n = norm(tx - b.x, ty - b.y);
  let sp, vz = 0;
  if (lofted) { vz = clamp(3 + d * 0.16, 4, 9); const T = 2 * vz / G; sp = d / T * 0.92; }
  else sp = clamp(6 + d * 0.72, 9, 26);
  Object.assign(b, { owner: null, vx: n.x * sp, vy: n.y * sp, vz, z: Math.max(b.z, 0.05), last: p.team, noPick: p, noPickT: 0.3 });
  p.dribble = null;
}
function passTo(p, m, lofted) {
  const d = len(m.x - p.x, m.y - p.y);
  const lead = lofted ? 0.8 : d / 16;
  kick(p, m.x + m.vx * lead, m.y + m.vy * lead, lofted);
  S.ball.target = m;
}
function shoot(p, pen) {
  const b = S.ball, gx = oppGoalX(p.team) + TEAMS[p.team].dir * 1;
  const gy = H / 2 + (Math.random() < 0.5 ? -1 : 1) * rand(0.3, 1) * GOAL_W * (pen ? 0.45 : 0.62);
  const n = norm(gx - b.x, gy - b.y);
  const sp = pen ? 22 : rand(19, 26);
  Object.assign(b, { owner: null, vx: n.x * sp, vy: n.y * sp, vz: pen ? rand(0, 2.5) : rand(0, 4.2), z: 0.1, last: p.team, noPick: p, noPickT: 0.4, target: null, penalty: !!pen });
  p.dribble = null;
}

// ---------- IA por passo ----------
function aiStep(dt) {
  const b = S.ball, act = active();
  const ownerTeam = b.owner ? b.owner.team : -1;
  const possTeam = ownerTeam >= 0 ? ownerTeam : (b.target ? b.target.team : -1);
  S.markT -= dt;
  if (S.markT <= 0) { S.markT = 0.5; assignMarks(0); assignMarks(1); }
  // quem vai à bola
  const chasers = [];
  for (let ti = 0; ti < 2; ti++) {
    if (ownerTeam === ti) continue;
    if (!b.owner && b.target && b.target.team === ti && b.target.down <= 0 && !b.target.off) { chasers.push(b.target); continue; }
    const field = act.filter(p => p.team === ti && p.role !== 'gk' && p.down <= 0);
    const px = b.x + b.vx * 0.35, py = b.y + b.vy * 0.35;
    const [c] = nearest(field, px, py);
    if (c) chasers.push(c);
  }
  for (const p of act) {
    p.cd -= dt; p.tackleCd -= dt; p.run -= dt;
    if (Math.random() < dt * 0.4) p.lineOff = rand(-2.8, 0.9);        // avançados nem sempre acertam a linha
    if (p.line === 'f' && possTeam === p.team && p.run <= -1 && b.owner && b.owner !== p && Math.random() < dt * 0.35) p.run = rand(1.4, 2.2);
    if (p.down > 0) { p.down -= dt; p.vx *= 0.9; p.vy *= 0.9; continue; }
    if (b.owner === p) { if (p.role === 'gk') { p.vx *= 0.8; p.vy *= 0.8; } onBall(p, dt); continue; }
    if (chasers.includes(p)) continue;
    if (p.role === 'gk') {
      const own = ownGoalX(p.team), dist = Math.abs(b.x - own);
      const gy = clamp(H / 2 + (b.y - H / 2) * 0.35, H / 2 - GOAL_W / 2 + 0.4, H / 2 + GOAL_W / 2 - 0.4);
      const out = dist < 16 ? 1.2 + (16 - dist) * 0.08 : 3.5;
      moveTo(p, own + TEAMS[p.team].dir * out, gy, 5.5, dt);
      continue;
    }
    const poss = possTeam === p.team;
    let tg = shapeTarget(p, poss);
    if (!poss && p.mark && !p.mark.off) {
      const m = p.mark, gxo = ownGoalX(p.team), n = norm(gxo - m.x, H / 2 - m.y);
      const mx = m.x + n.x * 1.8, my = m.y + n.y * 1.8;
      if (p.line === 'd') {
        // a defesa mantém a linha; só recua se o adversário já a passou
        tg = { x: tg.x, y: lerp(tg.y, my, 0.5) };
        if (rel(p.team, m.x) < rel(p.team, tg.x) - 3) tg.x = lerp(tg.x, mx, 0.7);
      } else if (len(mx - tg.x, my - tg.y) < 18) tg = { x: lerp(tg.x, mx, 0.6), y: lerp(tg.y, my, 0.6) };
    }
    const urgent = len(tg.x - p.x, tg.y - p.y) > 6;
    moveTo(p, tg.x, tg.y, urgent ? p.spd * 0.95 : p.spd * 0.65, dt);
  }
  for (const c of chasers) {
    let px = b.x + b.vx * 0.35, py = b.y + b.vy * 0.35;
    if (!b.owner && b.target === c) {
      // vai ao encontro da bola: ponto da trajetória mais próximo
      const n = norm(b.vx, b.vy), rx = c.x - b.x, ry = c.y - b.y, along = Math.max(0, rx * n.x + ry * n.y);
      px = b.x + n.x * along * 0.8; py = b.y + n.y * along * 0.8;
    }
    if (b.owner) { px = b.owner.x + b.owner.vx * 0.3; py = b.owner.y + b.owner.vy * 0.3; }
    moveTo(c, px, py, c.spd, dt);
    if (b.owner && b.owner.team !== c.team && b.owner.role !== 'gk') {
      const d = len(c.x - b.owner.x, c.y - b.owner.y);
      if (d < 1.9 && c.tackleCd <= 0) tackle(c, b.owner);
    }
  }
}

function tackle(def, att) {
  def.tackleCd = rand(0.7, 1.3);
  if (Math.random() > 0.5) return;                       // não chega à bola
  const ag = S.aggr[def.team];
  if (S.lanceCd <= 0 && Math.random() < 0.3 + ag * 0.4) { startLance(att, def); return; }
  S.ball.owner = def; S.ball.last = def.team; S.ball.target = null; def.cd = 0.3; att.down = 0.35; def.dribble = null;
}

// ---------- física ----------
function physics(dt) {
  const b = S.ball, act = active();
  for (const p of act) { p.x += p.vx * dt; p.y += p.vy * dt; }
  for (let i = 0; i < act.length; i++) for (let j = i + 1; j < act.length; j++) {
    const a = act[i], c = act[j], dx = c.x - a.x, dy = c.y - a.y, d = len(dx, dy);
    if (d < 1.6 && d > 0.001) { const push = (1.6 - d) / 2, n = norm(dx, dy); a.x -= n.x * push; a.y -= n.y * push; c.x += n.x * push; c.y += n.y * push; }
  }
  for (const p of act) { p.x = clamp(p.x, -1.5, W + 1.5); p.y = clamp(p.y, -1.5, H + 1.5); }
  if (b.owner) {
    const o = b.owner, n = len(o.vx, o.vy) > 0.4 ? norm(o.vx, o.vy) : norm(oppGoalX(o.team) - o.x, H / 2 - o.y);
    b.x = o.x + n.x * 1.0; b.y = o.y + n.y * 1.0; b.z = 0; b.vx = o.vx; b.vy = o.vy; b.vz = 0; b.offInfo = null;
    return;
  }
  if (dt <= 0) return;
  b.x += b.vx * dt; b.y += b.vy * dt;
  if (b.z > 0 || b.vz > 0) {
    b.z += b.vz * dt; b.vz -= G * dt;
    if (b.z <= 0) { b.z = 0; b.vz = Math.abs(b.vz) > 1.5 ? -b.vz * 0.45 : 0; }
  }
  const f = Math.exp((b.z > 0.05 ? -0.15 : -0.7) * dt); b.vx *= f; b.vy *= f;
  const sp = len(b.vx, b.vy);
  if (sp > 6) { b.trail.push({ x: b.x, y: b.y }); if (b.trail.length > 10) b.trail.shift(); } else if (b.trail.length) b.trail.shift();
  if (b.noPickT > 0) b.noPickT -= dt; else b.noPick = null;
  // saída
  if (b.y < 0 || b.y > H) { throwIn(); return; }
  if (b.x < 0 || b.x > W) {
    const side = b.x < 0 ? 0 : 1;              // 0 = baliza dos Azuis
    if (Math.abs(b.y - H / 2) < GOAL_W / 2 && b.z < 2.4) { goal(1 - side); return; }
    if (b.last === side) corner(1 - side, b.y < H / 2 ? 0.5 : H - 0.5); else goalKick(side);
    return;
  }
  // recuperar bola (guarda-redes defende)
  let best = null, bd = 1e9;
  for (const p of act) {
    if (p === b.noPick || p.down > 0) continue;
    const d = len(p.x - b.x, p.y - b.y);
    const gk = p.role === 'gk' && inOwnBox(p.team, p.x, p.y);
    const reach = gk ? 1.9 : p.team === b.last ? (sp > 17 ? 0.8 : 1.3) : (sp > 17 ? 0.5 : sp > 9 ? 0.7 : 1.1);
    const zOk = gk ? b.z < 2.6 : b.z < 1.5;
    if (zOk && d < reach && d < bd) { bd = d; best = p; }
  }
  if (!best) return;
  const oi = b.offInfo; b.offInfo = null;
  if (oi && best.id === oi.receiver && oi.margin > -1.0 && !best.off) {
    if (oi.margin > 1.2) { flagOffside(oi); return; }
    if (S.lanceCd <= 0) { startOffside(oi); return; }
    if (assistantCall(oi)) { flagOffside(oi); return; }
  }
  if (best.role === 'gk' && sp > 12 && b.last !== best.team) {
    const saveP = b.penalty ? 0.28 : clamp(0.95 - (sp - 12) * 0.03, 0.55, 0.9);
    if (Math.random() > saveP) { b.noPick = best; b.noPickT = 0.5; return; }          // passa pelo guarda-redes
    if (sp > 20 && Math.random() < 0.45) {                                                 // defende para o lado
      const n = norm(-b.vx * 0.3, (Math.random() < 0.5 ? -1 : 1) * 8);
      Object.assign(b, { vx: n.x * 9 + TEAMS[best.team].dir * 3, vy: n.y * 9, vz: 2, noPick: best, noPickT: 0.4, last: best.team, penalty: false });
      toast('Defesa do guarda-redes', 1.2);
      return;
    }
  }
  b.owner = best; b.last = best.team; b.target = null; b.penalty = false; b.trail = [];
  best.cd = best.role === 'gk' ? rand(0.9, 1.4) : rand(0.7, 1.4); best.dribble = null;
}

function throwIn() {
  const b = S.ball, team = 1 - b.last;
  const x = clamp(b.x, 1, W - 1), y = b.y < 0 ? -0.4 : H + 0.4;
  const [p] = nearest(active().filter(q => q.team === team && q.role !== 'gk'), x, y);
  Object.assign(b, { vx: 0, vy: 0, vz: 0, z: 0, target: null, trail: [], offInfo: null });
  if (p) { p.x = x; p.y = y; p.vx = p.vy = 0; b.owner = p; p.cd = 0.7; p.setPiece = true; }
  S.pause = 0.7;
}
function goalKick(side) {
  const b = S.ball, gk = active().find(p => p.team === side && p.role === 'gk');
  Object.assign(b, { vx: 0, vy: 0, vz: 0, z: 0, target: null, trail: [], offInfo: null });
  if (gk) { gk.x = side === 0 ? 3 : W - 3; gk.y = H / 2; b.owner = gk; gk.cd = 1.2; gk.setPiece = true; }
  S.pause = 0.9;
}
function corner(team, y) {
  const b = S.ball, x = TEAMS[team].dir > 0 ? W - 0.5 : 0.5;
  const [p] = nearest(active().filter(q => q.team === team && q.role !== 'gk'), x, y);
  Object.assign(b, { x, y, vx: 0, vy: 0, vz: 0, z: 0, target: null, trail: [], offInfo: null });
  if (p) { p.x = x + (x < 1 ? -0.6 : 0.6); p.y = y; b.owner = p; p.cd = 1.1; p.setPiece = true; }
  toast('Canto para os ' + TEAMS[team].name, 1.4);
  S.pause = 1.1;
}
function goal(team) {
  S.score[team]++;
  $('s' + team).textContent = S.score[team];
  toast('Golo dos ' + TEAMS[team].name + '!', 2.2);
  kickoff(1 - team);
  S.pause = 2.2;
}

// ---------- fora de jogo ----------
function offsideSnap(p, m) {
  const ti = p.team, b = S.ball;
  const opps = active().filter(q => q.team !== ti).sort((a, c) => rel(ti, c.x) - rel(ti, a.x));
  const lineDef = opps[1] || opps[0];
  const lineRel = Math.max(lineDef ? rel(ti, lineDef.x) : W, W / 2), ballRel = rel(ti, b.x), recvRel = rel(ti, m.x);
  const margin = recvRel - Math.max(lineRel, ballRel);                  // > 0 = fora de jogo
  const a = S.ast[TEAMS[ti].dir > 0 ? 1 : 0];
  b.offInfo = { passer: p.id, receiver: m.id, team: ti, margin, lineX: absX(ti, Math.max(lineRel, ballRel)), recvX: m.x, recvY: m.y,
    lineDef: lineDef ? lineDef.id : null, ast: { x: a.x, y: a.y }, ball: { x: b.x, y: b.y },
    snap: active().map(q => ({ id: q.id, team: q.team, role: q.role, x: q.x, y: q.y, vx: q.vx, vy: q.vy })), minute: Math.min(90, Math.floor(S.t / MATCH_SECONDS * 90) + 1) };
}
function assistantCall(oi) {
  const mis = Math.abs(oi.ast.x - oi.lineX);
  const acc = clamp((Math.abs(oi.margin) > 0.5 ? 0.92 : 0.7) - Math.min(0.3, mis * 0.05), 0.5, 0.95);
  const truth = oi.margin > 0;
  return Math.random() < acc ? truth : !truth;
}
function flagOffside(oi) {
  const b = S.ball, defT = 1 - oi.team;
  S.ast[TEAMS[oi.team].dir > 0 ? 1 : 0].flagT = 1.8;
  const x = clamp(oi.recvX, 1, W - 1), y = clamp(oi.recvY, 1, H - 1);
  const [p] = nearest(active().filter(q => q.team === defT && q.role !== 'gk'), x, y);
  Object.assign(b, { x, y, z: 0, vx: 0, vy: 0, vz: 0, target: null, trail: [], offInfo: null });
  if (p) { p.x = x - TEAMS[defT].dir * 0.8; p.y = y; b.owner = p; b.last = defT; p.cd = 0.9; p.setPiece = true; }
  S.offsides++;
  toast('Fora de jogo: bandeira do assistente', 1.8);
  S.pause = 1.2;
}
function astStep(dt) {
  const b = S.ball;
  S.ast.forEach((a, i) => {
    // assistente 0 acompanha a linha dos Azuis (metade esquerda), 1 a dos Laranjas
    const defT = i === 0 ? 0 : 1, attT = 1 - defT;
    const lineX = absX(attT, offsideLine(attT));
    let tx = i === 0 ? Math.min(lineX, b.x) : Math.max(lineX, b.x);
    tx = i === 0 ? clamp(tx, 0.5, W / 2) : clamp(tx, W / 2, W - 0.5);
    const d = tx - a.x;
    a.x += clamp(d * 3, -7.5, 7.5) * dt;
    if (a.flagT > 0) a.flagT -= dt;
  });
}
function startOffside(oi) {
  S.lanceCd = rand(11, 16);
  const mis = Math.abs(oi.ast.x - oi.lineX);
  const flag = assistantCall(oi);
  S.lance = { kind: 'offside', oi, truth: oi.margin > 0 ? 'fora' : 'emjogo', flag, mis, dist: mis, clarity: clamp(1 - mis / 6, 0.1, 1),
    distScore: 1, minute: oi.minute, ref: { x: S.ref.x, y: S.ref.y }, time: 0, speed: 1, replays: 0, decideT: 12, decided: null, cam: null, ideal: false, dur: 1.3,
    att: { id: oi.receiver, team: oi.team }, def: { id: oi.lineDef, team: 1 - oi.team } };
  mode = 'lance';
  $('flash').textContent = 'Fora de jogo?';
  $('flash').hidden = false;
  S.players.forEach(p => { p.vx *= 0.2; p.vy *= 0.2; });
  setTimeout(() => { $('flash').hidden = true; $('flash').textContent = 'Lance!'; if (mode === 'lance') show3D(S.lance, false); }, 650);
}

// ---------- árbitro ----------
function refStep(dt) {
  const r = S.ref;
  let dx = 0, dy = 0;
  if (keys.has('ArrowLeft') || keys.has('a')) dx -= 1;
  if (keys.has('ArrowRight') || keys.has('d')) dx += 1;
  if (keys.has('ArrowUp') || keys.has('w')) dy -= 1;
  if (keys.has('ArrowDown') || keys.has('s')) dy += 1;
  const sprint = keys.has('Shift') && S.stamina > 1;
  if (dx || dy) r.tx = null;
  else if (r.tx !== null) { dx = r.tx - r.x; dy = r.ty - r.y; if (len(dx, dy) < 0.3) { r.tx = null; dx = dy = 0; } }
  const moving = dx || dy;
  const speed = sprint && moving ? 8.6 : 6;
  if (moving) { const n = norm(dx, dy); r.x += n.x * speed * dt; r.y += n.y * speed * dt; }
  r.x = clamp(r.x, -2, W + 2); r.y = clamp(r.y, -2, H + 2);
  S.stamina = clamp(S.stamina + (sprint && moving ? -16 : (moving ? 3 : 7)) * dt, 0, 100);
}

// ---------- lance ----------
const TC = 2.2, DUR = 4.3;
function startLance(att, def) {
  S.lanceCd = rand(11, 16);
  const ag = S.aggr[def.team];
  const wts = { siga: 0.24, falta: 0.34, amarelo: 0.2 * (1 + ag * 2), vermelho: 0.06 * (1 + ag * 3), simulacao: 0.16 };
  let r = Math.random() * Object.values(wts).reduce((a, b) => a + b, 0), truth = 'siga';
  for (const [k, w] of Object.entries(wts)) { r -= w; if (r <= 0) { truth = k; break; } }
  const toGoal = norm(oppGoalX(att.team) - att.x, H / 2 - att.y);
  const mv = len(att.vx, att.vy) > 0.5 ? norm(att.vx, att.vy) : toGoal;
  const A = norm(mv.x * 0.7 + toGoal.x * 0.3, mv.y * 0.7 + toGoal.y * 0.3);
  const phiDeg = { siga: rand(115, 160), falta: rand(75, 115), amarelo: rand(40, 75), vermelho: rand(5, 30), simulacao: rand(85, 135) }[truth];
  const side = (A.x * (def.y - att.y) - A.y * (def.x - att.x)) > 0 ? 1 : -1;
  const D = rot(A, -side * phiDeg * Math.PI / 180);      // direção da corrida do defesa
  const P = { x: att.x, y: att.y };
  const ref = { x: S.ref.x, y: S.ref.y };
  const others = active().filter(p => p !== att && p !== def && len(p.x - P.x, p.y - P.y) < 38)
    .map(p => ({ id: p.id, team: p.team, role: p.role, num: p.num, x: p.x, y: p.y, vx: p.vx, vy: p.vy }));
  const dist = len(P.x - ref.x, P.y - ref.y);
  const distScore = clamp(1 - (dist - 8) / 28, 0.1, 1);
  const view = norm(P.x - ref.x, P.y - ref.y);
  const angleScore = 0.55 + 0.45 * Math.abs(view.x * D.y - view.y * D.x);
  let blockers = 0;
  for (const o of others) {
    const px = o.x - ref.x, py = o.y - ref.y, proj = px * view.x + py * view.y;
    if (proj <= 0.6 || proj >= dist - 1) continue;
    if (Math.abs(px * view.y - py * view.x) < 0.85) blockers++;
  }
  const clarity = clamp(distScore * angleScore * (1 - 0.3 * blockers), 0.05, 1);
  const minute = Math.min(90, Math.floor(S.t / MATCH_SECONDS * 90) + 1);
  const fall = truth !== 'siga' || Math.random() < 0.6;
  const inBox = inOwnBox(def.team, P.x, P.y);
  S.lance = { att: { id: att.id, team: att.team, num: att.num, role: att.role }, def: { id: def.id, team: def.team, num: def.num, role: def.role },
    truth, P, A, D, ref, others, dist, distScore, blockers, clarity, minute, fall, inBox,
    time: 0, speed: 1, replays: 0, decideT: 12, decided: null, cam: null, ideal: false };
  mode = 'lance';
  att.vx = att.vy = def.vx = def.vy = 0;
  $('flash').hidden = false;
  setTimeout(() => { $('flash').hidden = true; if (mode === 'lance') show3D(S.lance, false); }, 600);
}

function showDecide(on) {
  $('decide').hidden = !on;
  const off = !!(S && S.lance && S.lance.kind === 'offside');
  document.querySelectorAll('.foul-choice').forEach(b => b.hidden = off);
  document.querySelectorAll('.off-choice').forEach(b => b.hidden = !off);
  document.querySelectorAll('.choice').forEach(b => b.disabled = !on);
  $('replayBtn').disabled = !on || (S.lance && S.lance.replays >= 2);
}

function decide(d, timedOut) {
  const L = S.lance;
  if (mode !== 'lance' || !L || L.decided) return;
  L.decided = d; L.timedOut = !!timedOut;
  if (L.kind === 'offside') { decideOffside(L, d, timedOut); return; }
  let pts = 0, dc = 0;
  const atkT = L.att.team, defT = L.def.team;
  if (L.truth === 'simulacao') {
    if (d === 'simulacao') { pts = 1; dc = 4; }
    else if (d === 'siga') { pts = 0.4; dc = -3; }
    else { pts = 0; dc = -10; S.aggr[defT] += 0.25; }
  } else if (d === 'simulacao') {
    pts = 0; dc = -11; S.aggr[atkT] += 0.3;
  } else {
    const diff = SEV[d] - SEV[L.truth];
    if (diff === 0) { pts = 1; dc = 4; }
    else if (Math.abs(diff) === 1) { pts = 0.4; dc = -5; }
    else { pts = 0; dc = -12; }
    if (diff < 0) S.aggr[atkT] += 0.12 * -diff;
    if (diff > 0) S.aggr[defT] += 0.12 * diff;
  }
  if (timedOut) dc -= 4;
  S.control = clamp(S.control + dc, 0, 100);
  L.pts = pts;
  S.incidents.push(L);
  const att = S.players[L.att.id], def = S.players[L.def.id], b = S.ball;
  let msg = '';
  const foul = d === 'falta' || d === 'amarelo' || d === 'vermelho';
  if (foul) {
    if (d === 'amarelo') { def.yellow++; msg = 'Amarelo ao ' + def.num + ' dos ' + TEAMS[def.team].name; if (def.yellow >= 2) { def.off = true; msg = 'Segundo amarelo: ' + def.num + ' dos ' + TEAMS[def.team].name + ' expulso'; } }
    else if (d === 'vermelho') { def.off = true; msg = 'Vermelho direto ao ' + def.num + ' dos ' + TEAMS[def.team].name; }
    if (L.inBox) penalty(att);
    else {
      b.owner = att; b.last = att.team; att.cd = 0.9; att.setPiece = true; b.target = null;
      active().forEach(p => { if (p.team !== att.team) { const dd = len(p.x - att.x, p.y - att.y); if (dd < 6) { const n = norm(p.x - att.x, p.y - att.y); p.x = att.x + n.x * 6; p.y = att.y + n.y * 6; } } });
      if (!msg) msg = 'Livre para os ' + TEAMS[att.team].name;
    }
    if (L.inBox) msg = (msg ? msg + ' · ' : '') + 'Penálti para os ' + TEAMS[att.team].name;
  } else if (d === 'simulacao') {
    att.yellow++; b.owner = def; b.last = def.team; def.cd = 0.8; b.target = null;
    msg = 'Amarelo por simulação ao ' + att.num + ' dos ' + TEAMS[att.team].name;
    if (att.yellow >= 2) { att.off = true; msg = 'Segundo amarelo: ' + att.num + ' dos ' + TEAMS[att.team].name + ' expulso'; }
  } else {
    b.owner = def; b.last = def.team; def.cd = 0.5; b.target = null; if (L.fall) att.down = 1.2;
    msg = timedOut ? 'Hesitaste: o jogo seguiu' : 'Siga o jogo';
  }
  if (b.owner && b.owner.off) { const [p] = nearest(active().filter(q => q.team === b.owner.team), b.x, b.y); b.owner = p || null; }
  if (dc <= -10) msg += ' · protestos em campo';
  hide3D(); showDecide(false); toast(msg, 2.6);
  mode = 'play'; S.pause = Math.max(S.pause, 1.2);
  if (S.control <= 10) endMatch('abandonado');
}

function decideOffside(L, d, timedOut) {
  const ok = (d === 'fora') === (L.truth === 'fora');
  L.pts = ok ? 1 : 0;
  let dc = ok ? 3 : -7;
  if (timedOut) dc -= 4;
  if (!ok) S.aggr[d === 'fora' ? L.oi.team : 1 - L.oi.team] += 0.2;
  S.control = clamp(S.control + dc, 0, 100);
  S.incidents.push(L);
  let msg;
  if (d === 'fora') { flagOffside(L.oi); msg = 'Fora de jogo: livre para os ' + TEAMS[1 - L.oi.team].name; }
  else {
    const r = S.players[L.oi.receiver], b = S.ball;
    b.owner = r; b.last = r.team; b.target = null; r.cd = 0.4;
    msg = timedOut ? 'Hesitaste: o jogo seguiu' : 'Em jogo, siga';
  }
  if (!ok && !timedOut) msg += ' · protestos em campo';
  hide3D(); showDecide(false); toast(msg, 2.4);
  mode = 'play'; S.pause = Math.max(S.pause, 1);
  if (S.control <= 10) endMatch('abandonado');
}

function penalty(att) {
  const team = att.team, dir = TEAMS[team].dir, spotX = oppGoalX(team) - dir * SPOT;
  const taker = att.off ? active().find(p => p.team === team && p.role === 'st') || active().find(p => p.team === team && p.role !== 'gk') : att;
  active().forEach(p => {
    if (p.role === 'gk' && p.team !== team) { p.x = oppGoalX(team) - dir * 0.6; p.y = H / 2; return; }
    if (p === taker) return;
    if (inOwnBox(1 - team, p.x, p.y) || len(p.x - spotX, p.y - H / 2) < 9) { p.x = oppGoalX(team) - dir * (BOX_D + rand(1, 4)); p.y = H / 2 + rand(-10, 10); }
  });
  const b = S.ball;
  taker.x = spotX - dir * 1.2; taker.y = H / 2; taker.vx = taker.vy = 0;
  Object.assign(b, { x: spotX, y: H / 2, z: 0, vx: 0, vy: 0, vz: 0, owner: taker, last: team, target: null, offInfo: null });
  taker.cd = 1.8; taker.penalty = true;
  S.pause = 1.8;
}

// ---------- 3D ----------
let R3 = null;
function pitchCanvas(pxPerM) {
  const cv = document.createElement('canvas');
  cv.width = Math.round((W + 2 * MARGIN) * pxPerM); cv.height = Math.round((H + 2 * MARGIN) * pxPerM);
  drawPitch(cv.getContext('2d'), MARGIN * pxPerM, MARGIN * pxPerM, pxPerM, cv.width, cv.height);
  return cv;
}
function drawPitch(g, ox, oy, s, cw, ch) {
  g.fillStyle = '#2d7a3a'; g.fillRect(0, 0, cw, ch);
  const stripes = 18;
  for (let i = 0; i < stripes; i += 2) { g.fillStyle = '#296f35'; g.fillRect(ox + i * W / stripes * s, 0, W / stripes * s, ch); }
  g.strokeStyle = 'rgba(245,247,238,.92)'; g.lineWidth = Math.max(1.5, 0.12 * s);
  const X = x => ox + x * s, Y = y => oy + y * s;
  g.strokeRect(X(0), Y(0), W * s, H * s);
  g.beginPath(); g.moveTo(X(W / 2), Y(0)); g.lineTo(X(W / 2), Y(H)); g.stroke();
  g.beginPath(); g.arc(X(W / 2), Y(H / 2), CIRCLE * s, 0, Math.PI * 2); g.stroke();
  g.fillStyle = 'rgba(245,247,238,.92)';
  for (const side of [0, 1]) {
    const x0 = side ? W : 0, dir = side ? -1 : 1;
    g.strokeRect(X(Math.min(x0, x0 + dir * BOX_D)), Y(H / 2 - BOX_W / 2), BOX_D * s, BOX_W * s);
    g.strokeRect(X(Math.min(x0, x0 + dir * SIX_D)), Y(H / 2 - SIX_W / 2), SIX_D * s, SIX_W * s);
    g.beginPath(); g.arc(X(x0 + dir * SPOT), Y(H / 2), 0.2 * s, 0, Math.PI * 2); g.fill();
    const a = Math.acos((BOX_D - SPOT) / CIRCLE);
    g.beginPath(); g.arc(X(x0 + dir * SPOT), Y(H / 2), CIRCLE * s, dir > 0 ? -a : Math.PI - a, dir > 0 ? a : Math.PI + a); g.stroke();
    for (const cy of [0, H]) { g.beginPath(); g.arc(X(x0), Y(cy), 1 * s, 0, Math.PI * 2); g.stroke(); }
  }
  g.beginPath(); g.arc(X(W / 2), Y(H / 2), 0.2 * s, 0, Math.PI * 2); g.fill();
}

function init3D() {
  if (R3) return R3;
  if (!window.THREE) return null;
  const T = window.THREE;
  const renderer = new T.WebGLRenderer({ canvas: c3d, antialias: true });
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = T.PCFSoftShadowMap;
  const scene = new T.Scene();
  scene.background = new T.Color('#0f1728');
  scene.fog = new T.Fog('#56657a', 30, 140);
  const cam = new T.PerspectiveCamera(40, 1.5, 0.1, 300);
  scene.add(new T.HemisphereLight(0xf4f6ff, 0x2c4a24, 0.8));
  const sun = new T.DirectionalLight(0xffffff, 0.85);
  sun.position.set(W / 2 - 22, 55, H / 2 - 30); sun.target.position.set(W / 2, 0, H / 2);
  sun.castShadow = true; sun.shadow.mapSize.set(2048, 2048);
  Object.assign(sun.shadow.camera, { left: -70, right: 70, top: 50, bottom: -50, near: 1, far: 160 });
  scene.add(sun, sun.target);
  const tex = new T.CanvasTexture(pitchCanvas(22));
  tex.anisotropy = renderer.capabilities.getMaxAnisotropy();
  const pitch = new T.Mesh(new T.PlaneGeometry(W + 2 * MARGIN, H + 2 * MARGIN), new T.MeshLambertMaterial({ map: tex }));
  pitch.rotation.x = -Math.PI / 2; pitch.position.set(W / 2, 0, H / 2); pitch.receiveShadow = true; scene.add(pitch);
  const outer = new T.Mesh(new T.PlaneGeometry(240, 220), new T.MeshLambertMaterial({ color: '#23592c' }));
  outer.rotation.x = -Math.PI / 2; outer.position.set(W / 2, -0.02, H / 2); scene.add(outer);
  const crowd = document.createElement('canvas'); crowd.width = 512; crowd.height = 128;
  const cg = crowd.getContext('2d'); cg.fillStyle = '#1b2230'; cg.fillRect(0, 0, 512, 128);
  const cols = ['#3569dc', '#ee7d2c', '#e8e8e8', '#c9a15a', '#5b6475', '#2a3140'];
  for (let i = 0; i < 1500; i++) { cg.fillStyle = cols[i % cols.length]; cg.fillRect(Math.random() * 512, Math.random() * 128, 3, 4); }
  const crowdTex = new T.CanvasTexture(crowd); crowdTex.wrapS = T.RepeatWrapping; crowdTex.repeat.set(4, 1);
  const boardMat = [new T.MeshLambertMaterial({ color: '#f2cf3a' }), new T.MeshLambertMaterial({ color: '#1f3b7a' })];
  const standMat = new T.MeshLambertMaterial({ map: crowdTex });
  const addWall = (x, z, w, d, rotY) => {
    const n = Math.round(w / 6);
    for (let i = 0; i < n; i++) {
      const bd = new T.Mesh(new T.BoxGeometry(w / n - 0.2, 0.9, 0.15), boardMat[i % 2]);
      const off = -w / 2 + (i + 0.5) * w / n;
      bd.position.set(x + Math.cos(rotY) * off, 0.45, z - Math.sin(rotY) * off); bd.rotation.y = rotY; scene.add(bd);
    }
    const st = new T.Mesh(new T.BoxGeometry(w + 14, 12, 1), standMat);
    st.position.set(x + Math.sin(rotY) * -d, 5, z + Math.cos(rotY) * -d); st.rotation.y = rotY; scene.add(st);
  };
  addWall(W / 2, -5, W + 10, 8, 0);
  addWall(W / 2, H + 5, W + 10, -8, 0);
  addWall(-5, H / 2, H + 10, -8, Math.PI / 2);
  addWall(W + 5, H / 2, H + 10, 8, Math.PI / 2);
  const postMat = new T.MeshLambertMaterial({ color: '#ffffff' });
  for (const gx of [0, W]) {
    for (const s of [-1, 1]) { const p = new T.Mesh(new T.CylinderGeometry(0.07, 0.07, 2.2, 10), postMat); p.position.set(gx, 1.1, H / 2 + s * GOAL_W / 2); p.castShadow = true; scene.add(p); }
    const bar = new T.Mesh(new T.CylinderGeometry(0.07, 0.07, GOAL_W, 10), postMat); bar.rotation.x = Math.PI / 2; bar.position.set(gx, 2.2, H / 2); scene.add(bar);
    const net = new T.Mesh(new T.PlaneGeometry(GOAL_W, 2.2), new T.MeshLambertMaterial({ color: '#ffffff', transparent: true, opacity: 0.22, side: T.DoubleSide }));
    net.rotation.y = Math.PI / 2; net.position.set(gx + (gx ? 1.5 : -1.5), 1.1, H / 2); scene.add(net);
  }
  const rigs = [];
  for (let i = 0; i < 22; i++) { const r = makeRig(T); rigs.push(r); scene.add(r.outer); }
  // linhas do vídeo-árbitro para a revisão do fora de jogo
  const strip = col => { const m = new T.Mesh(new T.PlaneGeometry(0.12, H), new T.MeshBasicMaterial({ color: col, transparent: true, opacity: 0.85 })); m.rotation.x = -Math.PI / 2; m.position.set(0, 0.02, H / 2); m.visible = false; scene.add(m); return m; };
  const lines = { def: strip('#39d0ff'), att: strip('#ff4d6d') };
  const ballTex = document.createElement('canvas'); ballTex.width = 128; ballTex.height = 64;
  const bg = ballTex.getContext('2d'); bg.fillStyle = '#fbfbf5'; bg.fillRect(0, 0, 128, 64); bg.fillStyle = '#222';
  for (let i = 0; i < 6; i++) { bg.beginPath(); bg.arc(10 + i * 22, i % 2 ? 18 : 44, 7, 0, Math.PI * 2); bg.fill(); }
  const ball = new T.Mesh(new T.SphereGeometry(0.22, 18, 14), new T.MeshLambertMaterial({ map: new T.CanvasTexture(ballTex) }));
  ball.castShadow = true; scene.add(ball);
  R3 = { T, renderer, scene, cam, rigs, ball, sun, lines };
  return R3;
}

function makeRig(T) {
  const outer = new T.Group(), body = new T.Group(); outer.add(body);
  const shirt = new T.MeshLambertMaterial({ color: '#3569dc' });
  const shorts = new T.MeshLambertMaterial({ color: '#f1f1f1' });
  const sock = new T.MeshLambertMaterial({ color: '#1d3f8f' });
  const tones = ['#f1c7a5', '#c98e62', '#8d5a3b', '#e7b58c', '#5e3b26'];
  const skin = new T.MeshLambertMaterial({ color: tones[Math.floor(Math.random() * tones.length)] });
  const hairCols = ['#1b1b1b', '#5a3a1e', '#c9a15a', '#2a1a10'];
  const hair = new T.MeshLambertMaterial({ color: hairCols[Math.floor(Math.random() * hairCols.length)] });
  const boot = new T.MeshLambertMaterial({ color: '#141414' });
  const add = (geo, mat, x, y, z, parent) => { const m = new T.Mesh(geo, mat); m.position.set(x, y, z); m.castShadow = true; parent.add(m); return m; };
  add(new T.CylinderGeometry(0.31, 0.25, 0.7, 14), shirt, 0, 1.24, 0, body);
  add(new T.CylinderGeometry(0.27, 0.29, 0.28, 14), shorts, 0, 0.9, 0, body);
  add(new T.SphereGeometry(0.35, 20, 16), skin, 0, 1.93, 0, body);
  add(new T.SphereGeometry(0.36, 20, 10, 0, Math.PI * 2, 0, Math.PI / 2.4), hair, 0, 1.97, -0.02, body);
  add(new T.SphereGeometry(0.06, 8, 6), boot, -0.12, 1.98, 0.31, body);
  add(new T.SphereGeometry(0.06, 8, 6), boot, 0.12, 1.98, 0.31, body);
  add(new T.SphereGeometry(0.095, 8, 6), skin, 0, 1.88, 0.35, body);
  const leg = x => {
    const hip = new T.Group(); hip.position.set(x, 0.88, 0); body.add(hip);
    add(new T.CylinderGeometry(0.11, 0.09, 0.44, 10), shorts, 0, -0.2, 0, hip);
    const knee = new T.Group(); knee.position.set(0, -0.44, 0); hip.add(knee);
    add(new T.CylinderGeometry(0.085, 0.07, 0.42, 10), sock, 0, -0.21, 0, knee);
    add(new T.BoxGeometry(0.15, 0.11, 0.31), boot, 0, -0.44, 0.07, knee);
    return { hip, knee };
  };
  const arm = x => {
    const sh = new T.Group(); sh.position.set(x, 1.52, 0); body.add(sh);
    add(new T.CylinderGeometry(0.075, 0.065, 0.56, 10), shirt, 0, -0.28, 0, sh);
    add(new T.SphereGeometry(0.08, 8, 6), skin, 0, -0.6, 0, sh);
    return sh;
  };
  const L = leg(-0.14), R = leg(0.14);
  return { outer, body, hipL: L.hip, kneeL: L.knee, hipR: R.hip, kneeR: R.knee, armL: arm(-0.41), armR: arm(0.41), shirt, shorts, sock };
}
function styleRig(r, team, role) {
  if (team < 0) { r.shirt.color.set('#15161a'); r.shorts.color.set('#15161a'); r.sock.color.set('#15161a'); return; }
  const t = TEAMS[team];
  r.shirt.color.set(role === 'gk' ? t.gk : t.color); r.shorts.color.set(t.shorts); r.sock.color.set(role === 'gk' ? t.gk : t.dark);
}
function placeRig(r, x, y, fx, fy) { r.outer.position.set(x, 0, y); r.outer.rotation.y = Math.atan2(fx, fy); }
function setPose(r, o) {
  r.hipL.rotation.set(o.hl || 0, 0, o.hlz || 0); r.kneeL.rotation.x = o.kl || 0;
  r.hipR.rotation.set(o.hr || 0, 0, o.hrz || 0); r.kneeR.rotation.x = o.kr || 0;
  r.armL.rotation.set(o.al || 0, 0, o.alz === undefined ? -0.12 : o.alz);
  r.armR.rotation.set(o.ar || 0, 0, o.arz === undefined ? 0.12 : o.arz);
  r.body.rotation.set(o.pitch || 0, 0, o.roll || 0); r.body.position.y = o.y || 0;
}
function runPose(ph, amp) {
  const s = Math.sin(ph);
  return { hl: -s * amp, hr: s * amp, kl: Math.max(0, Math.sin(ph + 1.3)) * amp * 1.7, kr: Math.max(0, Math.sin(ph + 1.3 + Math.PI)) * amp * 1.7,
    al: s * amp * 0.9, ar: -s * amp * 0.9, pitch: 0.12 * amp, y: -Math.abs(Math.cos(ph)) * 0.04 * amp };
}
const smooth = k => k <= 0 ? 0 : k >= 1 ? 1 : k * k * (3 - 2 * k);

function show3D(L, review) {
  const R = init3D();
  if (!R) { $('capL').textContent = 'Sem 3D: não foi possível carregar o motor gráfico'; $('cap3d').hidden = false; if (!review) showDecide(true); return; }
  L.time = 0; L.speed = review ? 0.5 : 1; L.cam = null;
  R.rigs.forEach(r => r.outer.visible = false);
  R.lines.def.visible = R.lines.att.visible = false;
  if (L.kind === 'offside') {
    const oi = L.oi, cx = (oi.lineX + oi.recvX) / 2;
    const near = oi.snap.filter(q => q.id === oi.receiver || q.id === oi.lineDef || q.id === oi.passer || len(q.x - cx, q.y - oi.recvY) < 30)
      .sort((a, c) => (a.id === oi.receiver || a.id === oi.lineDef || a.id === oi.passer ? -1 : 0) - (c.id === oi.receiver || c.id === oi.lineDef || c.id === oi.passer ? -1 : 0)).slice(0, 21);
    L.rig = { list: near.map((q, i) => { const r = R.rigs[i]; styleRig(r, q.team, q.role); r.outer.visible = true; return { r, q, ph: Math.random() * 6 }; }), ref: R.rigs[21] };
    L.review = review;
    $('toast').hidden = true;
    resize3D();
    stage.classList.add('view3d');
    $('cap3d').hidden = false; $('viewBtns').hidden = !review;
    captions3D(L);
    if (!review) { $('decideMsg').textContent = 'Passe aos ' + L.minute + "'. Bandeira " + (L.flag ? 'levantada' : 'em baixo') + '. O recetor estava em jogo?'; showDecide(true); }
    pose3D(L, 0);
    return;
  }
  const a = R.rigs[0], d = R.rigs[1], ref = R.rigs[21];
  styleRig(a, L.att.team, L.att.role); styleRig(d, L.def.team, L.def.role); styleRig(ref, -1);
  a.outer.visible = d.outer.visible = true;
  L.rig = { a, d, ref, others: [] };
  L.others.slice(0, 18).forEach((o, i) => {
    const r = R.rigs[i + 2]; styleRig(r, o.team, o.role); r.outer.visible = true;
    L.rig.others.push({ r, o, ph: Math.random() * 6 });
  });
  L.review = review;
  $('toast').hidden = true;
  resize3D();
  stage.classList.add('view3d');
  $('cap3d').hidden = false;
  $('viewBtns').hidden = !review;
  captions3D(L);
  if (!review) { $('decideMsg').textContent = 'Lance aos ' + L.minute + "'. Qual é a tua decisão?"; showDecide(true); }
  pose3D(L, 0);
}
function captions3D(L) {
  if (L.kind === 'offside') {
    const m = Math.abs(L.oi.margin).toFixed(1).replace('.', ',');
    if (L.review) { $('capL').textContent = LABEL[L.truth] + ' por ' + m + ' m' + (L.ideal ? ' · vista do vídeo-árbitro' : ' · vista do assistente'); $('capR').textContent = 'Decidiste: ' + DEC_LABEL[L.decided]; }
    else { $('capL').textContent = 'Vista do assistente · ' + (L.mis < 0.8 ? 'alinhado' : 'desalinhado ' + L.mis.toFixed(1).replace('.', ',') + ' m'); $('capR').textContent = 'Bandeira ' + (L.flag ? 'levantada' : 'em baixo'); }
    return;
  }
  if (L.review) {
    $('capL').textContent = LABEL[L.truth] + (L.ideal ? ' · vista ideal' : ' · a tua vista');
    $('capR').textContent = 'Decidiste: ' + DEC_LABEL[L.decided];
  } else {
    $('capL').textContent = 'A tua vista · ' + Math.round(L.dist) + ' m';
    $('capR').textContent = L.blockers ? L.blockers + (L.blockers > 1 ? ' jogadores à frente' : ' jogador à frente') : 'Linha de vista livre';
  }
}
function hide3D() { stage.classList.remove('view3d'); $('cap3d').hidden = true; $('viewBtns').hidden = true; }
function resize3D() {
  if (!R3) return;
  const r = stage.getBoundingClientRect(), dpr = Math.min(2, window.devicePixelRatio || 1);
  const L = mode === 'fim' ? reviewing : (S && S.lance);
  // longe do lance vês com menos detalhe: menos resolução e mais neblina
  const sharp = L && !L.ideal ? clamp(L.distScore, 0.28, 1) : 1;
  R3.renderer.setPixelRatio(dpr * sharp);
  R3.renderer.setSize(r.width, r.height, false);
  R3.cam.aspect = r.width / Math.max(1, r.height); R3.cam.updateProjectionMatrix();
  R3.scene.fog.near = L && !L.ideal ? 6 + 30 * sharp : 60;
  R3.scene.fog.far = L && !L.ideal ? 30 + 120 * sharp : 180;
}

// guião do lance: posições e poses em função do tempo, para cada tipo de verdade
function poseOffside(L, t) {
  const R = R3, oi = L.oi, KT = 1.2;
  const k = Math.min(t, KT) - KT;                     // congela no momento do passe
  for (const { r, q, ph } of L.rig.list) {
    const sp = len(q.vx, q.vy);
    placeRig(r, q.x + q.vx * k, q.y + q.vy * k, sp > 0.5 ? q.vx : (oi.ball.x - q.x), sp > 0.5 ? q.vy : (oi.ball.y - q.y));
    if (q.id === oi.passer) {
      const kk = smooth((Math.min(t, KT) - (KT - 0.3)) / 0.3);
      setPose(r, kk > 0 ? { hr: -1.3 * kk, kr: 0.2, hl: 0.2, kl: 0.4, pitch: -0.15 * kk, al: 0.5, ar: -0.5, alz: -0.6, arz: 0.6 } : runPose(t * 9 + ph, 0.5));
    } else setPose(r, sp > 0.5 ? runPose(Math.min(t, KT) * 10 + ph, Math.min(0.85, sp / 7.5)) : { pitch: 0.02 });
  }
  const pb = oi.snap.find(q => q.id === oi.passer);
  const bxp = pb ? pb.x + pb.vx * k : oi.ball.x, byp = pb ? pb.y + pb.vy * k : oi.ball.y;
  const bd = pb ? norm(pb.vx || 1, pb.vy) : { x: 1, y: 0 };
  R.ball.position.set(bxp + bd.x * 0.6, 0.22, byp + bd.y * 0.6);
  const ref = L.rig.ref;
  let cx, cy, ch, lx, ly, fov;
  if (L.ideal) {
    R.lines.def.position.x = oi.lineX; R.lines.att.position.x = oi.recvX;
    R.lines.def.visible = R.lines.att.visible = true;
    const sideY = oi.ast.y < H / 2 ? -9 : H + 9;
    cx = oi.lineX; cy = sideY; ch = 7; lx = oi.lineX; ly = oi.recvY; fov = 32;
    ref.outer.visible = false;
  } else {
    R.lines.def.visible = R.lines.att.visible = false;
    cx = oi.ast.x; cy = oi.ast.y; ch = 1.75; lx = oi.ast.x; ly = oi.recvY;
    const across = Math.abs(ly - cy), spread = Math.abs(oi.recvX - oi.ast.x) * 2 + Math.abs(oi.lineX - oi.ast.x) + 10;
    fov = clamp(2 * Math.atan(Math.tan(Math.atan(spread / 2 / across)) / R.cam.aspect) * 180 / Math.PI, 12, 50);
    ref.outer.visible = false;
  }
  R.cam.fov = fov; R.cam.updateProjectionMatrix();
  R.cam.position.set(cx, ch, cy);
  R.cam.lookAt(lx, 0.9, ly);
  R.renderer.render(R.scene, R.cam);
}

function pose3D(L, t) {
  const R = R3; if (!R) return;
  if (L.kind === 'offside') { poseOffside(L, t); return; }
  const { a, d, ref, others } = L.rig, { P, A, D, truth } = L;
  const vA = 5.4;
  const vD = { siga: 6.2, falta: 6.6, amarelo: 8.2, vermelho: 9.6, simulacao: 6.2 }[truth];
  const perpSide = Math.sign(A.x * D.y - A.y * D.x) || 1;       // de que lado vem o defesa
  const touchT = { siga: 99, falta: TC - 0.55, amarelo: TC - 0.6, vermelho: TC - 0.65, simulacao: 99 }[truth];
  const fallT = { siga: TC + 0.3, falta: TC + 0.06, amarelo: TC + 0.04, vermelho: TC + 0.03, simulacao: TC + 0.35 }[truth];

  // ---- atacante
  let ax, ay;
  if (t < TC) { ax = P.x + A.x * vA * (t - TC); ay = P.y + A.y * vA * (t - TC); }
  else {
    const u = t - TC, go = L.fall ? 1.7 * (1 - Math.exp(-u * 2.6)) : Math.min(u, 1.4) * vA * (1 - Math.min(u, 1.4) / 3);
    ax = P.x + A.x * go; ay = P.y + A.y * go;
  }
  placeRig(a, ax, ay, A.x, A.y);
  // lado do empurrão no referencial do atacante
  const yaw = Math.atan2(A.x, A.y), dxl = D.x * Math.cos(yaw) - D.y * Math.sin(yaw);
  const rollDir = -Math.sign(dxl) || 1;
  if (L.fall && t >= fallT) {
    const u = t - fallT;
    if (truth === 'simulacao') {
      const k = smooth(u / 0.55);
      setPose(a, { pitch: 1.4 * k, y: 0.15 * Math.sin(Math.min(1, u / 0.55) * Math.PI), al: -2.8 * k, ar: -2.6 * k, alz: -0.3, arz: 0.3, hl: 0.5 * k, hr: 0.2 * k, kl: 0.6 * k, kr: 0.9 * k });
    } else if (truth === 'siga') {
      const k = smooth(u / 0.45);
      setPose(a, { pitch: 1.35 * k, al: -1.3 * k, ar: -1.5 * k, hl: 0.3 * k, kl: 0.8 * k, hr: -0.2, kr: 0.4 });
    } else {
      const hard = truth === 'falta' ? 0 : truth === 'amarelo' ? 1 : 1.7;
      const k = smooth(u / (0.38 - hard * 0.05));
      const hop = hard * 0.28 * Math.max(0, Math.sin(Math.min(1, u / 0.45) * Math.PI));
      const spin = truth === 'vermelho' ? Math.sin(u * 8) * 0.3 * Math.exp(-u * 2) : 0;
      setPose(a, { pitch: (0.45 + hard * 0.25) * k, roll: rollDir * (1.35 + spin) * k, y: hop,
        hrz: (dxl > 0 ? -1 : 1) * 0.9 * Math.min(1, u / 0.12), hr: 0.4 * k, kr: 1.1 * k, hl: -0.5 * k, kl: 0.4,
        al: -1.1 * k, ar: -1.6 * k, alz: -0.8 * k, arz: 0.8 * k });
    }
  } else if (t >= TC && !L.fall) {
    setPose(a, runPose(t * 11, 0.75 * Math.max(0.15, 1 - (t - TC) / 1.4)));
  } else {
    const po = runPose(t * 11, 0.8);
    // choque visível no instante do contacto (falta)
    if (truth !== 'siga' && truth !== 'simulacao' && t >= TC && t < fallT) po.hrz = (dxl > 0 ? -1 : 1) * 0.6;
    setPose(a, po);
  }

  // ---- defesa
  let target = P, reach = 0.8;
  if (truth === 'siga') { target = { x: P.x + A.x * 0.75, y: P.y + A.y * 0.75 }; reach = 0.95; }
  if (truth === 'simulacao') reach = 2.0;
  if (truth === 'vermelho') reach = 1.05;
  const C = { x: target.x - D.x * reach, y: target.y - D.y * reach };
  let dxp, dyp;
  if (truth === 'simulacao') {
    // trava a corrida e fica longe
    const stopT = TC - 0.1, dStop = t < stopT ? vD * (stopT - t) + 0.4 : 0.4 * Math.exp(-(t - stopT) * 4);
    dxp = C.x - D.x * dStop; dyp = C.y - D.y * dStop;
  } else if (t < TC) { dxp = C.x - D.x * vD * (TC - t); dyp = C.y - D.y * vD * (TC - t); }
  else {
    const u = t - TC, glide = { siga: 0.35, falta: 0.45, amarelo: 2.3, vermelho: 1.9 }[truth];
    dxp = C.x + D.x * glide * (1 - Math.exp(-u * 4)); dyp = C.y + D.y * glide * (1 - Math.exp(-u * 4));
  }
  placeRig(d, dxp, dyp, D.x, D.y);
  if (truth === 'siga' || truth === 'falta') {
    const k = smooth((t - (TC - 0.3)) / 0.3), out = t > TC + 0.7 ? smooth(1 - (t - TC - 0.7) / 0.5) : 1;
    if (k <= 0) setPose(d, runPose(t * 11.5, 0.8));
    else setPose(d, { pitch: -0.22 * k * out, hr: -1.15 * k * out, kr: 0.05, hl: 0.25 * k * out, kl: 0.45 * k * out, al: -0.5 * k, ar: 0.3 * k, alz: -0.5 * k, arz: 0.4 * k });
  } else if (truth === 'amarelo') {
    const k = smooth((t - (TC - 0.45)) / 0.35);
    if (k <= 0) setPose(d, runPose(t * 12, 0.85));
    else setPose(d, { pitch: -1.1 * k, y: -0.28 * k, hr: -0.5 * k, kr: 0, hl: -0.1 * k, kl: 1.3 * k, al: 0.6 * k, ar: -0.3, alz: -0.9 * k, arz: 0.4 });
  } else if (truth === 'vermelho') {
    const k = smooth((t - (TC - 0.4)) / 0.3), air = Math.max(0, Math.sin(clamp((t - (TC - 0.4)) / 0.6, 0, 1) * Math.PI));
    if (k <= 0) setPose(d, runPose(t * 12.5, 0.9));
    else setPose(d, { pitch: -0.75 * k, y: 0.32 * air - (t > TC + 0.3 ? 0.25 * smooth((t - TC - 0.3) / 0.3) : 0), hr: -1.75 * k, kr: 0.05, hl: -1.55 * k, kl: 0.15, al: 0.9 * k, ar: 0.9 * k, alz: -1 * k, arz: 1 * k });
  } else {
    // simulação: trava, perna mal esticada, braços abertos a dizer que não tocou
    const k = smooth((t - (TC - 0.45)) / 0.35), arms = smooth((t - (TC + 0.3)) / 0.4);
    if (k <= 0) setPose(d, runPose(t * 11.5, 0.8));
    else setPose(d, { pitch: -0.3 * k, hr: -0.45 * k, kr: 0.2, hl: 0.2 * k, kl: 0.5 * k, alz: -1.25 * arms - 0.12, arz: 1.25 * arms + 0.12, al: -0.4 * arms, ar: -0.4 * arms });
  }

  // ---- bola
  let bx, by, bh = 0.22;
  const bob = tt => 0.62 + 0.28 * Math.abs(Math.sin(tt * 4.2));
  const carry = tt => ({ x: P.x + A.x * (vA * (tt - TC) + bob(tt)), y: P.y + A.y * (vA * (tt - TC) + bob(tt)) });
  if (truth === 'siga') {
    const hit = TC - 0.04;
    if (t < hit) { const c = carry(t); bx = c.x; by = c.y; }
    else {
      const c = carry(hit), dir = norm(D.x - perpSide * A.y * 0.2 + A.x * 0.3, D.y + perpSide * A.x * 0.2 + A.y * 0.3), u = t - hit;
      const s = 10 * (1 - Math.exp(-u * 1.3)) / 1.3; bx = c.x + dir.x * s; by = c.y + dir.y * s;
      bh = 0.22 + Math.max(0, Math.sin(u * 5) * 0.6 * Math.exp(-u * 2.2));
    }
  } else if (truth === 'simulacao') {
    const rel0 = TC + 0.3;
    if (t < rel0) { const c = carry(Math.min(t, TC)); const extra = t > TC ? (t - TC) * vA * 0.8 : 0; bx = c.x + A.x * extra; by = c.y + A.y * extra; }
    else { const c = carry(TC), e0 = 0.3 * vA * 0.8, u = t - rel0, s = e0 + 4 * (1 - Math.exp(-u * 1.2)) / 1.2; bx = c.x + A.x * s; by = c.y + A.y * s; }
  } else {
    // toque longo antes do contacto: a bola já foi quando o defesa chega
    if (t < touchT) { const c = carry(t); bx = c.x; by = c.y; }
    else { const c = carry(touchT), u = t - touchT, s = 10 * (1 - Math.exp(-u * 0.8)) / 0.8; bx = c.x + A.x * s; by = c.y + A.y * s; }
  }
  R.ball.position.set(bx, bh, by);
  R.ball.rotation.x += 0.15; R.ball.rotation.z += 0.05;

  // ---- os outros continuam a mexer-se
  for (const o of others) {
    const k = clamp(t - TC, -1.5, 1.5) * 0.6, sp = len(o.o.vx, o.o.vy);
    const x = o.o.x + o.o.vx * k, y = o.o.y + o.o.vy * k;
    const fx = sp > 0.6 ? o.o.vx : P.x - o.o.x, fy = sp > 0.6 ? o.o.vy : P.y - o.o.y;
    placeRig(o.r, x, y, fx, fy);
    setPose(o.r, sp > 0.6 ? runPose(t * 10 + o.ph, Math.min(0.8, sp / 8)) : { pitch: Math.sin(t * 2 + o.ph) * 0.03 });
  }

  // ---- câmara
  const mid = { x: (ax + dxp) / 2, y: (ay + dyp) / 2 };
  const gap = len(ax - dxp, ay - dyp);
  let cx, cy, ch, look, width;
  if (L.ideal) {
    // câmara de lado, do lado contrário ao que vem o defesa, para ver o contacto sem ninguém à frente
    const perp = { x: -A.y, y: A.x };
    let sgn = (perp.x * D.x + perp.y * D.y) >= 0 ? 1 : -1;
    const camAt = sg => { const sd = norm(perp.x * sg * 0.9 + A.x * 0.25, perp.y * sg * 0.9 + A.y * 0.25); return { x: P.x + sd.x * 7.5, y: P.y + sd.y * 7.5 }; };
    const inside = c => c.x > -2.5 && c.x < W + 2.5 && c.y > -2.5 && c.y < H + 2.5;
    let cp = camAt(sgn);
    if (!inside(cp) && inside(camAt(-sgn))) cp = camAt(-sgn);
    cx = clamp(cp.x, -2.5, W + 2.5); cy = clamp(cp.y, -2.5, H + 2.5); ch = 2.3;
    look = { x: lerp(ax, mid.x, 0.5), y: lerp(ay, mid.y, 0.5) };
    width = clamp(gap + 5, 8.5, 20);
    placeRig(ref, L.ref.x, L.ref.y, P.x - L.ref.x, P.y - L.ref.y); setPose(ref, {}); ref.outer.visible = true;
  } else {
    cx = L.ref.x; cy = L.ref.y; ch = 1.75;
    const toP = norm(P.x - cx, P.y - cy);
    if (len(P.x - cx, P.y - cy) < 3.5) { cx = P.x - toP.x * 3.5; cy = P.y - toP.y * 3.5; }
    look = gap < 12 ? mid : { x: lerp(ax, dxp, 0.3), y: lerp(ay, dyp, 0.3) };
    width = clamp(gap + 5, 7, 18);
    ref.outer.visible = false;
  }
  const camDist = Math.max(1, len(look.x - cx, look.y - cy));
  const hfov = 2 * Math.atan(width / 2 / camDist);
  const vfov = clamp(2 * Math.atan(Math.tan(hfov / 2) / R.cam.aspect) * 180 / Math.PI, 7, 55);
  if (!L.cam || t === 0) L.cam = { x: look.x, y: look.y, fov: vfov };
  L.cam.x = lerp(L.cam.x, look.x, 0.12); L.cam.y = lerp(L.cam.y, look.y, 0.12); L.cam.fov = lerp(L.cam.fov, vfov, 0.08);
  R.cam.fov = L.cam.fov; R.cam.updateProjectionMatrix();
  R.cam.position.set(cx, ch, cy);
  R.cam.lookAt(L.cam.x, 0.9, L.cam.y);
  R.renderer.render(R.scene, R.cam);
}

// ---------- desenho 2D ----------
let view = { s: 10, ox: 20, oy: 20, dpr: 1 };
function resize2D() {
  const r = stage.getBoundingClientRect(), dpr = Math.min(2, window.devicePixelRatio || 1);
  c2d.width = Math.round(r.width * dpr); c2d.height = Math.round(r.height * dpr);
  const s = Math.min(c2d.width / (W + 2 * MARGIN), c2d.height / (H + 2 * MARGIN));
  view = { s, ox: (c2d.width - W * s) / 2, oy: (c2d.height - H * s) / 2, dpr };
  resize3D();
}
function drawCap(x, y, r, rim, face, text, textColor, yellow, fx, fy, alpha) {
  const s = view.s, X = view.ox + x * s, Y = view.oy + y * s, R = r * s;
  ctx.globalAlpha = alpha || 1;
  ctx.fillStyle = 'rgba(0,0,0,.28)';
  ctx.beginPath(); ctx.ellipse(X + R * 0.18, Y + R * 0.22, R, R * 0.92, 0, 0, Math.PI * 2); ctx.fill();
  ctx.beginPath();
  const teeth = 21;
  for (let i = 0; i <= teeth * 2; i++) { const a = i / (teeth * 2) * Math.PI * 2, rr = i % 2 ? R : R * 0.9; ctx.lineTo(X + Math.cos(a) * rr, Y + Math.sin(a) * rr); }
  const g = ctx.createRadialGradient(X - R * 0.4, Y - R * 0.4, R * 0.1, X, Y, R);
  g.addColorStop(0, '#f4f4f0'); g.addColorStop(0.6, rim); g.addColorStop(1, '#5a5f62');
  ctx.fillStyle = g; ctx.fill();
  ctx.fillStyle = face; ctx.beginPath(); ctx.arc(X, Y, R * 0.7, 0, Math.PI * 2); ctx.fill();
  if (fx !== undefined && (fx || fy)) {             // para onde está virado
    const n = norm(fx, fy);
    ctx.fillStyle = 'rgba(255,255,255,.85)';
    ctx.beginPath(); ctx.arc(X + n.x * R * 0.52, Y + n.y * R * 0.52, R * 0.13, 0, Math.PI * 2); ctx.fill();
  }
  if (text) { ctx.fillStyle = textColor; ctx.font = `700 ${Math.round(R * 0.9)}px "Barlow Condensed", sans-serif`; ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText(text, X, Y + R * 0.05); }
  if (yellow) { ctx.fillStyle = '#f2cf3a'; ctx.fillRect(X + R * 0.72, Y - R * 1.05, R * 0.42, R * 0.58); }
  ctx.globalAlpha = 1;
}
function draw2D() {
  const cw = c2d.width, ch = c2d.height, s = view.s;
  drawPitch(ctx, view.ox, view.oy, s, cw, ch);
  ctx.fillStyle = 'rgba(255,255,255,.18)'; ctx.strokeStyle = 'rgba(255,255,255,.85)'; ctx.lineWidth = Math.max(1.5, 0.12 * s);
  for (const side of [0, 1]) {
    const gx = side ? view.ox + W * s : view.ox - 1.5 * s;
    ctx.fillRect(gx, view.oy + (H / 2 - GOAL_W / 2) * s, 1.5 * s, GOAL_W * s);
    ctx.strokeRect(gx, view.oy + (H / 2 - GOAL_W / 2) * s, 1.5 * s, GOAL_W * s);
  }
  if (!S) return;
  const r = S.ref, b = S.ball;
  if (r.tx !== null) { ctx.strokeStyle = 'rgba(242,207,58,.7)'; ctx.lineWidth = 2 * view.dpr; ctx.beginPath(); ctx.arc(view.ox + r.tx * s, view.oy + r.ty * s, 0.6 * s, 0, Math.PI * 2); ctx.stroke(); }
  // rasto da bola
  if (b.trail.length > 1) {
    ctx.strokeStyle = 'rgba(255,255,255,.28)'; ctx.lineWidth = 0.22 * s; ctx.lineCap = 'round';
    ctx.beginPath(); b.trail.forEach((p, i) => { const X = view.ox + p.x * s, Y = view.oy + p.y * s; i ? ctx.lineTo(X, Y) : ctx.moveTo(X, Y); }); ctx.stroke();
  }
  const list = active().slice().sort((p, q) => p.y - q.y);
  for (const p of list) {
    const t = TEAMS[p.team];
    const fx = p.vx || (b.x - p.x), fy = p.vy || (b.y - p.y);
    drawCap(p.x, p.y, CAP_R, '#b9bec2', p.role === 'gk' ? t.gk : t.color, String(p.num), '#fff', p.yellow > 0, fx, fy, p.down > 0 ? 0.6 : 1);
  }
  for (const a of S.ast) {
    drawCap(a.x, a.y, CAP_R * 0.8, '#8c8f93', '#15161a', '', '#f2cf3a', false);
    const X = view.ox + a.x * s, Y = view.oy + a.y * s, up = a.flagT > 0;
    ctx.strokeStyle = '#e8e8e8'; ctx.lineWidth = Math.max(1.5, 0.12 * s);
    ctx.beginPath(); ctx.moveTo(X + 0.7 * s, Y); ctx.lineTo(X + 0.7 * s, Y - (up ? 2.2 : 0.9) * s); ctx.stroke();
    ctx.fillStyle = up ? '#f2cf3a' : 'rgba(242,207,58,.6)';
    ctx.fillRect(X + 0.7 * s, Y - (up ? 2.2 : 0.9) * s, 0.9 * s, 0.6 * s);
  }
  const pulse = 1 + 0.12 * Math.sin(performance.now() / 180);
  ctx.strokeStyle = 'rgba(242,207,58,.55)'; ctx.lineWidth = 2 * view.dpr;
  ctx.beginPath(); ctx.arc(view.ox + r.x * s, view.oy + r.y * s, CAP_R * 1.45 * pulse * s, 0, Math.PI * 2); ctx.stroke();
  drawCap(r.x, r.y, CAP_R, '#8c8f93', '#15161a', 'A', '#f2cf3a', false);
  // bola com altura: sombra no chão, bola acima
  const BX = view.ox + b.x * s, BY = view.oy + b.y * s, BR = 0.42 * s * (1 + b.z * 0.14);
  ctx.fillStyle = 'rgba(0,0,0,.3)'; ctx.beginPath(); ctx.ellipse(BX + 0.12 * s, BY + 0.12 * s, 0.42 * s, 0.36 * s, 0, 0, Math.PI * 2); ctx.fill();
  const lift = b.z * 0.55 * s;
  ctx.fillStyle = '#fbfbf5'; ctx.beginPath(); ctx.arc(BX, BY - lift, BR, 0, Math.PI * 2); ctx.fill();
  ctx.fillStyle = '#222'; ctx.beginPath(); ctx.arc(BX, BY - lift, BR * 0.36, 0, Math.PI * 2); ctx.fill();
}

// ---------- HUD ----------
function toast(msg, secs) { const el = $('toast'); el.textContent = msg; el.hidden = false; S.toastT = secs; }
function hud() {
  $('clock').textContent = Math.min(90, Math.floor(S.t / MATCH_SECONDS * 90)) + "'";
  const c = Math.round(S.control);
  $('ctrlTxt').textContent = c; const cb = $('ctrlBar');
  cb.style.width = c + '%'; cb.style.backgroundColor = c > 55 ? 'var(--good)' : (c > 30 ? 'var(--whistle)' : 'var(--bad)');
  $('staTxt').textContent = Math.round(S.stamina); $('staBar').style.width = S.stamina + '%';
}

// ---------- ciclo ----------
function step(dt) {
  if (mode === 'play') {
    S.t += dt;
    if (S.t >= MATCH_SECONDS) { endMatch('fim'); return; }
    S.lanceCd -= dt;
    S.aggr = S.aggr.map(a => Math.max(0.05, a - 0.012 * dt));
    S.control = Math.min(100, S.control + 0.05 * dt);
    refStep(dt);
    astStep(dt);
    if (S.pause > 0) { S.pause -= dt; physics(0); }
    else { aiStep(dt); physics(dt); }
    if (S.toastT > 0) { S.toastT -= dt; if (S.toastT <= 0) $('toast').hidden = true; }
  } else if (mode === 'lance' && S.lance && stage.classList.contains('view3d')) {
    const L = S.lance;
    L.time += dt * L.speed;
    const dur = L.dur || DUR;
    if (L.time >= dur) {
      L.time = dur;
      L.decideT -= dt;
      $('decideTime').textContent = Math.max(0, Math.ceil(L.decideT)) + ' s';
      $('timerBar').style.width = clamp(L.decideT / 12, 0, 1) * 100 + '%';
      if (L.decideT <= 0) decide('siga', true);
    } else { $('decideTime').textContent = L.speed < 1 ? 'repetição lenta' : 'a ver o lance'; $('timerBar').style.width = '100%'; }
  } else if (mode === 'fim' && reviewing) {
    reviewing.time += dt * reviewing.speed;
    const dur = reviewing.dur || DUR;
    if (reviewing.time >= dur + (reviewing.kind === 'offside' ? 2.5 : 0.8)) { reviewing.time = 0; reviewing.cam = null; }
  }
}

let last = performance.now(), acc = 0;
function frame(now) {
  const dt = Math.min(0.1, (now - last) / 1000); last = now; acc += dt;
  while (acc >= 1 / 60) { step(1 / 60); acc -= 1 / 60; }
  if (stage.classList.contains('view3d')) {
    const L = mode === 'fim' ? reviewing : (S && S.lance);
    if (L && L.rig) pose3D(L, Math.min(L.time, L.dur || DUR));
  } else draw2D();
  if (S) hud();
  requestAnimationFrame(frame);
}

// ---------- fim e revisão ----------
let reviewing = null;
function endMatch(kind) {
  mode = 'fim'; showDecide(false); hide3D(); $('toast').hidden = true;
  S.over = kind;
  const inc = S.incidents;
  const pts = inc.reduce((a, l) => a + l.pts, 0);
  const acc = inc.length ? pts / inc.length : 0.7;
  let grade = clamp(acc * 10 * (0.75 + 0.25 * S.control / 100), 0, 10);
  if (kind === 'abandonado') grade = Math.min(grade, 3);
  $('grade').textContent = grade.toFixed(1);
  const right = inc.filter(l => l.pts === 1).length;
  const verdict = kind === 'abandonado' ? 'Jogo interrompido: perdeste o controlo aos ' + Math.floor(S.t / MATCH_SECONDS * 90) + "'."
    : grade >= 8.5 ? 'Pronto para jogos grandes.' : grade >= 7 ? 'Boa exibição, com lances a rever.' : grade >= 5 ? 'Exibição irregular.' : 'O observador não ficou convencido.';
  $('gradeTxt').textContent = right + ' de ' + inc.length + ' decisões certas. ' + verdict;
  $('revTitle').textContent = 'Relatório do observador · ' + S.score[0] + '–' + S.score[1];
  const tb = $('revBody'); tb.textContent = '';
  if (!inc.length) { const tr = document.createElement('tr'); const td = document.createElement('td'); td.colSpan = 6; td.textContent = 'Nenhum lance para avaliar.'; tr.appendChild(td); tb.appendChild(tr); }
  inc.forEach(l => {
    const tr = document.createElement('tr');
    const cls = l.pts === 1 ? 'ok' : (l.pts > 0 ? 'half' : 'bad');
    const off = l.kind === 'offside';
    const why = l.pts === 1 ? 'Certo' : (l.timedOut ? 'Sem decisão' : off ? (l.flag === (l.truth === 'fora') ? 'Errado · a bandeira estava certa' : 'Errado · o assistente enganou-se e seguiste-o') : (l.clarity < 0.45 ? 'Errado · estavas mal colocado' : 'Errado · viste bem, decidiste mal'));
    const what = off ? LABEL[l.truth] + ' por ' + Math.abs(l.oi.margin).toFixed(1).replace('.', ',') + ' m' : LABEL[l.truth];
    const seen = off ? 'Assistente ' + (l.mis < 0.8 ? 'alinhado' : 'a ' + l.mis.toFixed(1).replace('.', ',') + ' m') + ' · bandeira ' + (l.flag ? 'levantada' : 'em baixo') : Math.round(l.dist) + ' m · clareza ' + Math.round(l.clarity * 100) + '%';
    const cells = [l.minute + "'" + (l.inBox ? ' · área' : ''), what, DEC_LABEL[l.decided] + (l.timedOut ? ' (tempo)' : ''), seen, why];
    cells.forEach((c, ci) => { const td = document.createElement('td'); td.textContent = c; if (ci === 4) td.className = cls; tr.appendChild(td); });
    const td = document.createElement('td'), btn = document.createElement('button');
    btn.className = 'linkbtn'; btn.type = 'button'; btn.textContent = 'Ver lance';
    btn.addEventListener('click', () => { reviewing = l; l.ideal = true; show3D(l, true); captions3D(l); setReviewView(true); resize3D(); stage.scrollIntoView({ behavior: 'smooth', block: 'center' }); });
    td.appendChild(btn); tr.appendChild(td); tb.appendChild(tr);
  });
  try { const best = Number(localStorage.getItem('arbitro-best') || 0); if (grade > best) localStorage.setItem('arbitro-best', grade.toFixed(1)); } catch (e) { /* sem armazenamento */ }
  $('review').hidden = false; $('help').hidden = true;
  $('review').scrollIntoView({ behavior: 'smooth', block: 'start' });
}
function setReviewView(ideal) {
  if (!reviewing) return;
  reviewing.ideal = ideal; reviewing.time = 0; reviewing.cam = null;
  resize3D(); captions3D(reviewing);
  $('viewMine').setAttribute('aria-pressed', String(!ideal)); $('viewIdeal').setAttribute('aria-pressed', String(ideal));
}

function start() {
  newMatch(); reviewing = null; hide3D();
  $('s0').textContent = '0'; $('s1').textContent = '0';
  $('menu').hidden = true; $('review').hidden = true; $('help').hidden = false; $('toast').hidden = true;
  mode = 'play';
}

// ---------- entradas ----------
$('startBtn').addEventListener('click', start);
$('againBtn').addEventListener('click', () => { start(); window.scrollTo({ top: 0, behavior: 'smooth' }); });
document.querySelectorAll('.choice[data-d]').forEach(b => b.addEventListener('click', () => decide(b.dataset.d)));
function replay() {
  const L = S && S.lance;
  if (mode !== 'lance' || !L || L.replays >= 2 || L.time < (L.dur || DUR) * 0.6) return;
  L.replays++; L.time = 0; L.cam = null; L.speed = 0.4;
  $('replayBtn').disabled = L.replays >= 2;
}
$('replayBtn').addEventListener('click', replay);
$('viewMine').addEventListener('click', e => { e.stopPropagation(); setReviewView(false); });
$('viewIdeal').addEventListener('click', e => { e.stopPropagation(); setReviewView(true); });
$('viewClose').addEventListener('click', e => { e.stopPropagation(); hide3D(); reviewing = null; });
const DKEYS = { '1': 'siga', '2': 'falta', '3': 'amarelo', '4': 'vermelho', '5': 'simulacao' };
const OKEYS = { '1': 'emjogo', '2': 'fora' };
window.addEventListener('keydown', e => {
  const k = e.key.length === 1 ? e.key.toLowerCase() : e.key;
  if (mode === 'lance') { const map = S.lance && S.lance.kind === 'offside' ? OKEYS : DKEYS; if (map[k]) decide(map[k]); if (k === 'r') replay(); return; }
  if (mode === 'menu' && (k === 'Enter' || k === ' ')) { start(); e.preventDefault(); return; }
  if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', ' '].includes(k) && mode === 'play') e.preventDefault();
  keys.add(k);
});
window.addEventListener('keyup', e => { keys.delete(e.key.length === 1 ? e.key.toLowerCase() : e.key); if (e.key === 'Shift') keys.delete('Shift'); });
window.addEventListener('blur', () => keys.clear());
stage.addEventListener('pointerdown', e => {
  if (mode !== 'play' || !S) return;
  const r = stage.getBoundingClientRect(), dpr = view.dpr;
  S.ref.tx = clamp(((e.clientX - r.left) * dpr - view.ox) / view.s, -2, W + 2);
  S.ref.ty = clamp(((e.clientY - r.top) * dpr - view.oy) / view.s, -2, H + 2);
});
window.addEventListener('resize', resize2D);
resize2D();
requestAnimationFrame(frame);
// gancho para testes automáticos
window.__arbitro = { get S() { return S; }, get mode() { return mode; }, start, decide, step, startLance, show3D, setReviewView,
  get reviewing() { return reviewing; }, set reviewing(v) { reviewing = v; } };
})();
