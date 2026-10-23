"""Drawing helpers that only ever write palette colors on an integer grid."""
import math

import numpy as np
from PIL import Image

from palette import NAMES, RGB, ALLOWED

IDX = {n: i for i, n in enumerate(NAMES)}
CLEAR = -1

# Material ramps, dark -> light. Lighting moves a pixel along its ramp.
RAMPS = {
    "wall":    ["k0", "g1", "g2", "g3", "g4", "b5"],
    "wood":    ["k0", "b1", "b2", "b3", "b4", "b5"],
    "stone":   ["k0", "n1", "n2", "n3", "n4", "n5", "n6"],
    "cloth":   ["k0", "p1", "p2", "p3"],
    "brass":   ["k0", "b2", "b4", "b5", "o4"],
    "bone":    ["k0", "n2", "n4", "n6", "w"],
    "dark":    ["k0", "k0", "n1", "n2", "n3"],
}
# What a material turns into when it sits inside moonlight.
MOON = ["k0", "p1", "p2", "p3", "n6"]

BAYER2 = np.array([[0, 2], [3, 1]]) / 4.0


class LitCanvas:
    """Paint materials + base shade, then resolve lighting into palette colors."""

    def __init__(self, w, h):
        self.w, self.h = w, h
        self.mat = np.full((h, w), "", dtype=object)
        self.shade = np.zeros((h, w), dtype=int)
        self.fixed = np.full((h, w), CLEAR, dtype=int)  # emissive/unlit colors
        self.lights = []
        self.moon = np.zeros((h, w), dtype=bool)
        self.shadow = np.zeros((h, w), dtype=int)  # extra darkening
        self.dither = True

    # --- painting -------------------------------------------------------
    def rect(self, x0, y0, x1, y1, mat, shade):
        """Inclusive rect."""
        x0, x1 = max(0, x0), min(self.w - 1, x1)
        y0, y1 = max(0, y0), min(self.h - 1, y1)
        if x0 > x1 or y0 > y1:
            return
        self.mat[y0:y1 + 1, x0:x1 + 1] = mat
        self.shade[y0:y1 + 1, x0:x1 + 1] = shade
        self.fixed[y0:y1 + 1, x0:x1 + 1] = CLEAR

    def px(self, x, y, mat, shade):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.mat[y, x] = mat
            self.shade[y, x] = shade
            self.fixed[y, x] = CLEAR

    def hline(self, x0, x1, y, mat, shade):
        self.rect(x0, y, x1, y, mat, shade)

    def vline(self, x, y0, y1, mat, shade):
        self.rect(x, y0, x, y1, mat, shade)

    def emit(self, x, y, color):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.fixed[y, x] = IDX[color]

    def emit_rect(self, x0, y0, x1, y1, color):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.emit(x, y, color)

    def clear(self, x0, y0, x1, y1):
        self.rect(x0, y0, x1, y1, "", 0)

    def stamp(self, x, y, rows, legend):
        """rows: list of strings; legend: char -> (mat, shade) | ('!', color)."""
        for j, row in enumerate(rows):
            for i, ch in enumerate(row):
                if ch in (".", " "):
                    continue
                v = legend[ch]
                if v[0] == "!":
                    self.emit(x + i, y + j, v[1])
                else:
                    self.px(x + i, y + j, v[0], v[1])

    def add_light(self, x, y, radius, strength, squash=1.0):
        self.lights.append((x, y, radius, strength, squash))

    def moon_poly(self, pts):
        from PIL import ImageDraw
        m = Image.new("1", (self.w, self.h), 0)
        ImageDraw.Draw(m).polygon(pts, fill=1)
        self.moon |= np.array(m, dtype=bool)

    # --- resolve --------------------------------------------------------
    def light_map(self):
        yy, xx = np.mgrid[0:self.h, 0:self.w]
        L = np.zeros((self.h, self.w))
        for (lx, ly, r, s, squash) in self.lights:
            d = np.sqrt((xx - lx) ** 2 + ((yy - ly) / squash) ** 2) / r
            L += s * np.clip(1 - d, 0, 1) ** 1.6
        return L

    def render(self):
        L = self.light_map()
        out = np.zeros((self.h, self.w, 4), dtype=np.uint8)
        for y in range(self.h):
            for x in range(self.w):
                f = self.fixed[y, x]
                if f != CLEAR:
                    out[y, x] = RGB[NAMES[f]] + (255,)
                    continue
                m = self.mat[y, x]
                if not m:
                    continue
                lv = L[y, x]
                step = math.floor(lv)
                # thin 2x2 dither band only right at the edge of a light step
                # checker band only on the outer rim of a light pool
                if self.dither and step == 0 and lv > 0.72 and (x + y) % 2 == 0:
                    step = 1
                level = self.shade[y, x] + step - self.shadow[y, x]
                ramp = RAMPS[m]
                if self.moon[y, x] and m not in ("dark",):
                    ramp = MOON
                    level -= 1
                level = max(0, min(len(ramp) - 1, level))
                out[y, x] = RGB[ramp[level]] + (255,)
        return Image.fromarray(out, "RGBA")


# --- sprite helpers -------------------------------------------------------

def sprite_from_rows(rows, legend, w=None, h=None, ox=0, oy=0, base=None):
    """Make (or draw into) an RGBA image from ASCII rows. legend: char -> palette name."""
    if base is None:
        w = w or max(len(r) for r in rows)
        h = h or len(rows)
        base = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = base.load()
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch in (".", " "):
                continue
            x, y = ox + i, oy + j
            if 0 <= x < base.width and 0 <= y < base.height:
                if ch == "_":  # explicit erase
                    px[x, y] = (0, 0, 0, 0)
                else:
                    px[x, y] = RGB[legend[ch]] + (255,)
    return base


def outline(img, color="k0", diagonal=False):
    """Add a 1px outer outline around opaque pixels."""
    a = np.array(img)[:, :, 3] > 0
    h, w = a.shape
    grow = np.zeros_like(a)
    shifts = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    if diagonal:
        shifts += [(-1, -1), (1, -1), (-1, 1), (1, 1)]
    for dx, dy in shifts:
        s = np.zeros_like(a)
        ys = slice(max(0, dy), h + min(0, dy))
        yd = slice(max(0, -dy), h + min(0, -dy))
        xs = slice(max(0, dx), w + min(0, dx))
        xd = slice(max(0, -dx), w + min(0, -dx))
        s[yd, xd] = a[ys, xs]
        grow |= s
    edge = grow & ~a
    out = img.copy()
    p = out.load()
    for y, x in zip(*np.nonzero(edge)):
        p[int(x), int(y)] = RGB[color] + (255,)
    return out


def check_palette(img, label):
    bad = set()
    for r, g, b, a in img.getdata():
        if a not in (0, 255):
            bad.add(("alpha", a))
        elif a == 255 and (r, g, b) not in ALLOWED:
            bad.add((r, g, b))
    if bad:
        raise ValueError(f"{label}: off-palette pixels {list(bad)[:8]}")
    return True


def upscale(img, k):
    return img.resize((img.width * k, img.height * k), Image.NEAREST)


def sheet(frames):
    w, h = frames[0].size
    s = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        assert f.size == (w, h)
        s.paste(f, (i * w, 0))
    return s
