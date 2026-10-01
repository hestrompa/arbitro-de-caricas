// ---------- fase 7: plantéis com qualidade (à Football Manager), vermelhos à vista, rádio dos árbitros e afinação ----------
const FIRST = ['Rui', 'Tiago', 'João', 'André', 'Diogo', 'Bruno', 'Pedro', 'Hugo', 'Nuno', 'Ricardo', 'Miguel', 'Fábio', 'Gonçalo', 'Rafael', 'Vítor', 'Luís', 'Daniel', 'Filipe', 'Marco', 'Sérgio', 'Ivo', 'Paulo', 'Joel', 'Renato'];
const LAST = ['Tavares', 'Moreira', 'Lopes', 'Pires', 'Sousa', 'Antunes', 'Carvalho', 'Neves', 'Fonseca', 'Mendes', 'Correia', 'Teixeira', 'Barros', 'Coelho', 'Monteiro', 'Vaz', 'Rocha', 'Matias', 'Gomes', 'Faria', 'Brito', 'Cunha', 'Lemos', 'Seixas', 'Dias', 'Marques', 'Patrício', 'Aguiar', 'Quintela', 'Sobral'];
// gerador com semente: o mesmo clube tem sempre os mesmos jogadores
function seeded(seed) { let s = (seed * 2654435761) % 4294967296 || 1; return () => (s = (s * 1664525 + 1013904223) % 4294967296) / 4294967296; }
// força do clube: sobe com o escalão; os dois primeiros de cada escalão (os do dérbi) são os grandes
function clubRating(name, tier) {
  const T = TIERS[tier], i = T.clubs.findIndex(c => c[0] === name), r = seeded(hashS(name) + 11)();
  return Math.round(clamp(52 + tier * 6.5 + (i >= 0 && i < 2 ? 6 : 0) + (r - 0.5) * 12, 40, 92));
}
function squadFor(name, rating) {
  const r = seeded(hashS(name) + 3), g = () => (r() + r() + r() - 1.5) * 1.15;
  const starI = 7 + Math.floor(r() * 4), simI = 5 + Math.floor(r() * 6), hardI = 1 + Math.floor(r() * 6), used = {};
  return ROLES.map((ro, i) => {
    let nm; do nm = FIRST[Math.floor(r() * FIRST.length)] + ' ' + LAST[Math.floor(r() * LAST.length)]; while (used[nm]); used[nm] = 1;
    const ovr = Math.round(clamp(rating + g() * 6 + (i === starI ? 11 : 0), 35, 95));
    const tr = [];
    if (i === starI) tr.push('estrela');
    if (i === simI && r() < 0.75) tr.push('simulador');
    if (i === hardI && r() < 0.8) tr.push('duro');
    return { name: nm, short: nm.split(' ')[1], ovr, tr, num: ro.num };
  });
}
function teamRatings(h, a) {
  if (h) { TEAMS[0].rating = clubRating(h[0], C ? C.tier : 2); TEAMS[1].rating = clubRating(a[0], C ? C.tier : 2); }
  else { const r = Math.random(); TEAMS[0].rating = Math.round(64 + r * 14); TEAMS[1].rating = Math.round(78 - r * 14 + rand(-3, 3)); }
}
// cada carica recebe o seu jogador: velocidade, passe, remate, desarme, disciplina e manha
function squadSetup() {
  // o jogo mede-se pela diferença entre as equipas: num distrital também há golos
  const base = ((TEAMS[0].rating || 70) + (TEAMS[1].rating || 70)) / 2;
  TEAMS.forEach((t, ti) => {
    const sq = squadFor(t.name, t.rating || 70);
    S.players.filter(p => p.team === ti).forEach((p, i) => {
      const q = sq[i], r = seeded(hashS(t.name) + p.num * 97);
      const v = k => clamp(q.ovr - base + 72 + (r() - 0.5) * 16 + k, 30, 99);
      Object.assign(p, { name: q.name, short: q.short, ovr: q.ovr, rel: q.ovr - base + 72, tr: q.tr, pac: v(p.line === 'f' ? 5 : 0), pas: v(p.line === 'm' ? 5 : 0), fin: v(p.line === 'f' ? 6 : -8), tck: v(p.line === 'd' ? 6 : -6), drb: v(p.line === 'f' ? 4 : 0) });
      p.spd = 5.7 + p.pac / 100 * 2.1;
      p.foulK = q.tr.includes('duro') ? 1.6 : 1;
      p.hardK = q.tr.includes('duro') ? 1.7 : 1;
      p.simK = q.tr.includes('simulador') ? 2.6 : 1;
    });
  });
}
const passErr = (p, d) => { const e = (100 - (p.pas || 70)) / 100 * d * 0.11; return { x: (Math.random() - 0.5) * 2 * e, y: (Math.random() - 0.5) * 2 * e }; };
const shotSpread = p => 0.5 + (100 - (p.fin || 70)) / 100 * 0.45;
const tackleP = (def, att) => clamp(0.5 + ((def.tck || 70) - (att.drb || 70)) / 160, 0.25, 0.75);
const gkBonus = gk => ((gk.rel || 70) - 70) * 0.004;
// o dossiê antes do jogo: favorito, estrela e quem é preciso vigiar
function briefSquads(h, a, tier) {
  const rh = clubRating(h[0], tier), ra = clubRating(a[0], tier), out = [];
  const fav = Math.abs(rh - ra) < 4 ? 'Jogo equilibrado' : 'Favorito: ' + (rh > ra ? h[0] : a[0]);
  out.push(fav + ' (força ' + rh + ' contra ' + ra + ').');
  [[h, rh], [a, ra]].forEach(([c, rt]) => {
    const sq = squadFor(c[0], rt), st = sq.find(q => q.tr.includes('estrela')), sm = sq.find(q => q.tr.includes('simulador')), du = sq.find(q => q.tr.includes('duro'));
    const bits = [];
    if (st) bits.push('a estrela é ' + st.name + ' (' + st.num + ', ' + st.ovr + ')');
    if (sm) bits.push(sm.short + ' (' + sm.num + ') tem fama de se atirar');
    if (du) bits.push(du.short + ' (' + du.num + ') entra duro');
    if (bits.length) out.push(c[0] + ': ' + bits.join('; ') + '.');
  });
  return out;
}
const pName = p => p && p.short ? p.short + ' (' + p.num + ')' : p ? 'o ' + p.num : '';

