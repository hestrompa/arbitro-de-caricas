// ---------- fase 4: carreira ----------
// equipamentos: cor da camisola, contorno, meias, calções e cor do número na carica
const KITS = {
  azul: { color: '#3569dc', dark: '#1d3f8f', sock: '#1d3f8f', shorts: '#f1f1f1' },
  laranja: { color: '#ee7d2c', dark: '#a4521a', sock: '#ee7d2c', shorts: '#23242a' },
  vermelho: { color: '#d23a3a', dark: '#8a1f1f', sock: '#d23a3a', shorts: '#f1f1f1' },
  verde: { color: '#2f9e57', dark: '#1c6636', sock: '#f1f1f1', shorts: '#f1f1f1' },
  branco: { color: '#eeeeea', dark: '#9a9a96', sock: '#eeeeea', shorts: '#1f2f6b', text: '#1f2f6b' },
  preto: { color: '#26272c', dark: '#111111', sock: '#26272c', shorts: '#26272c' },
  celeste: { color: '#6fb7e8', dark: '#3d7fae', sock: '#f1f1f1', shorts: '#f1f1f1', text: '#12304a' },
  roxo: { color: '#7b4bc4', dark: '#4d2c80', sock: '#7b4bc4', shorts: '#f1f1f1' },
  grena: { color: '#7a1f2e', dark: '#4a111b', sock: '#7a1f2e', shorts: '#f1f1f1' },
  amarelo: { color: '#f2cf3a', dark: '#b39320', sock: '#f2cf3a', shorts: '#1f2f6b', text: '#1f2f6b' },
  marinho: { color: '#1f2f6b', dark: '#101a40', sock: '#1f2f6b', shorts: '#f1f1f1' },
};
// [nome, equipamento principal, alternativo, calções opcionais, artigo (o por omissão)]; o dérbi de cada escalão são os dois primeiros
const TIERS = [
  { name: 'Distrital', games: 4, target: 6.5, var: false, derby: 'Dérbi da vila', clubs: [['Vila Nova', 'verde', 'branco'], ['Vila Velha', 'grena', 'branco'], ['Unidos da Ribeira', 'azul', 'branco'], ['Recreativo das Pedras', 'amarelo', 'preto'], ['Atlético da Serra', 'vermelho', 'branco'], ['Académico do Moinho', 'preto', 'branco']] },
  { name: 'Liga 3', games: 4, target: 7, var: false, derby: 'Dérbi do rio', clubs: [['Oriental da Foz', 'verde', 'branco'], ['Marítimo da Barra', 'laranja', 'branco'], ['Estrela do Norte', 'vermelho', 'branco'], ['Desportivo de Alvor', 'celeste', 'marinho'], ['União de Belmar', 'azul', 'branco'], ['Operário de Vale Fundo', 'preto', 'branco']] },
  { name: 'Liga 2', games: 5, target: 7.5, var: true, derby: 'Dérbi da serra', clubs: [['Penafria FC', 'vermelho', 'branco'], ['Clube de Montalto', 'azul', 'branco'], ['Lusitano de Arcos', 'verde', 'branco'], ['Naval da Enseada', 'marinho', 'branco'], ['Imortal de Ferreiros', 'roxo', 'branco'], ['Juventude de Sertã', 'amarelo', 'marinho']] },
  { name: 'Primeira Liga', games: 5, target: 8, var: true, derby: 'Clássico', clubs: [['Real Lusitano', 'vermelho', 'branco'], ['Clube Oceano', 'azul', 'branco'], ['Leões da Estrela', 'verde', 'branco'], ['Atlético Capital', 'grena', 'branco'], ['Vitória do Sul', 'preto', 'branco'], ['Desportivo Atlântico', 'celeste', 'marinho']] },
  { name: 'Taça Europeia', games: 4, target: 8.3, var: true, derby: 'Dérbi de Velgrad', clubs: [['Dinamo Velgrad', 'azul', 'branco'], ['Lokomotiv Velgrad', 'vermelho', 'branco'], ['Olympique Mireval', 'celeste', 'marinho'], ['Athletic Norbridge', 'grena', 'branco'], ['Real Castellar', 'branco', 'roxo'], ['FC Lindenau', 'amarelo', 'preto']] },
  { name: 'Mundial', games: 4, target: 7.5, var: true, cup: true, derby: 'Clássico sul-americano', clubs: [['Brasil', 'amarelo', 'azul'], ['Argentina', 'celeste', 'marinho', null, 'a'], ['França', 'marinho', 'branco', null, 'a'], ['Espanha', 'vermelho', 'branco', '#1f2f6b', 'a'], ['Alemanha', 'branco', 'preto', '#26272c', 'a'], ['Inglaterra', 'branco', 'vermelho', null, 'a'], ['Países Baixos', 'laranja', 'marinho', null, 'os'], ['Itália', 'azul', 'branco', null, 'a']] },
];
const CUP_ROUNDS = ['Oitavos de final', 'Quartos de final', 'Meias-finais', 'Final'];
const ATTRS = [
  { k: 'fis', name: 'Físico', txt: 'Corres mais depressa e cansas-te menos.' },
  { k: 'leit', name: 'Leitura de jogo', txt: 'Antecipas o lance e vês de mais perto.' },
  { k: 'aut', name: 'Autoridade', txt: 'Protestos mais brandos; os erros custam menos controlo.' },
  { k: 'calma', name: 'Calma', txt: 'Mais tempo para decidir quando o público aperta.' },
];
const STORIES = {
  subida: { txt: 'Os dois precisam de ganhar para chegar aos lugares de cima.', aggr: [0.08, 0.08], crowd: 8 },
  expulsoes: { txt: 'O último jogo entre eles acabou com duas expulsões.', aggr: [0.15, 0.15], crowd: 5 },
  crise: { txt: 'A equipa da casa não ganha há seis jogos e o público está impaciente.', aggr: [0.04, 0], crowd: 18 },
  calmo: { txt: 'Jogo a meio da tabela, sem muito em jogo.', aggr: [-0.03, -0.03], crowd: -6 },
};
const DEFAULT_TEAMS = TEAMS.map(t => Object.assign({ text: '#fff', art: 'os' }, t));
// "para os Azuis", "do Vila Nova", "da Argentina"
const artT = i => (TEAMS[i].art || 'os') + ' ' + TEAMS[i].name, deT = i => 'd' + artT(i);
const cArt = c => (c[4] || 'o') + ' ' + c[0];
const CKEY = 'arbitro-carreira';
let C = null;
function loadCareer() { try { const s = localStorage.getItem(CKEY); C = s ? JSON.parse(s) : null; } catch (e) { C = null; } }
function saveCareer() { try { localStorage.setItem(CKEY, JSON.stringify(C)); } catch (e) { /* sem armazenamento */ } }
const pick = a => a[Math.floor(Math.random() * a.length)];
function makeFixtures(ti) {
  const T = TIERS[ti], n = T.clubs.length, out = [];
  const dr = T.cup ? T.games - 1 : Math.floor(Math.random() * T.games);
  for (let i = 0; i < T.games; i++) {
    let h, a;
    if (i === dr) [h, a] = Math.random() < 0.5 ? [0, 1] : [1, 0];
    else do { h = Math.floor(Math.random() * n); a = Math.floor(Math.random() * n); } while (h === a || h + a === 1);
    out.push({ h, a, story: i === dr ? 'derby' : T.cup ? null : pick([null, null, 'subida', 'expulsoes', 'crise', 'calmo']) });
  }
  return out;
}
function newCareer() {
  C = { v: 1, tier: 0, season: 1, round: 0, sg: [], log: [], attrs: { fis: 3, leit: 3, aut: 3, calma: 3 }, pts: 2, grudge: {}, finals: 0,
    news: 'Começas nos distritais. O observador vê todos os teus jogos: com média acima do que pede, sobes de escalão no fim da época.', fixtures: makeFixtures(0) };
  saveCareer();
}
// atributos do árbitro no jogo em curso (5 = árbitro normal fora da carreira)
function refAttr(k) { return S && S.career ? S.career.attrs[k] : 5; }
function authK() { return 1.1 - refAttr('aut') * 0.02; }
function decisionTime() { const c = refAttr('calma'); return Math.max(8, Math.round(15 - S.crowd / 25 * (1.4 - 0.08 * c) + (c - 5) * 0.4)); }

