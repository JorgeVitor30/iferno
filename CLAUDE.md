# Iferno — roguelike top-down pixel art (estilo bullet-hell / dodge roll)

- Engine: Godot 4.7.2 (Steam). Binário: `~/.steam/debian-installation/steamapps/common/Godot Engine/godot.x11.opt.tools.64`
- Rodar: `./run.sh play` | Editor: `./run.sh`
- Checar erros sem abrir janela: `"$GODOT" --headless --path . --quit-after 60`
- Resolução base 640x360, stretch `viewport` + escala inteira, filtro nearest, snap de pixel ligado. Sprites em múltiplos de 16px.
- GDScript com tipagem estática, tabs, comentários em português.
- Pastas: `scenes/`, `scripts/`, `assets/{sprites,tilesets,sfx,music,fonts}`.
- Placeholders são desenhados com `_draw()` até existirem sprites.
- Camadas de colisão: 1 = paredes/cenário, 2 = jogador, 3 = inimigos (corpo), 4 = hurtbox dos inimigos (onde o tiro do jogador acerta).
- Andares: `scenes/floor.tscn` + `scripts/floor.gd` (geração), `room.gd` (sala, portas, ondas), `scripts/enemies/*.gd` (herdam de `enemy.gd`).
- Commits e branches: seguir `COMMITS.md` (ex.: branch `feat/inimigo-espiral`, commit `feat(enemy): ...`). `main` sempre roda.
- Lore e tema: ver `LORE.md` (faculdade; 4 estudantes presos querendo se formar; bosses = professores; armas/upgrades temáticos). Todo conteúdo novo deve seguir esse tema.
