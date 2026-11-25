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

# nome -> altura desejada no jogo (px). O protagonista tem ~42.
TARGET = {
    "zelador": 40,
    "veterano": 40,
    "professor": 42,
    "estagiario": 40,
    "coordenadora": 44,
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


def main() -> None:
    for name, target in TARGET.items():
        im = Image.open(RAW / f"{name}.png").convert("RGBA")
        im = im.crop(im.getbbox())
        k = max(1, round(im.height / target))
        small = reduce(im, k)
        small = small.crop(small.getbbox())
        small.save(OUT / f"{name}.png")
        print(f"{name}: fator {k}, {small.width}x{small.height}")


if __name__ == "__main__":
    main()
