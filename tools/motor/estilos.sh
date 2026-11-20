#!/bin/bash
# uso: GODOT=... AF='{"motor2":1}' N=6 bash tools/motor/estilos.sh  -> golos, xG, remates e 0-0 por confronto de estilos (N jogos x 4 processos)
cd "$(dirname "$0")/../.."
export GODOT=${GODOT:-godot}
for par in "posse:posse" "contra:contra" "pressao:pressao" "direto:direto" "posse:contra" "pressao:contra" "direto:posse"; do
  EA=${par%%:*}; EB=${par##*:}
  EA=$EA EB=$EB TAG=${TAGP:-e}_${EA}_${EB} bash tools/motor/motor.sh ${N:-6} 4 > /dev/null 2>&1
  cat /tmp/motor_${TAGP:-e}_${EA}_${EB}_*.txt | grep -c "SCRIPT ERROR" | sed "s/^/erros $par: /" | grep -v ": 0$"
  cat /tmp/motor_${TAGP:-e}_${EA}_${EB}_*.txt | grep "^JSON " | sed 's/^JSON //' | python3 -c "
import json,sys
rs=[json.loads(l) for l in sys.stdin]; n=len(rs)
g=[sum(r['golos'][i] for r in rs)/n for i in (0,1)]
x=[sum(r['xg'][i] for r in rs)/n for i in (0,1)]
s=[sum(r['remates'][i] for r in rs)/n for i in (0,1)]
p=[sum(r['posse'][i] for r in rs) for i in (0,1)]; pt=sum(p) or 1
z=sum(1 for r in rs if sum(r['golos'])==0)/n
print('%-16s %2d jogos  golos %.2f (%.2f-%.2f)  xG %.2f-%.2f  remates %.1f-%.1f  posse %.0f%%  0-0 %.0f%%'%('$EA x $EB',n,g[0]+g[1],g[0],g[1],x[0],x[1],s[0],s[1],100*p[0]/pt,100*z))
"
done
