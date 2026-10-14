import sys,re,ast
for f in sys.argv[1:]:
    t=open(f).read()
    g=lambda k: float(re.search(r'^'+k+r'\s+([\d.]+)',t,re.M).group(1))
    gol=float(re.search(r'golos ([\d.]+)',t).group(1))
    m=re.search(r"escolhas/jogo (\{.*\})",t); d=ast.literal_eval(m.group(1))
    pc=re.search(r'passes certos (\d+)',t).group(1)
    fj=re.search(r'foras de jogo ([\d.]+)',t).group(1)
    lt=re.search(r'total ([\d.]+)',t).group(1)
    print('%-6s gol %.2f rem %.1f oc %.2f xg %.2f cruz %.2f pas %.0f(%s%%) des %.1f fal %.1f fj %s lances %s | troca %.1f p/posse %.2f seq3 %.1f seq6 %.1f vira %.1f tab %.1f ter %.1f dmei %.1f drib %.1f | ent3 %.1f duel %.1f bat %.1f t %.0f/%.0f/%.0f | pausa %.0f parado %.0f dono %.0f voo %.0f solta %.0f | esp %.1f perto %.2f z/ent %.2f' % (
      f.split('/')[-1][:-4], gol, g('remates'), g('ocasioes'), g('xg'), g('cruz'), g('passes'), pc, g('desarmes'), g('faltas'), fj, lt,
      d.get('posse_troca',0), d.get('seq_tot',0)/max(d.get('posse_troca',1),1), d.get('seq3',0), d.get('seq6',0), d.get('vira',0), d.get('tabela',0), d.get('terceiro',0), d.get('perde_desarme_mei',0), d.get('dribble',0), d.get('entra3',0), d.get('duelo',0), d.get('batido',0), d.get('t_def',0), d.get('t_mei',0), d.get('t_ata',0), d.get('e_pausa',0), d.get('e_parado',0), d.get('e_dono',0), d.get('e_voo',0), d.get('e_solta',0), d.get('esp_sum',0)/max(d.get('esp_n',1),1), d.get('perto_sum',0)/max(d.get('esp_n',1),1), sum(v for k,v in d.items() if k in ('z_pass','z_dribble','z_shoot','z_through','z_cruza_cruz'))/max(d.get('entra3',1),1)))
