"""bow.webp を時計回り90度回転"""
import os
import shutil
from PIL import Image

SRC = "E:/AppCreate/apps/solara/assets/constellation-art/bow.webp"
BACKUP = "E:/AppCreate/apps/solara/assets/constellation-art-backup/bow.webp"

# already backed up from fix_white_borders run? check and skip
os.makedirs(os.path.dirname(BACKUP), exist_ok=True)
if not os.path.exists(BACKUP):
    shutil.copy2(SRC, BACKUP)
    print("Backed up bow.webp")

img = Image.open(SRC)
w, h = img.size
print(f"Original: {w}x{h}")
# ROTATE_270 = clockwise 90 degrees
rotated = img.transpose(Image.Transpose.ROTATE_270)
rotated.save(SRC, 'WEBP', quality=90)
print(f"Rotated -> {rotated.size}")
