"""Printed T-shirts: draws a chest print into a fighter's outfit texture.

The generated outfits keep the base body's UVs, so a print is placed on the chest in body
coordinates (metres, x across, y up) and mapped into texture space with a polynomial fitted
to the chest's own vertices (assets/characters/aged/face_uv.json, written by
tools/build_aged_skins.gd). Output: assets/characters/prints/T_<id>_<name>.png, used by
CharacterData.outfit_textures (the outfit slot's albedo; FighterModel). Designs are
original parody artwork: no real logos.

Run: python3 tools/build_prints.py   (needs Pillow and numpy)
"""
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "tools", "fonts", "InterDisplay-BlackItalic.otf")
SIZE = 2048
PX_PER_M = 2400  # design resolution


def inverse_fit(chest):
    """Cubic map (u, v) -> (x, y) over the chest front."""
    c = np.array(chest)
    uv, xy = c[:, 3:5], c[:, 0:2]
    terms = lambda u, v: np.stack([np.ones_like(u), u, v, u * u, u * v, v * v, u ** 3, u * u * v, u * v * v, v ** 3], -1)
    coef, *_ = np.linalg.lstsq(terms(uv[:, 0], uv[:, 1]), xy, rcond=None)
    return lambda u, v: terms(u, v) @ coef


def occupy_mars(width_m=0.27):
    """"OCCUPY MARS" over a little rocket and a red planet (an original parody design)."""
    W, H = int(width_m * PX_PER_M), int(width_m * 0.72 * PX_PER_M)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, int(H * 0.22))
    for text, y in (("OCCUPY", 0.02), ("MARS", 0.27)):
        w = d.textlength(text, font=font)
        d.text(((W - w) / 2, H * y), text, font=font, fill=(245, 245, 245, 255))
    # Mars: an orange disc with darker bands, lower right; a rocket rising, lower left.
    cx, cy, r = W * 0.88, H * 0.36, H * 0.11
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(214, 92, 44, 255))
    for k, dy in enumerate((-0.35, 0.1, 0.45)):
        d.ellipse([cx - r * 0.8, cy + dy * r - r * 0.12, cx + r * (0.3 + 0.2 * k), cy + dy * r + r * 0.1], fill=(170, 64, 30, 255))
    rx, ry, rh = W * 0.1, H * 0.34, H * 0.36
    d.polygon([(rx, ry - rh * 0.5), (rx + rh * 0.12, ry - rh * 0.25), (rx + rh * 0.12, ry + rh * 0.3),
               (rx - rh * 0.12, ry + rh * 0.3), (rx - rh * 0.12, ry - rh * 0.25)], fill=(235, 235, 235, 255))
    d.polygon([(rx - rh * 0.12, ry + rh * 0.1), (rx - rh * 0.25, ry + rh * 0.35), (rx - rh * 0.12, ry + rh * 0.3)], fill=(235, 235, 235, 255))
    d.polygon([(rx + rh * 0.12, ry + rh * 0.1), (rx + rh * 0.25, ry + rh * 0.35), (rx + rh * 0.12, ry + rh * 0.3)], fill=(235, 235, 235, 255))
    d.ellipse([rx - rh * 0.05, ry - rh * 0.12, rx + rh * 0.05, ry - rh * 0.02], fill=(40, 40, 40, 255))
    d.polygon([(rx - rh * 0.08, ry + rh * 0.3), (rx + rh * 0.08, ry + rh * 0.3), (rx, ry + rh * 0.55)], fill=(255, 160, 40, 255))
    return img, width_m, width_m * 0.72


