# Árbitro de Caricas

Jogo de árbitro de futebol no browser. O jogo corre em 2D, com os jogadores como caricas vistas de cima. Os lances que tens de julgar abrem em 3D, vistos do sítio onde estás no campo.

Abre o `index.html` num browser moderno. Não precisa de instalação nem de servidor.

## Jogar no telemóvel, sem internet

Com o GitHub Pages ligado (Settings → Pages → Deploy from a branch → `main` / root), o jogo fica em https://hestrompa.github.io/arbitro-de-caricas/. Aberto aí no telemóvel, o menu mostra "Instalar a app" (Android) ou usa-se "Adicionar ao ecrã principal" (iPhone). Depois de instalado abre em ecrã inteiro e funciona sem internet.

## Versão Godot (em curso)

O jogo está a passar para o Godot 4. O primeiro lance 3D já corre em Godot e pode ser jogado no browser em `jogar-godot/` (com o GitHub Pages ligado). Detalhes em [godot/LEIA-ME.md](godot/LEIA-ME.md).

## Como se joga

- Segues o jogo com a carica preta e amarela: WASD, setas ou toque no campo. Shift faz correr e gasta energia.
- Quando há um lance, vês o momento em 3D a partir da tua posição. Longe ou tapado, vês pior. Decides entre siga, falta, amarelo, vermelho ou simulação (teclas 1 a 5).
- Nos foras de jogo apertados vês o passe pelos olhos do assistente e decides se confias na bandeira (1 em jogo, 2 fora de jogo).
- Depois de veres o lance uma vez podes pausar e andar fotograma a fotograma (espaço, vírgula e ponto), enquanto o relógio da decisão corre.
- Os Azuis jogam em casa. O público pressiona e reduz o tempo para decidir, e os jogadores prejudicados vêm protestar: ignorar, afastar, amarelo ou falar com o capitão (1 a 4). O capitão, com a braçadeira amarela, só acalma a equipa se confiar em ti, e a confiança cai quando erras contra eles.
- Há mais tipos de lance: mão na bola (siga, mão, mão com amarelo), empurrões na área nos cantos (penálti ou falta do atacante) e saídas do guarda-redes aos pés do avançado.
- Lei da vantagem (tecla 6): se a bola sobra para um colega com espaço, deixas seguir e na paragem seguinte decides se mostras o cartão.
- Faltas repetidas do mesmo jogador e faltas táticas num contra-ataque pedem amarelo. O guarda-redes que está a ganhar pode queimar tempo: mandas jogar ou mostras amarelo. No fim o 4.º árbitro mostra os descontos.
- Os golos são revistos antes de contar: falta do atacante antes do remate, fora de jogo no passe da jogada e bola em cima da linha (com a câmara da linha de golo). O VAR verifica todos os golos.
- Nos livres diretos perto da área olhas para a barreira e decides se mandas bater, se medes os 9,15 m com o spray ou se mostras amarelo. Quem se volta a adiantar depois do spray leva amarelo.
- Depois de cada decisão o árbitro em 3D comunica-a: mostra o cartão, aponta para a marca de penálti ou para o meio-campo, faz o sinal de vantagem e explica a decisão aos jogadores numa frase.
- As equipas e os jogadores têm qualidade, como no Football Manager: cada clube tem uma força (mais alta nos escalões de cima e nos grandes de cada escalão) e cada carica é um jogador com nome, velocidade, passe, remate, desarme e disciplina. Cada equipa tem uma estrela (★ no campo), e pode ter um jogador duro, que faz mais faltas e mais graves, e um simulador, que se atira mais. O dossiê antes do jogo diz quem é favorito e quem é preciso vigiar.
- Os vermelhos ficam à vista: no marcador, ao lado do nome da equipa, e junto ao banco, por baixo do campo.
- Rádio dos árbitros: o assistente diz o que viu nos foras de jogo e nos lances tapados (acerta quase sempre, mas nem sempre), o VAR explica porque te chama e confirma os golos, e o 4.º árbitro avisa quando o banco está a ferver.
- Lances novos em 3D: disputa de cabeça nas bolas longas (empurrão, braço de alavanca ou cotovelada) e agarrão à camisola num contra-ataque.
- Ao intervalo as equipas trocam de campo. Antes da 2.ª parte revês os lances da 1.ª (com a vista ideal e a avaliação) e escolhes uma conversa: com os capitães, com os assistentes ou descansar.
- Há lances de interpretação: faltas no limite do amarelo (ou do vermelho), faltas que cortam um ataque prometedor e toques leves na área. Nesses, as duas decisões contam como certas, mas o observador vê o teu critério: se mudas de critério no mesmo jogo, a equipa prejudicada queixa-se e a nota desce; na carreira, ter o mesmo critério de jogo para jogo dá pontos na média da época.
- Mais lances em 3D: pisão por trás a quem protege a bola, guarda-redes que sai da área contra um avançado isolado, e toque leve na área.
- Os jogadores têm memória na carreira: 5 amarelos dão 1 jogo de castigo, a expulsão por 2 amarelos dá 1 jogo e o vermelho direto dá 2. Quem expulsaste lembra-se de ti e entra mais duro. O ecrã da carreira mostra a disciplina da época, e tocar numa carica abre a ficha do jogador.
- O rádio e o relato falam (voz do browser, em português), com botão para desligar no menu.
- "Primeiro jogo guiado" no menu ensina as teclas, os lances, o fora de jogo e o VAR.
- Os equipamentos têm o padrão de cada clube (riscas, aros, faixa, metades, mangas), gola e punhos, risca nos calções, nome nas costas e emblema ao peito. O árbitro troca de equipamento quando uma equipa joga de preto.
- Os treinadores também saem da área técnica a protestar: mandas sentar, mostras amarelo ou, se insistirem, vermelho.
- Há relato do jogo, um estádio 3D com bancadas nas cores das equipas, e o relatório final começa pelos momentos do jogo.
- Quando erras num vermelho, num penálti ou num fora de jogo, o VAR chama-te ao monitor, e cada ida ao monitor custa autoridade. No fora de jogo arrastas as linhas no relvado (setas afinam, Tab troca de linha).
- Os nervos do árbitro sobem com erros, protestos, idas ao VAR e público exaltado. Com nervos altos tens menos tempo para decidir e a imagem do lance treme.
- Os jogadores em 3D usam animações captadas de pessoas reais (corrida, carrinho, queda, mergulho, remate).
- "Treinar o VAR" no menu dá seis lances seguidos para rever no monitor.
- Na "Carreira" começas nos distritais e sobes por Liga 3, Liga 2, Primeira Liga e Taça Europeia até ao Mundial. O observador decide no fim de cada época se sobes, ficas ou desces. Cada jogo dá pontos para melhorar o árbitro (físico, leitura de jogo, autoridade, calma). Os jogos têm história: dérbis, equipas que se lembram dos teus erros, e escalões sem VAR. As épocas têm 6 ou 7 jogos, há uma classificação dos árbitros do escalão (o primeiro é árbitro do ano e ganha pontos extra) e depois de cada jogo sai o jornal com o título, as estrelas do árbitro e o que disse o treinador. A carreira fica guardada no browser.
- No fim, o observador avalia cada decisão contra o que aconteceu de facto (os lances grandes, na área, golos e vermelhos, pesam o dobro), e podes rever cada lance com a vista ideal.

