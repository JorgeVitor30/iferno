# Iferno — roguelike top-down pixel art (estilo bullet-hell / dodge roll)

- Engine: Godot 4.7.2 (Steam). Binário: `~/.steam/debian-installation/steamapps/common/Godot Engine/godot.x11.opt.tools.64`
- Rodar: `./run.sh play` | Editor: `./run.sh`
- Checar erros sem abrir janela: `"$GODOT" --headless --path . --quit-after 60`
- Resolução base 480x270, stretch `viewport` + escala inteira, filtro nearest, snap de pixel ligado. Sprites em múltiplos de 16px.
- GDScript com tipagem estática, tabs, comentários em português.
- Pastas: `scenes/`, `scripts/`, `assets/{sprites,tilesets,sfx,music,fonts}`.
- Placeholders são desenhados com `_draw()` até existirem sprites.