// ---- vermelhos: no marcador e no banco, ao lado do relvado
function redsUI() {
  if (!S) return;
  for (const ti of [0, 1]) {
    const offs = S.players.filter(p => p.team === ti && p.off), key = offs.map(p => p.num).join(',');
    const el = $('rc' + ti); if (el.dataset.k === key) continue;
    el.dataset.k = key; el.textContent = '';
    offs.forEach(p => { const c = document.createElement('i'); c.textContent = p.num; c.title = 'Expulso: ' + (p.name || p.num); el.appendChild(c); });
  }
}
function drawReds() {
  const s = view.s;
  for (const ti of [0, 1]) {
    const offs = S.players.filter(p => p.team === ti && p.off);
    offs.forEach((p, i) => {
      const x = W / 2 + (ti === 0 ? -3 - i * 1.7 : 3 + i * 1.7), y = H + 1.75;
      const X = view.ox + x * s, Y = view.oy + y * s;
      ctx.fillStyle = '#d8322f'; ctx.fillRect(X - 0.5 * s, Y - 0.7 * s, 1.0 * s, 1.4 * s);
      ctx.fillStyle = '#fff'; ctx.font = '700 ' + Math.round(0.85 * s) + 'px "Barlow Condensed", sans-serif'; ctx.textAlign = 'center'; ctx.textBaseline = 'middle';
      ctx.fillText(String(p.num), X, Y);
    });
  }
  ctx.textBaseline = 'alphabetic';
  // nome de quem tem a bola, e estrela por cima dos melhores jogadores
  const o = S.ball.owner;
  if (o && o.short && mode === 'play') {
    ctx.font = '600 ' + Math.round(1.05 * s) + 'px "Barlow Condensed", sans-serif'; ctx.textAlign = 'center';
    ctx.fillStyle = 'rgba(8,14,10,.6)'; const tw = ctx.measureText(o.short).width;
    ctx.fillRect(view.ox + o.x * s - tw / 2 - 3, view.oy + (o.y + 1.5) * s, tw + 6, 1.25 * s);
    ctx.fillStyle = '#f7f7f2'; ctx.fillText(o.short, view.ox + o.x * s, view.oy + (o.y + 2.5) * s);
  }
  ctx.fillStyle = '#f2cf3a'; ctx.font = '700 ' + Math.round(1.1 * s) + 'px sans-serif'; ctx.textAlign = 'center';
  for (const p of active()) if (p.tr && p.tr.includes('estrela')) ctx.fillText('★', view.ox + (p.x + 1.05) * s, view.oy + (p.y - 0.85) * s);
}

