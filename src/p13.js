// ---------- fase 8: lances de interpretação, critério do árbitro e intervalo ----------
// ---- interpretação: há faltas no limite do amarelo (ou do vermelho) em que as duas decisões são aceitáveis
const PAIR_UP = { falta: 'amarelo', amarelo: 'vermelho' }, PAIR_DN = { amarelo: 'falta', vermelho: 'amarelo' };
function promising(L) {
  const a = S.players[L.att.id]; if (!a || !L.A) return false;
  const r = rel(a.team, L.P.x), toGoal = L.A.x * TEAMS[a.team].dir;
  return L.counter || (r > W * 0.62 && toGoal > 0.35 && Math.abs(L.P.y - H / 2) < 24);
}
function interpOf(L) {
  if (L.interp !== undefined) return L.interp;
  L.interp = null;
  const T = L.truth;
  if (L.light && !L.training && (T === 'falta' || T === 'siga')) { L.interp = [T === 'falta' ? 'siga' : 'falta']; L.interpWhy = 'toque leve'; return L.interp; }
  if (L.training || L.tutL || L.scene || L.kind === 'offside' || !PAIR_UP[T] && !PAIR_DN[T] || L.why === 'reiterada') return null;
  let up = false, dn = false, why = '';
  if (!L.kind && L.A && L.D && L.def.role !== 'gk') {
    // o ângulo da entrada decide a gravidade: perto da fronteira entre dois níveis, os dois servem
    const phi = Math.acos(clamp(L.A.x * L.D.x + L.A.y * L.D.y, -1, 1)) * 180 / Math.PI;
    if (T === 'falta' && phi < 86) up = true;
    if (T === 'amarelo' && phi > 64 && L.why !== 'tatica') dn = true;
    if (T === 'amarelo' && phi < 48) up = true;
    if (T === 'vermelho' && phi > 21) dn = true;
  } else if (L.gkOut) {
    const r = Math.random(); if (T === 'vermelho' && r < 0.3) dn = true; else if (T === 'amarelo' && r < 0.35) up = true;
  } else if (L.kind === 'aereo' || L.kind === 'agarrao' || L.kind === 'pisao') {
    const r = Math.random(); if (r < 0.3 && T !== 'vermelho') up = true; else if (r > 0.72 && T !== 'falta') dn = true;
  }
  // falta que corta um ataque prometedor: o amarelo também se aceita
  if (T === 'falta' && !up && promising(L)) { up = true; why = 'ataque prometedor'; }
  const acc = [];
  if (up && PAIR_UP[T]) acc.push(PAIR_UP[T]);
  if (dn && PAIR_DN[T]) acc.push(PAIR_DN[T]);
  if (acc.length) { L.interp = acc; L.interpWhy = why; }
  return L.interp;
}
const interpOK = (L, d) => !!(interpOf(L) || []).includes(d);
function interpTxt(l) { return [l.truth].concat(l.interp).sort((a, b) => SEV[a] - SEV[b]).map(x => DEC_LABEL[x].toLowerCase()).join(' ou '); }

// ---- critério: nos lances no limite, o árbitro foi pelo mais duro ou pelo mais brando? E foi sempre igual?
function critNote(L, d) {
  if (!L.interp || L.training) return;
  const opts = [L.truth].concat(L.interp).map(x => SEV[x]), lo = Math.min(...opts), s = SEV[d] > lo ? 1 : 0, pair = Object.keys(SEV).find(k => SEV[k] === lo);
  L.interpOK = true; L.strict = s;
  S.crit = S.crit || [];
  const prev = S.crit.filter(c => c.pair === pair && c.s !== s).pop();
  S.crit.push({ s, pair, m: L.minute, team: L.def.team });
  if (prev) {
    // mudou de critério no mesmo jogo: quem levou o mais duro lembra-se do outro lance
    L.critFlip = prev.m;
    const hurt = s ? L.def.team : prev.team;
    S.critFlips = (S.critFlips || 0) + 1;
    S.control = clamp(S.control - 3 * authK(), 0, 100); S.aggr[hurt] += 0.06;
    setTimeout(() => { if (S && mode === 'play') { feed(TEAMS[hurt].name + ' queixam-se do critério: no lance aos ' + prev.m + "' a decisão foi outra.", 'protest'); toast('Critério diferente do lance aos ' + prev.m + "'", 2.4); } }, 2600);
  }
}
function critMean() { const c = S.crit || []; return c.length ? c.reduce((a, x) => a + x.s, 0) / c.length : null; }
function critLabel(m) { return m === null ? '' : m >= 0.67 ? 'rigoroso' : m <= 0.33 ? 'permissivo' : 'equilibrado'; }
function critTxt() {
  const c = S.crit || []; if (!c.length) return '';
  const f = S.critFlips || 0;
  return ' Critério nos lances no limite: ' + critLabel(critMean()) + (f ? ', mas mudaste de critério ' + (f > 1 ? f + ' vezes' : 'uma vez') + '.' : ', igual o jogo todo.');
}
const critPenalty = () => Math.min(1, 0.3 * (S.critFlips || 0));
// carreira: o observador compara o critério de jogo para jogo
function critCareer() {
  C.critS = C.critS || [];
  const m = critMean();
  if (m !== null && (S.crit || []).length >= 2) C.critS.push(Math.round(m * 100) / 100);
}
function critSeasonAdj() {
  const a = C.critS || []; if (a.length < 2) return 0;
  const mu = a.reduce((x, y) => x + y, 0) / a.length, sd = Math.sqrt(a.reduce((x, y) => x + (y - mu) * (y - mu), 0) / a.length);
  return Math.round((clamp(1 - sd * 2.5, 0, 1) - 0.6) * 5) / 10;
}
function critCareerTxt() {
  const a = C.critS || []; if (a.length < 2) return '';
  const adj = critSeasonAdj(), f1 = x => (x > 0 ? '+' : '') + x.toFixed(1).replace('.', ',');
  return ' Critério ' + (adj >= 0.1 ? 'igual de jogo para jogo' : adj > -0.1 ? 'quase sempre igual' : 'a mudar de jogo para jogo') + (adj ? ' (' + f1(adj) + ' na média)' : '') + '.';
}

