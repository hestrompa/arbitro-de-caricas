// ---------- fase 5: mão na bola, cantos, guarda-redes, vantagem e gestão do jogo ----------
Object.assign(LABEL, { mao: 'Mão na bola', maoAmarelo: 'Mão na bola para amarelo', penalti: 'Falta do defesa', ataque: 'Falta do atacante', vantagem: 'Vantagem' });
Object.assign(DEC_LABEL, { mao: 'Mão', maoAmarelo: 'Mão + amarelo', penalti: 'Penálti', ataque: 'Falta atacante', vantagem: 'Vantagem', nenhum: 'Sem cartão' });
const WHY = { reiterada: 'faltas repetidas', tatica: 'falta tática' };
const KEYS5 = {
  foul: { '1': 'siga', '2': 'falta', '3': 'amarelo', '4': 'vermelho', '5': 'simulacao', '6': 'vantagem' },
  offside: { '1': 'emjogo', '2': 'fora' },
  mao: { '1': 'siga', '2': 'mao', '3': 'maoAmarelo' },
  canto: { '1': 'siga', '2': 'penalti', '3': 'ataque' },
};
const KEYLBL = { offside: 'Passe', mao: 'Toque', canto: 'Contacto' };
const kindOf = L => L ? L.kind || 'foul' : 'foul';
function keyMap(L) { const m = Object.assign({}, KEYS5[kindOf(L)]); if (kindOf(L) === 'foul' && L.inBox) delete m['6']; return m; }
function choicesFor(L) {
  const k = kindOf(L);
  $('decide').dataset.kind = k + (k === 'foul' && L && L.inBox ? '-box' : '');
  document.querySelectorAll('#decide .choice[data-d]').forEach(b => { b.hidden = !b.dataset.k.split(' ').includes(k) || (b.dataset.d === 'vantagem' && !!(L && L.inBox)); });
  if (k === 'mao') $('maoSmall').textContent = '2 · ' + (L.inBox ? 'penálti' : 'livre');
  $('faltaSmall').textContent = '2 · ' + (k === 'foul' && L && L.inBox ? 'penálti' : 'livre');
  const gl = k === 'offside' && L && L.goal !== undefined;
  $('ojSmall').textContent = '1 · ' + (gl ? 'golo válido' : 'segue o ataque'); $('foraSmall').textContent = '2 · ' + (gl ? 'golo anulado' : 'livre indireto');
}
const pinfo = p => ({ id: p.id, team: p.team, num: p.num, role: p.role });
function pickTruth(w) { let r = Math.random() * Object.values(w).reduce((a, b) => a + b, 0); for (const [k, v] of Object.entries(w)) { r -= v; if (r <= 0) return k; } return Object.keys(w)[0]; }
const minuteNow = () => Math.min(90, Math.floor(S.t / MATCH_SECONDS * 90) + 1);

// o que o árbitro vê: distância, ângulo e quem está à frente
function sightOf(ref, P, dirAct, others) {
  const dist = len(P.x - ref.x, P.y - ref.y), distScore = clamp(1 - (dist - 8) / 28, 0.1, 1), view = norm(P.x - ref.x, P.y - ref.y);
  const angleScore = 0.55 + 0.45 * Math.abs(view.x * dirAct.y - view.y * dirAct.x);
  let blockers = 0;
  for (const o of others) {
    const px = o.x - ref.x, py = o.y - ref.y, proj = px * view.x + py * view.y;
    if (proj <= 0.6 || proj >= dist - 1) continue;
    if (Math.abs(px * view.y - py * view.x) < 0.85) blockers++;
  }
  return { dist, distScore, blockers, clarity: clamp(distScore * angleScore * (1 - 0.3 * blockers), 0.05, 1) };
}
function refSpot(P) {
  const ref = { x: S.ref.x, y: S.ref.y }, dd = len(P.x - ref.x, P.y - ref.y), n = norm(P.x - ref.x, P.y - ref.y), m = clamp((refAttr('leit') - 5) * 0.8, -3, Math.max(0, dd - 6));
  ref.x += n.x * m; ref.y += n.y * m;
  return ref;
}
const snapOf = p => ({ id: p.id, team: p.team, role: p.role, num: p.num, x: p.x, y: p.y, vx: p.vx, vy: p.vy });
function startScene(L0, dirAct, exclude, flash) {
  S.lanceCd = rand(11, 16) * (S.lanceK || 1);
  const ref = refSpot(L0.P);
  const others = L0.others || active().filter(p => !exclude.includes(p) && len(p.x - L0.P.x, p.y - L0.P.y) < 38).map(snapOf);
  const L = Object.assign({ scene: true, ref, others, minute: minuteNow(), time: 0, speed: 1, replays: 0, decideT: decisionTime(), stress: S.stress || 0, decided: null, cam: null, ideal: false, fall: false }, L0);
  Object.assign(L, sightOf(ref, L.P, dirAct, others));
  S.lance = L;
  mode = 'lance';
  const b = S.ball; Object.assign(b, { owner: null, vx: 0, vy: 0, vz: 0, target: null, trail: [], offInfo: null });
  S.players.forEach(p => { p.vx *= 0.2; p.vy *= 0.2; });
  $('flash').textContent = flash; $('flash').hidden = false;
  Sfx.ooh();
  setTimeout(() => { $('flash').hidden = true; $('flash').textContent = 'Lance!'; if (mode === 'lance' && S.lance === L) show3D(L, false); }, 650);
}

