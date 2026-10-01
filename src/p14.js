// ---------- fase 9: lances novos (guarda-redes fora da área, pisão, toque leve na área), voz e primeiro jogo guiado ----------
Object.assign(KEYS5, { pisao: { '1': 'siga', '2': 'falta', '3': 'amarelo', '4': 'vermelho' } });
Object.assign(KEYLBL, { pisao: 'Pisão' });
// lance com pesos próprios: o startLance usa S.forceW se existir
function forcedLance(att, def, wts, extra) {
  S.forceW = wts; startLance(att, def); S.forceW = null;
  const L = S.lance; if (!L) return null;
  Object.assign(L, extra);
  return L;
}
// guarda-redes sai da área ao encontro de um avançado isolado: último homem?
function gkOutCheck(p, dt) {
  if (mode !== 'play' || S.training || S.tut || S.lanceCd > 0 || p.role === 'gk' || Math.random() > dt * 1.1) return false;
  const r = rel(p.team, p.x);
  if (r < W - 34 || r > W - BOX_D - 3.5 || Math.abs(p.y - H / 2) > 18 || !counterAttack(p)) return false;
  const gk = active().find(q => q.team !== p.team && q.role === 'gk'); if (!gk) return false;
  const g = norm(oppGoalX(p.team) - p.x, H / 2 - p.y);
  gk.x = p.x + g.x * 2.6; gk.y = p.y + g.y * 2.6;
  const L = forcedLance(p, gk, { siga: 0.3, falta: 0.12, amarelo: 0.2, vermelho: 0.38 }, { gkOut: true });
  if (L && L.why) { L.why = null; }
  return !!L;
}
// toque leve na área: chega para penálti? Os dois lados têm argumentos
function lightCheck(att, def) {
  if (S.tut || !inOwnBox(def.team, att.x, att.y) || def.role === 'gk' || Math.random() > 0.18) return false;
  const L = forcedLance(att, def, { siga: 0.36, falta: 0.4, simulacao: 0.24 }, { light: true, fall: true });
  if (!L) return false;
  if (L.why === 'tatica' || L.why === 'reiterada') { L.truth = 'falta'; L.why = null; }
  if (L.truth === 'falta') { L.look = 'falta'; L.dOff = { x: -L.D.x * 0.14, y: -L.D.y * 0.14 }; }
  if (L.truth === 'siga') { L.look = 'siga'; L.dOff = { x: L.D.x * 0.22, y: L.D.y * 0.22 }; }
  return true;
}
// pisão: o avançado protege a bola de costas e o defesa entra por trás
function stampCheck(att, def) {
  if (S.tut || def.role === 'gk' || Math.random() > 0.035 * (def.foulK || 1)) return false;
  const A = len(att.vx, att.vy) > 0.5 ? norm(att.vx, att.vy) : norm(oppGoalX(att.team) - att.x, H / 2 - att.y);
  const truth = pickTruth({ siga: 0.25, falta: 0.3, amarelo: 0.3 * (def.hardK || 1), vermelho: 0.15 * (def.hardK || 1) });
  const CT = 1.6, P = { x: att.x, y: att.y }, s = Math.random() < 0.5 ? 1 : -1;
  startDuel({ kind: 'pisao', truth, P, A, D: A, perp: { x: -A.y, y: A.x }, s, CT, keyT: CT + 0.05, dur: CT + 2.2, inBox: inOwnBox(def.team, P.x, P.y),
    att: pinfo(att), def: pinfo(def), fall: truth !== 'siga' }, { x: -A.y, y: A.x }, [att, def], 'Lance!');
  return true;
}
function poseStamp(L, t) {
  $('pip').hidden = true;
  const { a, d } = L.rig, { P, A, perp, s, CT } = L, T = R3.T, tr = L.truth;
  // avançado: chega devagar, trava a bola e protege-a
  const slow = t < CT ? 2.4 * (1 - smooth((t - (CT - 1.2)) / 1.2)) : 0;
  const ap = t < CT - 1.2 ? { x: P.x + A.x * 2.4 * (t - CT + 0.6), y: P.y + A.y * 2.4 * (t - CT + 0.6) } : { x: P.x, y: P.y };
  placeRig(a, ap.x, ap.y, A.x, A.y);
  let aPo = t < CT ? runAt(t, 0, clamp(slow / 7.5, 0.05, 0.4)) : idleAt(t, 0);
  if (L.fall && t > CT + 0.05) { const f = t - CT - 0.05; aPo = { mix: [idleAt(CT, 0), { clip: tr === 'vermelho' ? 'fallback' : 'dive', t: 0.2 + f * 1.05 }, smooth(f / 0.14)] }; }
  setPose(a, aPo);
  // defesa: vem por trás e levanta a perna; a sola cai no ponto que a verdade pede
  const gap = t < CT - 0.3 ? 0.75 + 3.2 * (CT - 0.3 - t) : 0.75;
  const side = { x: perp.x * s * 0.28, y: perp.y * s * 0.28 };
  let dp = { x: ap.x - A.x * gap + side.x, y: ap.y - A.y * gap + side.y };
  placeRig(d, dp.x, dp.y, A.x, A.y);
  const k = smooth((t - (CT - 0.35)) / 0.3), back = t > CT + 0.45 ? smooth(1 - (t - CT - 0.45) / 0.4) : 1, w = k * back;
  const H0 = { siga: { hr: -0.55, kr: 0.25 }, falta: { hr: -0.5, kr: 0.35 }, amarelo: { hr: -0.85, kr: 0.45 }, vermelho: { hr: -1.15, kr: 0.35 } }[tr];
  const lift = t < CT ? Math.sin(clamp((t - (CT - 0.35)) / 0.35, 0, 1) * Math.PI) * 0.5 : 0;
  const dRun = runAt(t, 1.2, t < CT - 0.3 ? 0.45 : 0.1);
  setPose(d, w <= 0 ? dRun : { mix: [dRun, { pitch: tr === 'vermelho' ? -0.16 : -0.06, hr: H0.hr - lift, kr: H0.kr + lift * 1.6, fr: -0.45, hl: 0.12, kl: 0.25, al: -0.4, ar: 0.35, alz: -0.4, arz: 0.4, el: -0.6, er: -0.5 }, w] });
  // acerta a sola ao alvo: bola (siga), calcanhar (falta), tendão (amarelo) ou barriga da perna (vermelho)
  d.outer.updateMatrixWorld(true); a.outer.updateMatrixWorld(true);
  const ank = a.ankleL.getWorldPosition(new T.Vector3()), kn = a.kneeL.getWorldPosition(new T.Vector3());
  const bp = { x: ap.x + A.x * 0.38, y: ap.y + A.y * 0.38 };
  const tgt = tr === 'siga' ? new T.Vector3(bp.x, 0.12, bp.y) : ank.clone().lerp(kn, tr === 'falta' ? 0 : tr === 'amarelo' ? 0.3 : 0.62);
  const boot = d.bootR.getWorldPosition(new T.Vector3()), hit = smooth((t - (CT - 0.12)) / 0.12) * back;
  if (hit > 0) { dp = { x: dp.x + (tgt.x - boot.x) * hit, y: dp.y + (tgt.z - boot.z) * hit }; placeRig(d, dp.x, dp.y, A.x, A.y); }
  // bola: colada ao pé do avançado; no siga o defesa tira-a para o lado
  let bx = bp.x, by = bp.y;
  if (tr === 'siga' && t > CT) { const u = t - CT, k2 = 4 * (1 - Math.exp(-u * 2)); bx += (perp.x * s * 0.8 - A.x * 0.3) * k2; by += (perp.y * s * 0.8 - A.y * 0.3) * k2; }
  else if (t > CT + 0.1) { const u = t - CT - 0.1, k2 = 1.5 * (1 - Math.exp(-u * 2)); bx += A.x * k2; by += A.y * k2; }
  R3.ball.position.set(bx, 0.11, by);
  poseOthers5(L, t, CT, P);
  const sd = { x: perp.x * s, y: perp.y * s };
  sceneCam(L, t, { x: ap.x - A.x * 0.4, y: ap.y - A.y * 0.4 }, 6, { x: P.x - sd.x * 6.4 - A.x * 0.8, y: P.y - sd.y * 6.4 - A.y * 0.8, h: 1.45, look: { x: P.x - A.x * 0.3, y: P.y - A.y * 0.3 }, lh: 0.75, w: 4.4 });
}

