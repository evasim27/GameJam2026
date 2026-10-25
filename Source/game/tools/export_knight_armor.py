"""Pack generated v2 poses, align their bases, and export at pumpkin-relative scale."""
from pathlib import Path
from PIL import Image, ImageDraw
import json

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'game/assets/knight_armor'
im = Image.open(ROOT / 'assets/knight_armor/knight-armor-source-v2.png').convert('RGBA')
frames = []
idle_height = 413
idle_base_width = 240
for i in range(6):
    x, top = i % 3 * 512, 0 if i < 3 else 560
    pose = im.crop((x, top, x + 512, 560 if i < 3 else 1024))
    mask = pose.getchannel('A').point(lambda v: 255 if v > 128 else 0)
    bounds = mask.getbbox()
    base = mask.crop((0, bounds[3] - 24, 512, bounds[3])).getbbox()
    factor = 64 / idle_height * idle_base_width / (base[2] - base[0])
    pose = pose.crop((0, 0, 512, bounds[3]))
    scaled = pose.resize((round(pose.width * factor), round(pose.height * factor)), Image.Resampling.NEAREST)
    frame = Image.new('RGBA', (128, 128))
    frame.alpha_composite(scaled, (76 - round((base[0] + base[2]) * .5 * factor), 112 - scaled.height))
    frames.append(frame)
visible_idle_height = frames[0].getchannel('A').point(lambda v: 255 if v > 128 else 0).getbbox()
visible_idle_height = visible_idle_height[3] - visible_idle_height[1]
pumpkin = Image.open(ROOT / 'game/assets/rewind/pumpkin-styled.png').convert('RGBA').crop((248, 232, 788, 712))
pumpkin_bounds = pumpkin.getchannel('A').point(lambda v: 255 if v > 128 else 0).getbbox()
pumpkin_height = (pumpkin_bounds[3] - pumpkin_bounds[1]) * 16 / 540
scale = 2 * pumpkin_height / visible_idle_height
sheet = Image.new('RGBA', (768, 128))
for i, frame in enumerate(frames):
    sheet.alpha_composite(frame, (128 * i, 0))
sheet.save(OUT / 'knight-armor-swing-v2-6f.png')
frames[0].save(OUT / 'knight-armor-idle-v2.png')
previews = []
zoom = 12
for frame in frames:
    preview = Image.new('RGBA', (900, 660), (27, 23, 29, 255))
    draw = ImageDraw.Draw(preview)
    draw.line((60, 580, 840, 580), fill=(78, 64, 59), width=2)
    p = pumpkin.crop(pumpkin_bounds)
    p = p.resize((round(p.width * 16 / 540 * zoom), round(p.height * 16 / 540 * zoom)), Image.Resampling.NEAREST)
    preview.alpha_composite(p, (140, 580 - p.height))
    a = frame.resize((round(128 * scale * zoom), round(128 * scale * zoom)), Image.Resampling.NEAREST)
    preview.alpha_composite(a, (610 - round(76 * scale * zoom), 580 - round(112 * scale * zoom)))
    draw.text((140, 610), 'BUCA / 1x', fill=(230, 211, 183), font_size=20)
    draw.text((540, 610), 'OKLEP / 2x', fill=(230, 211, 183), font_size=20)
    previews.append(preview.convert('RGB'))
previews[0].save(ROOT / 'assets/knight_armor/knight-armor-pumpkin-comparison-v2.gif', save_all=True, append_images=previews[1:], duration=[1600, 160, 120, 70, 140, 220], loop=0, disposal=2)
previews[0].save(ROOT / 'assets/knight_armor/knight-armor-pumpkin-comparison-v2.png')
manifest = json.loads((OUT / 'manifest.json').read_text())
manifest.update(sheet='knight-armor-swing-v2-6f.png', base_width_pixels=round(idle_base_width * 64 / idle_height), scene_scale=scale, idle_visible_height_pixels=visible_idle_height, pumpkin_visible_height_world=pumpkin_height, armor_idle_visible_height_world=2*pumpkin_height, height_ratio=2, generation='built-in image_gen v2; coarser pumpkin-reference pixel art, nearest-neighbor packing and base alignment')
(OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
scene = ROOT / 'game/rewind/objects/knight_armor.tscn'
text = scene.read_text().replace('knight-armor-swing-6f.png', 'knight-armor-swing-v2-6f.png')
if '\nscale = ' not in text:
    text = text.replace('texture_filter = 1', f'texture_filter = 1\nscale = Vector2({scale}, {scale})')
scene.write_text(text)
print(json.dumps({k: manifest[k] for k in ['scene_scale', 'idle_visible_height_pixels', 'pumpkin_visible_height_world', 'armor_idle_visible_height_world', 'height_ratio']}, indent=2))