// ---- mão na bola: remate ou cruzamento que bate num defesa
function handCheck(p, sp) {
  const b = S.ball, k = b.kicker;
  if (mode !== 'play' || S.training || S.lanceCd > 0 || p.role === 'gk' || b.last === p.team || !k || k.off || k.team === p.team || sp < 8 || b.z > 2.2) return false;
  const box = inOwnBox(p.team, p.x, p.y);
  if (Math.random() > (box ? 0.22 : 0.05)) return false;
  startHand(k, p);
  return true;
}
function startHand(k, d) {
  const truth = pickTruth({ siga: 0.45, mao: 0.38, maoAmarelo: 0.17 });
  let Sd = norm(d.x - k.x, d.y - k.y); if (!Sd.x && !Sd.y) Sd = { x: TEAMS[k.team].dir, y: 0 };
  const dist0 = clamp(len(d.x - k.x, d.y - k.y), 7, 15), P = { x: d.x, y: d.y };
  const K = { x: P.x - Sd.x * dist0, y: P.y - Sd.y * dist0 };
  const KT = 1.0, HT = KT + dist0 / 21;
  // siga: metade das vezes a bola bate no braço junto ao corpo (posição natural), a outra metade no tronco
  const armOut = truth === 'mao' ? rand(1.15, 1.45) : truth === 'maoAmarelo' ? rand(2.3, 2.7) : Math.random() < 0.5 ? rand(0.25, 0.4) : 0;
  startScene({ kind: 'mao', truth, P, Sd, K, dist0, KT, HT, keyT: HT, dur: HT + 1.7, armOut, side: Math.random() < 0.5 ? 1 : -1,
    inBox: inOwnBox(d.team, d.x, d.y), att: pinfo(k), def: pinfo(d), A: Sd, D: { x: -Sd.x, y: -Sd.y } }, { x: -Sd.y, y: Sd.x }, [k, d], 'Mão?');
}

// ---- canto: empurrões na área
function cornerCheck(team, tk, cross) {
  if (mode !== 'play' || S.training || S.lanceCd > (cross ? 3 : 9) || Math.random() > (cross ? 0.6 : 0.75)) return;
  const dir = TEAMS[team].dir, gx = oppGoalX(team), near = S.ball.y < H / 2 ? -1 : 1;
  const Q = { x: gx - dir * rand(5.5, 8.5), y: H / 2 + near * rand(0, 3.5) };
  const byD = pt => (a, b) => len(a.x - pt.x, a.y - pt.y) - len(b.x - pt.x, b.y - pt.y);
  const att = active().filter(p => p.team === team && p !== tk && p.role !== 'gk').sort(byD(Q))[0];
  if (!att) return;
  const def = active().filter(p => p.team !== team && p.role !== 'gk').sort(byD(att))[0];
  if (!def) return;
  const start = { x: gx - dir * 14, y: H / 2 - near * 3 }, V = norm(Q.x - start.x, Q.y - start.y), perp = { x: -V.y, y: V.x };
  const truth = pickTruth({ siga: 0.45, penalti: 0.33, ataque: 0.22 });
  const KT = 0.9, HT = KT + 1.3;
  // quem sobra vai para a área: atacantes perto da marca de penálti, defesas entre eles e a baliza
  const others = [];
  active().forEach(p => {
    if (p === att || p === def || p === tk) return;
    if (p.role === 'gk') { if (p.team !== team) others.push({ id: p.id, team: p.team, role: p.role, num: p.num, x: gx - dir * 0.8, y: H / 2 + near * 0.6, vx: 0, vy: 0 }); return; }
    const mine = p.team === team;
    if (mine && p.line === 'd' && p.role !== 'lcb' && p.role !== 'rcb') return;           // os laterais ficam cá atrás
    const x = gx - dir * (mine ? rand(6, 14) : rand(2.5, 10)), y = H / 2 + rand(-9, 9);
    const v = norm(Q.x - x, Q.y - y), s = rand(0, 1.8);
    others.push({ id: p.id, team: p.team, role: p.role, num: p.num, x, y, vx: v.x * s, vy: v.y * s });
  });
  const s = Math.random() < 0.5 ? 1 : -1;                                   // lado do defesa em relação ao atacante
  startScene({ kind: 'canto', truth, P: Q, Q, V, perp, s, KT, HT, keyT: HT - 0.35, dur: HT + 1.9, inBox: true, corner: { x: S.ball.x, y: S.ball.y }, gx, dir,
    headBy: truth === 'ataque' ? 'a' : Math.random() < 0.55 ? 'a' : 'd', fall: truth === 'penalti' || (truth === 'siga' && Math.random() < 0.4),
    att: pinfo(att), def: pinfo(def), taker: pinfo(tk), others, A: V, D: V, cross: !!cross }, perp, [att, def, tk], cross ? 'Cruzamento' : 'Canto');
}

// ---- guarda-redes: saída aos pés de quem entra na área
function gkChance(p, dt) {
  if (mode !== 'play' || S.training || S.lanceCd > 0 || p.role === 'gk' || !inOwnBox(1 - p.team, p.x, p.y)) return false;
  const gk = active().find(q => q.team !== p.team && q.role === 'gk');
  if (!gk || len(gk.x - p.x, gk.y - p.y) > 5 || Math.random() > dt * 2.5) return false;
  startLance(p, gk);
  return true;
}

