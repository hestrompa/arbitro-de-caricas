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
rep("window.__arbitro = { get S() { return S; }, get mode() { return mode; }, start,", "window.__arbitro = { get S() { return S; }, get mode() { return mode; }, get C() { return C; }, set C(v) { C = v; }, openCareer, startCareerMatch, endMatch, saveCareer, start,")
# artigos certos para nomes de clubes e países
import re
t, n1 = re.subn(r"dos ' \+ TEAMS\[([^\]]+)\]\.name", r"' + deT(\1)", t)
t, n2 = re.subn(r"para os ' \+ TEAMS\[([^\]]+)\]\.name", r"para ' + artT(\1)", t)
assert n1 == 7 and n2 == 4, (n1, n2)
rep("(ps.length > 1 ? ps.length + ' jogadores dos ' : 'Um jogador dos ') + TEAMS[team].name", "(ps.length > 1 ? ps.length + ' jogadores ' : 'Um jogador ') + deT(team)")
open('game.js', 'w').write(t)
print('phase4 ok')
