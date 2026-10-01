t = open('game.js').read()


def rep(a, b, cnt=1):
    global t
    assert t.count(a) == cnt, (a, t.count(a))
    t = t.replace(a, b)


rep("  S.noVar = !B.T.var;\n", "  careerSquad();\n  S.noVar = !B.T.var;\n")
rep("  critCareer();\n", "  critCareer();\n  careerPlayers();\n")
rep("  msg += critCareerTxt();\n", "  msg += critCareerTxt() + (C.banNote || '');\n")
rep("C.sg = []; C.critS = [];", "C.sg = []; C.critS = []; seasonResetPlayers();")
rep("  renderCareer2();\n", "  renderCareer2(); renderDiscipline();\n")
rep("  lines.push(...briefSquads(h, a, C.tier));", "  lines.push(...briefSquads(h, a, C.tier), ...briefPlayers(h, a));")
rep("""stage.addEventListener('pointerdown', e => {
  if (mode !== 'play' || !S) return;
  const r = stage.getBoundingClientRect(), dpr = view.dpr;
  S.ref.tx = clamp(((e.clientX - r.left) * dpr - view.ox) / view.s, -2, W + 2);
  S.ref.ty = clamp(((e.clientY - r.top) * dpr - view.oy) / view.s, -2, H + 2);
});""", """stage.addEventListener('pointerdown', e => {
  if (!S || !['play', 'intervalo', 'fim'].includes(mode) || stage.classList.contains('view3d')) return;
  const r = stage.getBoundingClientRect(), dpr = view.dpr;
  const x = ((e.clientX - r.left) * dpr - view.ox) / view.s, y = ((e.clientY - r.top) * dpr - view.oy) / view.s;
  if (capTap(x, y) || mode !== 'play') return;
  S.ref.tx = clamp(x, -2, W + 2);
  S.ref.ty = clamp(y, -2, H + 2);
});""")
rep("startGoalFoul, startLine, fkCheck,", "startGoalFoul, startLine, fkCheck, showCard, capTap, careerPlayers,")
rep("// ---------- desenho 2D ----------", open('p15.js').read() + '\n// ---------- desenho 2D ----------')

# correção: depois da troca de campo ao intervalo, o golo e o pontapé de baliza contam pela equipa que defende aquela baliza (não pelo lado do campo)
rep("""    const side = b.x < 0 ? 0 : 1;              // 0 = baliza dos Azuis
    if (Math.abs(b.y - H / 2) < GOAL_W / 2 && b.z < 2.4) { goal(1 - side); return; }""",
"""    const side = ownGoalX(0) === (b.x < 0 ? 0 : W) ? 0 : 1;   // equipa que defende esta baliza (muda ao intervalo)
    if (Math.abs(b.y - H / 2) < GOAL_W / 2 && b.z < 2.4) { goal(1 - side); return; }""")
rep("gk.x = side === 0 ? 3 : W - 3;", "gk.x = ownGoalX(side) ? W - 3 : 3;")

open('game.js', 'w').write(t)
print('phase10 ok')
