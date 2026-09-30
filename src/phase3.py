t = open('game.js').read()


def rep(a, b, cnt=1):
    global t
    assert t.count(a) == cnt, (a, t.count(a))
    t = t.replace(a, b)


rep("// ---------- desenho 2D ----------", open('audio.js').read() + '\n' + open('p3.js').read() + '\n// ---------- desenho 2D ----------')
rep("ast: [{ x: W / 4, y: -1.6, flagT: 0 }, { x: W * 3 / 4, y: H + 1.6, flagT: 0 }], offsides: 0,",
    "ast: [{ x: W / 4, y: -1.6, flagT: 0 }, { x: W * 3 / 4, y: H + 1.6, flagT: 0 }], offsides: 0,\n    crowd: 35, protest: null, protests: [], sndT: 0,")
rep("decideT: 15,", "decideT: 15 - Math.round(S.crowd / 25),", 2)
# VAR antes de fechar a decisão
rep("""  if (mode !== 'lance' || !L || L.decided) return;
  L.decided = d; L.timedOut = !!timedOut;""", """  if (mode !== 'lance' || !L || L.decided) return;
  if (!L.varDone && !timedOut && needsVar(L, d) && Math.random() < 0.9) { startVar(L, d); return; }
  L.decided = d; L.timedOut = !!timedOut;""")
rep("""  if (timedOut) dc -= 4;
  S.control = clamp(S.control + dc, 0, 100);
  L.pts = pts;""", """  if (timedOut) dc -= 4;
  if (L.varFirst) { if (pts === 1) { pts = 0.7; dc = 1; } else { pts = 0; dc = -15; } }
  S.control = clamp(S.control + dc, 0, 100);
  L.pts = pts;""")
rep("""  if (dc <= -10) msg += ' · protestos em campo';
  hide3D(); showDecide(false); toast(msg, 2.6);
  mode = 'play'; S.pause = Math.max(S.pause, 1.2);
  if (S.control <= 10) endMatch('abandonado');""", """  if (L.varFirst) msg = (pts > 0 ? 'Corrigido com o VAR · ' : 'Mantiveste contra o VAR · ') + msg;
  else if (varEligible(L, d) && !timedOut) msg += ' · VAR confirmou';
  const wrong = pts < 1;
  if (foul || d === 'simulacao') Sfx.whistle(d === 'vermelho' || d === 'amarelo' || d === 'simulacao' ? 'long' : 'short');
  const against = foul ? defT : d === 'simulacao' ? atkT : (L.fall ? atkT : null);
  if (against !== null) crowdReact(against, wrong);
  const sev = d === 'vermelho' ? 0.6 : d === 'amarelo' ? 0.35 : d === 'simulacao' ? 0.35 : foul ? (L.inBox ? 0.5 : 0.12) : 0.18;
  hide3D(); showDecide(false); toast(msg, 2.6);
  mode = 'play'; S.pause = Math.max(S.pause, 1.2);
  protestAfter(against, sev, wrong);
  if (S.control <= 10) endMatch('abandonado');""")
rep("""  if (timedOut) dc -= 4;
  if (!ok) S.aggr""", """  if (timedOut) dc -= 4;
  if (L.varFirst) { L.pts = ok ? 0.7 : 0; dc = ok ? 1 : -15; }
  if (!ok) S.aggr""")
rep("""  if (!ok && !timedOut) msg += ' · protestos em campo';
  hide3D(); showDecide(false); toast(msg, 2.4);
  mode = 'play'; S.pause = Math.max(S.pause, 1);""", """  if (L.varFirst) msg = (ok ? 'Corrigido com o VAR · ' : 'Mantiveste contra o VAR · ') + msg;
  else if (!timedOut) msg += ' · VAR confirmou';
  if (d === 'fora') Sfx.whistle('short');
  const against = d === 'fora' ? L.oi.team : 1 - L.oi.team;
  crowdReact(against, !ok);
  hide3D(); showDecide(false); toast(msg, 2.4);
  mode = 'play'; S.pause = Math.max(S.pause, 1);
  protestAfter(against, d === 'fora' ? 0.28 : 0.18, !ok);""")
