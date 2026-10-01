# Árbitro de Caricas em Godot 4 (em curso)

O jogo está a passar do browser (Three.js) para o Godot 4.3. Esta pasta tem o primeiro passo: um lance 3D (falta para amarelo) no estádio, com o mesmo corpo MakeHuman e as mesmas animações CMU da versão browser.

- `projeto/`: projeto Godot (abre o `project.godot` no editor Godot 4.3).
- `make_glb.py`: converte o corpo MakeHuman e as animações (`src/../mh`, `anims.json`) no `projeto/assets/jogador.glb`.
- `exportar.sh`: exporta para a web, para a pasta `jogar-godot/`.

Para jogar no browser: com o GitHub Pages ligado, abre `.../arbitro-de-caricas/jogar-godot/`.

Teclas: 1 a tua vista, 2 vista ideal, 3 atrás, 4 de perto; Espaço pausa, S abranda, R repete; clique muda a câmara.

Física: cada jogador tem um corpo físico (cápsulas nos ossos). Na queda o corpo passa a ser físico (ragdoll) e tenta seguir a animação de queda (braços a amparar), com o chão e os outros jogadores como obstáculos. Os jogadores animados afastam-se uns dos outros e nunca ficam abaixo da relva.

Nota: a versão web do Godot usa o renderizador Compatibility (WebGL 2). As versões para computador (Windows, Mac, Linux) usam o Forward+, com mais qualidade de luz e sombras.
