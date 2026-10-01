// ---------- fase 6: carreira 2.0 (épocas longas, jornais, treinadores e classificação dos árbitros) ----------
const SEASON_GAMES = [6, 6, 7, 7, 6];
TIERS.forEach((t, i) => { if (!t.cup) t.games = SEASON_GAMES[i]; });
const REF_NAMES = ['Rui Matos', 'Carla Pinto', 'Nuno Teixeira', 'Sofia Ramos', 'Hélder Costa', 'Marta Faria', 'Tiago Lobo', 'Inês Barros', 'Paulo Seabra', 'Joana Prata', 'Vasco Nunes', 'Ana Lemos', 'Bruno Sá', 'Filipa Rocha', 'Duarte Leal', 'Rita Calado'];
const COACH_F = ['Abel', 'Jorge', 'Carlos', 'Vítor', 'Leonel', 'Manuel', 'Sérgio', 'Fernando', 'Artur', 'Rogério', 'Beatriz', 'Luísa'];
const COACH_L = ['Fontes', 'Mourão', 'Guerreiro', 'Pacheco', 'Valente', 'Carvalhal', 'Bento', 'Simões', 'Quaresma', 'Lacerda', 'Rebelo', 'Peixoto'];
const PAPERS = ['Gazeta da Carica', 'O Apito', 'Diário do Relvado', 'A Bancada'];
const hashS = s => { let h = 7; for (const ch of s) h = (h * 31 + ch.charCodeAt(0)) % 100003; return h; };
function coachName(team) { const n = TEAMS[team].name, h = hashS(n); return COACH_F[h % COACH_F.length] + ' ' + COACH_L[Math.floor(h / 7) % COACH_L.length]; }
const gauss = () => (Math.random() + Math.random() + Math.random() - 1.5) * 1.15;
const simGrade = sk => Math.round(clamp(sk + gauss() * 0.75, 3.5, 9.8) * 10) / 10;
function makeRefs(ti, played) {
  const T = TIERS[ti], names = REF_NAMES.slice().sort(() => Math.random() - 0.5).slice(0, 7);
  return names.map(n => { const sk = T.target + rand(-1.1, 0.45); return { n, sk, g: Array.from({ length: played || 0 }, () => simGrade(sk)) }; });
}
function migrateCareer() {
  if (!C) return;
  const T = TIERS[C.tier];
  if (!T.cup && C.fixtures.length < T.games) {
    const extra = makeFixtures(C.tier).slice(C.fixtures.length), hasDerby = C.fixtures.some(f => f.story === 'derby');
    extra.forEach(f => { if (hasDerby && f.story === 'derby') { f.story = null; do { f.h = Math.floor(Math.random() * 6); f.a = Math.floor(Math.random() * 6); } while (f.h === f.a || f.h + f.a === 1); } });
    C.fixtures = C.fixtures.concat(extra);
  }
  if (!C.refs) C.refs = makeRefs(C.tier, C.sg.length);
  if (!C.papers) C.papers = [];
  saveCareer();
}
function refTable() {
  const avg = g => g.length ? g.reduce((a, b) => a + b, 0) / g.length : 0;
  return [{ n: 'Tu', me: true, g: C.sg }].concat(C.refs).map(r => ({ n: r.n, me: !!r.me, j: r.g.length, a: avg(r.g) })).sort((p, q) => q.a - p.a || (q.me ? 1 : 0) - (p.me ? 1 : 0));
}
// depois de cada jogo da carreira: os outros árbitros também apitam e a tabela mexe
function career2(g) {
  const T = TIERS[C.tier];
  C.posNote = ''; C.rankNote = '';
  if (S.paper) { C.papers.unshift({ s: C.season, t: C.tier, r: C.round, p: S.paper.paper, h: S.paper.head, st: S.paper.stars, q: S.paper.quote }); C.papers = C.papers.slice(0, 8); }
  if (T.cup || !C.refs) return;
  C.refs.forEach(r => r.g.push(simGrade(r.sk)));
  const tb = refTable(), pos = tb.findIndex(r => r.me) + 1;
  C.posNote = 'Estás em ' + pos + '.º na classificação dos árbitros.';
  if (C.round + 1 >= T.games) {
    C.rankNote = 'Acabaste a época em ' + pos + '.º lugar entre ' + tb.length + ' árbitros' + (pos === 1 ? ': árbitro do ano, +2 pontos de atributo.' : '.');
    if (pos === 1) C.pts += 2;
  }
}
function renderCareer2() {
  const T = TIERS[C.tier], tb = $('carTable'), wrap = $('carRank');
  wrap.hidden = !!T.cup || !C.refs;
  if (!wrap.hidden) {
    tb.textContent = '';
    refTable().forEach((r, i) => {
      const tr = document.createElement('tr'); if (r.me) tr.className = 'me';
      [String(i + 1), r.n, String(r.j), r.j ? r.a.toFixed(1).replace('.', ',') : '–'].forEach(c => { const td = document.createElement('td'); td.textContent = c; tr.appendChild(td); });
      tb.appendChild(tr);
    });
  }
  const pl = $('carPapers'); pl.textContent = '';
  (C.papers || []).slice(0, 5).forEach(p => {
    const li = document.createElement('li'), b = document.createElement('b'), sm = document.createElement('small');
    b.textContent = p.h; sm.textContent = p.p + ' · ' + '★'.repeat(p.st) + '☆'.repeat(5 - p.st) + ' · ' + TIERS[p.t].name + (p.q ? ' · ' + p.q : '');
    li.append(b, sm); pl.appendChild(li);
  });
  $('carPapersWrap').hidden = !(C.papers && C.papers.length);
}

