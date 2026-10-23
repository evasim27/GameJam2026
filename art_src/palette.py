"""Lost on Tape - master palette (32 colors).

Reserved gameplay hues:
  orange  o1..o5  child + interactive objects
  cyan    c1..c3  safe time windows, glitch
  purple  p1..p3  unknown / mysterious, moonlight
  red     r1..r3  Tape Eater, danger
"""

PALETTE = [
    # neutrals (cool, desaturated)
    ("k0", "0b0a10"),  # outline / deepest shadow
    ("n1", "17141f"),
    ("n2", "25212f"),
    ("n3", "363143"),
    ("n4", "4f485c"),
    ("n5", "756c80"),
    ("n6", "b3a9b8"),
    ("w",  "e6dfe0"),  # bone white
    # wallpaper olive-green
    ("g1", "1a201b"),
    ("g2", "262f26"),
    ("g3", "364132"),
    ("g4", "4d573f"),
    # wood
    ("b1", "1c130f"),
    ("b2", "2d1e17"),
    ("b3", "432b1e"),
    ("b4", "5f3e29"),
    ("b5", "82583a"),
    # skin
    ("sk", "d9a07a"),
    # warm orange (child / interactive / flame)
    ("o1", "8f3a1a"),
    ("o2", "c95a1c"),
    ("o3", "ee8a2e"),
    ("o4", "ffc263"),
    ("o5", "fff1c9"),
    # cyan (safe / glitch)
    ("c1", "1a4f5c"),
    ("c2", "34a3b4"),
    ("c3", "9cefe9"),
    # purple (mystery / moonlight)
    ("p1", "2a1c40"),
    ("p2", "47306a"),
    ("p3", "7a58a6"),
    # red (Tape Eater / danger)
    ("r1", "4f1016"),
    ("r2", "9c1f2a"),
    ("r3", "e0443c"),
]

NAMES = [n for n, _ in PALETTE]
HEX = {n: h for n, h in PALETTE}


def rgb(name):
    h = HEX[name]
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


RGB = {n: rgb(n) for n in NAMES}
RGBA = {n: rgb(n) + (255,) for n in NAMES}
ALLOWED = set(RGB.values())
