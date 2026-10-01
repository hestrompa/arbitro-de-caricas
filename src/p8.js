// ---------- fase 6: lances de golo (falta antes do golo, fora de jogo, linha de golo) e livres diretos ----------
Object.assign(LABEL, { valido: 'Golo limpo', anular: 'Falta do atacante antes do golo', entrou: 'A bola entrou toda', naoEntrou: 'A bola não entrou toda' });
Object.assign(DEC_LABEL, { valido: 'Golo válido', anular: 'Golo anulado', entrou: 'Golo', naoEntrou: 'Não entrou' });
Object.assign(KEYS5, { golo: { '1': 'valido', '2': 'anular' }, linha: { '1': 'entrou', '2': 'naoEntrou' } });
Object.assign(KEYLBL, { golo: 'Contacto', linha: 'Linha' });
const LINE_IN = 0.17;                         // centro da bola a 17 cm da linha (meia linha + raio): passou toda

// o golo só conta depois de o árbitro ver o lance que interessa
function goal(team) { if (goalCheck(team)) return; goalAward(team); if (!S.noVar && !S.training) setTimeout(() => { if (S && mode === 'play') radio('VAR', 'Golo verificado. Pode recomeçar.'); }, 1400); }
function goalCheck(team) {
  const b = S.ball, lo = S.lastOff; S.lastOff = null;
  if (mode !== 'play' || S.training || b.penalty || S.lanceCd > 9) return false;
  const k = b.kicker && b.kicker.team === team && !b.kicker.off ? b.kicker : null;
  if (!k) return false;
  if (lo && S.t - lo.t < 6 && lo.oi.team === team && lo.n === S.incidents.length && lo.o === S.offsides && Math.random() < 0.85) { startGoalOffside(lo.oi, team); return true; }
  const r = Math.random();
  if (r < 0.3 && b.shotFrom && startGoalFoul(team, k)) return true;
  if (r > 0.85 && startLine(team, k, 'entrou', false)) return true;
  return false;
}
// fora de jogo no passe que deu o golo: o assistente não levantou a bandeira
function startGoalOffside(oi, team) {
  startOffside(oi);
  Object.assign(S.lance, { flag: false, goal: team, goalCtx: true, dflt: 'emjogo' });
  $('flash').textContent = 'Golo?';
}
function goalOffMsg(L) { return 'Golo ' + deT(L.goal) + ' aos ' + L.minute + "'. A bandeira ficou em baixo. No passe da jogada, o recetor estava em jogo?"; }