// jornal do dia seguinte: título, estrelas para o árbitro e o que disse o treinador
function paperOf(grade, kind) {
  const inc = S.incidents.filter(l => !l.training), wrong = inc.filter(l => l.pts < 1);
  const h = TEAMS[0].name, a = TEAMS[1].name, sc = S.score[0] + '–' + S.score[1], game = h + ' ' + sc + ' ' + a;
  const stars = kind === 'abandonado' ? 1 : grade >= 9 ? 5 : grade >= 8 ? 4 : grade >= 6.5 ? 3 : grade >= 5 ? 2 : 1;
  const big = wrong.find(l => l.goalCtx) || wrong.find(l => l.inBox && l.kind !== 'offside') || wrong.find(l => l.decided === 'vermelho' || l.truth === 'vermelho') || wrong.find(l => l.kind === 'offside');
  let head;
  if (kind === 'abandonado') head = 'Jogo interrompido: o árbitro perdeu o controlo no ' + game;
  else if (big) {
    const d = big.decided, t = big.truth;
    if (big.goalCtx) head = (GOAL_OK(d) || (big.kind === 'offside' && d === 'emjogo') ? 'Golo ilegal validado' : 'Golo limpo anulado') + ' marca o ' + game;
    else if (big.kind === 'offside') head = (d === 'fora' ? 'Fora de jogo inventado' : 'Fora de jogo por assinalar') + ' no ' + game;
    else if (big.inBox) head = (scenePen(big, d) || (!big.scene && FOUL(d)) ? 'Penálti inventado' : 'Penálti por marcar') + ' no ' + game;
    else head = (d === 'vermelho' ? 'Vermelho exagerado' : t === 'vermelho' ? 'Vermelho perdoado' : 'Erro grave') + ' no ' + game;
  } else if (inc.some(l => l.varFirst && l.pts > 0)) head = 'O VAR salva o árbitro no ' + game;
  else if (grade >= 8.5) head = pickOf(['Arbitragem de luxo no ' + game, 'Ninguém falou do árbitro no ' + game + ', e isso é um elogio', 'Árbitro impecável no ' + game]);
  else if (grade >= 6.5) head = pickOf(['Arbitragem segura no ' + game, game + ': jogo bem conduzido, com uma ou outra dúvida']);
  else head = pickOf(['Árbitro em noite difícil no ' + game, 'Muitas dúvidas na arbitragem do ' + game]);
  // treinador mais prejudicado fala; se ninguém foi prejudicado, o que perdeu elogia ou resmunga
  const wr = S.career ? S.career.wrong : [0, 0];
  const lost = S.score[0] < S.score[1] ? 0 : S.score[1] < S.score[0] ? 1 : -1;
  let ct = wr[0] > wr[1] ? 0 : wr[1] > wr[0] ? 1 : wr[0] > 0 ? (lost >= 0 ? lost : 0) : lost;
  let quote = '';
  if (ct >= 0) {
    const n = coachName(ct), bad = wr[ct] > 0 || (!S.career && wrong.length >= 2);
    quote = n + ' (' + TEAMS[ct].name + '): «' + (bad ? pickOf(['Hoje não perdemos com o adversário, perdemos com o árbitro.', 'Vi o que toda a gente viu. O árbitro decidiu o jogo.', 'Há decisões que não se explicam. Vamos fazer queixa.', 'Trabalhamos a semana toda para isto? Não aceito.'])
      : stars >= 4 ? pickOf(['Perdemos, mas o árbitro esteve bem. Não há desculpas.', 'O árbitro foi justo. Fomos piores.']) : pickOf(['Não vou falar da arbitragem.', 'Há lances que vou rever com calma.'])) + '»';
  }
  const right = inc.filter(l => l.pts === 1).length;
  const body = 'Nota do jornal para o árbitro: ' + stars + ' em 5. ' + right + ' de ' + inc.length + ' decisões certas' + (S.anulados ? ', ' + S.anulados + (S.anulados > 1 ? ' golos anulados' : ' golo anulado') : '') + (S.varN ? ', ' + S.varN + ' ida' + (S.varN > 1 ? 's' : '') + ' ao VAR' : '') + '.';
  return { paper: pickOf(PAPERS), head, body, stars, quote };
}
function paperShow(grade, kind) {
  const el = $('paper');
  if (S.training || kind === 'treino') { el.hidden = true; S.paper = null; return; }
  const P = S.paper = paperOf(grade, kind);
  $('paperName').textContent = P.paper; $('paperStars').textContent = '★'.repeat(P.stars) + '☆'.repeat(5 - P.stars);
  $('paperHead').textContent = P.head; $('paperBody').textContent = P.body; $('paperQuote').textContent = P.quote; $('paperQuote').hidden = !P.quote;
  el.hidden = false;
}

