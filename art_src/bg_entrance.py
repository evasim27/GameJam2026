"""Entrance hall, 480x270, three parallax layers.

layer0  night sky seen through the window (opaque, slow scroll)
layer1  the room: wall, door, window frame (glass cut out), furniture, floor
layer2  foreground silhouettes (transparent, fast scroll)

Gameplay plane: floor surface y=196..227, child's feet at y~218.
"""
import random

from PIL import Image, ImageDraw

from canvas import LitCanvas, upscale
from palette import RGB

W, H = 480, 270
FLOOR_TOP, FLOOR_FRONT = 196, 228
WIN = (140, 40, 196, 140)  # window glass box x0,y0,x1,y1


# -------------------------------------------------------------- layer 0 (sky)
def layer0():
    im = Image.new("RGBA", (W, H), RGB["p1"] + (255,))
    d = ImageDraw.Draw(im)
    # sky bands (hard steps, no smooth gradient)
    bands = [(0, "n1"), (40, "p1"), (110, "p2")]
    for y0, c in bands:
        d.rectangle([0, y0, W, H], fill=RGB[c])
    # dither seam between bands, 2px checker
    p = im.load()
    for y0, c_above in ((40, "n1"), (110, "p1")):
        for x in range(W):
            for dy in (0, 1):
                if (x + dy) % 2 == 0:
                    p[x, y0 + dy] = RGB[c_above] + (255,)
    # moon
    mx, my, r = 178, 62, 11
    for y in range(my - r, my + r + 1):
        for x in range(mx - r, mx + r + 1):
            dd = (x - mx) ** 2 + (y - my) ** 2
            if dd <= r * r:
                c = "w"
                if (x - mx + 4) ** 2 + (y - my - 3) ** 2 <= 8 or (x - mx - 3) ** 2 + (y - my + 4) ** 2 <= 3:
                    c = "n6"
                if dd > (r - 1) ** 2 and x > mx:
                    c = "n6"
                p[x, y] = RGB[c] + (255,)
    rnd = random.Random(7)
    for _ in range(70):
        x, y = rnd.randrange(W), rnd.randrange(0, 100)
        p[x, y] = RGB[rnd.choice(["n5", "n6", "p3"])] + (255,)
    # neighbour rooftops + bare tree
    d.polygon([(100, 150), (130, 122), (160, 150)], fill=RGB["k0"])
    d.rectangle([108, 150, 152, H], fill=RGB["k0"])
    d.rectangle([126, 108, 131, 128], fill=RGB["k0"])  # chimney
    d.rectangle([136, 158, 139, 162], fill=RGB["o4"])  # one lit window far away
    d.polygon([(186, 160), (220, 128), (262, 160)], fill=RGB["n1"])
    d.rectangle([194, 160, 254, H], fill=RGB["n1"])
    d.rectangle([0, 172, W, H], fill=RGB["k0"])
    trunk_x = 205
    d.rectangle([trunk_x, 90, trunk_x + 3, 172], fill=RGB["k0"])
    for (x0, y0, x1, y1) in [(trunk_x, 120, 160, 88), (trunk_x + 2, 104, 240, 70),
                             (trunk_x + 1, 96, 196, 40), (180, 104, 150, 92),
                             (222, 86, 232, 60), (trunk_x + 2, 140, 238, 126),
                             (172, 97, 168, 78), (226, 80, 250, 84)]:
        d.line([(x0, y0), (x1, y1)], fill=RGB["k0"], width=1)
    return im


# ------------------------------------------------------------ layer 1 (room)
WALLPAPER = [
    "................",
    ".......#........",
    "......#.#.......",
    ".......#........",
    ".......#........",
    "................",
    "................",
    "................",
    "...............#",
    "#.............#.",
    "...............#",
    "...............#",
    "................",
    "................",
    "................",
    "................",
]