// ---- voz: o VAR, os assistentes, o 4.º árbitro e o relato falam (voz do browser, em português)
const Voice = (() => {
  let on = true, list = null;
  try { on = localStorage.getItem('arbitro-voz') !== '0'; } catch (e) { /* sem armazenamento */ }
  const ok = () => typeof speechSynthesis !== 'undefined' && typeof SpeechSynthesisUtterance !== 'undefined';
  function voices() {
    if (list && list.length) return list;
    if (!ok()) return [];
    const all = speechSynthesis.getVoices();
    list = all.filter(v => /^pt/i.test(v.lang)).sort((x, y) => (y.lang === 'pt-PT') - (x.lang === 'pt-PT'));
    return list;
  }
  const P = { VAR: { p: 0.75, r: 1.05, i: 0 }, Assistente: { p: 1.15, r: 1.1, i: 1 }, '4.º árbitro': { p: 0.95, r: 1.08, i: 2 }, Relato: { p: 1.05, r: 1.18, i: 0 }, Árbitro: { p: 0.9, r: 1.08, i: 1 } };
  function say(txt, who) {
    if (!on || !ok() || Sfx.muted) return;
    const u = new SpeechSynthesisUtterance(txt), v = voices(), q = P[who] || P.Relato;
    u.lang = 'pt-PT'; if (v.length) u.voice = v[q.i % v.length];
    u.pitch = q.p; u.rate = q.r; u.volume = 0.95;
    if (who !== 'Relato') speechSynthesis.cancel();
    else if (speechSynthesis.speaking) return;
    speechSynthesis.speak(u);
  }
  function toggle() { on = !on; try { localStorage.setItem('arbitro-voz', on ? '1' : '0'); } catch (e) { /* sem armazenamento */ } if (!on && ok()) speechSynthesis.cancel(); return on; }
  if (ok()) speechSynthesis.onvoiceschanged = () => { list = null; };
  return { say, toggle, get on() { return on; }, stop: () => ok() && speechSynthesis.cancel() };
})();

