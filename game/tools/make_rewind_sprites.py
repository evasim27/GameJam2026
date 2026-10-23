"""Generates the hand-drawn pumpkin and the tiling textures for Be Kind, Rewind.

Usage: python3 tools/make_rewind_sprites.py  (from the project root)
"""
from PIL import Image

PALETTE = {
    "K": (63, 38, 49, 255),     # outline (matches Kenney Tiny Dungeon)
    "D": (176, 78, 28, 255),    # dark orange
    "O": (236, 128, 38, 255),   # orange
    "L": (255, 178, 82, 255),   # highlight
    "G": (70, 130, 60, 255),    # stem
    "Y": (255, 224, 96, 255),   # candle glow
    "W": (250, 244, 228, 255),  # teeth
    "R": (120, 24, 36, 255),    # mouth
}

IDLE = [
    "................",
    "......KKK.......",
    "......KGK.......",
    "...KKKKGKKKKK...",
    "..KOOODOLDOOOK..",
    ".KOOLODOODOOOOK.",
    ".KOYYODOODOYYOK.",
    ".KOYYODOODOYYOK.",
    ".KOOOODOODOOOOK.",
    ".KOYOYOYYOYOYOK.",
    ".KOYYYYYYYYYYOK.",
    ".KOOYYOYYOYYOOK.",
    "..KOOODOODOOOK..",
    "...KKKKKKKKKK...",
    "................",
    "................",
]

BITE = [
    "......KKK.......",
    "......KGK.......",
    "...KKKKGKKKKK...",
    "..KOOODOLDOOOK..",
    ".KOYYODOODOYYOK.",
    ".KOYYODOODOYYOK.",
    ".KOOOODOODOOOOK.",
    ".KYWYWYWYWYWYWK.",
    ".KYYYYYYYYYYYYK.",
    ".KYYRRRRRRRRYYK.",
    ".KYYRRRRRRRRYYK.",
    ".KYYYYYYYYYYYYK.",
    ".KYWYWYWYWYWYWK.",
    ".KOOOOOOOOOOOOK.",
    "..KOOODOODOOOK..",
    "...KKKKKKKKKK...",
]


def draw(rows, img, ox):
    for y, row in enumerate(rows):
        assert len(row) == 16, (y, row)
        for x, ch in enumerate(row):
            if ch != ".":
                img.putpixel((ox + x, y), PALETTE[ch])


pumpkin = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
draw(IDLE, pumpkin, 0)
draw(BITE, pumpkin, 16)
pumpkin.save("assets/rewind/pumpkin.png")

sheet = Image.open("assets/kenney_tiny_dungeon/tilemap_packed.png").convert("RGBA")


def tile(c, r):
    return sheet.crop((c * 16, r * 16, c * 16 + 16, r * 16 + 16))


tile(1, 3).save("assets/rewind/floor.png")
tile(9, 4).save("assets/rewind/wall.png")
print("sprites written")