def layer1():
    c = LitCanvas(W, H)

    # ceiling beam + crown moulding
    c.rect(0, 0, W - 1, 9, "wood", 1)
    c.hline(0, W - 1, 10, "wood", 2)
    c.hline(0, W - 1, 11, "wood", 3)
    c.hline(0, W - 1, 12, "wood", 1)
    c.hline(0, W - 1, 13, "dark", 0)

    # wallpaper
    for y in range(14, 152):
        for x in range(W):
            m = WALLPAPER[(y - 14) % 16][x % 16] == "#"
            c.px(x, y, "wall", 2 if m else 1)
    # vertical shadow strip under the moulding
    c.hline(0, W - 1, 14, "wall", 0)

    # chair rail, wainscot panels, skirting
    c.hline(0, W - 1, 152, "wood", 3)
    c.hline(0, W - 1, 153, "wood", 2)
    c.hline(0, W - 1, 154, "wood", 1)
    c.rect(0, 155, W - 1, 187, "wood", 1)
    for px0 in range(4, W, 40):
        c.rect(px0, 160, px0 + 33, 183, "wood", 2)
        c.hline(px0, px0 + 33, 160, "wood", 0)
        c.vline(px0, 160, 183, "wood", 0)
        c.hline(px0 + 1, px0 + 33, 183, "wood", 3)
        c.vline(px0 + 33, 161, 183, "wood", 3)
    c.hline(0, W - 1, 188, "wood", 3)
    c.rect(0, 189, W - 1, 194, "wood", 2)
    c.hline(0, W - 1, 195, "dark", 0)

    # floorboards (side-on strip, planks run left-right)
    rows = [(196, 203), (204, 211), (212, 219), (220, 227)]
    for i, (y0, y1) in enumerate(rows):
        c.rect(0, y0, W - 1, y1, "wood", 2 + (i % 2 == 0))
        c.hline(0, W - 1, y0, "wood", 1)
        off = (i * 23) % 48
        for jx in range(off, W, 48 + (i % 3) * 8):
            c.vline(jx, y0, y1, "wood", 1)
            c.px(jx + 2, y0 + 3, "wood", 1)  # nail
    # floor front edge + joists in the crawlspace
    c.hline(0, W - 1, FLOOR_FRONT, "wood", 4)
    c.rect(0, FLOOR_FRONT + 1, W - 1, FLOOR_FRONT + 6, "wood", 2)
    c.hline(0, W - 1, FLOOR_FRONT + 7, "dark", 0)
    c.rect(0, FLOOR_FRONT + 8, W - 1, H - 1, "dark", 1)
    for jx in range(10, W, 64):
        c.rect(jx, FLOOR_FRONT + 8, jx + 7, H - 1, "dark", 2)
        c.vline(jx, FLOOR_FRONT + 8, H - 1, "dark", 3)
    c.rect(0, 252, W - 1, 255, "dark", 2)

    # ---- front door (left) ------------------------------------------
    dx0, dx1, dy0 = 20, 70, 64
    c.rect(dx0, dy0 - 16, dx1, FLOOR_TOP - 1, "wood", 3)       # casing
    c.vline(dx0, dy0 - 16, FLOOR_TOP - 1, "wood", 4)
    c.vline(dx1, dy0 - 16, FLOOR_TOP - 1, "wood", 1)
    c.hline(dx0, dx1, dy0 - 16, "wood", 4)
    # fanlight (purple glass glow)
    for y in range(dy0 - 13, dy0 - 1):
        for x in range(dx0 + 5, dx1 - 4):
            r = ((x - (dx0 + dx1) / 2) / 21) ** 2 + ((y - (dy0 - 1)) / 12.5) ** 2
            if r <= 1:
                band = "p3" if r < 0.35 else "p2"
                spoke = (x - (dx0 + dx1) // 2) in (0,) or abs((x - (dx0 + dx1) / 2)) - abs(y - (dy0 - 1)) * 1.6 in (0, 0.5, 1)
                c.emit(x, y, "b2" if spoke else band)
    c.rect(dx0 + 5, dy0 - 1, dx1 - 5, dy0 - 1, "wood", 2)
    # slab with raised panels
    c.rect(dx0 + 5, dy0, dx1 - 5, FLOOR_TOP - 1, "wood", 2)
    for (px0, py0, px1, py1) in [(31, 72, 43, 112), (47, 72, 59, 112),
                                 (31, 124, 43, 186), (47, 124, 59, 186)]:
        c.rect(px0, py0, px1, py1, "wood", 1)
        c.hline(px0, px1, py0, "wood", 0)
        c.vline(px0, py0, py1, "wood", 0)
        c.hline(px0 + 1, px1, py1, "wood", 3)
        c.vline(px1, py0 + 1, py1, "wood", 3)
        c.rect(px0 + 3, py0 + 3, px1 - 3, py1 - 3, "wood", 2)
    # knob + keyhole
    c.stamp(58, 140, ["bb", "Bb"], {"b": ("brass", 3), "B": ("brass", 4)})
    c.px(58, 145, "dark", 0)
    # mail slot
    c.rect(38, 118, 52, 120, "brass", 2)
    c.hline(39, 51, 119, "dark", 0)

    # ---- wall sconce near the door ----------------------------------
    sx = 96
    c.rect(sx - 3, 96, sx + 3, 98, "brass", 1)  # wall plate
    c.stamp(sx - 4, 84, [
        "...aaa...",
        "..abbba..",
        ".abbcbba.",
        ".abcccba.",
        ".abbcbba.",
        "..abbba..",
        "...ddd...",
        "..ddddd..",
        "....d....",
        "....d....",
        "....d....",
        "....d....",
    ], {"a": ("!", "o3"), "b": ("!", "o4"), "c": ("!", "o5"), "d": ("brass", 2)})
    c.add_light(sx, 92, 70, 2.2)

    # coat hooks + hanging coat & umbrella
    c.rect(84, 116, 112, 118, "wood", 3)
    c.hline(84, 112, 116, "wood", 4)
    for hx in (88, 98, 108):
        c.px(hx, 119, "brass", 2)
    coat = [  # long raincoat on the middle hook, collar up, belt
        "......a......",
        ".....aba.....",
        "...aabbbaa...",
        "..abbbcbbbba.",
        ".abbbbcbbbbba",
        ".abdbbcbbbdba",
        "abbdbbcbbbdba",
        "abbdbbcbbbdba",
        "abbdbbcbbbdba",
        "abbdbbcbbbdba",
        "abbaeeeeeeaba",
        "abbdbbcbbbdba",
        "abbdbbcbbbdba",
        "abbdbbcbbbbda",
        "abbbbbcbbbbda",
        "abbbbbcbbbbba",
        "abbbbbcbbbbba",
        ".abbbbcbbbbba",
        ".abbbbcbbbbba",
        ".abbbbcbbbbba",
        ".abbbbcbbbbba",
        ".aaaaaaaaaaaa",
    ]
    c.stamp(92, 119, coat, {"a": ("stone", 0), "b": ("stone", 2), "c": ("stone", 1),
                            "d": ("stone", 1), "e": ("stone", 3)})

    # ---- window ------------------------------------------------------
    x0, y0, x1, y1 = WIN
    c.rect(x0 - 6, y0 - 6, x1 + 6, y1 + 8, "wood", 3)
    c.hline(x0 - 6, x1 + 6, y0 - 6, "wood", 4)
    c.vline(x0 - 6, y0 - 6, y1 + 8, "wood", 4)
    c.rect(x0 - 9, y1 + 4, x1 + 9, y1 + 8, "wood", 4)   # sill
    c.hline(x0 - 9, x1 + 9, y1 + 8, "wood", 2)
    c.clear(x0, y0, x1, y1)                            # glass = transparent
    mx = (x0 + x1) // 2
    c.rect(mx - 1, y0, mx + 1, y1, "wood", 3)          # muntins
    for my in (y0 + 33, y0 + 67):
        c.rect(x0, my - 1, x1, my + 1, "wood", 3)
    c.hline(x0, x1, y1 + 1, "wood", 1)
    # curtain rod + curtains
    c.rect(x0 - 18, y0 - 12, x1 + 18, y0 - 10, "brass", 2)
    for cx0, cx1, side in ((x0 - 16, x0 + 5, -1), (x1 - 5, x1 + 16, 1)):
        for y in range(y0 - 9, y1 + 12):
            sway = 0 if y < y1 - 20 else (y - (y1 - 20)) // 6
            for x in range(cx0, cx1 + 1):
                if side < 0 and x > cx1 - sway:
                    continue
                if side > 0 and x < cx0 + sway:
                    continue
                fold = (x - cx0) % 5
                s = 2 if fold in (1, 2) else 1
                if fold == 4:
                    s = 0
                c.px(x, y, "cloth", s)
    # moonlight spilling onto the floor and the wainscot below the window
    c.moon_poly([(x0 + 4, FLOOR_TOP), (x1 + 2, FLOOR_TOP),
                 (x1 + 30, FLOOR_FRONT - 1), (x0 + 28, FLOOR_FRONT - 1)])

    # radiator under the window
    rx0, rx1 = 148, 188
    c.rect(rx0, 160, rx1, 187, "stone", 2)
    for x in range(rx0, rx1 + 1, 4):
        c.vline(x, 162, 186, "stone", 1)
        c.vline(x + 1, 162, 186, "stone", 3)
    c.hline(rx0, rx1, 160, "stone", 3)
    c.rect(rx0 + 2, 188, rx0 + 4, 194, "stone", 1)
    c.rect(rx1 - 4, 188, rx1 - 2, 194, "stone", 1)
    c.rect(rx1 + 1, 176, rx1 + 4, 178, "brass", 2)  # valve

    # ---- mirror + side table + lamp + phone -------------------------
    mcx, mcy = 266, 92
    for y in range(mcy - 28, mcy + 29):
        for x in range(mcx - 20, mcx + 21):
            r = ((x - mcx) / 20) ** 2 + ((y - mcy) / 28) ** 2
            if r <= 1:
                if r > 0.80:
                    c.px(x, y, "wood", 4 if (x < mcx and y < mcy) else 2)
                elif r > 0.72:
                    c.px(x, y, "brass", 2)
                else:
                    # the mirror reflects an empty, darker room
                    sheen = abs((x - mcx) + (y - mcy) * 0.6 - 6) < 1.2
                    c.emit(x, y, "p2" if sheen else "p1")
    for y in range(mcy - 18, mcy + 18):  # faint shape in the glass
        pass

    tx0, tx1, ty = 236, 300, 166
    c.rect(tx0, ty, tx1, ty + 3, "wood", 4)
    c.hline(tx0, tx1, ty + 3, "wood", 2)
    c.rect(tx0 + 2, ty + 4, tx1 - 2, ty + 10, "wood", 2)   # drawer
    c.rect(tx0 + 29, ty + 6, tx0 + 33, ty + 6, "brass", 1)
    for lx in (tx0 + 3, tx1 - 5):
        c.rect(lx, ty + 11, lx + 2, FLOOR_TOP - 1, "wood", 2)
    # lamp
    lcx = 252
    c.rect(lcx - 4, 152, lcx + 4, ty - 1, "bone", 2)       # ceramic base
    c.rect(lcx - 3, 150, lcx + 3, 151, "bone", 2)
    c.hline(lcx - 6, lcx + 6, ty - 1, "bone", 1)
    c.vline(lcx, 146, 149, "brass", 2)
    for i, y in enumerate(range(126, 146)):
        half = 8 + i // 3
        for x in range(lcx - half, lcx + half + 1):
            col = "o4"
            if y == 126:
                col = "o3"
            elif y >= 144:
                col = "o5"
            elif x <= lcx - half + 1:
                col = "o3"
            c.emit(x, y, col)
    c.add_light(lcx, 146, 120, 2.6, squash=0.85)
    # rotary phone
    c.stamp(272, 154, [
        "..aaaaaaaa..",
        ".abbbbbbbba.",
        "abbbbbbbbbba",
        "..abbccbba..",
        ".abbcddcbba.",
        "abbbcddcbbba",
        "abbbbccbbbba",
        "aaaaaaaaaaaa",
    ], {"a": ("stone", 0), "b": ("stone", 2), "c": ("stone", 3), "d": ("stone", 1)})

    # ---- staircase (right) -------------------------------------------
    sx0, step_w, step_h, n = 340, 10, 10, 14
    # under-stair wall triangle + closet door
    for i in range(n):
        x = sx0 + i * step_w
        top = FLOOR_TOP - (i + 1) * step_h
        c.rect(x, top + step_h, x + step_w - 1, FLOOR_TOP - 1, "wood", 1)
    c.rect(410, 140, 440, FLOOR_TOP - 1, "wood", 2)
    c.vline(410, 140, FLOOR_TOP - 1, "wood", 0)
    c.hline(410, 440, 140, "wood", 0)
    c.vline(440, 140, FLOOR_TOP - 1, "wood", 3)
    c.rect(414, 145, 436, 165, "wood", 1)
    c.rect(414, 170, 436, 192, "wood", 1)
    c.px(434, 168, "brass", 3)
    # treads/risers (side profile + stringer)
    for i in range(n):
        x = sx0 + i * step_w
        top = FLOOR_TOP - (i + 1) * step_h
        c.rect(x, top, x + step_w - 1, top + 2, "wood", 4)   # tread nose
        c.hline(x, x + step_w + 1, top, "wood", 5)
        c.rect(x, top + 3, x + step_w - 1, top + step_h - 1, "wood", 2)
    # stringer band
    for i in range(n * step_w):
        x = sx0 + i
        yb = FLOOR_TOP - (i * step_h) // step_w
        c.rect(x, yb - 4, x, yb, "wood", 3)
        c.px(x, yb - 4, "wood", 4)
    # balusters + handrail
    for i in range(n):
        x = sx0 + i * step_w + 4
        top = FLOOR_TOP - (i + 1) * step_h
        c.rect(x, top - 22, x + 1, top - 1, "wood", 3)
        c.vline(x + 1, top - 22, top - 1, "wood", 2)
    for i in range(n * step_w + 2):
        x = sx0 - 2 + i
        yr = FLOOR_TOP - 26 - ((i - 2) * step_h) // step_w - 6
        c.rect(x, yr, x, yr + 2, "wood", 4)
        c.px(x, yr, "wood", 5)
        c.px(x, yr + 3, "wood", 1)
    # newel post
    c.rect(334, 158, 343, FLOOR_TOP - 1, "wood", 3)
    c.vline(334, 158, FLOOR_TOP - 1, "wood", 4)
    c.vline(343, 158, FLOOR_TOP - 1, "wood", 1)
    c.rect(332, 152, 345, 157, "wood", 4)
    c.rect(335, 147, 342, 151, "wood", 3)
    c.rect(336, 166, 341, 186, "wood", 2)
    # stairwell opening through the ceiling (the unknown upstairs)
    for y in range(0, 60):
        for x in range(452, W):
            c.emit(x, y, "k0")
    c.emit_rect(452, 0, 453, 59, "p1")
    c.emit_rect(454, 0, 454, 59, "p2")
    c.emit_rect(452, 59, W - 1, 59, "p1")
    # framed pictures stepping up the stair wall
    for (fx, fy) in ((356, 108), (388, 80), (420, 52)):
        c.rect(fx, fy, fx + 17, fy + 13, "wood", 4)
        c.rect(fx + 2, fy + 2, fx + 15, fy + 11, "stone", 1)
        c.hline(fx + 2, fx + 15, fy + 8, "stone", 2)        # horizon
        c.px(fx + 11, fy + 5, "stone", 3)                   # pale dot (moon/house)
        c.hline(fx + 1, fx + 17, fy + 13, "wood", 2)
    # crooked one
    c.rect(392, 64, 392, 64, "wood", 0)

    # hairline crack in the plaster
    for (x, y) in ((318, 15), (318, 16), (319, 17), (319, 18), (320, 19), (319, 20),
                   (320, 21), (321, 22), (321, 23), (322, 24), (320, 22), (317, 19)):
        c.px(x, y, "wall", 0)
    c.stamp(120, 15, ["aaaa", ".aa.", "..a."], {"a": ("wall", 3)})

    # darken the far corners a step (contact shadows)
    for y in range(H):
        for x in range(W):
            if c.mat[y, x] and y in (14, 15):
                c.shadow[y, x] = 1
    # floor shadows under furniture
    for (fx0, fx1) in ((tx0 - 2, tx1 + 2), (rx0 - 2, rx1 + 2), (dx0, dx1 + 2), (332, 346)):
        c.shadow[FLOOR_TOP:FLOOR_TOP + 3, fx0:fx1 + 1] = 1
    return c.render()


# ----------------------------------------------------- layer 2 (foreground)
def layer2():
    """Near-black silhouettes framing the bottom corners; keep clear of the floor plane."""
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    k, rim = RGB["k0"], RGB["n2"]
    # left: wing-back armchair, seen from behind/side
    d.rounded_rectangle([-20, 206, 46, H + 10], radius=10, fill=k)     # back
    d.rounded_rectangle([30, 236, 70, H + 10], radius=6, fill=k)       # arm
    d.rectangle([34, 250, 40, H], fill=k)
    d.line([(-20, 206), (36, 206)], fill=rim)                          # rim light
    d.line([(46, 214), (46, 236)], fill=rim)
    d.line([(36, 236), (66, 236)], fill=rim)
    # right: potted fern
    d.polygon([(430, 244), (472, 244), (466, H), (436, H)], fill=k)
    d.rectangle([426, 240, 476, 245], fill=k)
    d.line([(426, 240), (476, 240)], fill=rim)
    for (ex, ey, n) in ((400, 226, 6), (414, 208, 6), (440, 200, 7), (464, 204, 6),
                        (482, 222, 5)):
        sx, sy = 451, 240
        d.line([(sx, sy), (ex, ey)], fill=k, width=3)
        for i in range(1, n + 1):           # leaflets along each frond
            t = i / (n + 1)
            px, py = sx + (ex - sx) * t, sy + (ey - sy) * t
            L = 6 - i * 3 // n
            d.polygon([(px, py), (px - L, py - L), (px - L + 2, py - L - 2)], fill=k)
            d.polygon([(px, py), (px + L, py - L), (px + L - 2, py - L - 2)], fill=k)
    p = im.load()
    for y in range(H):
        for x in range(W):
            if p[x, y][3] and p[x, y][3] != 255:
                p[x, y] = k + (255,)
    return im