def nvidia(width_m=0.10):
    """NVIDIA logo: green spiral/eye emblem over NVIDIA text."""
    W = int(width_m * PX_PER_M)
    H = int(width_m * 1.05 * PX_PER_M)
    SS = 2
    sw, sh = W * SS, H * SS
    img = Image.new("RGBA", (sw, sh), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    green = (118, 185, 0, 255)
    light_green = (150, 215, 20, 255)
    white = (248, 248, 248, 255)

    cx, cy = sw * 0.5, sh * 0.38

    # 1. Outer green swoosh
    r1 = sw * 0.34
    d.arc([cx - r1, cy - r1 * 0.8, cx + r1, cy + r1 * 0.8], start=180, end=380, fill=green, width=int(sw * 0.065))

    # 2. Middle green swoosh
    r2 = r1 * 0.74
    d.arc([cx - r2 * 0.9, cy - r2 * 0.75, cx + r2 * 1.1, cy + r2 * 0.75], start=190, end=385, fill=green, width=int(sw * 0.055))

    # 3. Inner green swoosh
    r3 = r2 * 0.70
    d.arc([cx - r3 * 0.8, cy - r3 * 0.7, cx + r3 * 1.15, cy + r3 * 0.7], start=200, end=390, fill=light_green, width=int(sw * 0.045))

    # 4. Central pupil / iris
    pr_x, pr_y = sw * 0.065, sh * 0.055
    pcx, pcy = cx + sw * 0.02, cy + sh * 0.01
    d.ellipse([pcx - pr_x, pcy - pr_y, pcx + pr_x, pcy + pr_y], fill=white)
    d.ellipse([pcx - pr_x * 0.35, pcy - pr_y * 0.8, pcx + pr_x * 0.35, pcy + pr_y * 0.8], fill=(20, 20, 22, 255))

    # 5. Bottom eye waterline
    d.arc([cx - r1 * 0.75, cy - r1 * 0.2, cx + r1 * 0.85, cy + r1 * 0.7], start=20, end=160, fill=green, width=int(sw * 0.04))

    # Text: "NVIDIA"
    font_size = int(sw * 0.17)
    font = ImageFont.truetype(FONT, font_size)
    text = "NVIDIA"
    tw = d.textlength(text, font=font)
    d.text(((sw - tw) / 2, sh * 0.73), text, font=font, fill=white)

    res = img.resize((W, H), Image.Resampling.LANCZOS)
    return res, width_m, width_m * 1.05


# id -> (output name, base colour (0..1), design, centre (x, y) on the chest, metres)
PRINTS = {
    "tesla": ("tee", (0.05, 0.05, 0.06), occupy_mars, (0.0, 1.355)),
    "jensen": ("tee", (0.12, 0.12, 0.13), nvidia, (0.0, 1.365)),
}


def write_import(path):
    base = os.path.join(ROOT, "assets", "characters", "base", "T_Superhero_Male_Light.png.import")
    text = open(base).read()
    params = text[text.index("[params]"):]
    res = "res://" + os.path.relpath(path, ROOT).replace(os.sep, "/")
    with open(path + ".import", "w") as f:
        f.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[deps]\n\nsource_file="%s"\n\n' % res + params)


def build(fid, name, colour, design, centre, to_xy):
    base = np.ones((SIZE, SIZE, 3), np.float32) * np.array(colour) * 255
    art, w_m, h_m = design()
    art = np.asarray(art, np.float32) / 255.0
    # Every texture pixel of the chest area, mapped back onto the chest and the design.
    full_u, full_v = np.meshgrid(np.arange(int(0.02 * SIZE), int(0.25 * SIZE)), np.arange(int(0.46 * SIZE), int(0.66 * SIZE)))
    fxy = to_xy((full_u.ravel() + 0.5) / SIZE, (full_v.ravel() + 0.5) / SIZE)
    ax = ((fxy[:, 0] - (centre[0] - w_m / 2)) / w_m * art.shape[1]).astype(int)
    ay = (((centre[1] + h_m / 2) - fxy[:, 1]) / h_m * art.shape[0]).astype(int)
    ok = (ax >= 0) & (ax < art.shape[1]) & (ay >= 0) & (ay < art.shape[0])
    src = art[ay[ok], ax[ok]]
    a = src[:, 3:4]
    tx, ty = full_u.ravel()[ok], full_v.ravel()[ok]
    base[ty, tx] = base[ty, tx] * (1 - a) + src[:, :3] * 255 * a
    out = Image.fromarray(np.clip(base, 0, 255).astype(np.uint8))
    path = os.path.join(ROOT, "assets", "characters", "prints", f"T_{fid}_{name}.png")
    out.save(path, optimize=True)
    write_import(path)
    print(f"{fid}: {os.path.relpath(path, ROOT)}")
    return path


def main():
    data = json.load(open(os.path.join(ROOT, "assets", "characters", "aged", "face_uv.json")))
    to_xy = inverse_fit(data["chest"])
    for fid, (name, colour, design, centre) in PRINTS.items():
        build(fid, name, colour, design, centre, to_xy)


if __name__ == "__main__":
    main()
