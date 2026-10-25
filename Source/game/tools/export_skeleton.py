"""Pack skeleton sword poses and export the same scale as the approved knight."""
from pathlib import Path
from PIL import Image, ImageDraw
import json

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'game/assets/skeleton'
SOURCE = ROOT / 'assets/skeleton/skeleton-source.png'
im = Image.open(SOURCE).convert('RGBA')
CELL = im.width // 3
SPLIT_Y = 550
SOURCE_RECTS = [(0, 0, 512, 550), (512, 0, 1024, 550), (1024, 0, 1536, 550), (0, 550, 530, 1024), (530, 550, 1040, 1024), (1040, 550, 1536, 1024)]
poses = []
for i in range(6):
    top = 0 if i < 3 else SPLIT_Y
    pose = im.crop(SOURCE_RECTS[i])
    mask = pose.getchannel('A').point(lambda v: 255 if v > 128 else 0)
    bounds = mask.getbbox()
    if bounds is None:
        raise ValueError(f'Empty pose {i}')
    feet = mask.crop((0, bounds[3] - 16, pose.width, bounds[3])).getbbox()
    poses.append((pose, bounds, (feet[0] + feet[2]) / 2))
factor = 64 / (poses[0][1][3] - poses[0][1][1])
frames = []
for pose, bounds, center_x in poses:
    pose = pose.crop((0, 0, pose.width, bounds[3]))
    scaled = pose.resize((round(pose.width * factor), round(pose.height * factor)), Image.Resampling.NEAREST)
    frame = Image.new('RGBA', (128, 128))
    frame.alpha_composite(scaled, (76 - round(center_x * factor), 112 - scaled.height))
    frames.append(frame)
b = frames[0].getchannel('A').point(lambda v: 255 if v > 128 else 0).getbbox()
idle_height = b[3] - b[1]
pumpkin = Image.open(ROOT / 'game/assets/rewind/pumpkin-styled.png').convert('RGBA').crop((248, 232, 788, 712))
pb = pumpkin.getchannel('A').point(lambda v: 255 if v > 128 else 0).getbbox()
pumpkin_height = (pb[3] - pb[1]) * 16 / 540
scale = 2 * pumpkin_height / idle_height
sheet = Image.new('RGBA', (768, 128))
for i, frame in enumerate(frames):
    sheet.alpha_composite(frame, (128 * i, 0))
sheet.save(OUT / 'skeleton-swing-6f.png')
frames[0].save(OUT / 'skeleton-idle.png')
previews = []
zoom = 12
for frame in frames:
    preview = Image.new('RGBA', (900, 660), (27, 23, 29, 255))
    draw = ImageDraw.Draw(preview)
    draw.line((60, 580, 840, 580), fill=(78, 64, 59), width=2)
    p = pumpkin.crop(pb)
    p = p.resize((round(p.width * 16 / 540 * zoom), round(p.height * 16 / 540 * zoom)), Image.Resampling.NEAREST)
    preview.alpha_composite(p, (140, 580 - p.height))
    a = frame.resize((round(128 * scale * zoom), round(128 * scale * zoom)), Image.Resampling.NEAREST)
    preview.alpha_composite(a, (610 - round(76 * scale * zoom), 580 - round(112 * scale * zoom)))
    draw.text((140, 610), 'BUCA / 1x', fill=(230, 211, 183), font_size=20)
    draw.text((520, 610), 'OKOSTNJAK / 2x', fill=(230, 211, 183), font_size=20)
    previews.append(preview.convert('RGB'))
previews[0].save(ROOT / 'assets/skeleton/skeleton-pumpkin-comparison.gif', save_all=True, append_images=previews[1:], duration=[1600, 160, 120, 70, 140, 220], loop=0, disposal=2)
previews[0].save(ROOT / 'assets/skeleton/skeleton-pumpkin-comparison.png')
manifest = dict(sheet='skeleton-swing-6f.png', frame_size=[128, 128], columns=6, rows=1, anchor_pixels=[76, 112], facing='left', durations_seconds=[1.6, .16, .12, .07, .14, .22], frames=['idle', 'anticipation', 'raised', 'slash', 'follow_through', 'recover'], scene_scale=scale, idle_visible_height_pixels=idle_height, pumpkin_visible_height_world=pumpkin_height, skeleton_idle_visible_height_world=2*pumpkin_height, height_ratio=2, generation='built-in image_gen; pumpkin and approved knight style references; nearest-neighbor frame packing and foot alignment')
(OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
scene = (ROOT / 'game/rewind/objects/knight_armor.tscn').read_text()
scene = scene.replace('knight_armor/knight-armor-swing-v2-6f.png', 'skeleton/skeleton-swing-6f.png').replace('SpriteFrames_armor', 'SpriteFrames_skeleton').replace('KnightArmor', 'Skeleton')
import re
scene = re.sub(r'scale = Vector2\([^\n]+\)', f'scale = Vector2({scale}, {scale})', scene)
(ROOT / 'game/rewind/objects/skeleton.tscn').write_text(scene)
preview = (ROOT / 'game/rewind/objects/knight_armor_preview.tscn').read_text().replace('knight_armor.tscn', 'skeleton.tscn').replace('KnightArmor', 'Skeleton').replace('ArmorLabel', 'SkeletonLabel').replace('OKLEP / 2x', 'OKOSTNJAK / 2x')
(ROOT / 'game/rewind/objects/skeleton_preview.tscn').write_text(preview)
print(json.dumps({'idle_height': idle_height, 'scale': scale, 'height_ratio': 2}))