// ---- faltas: reiteradas, táticas e vantagem
function counterAttack(att) {
  const ti = att.team, r = rel(ti, att.x);
  if (r < W * 0.45) return false;
  const behind = active().filter(q => q.team !== ti && q.role !== 'gk' && rel(ti, q.x) > r).length;
  return behind <= 2;
}
function foulExtras(att, def, truth, P, A, inBox) {
  const o = { look: truth, why: null, adv: false, counter: def.role !== 'gk' && counterAttack(att) };
  if (def.role === 'gk') return Object.assign(o, { truth });
  // vantagem: a bola sobra para um colega com espaço?
  const E = { x: clamp(P.x + A.x * 9, 2, W - 2), y: clamp(P.y + A.y * 9, 2, H - 2) };
  const act = active().filter(q => q !== att && q !== def && q.role !== 'gk');
  const [mate, dm] = nearest(act.filter(q => q.team === att.team), E.x, E.y), [opp, dop] = nearest(act.filter(q => q.team !== att.team), E.x, E.y);
  const foulT = truth === 'falta' || truth === 'amarelo' || truth === 'vermelho';
  if (foulT) {
    if ((truth === 'falta' || truth === 'amarelo') && !inBox && mate && dm < 16 && (!opp || dm + 1.5 < dop) && Math.random() < 0.8) {
      o.adv = true; o.getId = mate.id; o.ballTo = { x: lerp(E.x, mate.x, 0.5), y: lerp(E.y, mate.y, 0.5) };
    } else if (opp && dop < 22) { o.getId = opp.id; o.ballTo = E; }
  }
  let tr = truth;
  if (tr === 'falta' && (def.fouls || 0) >= 2) { tr = 'amarelo'; o.why = 'reiterada'; }
  else if (tr === 'falta' && o.counter && !o.adv) { tr = 'amarelo'; o.why = 'tatica'; }
  o.truth = tr;
  return o;
}
function advScore(L) {
  const T = L.truth;
  if (T === 'falta' || T === 'amarelo') return L.adv ? { pts: 1, dc: 4 } : { pts: 0.4, dc: -4 };
  if (T === 'vermelho') return { pts: 0.4, dc: -6 };
  if (T === 'siga') return { pts: 0.4, dc: -3 };
  return { pts: 0, dc: -8 };
}
function advPlay(L) {
  const b = S.ball, g = L.getId !== undefined ? S.players[L.getId] : null, def = S.players[L.def.id];
  const to = g && !g.off ? g : def;
  if (L.ballTo) { to.x = L.ballTo.x; to.y = L.ballTo.y; }
  b.owner = to; b.last = to.team; b.target = null; to.cd = 0.5;
  def.fouls = (def.fouls || 0) + 1;
  S.pendCard = { L, t: 3.5 };
  return 'Vantagem! O jogo segue';
}

function lanceMsg(L) {
  if (L.kind === 'aereo') return 'Bola longa aos ' + L.minute + "'. Na disputa de cabeça, o " + L.def.num + ' ' + deT(L.def.team) + ' usou o braço?';
  if (L.kind === 'agarrao') return 'Contra-ataque ' + deT(L.att.team) + ' aos ' + L.minute + "'. O " + L.def.num + ' agarrou a camisola do ' + L.att.num + '?';
  if (L.kind === 'golo') return 'Golo ' + deT(L.goal) + ' aos ' + L.minute + "'. Antes do remate, o " + L.att.num + ' fez falta sobre o ' + L.def.num + '?';
  if (L.kind === 'linha') return (L.save ? 'Defesa em cima da linha aos ' + L.minute + "'. " : 'Golo ' + deT(L.goal) + '? ') + 'A bola passou toda a linha de golo?';
  if (L.kind === 'mao') return 'Aos ' + L.minute + "' a bola bateu no " + L.def.num + ' ' + deT(L.def.team) + (L.inBox ? ', dentro da área' : '') + '. Foi mão?';
  if (L.kind === 'canto') return (L.cross ? 'Cruzamento' : 'Canto') + ' aos ' + L.minute + "'. Houve falta na área?";
  const d = S.players[L.def.id], bits = [];
  if (d.role === 'gk') bits.push('Saída do guarda-redes.');
  if (L.counter) bits.push('Contra-ataque ' + deT(L.att.team) + '.');
  if ((d.fouls || 0) >= 2) bits.push('O ' + d.num + ' ' + deT(d.team) + ' já leva ' + d.fouls + ' faltas.');
  if (d.yellow) bits.push('O ' + d.num + ' já tem amarelo.');
  return 'Lance aos ' + L.minute + "'. " + (bits.length ? bits.join(' ') + ' ' : '') + 'Qual é a tua decisão?';
}

