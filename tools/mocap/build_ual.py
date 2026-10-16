# Junta ao anims_godot.json os clips da Quaternius (prefixo q_), sem mexer nos que já lá estão.
import json, base64, numpy as np, ual
def uclip(name, settle=False, **kw):
    t1 = ual.length(name)   # nos loops o fim é exclusivo (o último frame repete o primeiro)
    Q, RP = ual.clip(name, 0.0, t1, settle=settle, **kw)
    q16 = np.round(Q * 32767).astype('<i2').tobytes()
    p16 = np.round(RP * 1000).astype('<i2').tobytes()
    return {'n': len(Q), 'fps': 30, 'loop': bool(kw.get('loop')), 'q': base64.b64encode(q16).decode(), 'p': base64.b64encode(p16).decode()}
A = json.load(open('anims_godot.json'))
for k in [k for k in A if k.startswith('q_')]: del A[k]
L = dict(loop=True, inplace=True)
Q = {
    'q_sprint': ('Sprint_Loop', L), 'q_walk': ('Walk_Loop', L), 'q_jog': ('Jog_Fwd_Loop', L), 'q_idle': ('Idle_Loop', L),
    'q_cansado': ('Idle_Tired_Loop', L), 'q_fala': ('Idle_Talking_Loop', L), 'q_nao': ('Idle_No_Loop', L), 'q_bracos': ('Idle_FoldArms_Loop', L),
    'q_empurra': ('Push_Loop', L), 'q_recua': ('Walk_Bwd_Loop', L),
    'q_toque_peito': ('Hit_Chest', {}), 'q_toque_cabeca': ('Hit_Head', {}), 'q_toque_ombro_l': ('Hit_Shoulder_L', {}), 'q_toque_ombro_r': ('Hit_Shoulder_R', {}),
    'q_toque_barriga': ('Hit_Stomach', {}), 'q_empurra_ini': ('Push_Enter', {}), 'q_festa': ('Celebration', {}),
    'q_cai1': ('Death01', {}), 'q_cai2': ('Death02', {}), 'q_desvia_l': ('Dodge_Left', {}), 'q_desvia_r': ('Dodge_Right', {}),
    'q_projetado': ('Hit_Knockback', {}), 'q_deita': ('IdleToLay', {}), 'q_levanta': ('LayToIdle', {}), 'q_salta_chao': ('KipUp', {}),
    'q_sim': ('Yes', {}), 'q_surpresa': ('Surprise', {}),
}
for k, (n, kw) in Q.items(): A[k] = uclip(n, **kw)
json.dump(A, open('anims_godot.json', 'w'))
print('com quaternius', {k: v['n'] for k, v in A.items() if k.startswith('q_')})
