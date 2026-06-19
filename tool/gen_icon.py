"""Generates Sangam launcher icon PNGs (run once; not part of the app)."""
import math
from PIL import Image, ImageDraw

SS = 2048          # supersample size for smooth edges
OUT = 1024         # final size


def hex2rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lerp(a, b, t):
    return int(a + (b - a) * t)


def diagonal_gradient(size, c1, c2):
    # Build small then upscale (smooth + fast).
    small = 64
    g = Image.new('RGB', (small, small))
    px = g.load()
    for y in range(small):
        for x in range(small):
            t = (x + y) / (2 * (small - 1))
            px[x, y] = (lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t))
    return g.resize((size, size), Image.LANCZOS)


def draw_mark(draw, cx, cy, R, color=(255, 255, 255, 255)):
    sw = R * 0.30
    rr = sw / 2
    pts = []
    for ang in (-90, 150, 30):
        a = math.radians(ang)
        pts.append((cx + R * math.cos(a), cy + R * math.sin(a)))
    # streams (thick lines with round caps)
    for (x, y) in pts:
        draw.line([(x, y), (cx, cy)], fill=color, width=int(sw))
        draw.ellipse([x - rr, y - rr, x + rr, y + rr], fill=color)
        draw.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=color)
    # source dots
    dr = R * 0.22
    for (x, y) in pts:
        draw.ellipse([x - dr, y - dr, x + dr, y + dr], fill=color)
    # central confluence node
    cr = R * 0.34
    draw.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=color)


# ── Full icon (gradient squircle + white mark) ──
icon = Image.new('RGBA', (SS, SS), (0, 0, 0, 0))
grad = diagonal_gradient(SS, hex2rgb('#6366F1'), hex2rgb('#4338CA')).convert('RGBA')
mask = Image.new('L', (SS, SS), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, SS - 1, SS - 1], radius=int(SS * 0.225), fill=255)
icon.paste(grad, (0, 0), mask)
draw_mark(ImageDraw.Draw(icon), SS / 2, SS / 2, SS * 0.27)
icon.resize((OUT, OUT), Image.LANCZOS).save('assets/icon/icon.png')

# ── Adaptive foreground (transparent + white mark, inside safe zone) ──
fg = Image.new('RGBA', (SS, SS), (0, 0, 0, 0))
draw_mark(ImageDraw.Draw(fg), SS / 2, SS / 2, SS * 0.205)
fg.resize((OUT, OUT), Image.LANCZOS).save('assets/icon/icon_foreground.png')

print('icons written')
