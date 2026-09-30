t = open('game.js').read()


def rep(a, b, cnt=1):
    global t
    assert t.count(a) == cnt, (a, t.count(a))
    t = t.replace(a, b)


rep("// ---------- desenho 2D ----------", open('p4.js').read() + '\n// ---------- desenho 2D ----------')
# dificuldade por escalão
rep("S.crowd += (35 - S.crowd) * 0.02 * dt;", "S.crowd += ((S.crowdBase || 35) - S.crowd) * 0.02 * dt;")
rep("S.lanceCd = rand(11, 16);", "S.lanceCd = rand(11, 16) * (S.lanceK || 1);", 2)
rep("simulacao: 0.16 };", "simulacao: 0.16 * (S.simK || 1) };")
rep("decideT: 15 - Math.round(S.crowd / 25),", "decideT: decisionTime(),", 2)
# atributos: físico, leitura, autoridade
rep("  const speed = sprint && moving ? 8.6 : 6;", "  const fa = refAttr('fis'), speed = sprint && moving ? 8.3 + fa * 0.06 : 5.8 + fa * 0.04;")
rep("(sprint && moving ? -16 : (moving ? 3 : 7)) * dt", "(sprint && moving ? -16 * (1.25 - 0.05 * fa) : (moving ? 3 : 7) * (0.75 + 0.05 * fa)) * dt")
rep("""  const ref = { x: S.ref.x, y: S.ref.y };
  const others""", """  const ref = { x: S.ref.x, y: S.ref.y };
  { // leitura de jogo: o árbitro antecipa e chega uns metros mais perto (ou mais longe, se ainda for fraco)
    const dd = len(P.x - ref.x, P.y - ref.y), n = norm(P.x - ref.x, P.y - ref.y), m = clamp((refAttr('leit') - 5) * 0.8, -3, Math.max(0, dd - 6));
    ref.x += n.x * m; ref.y += n.y * m;
  }
  const others""")
rep("  S.control = clamp(S.control + dc, 0, 100);", "  if (dc < 0) dc *= authK();\n  S.control = clamp(S.control + dc, 0, 100);", 3)
rep("  const I = clamp(sev + (wrong ? 0.35 : 0)", "  const I = clamp(sev - (refAttr('aut') - 5) * 0.04 + (wrong ? 0.35 : 0)")
# sem VAR nos escalões de baixo
rep("if (!L.varDone && !timedOut && needsVar(L, d)", "if (!S.noVar && !L.varDone && !timedOut && needsVar(L, d)")
rep("else if (varEligible(L, d) && !timedOut) msg += ' · VAR confirmou';", "else if (!S.noVar && varEligible(L, d) && !timedOut) msg += ' · VAR confirmou';")
rep("  else if (!timedOut) msg += ' · VAR confirmou';", "  else if (!timedOut && !S.noVar) msg += ' · VAR confirmou';")
# história: erros contra cada equipa ficam na memória delas
rep("function crowdReact(against, wrong) {\n", "function crowdReact(against, wrong) {\n  if (wrong && S.career && against !== null && against !== undefined) S.career.wrong[against]++;\n")
# caricas com número legível em camisolas claras
rep("String(p.num), '#fff', p.yellow > 0", "String(p.num), t.text || '#fff', p.yellow > 0")
# fim de jogo e botões
rep("  $('review').hidden = false; $('help').hidden = true;\n", "  $('review').hidden = false; $('help').hidden = true;\n  careerAfter(grade, kind);\n")
rep("$('startBtn').addEventListener('click', start);", "$('startBtn').addEventListener('click', () => { C = null; useTeams(null); start(); });\n$('careerBtn').addEventListener('click', () => { loadCareer(); openCareer(); });\n$('briefStart').addEventListener('click', startCareerMatch);\n$('carMenu').addEventListener('click', () => { $('career').hidden = true; $('brief').hidden = true; $('help').hidden = false; useTeams(null); newMatch(); mode = 'menu'; menuCareerLabel(); $('menu').hidden = false; });\n$('carReset').addEventListener('click', () => { if (!confirm('Apagar a carreira e começar de novo nos distritais?')) return; newCareer(); renderCareer(); newMatch(); });\nmenuCareerLabel();")
rep("$('trainBtn').addEventListener('click', startTraining);", "$('trainBtn').addEventListener('click', () => { C = null; useTeams(null); startTraining(); });")
rep("$('againBtn').addEventListener('click', () => { start(); window.scrollTo({ top: 0, behavior: 'smooth' }); });",
    "$('againBtn').addEventListener('click', () => { if (S && S.career) { openCareer(); return; } start(); window.scrollTo({ top: 0, behavior: 'smooth' }); });")
rep("  if (mode === 'menu' && (k === 'Enter' || k === ' ')) { start(); e.preventDefault(); return; }",
    "  if (mode === 'menu' && (k === 'Enter' || k === ' ')) { if (!$('brief').hidden) startCareerMatch(); else { C = null; useTeams(null); start(); } e.preventDefault(); return; }")
rep("window.__arbitro = { get S() { return S; }, get mode() { return mode; }, start,", "window.__arbitro = { get S() { return S; }, get mode() { return mode; }, get C() { return C; }, set C(v) { C = v; }, openCareer, startCareerMatch, endMatch, saveCareer, protestAfter, start,")
# ecrãs baixos: se o painel de decisão ficar fora do ecrã, leva-o à vista
rep("function showDecide(on) {\n  $('decide').hidden = !on;", "function showDecide(on) {\n  $('decide').hidden = !on;\n  if (on) panelIntoView('decide');")
rep("  $('protest').hidden = false; $('decide').hidden = true;", "  $('protest').hidden = false; $('decide').hidden = true; panelIntoView('protest');")
# artigos certos para nomes de clubes e países
import re
t, n1 = re.subn(r"dos ' \+ TEAMS\[([^\]]+)\]\.name", r"' + deT(\1)", t)
t, n2 = re.subn(r"para os ' \+ TEAMS\[([^\]]+)\]\.name", r"para ' + artT(\1)", t)
assert n1 == 7 and n2 == 4, (n1, n2)
rep("(ps.length > 1 ? ps.length + ' jogadores dos ' : 'Um jogador dos ') + TEAMS[team].name", "(ps.length > 1 ? ps.length + ' jogadores ' : 'Um jogador ') + deT(team)")

