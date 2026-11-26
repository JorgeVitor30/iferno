"""Prepara os objetos de cenário com cara de 3D (SpriteCook / Pixel Engine).

1. Às vezes a imagem vem com mais de um objeto: fica só com o maior pedaço
   (componente conectado) e o que encosta nele.
2. Usa em 1x (o Pixel Engine já desenha no tamanho final, na mesma densidade do
   protagonista). Só a pilha de papel é reduzida pela metade (filtro de pixel art).
   A versão "reta, de frente" (raw2/) tem prioridade sobre a diagonal (raw/).

Entrada: assets/props/clean/raw2/<nome>.png ou assets/props/clean/raw/<nome>.png
Saída:   assets/props/clean/<nome>.png  (+ imprime o tamanho final de cada um)

Uso: python3 tools/build_clean_props.py
"""
from collections import Counter
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets/props/clean/raw"
RAW2 = ROOT / "assets/props/clean/raw2"
OUT = ROOT / "assets/props/clean"
HALF = {"pilha_papel"}


def lum(p: tuple) -> float:
    return 0.3 * p[0] + 0.59 * p[1] + 0.11 * p[2]


def main_object(im: Image.Image) -> Image.Image:
    """Mantém o maior componente conectado (alfa > 0) e o que estiver dentro da caixa dele."""
    w, h = im.size
    a = im.load()
    seen = [[False] * w for _ in range(h)]
    comps = []
    for y in range(h):
        for x in range(w):
            if seen[y][x] or a[x, y][3] == 0:
                continue
            stack = [(x, y)]
            seen[y][x] = True
            pts = []
            while stack:
                cx, cy = stack.pop()
                pts.append((cx, cy))
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < w and 0 <= ny < h and not seen[ny][nx] and a[nx, ny][3] > 0:
                        seen[ny][nx] = True
                        stack.append((nx, ny))
            comps.append(pts)
    if len(comps) <= 1:
        return im
    big = max(comps, key=len)
    x0 = min(p[0] for p in big); x1 = max(p[0] for p in big)
    y0 = min(p[1] for p in big); y1 = max(p[1] for p in big)
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    for c in comps:
        inside = sum(1 for (px, py) in c if x0 - 2 <= px <= x1 + 2 and y0 - 2 <= py <= y1 + 2)
        if c is big or inside > len(c) * 0.6:
            for p in c:
                out.putpixel(p, a[p[0], p[1]])
    return out


def half(im: Image.Image) -> Image.Image:
    w, h = (im.width + 1) // 2, (im.height + 1) // 2
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src = im.load()
    for y in range(h):
        for x in range(w):
            block = [src[min(x * 2 + dx, im.width - 1), min(y * 2 + dy, im.height - 1)] for dy in (0, 1) for dx in (0, 1)]
            solid = [p for p in block if p[3] >= 128]
            if len(solid) < 2:
                continue
            dark = [p for p in solid if lum(p) < 40]
            if dark and len(solid) < 4:
                out.putpixel((x, y), min(dark, key=lum)[:3] + (255,))
                continue
            c = Counter(p[:3] for p in solid).most_common()
            best = c[0][0]
            if len(c) > 1 and c[0][1] == c[1][1]:
                best = min((c[0][0], c[1][0]), key=lambda q: lum(q + (255,)))
            out.putpixel((x, y), best + (255,))
    return out


def main() -> None:
    names = sorted({f.stem for f in RAW.glob("*.png")} | {f.stem for f in RAW2.glob("*.png")})
    for name in names:
        f = RAW2 / f"{name}.png"
        if not f.exists():
            f = RAW / f"{name}.png"
        im = Image.open(f).convert("RGBA")
        im = main_object(im)
        im = im.crop(im.getbbox())
        if f.stem in HALF:
            im = half(im)
            im = im.crop(im.getbbox())
        im.save(OUT / f.name)
        print(f'"{f.stem}": Vector2({im.width}, {im.height}),')


if __name__ == "__main__":
    main()