# ciclo: público e protestos
rep("""    refStep(dt);
    astStep(dt);""", """    refStep(dt);
    astStep(dt);
    S.crowd += (35 - S.crowd) * 0.02 * dt;""")
rep("""  } else if (mode === 'lance' && S.lance && stage.classList.contains('view3d')) {""", """  } else if (mode === 'protesto' && S.protest) {
    protestStep(dt); physics(0);
    if (S.toastT > 0) { S.toastT -= dt; if (S.toastT <= 0) $('toast').hidden = true; }
  } else if (mode === 'lance' && S.lance && stage.classList.contains('view3d')) {""")
rep("""  $('staTxt').textContent = Math.round(S.stamina); $('staBar').style.width = S.stamina + '%';
}""", """  $('staTxt').textContent = Math.round(S.stamina); $('staBar').style.width = S.stamina + '%';
  const cr = Math.round(S.crowd); $('crowdTxt').textContent = cr; $('crowdBar').style.width = cr + '%';
  $('crowdBar').style.backgroundColor = cr > 70 ? 'var(--bad)' : cr > 50 ? 'var(--orange)' : 'var(--muted)';
  const now = performance.now();
  if (now - S.sndT > 250) {
    S.sndT = now;
    const b = S.ball, att = Math.max(0, 1 - Math.min(b.x, W - b.x) / 30);
    Sfx.setCrowd(clamp(S.crowd / 100 * 0.7 + att * 0.3, 0, 1));
  }
}""")
# sons no jogo
rep("""  Object.assign(b, { owner: null, vx: n.x * sp, vy: n.y * sp, vz, z: Math.max(b.z, 0.05), last: p.team, noPick: p, noPickT: 0.3 });""",
    """  Object.assign(b, { owner: null, vx: n.x * sp, vy: n.y * sp, vz, z: Math.max(b.z, 0.05), last: p.team, noPick: p, noPickT: 0.3 });
  if (mode === 'play') Sfx.kick(clamp(1 - len(b.x - S.ref.x, b.y - S.ref.y) / 45, 0, 1) * (lofted ? 0.9 : 0.6));""")
rep("""  Object.assign(b, { owner: null, vx: n.x * sp, vy: n.y * sp, vz: pen ? rand(0, 2.5) : rand(0, 4.2), z: 0.1, last: p.team, noPick: p, noPickT: 0.4, target: null, penalty: !!pen });""",
    """  Object.assign(b, { owner: null, vx: n.x * sp, vy: n.y * sp, vz: pen ? rand(0, 2.5) : rand(0, 4.2), z: 0.1, last: p.team, noPick: p, noPickT: 0.4, target: null, penalty: !!pen });
  if (mode === 'play') { Sfx.kick(clamp(1.2 - len(b.x - S.ref.x, b.y - S.ref.y) / 45, 0.2, 1)); setTimeout(() => { if (S && S.ball.owner === null && mode === 'play') Sfx.ooh(); }, 700); }""")
rep("""  toast('Golo dos ' + TEAMS[team].name + '!', 2.2);""", """  toast('Golo dos ' + TEAMS[team].name + '!', 2.2);
  Sfx.cheer(team === HOME ? 1 : 0.4); Sfx.whistle('short');
  S.crowd = clamp(S.crowd + (team === HOME ? -18 : 8), 0, 100);""")
rep("""  $('menu').hidden = true; $('review').hidden = true; $('help').hidden = false; $('toast').hidden = true;
  mode = 'play';""", """  $('menu').hidden = true; $('review').hidden = true; $('help').hidden = false; $('toast').hidden = true; $('protest').hidden = true;
  mode = 'play';
  Sfx.init(); Sfx.whistle('long');""")