# nervos, capitães e custo do VAR
rep("crowd: 35, protest: null, protests: [], sndT: 0,", "crowd: 35, protest: null, protests: [], sndT: 0, stress: 15, stressBase: 15, capTrust: [0.5, 0.5], varN: 0,")
rep("decideT: decisionTime(),", "decideT: decisionTime(), stress: S.stress || 0,", 2)
rep("S.crowd += ((S.crowdBase || 35) - S.crowd) * 0.02 * dt;", "S.crowd += ((S.crowdBase || 35) - S.crowd) * 0.02 * dt; stressStep(dt);")
rep("  L.pts = pts;\n  S.incidents.push(L);", "  L.pts = pts;\n  S.incidents.push(L); stressAfter(L);")
rep("  if (dc < 0) dc *= authK();\n  S.control = clamp(S.control + dc, 0, 100);\n  S.incidents.push(L);\n", "  if (dc < 0) dc *= authK();\n  S.control = clamp(S.control + dc, 0, 100);\n  S.incidents.push(L); stressAfter(L);\n")
rep("  R.cam.lookAt(L.cam.x, 0.85, L.cam.y);", "  { const sh = camShake(L, camDist); R.cam.lookAt(L.cam.x + sh.x, 0.85 + sh.y, L.cam.y + sh.z); }")
rep("  S.protest = { team, ids: ps.map(p => p.id), I, t: 0 };", "  S.protest = { team, ids: ps.map(p => p.id), I, t: 0 };\n  addStress(I * 8);\n  $('pCapT').textContent = '4 · confiança ' + Math.round(S.capTrust[team] * 100) + '%';")
rep("  else {\n    const p = S.players[P.ids[0]];\n    p.yellow++;", "  else if (choice === 'capitao') { const o = talkCaptain(P); dc = o.dc; msg = o.msg; }\n  else {\n    const p = S.players[P.ids[0]];\n    if (p === captainOf(p.team)) S.capTrust[p.team] = clamp(S.capTrust[p.team] - 0.25, 0, 1);\n    p.yellow++;")
rep("  if (wrong && S.career && against !== null && against !== undefined) S.career.wrong[against]++;\n",
    "  if (wrong && S.career && against !== null && against !== undefined) S.career.wrong[against]++;\n  if (against !== null && against !== undefined && !S.training) S.capTrust[against] = clamp(S.capTrust[against] + (wrong ? -0.12 : 0.03), 0, 1);\n")
rep("  L.varFirst = d; L.varDone = true;", "  L.varFirst = d; L.varDone = true;\n  if (!L.training) { S.varN++; S.control = clamp(S.control - 4 * authK(), 0, 100); addStress(10); }")
rep("'O VAR pede revisão no monitor', 1.6);", "'O VAR chama-te ao monitor: ir ver custa autoridade', 1.8);")
rep("(pr.length ? 'Protestos: ' + prGood + ' de ' + pr.length + ' bem geridos. ' : '')", "(pr.length ? 'Protestos: ' + prGood + ' de ' + pr.length + ' bem geridos. ' : '') + (S.varN ? 'Foste ao monitor ' + S.varN + (S.varN > 1 ? ' vezes. ' : ' vez. ') : '')")
rep("  $('crowdBar').style.backgroundColor = cr > 70 ? 'var(--bad)' : cr > 50 ? 'var(--orange)' : 'var(--muted)';",
    "  $('crowdBar').style.backgroundColor = cr > 70 ? 'var(--bad)' : cr > 50 ? 'var(--orange)' : 'var(--muted)';\n  const st = Math.round(S.stress); $('stTxt').textContent = st; $('stBar').style.width = st + '%'; $('stBar').style.backgroundColor = st > 65 ? 'var(--bad)' : st > 40 ? 'var(--orange)' : 'var(--good)';")
rep("  for (const p of list) {\n    const t = TEAMS[p.team];", "  const caps = [captainOf(0), captainOf(1)];\n  for (const p of list) {\n    const t = TEAMS[p.team];")
rep("t.text || '#fff', p.yellow > 0, fx, fy, p.down > 0 ? 0.6 : 1);\n", "t.text || '#fff', p.yellow > 0, fx, fy, p.down > 0 ? 0.6 : 1);\n    if (p === caps[p.team]) { ctx.strokeStyle = '#f2cf3a'; ctx.lineWidth = Math.max(2, 0.32 * s); ctx.beginPath(); ctx.arc(view.ox + p.x * s, view.oy + p.y * s, CAP_R * 0.98 * s, 2.3, 3.9); ctx.stroke(); }\n")
rep("{ '1': 'ignorar', '2': 'afastar', '3': 'amarelo' }", "{ '1': 'ignorar', '2': 'afastar', '3': 'amarelo', '4': 'capitao' }")
rep("$('pCard').addEventListener('click', () => resolveProtest('amarelo'));", "$('pCard').addEventListener('click', () => resolveProtest('amarelo'));\n$('pCap').addEventListener('click', () => resolveProtest('capitao'));")
open('game.js', 'w').write(t)
print('phase4 ok')
