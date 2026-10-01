t = open('game.js').read()


def rep(a, b, cnt=1):
    global t
    assert t.count(a) == cnt, (a, t.count(a))
    t = t.replace(a, b)


rep("  const wts = def.role === 'gk' ?", "  const wts = S.forceW ? S.forceW : def.role === 'gk' ?")
rep("if (b.owner === p && gkChance(p, dt)) return;", "if (b.owner === p && (gkChance(p, dt) || gkOutCheck(p, dt))) return;")
rep("  if (S.lanceCd <= 0 && grabCheck(att, def)) return;", "  if (S.lanceCd <= 0 && (lightCheck(att, def) || stampCheck(att, def) || grabCheck(att, def))) return;")
rep("  if (L.kind === 'aereo' || L.kind === 'agarrao') { poseDuel(L, t); return; }", "  if (L.kind === 'aereo' || L.kind === 'agarrao') { poseDuel(L, t); return; }\n  if (L.kind === 'pisao') { poseStamp(L, t); return; }")
rep("  S.feed.push({ min: clockTxt(), txt, kind: kind || 'info' });\n", "  S.feed.push({ min: clockTxt(), txt, kind: kind || 'info' });\n  if ((kind === 'goal' || kind === 'card' || kind === 'pen') && !S.training) Voice.say(txt, 'Relato');\n")
rep("    halfCheck(); addedTimeCheck();", "    tutStep(); halfCheck(); addedTimeCheck();")
rep("$('refSay').hidden = true; $('radio').hidden = true; $('half').hidden = true;\n  Sfx.whistle('end');", "$('refSay').hidden = true; $('radio').hidden = true; $('half').hidden = true; $('tut').hidden = true;\n  Sfx.whistle('end');")
rep("$('refSay').hidden = true; $('radio').hidden = true; $('half').hidden = true;\n  mode = 'play';", "$('refSay').hidden = true; $('radio').hidden = true; $('half').hidden = true; $('tut').hidden = true;\n  mode = 'play';")
rep("startGoalFoul, startLine, fkCheck,", "startGoalFoul, startLine, fkCheck, gkOutCheck, lightCheck, stampCheck, startTutorial, tutClick, Voice,")
rep("// ---------- desenho 2D ----------", open('p14.js').read() + '\n// ---------- desenho 2D ----------')
open('game.js', 'w').write(t)
print('phase9 ok')
