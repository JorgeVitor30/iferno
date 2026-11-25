"""Prepara as animações do estudante novo (SpriteCook, top-down, 88px por quadro).

Reduz pela metade com um filtro próprio de pixel art: cada bloco 2x2 vira o pixel
da cor mais frequente do bloco; se o bloco tem contorno escuro, o contorno ganha
(assim o boneco não perde a linha de fora nem fica "borrado"). Depois recorta,
alinha o pé na base e salva em células fixas de 48x48.

Entrada: assets/sprites/student2/raw/{idle,walk}_{s,n,e}.png (tiras de 8 quadros)
Saída:   assets/sprites/student2/{idle,walk}_{s,n,e}.png

Uso: python3 tools/build_student2_sheets.py
"""
from collections import Counter
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets/sprites/student2/raw"
OUT = ROOT / "assets/sprites/student2"
CELL = 48
FRAMES = 8


def lum(p: tuple) -> float:
    return 0.3 * p[0] + 0.59 * p[1] + 0.11 * p[2]


def half(im: Image.Image) -> Image.Image:
    w, h = im.width // 2, im.height // 2
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src = im.load()
    for y in range(h):
        for x in range(w):
            block = [src[x * 2 + dx, y * 2 + dy] for dy in (0, 1) for dx in (0, 1)]
            solid = [p for p in block if p[3] >= 128]
            if len(solid) < 2:
                continue
            dark = [p for p in solid if lum(p) < 40]
            if dark and len(solid) < 4:
                out.putpixel((x, y), min(dark, key=lum)[:3] + (255,))  # borda: mantém o contorno
                continue
            c = Counter(p[:3] for p in solid).most_common()
            best = c[0][0]
            if len(c) > 1 and c[0][1] == c[1][1]:
                best = min((c[0][0], c[1][0]), key=lambda q: lum(q + (255,)))
            out.putpixel((x, y), best + (255,))
    return out


def build(name: str) -> None:
    sheet = Image.open(RAW / f"{name}.png").convert("RGBA")
    fw = sheet.width // FRAMES
    frames = [half(sheet.crop((i * fw, 0, (i + 1) * fw, sheet.height))) for i in range(FRAMES)]
    boxes = [f.getbbox() for f in frames if f.getbbox()]
    x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
    x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
    w, h = x1 - x0, y1 - y0
    out = Image.new("RGBA", (CELL * FRAMES, CELL))
    for i, f in enumerate(frames):
        out.paste(f.crop((x0, y0, x1, y1)), (i * CELL + (CELL - w) // 2, CELL - h))
    out.save(OUT / f"{name}.png")
    print(f"{name}: boneco {w}x{h}")


if __name__ == "__main__":
    for kind in ("idle", "walk"):
        for view in ("s", "n", "e"):
            build(f"{kind}_{view}")
