"""Reduz as imagens dos inimigos (SpriteCook) pro tamanho do jogo, sem borrar.

Cada imagem vem num tamanho diferente. Pra cada uma escolhe um fator inteiro k
e troca cada bloco k x k pela cor mais frequente do bloco (o contorno escuro
ganha nas bordas), igual ao filtro do protagonista. Recorta e salva.

Entrada: assets/sprites/enemies/raw/<nome>.png
Saída:   assets/sprites/enemies/<nome>.png

Uso: python3 tools/build_enemy_sprites.py
"""
from collections import Counter
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets/sprites/enemies/raw"
OUT = ROOT / "assets/sprites/enemies"

# nome -> altura desejada no jogo (px). O protagonista tem ~42; inimigos um pouco maiores.
TARGET = {
    "zelador": 52,
    "veterano": 52,
    "professor": 54,
    "estagiario": 52,
    "coordenadora": 56,
    "prof_estatistica": 84,  # chefe: o dobro do estudante
}


def lum(p: tuple) -> float:
    return 0.3 * p[0] + 0.59 * p[1] + 0.11 * p[2]


def reduce(im: Image.Image, k: int) -> Image.Image:
    if k <= 1:
        return im
    w, h = im.width // k, im.height // k
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src = im.load()
    for y in range(h):
        for x in range(w):
            block = [src[x * k + dx, y * k + dy] for dy in range(k) for dx in range(k)]
            solid = [p for p in block if p[3] >= 128]
            if len(solid) < (k * k) / 2:
                continue
            dark = [p for p in solid if lum(p) < 40]
            if dark and len(solid) < k * k:
                out.putpixel((x, y), min(dark, key=lum)[:3] + (255,))
                continue
            c = Counter(p[:3] for p in solid).most_common()
            best = c[0][0]
            if len(c) > 1 and c[0][1] == c[1][1]:
                best = min((c[0][0], c[1][0]), key=lambda q: lum(q + (255,)))
            out.putpixel((x, y), best + (255,))
    return out


def reduce_to(im: Image.Image, target_h: int) -> Image.Image:
    """Reduz pra qualquer proporção: cada pixel de saída pega a cor mais frequente
    da área correspondente na imagem original (contorno escuro ganha nas bordas)."""
    s = im.height / target_h
    w, h = max(1, round(im.width / s)), target_h
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    src = im.load()
    for y in range(h):
        y0, y1 = int(y * s), max(int(y * s) + 1, int((y + 1) * s))
        for x in range(w):
            x0, x1 = int(x * s), max(int(x * s) + 1, int((x + 1) * s))
            block = [src[min(xx, im.width - 1), min(yy, im.height - 1)] for yy in range(y0, y1) for xx in range(x0, x1)]
            solid = [p for p in block if p[3] >= 128]
            if len(solid) * 2 < len(block):
                continue
            dark = [p for p in solid if lum(p) < 40]
            if dark and len(solid) < len(block):
                out.putpixel((x, y), min(dark, key=lum)[:3] + (255,))
                continue
            c = Counter(p[:3] for p in solid).most_common()
            best = c[0][0]
            if len(c) > 1 and c[0][1] == c[1][1]:
                best = min((c[0][0], c[1][0]), key=lambda q: lum(q + (255,)))
            out.putpixel((x, y), best + (255,))
    return out


def main() -> None:
    for name, target in TARGET.items():
        im = Image.open(RAW / f"{name}.png").convert("RGBA")
        im = im.crop(im.getbbox())
        # fator inteiro quando dá certinho (mais nítido), senão proporção livre
        k = max(1, round(im.height / target))
        if abs(im.height / k - target) <= 3:
            small = reduce(im, k)
        else:
            small = reduce_to(im, target)
        small = small.crop(small.getbbox())
        small.save(OUT / f"{name}.png")
        print(f"{name}: {small.width}x{small.height}")


if __name__ == "__main__":
    main()
