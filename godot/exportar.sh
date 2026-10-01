#!/bin/bash
# exporta o projeto Godot 4.3 para jogar-godot/ (precisa do Godot 4.3 e dos modelos de exportação Web)
# uso: GODOT=/caminho/para/godot bash godot/exportar.sh
set -e
cd "$(dirname "$0")/projeto"
G=${GODOT:-godot}
OUT=../../jogar-godot
$G --headless --import >/dev/null 2>&1 || true
$G --headless --export-release "Web" /tmp/arbitro-web/index.html
mkdir -p $OUT
cp /tmp/arbitro-web/index.js /tmp/arbitro-web/index.audio.worklet.js /tmp/arbitro-web/index.pck /tmp/arbitro-web/index.png $OUT/
gzip -9c /tmp/arbitro-web/index.wasm > $OUT/index.wasm.gz
echo "Atenção: o index.html de jogar-godot tem um pequeno ajuste que descomprime o index.wasm.gz; não o substituas pelo da exportação."
