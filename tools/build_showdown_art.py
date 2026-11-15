"""Builds AI Showdown's title art: assets/ui/logo.png (transparent), splash.png and
wallpaper.png (1920x1080) and icon.png / icon.ico.

The logo: "AI" in icy cyan over "SHOWDOWN" in hot magenta-to-orange, leaning forward,
with a dark outline, a chromatic (cyan/magenta) split and a glow. The splash and the
wallpaper put the roster lineup (tools/render_key_art.gd ->
assets/ui/source/key_art_fighters.png) on a dark neon grid; the splash adds the logo and
the parody disclaimer. Lettering: Inter Display (SIL OFL 1.1, tools/fonts/, kept out of
the game: only this tool uses it).

Run: python tools/build_showdown_art.py   (needs Pillow and numpy)
"""
import os

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI = os.path.join(ROOT, "assets", "ui")
FONT = os.path.join(ROOT, "tools", "fonts", "InterDisplay-BlackItalic.otf")
SMALL_FONT = os.path.join(ROOT, "tools", "fonts", "Inter-SemiBold.otf")
FIGHTERS = os.path.join(UI, "source", "key_art_fighters.png")
W, H = 1920, 1080
DISCLAIMER = "Parody. Not affiliated with or endorsed by any real person or company."
CYAN = np.array([90, 235, 255], np.float32)
MAGENTA = np.array([255, 60, 200], np.float32)
ORANGE = np.array([255, 170, 60], np.float32)


def text_mask(text: str, size: int, shear: float = 0.18) -> Image.Image:
    font = ImageFont.truetype(FONT, size)
    left, top, right, bottom = font.getbbox(text)
    w, h = right - left + 160, bottom - top + 120
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).text((80 - left, 60 - top), text, font=font, fill=255)
    return mask.transform(mask.size, Image.AFFINE, (1, shear, -shear * h * 0.5, 0, 1, 0), Image.BICUBIC)


def gradient_fill(mask: Image.Image, top: np.ndarray, bottom: np.ndarray) -> Image.Image:
    w, h = mask.size
    t = np.linspace(0.0, 1.0, h, dtype=np.float32)[:, None, None]
    rgb = top[None, None, :] * (1 - t) + bottom[None, None, :] * t
    rgb = np.broadcast_to(rgb, (h, w, 3))
    # A bright sheen across the upper third of the letters.
    sheen = np.clip(1.0 - np.abs(np.linspace(-1, 1, h, dtype=np.float32) + 0.35) * 3.0, 0, 1)[:, None, None] * 70
    rgb = np.clip(rgb + sheen, 0, 255).astype(np.uint8)
    img = Image.fromarray(np.ascontiguousarray(rgb), "RGB").convert("RGBA")
    img.putalpha(mask)
    return img


