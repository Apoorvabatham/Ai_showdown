"""Builds the character review boards under docs/reviews/ (not shipped)."""
import base64
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

root = Path(__file__).resolve().parent.parent
out = root / "docs" / "reviews"
out.mkdir(parents=True, exist_ok=True)
font_path = root / "tools" / "fonts" / "Inter-SemiBold.otf"


def font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(font_path), size) if font_path.exists() else ImageFont.load_default()


def data_uri(path: Path) -> str:
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode("ascii")


roster = Image.open(root / "docs" / "screenshots" / "roster.jpg").convert("RGB")
ids = ["ram", "tesla", "dario", "zuckerbot", "jensen", "yann", "geoff", "sundar", "donald", "xi", "algorithm"]
names = ["Ram Altman", "tesla man", "Dario Amoday", "Mark Zuckerbot", "Jensen Wong", "Yann LeCant",
         "Geoff Hintoff", "Sundar Pickai", "Donald Tarrif", "Xi Winping", "AGI"]

# --- Donald board -------------------------------------------------------------
x = 8 * 300
front = roster.crop((x, 0, x + 300, 560)).resize((600, 1120), Image.LANCZOS)
side = roster.crop((x, 560, x + 300, 1120)).resize((600, 1120), Image.LANCZOS)
head = roster.crop((x, 1120, x + 300, 1420)).resize((600, 600), Image.LANCZOS)
portrait = Image.open(root / "assets" / "ui" / "portraits" / "donald.png").convert("RGB").resize((600, 600), Image.LANCZOS)

board = Image.new("RGB", (1600, 1300), (22, 24, 30))
d = ImageDraw.Draw(board)
d.text((40, 24), "DONALD TARRIF  ·  likeness review", font=font(38), fill=(240, 240, 245))
d.text(
    (40, 74),
    "Age 80 · round full face, jowls, squint, big swept blond hair · lean-back stance, belly",
    font=font(17),
    fill=(160, 166, 180),
)
board.paste(front, (40, 120))
board.paste(side, (660, 120))
board.paste(head, (40, 780))
board.paste(portrait, (660, 780))
for xy, text in [((40, 1090), "front"), ((660, 1090), "side"), ((40, 1240), "close-up"), ((660, 1240), "in-game portrait")]:
    d.text(xy, text, font=font(22), fill=(200, 205, 215))
board.save(out / "donald_review_board.png")

# --- Roster contact sheet ----------------------------------------------------
cell_w, cell_h = 420, 500
cols = 4
rows = (len(ids) + cols - 1) // cols
sheet = Image.new("RGB", (cell_w * cols, cell_h * rows), (20, 22, 28))
sd = ImageDraw.Draw(sheet)
for i, (fighter_id, name) in enumerate(zip(ids, names)):
    col = i % cols
    row = i // cols
    px, py = col * cell_w, row * cell_h
    p = Image.open(root / "assets" / "ui" / "portraits" / f"{fighter_id}.png").convert("RGB")
    p.thumbnail((360, 360), Image.LANCZOS)
    sheet.paste(p, (px + (cell_w - p.width) // 2, py + 26))
    sd.text((px + 30, py + 400), name, font=font(28), fill=(240, 240, 245))
    sd.text((px + 30, py + 440), f"id: {fighter_id}", font=font(18), fill=(140, 146, 160))
sheet.save(out / "roster_contact_sheet.png")

# --- HTML review page --------------------------------------------------------
notes = [
    ("Ram Altman", "Hair reads as a side-part rather than the short buzz cut in the notes; tee carries a real OpenAI-style mark; collar edge is rough."),
    ("tesla man", "Hair is a tall quiff rather than a swept-back cut; otherwise the silhouette is distinct."),
    ("Dario Amoday", "Curly mop covers the eyes and glasses — the face is unreadable in game and in the portrait."),
    ("Mark Zuckerbot", "Caesar cut and grey V-neck; the hand-off notes call for tight curls and a hoodie."),
    ("Jensen Wong", "Strongest likeness. Glasses lenses read almost opaque white in the render."),
    ("Yann LeCant", "Hair reads black, not salt-and-pepper; rectangular glasses fit, but lenses are milky."),
    ("Geoff Hintoff", "Good: stooped elder build, silver hair, oatmeal cardigan all read clearly."),
    ("Sundar Pickai", "Skin reads pale rather than warm; tee print is hidden by the guard pose; glasses lenses milky."),
    ("Donald Tarrif", "Blond pomp is too tall and yellow, with a dark back patch; jowls/age could be stronger; collar and shirt edges are rough."),
    ("Xi Winping", "Hair is a tall black pomp rather than the combed-back part; the Zhongshan suit details are hard to read at game distance."),
    ("AGI", "Good: clean synthetic silhouette, cyan visor and conduits read well."),
]
notes_html = "".join(f"<li><b>{n}</b> — {t}</li>" for n, t in notes)
html = f"""<!doctype html>
<html><head><meta charset="utf-8"><title>AI Showdown character review</title>
<style>
body {{ background:#14161c; color:#e9eaf0; font-family:Inter,system-ui,sans-serif; margin:32px; }}
h1 {{ font-size:30px; margin:0 0 4px; }} h2 {{ font-size:20px; margin:36px 0 12px; }}
p, li {{ color:#a7adbd; max-width:1200px; line-height:1.55; }}
img {{ max-width:100%; border-radius:8px; display:block; margin:10px 0 24px; }}
.pill {{ display:inline-block; background:#233d2c; color:#8ff0b2; border-radius:999px; padding:2px 10px; font-size:13px; }}
li {{ margin-bottom:6px; }} b {{ color:#e9eaf0; }}
</style></head><body>
<h1>AI Showdown character review</h1>
<p><span class="pill">Fresh renders</span> &nbsp;Portraits and the model sheet were re-rendered from the current <code>data/characters/*.tres</code> files, so these are the real in-game looks.</p>
<h2>Donald Tarrif</h2>
<img src="{data_uri(out / 'donald_review_board.png')}" alt="Donald Tarrif review board">
<h2>Whole roster</h2>
<img src="{data_uri(out / 'roster_contact_sheet.png')}" alt="Roster contact sheet">
<h2>What I see</h2>
<ul>{notes_html}</ul>
</body></html>"""
(out / "character_review.html").write_text(html, encoding="utf-8")
print(out / "character_review.html")
