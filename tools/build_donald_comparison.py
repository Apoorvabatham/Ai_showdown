"""Builds a before/after comparison board for Donald Tarrif."""
import base64
import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parent.parent
out = root / "docs" / "reviews"
out.mkdir(parents=True, exist_ok=True)
font_path = root / "tools" / "fonts" / "Inter-SemiBold.otf"


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(font_path), size) if font_path.exists() else ImageFont.load_default()


before_portrait = Image.open(Path(os.environ["TEMP"]) / "donald_before.png").convert("RGB").resize((700, 700), Image.LANCZOS)
after_portrait = Image.open(root / "assets" / "ui" / "portraits" / "donald.png").convert("RGB").resize((700, 700), Image.LANCZOS)

# Before full-body crop from the saved full-roster sheet (index 8).
before_roster = Image.open(Path(os.environ["TEMP"]) / "roster_before.jpg").convert("RGB")
bx = 8 * 300
before_front = before_roster.crop((bx, 0, bx + 300, 560)).resize((520, 970), Image.LANCZOS)
before_side = before_roster.crop((bx, 560, bx + 300, 1120)).resize((520, 970), Image.LANCZOS)

after_roster = Image.open(root / "docs" / "screenshots" / "roster.jpg").convert("RGB")
# The model sheet currently contains only Donald; its cells are 300x560 and 300x300.
after_front = after_roster.crop((0, 0, 300, 560)).resize((520, 970), Image.LANCZOS)
after_side = after_roster.crop((0, 560, 300, 1120)).resize((520, 970), Image.LANCZOS)

board = Image.new("RGB", (2000, 1990), (20, 22, 28))
d = ImageDraw.Draw(board)
d.text((40, 24), "DONALD TARRIF  ·  before / after", font=font(38), fill=(240, 240, 245))
d.text((40, 74), "Neck proportions fixed, clean shirt collar and tie knot, softer jowls, heavier body and lower hairline.",
       font=font(18), fill=(160, 166, 180))
d.text((60, 120), "BEFORE", font=font(26), fill=(255, 190, 120))
d.text((1020, 120), "AFTER", font=font(26), fill=(140, 240, 170))
board.paste(before_portrait, (40, 160))
board.paste(after_portrait, (1000, 160))
d.text((60, 885), "portrait", font=font(20), fill=(190, 195, 210))
d.text((1020, 885), "portrait", font=font(20), fill=(190, 195, 210))
board.paste(before_front, (40, 930))
board.paste(before_side, (580, 930))
board.paste(after_front, (1000, 930))
board.paste(after_side, (1540, 930))
d.text((60, 1930), "front", font=font(20), fill=(190, 195, 210))
d.text((600, 1930), "side", font=font(20), fill=(190, 195, 210))
d.text((1020, 1930), "front", font=font(20), fill=(190, 195, 210))
d.text((1560, 1930), "side", font=font(20), fill=(190, 195, 210))
board.save(out / "donald_before_after.png")

# Simple HTML wrapper for the preview pane.
def data_uri(path: Path) -> str:
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode("ascii")

html = f"""<!doctype html>
<html><head><meta charset="utf-8"><title>Donald Tarrif review</title>
<style>body{{background:#14161c;color:#e9eaf0;font-family:Inter,system-ui,sans-serif;margin:32px}}
img{{max-width:100%;border-radius:8px;display:block;margin:12px 0 24px}}
p{{color:#a7adbd;max-width:1200px;line-height:1.5}}</style></head><body>
<h1>Donald Tarrif — before / after</h1>
<p>Latest pass: neck rebuilt to a natural proportion (it was forcing through the collar), shirt collar and tie knot cleaned up so nothing pokes through the throat, jowls softened into the jaw, body still heavy, hairline lower. Check the neck, collar and tie first, then tell me what still reads wrong.</p>
<img src="{data_uri(out / 'donald_before_after.png')}" alt="Donald before and after">
</body></html>"""
(out / "donald_review.html").write_text(html, encoding="utf-8")
print(out / "donald_review.html")