def styled_word(text: str, size: int, top: np.ndarray, bottom: np.ndarray) -> Image.Image:
    """Gradient letters with a chromatic split, a dark outline and a coloured glow."""
    mask = text_mask(text, size)
    pad = 60
    w, h = mask.size[0] + pad * 2, mask.size[1] + pad * 2
    base = Image.new("L", (w, h), 0)
    base.paste(mask, (pad, pad))
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow = base.filter(ImageFilter.GaussianBlur(26))
    glow_col = Image.new("RGBA", (w, h), tuple(int(c) for c in (top * 0.5 + bottom * 0.5)) + (0,))
    glow_col.putalpha(glow.point(lambda v: int(v * 0.85)))
    out.alpha_composite(glow_col)
    outline = base.filter(ImageFilter.MaxFilter(13))
    dark = Image.new("RGBA", (w, h), (8, 6, 20, 0))
    dark.putalpha(outline)
    out.alpha_composite(dark)
    shift = max(4, size // 55)
    for color, dx in ((CYAN, -shift), (MAGENTA, shift)):
        layer = Image.new("RGBA", (w, h), tuple(int(c) for c in color) + (0,))
        layer.putalpha(ImageChops.offset(base, dx, 0).point(lambda v: int(v * 0.8)))
        out.alpha_composite(layer)
    letters = gradient_fill(base, top, bottom)
    out.alpha_composite(letters)
    # Scanlines across the letters: a faint digital texture.
    lines = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(lines)
    for y in range(0, h, 6):
        d.line([(0, y), (w, y)], fill=60)
    scan = Image.new("RGBA", (w, h), (10, 0, 30, 0))
    scan.putalpha(ImageChops.multiply(lines, base))
    out.alpha_composite(scan)
    return out.crop(out.getbbox())


def build_logo() -> Image.Image:
    ai = styled_word("AI", 330, np.array([235, 255, 255], np.float32), CYAN * 0.85)
    show = styled_word("SHOWDOWN", 330, MAGENTA, ORANGE)
    gap = -40
    w = ai.width + gap + show.width
    h = max(ai.height, show.height)
    logo = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    logo.alpha_composite(ai, (0, (h - ai.height) // 2))
    logo.alpha_composite(show, (ai.width + gap, (h - show.height) // 2))
    return logo


def background() -> Image.Image:
    """Night-blue to violet, a glowing horizon and a neon grid floor in perspective."""
    y = np.linspace(0, 1, H, dtype=np.float32)[:, None]
    top = np.array([6, 6, 22], np.float32)
    mid = np.array([30, 12, 58], np.float32)
    horizon = 0.62
    t = np.clip(y / horizon, 0, 1)
    rgb = top * (1 - t[..., None]) + mid * t[..., None]
    rgb = np.broadcast_to(rgb, (H, W, 3)).copy()
    glow = np.exp(-((y - horizon) ** 2) / 0.0025)[..., None] * np.array([255, 70, 200], np.float32) * 0.55
    rgb += glow
    below = (y > horizon)[..., None]
    rgb = np.where(below, rgb * 0.55, rgb)
    img = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB").convert("RGBA")
    grid = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(grid)
    hy = int(H * horizon)
    vanish = (W // 2, hy - 40)
    for i in range(-24, 25):
        x = W // 2 + i * 150
        d.line([vanish, (W // 2 + (x - W // 2) * 3, H)], fill=(80, 230, 255, 90), width=2)
    for k in range(1, 14):
        yy = hy + int((H - hy) * (k / 13) ** 2.2)
        d.line([(0, yy), (W, yy)], fill=(80, 230, 255, 70 + k * 6), width=2)
    img.alpha_composite(grid.filter(ImageFilter.GaussianBlur(0.6)))
    # A few drifting "data" specks in the sky.
    rng = np.random.default_rng(5)
    sky = ImageDraw.Draw(img)
    for _ in range(140):
        x, yy = int(rng.random() * W), int(rng.random() * hy * 0.95)
        c = (120, 240, 255, int(60 + rng.random() * 120)) if rng.random() < 0.6 else (255, 90, 210, int(60 + rng.random() * 120))
        sky.rectangle([x, yy, x + 2, yy + 2], fill=c)
    return img


def fighters(scale: float, y_offset: int) -> Image.Image:
    lineup = Image.open(FIGHTERS).convert("RGBA")
    if scale != 1.0:
        lineup = lineup.resize((int(lineup.width * scale), int(lineup.height * scale)), Image.LANCZOS)
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow = Image.new("RGBA", lineup.size, (0, 0, 0, 0))
    shadow.putalpha(lineup.getchannel("A").filter(ImageFilter.GaussianBlur(18)).point(lambda v: int(v * 0.6)))
    x = (W - lineup.width) // 2
    layer.alpha_composite(shadow, (x, y_offset + 10))
    layer.alpha_composite(lineup, (x, y_offset))
    return layer


def caption(img: Image.Image, text: str, y: int, size: int, color, alpha: int = 230) -> None:
    font = ImageFont.truetype(SMALL_FONT, size)
    d = ImageDraw.Draw(img)
    w = d.textlength(text, font=font)
    x = (W - w) / 2
    d.text((x + 2, y + 2), text, font=font, fill=(0, 0, 0, 200))
    d.text((x, y), text, font=font, fill=color + (alpha,))


def main() -> None:
    logo = build_logo()
    logo.save(os.path.join(UI, "logo.png"))
    print("logo", logo.size)

    wallpaper = background()
    wallpaper.alpha_composite(fighters(1.05, 40))
    vignette = Image.new("L", (W, H), 0)
    ImageDraw.Draw(vignette).ellipse([-W * 0.2, -H * 0.3, W * 1.2, H * 1.3], fill=255)
    vignette = vignette.filter(ImageFilter.GaussianBlur(120))
    dark = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    dark.putalpha(ImageChops.invert(vignette).point(lambda v: int(v * 0.7)))
    wallpaper.alpha_composite(dark)
    wallpaper.convert("RGB").save(os.path.join(UI, "wallpaper.png"))

    splash = background()
    splash.alpha_composite(fighters(1.0, 70))
    small = logo.resize((1300, int(logo.height * 1300 / logo.width)), Image.LANCZOS)
    splash.alpha_composite(small, ((W - small.width) // 2, 40))
    caption(splash, "THE AI INDUSTRY SETTLES IT THE OLD-FASHIONED WAY", 70 + small.height - 10, 34, (200, 240, 255))
    caption(splash, DISCLAIMER, H - 44, 24, (235, 235, 245), 215)
    splash.convert("RGB").save(os.path.join(UI, "splash.png"))
    print("splash, wallpaper")

    icon = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    d = ImageDraw.Draw(icon)
    d.rounded_rectangle([16, 16, 496, 496], radius=96, fill=(14, 10, 34, 255), outline=(90, 235, 255, 255), width=10)
    ai = styled_word("AI", 300, np.array([235, 255, 255], np.float32), MAGENTA)
    ai = ai.resize((400, int(ai.height * 400 / ai.width)), Image.LANCZOS)
    icon.alpha_composite(ai, ((512 - ai.width) // 2, (512 - ai.height) // 2))
    icon.save(os.path.join(UI, "icon.png"))
    icon.save(os.path.join(UI, "icon.ico"), sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print("icon")


if __name__ == "__main__":
    main()
