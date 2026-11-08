#!/usr/bin/env python3
"""Generate the Xbox tile and splash PNGs for the single-game packages.

Usage: python3 scripts/xbox-uwp/make_game_assets.py

Reads ports/uwp/Assets/source/<game>.jpg (the full-size key art) and writes
ports/uwp/Assets/<game>/*.png at the sizes Package.appxmanifest.in names.
Square tiles are a centre crop; wide tiles and the splash fit the whole art
and pad the sides with the art's own edge colour.
"""

from pathlib import Path

from PIL import Image, ImageStat

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "ports" / "uwp" / "Assets"
GAMES = ("red", "ruby", "firered")

SQUARE = {
    "Square44x44Logo.png": 44,
    "StoreLogo.png": 50,
    "SmallTile.png": 71,
    "Square150x150Logo.png": 150,
    "LargeTile.png": 310,
}
WIDE = {
    "WideTile.png": (310, 150),
    "SplashScreen.png": (620, 300),
}


def edge_colour(img):
    w, h = img.size
    strip = img.crop((0, 0, max(1, w // 40), h))
    return tuple(int(c) for c in ImageStat.Stat(strip).mean[:3])


def square(img, size):
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    return img.crop((left, top, left + side, top + side)).resize(
        (size, size), Image.LANCZOS)


def fit(img, size, fill):
    tw, th = size
    w, h = img.size
    scale = min(tw / w, th / h)
    nw, nh = round(w * scale), round(h * scale)
    canvas = Image.new("RGB", size, fill)
    canvas.paste(img.resize((nw, nh), Image.LANCZOS), ((tw - nw) // 2, (th - nh) // 2))
    return canvas


def main():
    for game in GAMES:
        src = Image.open(ASSETS / "source" / f"{game}.jpg").convert("RGB")
        out = ASSETS / game
        out.mkdir(parents=True, exist_ok=True)
        fill = edge_colour(src)
        for name, size in SQUARE.items():
            square(src, size).save(out / name, optimize=True)
        for name, size in WIDE.items():
            fit(src, size, fill).save(out / name, optimize=True)
        print(f"wrote {out}")


if __name__ == "__main__":
    main()