function hexDist(a, b) { const p = x => [1, 3, 5].map(i => parseInt(x.slice(i, i + 2), 16)), A = p(a), B = p(b); return Math.hypot(A[0] - B[0], A[1] - B[1], A[2] - B[2]); }
function kitOf(club, alt) { const k = Object.assign({}, KITS[alt ? club[2] : club[1]]); if (!alt && club[3]) k.shorts = club[3]; if (!k.text) k.text = '#fff'; return k; }
function useTeams(h, a) {
  if (!h) { TEAMS.forEach((t, i) => Object.assign(t, DEFAULT_TEAMS[i])); }
  else {
    const hk = kitOf(h, false); let ak = kitOf(a, false);
    if (hexDist(hk.color, ak.color) < 120) ak = kitOf(a, true);
    if (hexDist(hk.color, ak.color) < 120) ak = Object.assign({}, KITS.branco.color === hk.color ? KITS.preto : KITS.branco);
    const gks = ['#2fa36b', '#8a5bd6', '#d8d8d8', '#f08fb6'].sort((x, y) => Math.min(hexDist(y, hk.color), hexDist(y, ak.color)) - Math.min(hexDist(x, hk.color), hexDist(x, ak.color)));
    Object.assign(TEAMS[0], hk, { name: h[0], art: h[4] || 'o', gk: gks[0] }); Object.assign(TEAMS[1], ak, { name: a[0], art: a[4] || 'o', gk: gks[1] });
  }
  [0, 1].forEach(i => { $('hn' + i).textContent = TEAMS[i].name; $('hd' + i).style.background = TEAMS[i].color; });
}
function roundName(T, r) { return T.cup ? CUP_ROUNDS[r] : 'Jornada ' + (r + 1) + ' de ' + T.games; }
// o que o jogo seguinte traz: dérbi, história da época e o que as equipas se lembram de ti
function matchBrief() {
  const T = TIERS[C.tier], f = C.fixtures[C.round], h = T.clubs[f.h], a = T.clubs[f.a];
  const lines = [], aggr = [0, 0]; let crowd = 0;
  if (f.story === 'derby') { lines.push(T.derby + ' entre ' + cArt(h) + ' e ' + cArt(a) + ': estádio cheio e ninguém quer perder.'); aggr[0] += 0.12; aggr[1] += 0.12; crowd += 15; }
  else if (f.story) { const s = STORIES[f.story]; lines.push(s.txt); aggr[0] += s.aggr[0]; aggr[1] += s.aggr[1]; crowd += s.crowd; }
  [h, a].forEach((c, i) => {
    const g = C.grudge[c[0]] || 0;
    if (g > 0) { lines.push('Os jogadores d' + cArt(c) + ' lembram-se de ti: no último jogo tiveram ' + (g > 1 ? g + ' decisões erradas' : 'uma decisão errada') + ' contra eles.'); aggr[i] += Math.min(0.3, 0.1 * g); }
  });
  if (!T.var) lines.push('Não há VAR neste escalão: o que decidires fica decidido.');
  return { T, f, h, a, lines, aggr, crowd };
}
function startCareerMatch() {
  const B = matchBrief(), ti = C.tier;
  useTeams(B.h, B.a);
  start();
  S.career = { tier: ti, round: C.round, attrs: Object.assign({}, C.attrs), wrong: [0, 0], h: B.h[0], a: B.a[0] };
  S.noVar = !B.T.var;
  S.lanceK = 1.1 - 0.05 * ti; S.simK = 0.7 + 0.15 * ti;
  S.crowdBase = clamp(25 + 7 * ti + B.crowd, 10, 90); S.crowd = S.crowdBase;
  S.aggr = [0, 1].map(i => clamp(0.06 + 0.035 * ti + B.aggr[i], 0.05, 0.8));
  $('career').hidden = true; $('brief').hidden = true;
  toast(B.T.name + ' · ' + roundName(B.T, C.round), 2.5);
}

