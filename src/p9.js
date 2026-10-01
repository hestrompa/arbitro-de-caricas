// ---------- fase 6: o árbitro em 3D comunica a decisão (cartão, gesto e uma frase aos jogadores) ----------
const GOAL_OK = d => d === 'valido' || d === 'entrou';
function refSays(L, d) {
  const tag = L.varFirst && L.varFirst !== d ? 'Vi as imagens. ' : '';
  const p = L.def && S.players[L.def.id], second = p && p.off && (d === 'amarelo' || d === 'maoAmarelo');
  let s;
  if (L.kind === 'offside') s = L.goal !== undefined ? (d === 'fora' ? 'Golo anulado: estavas em fora de jogo no passe.' : 'Estava em jogo. O golo conta!') : d === 'fora' ? 'Fora de jogo: estavas à frente do penúltimo defesa.' : 'Estava em jogo, siga!';
  else if (L.kind === 'aereo') s = { siga: 'Os dois foram à bola. Siga!', falta: 'Empurraste-o nas costas no salto. Falta.', amarelo: 'Usaste o braço como alavanca. Amarelo.', vermelho: 'Cotovelada na cara. Vermelho!' }[d] || 'Siga!';
  else if (L.kind === 'agarrao') s = { siga: 'Foi só um toque. Siga!', falta: 'Agarraste a camisola. Falta.', amarelo: 'Agarraste e paraste o contra-ataque. Amarelo.', vermelho: 'Agarrão a impedir um golo. Vermelho!' }[d] || 'Siga!';
  else if (L.kind === 'golo') s = d === 'valido' ? 'Foi ombro com ombro. O golo conta!' : 'Empurraste o defesa antes do remate. Golo anulado.';
  else if (L.kind === 'linha') s = d === 'entrou' ? 'A bola passou toda a linha. É golo!' : 'Não passou toda a linha. Não há golo.';
  else if (L.kind === 'mao') s = d === 'siga' ? 'Braço junto ao corpo, posição natural. Siga!' : d === 'mao' ? 'Braço aberto, a fazer o corpo maior. É mão.' : 'Mão deliberada a cortar o remate: amarelo.';
  else if (L.kind === 'canto') s = d === 'siga' ? 'Disputa normal na área. Siga, levanta-te!' : d === 'penalti' ? 'Empurrou-o pelas costas. Penálti!' : 'Afastaste o defesa com o braço. Falta atacante.';
  else s = {
    siga: 'Jogou a bola primeiro. Siga!',
    falta: L.inBox ? 'Chegaste atrasado e derrubaste-o. Penálti!' : 'Chegaste atrasado. Falta.',
    amarelo: L.why === 'reiterada' ? 'Já são faltas a mais. Amarelo.' : L.why === 'tatica' ? 'Cortaste o contra-ataque. Amarelo.' : 'Entrada imprudente. Amarelo.',
    vermelho: 'Entrada com força excessiva, pões o adversário em risco. Vermelho!',
    simulacao: 'Atiraste-te para o chão. Amarelo por simulação.',
    vantagem: 'Vantagem! Joguem, joguem!',
  }[d] || 'Siga!';
  if (second) s += ' É o segundo: rua!';
  return tag + s;
}
// que gesto fazer e quem fica à frente do árbitro
function gestOf(L, d) {
  const att = L.att && S.players[L.att.id], def = L.def && S.players[L.def.id];
  const atkT = L.kind === 'offside' ? L.oi.team : L.goal !== undefined ? L.goal : att ? att.team : 0;
  const pen = { x: oppGoalX(atkT) - TEAMS[atkT].dir * SPOT, y: H / 2 };
  if (d === 'vermelho') return { type: 'card', col: 'red', who: def };
  if (d === 'amarelo' || d === 'maoAmarelo' || d === 'simulacao') { const w = d === 'simulacao' ? att : def; return { type: 'card', col: 'yellow', second: !!(w && w.off), who: w }; }
  if (d === 'fora') return { type: 'up', who: att };
  if (d === 'vantagem') return { type: 'adv', who: null };
  if (GOAL_OK(d) || (L.goal !== undefined && d === 'emjogo')) return { type: 'point', to: { x: W / 2, y: H / 2 }, elev: -0.12, who: null, run: true };
  if (d === 'anular' || d === 'ataque') return { type: 'point', dir: { x: TEAMS[1 - atkT].dir, y: 0 }, elev: 0.12, who: att };
  if ((L.scene && scenePen(L, d)) || (!L.scene && L.kind !== 'offside' && FOUL(d) && L.inBox)) return { type: 'point', to: pen, elev: -0.55, who: def };
  if (FOUL(d) || d === 'mao') return { type: 'point', dir: { x: TEAMS[atkT].dir, y: 0 }, elev: 0.12, who: def };
  return { type: 'siga', who: att };
}
function gestSpot(L) {
  const p = L.kind === 'offside' ? { x: L.oi.recvX, y: L.oi.recvY } : L.kind === 'linha' ? { x: L.gx - L.dirIn * 4, y: L.B.y } : L.kind === 'golo' ? L.C : L.P;
  return { x: clamp(p.x, 3, W - 3), y: clamp(p.y, 3, H - 3) };
}
function finishDecision(L, d, msg, after) {
  showDecide(false);
  if (!R3 || !stage.classList.contains('view3d') || S.noGesture) { after(); return; }
  const g = gestOf(L, d), say = refSays(L, d);
  S.gesture = { L, d, g, t: 0, dur: g.type === 'card' && g.second ? 3.2 : 2.6, after };
  mode = 'gesto';
  $('scrub').hidden = true; $('viewBtns').hidden = true; $('pip').hidden = true;
  $('capL').textContent = 'Decisão do árbitro · toca para continuar'; $('capR').textContent = DEC_LABEL[d] || '';
  $('refSay').textContent = say; $('refSay').hidden = false;
  if (g.type === 'card') Sfx.whistle('short');
  if (/VAR confirmou/.test(msg)) radio('VAR', 'Check completo. Decisão confirmada.');
}
function gestureEnd() {
  const G = S && S.gesture; if (!G) return;
  S.gesture = null; $('refSay').hidden = true;
  if (R3) { R3.ball.visible = true; if (CARD) CARD.visible = false; }
  G.after();
}
function gestureStep(dt) { const G = S.gesture; G.t += dt; if (G.t >= G.dur) gestureEnd(); }
stage.addEventListener('pointerdown', () => { if (mode === 'gesto') gestureEnd(); });

