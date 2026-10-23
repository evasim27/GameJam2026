"""Step 1 deliverable: entrance hall + child + pumpkin composed as a 480x270 screen."""
import os
import sys

from PIL import Image

import bg_entrance as bg
from canvas import check_palette, upscale
from child import idle_frames
from props import pumpkin

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "art", "style_test")


def main():
    os.makedirs(OUT, exist_ok=True)
    l0, l1, l2 = bg.layer0(), bg.layer1(), bg.layer2()
    kid, pk = idle_frames()[0], pumpkin(0)
    for im, name in ((l0, "bg_entrance_layer0_480x270.png"),
                     (l1, "bg_entrance_layer1_480x270.png"),
                     (l2, "bg_entrance_layer2_480x270.png")):
        check_palette(im, name)
        im.save(os.path.join(OUT, name))
    check_palette(kid, "child")
    check_palette(pk, "pumpkin")

    screen = Image.new("RGBA", (bg.W, bg.H), (0, 0, 0, 255))
    screen.alpha_composite(l0)
    screen.alpha_composite(l1)
    screen.alpha_composite(kid, (196, 218 - 29))
    screen.alpha_composite(pk, (300, 220 - 30))
    screen.alpha_composite(l2)
    check_palette(screen, "screen")
    screen.save(os.path.join(OUT, "style_test_entrance_480x270.png"))
    upscale(screen, 3).save(os.path.join(OUT, "style_test_entrance_1440x810_preview.png"))
    print("ok")


if __name__ == "__main__":
    sys.exit(main())
