"""Generate PWA icons for AI Tarot app."""
import struct
import zlib

def create_png(width, height, pixels):
    """Create a PNG file from raw RGBA pixel data."""
    def chunk(chunk_type, data):
        c = chunk_type + data
        crc = struct.pack('>I', zlib.crc32(c) & 0xFFFFFFFF)
        return struct.pack('>I', len(data)) + c + crc

    header = b'\x89PNG\r\n\x1a\n'
    ihdr = chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))

    raw = b''
    for y in range(height):
        raw += b'\x00'
        for x in range(width):
            idx = (y * width + x) * 4
            raw += bytes(pixels[idx:idx+4])

    idat = chunk(b'IDAT', zlib.compress(raw, 9))
    iend = chunk(b'IEND', b'')
    return header + ihdr + idat + iend

def draw_icon(size):
    """Draw tarot card icon."""
    pixels = [0] * (size * size * 4)
    cx, cy = size // 2, size // 2

    for y in range(size):
        for x in range(size):
            idx = (y * size + x) * 4
            # Background: dark purple gradient
            bg_r = int(10 + (26 - 10) * y / size)
            bg_g = int(10 + (10) * x / size)
            bg_b = int(26 + (42 - 26) * y / size)

            # Distance from center
            dx = (x - cx) / (size * 0.5)
            dy = (y - cy) / (size * 0.5)
            dist = (dx*dx + dy*dy) ** 0.5

            # Circular mask for maskable icon (safe zone)
            if dist > 0.95:
                pixels[idx] = bg_r
                pixels[idx+1] = bg_g
                pixels[idx+2] = bg_b
                pixels[idx+3] = 255
                continue

            # Card shape (rounded rectangle in center)
            card_w = size * 0.45
            card_h = size * 0.65
            card_left = cx - card_w / 2
            card_top = cy - card_h / 2
            card_right = card_left + card_w
            card_bottom = card_top + card_h
            corner_r = size * 0.04

            in_card = False
            if card_left + corner_r <= x <= card_right - corner_r and card_top <= y <= card_bottom:
                in_card = True
            elif card_left <= x <= card_right and card_top + corner_r <= y <= card_bottom - corner_r:
                in_card = True
            elif card_left <= x < card_left + corner_r and card_top <= y < card_top + corner_r:
                ddx = x - (card_left + corner_r)
                ddy = y - (card_top + corner_r)
                if ddx*ddx + ddy*ddy <= corner_r*corner_r:
                    in_card = True
            elif card_right - corner_r < x <= card_right and card_top <= y < card_top + corner_r:
                ddx = x - (card_right - corner_r)
                ddy = y - (card_top + corner_r)
                if ddx*ddx + ddy*ddy <= corner_r*corner_r:
                    in_card = True
            elif card_left <= x < card_left + corner_r and card_bottom - corner_r < y <= card_bottom:
                ddx = x - (card_left + corner_r)
                ddy = y - (card_bottom - corner_r)
                if ddx*ddx + ddy*ddy <= corner_r*corner_r:
                    in_card = True
            elif card_right - corner_r < x <= card_right and card_bottom - corner_r < y <= card_bottom:
                ddx = x - (card_right - corner_r)
                ddy = y - (card_bottom - corner_r)
                if ddx*ddx + ddy*ddy <= corner_r*corner_r:
                    in_card = True

            if in_card:
                # Card interior: dark purple with gold border
                edge_dist = min(x - card_left, card_right - x, y - card_top, card_bottom - y)
                border_w = size * 0.015

                if edge_dist <= border_w:
                    # Gold border
                    pixels[idx] = 241
                    pixels[idx+1] = 196
                    pixels[idx+2] = 15
                    pixels[idx+3] = 255
                else:
                    # Card face: deep purple
                    pixels[idx] = 44
                    pixels[idx+1] = 22
                    pixels[idx+2] = 84
                    pixels[idx+3] = 255

                    # Star/sparkle in center of card
                    star_cx = cx
                    star_cy = cy
                    sdx = abs(x - star_cx)
                    sdy = abs(y - star_cy)
                    star_size = size * 0.12

                    # Diamond shape for star
                    if sdx + sdy < star_size:
                        bright = 1.0 - (sdx + sdy) / star_size
                        pixels[idx] = int(155 + (241-155) * bright)
                        pixels[idx+1] = int(89 + (196-89) * bright)
                        pixels[idx+2] = int(182 + (15) * bright)
                        pixels[idx+3] = 255

                    # Small dots around star
                    for angle_i in range(4):
                        import math
                        angle = angle_i * math.pi / 2 + math.pi / 4
                        dot_x = star_cx + math.cos(angle) * star_size * 1.8
                        dot_y = star_cy + math.sin(angle) * star_size * 1.8
                        dot_dist = ((x - dot_x)**2 + (y - dot_y)**2) ** 0.5
                        if dot_dist < size * 0.015:
                            pixels[idx] = 241
                            pixels[idx+1] = 196
                            pixels[idx+2] = 15
                            pixels[idx+3] = 255
            else:
                # Background
                # Add subtle purple glow around card
                card_cx_dist = abs(x - cx) / (size * 0.5)
                card_cy_dist = abs(y - cy) / (size * 0.5)
                glow = max(0, 1.0 - (card_cx_dist**2 + card_cy_dist**2) ** 0.5)
                glow = glow ** 3

                pixels[idx] = int(bg_r + (155 - bg_r) * glow * 0.15)
                pixels[idx+1] = int(bg_g + (89 - bg_g) * glow * 0.15)
                pixels[idx+2] = int(bg_b + (182 - bg_b) * glow * 0.15)
                pixels[idx+3] = 255

    return pixels

import math  # needed for star dots

for sz in [192, 512]:
    print(f"Generating {sz}x{sz} icon...")
    px = draw_icon(sz)
    png_data = create_png(sz, sz, px)
    with open(f"icon-{sz}.png", "wb") as f:
        f.write(png_data)
    print(f"  Saved icon-{sz}.png ({len(png_data)} bytes)")

print("Done!")
