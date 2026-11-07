"""Check the generated fixture artwork in all seven browser captures.

Opt-in evidence check, using only Python's standard library. These coordinates
belong to the 1x viewport fixture produced by prepare-obsidian-review.py; this
does not assert colors or artwork for real user content.
"""
from pathlib import Path
import struct
import zlib

def png_pixels(path):
    raw = path.read_bytes()
    pos, compressed = 8, b''
    while pos < len(raw):
        size = struct.unpack('>I', raw[pos:pos+4])[0]
        kind, data = raw[pos+4:pos+8], raw[pos+8:pos+8+size]
        if kind == b'IHDR':
            width, height, depth, color, _, _, interlace = struct.unpack('>IIBBBBB', data)
        if kind == b'IDAT':
            compressed += data
        pos += size + 12
    assert depth == 8 and color in (2, 6) and interlace == 0
    channels = 3 if color == 2 else 4
    stride, decoded, rows = width * channels, zlib.decompress(compressed), []
    def paeth(a, b, c):
        p = a + b - c
        distances = [abs(p-a), abs(p-b), abs(p-c)]
        return [a, b, c][distances.index(min(distances))]
    for y in range(height):
        line = decoded[y*(stride+1):(y+1)*(stride+1)]
        mode, row = line[0], bytearray(line[1:])
        for x in range(stride):
            a = row[x-channels] if x >= channels else 0
            b = rows[y-1][x] if y else 0
            c = rows[y-1][x-channels] if y and x >= channels else 0
            row[x] = (row[x] + [0, a, b, (a+b)//2, paeth(a,b,c)][mode]) & 255
        rows.append(row)
    return width, height, channels, rows

for width in [320, 390, 430, 768, 1024, 1280, 1440]:
    path = Path(f'build/obsidian-review/player-{width}.png')
    w, h, channels, rows = png_pixels(path)
    # Use only the central artwork area, never metadata/controls. The fixture
    # PNG has many cyan ring pixels; a note/error placeholder has very few.
    nav = 224 if width >= 1100 else 80
    available = width - nav
    if width >= 768 and available >= 850:
        left, top, size = nav + (available - min(available - 48, 1120))/2, 156, min(available*.43, 460)
    elif width >= 768:
        left, top, size = (width+80-360)/2, 156, 360
    else:
        left, top, size = 24, 80, min(width-48, 360)
    count = 0
    for y in range(int(top+size*.15), min(h,int(top+size*.85))):
        for x in range(int(left+size*.15), min(w,int(left+size*.85))):
            i=x*channels
            red, green, blue = rows[y][i:i+3]
            count += red > 100 and green > 140 and blue > 170
    assert count > 400, f'{width}px: actual artwork missing ({count} ring pixels)'
    print(f'{width}px: decoded artwork present ({count} ring pixels)')
