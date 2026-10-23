"""Writes palette.png (8x4 swatch, 8px cells) and palette.hex."""
import os

from PIL import Image, ImageDraw

from palette import PALETTE, RGB

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "art")

os.makedirs(OUT, exist_ok=True)
cell, cols = 8, 8
rows = (len(PALETTE) + cols - 1) // cols
im = Image.new("RGBA", (cols * cell, rows * cell), (0, 0, 0, 0))
d = ImageDraw.Draw(im)
for i, (name, _) in enumerate(PALETTE):
    x, y = (i % cols) * cell, (i // cols) * cell
    d.rectangle([x, y, x + cell - 1, y + cell - 1], fill=RGB[name])
im.save(os.path.join(OUT, "palette.png"))
with open(os.path.join(OUT, "palette.hex"), "w") as f:
    f.write("".join(h + "\n" for _, h in PALETTE))
print(len(PALETTE), "colors")
