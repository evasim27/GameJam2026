"""Animated props. All frames transparent, outlined in k0, light from upper-left."""
from PIL import Image

from canvas import outline
from palette import RGB


def _put(p, img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        p[x, y] = RGB[c] + (255,)


# ---------------------------------------------------------------- pumpkin trap
PUMPKIN_FACE = [  # rows 14..25, '#' = carved hole
    "................................",  # 14
    ".........##..........##.........",  # 15
    "........####........####........",  # 16
    ".......######......######.......",  # 17
    "................................",  # 18
    "...............##...............",  # 19
    "..............####..............",  # 20
    "......##................##......",  # 21
    "......####...######...####......",  # 22
    ".......######..##..######.......",  # 23
    "........######....######........",  # 24
    "..........############..........",  # 25
]
PUMPKIN_SEAM = 23  # rows >= seam form the lower jaw


def pumpkin(open_px=0, glow=1):
    """32x32 carved pumpkin. open_px lifts the upper jaw (0 = closed).
    glow: 0 dim, 1 normal, 2 bright (snap)."""
    W = H = 32
    cx, cy, rx, ry = 16.0, 20.5, 13.5, 10.0
    body = {}
    for y in range(H):
        for x in range(W):
            dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            if dx * dx + dy * dy > 1:
                continue
            light = -dx * 0.7 - dy * 0.6          # upper-left key light
            gx = min(abs(x + 0.5 - g) for g in (8.5, 16.0, 23.5))
            lobe = min(gx, 3.5) / 3.5            # 0 at groove, 1 at lobe middle
            v = 1.0 + light + (lobe - 0.5) * 0.9
            if gx < 0.6:
                v -= 0.8
            c = "o1" if v < 0.8 else "o2" if v < 2.0 else "o3"
            if lobe > 0.75 and dy < -0.5 and -0.75 < dx < -0.1:
                c = "o3"
            body[(x, y)] = c
    holes = set()
    for j, row in enumerate(PUMPKIN_FACE):
        for i, ch in enumerate(row):
            if ch == "#":
                holes.add((i, 14 + j))
    g_hi = {0: "o4", 1: "o5", 2: "o5"}[glow]
    g_lo = {0: "o3", 1: "o4", 2: "o5"}[glow]
    for (x, y) in holes:
        top = (x, y - 1) not in holes
        body[(x, y)] = g_lo if top else g_hi
        if top and (x, y - 1) in body:
            body[(x, y - 1)] = "o1"  # carved lip catches shadow
    # stem + leaf
    for (x, y), c in {(15, 8): "b4", (16, 8): "b3", (15, 9): "b5", (16, 9): "b3",
                      (15, 10): "b4", (16, 10): "b2", (16, 7): "b4", (17, 7): "b3",
                      (18, 7): "g3", (19, 8): "g3", (18, 8): "g2", (14, 10): "b3",
                      (17, 10): "b2"}.items():
        body[(x, y)] = c

    def layer(keep):
        im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        p = im.load()
        for (x, y), c in body.items():
            if keep(y):
                _put(p, im, x, y, c)
        return im

    upper = layer(lambda y: y < PUMPKIN_SEAM)
    lower = layer(lambda y: y >= PUMPKIN_SEAM)
    frame = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    if open_px:
        cav = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        p = cav.load()
        top = PUMPKIN_SEAM - open_px
        for y in range(top, PUMPKIN_SEAM):
            for x in range(5, 27):
                c = "r1"
                if y == PUMPKIN_SEAM - 1 and 9 <= x <= 22:
                    c = "r2"
                _put(p, cav, x, y, c)
        frame.alpha_composite(cav)
    frame.alpha_composite(lower)
    frame.alpha_composite(upper, (0, -open_px))
    return outline(frame)
