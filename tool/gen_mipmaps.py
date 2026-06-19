"""Regenerate Android launcher mipmap PNGs from assets/icon/*.png (run once)."""
from PIL import Image, ImageDraw

BASE = 'android/app/src/main/res'
icon = Image.open('assets/icon/icon.png').convert('RGBA')
fg = Image.open('assets/icon/icon_foreground.png').convert('RGBA')

launcher = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
foreground = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432}

for d, s in launcher.items():
    sq = icon.resize((s, s), Image.LANCZOS)
    sq.save(f'{BASE}/mipmap-{d}/ic_launcher.png')
    # circular variant
    mask = Image.new('L', (s, s), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, s - 1, s - 1], fill=255)
    rnd = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    rnd.paste(sq, (0, 0), mask)
    rnd.save(f'{BASE}/mipmap-{d}/ic_launcher_round.png')

for d, s in foreground.items():
    fg.resize((s, s), Image.LANCZOS).save(f'{BASE}/mipmap-{d}/ic_launcher_foreground.png')

print('mipmaps regenerated')
