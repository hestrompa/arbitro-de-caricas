t = open('game.js').read()


def rep(a, b, cnt=1):
    global t
    assert t.count(a) == cnt, (a, t.count(a))
    t = t.replace(a, b)


# plantéis: força do clube e jogadores com atributos
rep("  [0, 1].forEach(i => { $('hn' + i).textContent = TEAMS[i].name; $('hd' + i).style.background = TEAMS[i].color; });\n}",
    "  [0, 1].forEach(i => { $('hn' + i).textContent = TEAMS[i].name; $('hd' + i).style.background = TEAMS[i].color; });\n  teamRatings(h, a);\n}")
rep("pendCard: null, ask: null, feed: [], addMin: 0,\n  };\n  kickoff(0);", "pendCard: null, ask: null, feed: [], addMin: 0,\n  };\n  squadSetup();\n  kickoff(0);")
rep("  kick(p, m.x + m.vx * lead, m.y + m.vy * lead, lofted);", "  const pe = passErr(p, d);\n  kick(p, m.x + m.vx * lead + pe.x, m.y + m.vy * lead + pe.y, lofted);")
rep("GOAL_W * (pen ? 0.45 : 0.62);", "GOAL_W * (pen ? 0.45 : shotSpread(p));")
rep("  const sp = pen ? 22 : rand(19, 26);", "  const sp = pen ? 22 : rand(19, 26) + ((p.fin || 70) - 70) * 0.05;")
rep("clamp(0.95 - (sp - 12) * 0.03, 0.55, 0.9);", "clamp(0.95 - (sp - 12) * 0.03 + gkBonus(best), 0.5, 0.93);")
rep("  if (Math.random() > 0.5) return;                       // não chega à bola", "  if (Math.random() > tackleP(def, att)) return;          // não chega à bola")
rep("  if (S.lanceCd <= 0 && Math.random() < 0.3 + ag * 0.4) { startLance(att, def); return; }",
    "  if (S.lanceCd <= 0 && grabCheck(att, def)) return;\n  if (S.lanceCd <= 0 && Math.random() < (0.3 + ag * 0.4) * (def.foulK || 1)) { startLance(att, def); return; }")
rep("amarelo: 0.2 * (1 + ag * 2), vermelho: 0.06 * (1 + ag * 3), simulacao: 0.16 * (S.simK || 1) };",
    "amarelo: 0.2 * (1 + ag * 2) * (def.hardK || 1), vermelho: 0.06 * (1 + ag * 3) * (def.hardK || 1), simulacao: 0.16 * (S.simK || 1) * (att.simK || 1) };")
# disputa aérea nas bolas longas
rep("if (c.cross && !wasSetPiece) cornerCheck(p.team, p, true); }", "if (c.cross && !wasSetPiece) cornerCheck(p.team, p, true); else if (c.lofted && !wasSetPiece) aerialCheck(p, c.m); }")
rep("  if (L.scene) { poseScene(L, t); return; }\n  $('pip').hidden = true;\n  const { ax, ay, dxp, dyp } = poseFoul(L, t);",
    "  if (L.scene) { poseScene(L, t); return; }\n  if (L.kind === 'aereo' || L.kind === 'agarrao') { poseDuel(L, t); return; }\n  $('pip').hidden = true;\n  const { ax, ay, dxp, dyp } = poseFoul(L, t);")
# vermelhos à vista
rep("function hud() {\n", "function hud() {\n  redsUI();\n")
rep("  drawFK();\n", "  drawFK();\n  drawReds();\n")
# rádio
rep("feed('O VAR chama o árbitro ao monitor.', 'var');", "feed('O VAR chama o árbitro ao monitor.', 'var'); radio('VAR', varCallText(L, d));")
rep("      : lanceMsg(L);\n    showDecide(true);\n  }\n  syncScrub();\n  pose3D(L, 0);", "      : lanceMsg(L);\n    showDecide(true);\n  }\n  if (!review && !L.varReview && !L.radioed) radioLance(L);\n  syncScrub();\n  pose3D(L, 0);")
rep("S.gesture = null; $('refSay').hidden = true;\n  Sfx.whistle('end');", "S.gesture = null; $('refSay').hidden = true; $('radio').hidden = true;\n  Sfx.whistle('end');")
rep("$('ticker').hidden = true; $('refSay').hidden = true;\n  mode = 'play';", "$('ticker').hidden = true; $('refSay').hidden = true; $('radio').hidden = true;\n  mode = 'play';")
# afinação: lances grandes pesam mais na nota; mais escalão, menos tempo para decidir
rep("  const mg = S.manage || [], pts = inc.reduce((a, l) => a + l.pts, 0) + mg.reduce((a, m) => a + m.pts, 0);\n  const acc = inc.length + mg.length ? pts / (inc.length + mg.length) : 0.7;",
    "  const mg = S.manage || [], acc = obsAcc(inc, mg);")
rep("(c - 5) * 0.4 - (S.stress || 0) / 25)); }", "(c - 5) * 0.4 - (S.stress || 0) / 25 - (S.career ? S.career.tier * 0.5 : 0))); }")
rep("  if (!T.var) lines.push('Não há VAR", "  lines.push(...briefSquads(h, a, C.tier));\n  if (!T.var) lines.push('Não há VAR")
rep("startGoalFoul, startLine, fkCheck,", "startGoalFoul, startLine, fkCheck, aerialCheck, grabCheck, squadSetup, radio,")
rep("// ---------- desenho 2D ----------", open('p11.js').read() + '\n' + open('p12.js').read() + '\n// ---------- desenho 2D ----------')
open('game.js', 'w').write(t)
print('phase7 ok')
