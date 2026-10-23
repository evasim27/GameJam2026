"""Generates the hand-drawn pumpkin, kid, echo and candy, and the house textures for Be Kind, Rewind.

Usage: python3 tools/make_rewind_sprites.py [TILECRAFT_DIR NOBLE_DIR]  (from the project root)

TILECRAFT_DIR is the unzipped Tilecraft pack (https://kelano-studio.itch.io/tilecraft) and
NOBLE_DIR the unzipped Noble Interior pack (https://kelano-studio.itch.io/noble-interior).
Their licences forbid redistributing the packs as-is, so only the pieces we use are copied.
Without them, only the hand-drawn sprites are redrawn.
"""
import os
import sys

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


# The kid: a home-made Shrek costume (green tracksuit, green face paint, cardboard ears on a cap),
# an orange pillowcase for candy and a small orange lantern. 16x24, facing right.
KID_PALETTE = {
    "K": (30, 22, 30, 255),     # outline
    "G": (78, 140, 62, 255),    # tracksuit
    "g": (52, 98, 48, 255),     # tracksuit shadow
    "F": (120, 178, 80, 255),   # face paint
    "L": (160, 204, 112, 255),  # smeared paint
    "E": (16, 16, 20, 255),     # eyes
    "c": (196, 160, 108, 255),  # cardboard ears
    "O": (236, 128, 38, 255),   # pillowcase
    "o": (176, 78, 28, 255),    # pillowcase shadow
    "Y": (255, 214, 96, 255),   # lantern
}

KID_HEAD = [
    "................",
    ".ccc.......ccc..",
    "...cK.....Kc....",
    "....KKGGGGKK....",
    "...KGGGGGGGGK...",
    "...KGgGGGGGGK...",
    "...KFFFFFFFFK...",
    "...KFFFFFEFEK...",
    "...KFLFFFFFFK...",
    "...KFFFFFFKFK...",
    "....KFFFFFFK....",
    ".....KKKKKK.....",
]
KID_FRONT_HEAD = KID_HEAD[:5] + [
    "...KGgGGGGgGK...",
    "...KFFFFFFFFK...",
    "...KFEFFFFEFK...",
    "...KFLFFFFLFK...",
    "...KFFFKKFFFK...",
] + KID_HEAD[10:]
KID_BODY = [
    "....KGGGGGGK....",
    "...KGGGGGGGGK...",
    ".KKKGGGGGGGGKK..",
    "KOOKGGGGGGGGFK..",
    "KOOOKGGGGGGKKYK.",
    "KOOOOKGGGGK.KYYK",
    "KOoOOKgGGgK.KYYK",
    ".KOOK.KGGK...KK.",
]
LEGS_STAND = [
    "......KGGK......",
    "......KGKGK.....",
    ".....KKK.KKK....",
    "................",
]
LEGS_STRIDE = [
    ".....KGKKGK.....",
    "....KGK...KGK...",
    "...KKK.....KKK..",
    "................",
]
# idle, walk, idle, walk... and a last frame looking straight into the camera.
KID_FRAMES = [
    KID_HEAD + KID_BODY + LEGS_STAND,
    KID_HEAD + KID_BODY + LEGS_STRIDE,
    KID_FRONT_HEAD + KID_BODY + LEGS_STAND,
]

# The echo of a failed attempt: same silhouette, no lantern, no bag, two dark dots for eyes.
ECHO_PALETTE = {ch: (215, 245, 255, 150) for ch in "GgFLcOoY"}
ECHO_PALETTE["K"] = (120, 200, 220, 190)
ECHO_PALETTE["E"] = (10, 20, 30, 230)
ECHO_BODY = [
    "....KGGGGGGK....",
    "...KGGGGGGGGK...",
    "..KGGGGGGGGGGK..",
    "..KGKGGGGGGKGK..",
    "..KK.KGGGGK.KK..",
    ".....KGGGGK.....",
    "......KGGK......",
    ".......KK.......",
    "......K..K......",
    "................",
    "................",
    "................",
]
ECHO_FRAMES = [KID_HEAD + ECHO_BODY, KID_FRONT_HEAD + ECHO_BODY]

CANDY_PALETTE = {
    "K": (40, 20, 34, 255),
    "P": (236, 110, 160, 255),  # wrapper twists
    "W": (250, 244, 228, 255),
    "Y": (255, 200, 80, 255),
}
CANDY = [
    "..........",
    "K.KKKKKK.K",
    "KPKWYYYKPK",
    "KPKYYYYKPK",
    "K.KKKKKK.K",
    "..........",
]


def draw_sheet(frames, palette, w, h, path):
    img = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, rows in enumerate(frames):
        assert len(rows) == h, (path, i, len(rows))
        for y, row in enumerate(rows):
            assert len(row) == w, (path, i, y, row)
            for x, ch in enumerate(row):
                if ch != ".":
                    img.putpixel((i * w + x, y), palette[ch])
    img.save(path)


draw_sheet(KID_FRAMES, KID_PALETTE, 16, 24, "assets/rewind/kid.png")
draw_sheet(ECHO_FRAMES, ECHO_PALETTE, 16, 24, "assets/rewind/echo.png")
draw_sheet([CANDY], CANDY_PALETTE, 10, 6, "assets/rewind/candy.png")

if len(sys.argv) < 3:
    print("sprites written (pass the asset pack dirs to also cut the house tiles)")
    sys.exit()

tilecraft, noble = sys.argv[1], sys.argv[2]
earth_wood = Image.open(os.path.join(tilecraft, "earth_wood_14tiles_32px.png")).convert("RGBA")
stone_metal = Image.open(os.path.join(tilecraft, "stone_metal_20tiles_32px.png")).convert("RGBA")


def tile(sheet, c, r):
    return sheet.crop((c * 32, r * 32, c * 32 + 32, r * 32 + 32))


tile(earth_wood, 0, 2).save("assets/rewind/floor.png")      # creaky parquet
tile(earth_wood, 0, 0).save("assets/rewind/wall.png")       # striped wallpaper
tile(earth_wood, 3, 1).save("assets/rewind/wainscot.png")   # dark wood panelling
tile(stone_metal, 0, 0).save("assets/rewind/bricks.png")    # bricked-up doorway

os.makedirs("assets/noble_interior", exist_ok=True)
for name in ["clock_tall", "armchair_tall", "cabinet_tall", "wardrobe_small", "table_side"]:
    src = os.path.join(noble, "noble_furniture", "sprites", "purple", name + ".png")
    Image.open(src).save(os.path.join("assets/noble_interior", name + ".png"))
print("sprites written")