## Estrutura

- `index.html`: o jogo completo num só ficheiro, pronto a abrir.
- `src/`: código-fonte. `python3 build.py` (dentro de `src/`) volta a gerar o `index.html`.
  - `jogo-base.js`: simulação 2D, IA das equipas, árbitro, assistentes, decisões.
  - `rig3d.js`: corpo 3D dos jogadores, poses, câmaras e guiões dos lances.
  - `audio.js`: sons sintetizados com Web Audio.
  - `p3.js`: público, protestos, VAR e treino do VAR.
  - `p4.js`: carreira (escalões, clubes, atributos, histórias dos jogos).
  - `p5.js`: mão na bola, cantos, guarda-redes, vantagem, antijogo e descontos.
  - `p6.js`: relato e momentos do jogo.
  - `p7.js`: estádio 3D e modo app instalável.
  - `p8.js`: lances de golo (falta, fora de jogo, linha de golo) e livres diretos com barreira.
  - `p9.js`: gestos e explicações do árbitro em 3D.
  - `p10.js`: carreira 2.0 (épocas longas, jornais, treinadores, classificação dos árbitros).
  - `p11.js`: plantéis e força das equipas, vermelhos à vista, rádio dos árbitros e nota do observador.
  - `p12.js`: lances novos em 3D (disputa aérea e agarrão).
  - `p13.js`: lances de interpretação, critério do árbitro e intervalo.
  - `p14.js`: pisão, guarda-redes fora da área, toque leve, voz e primeiro jogo guiado.
  - `p15.js`: castigos e memória dos jogadores na carreira, ficha do jogador.
  - `splice.py` e `phase3.py` a `phase10.py`: juntam as partes no `game.js` final.
- `manifest.webmanifest`, `sw.js` e os ícones: modo app instalável e offline.
- `assets/`: corpo humano já convertido (`human.bin`, `human.json`) e texturas de pele.
- `assets/anims.json`: animações captadas (corrida, trote, parado, mergulho, queda, remate) já adaptadas ao corpo do jogo.
- `tools/mocap/`: scripts que leem os ficheiros BVH da base de dados da CMU e os adaptam ao esqueleto do MakeHuman (`build_anims.py` gera o `anims.json`).
- `tools/build_human.py`: converte o corpo base do MakeHuman no formato do jogo (precisa do pacote npm `makehuman-data`, numpy e Pillow).

## Tecnologia

- Three.js r128, carregado do cdnjs.
- Canvas 2D para o jogo em caricas.
- Web Audio para todos os sons. Não há ficheiros de áudio.

## Créditos e licenças

- Código: licença MIT (ver `LICENSE`).
- Corpo humano e texturas de pele: [MakeHuman](http://www.makehuman.org), a partir do pacote npm `makehuman-data`. Os ficheiros de origem indicam a licença AGPL3 do MakeHuman, que declara os modelos exportados como CC0. Esta licença deve ser confirmada antes de uma distribuição comercial.
- Animações: [CMU Graphics Lab Motion Capture Database](http://mocap.cs.cmu.edu), financiada pela NSF EIA-0196217. Uso livre, incluindo comercial; não se pode revender a base de dados em si.
