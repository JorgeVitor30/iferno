# Gera 4 quadros de andar a partir do quadro 0 do idle: perna esquerda sobe, neutro, perna direita sobe, neutro.
import sys
from PIL import Image
src, dst = sys.argv[1], sys.argv[2]
W, H = 24, 39
LEG_TOP, SPLIT = 32, 12          # pernas começam na linha 32; esquerda = colunas < 12
base = Image.open(src).convert("RGBA").crop((0, 0, W, H))

def lift(img, left: bool):
    out = img.copy()
    x0, x1 = (0, SPLIT) if left else (SPLIT, W)
    rows = [y for y in range(LEG_TOP, H) if y not in (34, 35)]  # encurta a perna 2px = pé levantado
    for x in range(x0, x1):
        for y in range(LEG_TOP, H):
            out.putpixel((x, y), (0, 0, 0, 0))
        for i, y in enumerate(rows):
            out.putpixel((x, LEG_TOP + i), img.getpixel((x, y)))
    return out

frames = [lift(base, True), base, lift(base, False), base]
sheet = Image.new("RGBA", (W * 4, H))
for i, f in enumerate(frames):
    sheet.paste(f, (i * W, 0))
sheet.save(dst)
