"""Gera os tiles do estilo "clean escuro" (piso de lajota e parede de tijolo).

Estilo: pixel GROSSO (cada pixel da arte vira 2x2 na tela: o jogo desenha esses
tiles com escala 2), poucos tons, formas limpas, paleta roxo-acinzentada escura
tirada da referência. Sem textura pontilhada.

Saída (assets/tilesets/clean/), em pixels de arte (metade do tamanho na tela):
  floor.png    32x32  (4x4 lajotas de 8 -> 16px na tela)
  outdoor.png  32x32  (calçada da frente da faculdade, à noite)
  wall.png     16x16  (face da parede de cima -> 32x32 na tela)

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


def floor_tiles(base: str, light: str, dark: str, grout: str, seed: int) -> Image.Image:
    rnd = random.Random(seed)
    im = Image.new("RGBA", (32, 32), hexc(grout))
    for ty in range(4):
        for tx in range(4):
            x0, y0 = tx * 8, ty * 8
            b = hexc(base) if rnd.random() < 0.75 else hexc(dark)
            for y in range(7):
                for x in range(7):
                    im.putpixel((x0 + x, y0 + y), b)
            for x in range(7):
                im.putpixel((x0 + x, y0), hexc(light))
            for y in range(1, 7):
                im.putpixel((x0, y0 + y), hexc(light))
            # um detalhe só de vez em quando (lasquinha)
            if rnd.random() < 0.18:
                im.putpixel((x0 + rnd.randint(2, 5), y0 + rnd.randint(2, 5)), hexc(grout))
    return im


def wall() -> Image.Image:
    brick, brick_l, mortar = hexc("#473955"), hexc("#56476b"), hexc("#30233e")
    low, low_d, rim = hexc("#332741"), hexc("#261c31"), hexc("#64547a")
    im = Image.new("RGBA", (16, 16), mortar)
    for x in range(16):
        im.putpixel((x, 0), rim)
    # 2 fileiras de tijolos (3 de altura + 1 de rejunte), desencontradas
    for row, y in enumerate((1, 5)):
        off = 0 if row == 0 else 4
        for x in range(16):
            if (x + off) % 8 == 7:
                continue
            for yy in range(3):
                im.putpixel((x, y + yy), brick_l if yy == 0 else brick)
    # rodapé escuro e a linha onde encosta no chão
    for y in range(9, 16):
        for x in range(16):
            im.putpixel((x, y), low if y < 15 else low_d)
    for x in range(16):
        im.putpixel((x, 9), mortar)
    return im


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    floor_tiles("#3d3049", "#4a3d59", "#352a42", "#2b243b", 7).save(OUT / "floor.png")
    floor_tiles("#2c3140", "#384052", "#262a36", "#1d2029", 11).save(OUT / "outdoor.png")
    wall().save(OUT / "wall.png")
    print("tiles gerados em", OUT)


if __name__ == "__main__":
    main()
