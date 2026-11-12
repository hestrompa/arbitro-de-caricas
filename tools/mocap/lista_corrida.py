# Corrida do Mixamo (Male Locomotion Pack, "standard run") no lugar da corrida da CMU:
# tronco inclinado e braços a balançar de origem, sem precisar do balanço de braços feito por IK.
L = dict(loop=True, inplace=True)
CLIPS = {'run': ('loc_standard_run', 0.0, None, L)}
