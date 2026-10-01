// ---------- fase 7: lances novos em 3D: disputa aérea (cotovelada) e agarrão à camisola ----------
Object.assign(KEYS5, { aereo: { '1': 'siga', '2': 'falta', '3': 'amarelo', '4': 'vermelho' }, agarrao: { '1': 'siga', '2': 'falta', '3': 'amarelo', '4': 'vermelho' } });
Object.assign(KEYLBL, { aereo: 'Salto', agarrao: 'Agarrão' });
function startDuel(L0, dirAct, exclude, flash) {
  startScene(L0, dirAct, exclude, flash);
  Object.assign(S.lance, { scene: false, dOff: { x: 0, y: 0 } });
}
// bola longa: dois jogadores saltam à bola e um deles pode usar o braço
function aerialCheck(p, m) {
  if (mode !== 'play' || S.training || S.lanceCd > 0 || Math.random() > 0.14) return;
  const [opp, dd] = nearest(active().filter(q => q.team !== m.team && q.role !== 'gk'), m.x, m.y);
  if (!opp || dd > 7) return;
  const Q = { x: clamp(m.x, 4, W - 4), y: clamp(m.y, 4, H - 4) }, V = norm(Q.x - p.x, Q.y - p.y), s = Math.random() < 0.5 ? 1 : -1;
  const truth = pickTruth({ siga: 0.38, falta: 0.3, amarelo: 0.17 * (opp.hardK || 1), vermelho: 0.12 * (opp.hardK || 1) });
  const KT = 0.6, HT = 1.9;
  startDuel({ kind: 'aereo', truth, P: Q, Q, V, perp: { x: -V.y, y: V.x }, s, K: { x: p.x, y: p.y }, KT, HT, keyT: HT - 0.05, dur: HT + 2, inBox: inOwnBox(opp.team, Q.x, Q.y),
    att: pinfo(m), def: pinfo(opp), A: V, D: { x: -V.x, y: -V.y }, fall: truth !== 'siga' || Math.random() < 0.3 }, { x: -V.y, y: V.x }, [m, opp], 'Lance!');
}
// contra-ataque: o defesa fica para trás e agarra a camisola
function grabCheck(att, def) {
  if (!counterAttack(att) || Math.random() > 0.45 * (def.foulK || 1)) return false;
  const A = norm(oppGoalX(att.team) - att.x, H / 2 - att.y), s = Math.random() < 0.5 ? 1 : -1;
  const truth = pickTruth({ siga: 0.3, falta: 0.3, amarelo: 0.4 });
  const CT = 1.5, P = { x: att.x, y: att.y };
  startDuel({ kind: 'agarrao', truth, P, A, D: A, perp: { x: -A.y, y: A.x }, s, CT, keyT: CT + 0.15, dur: CT + 2.4, inBox: inOwnBox(def.team, P.x, P.y),
    att: pinfo(att), def: pinfo(def), counter: true, fall: truth === 'amarelo' || (truth === 'falta' && Math.random() < 0.5) }, { x: -A.y, y: A.x }, [att, def], 'Lance!');
  return true;
}
function poseDuel(L, t) { $('pip').hidden = true; if (L.kind === 'aereo') poseAerial(L, t); else poseGrab(L, t); }
function poseAerial(L, t) {
  const { a, d } = L.rig, { Q, V, perp, s, HT, KT } = L, T = R3.T, tr = L.truth;
  const jT = HT - 0.32, hop = u => 0.5 * Math.max(0, Math.sin(clamp(u / 0.65, 0, 1) * Math.PI));
  // vítima: corre na direção da bola e salta
  const ap = t < HT ? { x: Q.x - V.x * 4.5 * (HT - t), y: Q.y - V.y * 4.5 * (HT - t) } : { x: Q.x + V.x * 0.4 * Math.min(1, t - HT), y: Q.y + V.y * 0.4 * Math.min(1, t - HT) };
  placeRig(a, ap.x, ap.y, V.x, V.y);
  const aRun = runAt(t, 0, t < HT ? 0.65 : 0.1), ua = t - jT;
  let aPo = ua < 0 ? aRun : { mix: [aRun, jumpPose(hop(ua), 2.4), smooth(ua / 0.12) * (ua > 0.65 ? smooth(1 - (ua - 0.65) / 0.2) : 1)] };
  if (L.fall && t > HT + 0.05) { const f = t - HT - 0.05; aPo = { mix: [aPo, { clip: tr === 'vermelho' ? 'fallback' : 'dive', t: 0.15 + f * 1.1 }, smooth(f / 0.15)] }; }
  setPose(a, aPo);
  // quem faz a falta: vem de lado e salta ao mesmo tempo
  const side = { x: perp.x * s, y: perp.y * s };
  const dp = t < HT ? { x: Q.x + side.x * (0.65 + 3.2 * (HT - t)) - V.x * 0.25, y: Q.y + side.y * (0.65 + 3.2 * (HT - t)) - V.y * 0.25 } : { x: Q.x + side.x * 0.75, y: Q.y + side.y * 0.75 };
  const face = norm(-side.x * 0.8 + V.x * 0.5, -side.y * 0.8 + V.y * 0.5);
  placeRig(d, dp.x, dp.y, face.x, face.y);
  const dRun = runAt(t, 1.3, t < HT ? 0.6 : 0.1), ud = t - jT - 0.03;
  setPose(d, ud < 0 ? dRun : { mix: [dRun, jumpPose(hop(ud) * 0.95, tr === 'siga' ? 2.2 : 1.2), smooth(ud / 0.12) * (ud > 0.65 ? smooth(1 - (ud - 0.65) / 0.2) : 1)] });
  if (tr !== 'siga') {
    // braço: empurrão nas costas (falta), braço de alavanca no ombro (amarelo) ou cotovelo à cara (vermelho)
    d.outer.updateMatrixWorld(true); a.outer.updateMatrixWorld(true);
    const tgt = (tr === 'falta' ? a.spine : a.head).getWorldPosition(new T.Vector3()), sh = d.spine.getWorldPosition(new T.Vector3());
    const win = tr === 'vermelho' ? Math.max(0, Math.sin(clamp((t - (HT - 0.2)) / 0.35, 0, 1) * Math.PI)) : Math.max(0, Math.sin(clamp((t - (HT - 0.55)) / 0.85, 0, 1) * Math.PI));
    const v = tgt.sub(sh).normalize(), rot = d.outer.rotation.y, right = v.x * Math.cos(rot) - v.z * Math.sin(rot) >= 0;
    aimArm(d, right, v, win);
    if (tr === 'vermelho' && win > 0) { const el = right ? d.elR : d.elL; el.rotation.x -= 1.6 * win; }
  }
  // bola: cruzamento longo que chega às cabeças em HT
  const K = L.K, hitH = 2.45;
  let bx, by, bh;
  if (t < KT) { bx = K.x; by = K.y; bh = 0.11; }
  else if (t < HT) { const u = (t - KT) / (HT - KT); bx = lerp(K.x, Q.x, u); by = lerp(K.y, Q.y, u); bh = lerp(0.11, hitH, u) + 12 * u * (1 - u); }
  else { const u = t - HT, dir = norm(V.x * 0.4 + side.x * (tr === 'siga' ? -0.9 : 0.6), V.y * 0.4 + side.y * (tr === 'siga' ? -0.9 : 0.6)), sd = 8 * (1 - Math.exp(-u * 1.2)) / 1.2; bx = Q.x + dir.x * sd; by = Q.y + dir.y * sd; bh = hitH + 1.2 * u - 4.9 * u * u; if (bh < 0.11) bh = 0.11 + Math.abs(Math.sin(u * 5)) * 0.25 * Math.exp(-u * 2); }
  R3.ball.position.set(bx, bh, by);
  poseOthers5(L, t, HT, Q);
  const opp = { x: -side.x, y: -side.y };
  sceneCam(L, t, { x: Q.x, y: Q.y }, 7, { x: Q.x + opp.x * 1.2 - V.x * 6.5, y: Q.y + opp.y * 1.2 - V.y * 6.5, h: 2.6, look: { x: Q.x + side.x * 0.35, y: Q.y + side.y * 0.35 }, lh: 1.7, w: 4.5 });
}
function poseGrab(L, t) {
  const { a, d } = L.rig, { P, A, perp, s, CT } = L, T = R3.T, tr = L.truth;
  const hold = { siga: 0.22, falta: 0.6, amarelo: 1.0 }[tr] || 0.6, pull = smooth((t - CT) / 0.2) * (t < CT + hold ? 1 : smooth(1 - (t - CT - hold) / 0.25));
  // atacante em corrida; travado enquanto é agarrado
  const vA = 6.8, slow = tr === 'siga' ? 0.15 : tr === 'falta' ? 0.45 : 0.7;
  const dist = t < CT ? vA * (t - CT) : vA * (t - CT) - slow * vA * Math.min(t - CT, hold + 0.3);
  const ap = { x: P.x + A.x * dist, y: P.y + A.y * dist };
  placeRig(a, ap.x, ap.y, A.x, A.y);
  let aPo = runAt(t, 0, 0.85);
  if (pull > 0) aPo = Object.assign({}, aPo, { add: { alx: 0.5 * pull, arx: 0.5 * pull } });
  const fT = CT + hold - 0.1;
  if (L.fall && t > fT) { const f = t - fT; aPo = { mix: [runAt(fT, 0, 0.85), { clip: tr === 'amarelo' ? 'fallback' : 'dive', t: 0.2 + f * 1.1 }, smooth(f / 0.15)] }; }
  setPose(a, aPo);
  a.spine.rotation.x -= 0.35 * pull;
  // defesa: chega por trás e estica o braço até à camisola
  const lag = t < CT ? 1.6 - 1.0 * smooth(t / CT) : 0.6 + (t - CT - hold > 0 ? (t - CT - hold) * 3 : 0);
  const dp = { x: ap.x - A.x * lag + perp.x * s * 0.45, y: ap.y - A.y * lag + perp.y * s * 0.45 };
  placeRig(d, dp.x, dp.y, A.x, A.y);
  setPose(d, runAt(t, 1.1, t < CT + hold ? 0.85 : 0.5));
  if (pull > 0) {
    d.outer.updateMatrixWorld(true); a.outer.updateMatrixWorld(true);
    const tgt = a.spine.getWorldPosition(new T.Vector3()), sh = d.spine.getWorldPosition(new T.Vector3());
    const v = tgt.sub(sh).normalize(), rot = d.outer.rotation.y;
    aimArm(d, v.x * Math.cos(rot) - v.z * Math.sin(rot) >= 0, v, pull);
  }
  // bola: conduzida à frente; depois do agarrão fica a rolar
  const lose = CT + hold * 0.6;
  let bx, by;
  if (t < lose) { const k = dist + 0.6 + 0.25 * Math.abs(Math.sin(t * 4.2)); bx = P.x + A.x * k; by = P.y + A.y * k; }
  else { const d0 = (lose < CT ? vA * (lose - CT) : vA * (lose - CT) - slow * vA * Math.min(lose - CT, hold + 0.3)) + 0.7, u = t - lose; const k = d0 + 4 * (1 - Math.exp(-u * 1.5)) / 1.5; bx = P.x + A.x * k; by = P.y + A.y * k; }
  R3.ball.position.set(bx, 0.11, by);
  if (!L.paused) R3.ball.rotation.x += 0.15;
  poseOthers5(L, t, CT, P);
  const side = { x: perp.x * s, y: perp.y * s };
  sceneCam(L, t, { x: ap.x, y: ap.y }, 7, { x: P.x + side.x * 6.5 + A.x * 1.5, y: P.y + side.y * 6.5 + A.y * 1.5, h: 1.9, look: { x: P.x + A.x * 1.2, y: P.y + A.y * 1.2 }, lh: 1.1, w: 6 });
}
