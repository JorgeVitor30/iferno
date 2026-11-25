# Iferno — roguelike top-down pixel art (estilo bullet-hell / dodge roll)

- Engine: Godot 4.7.2 (Steam). Binário: `~/.steam/debian-installation/steamapps/common/Godot Engine/godot.x11.opt.tools.64`
- Rodar: `./run.sh play` | Editor: `./run.sh`
- Checar erros sem abrir janela: `"$GODOT" --headless --path . --quit-after 60`
- Resolução base 640x360, stretch `viewport` + escala inteira, filtro nearest, snap de pixel ligado. Tiles de 16px (8 de arte x2). HUD em 1x.
- GDScript com tipagem estática, tabs, comentários em português.
- Pastas: `scenes/`, `scripts/`, `assets/{sprites,tilesets,sfx,music,fonts}`.
- **Estilo visual "clean escuro 2.5D"**: paleta roxo-acinzentada escura (fundo `#0e0718`, tijolo `#473955`, piso `#3d3049`), contorno fino quase preto `#0b0612`, volume (topo claro, lado direito escuro, sombra projetada pra direita/baixo) e iluminação: `Fx.setup_lighting` (CanvasModulate escuro + luz no jogador) e `Fx.glow` (brilho + PointLight2D) em quem acende.
  - Tiles 1x detalhados: `tools/build_clean_tiles.py` → `assets/tilesets/clean/` (piso 16px com volume, parede de 48px com topo iluminado). Paredes jogam sombra no chão (`Room.draw_wall_shadow`).
  - Protagonista: SpriteCook top-down (frente/costas/lado, idle+walk), reduzido de 88 pra 48px por `tools/build_student2_sheets.py` (filtro que mantém contorno) → `assets/sprites/student2/`. A esquerda espelha a direita; diagonais usam a vista de lado.
  - Inimigos e chefe: imagem de frente do SpriteCook (`assets/sprites/enemies/`, reduzida por `tools/build_enemy_sprites.py`), animada em código em `Enemy._draw_sprite` (passo, respiração, achatamento, virar). Móveis (`prop.gd`) ainda desenhados em código, em unidades de 2px (`Fx.ART`) com contorno de 1px.
  - Não gire sprites de pixel art (borra); gire só em passos de 45°/90°.
  - Prints sem abrir janela na tela: rodar o jogo com janela escondida (`--position -20000,-20000`, `-WindowStyle Hidden`) e salvar `get_viewport().get_texture().get_image()`.
- Textos: fonte pixel própria (`tools/build_pixel_font.py` → `assets/fonts/`, montada no autoload `PixelFont`). Só fica nítida em 11 ou 22 (`Fx.SMALL`/`Fx.BIG`); `Fx.text` e `Fx.float_text` já arredondam.
- Camadas de colisão: 1 = paredes/cenário, 2 = jogador, 3 = inimigos (corpo), 4 = hurtbox dos inimigos (onde o tiro do jogador acerta).
- Andares: `scenes/floor.tscn` + `scripts/floor.gd` (geração), `room.gd` (sala, portas, ondas), `scripts/enemies/*.gd` (herdam de `enemy.gd`).
- Commits e branches: seguir `COMMITS.md` (ex.: branch `feat/inimigo-espiral`, commit `feat(enemy): ...`). `main` sempre roda.
- Lore e tema: ver `LORE.md` (faculdade; 4 estudantes presos querendo se formar; bosses = professores; armas/upgrades temáticos). Todo conteúdo novo deve seguir esse tema.