// ---- intervalo: troca de campo, revisão dos lances da 1.ª parte e uma conversa antes de recomeçar
function halfCheck() {
  if (S.half || S.training || mode !== 'play' || S.t < MATCH_SECONDS / 2 || S.pause > 0 || S.ask || S.fk || S.pendCard || S.ball.penalty) return;
  S.half = 1; halfTime();
}
function halfTime() {
  mode = 'intervalo'; showDecide(false); hide3D(); $('toast').hidden = true; $('radio').hidden = true; $('refSay').hidden = true;
  Sfx.whistle('end');
  feed('Intervalo: ' + TEAMS[0].name + ' ' + S.score[0] + '–' + S.score[1] + ' ' + TEAMS[1].name + '.', 'info');
  const inc = S.incidents.filter(l => !l.training), right = inc.filter(l => l.pts === 1).length;
  $('halfTitle').textContent = 'Intervalo · ' + S.score[0] + '–' + S.score[1];
  $('halfTxt').textContent = (inc.length ? right + ' de ' + inc.length + ' decisões certas na 1.ª parte.' : 'Primeira parte sem lances para rever.') + critTxt() + ' Na 2.ª parte as equipas trocam de campo.';
  const tb = $('halfBody'); tb.textContent = '';
  inc.forEach(l => {
    const tr = document.createElement('tr'), cls = l.pts === 1 ? 'ok' : (l.pts > 0 ? 'half' : 'bad');
    const what = l.kind === 'offside' ? LABEL[l.truth] : (LABEL[l.truth] || DEC_LABEL[l.truth] || l.truth) + (l.interp ? ' · no limite' : '');
    const cells = [l.minute + "'", what, (DEC_LABEL[l.decided] || l.decided || '–'), l.interpOK ? 'Certo · ' + interpTxt(l) : l.pts === 1 ? 'Certo' : l.pts > 0 ? 'Meio certo' : 'Errado'];
    cells.forEach((c, ci) => { const td = document.createElement('td'); td.textContent = c; if (ci === 3) td.className = cls; tr.appendChild(td); });
    const td = document.createElement('td'), btn = document.createElement('button');
    btn.className = 'linkbtn'; btn.type = 'button'; btn.textContent = 'Ver lance';
    btn.addEventListener('click', () => { reviewing = l; l.ideal = true; show3D(l, true); captions3D(l); setReviewView(true); resize3D(); stage.scrollIntoView({ behavior: 'smooth', block: 'center' }); });
    td.appendChild(btn); tr.appendChild(td); tb.appendChild(tr);
  });
  S.halfTalk = null; document.querySelectorAll('#halfTalk button').forEach(b => b.classList.remove('on'));
  $('half').hidden = false; $('help').hidden = true;
}
const HALF_TALK = {
  capitaes: () => { S.capTrust = S.capTrust.map(c => clamp(c + 0.12, 0, 1)); S.aggr = S.aggr.map(a => Math.max(0.05, a - 0.05)); return 'Falaste com os capitães: confiam mais em ti e os jogadores acalmam.'; },
  assist: () => { S.astBoost = true; return 'Acertaste o posicionamento com os assistentes: na 2.ª parte as indicações deles são mais certeiras.'; },
  descanso: () => { S.stamina = 100; S.stress = Math.max(S.stressBase || 10, S.stress - 12); return 'Descansaste no balneário: energia cheia e menos nervos.'; },
};
function secondHalf() {
  if (mode !== 'intervalo') return;
  hide3D(); reviewing = null; $('half').hidden = true; $('help').hidden = false;
  const k = S.halfTalk || 'descanso', msg = HALF_TALK[k]();
  TEAMS.forEach(t => { t.dir = -t.dir; });
  S.half = 2; S.lance = null; S.pause = 0.8;
  kickoff(1);
  mode = 'play'; Sfx.whistle('long');
  feed('Começa a 2.ª parte. As equipas trocaram de campo.', 'info'); toast(msg, 3);
}
document.querySelectorAll('#halfTalk button').forEach(b => b.addEventListener('click', () => {
  if (!S) return; S.halfTalk = b.dataset.t;
  document.querySelectorAll('#halfTalk button').forEach(x => x.classList.toggle('on', x === b));
}));
$('halfBtn').addEventListener('click', secondHalf);