// depois do apito final: nota conta para a época, pontos de atributo, subidas e descidas
function careerAfter(grade, kind) {
  const note = $('careerNote');
  if (!S.career || !C) { note.hidden = true; $('againBtn').textContent = 'Jogar outra vez'; return; }
  if (S.career.done) return;
  S.career.done = true;
  const T = TIERS[C.tier], g = Math.round(grade * 10) / 10, round = C.round;
  C.sg.push(g);
  C.log.unshift({ s: C.season, t: C.tier, r: round, h: S.career.h, a: S.career.a, sc: S.score.slice(), g });
  C.log = C.log.slice(0, 30);
  const gain = 1 + (g >= 8 ? 1 : 0) + (g >= 9 ? 1 : 0);
  C.pts += gain;
  Object.keys(C.grudge).forEach(k => { C.grudge[k] = Math.max(0, C.grudge[k] - 1); if (!C.grudge[k]) delete C.grudge[k]; });
  [S.career.h, S.career.a].forEach((n, i) => { if (S.career.wrong[i] > 0) C.grudge[n] = S.career.wrong[i]; });
  C.round++;
  const avg = C.sg.reduce((a, b) => a + b, 0) / C.sg.length, f1 = x => x.toFixed(1).replace('.', ',');
  let msg = T.name + ' · ' + roundName(T, round) + '. ';
  if (T.cup) {
    if (g < T.target) { msg += 'Com ' + f1(g) + ' o observador não te deixa continuar no Mundial.'; endSeason('Foste dispensado do Mundial depois dos ' + CUP_ROUNDS[round].toLowerCase() + ' (' + f1(g) + '; pediam ' + f1(T.target) + '). Voltas à Taça Europeia.', 4); }
    else if (C.round >= T.games) { C.finals++; msg += 'Apitaste a final do Mundial!'; endSeason('Apitaste a final do Mundial com ' + f1(g) + '. É o topo da carreira. Na época seguinte voltas à Taça Europeia para tentar outra vez.', 4); }
    else msg += 'Nota ' + f1(g) + ': segues para os ' + CUP_ROUNDS[C.round].toLowerCase() + '.';
  } else {
    msg += 'Média da época ' + f1(avg) + ' (para subir: ' + f1(T.target) + ').';
    if (C.round >= T.games) {
      if (avg >= T.target) endSeason(C.tier === 4 ? 'Média de ' + f1(avg) + ' na Taça Europeia: foste escolhido para o Mundial.' : 'Média de ' + f1(avg) + ': sobes para a ' + TIERS[C.tier + 1].name + '.', C.tier + 1);
      else if (avg < T.target - 1.5 && C.tier > 0) endSeason('Média de ' + f1(avg) + ': o observador manda-te descer para a ' + TIERS[C.tier - 1].name + '.', C.tier - 1);
      else endSeason('Média de ' + f1(avg) + ': ficas na ' + T.name + ' mais uma época (para subir precisavas de ' + f1(T.target) + ').', C.tier);
    }
  }
  msg += ' +' + gain + (gain > 1 ? ' pontos' : ' ponto') + ' de atributo.';
  saveCareer();
  note.textContent = msg; note.hidden = false;
  $('againBtn').textContent = 'Continuar carreira';
}
function endSeason(news, tier) {
  C.news = news; C.tier = clamp(tier, 0, TIERS.length - 1); C.season++; C.round = 0; C.sg = []; C.fixtures = makeFixtures(C.tier);
}