// falta do atacante antes do remate: empurra o defesa com o braço ou é só ombro com ombro
function startGoalFoul(team, k) {
  const b = S.ball, gx = oppGoalX(team), dirIn = gx > W / 2 ? 1 : -1;
  const G = { x: gx + dirIn * 0.3, y: clamp(b.y, H / 2 - GOAL_W / 2 + 0.5, H / 2 + GOAL_W / 2 - 0.5) };
  let Pk = { x: b.shotFrom.x, y: b.shotFrom.y };
  const dg = len(G.x - Pk.x, G.y - Pk.y), want = clamp(dg, 9, 22), nn = norm(Pk.x - G.x, Pk.y - G.y);
  Pk = { x: G.x + nn.x * want, y: G.y + nn.y * want };
  const def = active().filter(p => p.team !== team && p.role !== 'gk').sort((p, q) => len(p.x - Pk.x, p.y - Pk.y) - len(q.x - Pk.x, q.y - Pk.y))[0];
  const gk = active().find(p => p.team !== team && p.role === 'gk');
  if (!def || !gk) return false;
  const A = norm(G.x - Pk.x, G.y - Pk.y), perp = { x: -A.y, y: A.x }, s = Math.random() < 0.5 ? 1 : -1;
  const truth = pickTruth({ valido: 0.55, anular: 0.45 });
  const vA = 6, CT = 1.45, KT = CT + 0.4, HT = KT + want / 24;
  const C = { x: Pk.x - A.x * vA * (KT - CT), y: Pk.y - A.y * vA * (KT - CT) };
  const others = active().filter(p => p !== k && p !== def && p !== gk && len(p.x - Pk.x, p.y - Pk.y) < 32).map(snapOf);
  startScene({ kind: 'golo', truth, P: C, C, Pk, G, A, D: A, perp, s, vA, CT, KT, HT, keyT: CT, dur: HT + 1.5, dirIn, gx,
    inBox: inOwnBox(1 - team, Pk.x, Pk.y), att: pinfo(k), def: pinfo(def), taker: pinfo(gk), others, goal: team, goalCtx: true, dflt: 'valido',
    fall: truth === 'anular' || Math.random() < 0.45 }, perp, [k, def, gk], 'Golo?');
  return true;
}
// bola em cima da linha: o guarda-redes tira-a de lá; passou toda ou não?
function startLine(team, k, truth, save) {
  const b = S.ball, gx = oppGoalX(team), dirIn = gx > W / 2 ? 1 : -1;
  const gk = active().find(p => p.team !== team && p.role === 'gk');
  if (!gk) return false;
  const m = truth === 'entrou' ? rand(0.2, 0.31) : rand(0.0, 0.14);
  const Y = clamp(b.y, H / 2 - GOAL_W / 2 + 0.7, H / 2 + GOAL_W / 2 - 0.7);
  const B = { x: gx + dirIn * m, y: Y, h: rand(0.2, 0.45) };
  const sf = b.shotFrom || { x: gx - dirIn * 15, y: H / 2 + rand(-7, 7) };
  const nn = norm(sf.x - B.x, sf.y - B.y), dd = clamp(len(sf.x - B.x, sf.y - B.y), 8, 20);
  const Pk = { x: B.x + nn.x * dd, y: B.y + nn.y * dd }, A = { x: -nn.x, y: -nn.y };
  const KT = 0.9, HT = KT + dd / 24;
  const others = active().filter(p => p !== k && p !== gk && len(p.x - B.x, p.y - B.y) < 30).map(snapOf);
  startScene({ kind: 'linha', truth, P: { x: gx - dirIn * 0.6, y: Y }, B, Pk, A, D: A, KT, HT, keyT: HT + 0.15, dur: HT + 1.6, dirIn, gx, m,
    inBox: true, att: pinfo(k), def: pinfo(gk), others, goal: team, goalCtx: true, dflt: save ? 'naoEntrou' : 'entrou', save: !!save }, { x: 0, y: 1 }, [k, gk], save ? 'Entrou?' : 'Golo?');
  return true;
}
// defesa do guarda-redes em cima da linha (o remate não chegou a ser golo no 2D)
function lineCheck(gk, sp) {
  const b = S.ball, k = b.kicker;
  if (mode !== 'play' || S.training || S.lanceCd > 0 || gk.role !== 'gk' || b.last === gk.team || !k || k.team === gk.team || sp < 12 || b.penalty) return false;
  if (Math.abs(b.x - ownGoalX(gk.team)) > 2.2 || Math.abs(b.y - H / 2) > GOAL_W / 2 || Math.random() > 0.3) return false;
  return startLine(k.team, k, pickTruth({ naoEntrou: 0.65, entrou: 0.35 }), true);
}