rep("""  mode = 'fim'; showDecide(false); hide3D(); $('toast').hidden = true;""", """  mode = 'fim'; showDecide(false); hide3D(); $('toast').hidden = true; $('protest').hidden = true; S.protest = null;
  Sfx.whistle('end');""")
rep("""  $('flash').hidden = false;
  setTimeout(() => { $('flash').hidden = true; if (mode === 'lance') show3D(S.lance, false); }, 600);""", """  $('flash').hidden = false;
  Sfx.ooh();
  setTimeout(() => { $('flash').hidden = true; if (mode === 'lance') show3D(S.lance, false); }, 600);""")
# relatório
rep("""    const why = l.pts === 1 ? 'Certo'""", """    const why = l.varFirst ? (l.pts > 0 ? 'Corrigido com o VAR' : 'Errado, mesmo depois do VAR') : l.pts === 1 ? 'Certo'""")
rep("""  $('gradeTxt').textContent = right + ' de ' + inc.length + ' decisões certas. ' + verdict;""",
    """  const pr = S.protests, prGood = pr.filter(p => p.dc > 0).length;
  $('gradeTxt').textContent = right + ' de ' + inc.length + ' decisões certas. ' + (pr.length ? 'Protestos: ' + prGood + ' de ' + pr.length + ' bem geridos. ' : '') + verdict;""")
# teclas e botões
rep("""  if (mode === 'lance') {
    const map""", """  if (mode === 'protesto') { const m = { '1': 'ignorar', '2': 'afastar', '3': 'amarelo' }[k]; if (m) resolveProtest(m); return; }
  const VL = S && S.lance;
  if (mode === 'lance' && VL && VL.varReview && VL.userLines && (k === 'ArrowLeft' || k === 'ArrowRight' || k === 'Tab')) {
    const u = VL.userLines;
    if (k === 'Tab') u.sel = u.sel === 'att' ? 'def' : 'att'; else u[u.sel] = clamp(u[u.sel] + (k === 'ArrowRight' ? 1 : -1) * (e.shiftKey ? 0.1 : 0.02), 0, W);
    captions3D(VL); e.preventDefault(); return;
  }
  if (mode === 'lance') {
    const map""")
rep("""$('replayBtn').addEventListener('click', replay);""", """$('replayBtn').addEventListener('click', replay);
$('pIgnore').addEventListener('click', () => resolveProtest('ignorar'));
$('pAway').addEventListener('click', () => resolveProtest('afastar'));
$('pCard').addEventListener('click', () => resolveProtest('amarelo'));
$('soundBtn').addEventListener('click', () => { Sfx.init(); const m = Sfx.toggle(); $('soundBtn').setAttribute('aria-pressed', String(!m)); $('soundBtn').textContent = m ? 'Som desligado' : 'Som ligado'; });
stage.addEventListener('pointerdown', e => { if (varPointer(e, true)) { e.preventDefault(); try { stage.setPointerCapture(e.pointerId); } catch (x) { /* sem captura */ } } });
stage.addEventListener('pointermove', e => { if (varDrag) varPointer(e, false); });
stage.addEventListener('pointerup', () => { varDrag = null; });
stage.addEventListener('pointercancel', () => { varDrag = null; });""")
# desenho: protestos
rep("""  for (const a of S.ast) {
    drawCap(""", """  if (S.protest) {
    ctx.fillStyle = '#e5533d'; ctx.font = '700 ' + Math.round(1.6 * s) + 'px "Barlow Condensed", sans-serif'; ctx.textAlign = 'center';
    for (const id of S.protest.ids) { const p = S.players[id]; ctx.fillText('!', view.ox + p.x * s, view.oy + (p.y - 1.6) * s); }
  }
  for (const a of S.ast) {
    drawCap(""")
