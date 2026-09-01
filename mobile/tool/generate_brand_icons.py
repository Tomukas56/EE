#!/usr/bin/env python3
"""Resize Energy Eniwhere master art into launcher / splash / web icons."""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / "assets" / "brand"
SPLASH_BG = (11, 61, 46, 255)
IOS_BG = (6, 18, 36, 255)  # dark map blue behind any leftover alpha


def load_master() -> Image.Image:
    for name in ("ee_emblem.png", "ee_icon.png"):
        path = BRAND / name
        if path.exists() and path.stat().st_size > 100_000:
            im = Image.open(path).convert("RGBA")
            print(f"Master: {path.name} {im.size} {path.stat().st_size} bytes")
            return im
    raise SystemExit(f"No large master PNG in {BRAND}")


def square(im: Image.Image, size: int, flatten=None) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fitted = im.copy()
    fitted.thumbnail((size, size), Image.Resampling.LANCZOS)
    x = (size - fitted.width) // 2
    y = (size - fitted.height) // 2
    canvas.paste(fitted, (x, y), fitted)
    if flatten is not None:
        bg = Image.new("RGBA", (size, size), flatten)
        bg.alpha_composite(canvas)
        return bg
    return canvas


def rounded(im: Image.Image, radius_ratio=0.22) -> Image.Image:
    size = im.width
    mask = Image.new("L", (size, size), 0)
    from PIL import ImageDraw

    r = int(size * radius_ratio)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size - 1, size - 1), r, fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(im, mask=mask)
    return out


def save(im: Image.Image, path: Path, size: int, flatten=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    square(im, size, flatten=flatten).save(path, "PNG", optimize=True)


def main():
    master = load_master()
    opaque = square(master, 1024, flatten=IOS_BG)
    framed = rounded(opaque)

    icon_path = BRAND / "ee_icon.png"
    if not icon_path.exists() or icon_path.stat().st_size < 100_000:
        opaque.save(icon_path, "PNG", optimize=True)
        print("Wrote assets/brand/ee_icon.png")

    android = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    res = ROOT / "android" / "app" / "src" / "main" / "res"
    for folder, px in android.items():
        save(opaque, res / folder / "ic_launcher.png", px, flatten=IOS_BG)
        save(framed, res / folder / "ic_launcher_round.png", px)
        fg = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
        inner = framed.resize((640, 640), Image.Resampling.LANCZOS)
        fg.paste(inner, (192, 192), inner)
        save(fg, res / folder / "ic_launcher_foreground.png", int(px * 108 / 48))

    splash = Image.new("RGBA", (1024, 1024), SPLASH_BG)
    emblem = framed.resize((720, 720), Image.Resampling.LANCZOS)
    splash.paste(emblem, (152, 152), emblem)
    splash.save(res / "drawable" / "splash_emblem.png", "PNG", optimize=True)

    ios_sizes = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    ios_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for name, px in ios_sizes.items():
        save(opaque, ios_dir / name, px, flatten=IOS_BG)

    launch = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"
    save(framed, launch / "LaunchImage.png", 168)
    save(framed, launch / "LaunchImage@2x.png", 336)
    save(framed, launch / "LaunchImage@3x.png", 504)

    web = ROOT / "web"
    save(framed, web / "favicon.png", 48)
    save(framed, web / "icons" / "Icon-192.png", 192)
    save(framed, web / "icons" / "Icon-512.png", 512)
    save(opaque, web / "icons" / "Icon-maskable-192.png", 192, flatten=IOS_BG)
    save(opaque, web / "icons" / "Icon-maskable-512.png", 512, flatten=IOS_BG)
    print("Resized your emblem into all launcher sizes.")


if __name__ == "__main__":
    main()
