"""Pack the generated shadow poses into a transparent, pixel-sized game atlas."""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'assets/shadow_monster/shadow-monster-source.png'
OUT = ROOT / 'game/assets/rewind/cinematic/shadow-monster.png'
source = Image.open(SOURCE).convert('RGBA')
sheet = Image.new('RGBA', (256, 128))
rects = []
# The generated reach starts before the canvas midpoint; split in the clear gap.
source_rects = [(0, 0, 740, source.height), (740, 0, source.width, source.height)]
for index, source_rect in enumerate(source_rects):
    pose = source.crop(source_rect)
    # Ignore almost invisible generation specks when finding the useful bounds.
    bounds = pose.getchannel('A').point(lambda alpha: 255 if alpha > 128 else 0).getbbox()
    if bounds is None:
        raise ValueError(f'Empty pose {index}')
    pose = pose.crop(bounds)
    height = 96
    width = round(pose.width * height / pose.height)
    pose = pose.resize((width, height), Image.Resampling.NEAREST)
    if width > 120:
        raise ValueError('Pose does not fit its cell')
    x, y = index * 128 + (128 - width) // 2, 16
    sheet.alpha_composite(pose, (x, y))
    rects.append([x, y, width, height])
sheet.save(OUT)
manifest = {'texture': str(OUT.relative_to(ROOT)), 'frame_rects': dict(zip(['idle', 'reach'], rects)),
            'generation': 'built-in image_gen; nearest-neighbor export; original alpha preserved'}
(SOURCE.parent / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
print(json.dumps(manifest))