rep("window.__arbitro = { get S() { return S; }, get mode() { return mode; }, start, decide,", "window.__arbitro = { get S() { return S; }, get mode() { return mode; }, start, decide, resolveProtest, varPointer, get R3() { return R3; },")
# 3D: VAR no monitor
rep("""function canScrub(L) { return !!(L && L.rig && (L.review || L.seen)); }""", """function canScrub(L) { return !!(L && L.rig && (L.review || L.seen || L.varReview)); }""")
rep("""  if (!review) {
    $('decideMsg').textContent = L.kind === 'offside'""", """  if (!review && L.varReview) { $('decideMsg').textContent = 'Revisão no monitor do VAR. Decidiste ' + DEC_LABEL[L.varFirst].toLowerCase() + '. Confirmas ou mudas?'; showDecide(true); }
  else if (!review) {
    $('decideMsg').textContent = L.kind === 'offside'""")
rep("""function captions3D(L) {
""", """function captions3D(L) {
  if (L.varReview && !L.review) {
    $('capL').textContent = 'Monitor do VAR' + (L.kind === 'offside' ? ' · arrasta as linhas' : ' · vista ideal');
    $('capR').textContent = L.kind === 'offside' && L.userLines ? varReadout(L) : 'Decidiste: ' + DEC_LABEL[L.varFirst];
    return;
  }
""")
rep("""    R.lines.def.visible = R.lines.att.visible = t >= OFF_KT - 0.02 && t <= OFF_KT + 0.5;
    const sideY = oi.ast.y < H / 2 ? -9 : H + 9;
    cx = oi.lineX; cy = sideY; ch = 7; lx = oi.lineX; ly = oi.recvY; fov = 30;""", """    R.lines.def.visible = R.lines.att.visible = t >= OFF_KT - 0.02 && t <= OFF_KT + 0.5;
    const sideY = oi.ast.y < H / 2 ? -9 : H + 9;
    cx = oi.lineX; cy = sideY; ch = 7; lx = oi.lineX; ly = oi.recvY; fov = 30;
    if (L.varReview && !L.review && L.userLines) {
      // no monitor: as linhas são tuas e a câmara fica no defesa (não na linha certa)
      const ld = oi.snap.find(q => q.id === oi.lineDef) || { x: oi.recvX, y: oi.recvY }, rc = oi.snap.find(q => q.id === oi.receiver) || ld, u = L.userLines;
      const my = (ld.y + rc.y) / 2, side = oi.ast.y < H / 2 ? -1 : 1, depth = Math.abs(ld.y - rc.y);
      cx = lx = (ld.x + rc.x) / 2; cy = clamp(my + side * (12 + depth * 0.6), -8, H + 8); ly = my; ch = 4.5;
      fov = clamp(2 * Math.atan((depth * 0.35 + 5) / Math.abs(cy - my) / R.cam.aspect * 1.4) * 180 / Math.PI, 16, 40);
      R.lines.def.position.x = u.def; R.lines.att.position.x = u.att; R.lines.def.visible = R.lines.att.visible = true;
      R.lines.def.scale.x = u.sel === 'def' ? 1.8 : 1; R.lines.att.scale.x = u.sel === 'att' ? 1.8 : 1;
    } else { R.lines.def.scale.x = R.lines.att.scale.x = 1; }""")
rep("document.querySelectorAll('.choice').forEach(b => b.disabled = !on);", "document.querySelectorAll('#decide .choice').forEach(b => b.disabled = !on);")
# ---- treino do VAR
rep("    S.crowd += (35 - S.crowd) * 0.02 * dt;", """    S.crowd += (35 - S.crowd) * 0.02 * dt;
    if (S.training) { S.lanceCd = 1e9; S.training.next -= dt; if (S.training.next <= 0 && S.pause <= 0) trainNext(); }""")
rep("  if (L.varFirst) { if (pts === 1) { pts = 0.7; dc = 1; } else { pts = 0; dc = -15; } }",
    "  if (L.training) { pts = pts === 1 ? 1 : 0; dc = 0; } else if (L.varFirst) { if (pts === 1) { pts = 0.7; dc = 1; } else { pts = 0; dc = -15; } }")
