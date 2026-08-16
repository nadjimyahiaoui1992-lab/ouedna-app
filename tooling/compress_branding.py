from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / 'assets' / 'branding'
FILES = ('icon.png', 'logo.png', 'welcome_bg.jpg')

for name in FILES:
    path = ASSET_DIR / name
    before = path.stat().st_size
    with Image.open(path) as image:
        image.load()
        mode = 'RGBA' if 'A' in image.getbands() else 'RGB'
        image = image.convert(mode)
        image.save(
            path,
            format='PNG',
            optimize=True,
            compress_level=9,
        )
    after = path.stat().st_size
    print(f'{name}: {before} -> {after} bytes')