let CARD = null;
const IDQ = { x: 0, y: 0, z: 0, w: 1 };
function cardMesh(ref) {
  if (CARD) return CARD;
  const T = R3.T, m = new T.Mesh(new T.BoxGeometry(0.1, 0.14, 0.008), new T.MeshBasicMaterial({ color: '#f2cf3a' }));
  const dir = ref.handR.position.clone().normalize();
  m.position.copy(dir.multiplyScalar(0.16)); ref.handR.add(m);
  return (CARD = m);
}
// aponta o braço inteiro (ombro→pulso) para uma direção do mundo, com o cotovelo esticado
function aimArm(r, right, v, w) {
  if (w <= 0) return;
  const T = R3.T, up = right ? r.armR : r.armL, lo = right ? r.elR : r.elL, hd = right ? r.handR : r.handL;
  lo.quaternion.slerp(new T.Quaternion(IDQ.x, IDQ.y, IDQ.z, IDQ.w), w * 0.85);
  r.outer.updateMatrixWorld(true);
  const a = up.getWorldPosition(new T.Vector3()), b = hd.getWorldPosition(new T.Vector3());
  const cur = b.sub(a).normalize(), want = cur.clone().lerp(v, w).normalize();
  const qw = new T.Quaternion().setFromUnitVectors(cur, want), pq = up.parent.getWorldQuaternion(new T.Quaternion());
  up.quaternion.premultiply(pq.clone().invert().multiply(qw).multiply(pq));
}
function poseGesture(G) {
  const R = R3, T = R.T, L = G.L, t = G.t, g = G.g;
  R.rigs.forEach(r => r.outer.visible = false); R.ball.visible = false; R.lines.def.visible = R.lines.att.visible = false;
  glassPosts(null);
  const P = gestSpot(L);
  let u = norm(L.ref.x - P.x, L.ref.y - P.y); if (!u.x && !u.y) u = { x: 0, y: 1 };
  const ref = R.rigs[22], pl = R.rigs[0];
  styleRig(ref, -1);
  const Rp = { x: P.x + u.x * 2.3, y: P.y + u.y * 2.3 }, F = { x: -u.x, y: -u.y };
  if (g.who) { styleRig(pl, g.who.team, g.who.role, g.who.num, g.who.id); placeRig(pl, P.x, P.y, u.x, u.y); setPose(pl, g.type === 'card' ? { clip: 'idle', t: t + 1, pp: true, add: { alz: -0.5, arz: 0.5 } } : idleAt(t, 1)); pl.outer.visible = true; }
  // golo validado: o árbitro dá uns passos para o meio-campo enquanto aponta
  let rp = Rp, face = F;
  if (g.type === 'point' && g.run) { const dc = norm(g.to.x - Rp.x, g.to.y - Rp.y), m = Math.min(t, 1.6) * 1.3; rp = { x: Rp.x + dc.x * m, y: Rp.y + dc.y * m }; face = norm(lerp(F.x, dc.x, 0.6), lerp(F.y, dc.y, 0.6)); }
  placeRig(ref, rp.x, rp.y, face.x, face.y); ref.outer.visible = true;
  setPose(ref, g.run && t < 1.6 ? runAt(t, 0, 0.3) : idleAt(t, 2));
  const w = smooth((t - 0.15) / 0.4), rot = ref.outer.rotation.y, xAx = new T.Vector3(Math.cos(rot), 0, -Math.sin(rot)), fwd = new T.Vector3(Math.sin(rot), 0, Math.cos(rot)), upV = new T.Vector3(0, 1, 0);
  const card = cardMesh(ref); card.visible = false;
  if (g.type === 'card' || g.type === 'up') {
    aimArm(ref, true, upV.clone().multiplyScalar(1).add(xAx.clone().multiplyScalar(0.12)).add(fwd.clone().multiplyScalar(0.1)).normalize(), w);
    if (g.type === 'card') { card.visible = w > 0.3; card.material.color.set(g.col === 'red' || (g.second && t > 1.6) ? '#d8322f' : '#f2cf3a'); }
  } else if (g.type === 'adv') {
    for (const right of [true, false]) aimArm(ref, right, fwd.clone().add(xAx.clone().multiplyScalar(right ? 0.22 : -0.22)).add(upV.clone().multiplyScalar(0.05)).normalize(), w);
  } else if (g.type === 'point') {
    const dir = g.to ? norm(g.to.x - rp.x, g.to.y - rp.y) : g.dir, c = Math.cos(g.elev);
    const v = new T.Vector3(dir.x * c, Math.sin(g.elev), dir.y * c).normalize();
    aimArm(ref, v.dot(xAx) >= 0, v, w);
  } else {
    aimArm(ref, true, fwd.clone().multiplyScalar(0.75).add(xAx.clone().multiplyScalar(0.25)).add(upV.clone().multiplyScalar(-0.35 + 0.3 * Math.sin(t * 5))).normalize(), w);
  }
  // câmara de frente para o árbitro, com o jogador ao lado
  const side = { x: -u.y, y: u.x };
  if (g.run) {                                                         // golo: câmara à frente do árbitro, que corre para o meio-campo
    const dc = norm(g.to.x - Rp.x, g.to.y - Rp.y), sd = { x: -dc.y, y: dc.x };
    rp = { x: rp.x + dc.x * 4.5 + sd.x * 2.2, y: rp.y + dc.y * 4.5 + sd.y * 2.2 }; u = { x: dc.x, y: dc.y };
    const cx = clamp(rp.x, -3, W + 3), cy = clamp(rp.y, -3, H + 3), lk = ref.outer.position, dist = Math.max(1, len(lk.x - cx, lk.z - cy));
    R.cam.fov = clamp(2 * Math.atan(1.5 / dist) * 180 / Math.PI, 14, 55); R.cam.updateProjectionMatrix();
    R.cam.position.set(cx, 1.6, cy); R.cam.lookAt(lk.x, 1.25, lk.z); R.renderer.render(R.scene, R.cam); return;
  }
  let cx = rp.x - u.x * 3.8 + side.x * 3.4, cy = rp.y - u.y * 3.8 + side.y * 3.4;
  if (cx < -3 || cx > W + 3 || cy < -3 || cy > H + 3) { cx = rp.x - u.x * 3.8 - side.x * 3.4; cy = rp.y - u.y * 3.8 - side.y * 3.4; }
  cx = clamp(cx, -3, W + 3); cy = clamp(cy, -3, H + 3);
  const look = { x: lerp(rp.x, P.x, 0.3), y: lerp(rp.y, P.y, 0.3) }, dist = Math.max(1, len(look.x - cx, look.y - cy));
  const vfov = clamp(2 * Math.atan(Math.tan(Math.atan(4.6 / 2 / dist)) / R.cam.aspect) * 180 / Math.PI, 14, 55);
  R.cam.fov = Math.max(vfov, 2 * Math.atan(1.35 / dist) * 180 / Math.PI); R.cam.updateProjectionMatrix();
  R.cam.position.set(cx, 1.6, cy); R.cam.lookAt(look.x, 1.3, look.y);
  R.renderer.render(R.scene, R.cam);
}