// ---- primeiro jogo guiado
const TUT = [
  { txt: 'Tu és a carica preta e amarela com o A. Move-te com WASD ou as setas (no telemóvel, toca no campo). Aproxima-te da bola.', until: () => len(S.ref.x - S.ball.x, S.ref.y - S.ball.y) < 13 },
  { txt: 'Boa. Quando há um lance, o jogo para e vês o momento em 3D a partir de onde estás. Perto e com bom ângulo vês melhor. Vamos ver um.', btn: 'Ver o lance', go: () => tutFoul() },
  { txt: 'Vê o lance e decide: 1 siga, 2 falta, 3 amarelo, 4 vermelho, 5 simulação. Depois da 1.ª vez podes rever (R) e andar fotograma a fotograma.', until: () => S.tutDone },
  { txt: 'O árbitro comunica a decisão aos jogadores. Nos lances no limite (falta ou amarelo, por exemplo) as duas decisões contam como certas, mas o observador vê se tens o mesmo critério o jogo todo.', btn: 'Seguinte' },
  { txt: 'Foras de jogo: vês o passe pelos olhos do assistente. Quando há dúvida, o VAR chama-te ao monitor: arrastas as linhas no relvado até às partes do corpo que contam e decides.', btn: 'Ver um fora de jogo', go: () => tutOffside() },
  { txt: 'Arrasta as duas linhas até aos pés, ombros ou cabeça do atacante e do penúltimo defesa. Tab troca de linha, as setas afinam.', until: () => S.tutDone },
  { txt: 'Em cima tens o controlo do jogo, a tua energia, a pressão do público e os nervos. Erros e protestos mal geridos baixam o controlo: abaixo de 10 o jogo é interrompido. Ao intervalo revês os lances da 1.ª parte.', btn: 'Seguinte' },
  { txt: 'Estás pronto. Na carreira começas nos distritais e sobes até ao Mundial. No auricular ouves o VAR, os assistentes e o 4.º árbitro.', btn: 'Ir para o menu', go: () => tutEnd() },
];
function startTutorial() {
  C = null; useTeams(null); start();
  S.tut = { i: -1 }; S.lanceCd = 1e9;
  tutNext();
}
function tutNext() {
  const T = S.tut; T.i++; S.tutDone = false;
  const st = TUT[T.i]; if (!st) return;
  $('tutTxt').textContent = st.txt; $('tutStep').textContent = (T.i + 1) + ' / ' + TUT.length;
  $('tutBtn').hidden = !st.btn; $('tutBtn').textContent = st.btn || '';
  $('tut').hidden = false;
}
function tutStep() {
  if (!S || !S.tut) return;
  S.lanceCd = 1e9; S.t = Math.min(S.t, 60);
  const st = TUT[S.tut.i];
  if (st && st.until && mode === 'play' && st.until()) tutNext();
}
function tutClick() {
  if (!S || !S.tut) return;
  const st = TUT[S.tut.i];
  if (st && st.go) { st.go(); if (st === TUT[TUT.length - 1]) return; }
  tutNext();
}
function tutFoul() {
  const att = S.players.find(p => p.team === 1 && p.role === 'st'), def = S.players.find(p => p.team === 0 && p.role === 'lcb');
  att.off = def.off = false;
  att.x = clamp(S.ref.x - 6, 8, W - 8); att.y = clamp(S.ref.y - 7, 6, H - 6); att.vx = -5; att.vy = 0;
  def.x = att.x + 1; def.y = att.y + 3.6;
  S.noVar = true;
  const L = forcedLance(att, def, { amarelo: 1 }, { tutL: true });
  if (L) { L.why = null; L.truth = 'amarelo'; L.look = 'amarelo'; L.adv = false; L.interp = null; L.decideT = 30; }
  const iv = setInterval(() => { if (!S || !S.tut) { clearInterval(iv); return; } if (mode === 'play' && S.lance === null || (S.lance && S.lance.decided && mode === 'play')) { S.tutDone = true; clearInterval(iv); } }, 200);
}
function tutOffside() {
  S.training = { n: 0, next: 1e9, total: 99, tut: true }; S.noVar = false;
  trainOffside();
  const iv = setInterval(() => { if (!S || !S.tut) { clearInterval(iv); return; } if (mode === 'play') { S.training = null; S.tutDone = true; clearInterval(iv); } }, 200);
}
function tutEnd() {
  $('tut').hidden = true; S.tut = null; Voice.stop();
  hide3D(); mode = 'menu'; newMatch(); useTeams(null);
  $('menu').hidden = false; $('help').hidden = false;
}
$('tutBtn').addEventListener('click', tutClick);
$('tutBtnMenu').addEventListener('click', startTutorial);
$('voiceBtn').textContent = Voice.on ? 'Voz ligada' : 'Voz desligada';
$('voiceBtn').addEventListener('click', () => { const v = Voice.toggle(); $('voiceBtn').textContent = v ? 'Voz ligada' : 'Voz desligada'; if (v) Voice.say('Rádio ligado.', 'VAR'); });
