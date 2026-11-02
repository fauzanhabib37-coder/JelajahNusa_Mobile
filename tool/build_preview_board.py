"""Combine actual Flutter widget captures; requires Pillow (preview tooling only)."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT = Path(__file__).resolve().parents[1]
font = ROOT / 'assets/fonts/NusaSans.ttf'
serif = ROOT / 'assets/fonts/NusaSerif.ttf'
board = Image.new('RGB', (1800, 1800), '#E4EAE0')
d = ImageDraw.Draw(board)
d.text((50, 30), 'JelajahNusa', font=ImageFont.truetype(serif, 46), fill='#426B50')
d.text((50, 100), 'Pratinjau widget Flutter · data contoh · 31 Oktober 2026', font=ImageFont.truetype(font, 18), fill='#6A786E')
for i, p in enumerate(sorted((ROOT / 'design/runtime/screens').glob('*.png'))):
    x, y = 50 + (i % 5) * 350, 200 + (i // 5) * 770
    im = Image.open(p).resize((312, 675), Image.Resampling.LANCZOS)
    mask = Image.new('L', im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 311, 674), radius=24, fill=255)
    board.paste(im, (x, y), mask)
    d.text((x, y - 36), p.stem.replace('_', ' ').upper(), font=ImageFont.truetype(font, 14), fill='#426B50')
d.text((50, 1710), 'Akun lokal · 3 daerah · 9 materi · 45 soal · Flutter / Dart', font=ImageFont.truetype(font, 18), fill='#23372C')
board.save(ROOT / 'design/runtime/JelajahNusa_Flutter_Preview.png', optimize=True)
