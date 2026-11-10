#!/bin/bash
# Publica uma versão nova: numera, exporta web e computador, faz commit e push.
# uso: GODOT=/caminho/para/godot bash godot/publicar.sh "mensagem do commit"
# Precisa do Godot 4.4.1 e dos modelos de exportação (Web, Windows, Linux).
# ZIPS=pasta onde ficam os zips de computador (por omissão /mnt/project-files/arbitro-caricas/computador).
set -e
MSG=${1:?falta a mensagem do commit}
G=${GODOT:-godot}
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
P="$RAIZ/godot/projeto"
ZIPS=${ZIPS:-/mnt/project-files/arbitro-caricas/computador}

# 1. número da versão (o anterior mais um) e hora de Lisboa
ANT=$(grep -oE 'TXT := "[0-9]+' "$P/scripts/versao.gd" | grep -oE '[0-9]+$')
N=$((ANT + 1))
HORA=$(TZ=Europe/Lisbon date +'%d/%m %H:%M')
cat > "$P/scripts/versao.gd" <<EOF
extends RefCounted
# gerado pelo publicar.sh: número da publicação e hora de Lisboa
const TXT := "$N · $HORA"
EOF

# 2. web
GODOT="$G" bash "$RAIZ/godot/exportar.sh"

# 3. computador (não vai para o git)
cd "$P"
mkdir -p ../desk/win ../desk/linux
$G --headless --export-release "Windows" ../desk/win/ArbitroDeCaricas.exe
$G --headless --export-release "Linux" ../desk/linux/ArbitroDeCaricas.x86_64
if [ -d "$ZIPS" ]; then
  (cd ../desk/win && zip -qr "$ZIPS/ArbitroDeCaricas-Windows.zip" .)
  (cd ../desk/linux && zip -qr "$ZIPS/ArbitroDeCaricas-Linux.zip" .)
fi

# 4. commit e push
cd "$RAIZ"
git add -A
git commit -q -m "$MSG"
git push -u origin main
echo "Publicada a versão $N ($HORA)"