// decisão nos lances novos (mão e canto)
const scenePen = (L, x) => x === 'penalti' || ((x === 'mao' || x === 'maoAmarelo') && L.inBox);
function decideScene(L, d, timedOut) {
  const ok = d === L.truth;
  const near = L.kind === 'mao' ? d !== 'siga' && L.truth !== 'siga' : d !== 'penalti' && L.truth !== 'penalti';
  let pts = ok ? 1 : near ? 0.4 : 0, dc = ok ? 4 : near ? -5 : -12;
  if (timedOut) dc -= 4;
  if (L.training) { pts = ok ? 1 : 0; dc = 0; } else if (L.varFirst) { if (pts === 1) { pts = 0.7; dc = 1; } else { pts = 0; dc = -15; } }
  if (dc < 0) dc *= authK();
  S.control = clamp(S.control + dc, 0, 100);
  L.pts = pts; S.incidents.push(L); stressAfter(L); S.added += 0.2;
  const att = S.players[L.att.id], def = S.players[L.def.id], b = S.ball, atkT = att.team, defT = def.team;
  Object.assign(b, { vx: 0, vy: 0, vz: 0, z: 0, target: null, trail: [], offInfo: null });
  let msg, against = null, sev = 0.2;
  const pen = scenePen(L, d);
  if (L.kind === 'canto') {                                        // no 2D, os dois ficam onde o lance aconteceu
    att.x = L.Q.x; att.y = L.Q.y; def.x = L.Q.x - L.V.x * 0.4 + L.perp.x * L.s * 0.7; def.y = L.Q.y - L.V.y * 0.4 + L.perp.y * L.s * 0.7;
  }
  if (d === 'maoAmarelo') { def.yellow++; if (def.yellow >= 2) def.off = true; }
  if (d === 'ataque') {
    b.x = def.x; b.y = def.y; b.owner = def; b.last = defT; def.cd = 0.9; def.setPiece = true;
    msg = 'Falta do atacante: livre para ' + artT(defT); against = atkT; sev = 0.3;
  } else if (pen) {
    penalty(att.off ? active().find(p => p.team === atkT && p.role !== 'gk') : att);
    msg = 'Penálti para ' + artT(atkT) + (L.kind === 'mao' ? ' por mão na bola' : ''); against = defT; sev = 0.5;
  } else if (d === 'mao' || d === 'maoAmarelo') {
    const [tk] = nearest(active().filter(p => p.team === atkT && p.role !== 'gk'), L.P.x, L.P.y);
    b.x = L.P.x; b.y = L.P.y; tk.x = L.P.x - TEAMS[atkT].dir * 0.8; tk.y = L.P.y; b.owner = tk; b.last = atkT; tk.cd = 0.9; tk.setPiece = true;
    msg = 'Mão na bola: livre para ' + artT(atkT); against = defT; fkCheck(tk);
  } else {
    const keep = def.off ? active().find(p => p.team === defT) : def;
    b.x = keep.x; b.y = keep.y; b.owner = keep; b.last = defT; keep.cd = 0.5;
    msg = timedOut ? 'Hesitaste: o jogo seguiu' : 'Siga o jogo'; against = atkT; sev = L.kind === 'canto' && L.fall ? 0.35 : 0.22;
  }
  if (d === 'maoAmarelo') msg = 'Amarelo ao ' + def.num + ' ' + deT(defT) + ' · ' + msg;
  if (L.training) msg = (pts === 1 ? 'Certo · ' : 'Errado, era ' + LABEL[L.truth].toLowerCase() + ' · ') + msg;
  else if (L.varFirst) msg = (pts > 0 ? 'Corrigido com o VAR · ' : 'Mantiveste contra o VAR · ') + msg;
  else if (!S.noVar && varEligible(L, d) && !timedOut) msg += ' · VAR confirmou';
  if (d !== 'siga') Sfx.whistle(d === 'maoAmarelo' || pen ? 'long' : 'short');
  if (against !== null) crowdReact(against, pts < 1);
  feedDecision(L, d, msg);
  finishDecision(L, d, msg, () => {
    hide3D(); toast(msg, 2.6);
    mode = 'play'; S.pause = Math.max(S.pause, 1.2);
    protestAfter(against, sev, pts < 1);
    if (S.control <= 10) endMatch('abandonado');
  });
}

