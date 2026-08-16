from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "branding"


def save_png(path: Path, size: tuple[int, int]) -> None:
    with Image.open(path) as image:
        image.load()
        image = image.convert("RGBA" if "A" in image.getbands() else "RGB")
        image.thumbnail(size, Image.Resampling.LANCZOS)
        image.save(path, format="PNG", optimize=True, compress_level=9)


def save_jpeg(path: Path, size: tuple[int, int], quality: int = 92) -> None:
    with Image.open(path) as image:
        image.load()
        image = image.convert("RGB")
        image.thumbnail(size, Image.Resampling.LANCZOS)
        image.save(
            path,
            format="JPEG",
            quality=quality,
            optimize=True,
            progressive=True,
        )


for name, operation in (
    ("icon.png", lambda path: save_png(path, (512, 512))),
    ("logo.png", lambda path: save_png(path, (768, 768))),
    ("welcome_bg.jpg", lambda path: save_jpeg(path, (1440, 2560))),
):
    path = ASSET_DIR / name
    before = path.stat().st_size
    operation(path)
    after = path.stat().st_size
    print(f"{name}: {before} -> {after} bytes")