// decisão nos lances de golo
function goalVerdict(L, allowed) {
  const team = L.goal, b = S.ball;
  Object.assign(b, { vx: 0, vy: 0, vz: 0, z: 0, target: null, trail: [], offInfo: null, penalty: false });
  if (allowed) { goalAward(team); return L.kind === 'linha' && L.save ? 'A bola entrou toda: golo ' + deT(team) : 'Golo validado'; }
  S.anulados = (S.anulados || 0) + 1;
  if (L.kind === 'offside') { flagOffside(L.oi); return 'Golo anulado por fora de jogo'; }
  if (L.kind === 'golo') {
    const d0 = S.players[L.def.id], tk = d0.off ? active().find(p => p.team === d0.team && p.role !== 'gk') : d0;
    tk.x = clamp(L.C.x, 1, W - 1); tk.y = clamp(L.C.y, 1, H - 1);
    Object.assign(b, { x: tk.x, y: tk.y, owner: tk, last: tk.team }); tk.cd = 0.9; tk.setPiece = true;
    return 'Golo anulado: falta do ' + L.att.num + ' ' + deT(team);
  }
  const gk = S.players[L.def.id];
  gk.x = L.gx - L.dirIn * 1.2; gk.y = L.B.y;
  Object.assign(b, { x: gk.x, y: gk.y, owner: gk, last: gk.team }); gk.cd = 1.1;
  return L.save ? 'Não entrou toda: o guarda-redes salvou' : 'Golo anulado: a bola não entrou toda';
}
function decideGoal(L, d, timedOut) {
  const ok = d === L.truth;
  let pts = ok ? 1 : 0, dc = ok ? 4 : -12;
  if (timedOut) dc -= 4;
  if (L.varFirst) { if (pts === 1) { pts = 0.7; dc = 1; } else { pts = 0; dc = -15; } }
  if (dc < 0) dc *= authK();
  S.control = clamp(S.control + dc, 0, 100);
  L.pts = pts; S.incidents.push(L); stressAfter(L); S.added += 0.3;
  const allowed = d === 'valido' || d === 'entrou';
  let msg = goalVerdict(L, allowed);
  const against = allowed ? 1 - L.goal : L.goal;
  if (L.varFirst) msg = (pts > 0 ? 'Corrigido com o VAR · ' : 'Mantiveste contra o VAR · ') + msg;
  else if (!S.noVar && !timedOut) msg += ' · VAR confirmou';
  if (!allowed) Sfx.whistle('short');
  crowdReact(against, pts < 1);
  feedDecision(L, d, msg);
  finishDecision(L, d, msg, () => {
    hide3D(); toast(msg, 2.6);
    mode = 'play'; S.pause = Math.max(S.pause, 1.2);
    protestAfter(against, allowed ? 0.4 : 0.5, pts < 1);
    if (S.control <= 10) endMatch('abandonado');
  });
}