// ---- rádio: VAR, assistentes e 4.º árbitro falam no auricular
let radioT = null;
function radio(who, txt) {
  if (!S || S.noRadio) return;
  $('radioWho').textContent = who; $('radioTxt').textContent = txt; $('radio').hidden = false;
  const el = $('radio'); el.classList.remove('fresh'); void el.offsetWidth; el.classList.add('fresh');
  Sfx.radio();
  clearTimeout(radioT); radioT = setTimeout(() => { $('radio').hidden = true; }, 4200);
}
function varCallText(L, d) {
  if (L.kind === 'offside') return L.goal !== undefined ? 'Golo em verificação: possível fora de jogo no passe. Recomendo revisão.' : 'Possível erro no fora de jogo. Recomendo revisão no monitor.';
  if (L.goalCtx) return L.kind === 'linha' ? 'Tenho imagens da linha de golo. Recomendo revisão.' : 'Golo em verificação: possível falta antes do remate.';
  if (d === 'vermelho' || L.truth === 'vermelho') return 'Possível vermelho. Recomendo revisão no monitor.';
  return 'Possível penálti. Recomendo revisão no monitor.';
}
function radioLance(L) {
  L.radioed = true;
  if (L.training) return;
  if (L.kind === 'offside') { radio('Assistente', L.flag ? 'Levantei: para mim o recetor está fora.' : 'Bandeira em baixo: vi-o em linha.'); return; }
  if (L.goalCtx) { radio('VAR', 'Estamos a ver o golo. Decide tu primeiro.'); return; }
  // lance tapado: o assistente diz o que viu; acerta quase sempre, mas nem sempre
  if (L.clarity < 0.5 && Math.random() < 0.65) {
    const right = Math.random() < 0.8, alt = Object.values(keyMap(L)).filter(x => x !== L.truth && x !== 'vantagem'), says = right || !alt.length ? L.truth : pickOf(alt);
    L.astSaid = says; L.astRight = says === L.truth;
    const T = { siga: 'Daqui pareceu-me lance limpo.', falta: 'Daqui vi falta.', amarelo: 'Entrada imprudente, eu dava amarelo.', vermelho: 'Foi muito forte, pode ser vermelho.', simulacao: 'Para mim atirou-se.', mao: 'Vi mão, braço aberto.', maoAmarelo: 'Mão deliberada.', penalti: 'Vi o empurrão do defesa.', ataque: 'Foi o atacante que empurrou.', soco: 'Cotovelada na cara.' };
    if (T[says]) radio('Assistente', T[says]);
  }
}

// ---- afinação: o observador pesa mais os lances grandes; mais escalão, menos tempo para decidir
const bigInc = l => l.inBox || l.goalCtx || l.truth === 'vermelho' || l.decided === 'vermelho';
function obsAcc(inc, mg) {
  let w = 0, p = 0;
  inc.forEach(l => { const k = bigInc(l) ? 2 : 1; w += k; p += k * l.pts; });
  mg.forEach(m => { w += 0.6; p += 0.6 * m.pts; });
  return w ? p / w : 0.7;
}
