// ---------- fase 10: jogadores com memória na carreira (cartões, castigos, rancor) e ficha do jogador ----------
const plKey = (club, num) => club + '#' + num;
function plRec(club, num) { C.pl = C.pl || {}; const k = plKey(club, num); return C.pl[k] || (C.pl[k] = { n: '', j: 0, y: 0, r: 0, f: 0, ban: 0, grudge: 0 }); }
// antes do jogo: castigados ficam de fora (entra um suplente) e quem foi expulso por ti lembra-se
function careerSquad() {
  if (!S || !S.career || !C) return;
  S.players.forEach(p => {
    const club = TEAMS[p.team].name, rec = C.pl && C.pl[plKey(club, p.num)];
    if (!rec) return;
    if (rec.ban > 0) {
      const r = seeded(hashS(club) + p.num * 31 + C.season * 7);
      const nm = FIRST[Math.floor(r() * FIRST.length)] + ' ' + LAST[Math.floor(r() * LAST.length)];
      Object.assign(p, { name: nm, short: nm.split(' ')[1], ovr: p.ovr - 6, tr: [], reserve: true, banned: rec.n });
      ['pac', 'pas', 'fin', 'tck', 'drb'].forEach(k => { p[k] = Math.max(30, p[k] - 6); });
      p.foulK = p.hardK = p.simK = 1; p.rel = (p.rel || 70) - 6;
    } else if (rec.grudge) {
      p.grudge = true; p.foulK = (p.foulK || 1) * 1.25; p.hardK = (p.hardK || 1) * 1.3; p.simK = (p.simK || 1) * 1.2;
    }
  });
}
function briefPlayers(h, a) {
  const out = [];
  [h, a].forEach(c => {
    const recs = Object.entries(C.pl || {}).filter(([k]) => k.startsWith(c[0] + '#'));
    const ban = recs.filter(([, r]) => r.ban > 0).map(([k, r]) => r.n + ' (' + k.split('#')[1] + ', ' + r.ban + (r.ban > 1 ? ' jogos' : ' jogo') + ')');
    const gr = recs.filter(([, r]) => r.grudge && !r.ban).map(([k, r]) => r.n + ' (' + k.split('#')[1] + ')');
    if (ban.length) out.push(c[0] + ': castigado' + (ban.length > 1 ? 's ' : ' ') + ban.join(', ') + '.');
    if (gr.length) out.push(c[0] + ': ' + gr.join(', ') + (gr.length > 1 ? ' não esqueceram' : ' não esqueceu') + ' a expulsão que lhe mostraste. Vai entrar com tudo.');
  });
  return out;
}
// depois do jogo: castigos cumpridos, cartões acumulados (5 amarelos = 1 jogo), vermelhos e rancor
function careerPlayers() {
  if (!S || !S.career || !C) return;
  const notes = [];
  [0, 1].forEach(ti => {
    const club = TEAMS[ti].name;
    Object.entries(C.pl || {}).forEach(([k, r]) => { if (k.startsWith(club + '#') && r.ban > 0) r.ban--; });
    S.players.filter(p => p.team === ti).forEach(p => {
      if (p.reserve) return;
      const r = plRec(club, p.num); r.n = p.name || r.n || ('n.º ' + p.num); r.j++; r.f += p.fouls || 0;
      if (r.grudge && !p.off) r.grudge = Math.max(0, r.grudge - 1);
      const second = p.off && p.yellow >= 2, direct = p.off && !second;
      if (p.yellow && !second) { const y0 = r.y; r.y += Math.min(1, p.yellow); if (Math.floor(r.y / 5) > Math.floor(y0 / 5)) { r.ban += 1; notes.push(r.n + ' chega aos ' + r.y + ' amarelos: 1 jogo de castigo'); } }
      if (second) { r.y += 1; r.r++; r.ban += 1; r.grudge = 2; notes.push(r.n + ' (' + club + '): 1 jogo de castigo'); }
      if (direct) { r.r++; r.ban += 2; r.grudge = 2; notes.push(r.n + ' (' + club + '): 2 jogos de castigo'); }
    });
  });
  C.banNote = notes.length ? ' Castigos: ' + notes.join('; ') + '.' : '';
}
function seasonResetPlayers() {
  Object.values(C.pl || {}).forEach(r => { r.j = 0; r.y = 0; r.r = 0; r.f = 0; });
}
// disciplina da época no ecrã da carreira
function renderDiscipline() {
  const wrap = $('carDiscWrap'), ul = $('carDisc'); if (!wrap) return;
  const rows = Object.entries(C.pl || {}).filter(([, r]) => r.y || r.r || r.ban).sort((x, y) => (y[1].r * 3 + y[1].y) - (x[1].r * 3 + x[1].y)).slice(0, 6);
  ul.textContent = '';
  rows.forEach(([k, r]) => {
    const li = document.createElement('li'), b = document.createElement('b'), sm = document.createElement('small');
    const [club, num] = k.split('#');
    b.textContent = r.n + ' · ' + num; sm.textContent = club + ' · ' + r.j + (r.j === 1 ? ' jogo' : ' jogos') + ' · ' + r.y + (r.y === 1 ? ' amarelo' : ' amarelos') + ' · ' + r.r + (r.r === 1 ? ' vermelho' : ' vermelhos') + (r.ban ? ' · castigado ' + r.ban + (r.ban > 1 ? ' jogos' : ' jogo') : '') + (r.grudge ? ' · tem-te de olho' : '');
    li.append(b, sm); ul.appendChild(li);
  });
  wrap.hidden = !rows.length;
}