// ---------- 3D dos lances de golo ----------
// postes translúcidos na câmara da linha, para se ver a bola encostada à linha
function glassPosts(L) {
  const m = R3 && R3.postMat; if (!m) return;
  const on = !!(L && L.kind === 'linha' && L.ideal);
  if (m.transparent !== on) { m.transparent = on; m.opacity = on ? 0.18 : 1; m.depthWrite = !on; m.needsUpdate = true; }
}
function poseGoalFoul(L, t) {
  const { a, d, tk } = L.rig, { Pk, G, A, perp, s, vA, CT, KT, HT } = L;
  // atacante: corre para a baliza e remata em KT
  const apos = t < KT ? { x: Pk.x - A.x * vA * (KT - t), y: Pk.y - A.y * vA * (KT - t) } : { x: Pk.x + A.x * Math.min(t - KT, 0.35) * 2, y: Pk.y + A.y * Math.min(t - KT, 0.35) * 2 };
  placeRig(a, apos.x, apos.y, A.x, A.y);
  const ck = anims().kick, kk = t - KT, run = runAt(t, 0, t < KT ? 0.8 : Math.max(0.15, 0.8 - kk));
  let po = ck && kk >= -ck.key ? { mix: [run, { clip: 'kick', t: kk + ck.key }, smooth((kk + ck.key) / 0.2)] } : run;
  const shove = L.truth === 'anular' ? Math.max(0, Math.sin(clamp((t - (CT - 0.3)) / 0.55, 0, 1) * Math.PI)) : 0;
  setPose(a, po);
  if (shove > 0) {                                                  // braço esticado para o peito do defesa
    const v = new R3.T.Vector3(perp.x * s + A.x * 0.15, -0.12, perp.y * s + A.y * 0.15).normalize(), rot = a.outer.rotation.y;
    aimArm(a, v.x * Math.cos(rot) - v.z * Math.sin(rot) >= 0, v, shove);
  }
  // defesa: colado ao lado do atacante; depois do contacto fica para trás (e às vezes cai)
  let dp = { x: apos.x - A.x * 0.25 + perp.x * s * 0.66, y: apos.y - A.y * 0.25 + perp.y * s * 0.66 };
  if (t > CT) {
    const u = t - CT, side = L.truth === 'anular' ? 1.5 * (1 - Math.exp(-u * 3)) : 0.35 * (1 - Math.exp(-u * 3)), back = Math.min(u, 1.2) * (L.truth === 'anular' || L.fall ? vA * 0.75 : vA * 0.45);
    dp = { x: dp.x + perp.x * s * side - A.x * back, y: dp.y + perp.y * s * side - A.y * back };
  }
  placeRig(d, dp.x, dp.y, A.x, A.y);
  const dRun = runAt(t, 1.3, t < CT ? 0.8 : Math.max(0.15, 0.8 - (t - CT) * 0.6));
  if (L.fall && t > CT) { const u = t - CT - (L.truth === 'anular' ? 0.02 : 0.12); setPose(d, u < 0 ? dRun : { mix: [dRun, L.truth === 'anular' ? { clip: 'fallback', t: 0.3 + u } : { clip: 'dive', t: 0.1 + u * 1.1 }, smooth(u / 0.15)] }); }
  else setPose(d, dRun);
  // guarda-redes: atira-se para o lado do remate, sem chegar
  const gpos = { x: L.gx - L.dirIn * 1.3, y: lerp(H / 2, Pk.y, 0.15) }, gs = G.y >= gpos.y ? 1 : -1;
  placeRig(tk, gpos.x, gpos.y, -L.dirIn * 0.35, gs);
  const gu = t - (HT - 0.45);
  setPose(tk, gu < 0 ? idleAt(t, 3) : { mix: [idleAt(t, 3), { clip: 'dive', t: gu * 1.1 }, smooth(gu / 0.12)] });
  // bola: nos pés do atacante, remate em KT, rede em HT
  const b0 = { x: Pk.x + A.x * 0.45, y: Pk.y + A.y * 0.45 };
  let bx, by, bh;
  if (t < KT) { bx = apos.x + A.x * 0.55; by = apos.y + A.y * 0.55; bh = 0.11; R3.ball.rotation.x += 0.15; }
  else if (t < HT) { const u = (t - KT) / (HT - KT); bx = lerp(b0.x, G.x, u); by = lerp(b0.y, G.y, u); bh = lerp(0.11, 0.8, u) + Math.sin(u * Math.PI) * 0.5; R3.ball.rotation.x += 0.35; }
  else { const u = t - HT, sd = Math.min(1.3, 6 * (1 - Math.exp(-u * 4)) / 4); bx = G.x + A.x * sd; by = G.y + A.y * sd; bh = Math.max(0.11, 0.8 - u * 1.8); }
  R3.ball.position.set(bx, bh, by);
  poseOthers5(L, t, KT, Pk);
  const mid = { x: (apos.x + dp.x) / 2, y: (apos.y + dp.y) / 2 }, k2 = smooth((t - KT) / 0.8);
  const look = { x: lerp(mid.x, (mid.x + G.x) / 2, k2), y: lerp(mid.y, (mid.y + G.y) / 2, k2) };
  const C = L.C, side = { x: -perp.x * s, y: -perp.y * s };
  sceneCam(L, t, look, lerp(8, len(G.x - mid.x, G.y - mid.y) + 6, k2), { x: C.x - A.x * 6.5 + side.x * 1.6, y: C.y - A.y * 6.5 + side.y * 1.6, h: 2.5, look: { x: C.x + A.x * 1.2, y: C.y + A.y * 1.2 }, w: 6.5 });
}
function poseLine(L, t) {
  const { a, d } = L.rig, { B, Pk, A, KT, HT, dirIn, gx } = L;
  const kp = kickPoint(L, a, Pk, A);
  poseKicker(a, Pk, A, t, KT);
  // guarda-redes recua para a linha e cai de costas em cima da bola
  const sy = B.y >= H / 2 ? 1 : -1, back = smooth(t / HT);
  const gp = { x: gx - dirIn * lerp(2.4, 1.05, back), y: lerp(H / 2 + (B.y - H / 2) * 0.4, B.y - sy * 0.35, back) };
  placeRig(d, gp.x, gp.y, -dirIn, 0);
  const gu = t - (HT - 0.38);
  setPose(d, gu < 0 ? runAt(t, 2, 0.35) : { mix: [runAt(t, 2, 0.35), { clip: 'fallback', t: 0.25 + gu }, smooth(gu / 0.15)] });
  // bola: chega à linha em HT, fica presa uns instantes e o guarda-redes puxa-a para fora
  const b0 = kp ? { x: kp.x + A.x * 0.13, y: kp.y + A.y * 0.13 } : Pk;
  let bx, by, bh;
  if (t < KT) { bx = b0.x; by = b0.y; bh = 0.11; }
  else if (t < HT) { const u = (t - KT) / (HT - KT); bx = lerp(b0.x, B.x, u); by = lerp(b0.y, B.y, u); bh = lerp(0.11, B.h, u) + Math.sin(u * Math.PI) * 0.6; R3.ball.rotation.x += 0.35; }
  else if (t < HT + 0.32) { const u = t - HT; bx = B.x + dirIn * 0.01 * Math.sin(u * 30); by = B.y; bh = Math.max(0.11, B.h - u * 0.6); }
  else { const u = smooth((t - HT - 0.32) / 0.6); bx = lerp(B.x, gx - dirIn * 0.85, u); by = B.y; bh = Math.max(0.11, B.h - 0.19 - u * 0.2); }
  R3.ball.position.set(bx, bh, by);
  poseOthers5(L, t, HT, B);
  const ny = H / 2 + sy * (GOAL_W / 2 + 4.2);
  if (L.ideal) { const c = $('capL'), inRight = (B.y > ny) ? dirIn < 0 : dirIn > 0, hint = ' · baliza do lado ' + (inRight ? 'direito' : 'esquerdo'); if (!c.textContent.includes('baliza')) c.textContent += hint; }
  sceneCam(L, t, { x: lerp(Pk.x, B.x, smooth((t - KT + 0.3) / 0.7)), y: lerp(Pk.y, B.y, smooth((t - KT + 0.3) / 0.7)) }, 9,
    { x: gx, y: ny, h: 0.75, look: { x: gx, y: B.y }, lh: Math.max(0.15, B.h - 0.1), w: 2.6 });
}