rep("  if (L.varFirst) { L.pts = ok ? 0.7 : 0; dc = ok ? 1 : -15; }",
    "  if (L.training) dc = 0; else if (L.varFirst) { L.pts = ok ? 0.7 : 0; dc = ok ? 1 : -15; }")
rep("  if (L.varFirst) msg = (pts > 0 ? 'Corrigido com o VAR · ' : 'Mantiveste contra o VAR · ') + msg;",
    "  if (L.training) msg = (pts === 1 ? 'Certo · ' : 'Errado, era ' + LABEL[L.truth].toLowerCase() + ' · ') + msg;\n  else if (L.varFirst) msg = (pts > 0 ? 'Corrigido com o VAR · ' : 'Mantiveste contra o VAR · ') + msg;")
rep("  if (L.varFirst) msg = (ok ? 'Corrigido com o VAR · ' : 'Mantiveste contra o VAR · ') + msg;",
    "  if (L.training) msg = (ok ? 'Certo · ' : 'Errado, era ' + LABEL[L.truth].toLowerCase() + ' por ' + Math.abs(L.oi.margin).toFixed(2).replace('.', ',') + ' m · ') + msg;\n  else if (L.varFirst) msg = (ok ? 'Corrigido com o VAR · ' : 'Mantiveste contra o VAR · ') + msg;")
rep("function crowdReact(against, wrong) {\n", "function crowdReact(against, wrong) {\n  if (S.training) return;\n")
rep("  if (team === null || team === undefined || mode !== 'play') return;", "  if (team === null || team === undefined || mode !== 'play' || S.training) return;")
rep("  Sfx.beep();\n  $('flash').textContent = 'VAR'; $('flash').hidden = false;\n  toast('O VAR pede revisão no monitor', 1.6);",
    "  Sfx.beep();\n  $('flash').textContent = 'VAR'; $('flash').hidden = false;\n  toast(L.training ? 'Treino: revê a decisão de campo' : 'O VAR pede revisão no monitor', 1.6);")
rep("  if (!review && L.varReview) { $('decideMsg').textContent = 'Revisão no monitor do VAR. Decidiste ' + DEC_LABEL[L.varFirst].toLowerCase() + '. Confirmas ou mudas?'; showDecide(true); }",
    "  if (!review && L.varReview) { $('decideMsg').textContent = (L.training ? 'Treino do VAR. A decisão em campo foi ' : 'Revisão no monitor do VAR. Decidiste ') + DEC_LABEL[L.varFirst].toLowerCase() + '. Confirmas ou mudas?'; showDecide(true); }")
rep("    $('capR').textContent = L.kind === 'offside' && L.userLines ? varReadout(L) : 'Decidiste: ' + DEC_LABEL[L.varFirst];",
    "    $('capR').textContent = L.kind === 'offside' && L.userLines ? varReadout(L) : (L.training ? 'Em campo: ' : 'Decidiste: ') + DEC_LABEL[L.varFirst];")
rep("    const why = l.varFirst ? (l.pts > 0", "    const why = l.training ? (l.pts === 1 ? (l.decided === l.varFirst ? 'Certo · confirmaste a decisão de campo' : 'Certo · corrigiste a decisão de campo') : 'Errado · decisão de campo era ' + DEC_LABEL[l.varFirst].toLowerCase()) : l.varFirst ? (l.pts > 0")
rep("  const verdict = kind === 'abandonado'", "  const verdict = kind === 'treino' ? 'Treino do VAR terminado.' : kind === 'abandonado'")
rep("$('startBtn').addEventListener('click', start);", "$('startBtn').addEventListener('click', start);\n$('trainBtn').addEventListener('click', startTraining);")
open('game.js', 'w').write(t)
print('phase3 ok')
