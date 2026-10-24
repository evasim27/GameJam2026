"""Pack generated bat poses with a shared scale and fixed torso anchor."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/bat/bat-flight-source.png'
OUT = ROOT / 'game/assets/rewind/cinematic/bat-flight-4f.png'
source = Image.open(SOURCE).convert('RGBA')
CELL = 128
SCALE = 96 / 720
# Generated cells have different margins. Keep the torso still through the flap.
ANCHORS = [(505, 340), (1270, 340), (505, 700), (1270, 700)]
sheet = Image.new('RGBA', (4 * CELL, CELL))
for i, (anchor_x, anchor_y) in enumerate(ANCHORS):
    x, y = (i % 2) * (source.width // 2), (i // 2) * (source.height // 2)
    pose = source.crop((x, y, x + source.width // 2, y + source.height // 2))
    bounds = pose.getchannel('A').point(lambda a: 255 if a > 128 else 0).getbbox()
    if bounds is None:
        raise ValueError(f'Empty bat pose {i}')
    pose = pose.crop(bounds)
    pose = pose.resize((round(pose.width * SCALE), round(pose.height * SCALE)), Image.Resampling.NEAREST)
    offset_x = CELL // 2 + round((x + bounds[0] - anchor_x) * SCALE)
    offset_y = CELL // 2 + round((y + bounds[1] - anchor_y) * SCALE)
    if not (0 <= offset_x <= CELL - pose.width and 0 <= offset_y <= CELL - pose.height):
        raise ValueError(f'Bat pose {i} exceeds its frame')
    sheet.alpha_composite(pose, (i * CELL + offset_x, offset_y))
sheet.save(OUT)
manifest = dict(texture=str(OUT.relative_to(ROOT)), frame_size=[CELL, CELL],
                frames=['wings_up', 'wings_open', 'wings_down', 'recovery'],
                anchor_pixels=[64, 64], draw_size_world=[32, 32],
                source_anchors=ANCHORS, source_scale=SCALE,
                generation='built-in image_gen; pumpkin and skeleton style references; nearest-neighbor packing; original alpha preserved')
(SOURCE.parent / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(OUT)
