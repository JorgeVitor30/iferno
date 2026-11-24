#!/usr/bin/env bash
# ./run.sh        -> abre o editor neste projeto
# ./run.sh play   -> roda o jogo direto
GODOT="$HOME/.steam/debian-installation/steamapps/common/Godot Engine/godot.x11.opt.tools.64"
cd "$(dirname "$0")"
if [ "$1" = "play" ]; then exec "$GODOT" --path . ; else exec "$GODOT" --editor --path . ; fi
