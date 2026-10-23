"""Protagonist: kid in a homemade fox costume (orange hoodie w/ ears + tail), cloth candy sack.
Frame 24x32, facing right, light from upper-left. Fill pixels only; outline added automatically."""
from canvas import sprite_from_rows, outline

LEGEND = {
    "Y": "o4", "L": "o3", "O": "o2", "o": "o1",
    "s": "sk", "z": "b5", "e": "k0",
    "w": "w", "v": "n6",
    "g": "n6", "G": "w", "q": "n5",
    "n": "n4", "d": "n3", "m": "n2",
    "b": "b3", "B": "b2",
}

IDLE_A = [
    "........................",
    "........o.....o.........",
    ".......oLo...oOo........",
    ".......LYO..oOOo........",
    ".......LLOOOOOOOo.......",
    "......LLLOOOOOOOOo......",
    "......LLOOOOOOOOOOo.....",
    ".....LLOOOOOOOObbbbo....",
    ".....LLOOOOOOObbssssz...",
    ".....LOOOOOOOObsssess...",
    ".....LOOOOOOOOsssssss...",
    ".....oOOOOOOOOsssssz....",
    "......oOOOOOOOOzsss.....",
    ".......ooOOOOOOOoo......",
    ".........oOOOOOo........",
    "........LLOOOOOOo.......",
    ".......LLLOOOOOOOo......",
    "..ww...LLOOOOOOOOo......",
    ".wGwO..LLOOOOOOOOo......",
    ".wwOOO.LOOOOOOOOso......",
    "..oOOOOLOOOOOOOGGG......",
    "....ooOOOOOOOOgGGgg.....",
    "........dnnnnngGggq.....",
    "........dnnnnnggggq.....",
    "........dnn.nnqgqq......",
    "........dnn.dnn.........",
    "........dnn.dnn.........",
    "........dnn.dnn.........",
    ".......Bbbb.Bbbbb.......",
    ".......BBBB.BBBBB.......",
    "........................",
    "........................",
]


def frame(rows):
    return outline(sprite_from_rows(rows, LEGEND, 24, 32))


def idle_frames():
    return [frame(IDLE_A)]
