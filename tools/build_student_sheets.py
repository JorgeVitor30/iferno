"""Prepara as animações do estudante para o jogo.

Lê as folhas brutas do SpriteCook (tiras horizontais de quadros), reduz pela
metade com NEAREST (pixel nítido) e coloca cada quadro numa célula de tamanho
fixo, com o pé na linha de baixo e o corpo centralizado. Assim todas as
direções trocam entre si sem o boneco "pular".

Uso: python3 tools/build_student_sheets.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets/sprites/raw"
OUT = ROOT / "assets/sprites/student"
CELL_W, CELL_H = 32, 44
SCALE = 0.5

# nome da animação -> (arquivo bruto, nº de quadros)
SHEETS = {
    "idle_s": ("idle_s.png", 8),
    "walk_s": ("walk_s.png", 8),
    "idle_e": ("idle_e.png", 8),
    "walk_e": ("walk_e.png", 8),
    "idle_n": ("idle_n.png", 8),
    "walk_n": ("walk_n.png", 8),
    "idle_se": ("idle_se.png", 8),
    "walk_se": ("walk_se.png", 8),
    "idle_ne": ("idle_ne.png", 8),
    "walk_ne": ("walk_ne.png", 8),
}


def build(name: str, file: str, count: int) -> None:
    sheet = Image.open(RAW / file).convert("RGBA")
    fw = sheet.width // count
    frames = [sheet.crop((i * fw, 0, (i + 1) * fw, sheet.height)) for i in range(count)]
    # caixa que cobre o boneco em todos os quadros (preserva o movimento dentro da animação)
    boxes = [f.getbbox() for f in frames if f.getbbox()]
    x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
    x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
    w = max(1, round((x1 - x0) * SCALE)); h = max(1, round((y1 - y0) * SCALE))
    if w > CELL_W or h > CELL_H:
        raise SystemExit(f"{name}: {w}x{h} não cabe na célula {CELL_W}x{CELL_H}")
    out = Image.new("RGBA", (CELL_W * count, CELL_H))
    for i, f in enumerate(frames):
        small = f.crop((x0, y0, x1, y1)).resize((w, h), Image.NEAREST)
        out.paste(small, (i * CELL_W + (CELL_W - w) // 2, CELL_H - h))
    out.save(OUT / f"{name}.png")
    print(f"{name}: {count} quadros, boneco {w}x{h}")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (file, count) in SHEETS.items():
        if (RAW / file).exists():
            build(name, file, count)
        else:
            print(f"{name}: falta {file}")