// ---------- 3D dos lances novos ----------
function setupScene(L, R) {
  const a = R.rigs[0], d = R.rigs[1], ref = R.rigs[22];
  styleRig(a, L.att.team, L.att.role, L.att.num, L.att.id); styleRig(d, L.def.team, L.def.role, L.def.num, L.def.id); styleRig(ref, -1);
  a.outer.visible = d.outer.visible = true;
  L.rig = { a, d, ref, others: [] };
  let i = 2;
  if (L.taker) { const tk = R.rigs[i++]; styleRig(tk, L.taker.team, L.taker.role, L.taker.num, L.taker.id); tk.outer.visible = true; L.rig.tk = tk; }
  L.others.slice(0, 22 - i).forEach(o => { const r = R.rigs[i++]; styleRig(r, o.team, o.role, o.num, o.id); r.outer.visible = true; L.rig.others.push({ r, o, ph: (o.id * 1.7) % 6.28 }); });
}
// quem remata: corrida curta e remate captado com o contacto em KT
function poseKicker(r, pos, dir, t, KT) {
  const k = t - KT, ck = anims().kick, m = Math.min(k, 0.25) * 1.5;
  placeRig(r, pos.x + dir.x * m, pos.y + dir.y * m, dir.x, dir.y);
  const run = runAt(t, 0, 0.45);
  setPose(r, ck && k >= -ck.key ? { mix: [run, { clip: 'kick', t: k + ck.key }, smooth((k + ck.key) / 0.2)] } : run);
}
function kickPoint(L, r, pos, dir) {
  if (L.kickPt !== undefined) return L.kickPt;
  L.kickPt = null;
  poseKicker(r, pos, dir, L.KT, L.KT); r.outer.updateMatrixWorld(true);
  const f = r.bootL.getWorldPosition(new R3.T.Vector3());
  return (L.kickPt = { x: f.x, y: f.z });
}
function poseOthers5(L, t, key, focus) {
  for (const o of L.rig.others) {
    const k = clamp(t - key, -1.5, 1.5) * 0.6, sp = len(o.o.vx, o.o.vy);
    const x = o.o.x + o.o.vx * k, y = o.o.y + o.o.vy * k;
    placeRig(o.r, x, y, sp > 0.6 ? o.o.vx : focus.x - o.o.x, sp > 0.6 ? o.o.vy : focus.y - o.o.y);
    setPose(o.r, sp > 0.6 ? runAt(t, o.ph, Math.min(0.85, sp / 7.5)) : idleAt(t, o.ph));
  }
}
// defesa que tenta tapar o remate: braço junto ao corpo, aberto ou levantado
function poseHandDef(L, t) {
  const d = L.rig.d, Sd = L.Sd, side = L.side, perp = { x: -Sd.y, y: Sd.x };
  const lean = L.truth === 'maoAmarelo' ? 0.25 * smooth((t - (L.HT - 0.4)) / 0.3) : 0;
  placeRig(d, L.P.x + perp.x * side * lean, L.P.y + perp.y * side * lean, -Sd.x, -Sd.y);
  let arm;
  if (L.truth === 'maoAmarelo') arm = L.armOut * smooth((t - (L.HT - 0.42)) / 0.3);          // movimento deliberado para a bola
  else if (L.truth === 'mao') arm = L.armOut * smooth((t - (L.KT - 0.5)) / 0.4);            // braço aberto antes do remate
  else arm = L.armOut;
  if (t > L.HT + 0.1 && L.truth !== 'siga') arm *= 1 - smooth((t - L.HT - 0.1) / 0.45);
  const flinch = t > L.HT ? 0.25 * Math.exp(-(t - L.HT) * 4) : 0;
  const add = side > 0 ? { arz: arm, alz: -0.1 } : { alz: -arm, arz: 0.1 };
  setPose(d, { clip: 'idle', t: t * 0.8 + 1, pp: true, alt: { pitch: 0.05 + flinch }, add });
}
function poseHand(L, t) {
  const { a, d } = L.rig, Sd = L.Sd, T = R3.T;
  const kp = kickPoint(L, a, L.K, Sd);
  if (L.hitPt === undefined) {
    L.hitPt = null;
    poseHandDef(L, L.HT); d.outer.updateMatrixWorld(true);
    const hand = L.side > 0 ? d.handR : d.handL, v = new T.Vector3();
    if (L.armOut > 0) hand.getWorldPosition(v); else { d.spine.getWorldPosition(v); v.x -= Sd.x * 0.14; v.z -= Sd.y * 0.14; v.y -= 0.12; }
    L.hitPt = { x: v.x, y: v.z, h: v.y };
  }
  poseKicker(a, L.K, Sd, t, L.KT);
  poseHandDef(L, t);
  const b0 = kp ? { x: kp.x + Sd.x * 0.13, y: kp.y + Sd.y * 0.13 } : L.K, hp = L.hitPt || { x: L.P.x, y: L.P.y, h: 1 };
  let bx, by, bh;
  if (t < L.KT) { bx = b0.x; by = b0.y; bh = 0.11; }
  else if (t < L.HT) { const u = (t - L.KT) / (L.HT - L.KT); bx = lerp(b0.x, hp.x, u); by = lerp(b0.y, hp.y, u); bh = lerp(0.11, hp.h, u) + Math.sin(u * Math.PI) * 0.35; R3.ball.rotation.x += 0.3; }
  else {
    const u = t - L.HT, perp = { x: -Sd.y, y: Sd.x }, dir = norm(-Sd.x * 0.6 + perp.x * L.side * 0.8, -Sd.y * 0.6 + perp.y * L.side * 0.8);
    const s = 7 * (1 - Math.exp(-u * 1.6)) / 1.6; bx = hp.x + dir.x * s; by = hp.y + dir.y * s;
    bh = hp.h + 2 * u - 4.9 * u * u; if (bh < 0.11) bh = 0.11 + Math.abs(Math.sin(u * 6)) * 0.3 * Math.exp(-u * 2);
  }
  R3.ball.position.set(bx, bh, by);
  poseOthers5(L, t, L.HT, L.P);
  const look = { x: lerp(L.P.x, L.K.x, 0.25), y: lerp(L.P.y, L.K.y, 0.25) }, perp = { x: -Sd.y, y: Sd.x };
  sceneCam(L, t, look, clamp(L.dist0 * 0.5 + 4, 6, 12), { x: L.P.x - Sd.x * 4.5 + perp.x * L.side * 2.5, y: L.P.y - Sd.y * 4.5 + perp.y * L.side * 2.5, h: 1.6, look: { x: L.P.x - Sd.x * 1.2, y: L.P.y - Sd.y * 1.2 }, w: 5 });
}
// canto: batedor, ataque ao primeiro poste, empurrões e cabeceamento
const jumpPose = (h, arms) => ({ air: true, y: h, hl: -0.55, kl: 1.1, hr: -0.25, kr: 0.6, fl: 0.4, fr: 0.3, al: -arms, ar: -arms * 0.9, alz: -0.3, arz: 0.3, el: -0.4, er: -0.4, pitch: -0.05 });
function poseCorner(L, t) {
  const { a, d, tk } = L.rig, { Q, V, perp, s, KT, HT } = L, T = R3.T;
  const cdir = norm(Q.x - L.corner.x, Q.y - L.corner.y), tkPos = { x: L.corner.x - cdir.x * 0.4, y: L.corner.y - cdir.y * 0.4 };
  const kp = kickPoint(L, tk, tkPos, cdir);
  poseKicker(tk, tkPos, cdir, t, KT);
  const vA = 5.2, jT = HT - 0.33, hopH = u => 0.42 * Math.max(0, Math.sin(clamp(u / 0.62, 0, 1) * Math.PI));
  // ---- atacante
  let ap;
  if (t < HT) ap = { x: Q.x - V.x * vA * (HT - t), y: Q.y - V.y * vA * (HT - t) };
  else { const u = t - HT, go = L.truth === 'penalti' ? 1.5 * (1 - Math.exp(-u * 2.6)) : 1.4 * (1 - Math.exp(-u * 2)); ap = { x: Q.x + V.x * go, y: Q.y + V.y * go }; }
  placeRig(a, ap.x, ap.y, V.x, V.y);
  const aRun = runAt(t, 0, t < HT ? 0.7 : Math.max(0.1, 0.7 - (t - HT)));
  if (L.truth === 'penalti') {
    const fT = HT - 0.32, u = t - fT;
    setPose(a, u < 0 ? aRun : { mix: [aRun, { clip: 'dive', t: u * 1.1 }, smooth(u / 0.14)] });
  } else {
    // ataque: afasta o defesa com o braço do lado dele, depois salta
    const shove = L.truth === 'ataque' ? Math.max(0, Math.sin(clamp((t - (HT - 0.62)) / 0.4, 0, 1) * Math.PI)) : 0;
    const add = s > 0 ? { alz: -1.3 * shove } : { arz: 1.3 * shove };
    const u = t - jT, jp = jumpPose(hopH(u), 2.3);
    let po = u < 0 ? aRun : { mix: [aRun, jp, smooth(u / 0.12) * (u > 0.62 ? smooth(1 - (u - 0.62) / 0.2) : 1)] };
    if (L.truth === 'siga' && L.fall && t > HT + 0.15) { const f = t - HT - 0.15; po = { mix: [po, { clip: 'dive', t: 0.15 + f * 1.1 }, smooth(f / 0.14)] }; }
    setPose(a, shove > 0 && u < 0 ? Object.assign({}, po, { add }) : po);
  }
  // ---- defesa, colado ao atacante
  let dp = { x: ap.x - V.x * 0.35 + perp.x * s * 0.7, y: ap.y - V.y * 0.35 + perp.y * s * 0.7 };
  let face = V;
  if (L.truth === 'ataque' && t > HT - 0.45) { const u = t - (HT - 0.45), pushed = 1.3 * (1 - Math.exp(-u * 3)); dp = { x: dp.x + perp.x * s * pushed - V.x * u * 2.5, y: dp.y + perp.y * s * pushed - V.y * u * 2.5 }; if (t > HT) dp = { x: dp.x + V.x * (t - HT) * 2.5, y: dp.y + V.y * (t - HT) * 2.5 }; }
  if (L.truth === 'penalti') face = norm(V.x - perp.x * s * 0.5, V.y - perp.y * s * 0.5);
  placeRig(d, dp.x, dp.y, face.x, face.y);
  const dRun = runAt(t, 1.2, t < HT ? 0.7 : Math.max(0.1, 0.7 - (t - HT)));
  if (L.truth === 'ataque') {
    const u = t - (HT - 0.42);
    setPose(d, u < 0 ? dRun : { mix: [dRun, { clip: 'fallback', t: 0.35 + u }, smooth(u / 0.15)] });
  } else {
    // penálti: empurra com as duas mãos nas costas; depois salta tarde
    const push = L.truth === 'penalti' ? Math.max(0, Math.sin(clamp((t - (HT - 0.62)) / 0.45, 0, 1) * Math.PI)) : 0;
    const u = t - (jT + (L.truth === 'penalti' ? 0.12 : 0)), jp = jumpPose(hopH(u) * (L.truth === 'penalti' ? 0.6 : 1), 1.9);
    const po = u < 0 ? dRun : { mix: [dRun, jp, smooth(u / 0.12) * (u > 0.62 ? smooth(1 - (u - 0.62) / 0.2) : 1)] };
    setPose(d, push > 0 && u < 0 ? Object.assign({}, po, { add: { alx: -1.35 * push, arx: -1.35 * push } }) : po);
  }
  // ---- bola: sai do pé do batedor e chega à cabeça no instante HT
  const b0 = kp ? { x: kp.x + cdir.x * 0.13, y: kp.y + cdir.y * 0.13 } : L.corner, hitH = 2.3;
  let bx, by, bh;
  if (t < KT) { bx = b0.x; by = b0.y; bh = 0.11; }
  else if (t < HT) { const u = (t - KT) / (HT - KT); bx = lerp(b0.x, Q.x, u); by = lerp(b0.y, Q.y, u); bh = lerp(0.11, hitH, u) + 11 * u * (1 - u); R3.ball.rotation.z += 0.2; }
  else {
    const u = t - HT, flight = norm(Q.x - b0.x, Q.y - b0.y);
    const headed = L.truth !== 'penalti' && !(L.truth === 'siga' && L.headBy === 'd' && false);
    const dir = headed ? (L.headBy === 'a' ? norm(L.gx - Q.x, H / 2 + (Q.y < H / 2 ? 1.5 : -1.5) - Q.y) : norm(-L.dir, (Q.y < H / 2 ? -0.6 : 0.6))) : flight;
    const sp = headed ? 11 : 9, sd = sp * (1 - Math.exp(-u * 1.2)) / 1.2;
    bx = Q.x + dir.x * sd; by = Q.y + dir.y * sd;
    bh = hitH + (headed ? 1.5 : -1) * u - 4.9 * u * u; if (bh < 0.11) bh = 0.11 + Math.abs(Math.sin(u * 5)) * 0.25 * Math.exp(-u * 2);
  }
  R3.ball.position.set(bx, bh, by);
  poseOthers5(L, t, HT, Q);
  sceneCam(L, t, { x: Q.x - V.x * 1.5, y: Q.y - V.y * 1.5 }, 11, { x: Q.x - V.x * 8 - perp.x * s * 1.2, y: Q.y - V.y * 8 - perp.y * s * 1.2, h: 2.6, look: { x: Q.x - V.x * 0.8, y: Q.y - V.y * 0.8 }, w: 6.5 });
}
function sceneCam(L, t, look, width, ideal) {
  const R = R3, ref = L.rig.ref;
  let cx, cy, ch;
  if (L.ideal) { cx = clamp(ideal.x, -2.5, W + 2.5); cy = clamp(ideal.y, -2.5, H + 2.5); ch = ideal.h; placeRig(ref, L.ref.x, L.ref.y, L.P.x - L.ref.x, L.P.y - L.ref.y); setPose(ref, idleAt(t, 2)); ref.outer.visible = true; }
  else {
    cx = L.ref.x; cy = L.ref.y; ch = 1.75; ref.outer.visible = false;
    const toP = norm(L.P.x - cx, L.P.y - cy);
    if (len(L.P.x - cx, L.P.y - cy) < 3.5) { cx = L.P.x - toP.x * 3.5; cy = L.P.y - toP.y * 3.5; }
  }
  if (L.ideal && ideal.look) { look = ideal.look; width = ideal.w; }
  // ninguém fica colado à câmara nem à frente do lance na vista ideal
  for (const o of L.rig.others) {
    const ox = o.r.outer.position.x, oz = o.r.outer.position.z;
    let vis = len(ox - cx, oz - cy) > 2;
    if (vis && L.ideal) { const sd = segDist(cx, cy, look.x, look.y, ox, oz); vis = !(sd.d < 0.9 && sd.t < 0.85); }
    o.r.outer.visible = vis;
  }
  if (L.rig.tk) L.rig.tk.outer.visible = len(L.rig.tk.outer.position.x - cx, L.rig.tk.outer.position.z - cy) > 2;
  const camDist = Math.max(1, len(look.x - cx, look.y - cy));
  const hfov = 2 * Math.atan(width / 2 / camDist), vfov = clamp(2 * Math.atan(Math.tan(hfov / 2) / R.cam.aspect) * 180 / Math.PI, 6, 55);
  if (!L.cam || t === 0 || L.paused) L.cam = { x: look.x, y: look.y, fov: vfov };
  L.cam.x = lerp(L.cam.x, look.x, 0.12); L.cam.y = lerp(L.cam.y, look.y, 0.12); L.cam.fov = lerp(L.cam.fov, vfov, 0.08);
  R.cam.fov = L.cam.fov; R.cam.updateProjectionMatrix();
  R.cam.position.set(cx, ch, cy);
  const sh = camShake(L, camDist); R.cam.lookAt(L.cam.x + sh.x, (L.ideal && ideal.lh !== undefined ? ideal.lh : 1) + sh.y, L.cam.y + sh.z);
  R.renderer.render(R.scene, R.cam);
}
function poseScene(L, t) { $('pip').hidden = true; glassPosts(L); if (L.kind === 'mao') poseHand(L, t); else if (L.kind === 'golo') poseGoalFoul(L, t); else if (L.kind === 'linha') poseLine(L, t); else poseCorner(L, t); }

