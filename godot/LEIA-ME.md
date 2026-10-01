# Árbitro de Caricas em Godot 4

O jogo está a passar do browser (Three.js) para o Godot 4.4, com o motor de física Jolt. Esta pasta tem os lances 3D com o mesmo corpo MakeHuman e animações reais da base de dados de captura de movimento da CMU.

- `projeto/`: projeto Godot 4.4 (abre o `project.godot` no editor).
  - `scripts/jogador.gd`: o jogador (corpo físico, queda ativa, IK de pés e mãos, levantar-se).
  - `scripts/main.gd`: menu, estádio, os lances 3D, a bola, as câmaras e a decisão do árbitro.
  - `scripts/partida.gd`: o jogo de caricas (22 jogadores em 4-3-3, passes, remates, foras de jogo com os assistentes, golos, intervalo com troca de campo).
  - `scripts/campo2d.gd`: desenha o campo visto de cima e lê os comandos do árbitro.
- `make_glb.py`: converte o corpo MakeHuman e as animações (`tools/mocap/build_anims_godot.py` gera o `anims_godot.json`) no `projeto/assets/jogador.glb`.
- `exportar.sh`: exporta para a web, para a pasta `jogar-godot/`.

Para jogar no browser: `https://hestrompa.github.io/arbitro-de-caricas/jogar-godot/`. A versão para computador (Windows, Linux) exporta-se a partir do editor e usa o renderizador Forward+ (sombras suaves, oclusão de ambiente, relva com volume).

## Partida

No menu escolhe "Jogar partida". O jogo corre visto de cima (5 minutos reais = 90 minutos). Moves o árbitro com WASD ou setas (Shift para correr) ou clicando/tocando no campo.

Quando há uma entrada duvidosa, o jogo passa para 3D e mostra o lance visto de onde estás (a distância e quem está a tapar contam). Depois decides: Siga (Z), Falta (X), Amarelo (C), Vermelho (V) ou Simulação (B), ou com os botões. Tens 7 segundos; podes rever o lance duas vezes (R), já com as outras câmaras (1-4).

A decisão tem consequências no jogo: livre, penálti dentro da área, cartões (dois amarelos = expulso), e o controlo do jogo sobe ou desce. No fim aparece a nota do observador e a lista de lances.

## Treino de lances

N muda de lance; R repete com outro toque (força e ângulo novos). A verdade do lance aparece em cima depois do contacto.

1. Entrada: a força e o ângulo decidem se o atacante só se desequilibra, cai pelo impacto ou é varrido com força (fica queixoso mais tempo). Às vezes é simulação: o defesa só toca na bola e o atacante atira-se.
2. Empurrão nas costas: as mãos do defesa vão mesmo às costas do atacante (IK); empurrão leve desequilibra, forte projeta-o.
3. Puxão de camisola: o defesa corre ao lado e agarra o ombro; o atacante é travado e, ao ser largado, dá um esticão (ou cai para trás, se for forte).
4. Ombro a ombro: correm lado a lado e chocam; quem perde o duelo desequilibra-se, ou cai de lado se a carga for forte e tardia.

Teclas: 1 a tua vista, 2 vista ideal, 3 atrás, 4 de perto; Espaço pausa, S abranda. No telemóvel: tocar no ecrã muda a câmara, tocar na margem direita muda de lance.

## Física

- Cada jogador tem um corpo físico (cápsulas nos ossos). Na queda o corpo passa a ser físico e tenta seguir a animação de queda (braços a amparar); o chão e os outros jogadores travam-no.
- No chão, se estiver magoado, agarra a perna tocada e balança; depois levanta-se com uma animação real (de barriga para baixo ou de costas, conforme ficou).
- Os pés e as mãos usam IK: o pé do defesa acerta no tornozelo na entrada, o pé do atacante vai à bola na condução, as mãos vão às costas no empurrão e ao ombro no puxão.
- A cadência da passada acompanha a velocidade, para os pés não deslizarem.
- Os jogadores afastam-se em vez de se atravessarem e nunca ficam abaixo da relva.
