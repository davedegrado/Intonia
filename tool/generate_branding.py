"""Genera splash e icone dell'app dalle immagini sorgente in assets/branding/.

    python3 tool/generate_branding.py   (richiede Pillow)

Sorgenti:
  assets/branding/splash_full.png      splash completa (verticale)
  assets/branding/app_icon_source.png  icona quadrata (riquadro arrotondato su fondo scuro)
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
BRANDING = ROOT / "assets/branding"
RES = ROOT / "android/app/src/main/res"
IOS = ROOT / "ios/Runner/Assets.xcassets"

SPLASH_BG = (3, 1, 26)  # #03011A, bordi della splash
DENSITIES = {"mdpi": 1, "hdpi": 1.5, "xhdpi": 2, "xxhdpi": 3, "xxxhdpi": 4}

# Riquadro dell'icona sorgente appena dentro il bordo luminoso (frazioni del lato).
ICON_CROP = (0.090, 0.086, 0.911, 0.907)
# Mascotte nella splash (frazioni di larghezza/altezza): centro e lato del quadrato.
LOGO_CENTER = (0.5, 0.365)
LOGO_SIDE = 0.62


def icon_square() -> Image.Image:
    src = Image.open(BRANDING / "app_icon_source.png").convert("RGB")
    w, h = src.size
    box = (round(ICON_CROP[0] * w), round(ICON_CROP[1] * h),
           round(ICON_CROP[2] * w), round(ICON_CROP[3] * h))
    side = min(box[2] - box[0], box[3] - box[1])
    return src.crop((box[0], box[1], box[0] + side, box[1] + side)).resize(
        (1024, 1024), Image.LANCZOS)


def feather(size: int, inner: float) -> Image.Image:
    """Maschera radiale: opaca fino a `inner` del raggio, poi sfuma a zero."""
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    steps = 64
    for i in range(steps):
        t = i / (steps - 1)
        r = size / 2 * (1 - t * (1 - inner))
        value = round(255 * min(1.0, t / 0.6))
        draw.ellipse((size / 2 - r, size / 2 - r, size / 2 + r, size / 2 + r), fill=value)
    return mask


def ios_icons(icon: Image.Image) -> None:
    folder = IOS / "AppIcon.appiconset"
    for path in folder.glob("Icon-App-*.png"):
        # Icon-App-20x20@2x.png -> 20 * 2
        size_part, scale_part = path.stem.removeprefix("Icon-App-").split("@")
        px = round(float(size_part.split("x")[0]) * int(scale_part.removesuffix("x")))
        icon.resize((px, px), Image.LANCZOS).save(path)


def android_icons(icon: Image.Image) -> None:
    # Icona adattiva: tela 108dp di cui il launcher mostra circa i 72dp centrali.
    # Sfondo = icona sfocata a tutta tela, primo piano = icona a 80dp con bordi sfumati.
    canvas = 432
    background = icon.resize((canvas, canvas), Image.LANCZOS).filter(ImageFilter.GaussianBlur(24))
    inner = round(canvas * 80 / 108)
    fg = icon.resize((inner, inner), Image.LANCZOS)
    composite = background.copy()
    composite.paste(fg, ((canvas - inner) // 2,) * 2, feather(inner, 0.86))
    # Tutto nel primo piano (opaco): lo sfondo dell'adaptive icon resta solo colore.
    composite.save(RES / "drawable/ic_launcher_foreground.png")
    # Icone legacy (Android < 8): riquadro arrotondato.
    for density, scale in DENSITIES.items():
        px = round(48 * scale)
        img = icon.resize((px, px), Image.LANCZOS).convert("RGBA")
        mask = Image.new("L", (px * 4, px * 4), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, px * 4 - 1, px * 4 - 1), radius=px * 4 * 0.22, fill=255)
        img.putalpha(mask.resize((px, px), Image.LANCZOS))
        img.save(RES / f"mipmap-{density}/ic_launcher.png")


def splash() -> None:
    full = Image.open(BRANDING / "splash_full.png").convert("RGB")
    w, h = full.size
    # Splash dell'app Flutter (lib/app/splash_overlay.dart).
    full.save(BRANDING / "splash.jpg", quality=88, optimize=True, progressive=True)
    # iOS: launch screen a tutto schermo (3x = originale, 2x, 1x).
    folder = IOS / "LaunchImage.imageset"
    for suffix, factor in (("@3x", 1), ("@2x", 2 / 3), ("", 1 / 3)):
        full.resize((round(w * factor), round(h * factor)), Image.LANCZOS).save(
            folder / f"LaunchImage{suffix}.png")
    # Android: logo centrale (288dp, entro il cerchio da 192dp di Android 12+).
    side = round(LOGO_SIDE * w)
    cx, cy = round(LOGO_CENTER[0] * w), round(LOGO_CENTER[1] * h)
    logo = full.crop((cx - side // 2, cy - side // 2, cx + side // 2, cy + side // 2))
    logo = logo.resize((560, 560), Image.LANCZOS)
    faded = Image.new("RGB", logo.size, SPLASH_BG)
    faded.paste(logo, (0, 0), feather(560, 0.72))
    faded.save(BRANDING / "splash_logo.png")
    for density, scale in DENSITIES.items():
        px = round(288 * scale)
        canvas = Image.new("RGB", (px, px), SPLASH_BG)
        inner = round(px * 192 / 288)
        canvas.paste(faded.resize((inner, inner), Image.LANCZOS), ((px - inner) // 2,) * 2)
        canvas.save(RES / f"drawable-{density}/splash_icon.png")


if __name__ == "__main__":
    icon = icon_square()
    ios_icons(icon)
    android_icons(icon)
    splash()
    print("ok")
