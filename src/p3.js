// ---------- fase 3: público, VAR e protestos ----------
const HOME = 0;                                   // os Azuis jogam em casa
function crowdReact(against, wrong) {
  // against: equipa prejudicada pela decisão
  if (against === HOME) { S.crowd = clamp(S.crowd + 9 + (wrong ? 12 : 0), 0, 100); Sfx.boo(0.5 + S.crowd / 200); }
  else { S.crowd = clamp(S.crowd - 4, 0, 100); if (wrong) Sfx.cheer(0.35); }
}
const FOUL = d => d === 'falta' || d === 'amarelo' || d === 'vermelho';
function needsVar(L, d) {
  if (L.kind === 'offside') return (d === 'fora') !== (L.truth === 'fora') && Math.abs(L.oi.margin) > 0.03;
  if (d === L.truth) return false;
  if (d === 'vermelho' || L.truth === 'vermelho') return true;                 // expulsão
  if (L.inBox && FOUL(d) !== FOUL(L.truth)) return true;                      // penálti
  return false;
}
function varEligible(L, d) { return L.kind === 'offside' || d === 'vermelho' || L.truth === 'vermelho' || (L.inBox && (FOUL(d) || FOUL(L.truth))); }
function startVar(L, d) {
  L.varFirst = d; L.varDone = true;
  showDecide(false); hide3D();
  Sfx.beep();
  $('flash').textContent = 'VAR'; $('flash').hidden = false;
  toast('O VAR pede revisão no monitor', 1.6);
  setTimeout(() => {
    $('flash').hidden = true; $('flash').textContent = 'Lance!';
    if (mode !== 'lance') return;
    L.varReview = true; L.ideal = true; L.decideT = 20;
    show3D(L, false);
    L.seen = true; L.speed = 0.5;
    if (L.kind === 'offside') {
      const oi = L.oi, ld = oi.snap.find(q => q.id === oi.lineDef), rc = oi.snap.find(q => q.id === oi.receiver);
      L.userLines = { def: ld ? ld.x : oi.lineX, att: rc ? rc.x : oi.recvX, sel: 'att' };
      L.paused = true; L.time = OFF_KT;
    }
    captions3D(L); syncScrub();
  }, 1300);
}
// linhas do VAR: arrasta no relvado a linha mais próxima do ponteiro
let varDrag = null;
function varPointer(e, down) {
  const L = S && S.lance;
  if (!R3 || !L || !L.varReview || L.kind !== 'offside' || mode !== 'lance') return false;
  const r = c3d.getBoundingClientRect(), T = R3.T;
  const ndc = new T.Vector2(((e.clientX - r.left) / r.width) * 2 - 1, -((e.clientY - r.top) / r.height) * 2 + 1);
  const ray = new T.Raycaster(); ray.setFromCamera(ndc, R3.cam);
  const hit = new T.Vector3();
  if (!ray.ray.intersectPlane(new T.Plane(new T.Vector3(0, 1, 0), 0), hit)) return false;
  const u = L.userLines;
  if (down) varDrag = Math.abs(hit.x - u.def) < Math.abs(hit.x - u.att) ? 'def' : 'att';
  if (!varDrag) return false;
  u[varDrag] = clamp(hit.x, 0, W); u.sel = varDrag;
  captions3D(L);
  return true;
}
function varReadout(L) {
  const u = L.userLines, ti = L.oi.team, g = rel(ti, u.att) - rel(ti, u.def);
  return 'Linhas: atacante ' + Math.abs(g).toFixed(2).replace('.', ',') + ' m ' + (g > 0 ? 'à frente' : 'atrás');
}

// protestos: os jogadores prejudicados vão ter com o árbitro
function protestAfter(team, sev, wrong) {
  if (team === null || team === undefined || mode !== 'play') return;
  const I = clamp(sev + (wrong ? 0.35 : 0) + S.aggr[team] * 0.3 + (team === HOME ? S.crowd / 100 * 0.15 : 0) + rand(-0.1, 0.1), 0, 1);
  if (I < 0.3) return;
  const ps = active().filter(p => p.team === team && p.role !== 'gk').sort((a, b) => len(a.x - S.ref.x, a.y - S.ref.y) - len(b.x - S.ref.x, b.y - S.ref.y)).slice(0, 1 + Math.round(I * 3));
  S.protest = { team, ids: ps.map(p => p.id), I, t: 0 };
  mode = 'protesto';
  $('protestMsg').textContent = (ps.length > 1 ? ps.length + ' jogadores dos ' : 'Um jogador dos ') + TEAMS[team].name + ' ' + (ps.length > 1 ? 'vêm' : 'vem') + ' protestar' + (I > 0.7 ? ', muito exaltados' : I > 0.5 ? ', exaltados' : '');
  $('protestBar').style.width = Math.round(I * 100) + '%';
  $('protest').hidden = false; $('decide').hidden = true;
  if (team === HOME) Sfx.boo(0.4 + I * 0.4);
}
function protestStep(dt) {
  const P = S.protest; P.t += dt;
  const r = S.ref;
  S.players.forEach(p => { p.vx *= 0.9; p.vy *= 0.9; });
  P.ids.forEach((id, i) => {
    const p = S.players[id], a = i / Math.max(1, P.ids.length) * Math.PI * 1.4 - 0.7 + Math.atan2(p.y - r.y, p.x - r.x);
    const tx = r.x + Math.cos(a) * 1.9, ty = r.y + Math.sin(a) * 1.9;
    moveTo(p, tx, ty, 6.5, dt);
  });
  if (P.t > 8) resolveProtest('ignorar', true);
}
function resolveProtest(choice, timedOut) {
  const P = S.protest; if (!P || mode !== 'protesto') return;
  const I = P.I; let dc = 0, msg = '';
  if (choice === 'ignorar') { dc = I > 0.6 ? -8 : I > 0.4 ? -3 : 1; S.aggr[P.team] += I * 0.15; msg = timedOut ? 'Deixaste-os falar: ' : 'Ignoraste os protestos: '; msg += dc < 0 ? 'o ambiente aquece' : 'acalmaram'; }
  else if (choice === 'afastar') { dc = I > 0.75 ? -3 : 2; S.aggr[P.team] = Math.max(0.05, S.aggr[P.team] - 0.05); msg = dc > 0 ? 'Afastaste os jogadores com firmeza' : 'Afastaste-os, mas continuam a reclamar'; }
  else {
    const p = S.players[P.ids[0]];
    p.yellow++; dc = I > 0.55 ? 6 : -5;
    if (I > 0.55) S.aggr[P.team] = Math.max(0.05, S.aggr[P.team] - 0.2);
    msg = 'Amarelo por protestos ao ' + p.num + ' dos ' + TEAMS[p.team].name;
    if (p.yellow >= 2) { p.off = true; msg = 'Segundo amarelo por protestos: ' + p.num + ' expulso'; if (S.ball.owner === p) S.ball.owner = null; }
    if (dc < 0) msg += ' · pareceu exagerado';
    Sfx.whistle('short');
  }
  S.control = clamp(S.control + dc, 0, 100);
  S.protests.push({ minute: Math.min(90, Math.floor(S.t / MATCH_SECONDS * 90) + 1), choice, I, dc });
  S.protest = null;
  $('protest').hidden = true;
  toast(msg, 2.4);
  mode = 'play'; S.pause = Math.max(S.pause, 0.8);
  if (S.control <= 10) endMatch('abandonado');
}