// treinador fora da área técnica: aviso, amarelo e, se insistir, vermelho
function coachCheck(team, sev, wrong) {
  if (S.training || S.coach || (S.coachOff && S.coachOff[team]) || (S.coachN || 0) >= 2) return;
  if (Math.random() > 0.04 + (wrong ? 0.15 : 0) + sev * 0.08 + S.aggr[team] * 0.1) return;
  S.coach = { team, t: 0 };
}
function coachStep(dt) {
  const Co = S.coach; if (!Co || S.pause > 0 || S.fk) return;
  Co.t += dt; if (Co.t < 1.5) return;
  S.coach = null; S.coachN = (S.coachN || 0) + 1;
  const team = Co.team, lv = S.coachW[team], name = coachName(team), cardD = lv >= 2 ? 'vermelho' : 'amarelo';
  askOpen('O treinador ' + deT(team) + ', ' + name + ', sai da área técnica aos gritos' + (lv ? ' outra vez' + (lv >= 2 ? ', já com amarelo' : ', depois do aviso') : '') + '.', 'Banco',
    [{ d: 'ignorar', label: 'Ignorar', small: 'deixa-o falar' }, { d: 'avisar', label: 'Mandar sentar', small: 'aviso ao 4.º árbitro' }, { d: cardD, label: lv >= 2 ? 'Vermelho' : 'Amarelo', small: lv >= 2 ? 'expulso para a bancada' : 'cartão ao treinador', sw: lv >= 2 ? 'var(--bad)' : 'var(--whistle)' }],
    c => {
      const best = lv === 0 ? 'avisar' : cardD;
      const pts = c === best ? 1 : c === 'ignorar' ? (lv === 0 ? 0.3 : 0) : 0.5;
      let dc = pts === 1 ? 3 : pts >= 0.5 ? -1 : -4; if (dc < 0) dc *= authK();
      S.control = clamp(S.control + dc, 0, 100);
      let msg;
      if (c === 'ignorar') { S.aggr[team] += 0.1; msg = 'Deixaste o treinador ' + deT(team) + ' protestar'; }
      else if (c === 'avisar') { S.coachW[team] = Math.max(lv, 1); msg = 'O 4.º árbitro manda sentar o treinador ' + deT(team); }
      else if (c === 'amarelo') { S.coachW[team] = 2; msg = 'Amarelo ao treinador ' + deT(team) + ', ' + name; Sfx.whistle('short'); }
      else { S.coachOff[team] = true; msg = 'Vermelho: ' + name + ' vai para a bancada'; Sfx.whistle('long'); if (team === HOME) { S.crowd = clamp(S.crowd + 12, 0, 100); Sfx.boo(0.6); } }
      S.manage.push({ minute: minuteNow(), what: 'Treinador ' + deT(team) + ' a protestar' + (lv === 1 ? ' (já avisado)' : lv >= 2 ? ' (já com amarelo)' : ''), dec: { ignorar: 'Ignorar', avisar: 'Mandar sentar', amarelo: 'Amarelo', vermelho: 'Vermelho' }[c], pts,
        why: pts === 1 ? 'Certo' : c === 'ignorar' ? 'O banco também se gere: devias ter agido' : lv === 0 ? 'Primeira vez: bastava mandá-lo sentar' : lv === 1 ? 'Já tinha sido avisado: era amarelo' : 'Com amarelo e a insistir: era vermelho' });
      feed(msg + '.', c === 'amarelo' || c === 'vermelho' ? 'card' : 'info');
      toast(msg, 2.2);
    }, 0);
}
