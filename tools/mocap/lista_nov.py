# Clips do Mixamo descarregados pelo Hugo a 10 de novembro de 2026 (nomes do dump: ficheiro em minúsculas com _)
L = dict(loop=True, inplace=True)
# Os que começam por q_mx_ são gestos de corpo inteiro: o jogo trata os clips q_* como gesto (sem IK de braços nem olhar por cima).
CLIPS = {
    'q_mx_zangado': ('angry_gesture', 0.0, None, {}), 'q_mx_aponta_z': ('angry_point', 0.0, None, {}), 'q_mx_aponta': ('pointing', 0.0, None, {}),
    'm_aponta_f': ('pointing_forward', 0.0, None, {}), 'q_mx_discute': ('standing_arguing', 0.0, 6.0, {}), 'q_mx_discute2': ('standing_arguing_1', 0.0, 6.0, {}),
    'm_furia': ('angry', 0.0, 6.0, {}),
    'q_mx_dor': ('inj_injured_hurting_idle', 0.0, None, L), 'q_mx_lesao': ('inj_injured_idle', 0.0, None, L), 'm_coxo': ('inj_injured_walk', 0.0, None, L),
    'm_coxo_corre': ('inj_injured_run', 0.0, None, L), 'm_lesao_acena': ('inj_injured_wave_idle', 0.0, None, {}),
    'm_cai': ('falling_down', 0.0, None, {}), 'm_tropeca_tras': ('stumble_backwards', 0.0, None, {}), 'm_tropeca': ('jogging_stumble', 0.0, None, {}),
    'm_cab1': ('header', 0.0, None, {}), 'm_cab2': ('header_soccerball', 0.0, None, {}), 'm_cab3': ('header_soccerball_1', 0.0, None, {}),
    'm_salto': ('jump_2', 0.0, None, {}), 'm_salto2': ('jumping', 0.0, None, {}),
    'gk_bloqueio': ('goalkeeper_body_block', 0.0, None, {}), 'gk_bloqueio2': ('goalkeeper_body_block_1', 0.0, None, {}), 'gk_falha': ('goalkeeper_miss', 0.0, None, {}),
    'gk_lanca': ('goalkeeper_overhand_throw', 0.0, None, {}), 'gk_pontape': ('goalkeeper_drop_kick', 0.0, None, {}), 'gk_passe': ('goalkeeper_pass', 0.0, None, {}),
    'gk_poe_bola': ('goalkeeper_placing_ball', 0.0, None, {}), 'gk_dirige': ('goalkeeper_directing', 0.0, None, {}), 'gk_agarra3': ('goalkeeper_catch_1', 0.0, None, {}),
    'q_mx_vitoria': ('victory', 0.0, None, {}),
}