// treino do VAR: seis lances seguidos em que a decisão de campo vai ao monitor
function startTraining() {
  start();
  S.training = { n: 0, next: 1.2, total: 6 };
  toast('Treino do VAR: seis lances para rever no monitor', 2.5);
}
function trainNext() {
  const T = S.training; T.n++;
  if (T.n > T.total) { endMatch('treino'); return; }
  T.next = 2.5;
  if (T.n % 2 === 0) trainOffside(); else trainFoul();
}
function trainFoul() {
  const att = S.players.find(p => p.team === 1 && p.role === 'st'), def = S.players.find(p => p.team === 0 && p.role === 'lcb');
  att.off = def.off = false;
  att.x = rand(7, 14); att.y = rand(24, 44); att.vx = -5; att.vy = rand(-1, 1);
  def.x = att.x + rand(-2.5, 2); def.y = att.y + (Math.random() < 0.5 ? -1 : 1) * rand(3, 4.5);
  const a = Math.random() * Math.PI; S.ref.x = clamp(att.x + Math.cos(a) * rand(12, 22), 1, W / 2); S.ref.y = clamp(att.y + Math.sin(a) * rand(10, 20), 1, H - 1);
  startLance(att, def);
  const L = S.lance, truths = ['vermelho', 'falta', 'siga', 'amarelo', 'simulacao'];
  L.truth = truths[Math.floor(Math.random() * truths.length)]; L.fall = L.truth !== 'siga' || Math.random() < 0.6; L.training = true;
  const wrong = Object.values(DKEYS).filter(d => d !== L.truth);
  const d0 = Math.random() < 0.65 ? wrong[Math.floor(Math.random() * wrong.length)] : L.truth;
  setTimeout(() => { if (mode === 'lance' && S.lance === L) startVar(L, d0); }, 1500);
}
function trainOffside() {
  const P = S.players, lineX = rand(70, 86), margin = rand(-0.7, 0.7), byRole = (t, r) => P.find(p => p.team === t && p.role === r);
  P.forEach(p => { p.off = false; p.vx = p.vy = 0; });
  P.filter(p => p.team === 1).forEach(p => { if (p.role === 'gk') { p.x = W - 3; p.y = H / 2; } else p.x = Math.min(p.x, lineX - 3); });
  ['lb', 'lcb', 'rcb', 'rb'].forEach((r, i) => { const p = byRole(1, r); p.x = i === 1 ? lineX : lineX - rand(0.4, 2.5); p.y = [12, 27, 41, 56][i] + rand(-2, 2); p.vx = -rand(0.5, 2.5); });
  P.filter(p => p.team === 0).forEach(p => { p.x = Math.min(p.x, lineX - 4); });
  const recv = byRole(0, 'st'), passer = byRole(0, 'cm');
  recv.x = lineX + margin; recv.y = rand(24, 36); recv.vx = rand(5, 7); recv.vy = rand(-1, 1);
  passer.x = lineX - rand(16, 24); passer.y = rand(30, 44); passer.vx = 2;
  const b = S.ball; Object.assign(b, { x: passer.x + 0.5, y: passer.y, z: 0, vx: 0, vy: 0, vz: 0, owner: null, target: null, trail: [] });
  S.ast[1].x = lineX + rand(-1.5, 1.5);
  offsideSnap(passer, recv);
  const oi = b.offInfo; b.offInfo = null;
  startOffside(oi);
  const L = S.lance; L.training = true;
  setTimeout(() => {
    if (mode !== 'lance' || S.lance !== L) return;
    const right = L.truth, d0 = Math.random() < 0.6 ? (right === 'fora' ? 'emjogo' : 'fora') : right;
    L.flag = d0 === 'fora';
    startVar(L, d0);
  }, 1600);
}
