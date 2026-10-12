#!/bin/bash
# uso: motor.sh [jogos por processo] [processos] -> resumo das métricas do motor
cd "$(dirname "$0")/arbitro44"
N=${1:-4}; P=${2:-4}
for i in $(seq 1 $P); do AF="$AF" N=$N RA=${RA:-70} RB=${RB:-70} timeout 900 ../Godot_v4.4.1-stable_linux.x86_64 --headless --path . -s t_motor.gd > /tmp/motor_${TAG}_$i.txt 2>&1 & done; wait
cat /tmp/motor_${TAG}_*.txt | grep "^JSON " | sed 's/^JSON //' | python3 -c "
import json,sys
rs=[json.loads(l) for l in sys.stdin]
n=len(rs)
def m(k,i=None):
    if i is None: return sum(r[k][0]+r[k][1] for r in rs)/n
    return sum(r[k][i] for r in rs)/n
print('jogos',n,' golos %.2f (%.2f-%.2f)'%(m('golos'),m('golos',0),m('golos',1)))
for k in ['remates','alvo','rem_area','ocasioes','xg','cruz','na_area','primeira','cantos','passes','desarmes','faltas']:
    print('%-9s %6.2f   (%.2f - %.2f)'%(k,m(k),m(k,0),m(k,1)))
pas=sum(r['passes'][0]+r['passes'][1] for r in rs); ok=sum(r['passes_ok'][0]+r['passes_ok'][1] for r in rs)
print('passes certos %.0f%%'%(100*ok/max(pas,1)))
d={}
for r in rs:
    for k,v in r['dbg'].items(): d[k]=d.get(k,0)+v
print('foras de jogo %.2f'%(sum(r['foras'] for r in rs)/n))
lk={}
for r in rs:
    for k,v in r['lances'].items(): lk[k]=lk.get(k,0)+v
print('lances/jogo', {k: round(v/n,1) for k,v in sorted(lk.items(), key=lambda x:-x[1])}, 'total %.1f'%(sum(lk.values())/n))
print('escolhas/jogo', {k: round(v/n,1) for k,v in d.items()})
"
