"""Prepara os objetos de cenário: recorta o espaço vazio e aplica a escala.

Escala só 1x ou 0.5x (NEAREST), para o pixel não borrar. Os objetos grandes
(ônibus, árvore, mesa) ficam em 1x para manter o tamanho certo em relação ao
estudante (39px de altura).

Uso: python3 tools/build_props.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets/props/raw"
OUT = ROOT / "assets/props"

PROPS = {  # nome: escala
    "bus": 1.0,
    "tree": 1.0,
    "table": 1.0,
    "fence": 1.0,
    "bench": 0.5,
    "trash": 0.5,
    "lamp": 0.5,
}

for name, scale in PROPS.items():
    im = Image.open(RAW / f"{name}.png").convert("RGBA")
    im = im.crop(im.getbbox())
    if scale != 1.0:
        im = im.resize((round(im.width * scale), round(im.height * scale)), Image.NEAREST)
    im.save(OUT / f"{name}.png")
    print(f"{name}: {im.width}x{im.height}")
