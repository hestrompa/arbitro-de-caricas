import base64, json, subprocess
exec(open('splice.py').read())
exec(open('phase3.py').read())
M = '../assets/'
h = json.load(open(M + 'human.json'))
skins = {k: 'data:image/jpeg;base64,' + base64.b64encode(open(M + 'skin_' + k + '.jpg', 'rb').read()).decode() for k in ['light', 'mid', 'brown', 'dark']}
human = 'window.HUMAN = ' + json.dumps({'h': h, 'bin': base64.b64encode(open(M + 'human.bin', 'rb').read()).decode(), 'skins': skins}, separators=(',', ':')) + ';\n'
head = open('head5.part').read()
s = open('game.js').read()
open('../index.html', 'w').write(head + '<script>\n// Corpo humano e texturas de pele: MakeHuman (makehuman.org), via pacote npm makehuman-data. Ver README.\n' + human + '</script>\n<script>\n' + s + '</script>\n')
print('index bytes', len(open('../index.html').read().encode()))