// ---------- livres diretos: barreira a 9,15 m ----------
function fkCheck(tk) {
  if (S.training || !tk || tk.off || mode === 'fim') return;
  const team = tk.team, gx = oppGoalX(team), d = len(gx - tk.x, H / 2 - tk.y);
  if (d < 17 || d > 31 || Math.abs(tk.y - H / 2) > 17 || inOwnBox(1 - team, tk.x, tk.y)) return;
  const spot = { x: tk.x, y: tk.y }, toG = norm(gx - spot.x, H / 2 - spot.y), perp = { x: -toG.y, y: toG.x };
  const short = Math.random() < 0.6, wd = short ? rand(6.3, 8.2) : rand(9.05, 9.6), n = d < 23 ? 4 : 3;
  const C0 = { x: spot.x + toG.x * wd, y: spot.y + toG.y * wd };
  const defs = active().filter(p => p.team !== team && p.role !== 'gk' && !p.off).sort((p, q) => len(p.x - C0.x, p.y - C0.y) - len(q.x - C0.x, q.y - C0.y)).slice(0, n);
  S.fk = { team, tk: tk.id, spot, toG, perp, d, wd, d0: wd, tgt: wd, wall: defs.map(p => p.id), t: 0, phase: 'set', short, creep: short && Math.random() < 0.45 };
  tk.x = spot.x - toG.x * 1.0; tk.y = spot.y - toG.y * 1.0; tk.vx = tk.vy = 0; tk.cd = 99;
  fkPlace(S.fk);
}
function fkPlace(F) {
  const n = F.wall.length;
  F.wall.forEach((id, i) => {
    const p = S.players[id]; if (!p || p.off) return;
    const dd = F.wd + (F.creepId === id ? -F.creepD : 0);
    p.x = F.spot.x + F.toG.x * dd + F.perp.x * (i - (n - 1) / 2) * 0.85; p.y = F.spot.y + F.toG.y * dd + F.perp.y * (i - (n - 1) / 2) * 0.85; p.vx = p.vy = 0;
  });
}
const fx1 = v => v.toFixed(1).replace('.', ',');
function fkStep(dt) {
  const F = S.fk; if (!F) return;
  const tk = S.players[F.tk];
  if (tk.off || S.ball.owner !== tk) { S.fk = null; return; }
  F.t += dt; S.pause = Math.max(S.pause, 0.05);
  F.wd += clamp(F.tgt - F.wd, -2.5 * dt, 2.5 * dt);
  if (F.creepId !== undefined && F.creepD < 1.2) F.creepD += dt * 0.8;
  fkPlace(F);
  if (F.phase === 'set' && F.t > 1.6) {
    F.phase = 'ask';
    askOpen('Livre direto ' + deT(F.team) + ' a ' + Math.round(F.d) + ' m da baliza. Olha para a barreira: está a 9,15 m?', 'Livre direto',
      [{ d: 'bater', label: 'Mandar bater', small: 'a barreira está bem' }, { d: 'medir', label: 'Medir 9,15 m', small: 'spray e recuar' }, { d: 'amarelo', label: 'Amarelo', small: 'a quem não recua', sw: 'var(--whistle)' }],
      c => fkFirst(c), 0);
  } else if (F.phase === 'creep' && F.t > F.creepAt) {
    F.phase = 'ask2';
    const p = S.players[F.creepId];
    askOpen('Já com o spray no chão, o ' + p.num + ' ' + deT(p.team) + ' volta a adiantar-se na barreira.', 'Livre direto',
      [{ d: 'deixar', label: 'Deixar', small: 'é só um passo' }, { d: 'afastar', label: 'Afastar outra vez', small: 'mais um aviso' }, { d: 'amarelo', label: 'Amarelo', small: 'não respeita a distância', sw: 'var(--whistle)' }],
      c => fkSecond(c, p), 0);
  } else if (F.phase === 'kick' && F.t > F.kickAt) fkKick(F, tk);
}
function fkFirst(c) {
  const F = S.fk; if (!F) return;
  const ok = !F.short, best = ok ? 'bater' : 'medir';
  const pts = c === best ? 1 : (!ok && c === 'amarelo') ? 0.5 : (ok && c === 'medir') ? 0.6 : 0;
  let dc = pts === 1 ? 2 : pts >= 0.5 ? -1 : -5; if (dc < 0) dc *= authK();
  S.control = clamp(S.control + dc, 0, 100);
  let msg;
  if (c === 'medir') { F.sprayed = true; F.tgt = 9.15; S.added += 0.2; msg = 'Spray no chão: barreira a 9,15 m'; S.ref.tx = clamp(F.spot.x + F.toG.x * 9.15 + F.perp.x * 3, -2, W + 2); S.ref.ty = clamp(F.spot.y + F.toG.y * 9.15 + F.perp.y * 3, -2, H + 2); }
  else if (c === 'amarelo') {
    const p = S.players[F.wall[0]]; F.tgt = 9.15; F.sprayed = true;
    p.yellow++; msg = 'Amarelo ao ' + p.num + ' ' + deT(p.team) + ' por não respeitar a distância';
    if (p.yellow >= 2) { p.off = true; msg = 'Segundo amarelo: ' + p.num + ' ' + deT(p.team) + ' expulso'; F.wall = F.wall.filter(id => id !== p.id); }
    Sfx.whistle('long'); feed(msg + '.', 'card');
  } else { msg = F.short ? 'Mandaste bater com a barreira a ' + fx1(F.wd) + ' m' : 'Barreira no sítio: pode bater'; if (F.short) protestAfterSoon(F.team); }
  S.manage.push({ minute: minuteNow(), what: 'Livre direto: barreira a ' + fx1(F.d0) + ' m', dec: { bater: 'Mandar bater', medir: 'Medir 9,15 m', amarelo: 'Amarelo' }[c], pts,
    why: pts === 1 ? 'Certo' : ok ? (c === 'medir' ? 'A barreira já estava bem: perdeste tempo' : 'Cartão sem razão: a barreira estava bem') : (c === 'amarelo' ? 'Primeiro mede e afasta; o cartão é para quem insiste' : 'A barreira estava perto demais') });
  toast(msg, 2);
  if (c === 'medir' && F.creep) { F.phase = 'creep'; F.creepAt = F.t + 2.2; F.creepId = F.wall[Math.floor(Math.random() * F.wall.length)]; F.creepD = 0; }
  else { F.phase = 'kick'; F.kickAt = F.t + (c === 'bater' ? 0.8 : 1.8); }
}
function fkSecond(c, p) {
  const F = S.fk; if (!F) return;
  const pts = c === 'amarelo' ? 1 : c === 'afastar' ? 0.5 : 0;
  let dc = pts === 1 ? 2 : pts > 0 ? -1 : -4; if (dc < 0) dc *= authK();
  S.control = clamp(S.control + dc, 0, 100);
  let msg = c === 'deixar' ? 'Deixaste o ' + p.num + ' adiantado' : c === 'afastar' ? 'Voltaste a afastar o ' + p.num : 'Amarelo ao ' + p.num + ' ' + deT(p.team) + ': não respeitou a distância';
  if (c === 'amarelo') { p.yellow++; if (p.yellow >= 2) { p.off = true; msg = 'Segundo amarelo: ' + p.num + ' ' + deT(p.team) + ' expulso'; F.wall = F.wall.filter(id => id !== p.id); } Sfx.whistle('long'); feed(msg + '.', 'card'); }
  if (c !== 'deixar') F.creepId = undefined;
  S.manage.push({ minute: minuteNow(), what: 'Jogador volta a adiantar-se na barreira', dec: { deixar: 'Deixar', afastar: 'Afastar outra vez', amarelo: 'Amarelo' }[c], pts,
    why: pts === 1 ? 'Certo: depois do spray, quem avança leva amarelo' : c === 'afastar' ? 'Já tinha sido avisado: era amarelo' : 'Deixaste a barreira encurtar' });
  toast(msg, 2);
  F.phase = 'kick'; F.kickAt = F.t + 1.2;
}
function protestAfterSoon(team) { S.pause = Math.max(S.pause, 0.3); setTimeout(() => { if (S && mode === 'play' && !S.fk) protestAfter(team, 0.3, true); }, 2600); }
function fkKick(F, tk) {
  S.fk = null; tk.cd = 0;
  const b = S.ball;
  shoot(tk, false);
  // remate por cima da barreira: desce a tempo de entrar (ou não)
  const sp = Math.max(14, len(b.vx, b.vy)), tg = F.d / sp, zg = rand(0.5, 2.6);
  b.vz = (zg + 0.5 * G * tg * tg) / tg;
  S.pause = 0;
  feed('Livre direto ' + deT(F.team) + ': o ' + tk.num + ' bate por cima da barreira.', 'info');
}
// spray no relvado
function drawFK() {
  const F = S && S.fk; if (!F || !F.sprayed) return;
  const s = view.s, P = (x, y) => [view.ox + x * s, view.oy + y * s];
  const c = { x: F.spot.x + F.toG.x * 9.15, y: F.spot.y + F.toG.y * 9.15 }, hw = F.wall.length * 0.55 + 0.8;
  ctx.save(); ctx.strokeStyle = 'rgba(255,255,255,.85)'; ctx.lineWidth = Math.max(1.5, 0.16 * s); ctx.setLineDash([0.35 * s, 0.2 * s]);
  ctx.beginPath(); ctx.moveTo(...P(c.x - F.perp.x * hw, c.y - F.perp.y * hw)); ctx.lineTo(...P(c.x + F.perp.x * hw, c.y + F.perp.y * hw)); ctx.stroke();
  ctx.setLineDash([]); ctx.beginPath(); ctx.arc(...P(F.spot.x, F.spot.y), 0.6 * s, 0, Math.PI * 2); ctx.stroke(); ctx.restore();
}