// guarda-redes: sai a correr e atira-se aos pés (queda captada)
function gkPose(L, d, t, dRun) {
  const u = t - (TC - 0.5);
  setPose(d, u <= 0 ? dRun : { mix: [dRun, { clip: 'dive', t: u * 1.15 }, smooth(u / 0.15)] });
}
// quem fica com a bola depois da falta: colega com espaço (vantagem) ou adversário
function poseGetter(L, o, t) {
  const p0 = { x: o.o.x + o.o.vx * clamp(t - TC, -1.5, 0) * 0.6, y: o.o.y + o.o.vy * clamp(t - TC, -1.5, 0) * 0.6 };
  const tgt = L.ballTo, dir = norm(tgt.x - o.o.x, tgt.y - o.o.y), end = { x: tgt.x - dir.x * 0.5, y: tgt.y - dir.y * 0.5 };
  const k = smooth((t - (TC - 0.3)) / 1.9), x = lerp(p0.x, end.x, k), y = lerp(p0.y, end.y, k);
  const moving = t > TC - 0.3 && k < 0.98, sp = len(end.x - p0.x, end.y - p0.y) / 1.9;
  placeRig(o.r, x, y, moving ? dir.x : L.A.x, moving ? dir.y : L.A.y);
  setPose(o.r, moving ? runAt(t, o.ph, clamp(sp / 7.5, 0.3, 0.9)) : idleAt(t, o.ph));
}

