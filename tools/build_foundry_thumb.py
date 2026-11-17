"""Generates the 640x360 RGBA thumbnail for the GPU Foundry stage.
Produces assets/ui/stages/foundry.png matching the cleanroom fab theme.
"""
import math
import os
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_PATH = os.path.join(ROOT, "assets", "ui", "stages", "foundry.png")
FONT_DIR = os.path.join(ROOT, "tools", "fonts")
INTER_BLACK = os.path.join(FONT_DIR, "InterDisplay-BlackItalic.otf")
INTER_SEMI = os.path.join(FONT_DIR, "Inter-SemiBold.otf")

W, H = 640, 360

def build_foundry_thumbnail() -> None:
    # 1. Base image canvas
    img = Image.new("RGBA", (W, H), (14, 18, 24, 255))
    draw = ImageDraw.Draw(img)

    # Cleanroom background gradient (dark industrial ceiling to cleanroom wall)
    for y in range(H):
        t = y / float(H)
        if t < 0.55: # Ceiling & upper cleanroom wall
            r = int(10 + t * 25)
            g = int(14 + t * 35)
            b = int(22 + t * 50)
        else: # Lower cleanroom wall & floor transition
            r = int(24 + (t - 0.55) * 60)
            g = int(32 + (t - 0.55) * 70)
            b = int(45 + (t - 0.55) * 85)
        draw.line([(0, y), (W, y)], fill=(r, g, b, 255))

    # 2. Cleanroom modular wall partitions (back wall)
    horizon_y = 205
    wall_top = 70
    draw.rectangle([(20, wall_top), (W - 20, horizon_y)], fill=(32, 40, 52, 255), outline=(50, 62, 78, 255), width=2)
    # Vertical partition seams
    for x in range(40, W - 20, 48):
        draw.line([(x, wall_top), (x, horizon_y)], fill=(45, 56, 70, 255), width=2)
        # Partition rivet / filter grid dots
        for ry in range(wall_top + 12, horizon_y, 24):
            draw.point([(x, ry)], fill=(70, 85, 105, 255))

    # HEPA filter units across wall top
    for x in range(24, W - 24, 36):
        draw.rectangle([(x, wall_top + 4), (x + 30, wall_top + 28)], fill=(22, 28, 38, 255), outline=(42, 52, 68, 255))
        draw.line([(x + 2, wall_top + 16), (x + 28, wall_top + 16)], fill=(35, 45, 60, 255))

    # 3. Cleanroom floor with perspective grid
    floor_surface = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    floor_draw = ImageDraw.Draw(floor_surface)
    
    # Floor base fill
    floor_draw.rectangle([(0, horizon_y), (W, H)], fill=(28, 34, 44, 255))
    
    # Horizontal grid lines (getting closer together towards horizon)
    for i in range(16):
        fy = int(horizon_y + (H - horizon_y) * (math.pow(i / 15.0, 1.8)))
        floor_draw.line([(0, fy), (W, fy)], fill=(48, 60, 76, 180), width=1)

    # Perspective lines converging to center horizon (W/2, horizon_y - 20)
    vp_x, vp_y = W // 2, horizon_y - 30
    for x in range(-120, W + 140, 32):
        floor_draw.line([(vp_x, vp_y), (x, H)], fill=(45, 58, 75, 160), width=1)

    # Glowing yellow ESD safety boundary box
    esd_glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    esd_draw = ImageDraw.Draw(esd_glow)
    esd_pts = [
        (130, horizon_y + 15),
        (510, horizon_y + 15),
        (590, H - 10),
        (50, H - 10)
    ]
    esd_draw.line([esd_pts[0], esd_pts[1], esd_pts[2], esd_pts[3], esd_pts[0]], fill=(255, 200, 30, 220), width=3)
    esd_blur = esd_glow.filter(ImageFilter.GaussianBlur(4))
    img.alpha_composite(floor_surface)
    img.alpha_composite(esd_blur)
    img.alpha_composite(esd_glow)

    # 4. EUV Photolithography Scanner Chamber (Centerpiece)
    scanner_w, scanner_h = 190, 130
    sc_x = (W - scanner_w) // 2
    sc_y = horizon_y - scanner_h + 10
    
    # Scanner housing (dark metallic chamfered monolith)
    draw.rectangle([(sc_x, sc_y), (sc_x + scanner_w, horizon_y + 10)], fill=(18, 22, 28, 255), outline=(65, 80, 100, 255), width=2)
    draw.rectangle([(sc_x + 8, sc_y - 8), (sc_x + scanner_w - 8, sc_y)], fill=(30, 38, 48, 255), outline=(55, 70, 90, 255))
    
    # Observation window (tinted amber UV glass)
    win_w, win_h = 120, 68
    win_x = (W - win_w) // 2
    win_y = sc_y + 18
    draw.rectangle([(win_x, win_y), (win_x + win_w, win_y + win_h)], fill=(45, 32, 10, 255), outline=(180, 140, 40, 255), width=2)

    # 13.5nm EUV Laser Aperture & Pulsing Core (Violet/Cyan Glow)
    euv_glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    euv_draw = ImageDraw.Draw(euv_glow)
    laser_cx, laser_cy = W // 2, win_y + win_h // 2 - 2
    
    # Outer violet/magenta corona
    for rad in range(48, 4, -4):
        alpha = int(140 * (1.0 - rad / 48.0))
        euv_draw.ellipse([(laser_cx - rad, laser_cy - rad), (laser_cx + rad, laser_cy + rad)], fill=(180, 50, 255, alpha))
    
    # Inner cyan/white core
    for rad in range(18, 2, -2):
        alpha = int(220 * (1.0 - rad / 18.0))
        euv_draw.ellipse([(laser_cx - rad, laser_cy - rad), (laser_cx + rad, laser_cy + rad)], fill=(100, 240, 255, alpha))
    euv_draw.ellipse([(laser_cx - 4, laser_cy - 4), (laser_cx + 4, laser_cy + 4)], fill=(255, 255, 255, 255))
    
    # Laser focus beam shooting down to wafer stage
    beam_w = 4
    for b_alpha, b_col in [(80, (190, 60, 255)), (180, (120, 240, 255)), (255, (255, 255, 255))]:
        euv_draw.line([(laser_cx, laser_cy), (laser_cx, horizon_y + 2)], fill=b_col + (b_alpha,), width=beam_w)
        beam_w = max(1, beam_w - 1)

    img.alpha_composite(euv_glow)

    # 5. Silicon Wafer & Load Port
    # Wafer pedestal / load port table
    port_w, port_h = 96, 32
    port_x = (W - port_w) // 2
    port_y = horizon_y - 12
    draw.rectangle([(port_x, port_y), (port_x + port_w, port_y + port_h)], fill=(25, 30, 38, 255), outline=(70, 85, 105, 255), width=1)
    
    # 300mm Silicon Wafer (iridescent circular disc with grid dies)
    wafer_cx, wafer_cy = W // 2, port_y + 4
    wafer_rx, wafer_ry = 38, 12 # Elliptical in perspective
    
    wafer_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    w_draw = ImageDraw.Draw(wafer_layer)
    # Wafer base (polished specular silicon)
    w_draw.ellipse([(wafer_cx - wafer_rx, wafer_cy - wafer_ry), (wafer_cx + wafer_rx, wafer_cy + wafer_ry)],
                   fill=(35, 75, 95, 255), outline=(120, 220, 240, 255), width=2)
    # Iridescent die matrix grid lines on the wafer
    for wx in range(wafer_cx - wafer_rx + 8, wafer_cx + wafer_rx - 6, 8):
        # Calculate ellipse height at this x
        dx = (wx - wafer_cx) / float(wafer_rx)
        if abs(dx) < 0.95:
            dy = wafer_ry * math.sqrt(1.0 - dx * dx)
            w_draw.line([(wx, wafer_cy - dy + 1), (wx, wafer_cy + dy - 1)], fill=(70, 160, 190, 160))
    for wy in range(int(wafer_cy - wafer_ry + 3), int(wafer_cy + wafer_ry - 2), 4):
        dy = (wy - wafer_cy) / float(wafer_ry)
        if abs(dy) < 0.95:
            dx = wafer_rx * math.sqrt(1.0 - dy * dy)
            w_draw.line([(wafer_cx - dx + 1, wy), (wafer_cx + dx - 1, wy)], fill=(70, 160, 190, 160))
    # Rainbow sheen across wafer
    sheen = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(sheen)
    s_draw.line([(wafer_cx - 24, wafer_cy - 4), (wafer_cx + 24, wafer_cy + 4)], fill=(255, 120, 220, 140), width=3)
    s_draw.line([(wafer_cx - 20, wafer_cy - 2), (wafer_cx + 20, wafer_cy + 2)], fill=(120, 255, 220, 180), width=2)
    wafer_layer.alpha_composite(sheen.filter(ImageFilter.GaussianBlur(2)))
    img.alpha_composite(wafer_layer)

    # 6. Overhead AMHS Monorail Track & FOUP Pods
    rail_y = 48
    draw.rectangle([(0, rail_y), (W, rail_y + 10)], fill=(38, 46, 58, 255), outline=(65, 80, 100, 255))
    draw.line([(0, rail_y + 5), (W, rail_y + 5)], fill=(100, 130, 160, 255), width=1)
    
    # 4 FOUP Carrier Pods suspended from the rail
    foup_xs = [90, 210, 430, 550]
    for fx in foup_xs:
        # Clamp hanger
        draw.rectangle([(fx + 14, rail_y + 10), (fx + 22, rail_y + 22)], fill=(45, 55, 70, 255))
        # FOUP body
        draw.rectangle([(fx, rail_y + 22), (fx + 36, rail_y + 54)], fill=(16, 20, 26, 255), outline=(55, 70, 88, 255), width=2)
        # Handle & lock clasp
        draw.rectangle([(fx + 8, rail_y + 26), (fx + 28, rail_y + 32)], fill=(32, 40, 52, 255))
        # Glowing green status LED
        draw.rectangle([(fx + 6, rail_y + 46), (fx + 30, rail_y + 50)], fill=(40, 240, 80, 255))

    # 7. Diagnostic Terminals & Racks on Flanks
    # Left Console
    draw.rectangle([(30, horizon_y - 65), (96, horizon_y + 15)], fill=(20, 25, 32, 255), outline=(60, 75, 95, 255), width=2)
    # Angled monitor display
    draw.rectangle([(38, horizon_y - 58), (88, horizon_y - 20)], fill=(8, 30, 36, 255), outline=(30, 180, 200, 255), width=1)
    # Screen lines (glow)
    for ly in range(horizon_y - 54, horizon_y - 22, 6):
        draw.line([(42, ly), (84, ly)], fill=(40, 220, 240, 200), width=1)

    # Right Console
    draw.rectangle([(W - 96, horizon_y - 65), (W - 30, horizon_y + 15)], fill=(20, 25, 32, 255), outline=(60, 75, 95, 255), width=2)
    draw.rectangle([(W - 88, horizon_y - 58), (W - 38, horizon_y - 20)], fill=(8, 30, 36, 255), outline=(30, 180, 200, 255), width=1)
    for ly in range(horizon_y - 54, horizon_y - 22, 6):
        draw.line([(W - 84, ly), (W - 42, ly)], fill=(40, 220, 240, 200), width=1)

    # 8. Cleanroom Technicians in Bunny Suits (Spectators)
    # White suits, cleanroom hood, visor goggles
    tech_coords = [
        (135, horizon_y - 10, 1.0),
        (185, horizon_y - 25, 0.85),
        (455, horizon_y - 25, 0.85),
        (505, horizon_y - 10, 1.0),
    ]
    for tx, ty, scale in tech_coords:
        bw = int(18 * scale)
        bh = int(46 * scale)
        hw = int(14 * scale)
        hh = int(16 * scale)
        
        # Body (capsule-like bunny suit)
        draw.ellipse([(tx - bw//2, ty - bh), (tx + bw//2, ty)], fill=(225, 230, 238, 255), outline=(150, 160, 175, 255))
        # Hooded head
        draw.ellipse([(tx - hw//2, ty - bh - hh + 4), (tx + hw//2, ty - bh + 6)], fill=(235, 240, 248, 255), outline=(160, 170, 185, 255))
        # Glowing cyan / amber cleanroom visor
        vw = int(12 * scale)
        vh = int(5 * scale)
        draw.rectangle([(tx - vw//2, ty - bh - hh + 8), (tx + vw//2, ty - bh - hh + 8 + vh)], fill=(40, 210, 245, 255))
        # Blue ESD nitrile gloves
        gw = int(6 * scale)
        draw.ellipse([(tx - bw//2 - 2, ty - bh//2), (tx - bw//2 + gw - 2, ty - bh//2 + gw)], fill=(40, 80, 180, 255))
        draw.ellipse([(tx + bw//2 - gw + 2, ty - bh//2), (tx + bw//2 + 2, ty - bh//2 + gw)], fill=(40, 80, 180, 255))

    # 9. Liquid Argon Cryogenic Exhaust Steam (plumes at outer edges)
    steam_glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    st_draw = ImageDraw.Draw(steam_glow)
    for sx in [18, W - 18]:
        for si in range(8):
            rad = 12 + si * 4
            sy = horizon_y - 20 - si * 14
            alpha = int(70 * (1.0 - si / 8.0))
            st_draw.ellipse([(sx - rad, sy - rad), (sx + rad, sy + rad)], fill=(190, 220, 255, alpha))
    img.alpha_composite(steam_glow.filter(ImageFilter.GaussianBlur(8)))

    # 10. Cleanroom Stage Lighting & Ambient Volumetric Glow
    lighting = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    l_draw = ImageDraw.Draw(lighting)
    # Warm ceiling cleanroom lamps
    l_draw.ellipse([(W//2 - 140, 10), (W//2 + 140, 150)], fill=(255, 240, 190, 35))
    # Cyan diagnostic sidelights
    l_draw.ellipse([(-20, horizon_y - 90), (140, horizon_y + 50)], fill=(40, 180, 255, 30))
    l_draw.ellipse([(W - 140, horizon_y - 90), (W + 20, horizon_y + 50)], fill=(40, 180, 255, 30))
    img.alpha_composite(lighting.filter(ImageFilter.GaussianBlur(16)))

    # 11. Subtle Vignette around border
    vignette = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    v_draw = ImageDraw.Draw(vignette)
    for b in range(24):
        alpha = int(120 * (1.0 - b / 24.0))
        v_draw.rectangle([(b, b), (W - 1 - b, H - 1 - b)], outline=(0, 0, 0, alpha))
    img.alpha_composite(vignette)

    # 12. Save thumbnail
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    img.save(OUT_PATH, "PNG")
    print(f"Generated {OUT_PATH} successfully ({W}x{H} RGBA).")

if __name__ == "__main__":
    build_foundry_thumbnail()
