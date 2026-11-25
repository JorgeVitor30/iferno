# Iferno — roguelike top-down pixel art (estilo bullet-hell / dodge roll)

- Engine: Godot 4.7.2 (Steam). Binário: `~/.steam/debian-installation/steamapps/common/Godot Engine/godot.x11.opt.tools.64`
- Rodar: `./run.sh play` | Editor: `./run.sh`
- Checar erros sem abrir janela: `"$GODOT" --headless --path . --quit-after 60`
- Resolução base 640x360, stretch `viewport` + escala inteira, filtro nearest, snap de pixel ligado. Tiles de 16px (8 de arte x2). HUD em 1x.
- GDScript com tipagem estática, tabs, comentários em português.
- Pastas: `scenes/`, `scripts/`, `assets/{sprites,tilesets,sfx,music,fonts}`.
- **Estilo visual "clean escuro"** (referência do usuário): pixel GROSSO — a arte do mundo é desenhada em unidades de 2px (`Fx.ART`), poucos tons por objeto, contorno quase preto `#0b0612`, luz em cima e sombra embaixo, sem pontilhado. Paleta roxo-acinzentada escura: fundo `#0e0718`, topo de parede `#150b1f`, tijolo `#473955`, piso `#3d3049` com rejunte `#2b243b`. Coisas que acendem ganham `Fx.glow` (brilho em anéis).
  - Tiles: `tools/build_clean_tiles.py` → `assets/tilesets/clean/` (desenhados com escala 2 via `Fx.tiled`). Face da parede de cima = 32px.
  - Bonecos chibi (cabeça grande, ~14 unidades = 28px): jogador em `player_body.gd`, inimigos no molde `draw_person` de `enemy.gd` (pincéis `ob/fb/bb` em unidades de arte). Móveis em `prop.gd`.
  - Os sprites antigos do SpriteCook continuam em `assets/` mas não são mais usados. Não gire sprites de pixel art (borra); gire só em passos de 45°/90°.
  - Prints sem abrir janela na tela: rodar o jogo com janela escondida (`--position -20000,-20000`, `-WindowStyle Hidden`) e salvar `get_viewport().get_texture().get_image()`.
- Textos: fonte pixel própria (`tools/build_pixel_font.py` → `assets/fonts/`, montada no autoload `PixelFont`). Só fica nítida em 11 ou 22 (`Fx.SMALL`/`Fx.BIG`); `Fx.text` e `Fx.float_text` já arredondam.
- Camadas de colisão: 1 = paredes/cenário, 2 = jogador, 3 = inimigos (corpo), 4 = hurtbox dos inimigos (onde o tiro do jogador acerta).
- Andares: `scenes/floor.tscn` + `scripts/floor.gd` (geração), `room.gd` (sala, portas, ondas), `scripts/enemies/*.gd` (herdam de `enemy.gd`).
- Commits e branches: seguir `COMMITS.md` (ex.: branch `feat/inimigo-espiral`, commit `feat(enemy): ...`). `main` sempre roda.
- Lore e tema: ver `LORE.md` (faculdade; 4 estudantes presos querendo se formar; bosses = professores; armas/upgrades temáticos). Todo conteúdo novo deve seguir esse tema.
