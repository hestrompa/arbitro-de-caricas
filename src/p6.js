// ---------- relato do jogo e resumo no relatório ----------
const pickOf = a => a[Math.floor(Math.random() * a.length)];
function feed(txt, kind) {
  if (!S || !S.feed) return;
  S.feed.push({ min: clockTxt(), txt, kind: kind || 'info' });
  const el = $('ticker'); if (!el) return;
  el.textContent = clockTxt() + '  ' + txt; el.hidden = false;
  el.classList.remove('fresh'); void el.offsetWidth; el.classList.add('fresh');
}
const who = (num, team) => 'o ' + num + ' ' + deT(team);
function feedGoal(team) {
  const k = S.ball.kicker, n = k && k.team === team ? k.num : null, pen = S.ball.penalty;
  const lines = pen ? ['Golo ' + deT(team) + '! Penálti bem batido' + (n ? ' pelo ' + n : '') + '.', 'Golo ' + deT(team) + ' de penálti, guarda-redes para um lado e bola para o outro.']
    : n ? ['Golo ' + deT(team) + '! Remate do ' + n + ' que só para no fundo da baliza.', 'Golo ' + deT(team) + '! O ' + n + ' não perdoa.', 'Golo ' + deT(team) + '! O ' + n + ' encosta e festeja.']
      : ['Golo ' + deT(team) + '!'];
  feed(pickOf(lines) + ' ' + S.score[0] + '–' + S.score[1] + '.', 'goal');
}
function feedDecision(L, d, msg) {
  if (L.training) return;
  const kind = d === 'amarelo' || d === 'vermelho' || d === 'simulacao' || d === 'maoAmarelo' ? 'card' : /Penálti/.test(msg) ? 'pen' : 'info';
  let intro = '';
  if (L.goalCtx) intro = pickOf(['Revisão do golo: ', 'Antes de validar o golo: ', 'Golo em análise: ']);
  else if (L.kind === 'offside') intro = pickOf(['Passe em profundidade para ' + who(S.players[L.oi.receiver].num, L.oi.team) + ': ', 'Bola nas costas da defesa: ']);
  else if (L.kind === 'mao') intro = pickOf(['Remate do ' + L.att.num + ' e a bola bate no ' + L.def.num + ': ', 'A bola bate no ' + L.def.num + ' ' + deT(L.def.team) + ': ']);
  else if (L.kind === 'canto') intro = pickOf(['Muita luta na área no canto: ', 'Empurrões na área no canto ' + deT(L.att.team) + ': ']);
  else if (L.def.role === 'gk') intro = 'O guarda-redes sai aos pés do ' + L.att.num + ': ';
  else intro = pickOf(['Duelo entre ' + who(L.att.num, L.att.team) + ' e ' + who(L.def.num, L.def.team) + ': ', 'Entrada do ' + L.def.num + ' ' + deT(L.def.team) + ' sobre o ' + L.att.num + ': ', 'Choque a meio-campo: ']);
  feed(intro + msg.charAt(0).toLowerCase() + msg.slice(1) + '.', kind);
}
// relatório: momentos marcantes primeiro, o relato completo numa secção que abre
function summaryRows() {
  const key = S.feed.filter(f => f.kind !== 'info');
  const ol = $('sumList'); ol.textContent = '';
  (key.length ? key : [{ min: '', txt: 'Jogo sem golos, cartões nem VAR.', kind: 'info' }]).forEach(f => {
    const li = document.createElement('li'); li.className = 'k-' + f.kind;
    const b = document.createElement('b'); b.textContent = f.min; li.append(b, document.createTextNode(' ' + f.txt)); ol.appendChild(li);
  });
  const fl = $('feedList'); fl.textContent = '';
  S.feed.forEach(f => { const li = document.createElement('li'); const b = document.createElement('b'); b.textContent = f.min; li.append(b, document.createTextNode(' ' + f.txt)); fl.appendChild(li); });
  $('feedCount').textContent = S.feed.length + (S.feed.length === 1 ? ' entrada' : ' entradas');
}