// ---- ficha do jogador: toca numa carica
let pcardT = null;
const ROLE_PT = { gk: 'Guarda-redes', lb: 'Lateral esquerdo', rb: 'Lateral direito', lcb: 'Central', rcb: 'Central', cb: 'Central', cm: 'Médio', lcm: 'Médio', rcm: 'Médio', lw: 'Extremo esquerdo', rw: 'Extremo direito', st: 'Avançado' };
function capTap(x, y) {
  if (!S) return false;
  const [p, d] = nearest(S.players.filter(q => !q.off), x, y);
  if (!p || d > 1.3) return false;
  showCard(p); return true;
}
function showCard(p) {
  const t = TEAMS[p.team], el = $('pcard');
  $('pcNum').textContent = p.num; $('pcNum').style.background = t.color; $('pcNum').style.color = t.text || '#fff';
  $('pcName').textContent = p.name || ('Jogador ' + p.num);
  $('pcSub').textContent = t.name + ' · ' + (ROLE_PT[p.role] || (p.line === 'd' ? 'Defesa' : p.line === 'm' ? 'Médio' : p.line === 'f' ? 'Avançado' : 'Guarda-redes')) + (p.ovr ? ' · ' + Math.round(p.ovr) : '');
  const bars = $('pcBars'); bars.textContent = '';
  [['Velocidade', p.pac], ['Passe', p.pas], ['Remate', p.fin], ['Desarme', p.tck], ['Drible', p.drb]].forEach(([n, v]) => {
    if (v === undefined) return;
    const row = document.createElement('div'), lab = document.createElement('span'), bar = document.createElement('i'), num = document.createElement('b');
    lab.textContent = n; bar.style.setProperty('--w', Math.round(v) + '%'); num.textContent = Math.round(v);
    row.append(lab, bar, num); bars.appendChild(row);
  });
  const tags = [];
  (p.tr || []).forEach(x => tags.push(x === 'estrela' ? '★ estrela' : x === 'duro' ? 'entra duro' : 'atira-se'));
  if (p.reserve) tags.push('suplente: ' + p.banned + ' está castigado');
  if (p.grudge) tags.push('lembra-se da expulsão');
  if (p.yellow) tags.push(p.yellow + ' amarelo' + (p.yellow > 1 ? 's' : '') + ' hoje');
  if (p.fouls) tags.push(p.fouls + ' falta' + (p.fouls > 1 ? 's' : '') + ' hoje');
  if (S.career && C && C.pl) { const r = C.pl[plKey(t.name, p.num)]; if (r && !p.reserve && (r.j || r.y)) tags.push('época: ' + r.j + ' j, ' + r.y + ' am, ' + r.r + ' verm'); }
  $('pcTags').textContent = tags.join(' · ');
  el.hidden = false;
  clearTimeout(pcardT); pcardT = setTimeout(() => { el.hidden = true; }, 5000);
}
$('pcard').addEventListener('pointerdown', e => { e.stopPropagation(); $('pcard').hidden = true; });
