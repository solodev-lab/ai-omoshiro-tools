"""
Generate planet rotation animations (APNG/WebP) from equirectangular textures.

Input:  equirectangular planet texture (2:1 aspect), e.g. 2048x1024
Output: looping WebP animation of a 3D rotating sphere with shading

Algorithm (per frame):
  1. For each output pixel, compute sphere normal (x,y,z).
  2. Convert to (longitude, latitude).
  3. Apply frame's rotation offset.
  4. Sample texture at (lon, lat).
  5. Apply Lambert shading from upper-right light.
  6. Alpha mask: sphere only.

Usage:
  python generate_planet_rotations.py                 # all found textures
  python generate_planet_rotations.py jupiter         # single
  python generate_planet_rotations.py --frames 60     # override frame count
  python generate_planet_rotations.py --size 384      # override sphere diameter
"""
import sys
import time
from pathlib import Path

TEX_DIR = Path(__file__).parent / "share-assets" / "tarot_scene" / "planet_textures"
OUT_DIR = Path(__file__).parent / "share-assets" / "tarot_scene" / "planet_rotations"
OUT_DIR.mkdir(parents=True, exist_ok=True)

DEFAULT_FRAMES = 60        # 60 frames × ~100ms = 6s loop
DEFAULT_SIZE = 384         # sphere diameter (output canvas = size×size)
DEFAULT_FPS = 10


def render_sphere(tex_arr, rotation_deg, size, light_dir=(0.7, -0.5, 0.55), ambient=0.12):
    """Render one frame of a lit sphere from equirectangular texture."""
    import numpy as np

    tex_h, tex_w = tex_arr.shape[:2]

    # Normalize light
    lx, ly, lz = light_dir
    ln = (lx * lx + ly * ly + lz * lz) ** 0.5
    lx, ly, lz = lx / ln, ly / ln, lz / ln

    # Output canvas: [size, size, 4]
    out = np.zeros((size, size, 4), dtype=np.uint8)

    cx = cy = size / 2
    r = size / 2 - 1

    ys, xs = np.mgrid[0:size, 0:size].astype(np.float32)
    dx = (xs - cx) / r
    dy = (ys - cy) / r
    d2 = dx * dx + dy * dy
    mask = d2 <= 1.0
    dz = np.sqrt(np.clip(1.0 - d2, 0.0, 1.0))

    # Sphere surface point (viewer-facing normal = (dx, -dy, dz))
    nx = dx
    ny = -dy
    nz = dz

    # Latitude = arcsin(ny); Longitude = arctan2(nx, nz) + rotation
    lat = np.arcsin(np.clip(ny, -1.0, 1.0))
    lon = np.arctan2(nx, nz)
    lon = lon + np.radians(rotation_deg)
    lon = (lon + np.pi) % (2 * np.pi) - np.pi

    u = ((lon + np.pi) / (2 * np.pi)) * (tex_w - 1)
    v = ((np.pi / 2 - lat) / np.pi) * (tex_h - 1)  # top=north pole
    ui = np.clip(u.astype(np.int32), 0, tex_w - 1)
    vi = np.clip(v.astype(np.int32), 0, tex_h - 1)

    sampled = tex_arr[vi, ui]

    # Lambert + ambient
    diffuse = np.clip(nx * lx + ny * ly + nz * lz, 0.0, 1.0)
    shading = ambient + (1.0 - ambient) * diffuse
    shading = shading[..., None]

    shaded = np.clip(sampled[:, :, :3].astype(np.float32) * shading, 0, 255).astype(np.uint8)
    out[:, :, :3] = shaded

    # Alpha with 1-pixel soft edge
    alpha_soft = np.clip((1.0 - d2) * 120.0, 0.0, 1.0)
    out[:, :, 3] = np.where(mask, 255 * alpha_soft, 0).astype(np.uint8)

    return out


def render_planet(texture_path: Path, out_path: Path, frames=DEFAULT_FRAMES, size=DEFAULT_SIZE, fps=DEFAULT_FPS):
    try:
        from PIL import Image
        import numpy as np
    except ImportError as e:
        print(f"ERROR: missing library — {e}")
        return False

    print(f"  Loading texture: {texture_path.name}")
    tex_img = Image.open(texture_path).convert("RGB")
    tex_arr = np.array(tex_img)

    print(f"  Rendering {frames} frames @ {size}×{size} ...")
    t0 = time.time()
    frame_imgs = []
    for i in range(frames):
        rot = 360.0 * i / frames
        frame = render_sphere(tex_arr, rot, size)
        frame_imgs.append(Image.fromarray(frame, mode="RGBA"))
    dt = time.time() - t0
    print(f"  Rendered in {dt:.1f}s")

    duration_ms = int(1000 / fps)
    frame_imgs[0].save(
        str(out_path),
        format="WEBP",
        save_all=True,
        append_images=frame_imgs[1:],
        loop=0,
        duration=duration_ms,
        lossless=False,
        quality=85,
        method=4,
    )
    size_kb = out_path.stat().st_size // 1024
    print(f"  OK: {out_path.name} ({size}×{size}, {frames}f, {size_kb}KB)")
    return True


def main():
    args = sys.argv[1:]
    frames = DEFAULT_FRAMES
    size = DEFAULT_SIZE

    pruned = []
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--frames" and i + 1 < len(args):
            frames = int(args[i + 1]); i += 2
        elif a == "--size" and i + 1 < len(args):
            size = int(args[i + 1]); i += 2
        else:
            pruned.append(a); i += 1
    args = pruned

    if not TEX_DIR.exists():
        print(f"ERROR: texture directory not found: {TEX_DIR}")
        print("  Place equirectangular maps (2:1 ratio) named <planet>.png there.")
        return

    textures = sorted(TEX_DIR.glob("*.png")) + sorted(TEX_DIR.glob("*.jpg"))
    if args:
        textures = [t for t in textures if t.stem in args]

    if not textures:
        print("No textures found.")
        return

    print(f"=== Rendering rotations for {len(textures)} planets ===")
    ok = 0
    for tex in textures:
        name = tex.stem
        out_path = OUT_DIR / f"{name}.webp"
        if render_planet(tex, out_path, frames=frames, size=size):
            ok += 1
    print(f"=== Done: {ok}/{len(textures)} ===")


if __name__ == "__main__":
    main()
