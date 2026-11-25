"""Gera os tiles do estilo "clean escuro 2.5D" (piso de lajota e parede alta de tijolo).

Pixel nítido (1x, sem ampliar), paleta roxo-acinzentada escura da referência,
volume nas lajotas (quina clara em cima/esquerda, sombra embaixo) e parede alta
com topo iluminado, tijolos com variação de tom e rodapé — dá profundidade.

Saída (assets/tilesets/clean/):
  floor.png    64x64  (4x4 lajotas de 16px)
  outdoor.png  64x64  (calçada da frente da faculdade, à noite)
  wall.png     32x48  (face da parede de cima)

Uso: python3 tools/build_clean_tiles.py
"""
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets/tilesets/clean"


def hexc(h: str) -> tuple:
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def shade(c: tuple, k: float) -> tuple:
    return tuple(max(0, min(255, int(v * k))) for v in c[:3]) + (255,)


def floor_tiles(base: str, grout: str, seed: int) -> Image.Image:
    rnd = random.Random(seed)
    g = hexc(grout)
    im = Image.new("RGBA", (64, 64), g)
    for ty in range(4):
        for tx in range(4):
            x0, y0 = tx * 16, ty * 16
            b = shade(hexc(base), rnd.choice([1.0, 1.0, 0.94, 1.05]))
            light, mid_l, dark = shade(b, 1.22), shade(b, 1.1), shade(b, 0.8)
            for y in range(15):
                for x in range(15):
                    c = b
                    if y == 0 or x == 0:
                        c = light            # quina pegando luz
                    elif y == 1 or x == 1:
                        c = mid_l
                    elif y >= 13 or x >= 13:
                        c = dark             # lado de baixo/direita mais escuro (volume)
                    im.putpixel((x0 + x, y0 + y), c)
            # textura sutil de pedra (poucos pontos, sem virar ruído)
            for _ in range(rnd.randint(2, 5)):
                im.putpixel((x0 + rnd.randint(3, 11), y0 + rnd.randint(3, 11)), shade(b, rnd.choice([0.9, 1.08])))
            if rnd.random() < 0.2:  # rachadura
                x, y = x0 + rnd.randint(3, 8), y0 + rnd.randint(3, 6)
                for _ in range(rnd.randint(3, 6)):
                    im.putpixel((x, y), shade(b, 0.72))
                    x += rnd.choice([0, 1, 1])
                    y += 1
    return im


def wall() -> Image.Image:
    W, H = 32, 48
    rnd = random.Random(3)
    brick = hexc("#473955")
    mortar = hexc("#2c2039")
    im = Image.new("RGBA", (W, H), mortar)
    # topo da parede (a "espessura" vista de cima, bem iluminada)
    for x in range(W):
        im.putpixel((x, 0), hexc("#7a6a92"))
        im.putpixel((x, 1), hexc("#6a5a80"))
        im.putpixel((x, 2), hexc("#56476b"))
        im.putpixel((x, 3), hexc("#30233e"))
    # tijolos: 4 fileiras de 7px + 1 de rejunte, desencontradas
    y = 4
    row = 0
    while y + 7 <= 36:
        off = 0 if row % 2 == 0 else 8
        bx = -off
        while bx < W:
            k = rnd.choice([0.92, 1.0, 1.0, 1.08])
            c = shade(brick, k)
            for yy in range(7):
                for xx in range(15):
                    x = bx + xx
                    if 0 <= x < W:
                        col = c
                        if yy == 0:
                            col = shade(c, 1.2)
                        elif yy == 6:
                            col = shade(c, 0.78)
                        elif xx == 0:
                            col = shade(c, 1.1)
                        im.putpixel((x, y + yy), col)
            bx += 16
        y += 8
        row += 1
    # rodapé: frisinho claro e faixa escura, mais a linha de contato com o chão
    for x in range(W):
        im.putpixel((x, 36), hexc("#56476b"))
        for yy in range(37, H):
            im.putpixel((x, yy), hexc("#2f2440") if yy < H - 2 else hexc("#1e1629"))
        im.putpixel((x, 37), hexc("#3a2e4c"))
    return im


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    floor_tiles("#3d3049", "#251e33", 7).save(OUT / "floor.png")
    floor_tiles("#2c3140", "#1a1d26", 11).save(OUT / "outdoor.png")
    wall().save(OUT / "wall.png")
    print("tiles gerados em", OUT)


if __name__ == "__main__":
    main()