// ecrã da carreira: resumo do próximo jogo no relvado, escada e atributos por baixo
function openCareer() {
  if (!C) newCareer();
  mode = 'menu'; reviewing = null; hide3D();
  $('menu').hidden = true; $('review').hidden = true; $('help').hidden = true; $('toast').hidden = true; $('protest').hidden = true; $('decide').hidden = true;
  renderCareer(); newMatch();
  $('career').hidden = false; $('brief').hidden = false;
  window.scrollTo({ top: 0, behavior: 'smooth' });
}
function renderCareer() {
  const B = matchBrief(), T = B.T;
  useTeams(B.h, B.a);
  $('s0').textContent = '0'; $('s1').textContent = '0'; $('clock').textContent = "0'";
  $('briefComp').textContent = T.name + ' · ' + roundName(T, C.round);
  $('briefTeams').textContent = B.h[0] + ' – ' + B.a[0];
  const lines = B.lines.length ? B.lines : ['Jogo sem história especial. O observador pede ' + T.target.toFixed(1).replace('.', ',') + ' de média' + (T.cup ? ' para continuares.' : ' para subires.')];
  ['briefLines', 'carStory'].forEach(id => { const bl = $(id); bl.textContent = ''; lines.forEach(x => { const li = document.createElement('li'); li.textContent = x; bl.appendChild(li); }); });
  $('carSeason').textContent = 'Época ' + C.season + ' · ' + T.name;
  $('carNews').textContent = C.news || ''; $('carNews').hidden = !C.news;
  const ld = $('carLadder'); ld.textContent = '';
  TIERS.forEach((t, i) => { const li = document.createElement('li'); li.textContent = t.name; if (i === C.tier) li.className = 'on'; else if (i < C.tier) li.className = 'past'; ld.appendChild(li); });
  const fx = $('carFix'); fx.textContent = '';
  C.fixtures.forEach((f, i) => {
    const tr = document.createElement('tr'), played = i < C.round, g = played ? C.sg[i] : null;
    [T.cup ? CUP_ROUNDS[i] : String(i + 1), T.clubs[f.h][0] + ' – ' + T.clubs[f.a][0] + (f.story === 'derby' ? (T.derby.startsWith('Clássico') ? ' · clássico' : ' · dérbi') : ''), played ? g.toFixed(1).replace('.', ',') : i === C.round ? 'Próximo' : ''].forEach((c, ci) => {
      const td = document.createElement('td'); td.textContent = c;
      if (ci === 2 && played) td.className = g >= T.target ? 'ok' : g >= T.target - 1.5 ? 'half' : 'bad';
      if (i === C.round && ci === 2) td.className = 'next';
      tr.appendChild(td);
    });
    fx.appendChild(tr);
  });
  $('carPts').textContent = C.pts ? C.pts + (C.pts > 1 ? ' pontos para gastar' : ' ponto para gastar') : 'Sem pontos para gastar: ganhas um por jogo, mais com notas de 8 e 9';
  const at = $('carAttrs'); at.textContent = '';
  ATTRS.forEach(a => {
    const v = C.attrs[a.k], row = document.createElement('div'); row.className = 'attr';
    const tx = document.createElement('div'); const b = document.createElement('b'); b.textContent = a.name; const sm = document.createElement('small'); sm.textContent = a.txt; tx.append(b, sm);
    const bar = document.createElement('div'); bar.className = 'pips'; for (let i = 1; i <= 10; i++) { const s = document.createElement('i'); if (i <= v) s.className = 'on'; bar.appendChild(s); }
    const btn = document.createElement('button'); btn.type = 'button'; btn.className = 'linkbtn'; btn.textContent = '+1'; btn.setAttribute('aria-label', 'Subir ' + a.name);
    btn.disabled = !C.pts || v >= 10;
    btn.addEventListener('click', () => { if (!C.pts || C.attrs[a.k] >= 10) return; C.attrs[a.k]++; C.pts--; saveCareer(); renderCareer(); });
    row.append(tx, bar, btn); at.appendChild(row);
  });
  $('carFinals').hidden = !C.finals; $('carFinals').textContent = C.finals ? 'Finais do Mundial apitadas: ' + C.finals : '';
}
function menuCareerLabel() { loadCareer(); $('careerBtn').textContent = C ? 'Continuar carreira' : 'Carreira'; }