// ---------- perguntas curtas a meio do jogo: cartão depois da vantagem, antijogo ----------
function askOpen(msg, tag, opts, cb, def) {
  S.ask = { opts, cb, t: 0, def: def || 0 };
  mode = 'pergunta';
  $('askMsg').textContent = msg; $('askTag').textContent = tag;
  const box = $('askChoices'); box.textContent = '';
  opts.forEach((o, i) => {
    const b = document.createElement('button'); b.type = 'button'; b.className = 'choice';
    if (o.sw) { const sw = document.createElement('span'); sw.className = 'swatch'; sw.style.background = o.sw; b.appendChild(sw); }
    b.appendChild(document.createTextNode(o.label));
    const sm = document.createElement('small'); sm.textContent = (i + 1) + ' · ' + o.small; b.appendChild(sm);
    b.addEventListener('click', () => askPick(i));
    box.appendChild(b);
  });
  $('ask').hidden = false; $('decide').hidden = true;
  panelIntoView('ask');
}
function askPick(i) {
  const A = S && S.ask; if (!A || mode !== 'pergunta' || !A.opts[i]) return;
  S.ask = null; $('ask').hidden = true;
  mode = 'play'; S.pause = Math.max(S.pause, 0.8);
  A.cb(A.opts[i].d);
  if (S.control <= 10) endMatch('abandonado');
}
function askStep(dt) { S.ask.t += dt; $('askBar').style.width = clamp(1 - S.ask.t / 10, 0, 1) * 100 + '%'; if (S.ask.t > 10) askPick(S.ask.def); }
function askKey(k) { const i = Number(k) - 1; if (i >= 0) askPick(i); }
function pendStep(dt) {
  const P = S.pendCard; if (!P || S.pause > 0) return;
  P.t -= dt; if (P.t > 0) return;
  S.pendCard = null;
  const L = P.L, p = S.players[L.def.id];
  askOpen('Jogo parado. Deste vantagem na falta do ' + p.num + ' ' + deT(p.team) + (p.yellow ? ' (já tem amarelo)' : '') + '. Mostras cartão?', 'Depois da vantagem',
    [{ d: 'nenhum', label: 'Sem cartão', small: 'foi só falta' }, { d: 'amarelo', label: 'Amarelo', small: 'entrada imprudente', sw: 'var(--whistle)' }, { d: 'vermelho', label: 'Vermelho', small: 'jogo violento', sw: 'var(--bad)' }],
    c => {
      L.cardLater = c;
      const want = L.truth === 'amarelo' ? 'amarelo' : L.truth === 'vermelho' ? 'vermelho' : 'nenhum';
      let dc = c === want ? 2 : -4;
      if (c !== want) L.pts = Math.max(0, L.pts - 0.5);
      if (dc < 0) dc *= authK();
      S.control = clamp(S.control + dc, 0, 100);
      let msg = c === 'nenhum' ? 'Sem cartão para o ' + p.num : (c === 'amarelo' ? 'Amarelo' : 'Vermelho') + ' ao ' + p.num + ' ' + deT(p.team) + ' pela falta anterior';
      if (c === 'amarelo') { p.yellow++; if (p.yellow >= 2) { p.off = true; msg = 'Segundo amarelo: ' + p.num + ' ' + deT(p.team) + ' expulso'; } }
      if (c === 'vermelho') p.off = true;
      if (p.off && S.ball.owner === p) { const [q] = nearest(active().filter(x => x.team === p.team), p.x, p.y); S.ball.owner = q || null; }
      if (c !== 'nenhum') { Sfx.whistle('long'); feed(msg + '.', 'card'); }
      toast(msg, 2.2);
    }, 0);
}
// antijogo: o guarda-redes que está a ganhar demora a repor a bola
function stallCheck(gk) {
  if (S.training || S.stall || S.stallN >= 2 || S.t < MATCH_SECONDS * 0.5 || S.score[gk.team] <= S.score[1 - gk.team] || Math.random() > 0.7) return;
  S.stall = { id: gk.id, team: gk.team, t: 0 }; S.stallN++;
}
function stallStep(dt) {
  const St = S.stall; if (!St) return;
  const p = S.players[St.id];
  if (S.ball.owner !== p || p.off) { S.stall = null; return; }
  St.t += dt; p.cd = Math.max(p.cd, 0.5);
  if (St.t < 3.2 || S.pause > 0) return;
  const warned = S.warned[St.team];
  askOpen('O guarda-redes ' + deT(St.team) + ' está a demorar a repor a bola' + (warned ? ' outra vez' : '') + '.', 'Antijogo',
    [{ d: 'deixar', label: 'Deixar', small: 'ainda é cedo' }, { d: 'avisar', label: 'Mandar jogar', small: 'aviso verbal' }, { d: 'amarelo', label: 'Amarelo', small: 'por antijogo', sw: 'var(--whistle)' }],
    c => {
      const best = warned ? 'amarelo' : 'avisar';
      const pts = c === best ? 1 : c !== 'deixar' ? 0.5 : warned ? 0 : 0.2;
      let dc = pts === 1 ? 3 : pts >= 0.5 ? -1 : -4; if (dc < 0) dc *= authK();
      S.control = clamp(S.control + dc, 0, 100);
      if (c === 'deixar' && St.team !== HOME) { S.crowd = clamp(S.crowd + 10, 0, 100); Sfx.boo(0.5); }
      if (c !== 'deixar') S.warned[St.team] = true;
      let msg = c === 'deixar' ? 'Deixaste o guarda-redes demorar' : c === 'avisar' ? 'Mandaste o guarda-redes jogar' : 'Amarelo ao guarda-redes ' + deT(St.team) + ' por antijogo';
      if (c === 'amarelo') { p.yellow++; Sfx.whistle('short'); if (p.yellow >= 2) { p.off = true; msg = 'Segundo amarelo: guarda-redes ' + deT(St.team) + ' expulso'; } }
      S.manage.push({ minute: minuteNow(), what: 'Guarda-redes a queimar tempo' + (warned ? ' (já avisado)' : ''), dec: { deixar: 'Deixar', avisar: 'Mandar jogar', amarelo: 'Amarelo' }[c], pts, why: pts === 1 ? 'Certo' : warned ? 'Já tinha sido avisado: era amarelo' : c === 'deixar' ? 'Devias ter mandado jogar' : 'Primeira vez: bastava um aviso' });
      S.added += 0.5; p.cd = 0.3; S.stall = null;
      feed(msg + '.', c === 'amarelo' ? 'card' : 'info');
      toast(msg, 2.2);
    }, 0);
}
function manageRows() {
  const tb = $('revBody');
  (S.manage || []).forEach(m => {
    const tr = document.createElement('tr'), cls = m.pts === 1 ? 'ok' : m.pts > 0 ? 'half' : 'bad';
    [m.minute + "'", m.what, m.dec, 'Gestão do jogo', m.why, ''].forEach((c, i) => { const td = document.createElement('td'); td.textContent = c; if (i === 4) td.className = cls; tr.appendChild(td); });
    tb.appendChild(tr);
  });
}
// descontos: o 4.º árbitro mostra o tempo perdido com lances, golos, VAR e antijogo
function clockTxt() { return S.t <= MATCH_SECONDS ? Math.floor(S.t / MATCH_SECONDS * 90) + "'" : '90+' + Math.ceil((S.t - MATCH_SECONDS) / MATCH_SECONDS * 90) + "'"; }
function addedTimeCheck() {
  if (S.t < MATCH_SECONDS || S.addMin) return;
  S.addMin = clamp(Math.round(S.added), 1, 6);
  toast('O 4.º árbitro mostra +' + S.addMin + "' de descontos", 2.6); radio('4.º árbitro', 'Tempo cumprido. Vou mostrar +' + S.addMin + '.');
  feed('Descontos: mais ' + S.addMin + (S.addMin > 1 ? ' minutos.' : ' minuto.'), 'info');
}
