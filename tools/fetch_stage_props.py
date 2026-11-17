#!/usr/bin/env python3
"""
Downloads CC0 models from Kenney (shorepine/kenney mirror) and CC0 PBR textures from Poly Haven.
Places them in assets/stage_props/<stage>/ for use by scripts/stages/stage_retheme.gd.
"""

import os
import urllib.request
import json

BASE_KENNEY = "https://raw.githubusercontent.com/shorepine/kenney/main/3d"

KENNEY_FILES = {
    "mensa": [
        ("furniture", "chair.glb"),
        ("furniture", "chairRounded.glb"),
        ("furniture", "table.glb"),
        ("furniture", "tableRound.glb"),
        ("furniture", "kitchenBar.glb"),
        ("furniture", "kitchenBarEnd.glb"),
        ("furniture", "kitchenCoffeeMachine.glb"),
        ("furniture", "trashcan.glb"),
        ("furniture", "cardboardBoxClosed.glb"),
        ("furniture", "pottedPlant.glb"),
        ("furniture", "stoolBar.glb"),
        ("food", "plate.glb"),
        ("food", "plate-dinner.glb"),
        ("food", "cup-coffee.glb"),
        ("food", "bowl.glb"),
        ("food", "bottle-ketchup.glb"),
        ("food", "bottle-musterd.glb"),
    ],
    "server_farm": [
        ("space-station", "computer-screen.glb"),
        ("space-station", "computer-system.glb"),
        ("space-station", "computer-wide.glb"),
        ("space-station", "structure-panel.glb"),
        ("space-station", "structure-barrier.glb"),
        ("space-station", "display-wall.glb"),
        ("space-station", "container-tall.glb"),
        ("space-station", "container-wide.glb"),
        ("space-station", "floor-panel.glb"),
        ("space-station", "pipe.glb"),
        ("space-station", "pipe-bend.glb"),
    ],
    "senate": [
        ("furniture", "chairDesk.glb"),
        ("furniture", "desk.glb"),
        ("furniture", "deskCorner.glb"),
        ("furniture", "lampRoundTable.glb"),
        ("furniture", "laptop.glb"),
        ("furniture", "books.glb"),
        ("furniture", "bookcaseClosed.glb"),
        ("furniture", "bookcaseClosedWide.glb"),
        ("furniture", "bench.glb"),
        ("furniture", "speakerSmall.glb"),
        ("furniture", "plantSmall1.glb"),
    ],
    "foundry": [
        ("factory", "robot-arm-a.glb"),
        ("factory", "robot-arm-b.glb"),
        ("factory", "pipe-large.glb"),
        ("factory", "pipe-glass-large.glb"),
        ("factory", "machine.glb"),
        ("factory", "conveyor.glb"),
        ("factory", "catwalk-straight.glb"),
        ("factory", "catwalk-stairs.glb"),
        ("factory", "scanner-high.glb"),
        ("factory", "scanner-low.glb"),
        ("factory", "screen-panel-wide.glb"),
        ("factory", "screen-hanging-wide.glb"),
        ("factory", "warning-orange.glb"),
        ("factory", "box-large.glb"),
    ]
}

POLYHAVEN_TEXTURES = {
    "mensa": {
        "id": "floor_tiles_06",
        "files": [
            ("diff", "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/floor_tiles_06/floor_tiles_06_diff_1k.jpg"),
            ("nor", "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/floor_tiles_06/floor_tiles_06_nor_gl_1k.jpg"),
            ("rough", "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/floor_tiles_06/floor_tiles_06_rough_1k.jpg")
        ]
    },
    "server_farm": {
        "id": "anti_skid_tiles",
        "files": [
            ("diff", "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/anti_skid_tiles/anti_skid_tiles_diff_1k.jpg"),
            ("nor", "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/anti_skid_tiles/anti_skid_tiles_nor_gl_1k.jpg"),
            ("rough", "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/anti_skid_tiles/anti_skid_tiles_rough_1k.jpg")
        ]
    },
    "senate": {
        "id": "lacquered_cherry_wood",
        "files": [
            ("diff", "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/lacquered_cherry_wood/lacquered_cherry_wood_diff_1k.jpg"),
            ("nor", "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/lacquered_cherry_wood/lacquered_cherry_wood_nor_gl_1k.jpg"),
            ("rough", "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/lacquered_cherry_wood/lacquered_cherry_wood_rough_1k.jpg")
        ]
    },
    "foundry": {
        "id": "metal_plate_02",
        "files": [
            ("diff", "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/metal_plate_02/metal_plate_02_diff_1k.jpg"),
            ("nor", "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/metal_plate_02/metal_plate_02_nor_gl_1k.jpg"),
            ("rough", "https://dl.polyhaven.org/file/ph-assets/Textures/jpg/1k/metal_plate_02/metal_plate_02_rough_1k.jpg")
        ]
    }
}

def download_file(url, target_path):
    os.makedirs(os.path.dirname(target_path), exist_ok=True)
    if os.path.exists(target_path) and os.path.getsize(target_path) > 0:
        print(f"Already exists: {target_path}")
        return
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    try:
        with urllib.request.urlopen(req) as resp, open(target_path, "wb") as f:
            f.write(resp.read())
        print(f"Downloaded: {target_path} ({os.path.getsize(target_path)} bytes)")
    except Exception as e:
        print(f"Error downloading {url}: {e}")

def main():
    print("=== Downloading Kenney Models ===")
    for stage, items in KENNEY_FILES.items():
        stage_dir = os.path.join("assets", "stage_props", stage)
        for cat, filename in items:
            url = f"{BASE_KENNEY}/{cat}/{filename}"
            target = os.path.join(stage_dir, filename)
            download_file(url, target)

    print("\n=== Downloading Poly Haven Textures ===")
    for stage, tex_info in POLYHAVEN_TEXTURES.items():
        cand_capital = os.path.join("assets", "stage_props", stage, "Textures")
        cand_lower = os.path.join("assets", "stage_props", stage, "textures")
        tex_dir = cand_capital if os.path.exists(cand_capital) else cand_lower
        for suffix, url in tex_info["files"]:
            filename = f"{tex_info['id']}_{suffix}_1k.jpg"
            target = os.path.join(tex_dir, filename)
            download_file(url, target)

if __name__ == "__main__":
    main()
