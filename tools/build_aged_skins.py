"""Step 2 of the age pass: paints each AI Showdown fighter's age into their skin texture.

Reads assets/characters/aged/face_uv.json (tools/build_aged_skins.gd: the base face's
front vertices with UVs, its landmarks, and each fighter's age and skin) and writes
assets/characters/aged/T_<id>_skin.png. Lines are drawn on the face in 3D-ish face
coordinates (metres, x across, y up), mapped to the texture by a smooth polynomial fitted
to the face's own vertices, then painted as soft, anti-aliased creases: forehead lines,
a frown line, crow's feet, under-eye bags, nasolabial and marionette lines, neck lines,
and age spots from about 70. Strength grows from age 35 to full at 82.

Run: python3 tools/build_aged_skins.py [<id> ...]   (needs Pillow and numpy)
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AGED = os.path.join(ROOT, "assets", "characters", "aged")
YOUNG, OLD = 35.0, 82.0
SS = 2  # supersampling for the stroke layer


def fit(face):
    """Least-squares cubic map (x, y) -> (u, v) over the front of the face."""
    f = np.array(face)
    x, y, uv = f[:, 0], f[:, 1], f[:, 3:5]
    terms = lambda x, y: np.stack([np.ones_like(x), x, y, x * x, x * y, y * y, x ** 3, x * x * y, x * y * y, y ** 3], -1)
    keep = np.ones(len(x), bool)
    for _ in range(6):  # drop vertices from other UV islands (ears, lips' inside, seams)
        coef, *_ = np.linalg.lstsq(terms(x[keep], y[keep]), uv[keep], rcond=None)
        res = np.linalg.norm(terms(x, y) @ coef - uv, axis=1)
        keep = res < max(np.median(res[keep]) * 4, 0.002)
    err = np.percentile(res[keep], 95)
    return (lambda x, y: terms(np.asarray(x, float), np.asarray(y, float)) @ coef), (err, keep.sum(), len(x))


def strokes(L, age):
    k = np.clip((age - YOUNG) / (OLD - YOUNG), 0, 1)
    ex, ey, _ = L["eye"]
    r, seam, corner = L["eye_radius"], L["seam"], L["corner"]
    out = []  # (points, width in m, strength)
    t = np.linspace(0, 1, 40)
    for i, dy in enumerate([0.03, 0.041, 0.052]):  # forehead lines, wavy arcs
        xs = np.linspace(-0.045 + i * 0.004, 0.045 - i * 0.004, 40)
        ys = ey + dy + 0.003 * (1 - (xs / 0.045) ** 2) + 0.0008 * np.sin(xs * 260 + i)
        out.append((np.stack([xs, ys], -1), 0.0016, 0.55 * k))
    for s in (-1, 1):  # frown lines
        out.append((np.stack([s * np.linspace(0.0055, 0.0045, 10), np.linspace(ey + 0.01, ey + 0.026, 10)], -1), 0.0012, 0.5 * k))
    for s in (-1, 1):
        cx = s * ex
        for a in (-0.5, -0.1, 0.35):  # crow's feet
            start = np.array([cx + s * r * 1.3, ey + a * r * 0.7])
            d = np.array([s, a * 0.9]); d /= np.linalg.norm(d)
            out.append((start + np.outer(np.linspace(0, 0.0075, 10), d), 0.0013, 0.4 * k))
        for depth, w, st in ((1.15, 0.0018, 0.5), (1.65, 0.0024, 0.3)):  # bags under the eyes
            xs = np.linspace(-r * 0.75, r * 1.05, 30)
            ys = ey - r * depth - 0.0045 * np.sin((xs + r * 0.75) / (r * 1.8) * np.pi)
            out.append((np.stack([cx + s * xs, ys], -1), w, st * k))
        # nasolabial fold: nose wing round to beside the mouth corner
        xs = s * (0.02 + (corner + 0.01 - 0.02) * t + 0.007 * np.sin(t * np.pi))
        ys = (ey - 0.044) + (seam - 0.008 - (ey - 0.044)) * t
        out.append((np.stack([xs, ys], -1), 0.0022, 0.7 * k))
        # marionette line
        out.append((np.stack([s * (corner + 0.004 + 0.003 * t), seam - 0.004 - 0.028 * t], -1), 0.0018, 0.5 * k))
    for i in range(2):  # neck lines
        xs = np.linspace(-0.045, 0.045, 30)
        out.append((np.stack([xs, seam - 0.105 - i * 0.02 + 0.004 * np.cos(xs / 0.045 * np.pi / 2)], -1), 0.0018, 0.35 * k))
    return out, k


def paint(skin_path, L, mapper, age, seed):
    img = Image.open(skin_path).convert("RGB")
    W, H = img.size
    lines, k = strokes(L, age)
    shade = Image.new("L", (W * SS, H * SS), 0)
    draw = ImageDraw.Draw(shade)
    px_per_m = None
    for pts, width, strength in lines:
        uv = mapper(pts[:, 0], pts[:, 1])
        if px_per_m is None:  # texture pixels per metre on the face
            a = mapper([0.0, 0.01], [L["eye"][1], L["eye"][1]])
            px_per_m = np.linalg.norm(a[1] - a[0]) * W / 0.01
        xy = [(u * W * SS, v * H * SS) for u, v in uv]
        draw.line(xy, fill=int(255 * min(strength, 1.0)), width=max(1, int(width * px_per_m * SS)), joint="curve")
    rng = np.random.default_rng(seed)
    spots = np.clip((age - 68) / 12, 0, 1)
    for _ in range(int(22 * spots)):
        p = mapper([rng.uniform(-0.06, 0.06)], [L["eye"][1] + rng.uniform(0.01, 0.075)])[0]
        rad = rng.uniform(0.0012, 0.0025) * px_per_m * SS
        draw.ellipse([p[0] * W * SS - rad, p[1] * H * SS - rad, p[0] * W * SS + rad, p[1] * H * SS + rad], fill=int(90 * spots))
    shade = shade.resize((W, H), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.6))
    a = np.asarray(shade, np.float32)[..., None] / 255.0
    base = np.asarray(img, np.float32)
    crease = base * np.array([0.7, 0.58, 0.54])  # darker, a touch warmer in the folds
    out = base * (1 - a) + crease * a
    # Older skin: slightly paler and less saturated.
    grey = out.mean(-1, keepdims=True)
    out = out + (grey - out) * 0.08 * k
    out = out + (np.array([250, 238, 228]) - out) * 0.05 * k
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))


def write_import(path):
    """Imports the texture like the base skins (VRAM compressed, mipmaps): Godot's
    defaults would keep it lossless, several MB more per fighter in the download."""
    base = os.path.join(ROOT, "assets", "characters", "base", "T_Superhero_Male_Light.png.import")
    text = open(base).read()
    params = text[text.index("[params]"):]
    res = "res://" + os.path.relpath(path, ROOT).replace(os.sep, "/")
    with open(path + ".import", "w") as f:
        f.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[deps]\n\nsource_file="%s"\n\n' % res + params)


def main():
    data = json.load(open(os.path.join(AGED, "face_uv.json")))
    mapper, err = fit(data["face"])
    print("face uv fit (95th pct error, kept, total):", err)
    only = sys.argv[1:]
    for f in data["fighters"]:
        if only and f["id"] not in only:
            continue
        out = paint(f["skin"], data, mapper, float(f["age"]), abs(hash(f["id"])) % 2**32)
        path = os.path.join(AGED, "T_%s_skin.png" % f["id"])
        out.save(path, optimize=True)
        write_import(path)
        print(f"{f['id']:10s} age {f['age']} -> {os.path.relpath(path, ROOT)}")


if __name__ == "__main__":
    main()
