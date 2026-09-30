# Árbitro de Caricas

Jogo de árbitro de futebol no browser. O jogo corre em 2D, com os jogadores como caricas vistas de cima. Os lances que tens de julgar abrem em 3D, vistos do sítio onde estás no campo.

Abre o `index.html` num browser moderno. Não precisa de instalação nem de servidor.

## Como se joga

- Segues o jogo com a carica preta e amarela: WASD, setas ou toque no campo. Shift faz correr e gasta energia.
- Quando há um lance, vês o momento em 3D a partir da tua posição. Longe ou tapado, vês pior. Decides entre siga, falta, amarelo, vermelho ou simulação (teclas 1 a 5).
- Nos foras de jogo apertados vês o passe pelos olhos do assistente e decides se confias na bandeira (1 em jogo, 2 fora de jogo).
- Depois de veres o lance uma vez podes pausar e andar fotograma a fotograma (espaço, vírgula e ponto), enquanto o relógio da decisão corre.
- Os Azuis jogam em casa. O público pressiona e reduz o tempo para decidir, e os jogadores prejudicados vêm protestar: ignorar, afastar ou amarelo (1 a 3).
- Quando erras num vermelho, num penálti ou num fora de jogo, o VAR chama-te ao monitor. No fora de jogo arrastas as linhas no relvado (setas afinam, Tab troca de linha).
- "Treinar o VAR" no menu dá seis lances seguidos para rever no monitor.
- Na "Carreira" começas nos distritais e sobes por Liga 3, Liga 2, Primeira Liga e Taça Europeia até ao Mundial. O observador decide no fim de cada época se sobes, ficas ou desces. Cada jogo dá pontos para melhorar o árbitro (físico, leitura de jogo, autoridade, calma). Os jogos têm história: dérbis, equipas que se lembram dos teus erros, e escalões sem VAR. A carreira fica guardada no browser.
- No fim, o observador avalia cada decisão contra o que aconteceu de facto, e podes rever cada lance com a vista ideal.

## Estrutura

- `index.html`: o jogo completo num só ficheiro, pronto a abrir.
- `src/`: código-fonte. `python3 build.py` (dentro de `src/`) volta a gerar o `index.html`.
  - `jogo-base.js`: simulação 2D, IA das equipas, árbitro, assistentes, decisões.
  - `rig3d.js`: corpo 3D dos jogadores, poses, câmaras e guiões dos lances.
  - `audio.js`: sons sintetizados com Web Audio.
  - `p3.js`: público, protestos, VAR e treino do VAR.
  - `p4.js`: carreira (escalões, clubes, atributos, histórias dos jogos).
  - `splice.py`, `phase3.py` e `phase4.py`: juntam as partes no `game.js` final.
- `assets/`: corpo humano já convertido (`human.bin`, `human.json`) e texturas de pele.
- `tools/build_human.py`: converte o corpo base do MakeHuman no formato do jogo (precisa do pacote npm `makehuman-data`, numpy e Pillow).

## Tecnologia

- Three.js r128, carregado do cdnjs.
- Canvas 2D para o jogo em caricas.
- Web Audio para todos os sons. Não há ficheiros de áudio.

## Créditos e licenças

- Código: licença MIT (ver `LICENSE`).
- Corpo humano e texturas de pele: [MakeHuman](http://www.makehuman.org), a partir do pacote npm `makehuman-data`. Os ficheiros de origem indicam a licença AGPL3 do MakeHuman, que declara os modelos exportados como CC0. Esta licença deve ser confirmada antes de uma distribuição comercial.

## Próximos passos

- Animações captadas de pessoas reais para corrida, carrinhos e quedas.
