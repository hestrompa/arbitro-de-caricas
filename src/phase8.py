t = open('game.js').read()


def rep(a, b, cnt=1):
    global t
    assert t.count(a) == cnt, (a, t.count(a))
    t = t.replace(a, b)


# intervalo e troca de campo
rep("function newMatch() {\n  const players = [];", "function newMatch() {\n  TEAMS[0].dir = 1; TEAMS[1].dir = -1;\n  const players = [];")
rep("manage: [], fk: null,", "manage: [], crit: [], critFlips: 0, half: 0, fk: null,")
rep("    addedTimeCheck(); pendStep(dt);", "    halfCheck(); addedTimeCheck(); pendStep(dt);")
rep("mode === 'fim' ? reviewing", "(mode === 'fim' || mode === 'intervalo') ? reviewing", 3)
rep("mode === 'fim' && reviewing", "(mode === 'fim' || mode === 'intervalo') && reviewing", 2)
rep("S.gesture = null; $('refSay').hidden = true; $('radio').hidden = true;\n  Sfx.whistle('end');", "S.gesture = null; $('refSay').hidden = true; $('radio').hidden = true; $('half').hidden = true;\n  Sfx.whistle('end');")
rep("$('refSay').hidden = true; $('radio').hidden = true;\n  mode = 'play';", "$('refSay').hidden = true; $('radio').hidden = true; $('half').hidden = true;\n  mode = 'play';")
# lances de interpretação: as duas decisões contam como certas, e fica registado o critério
rep("    const diff = SEV[d] - SEV[L.truth];\n    if (diff === 0) { pts = 1; dc = 4; }", "    const ok2 = interpOK(L, d) || (d === L.truth && !!interpOf(L));\n    const diff = ok2 ? 0 : SEV[d] - SEV[L.truth];\n    if (ok2) critNote(L, d);\n    if (diff === 0) { pts = 1; dc = 4; }")
rep("function needsVar(L, d) {\n", "function needsVar(L, d) {\n  if (interpOK(L, d)) return false;\n")
rep("    const why = l.missAdv ?", "    const why = l.interpOK && l.pts === 1 ? 'Certo · no limite: ' + interpTxt(l) + ' serviam' + (l.critFlip ? ' (mas aos ' + l.critFlip + \"' foste por outro critério)\" : '') : l.missAdv ?")
rep("(l.goal !== undefined && l.kind === 'offside' ? ' · no golo' : '');\n    const seen", "(l.goal !== undefined && l.kind === 'offside' ? ' · no golo' : '') + (l.interp ? ' · no limite' + (l.interpWhy ? ', ' + l.interpWhy : '') : '');\n    const seen")
rep("+ verdict;\n  $('revTitle')", "+ verdict + critTxt();\n  $('revTitle')")
rep("  if (kind === 'abandonado') grade = Math.min(grade, 3);", "  grade = clamp(grade - critPenalty(), 0, 10);\n  if (kind === 'abandonado') grade = Math.min(grade, 3);")
# carreira: critério de jogo para jogo
rep("  C.sg.push(g);\n  career2(g);\n", "  C.sg.push(g);\n  career2(g);\n  critCareer();\n")
rep("  const avg = C.sg.reduce((a, b) => a + b, 0) / C.sg.length, f1", "  const avg = C.sg.reduce((a, b) => a + b, 0) / C.sg.length + critSeasonAdj(), f1")
rep("  if (C.posNote) msg += ' ' + C.posNote;", "  msg += critCareerTxt();\n  if (C.posNote) msg += ' ' + C.posNote;")
rep("C.season++; C.round = 0; C.sg = [];", "C.season++; C.round = 0; C.sg = []; C.critS = [];")
rep("startGoalFoul, startLine, fkCheck,", "startGoalFoul, startLine, fkCheck, halfTime, secondHalf, interpOf,")
rep("// ---------- desenho 2D ----------", open('p13.js').read() + '\n// ---------- desenho 2D ----------')
open('game.js', 'w').write(t)
print('phase8 ok')
