"""
Extract constellation templates from illustration images.
Analyzes each WebP illustration to find characteristic feature points
(wing tips, horn points, leg ends, etc.) and outputs JS template code.

Strategy:
1. Threshold to binary (white lines on black)
2. Detect corners (Harris) + contour extremities
3. Cluster nearby points
4. Select 8-13 points based on image complexity
5. Prioritize: extremities > corners > spread

Usage: python extract_templates.py
"""
import json
import numpy as np
import cv2
from pathlib import Path

ART_DIR = Path(__file__).parent / "share-assets" / "constellation-art"

NOUN_FILENAMES = [
    'orbit','comet','meteor','nova','crescent','singularity',
    'phoenix','dragon','griffin','unicorn','pegasus','kraken','ouroboros',
    'serpent','trident','anchor','bow','butterfly','leviathan',
    'arrow','sword','shield','key','lantern','excalibur',
    'crown','chalice','throne','scepter','jewel','philosophers_stone',
    'flame','tempest','pyramid','ember','glacier','yggdrasil',
    'gate','tower','lighthouse','citadel','babel',
    'emblem','mirror','hourglass','scale','mask','pandora',
    'harp','bell','lyre','compass',
    'wing','feather','eye','halo','third_eye',
    'crux','prism','ring','mobius',
]


def load_and_threshold(path, thresh=80):
    """Load image, convert to grayscale, threshold."""
    img = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
    if img is None:
        return None, None
    # Resize to 512x512 if needed
    if img.shape[0] != 512 or img.shape[1] != 512:
        img = cv2.resize(img, (512, 512))
    _, binary = cv2.threshold(img, thresh, 255, cv2.THRESH_BINARY)
    return img, binary


def detect_corners(gray, binary, max_corners=30):
    """Detect Harris corners on the bright regions."""
    # Harris corner detection
    gray_f = np.float32(gray)
    harris = cv2.cornerHarris(gray_f, blockSize=5, ksize=3, k=0.04)
    harris = cv2.dilate(harris, None)

    # Only keep corners on bright pixels
    harris[binary == 0] = 0

    # Threshold and get coordinates
    threshold = harris.max() * 0.05
    coords = np.argwhere(harris > threshold)  # (y, x)

    if len(coords) == 0:
        return np.array([])

    # Convert to (x, y)
    points = coords[:, ::-1].astype(float)  # (x, y)
    return points


def detect_contour_extremities(binary, max_points=20):
    """Find extremity points of contours (tips of features)."""
    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    points = []

    for contour in contours:
        if cv2.contourArea(contour) < 50:
            continue

        # Convex hull defects for finding tips
        hull = cv2.convexHull(contour, returnPoints=True)
        # Add hull vertices as candidate points
        for pt in hull:
            points.append(pt[0].astype(float))

        # Also find the topmost, bottommost, leftmost, rightmost points
        extremes = [
            tuple(contour[contour[:, :, 1].argmin()][0]),  # top
            tuple(contour[contour[:, :, 1].argmax()][0]),  # bottom
            tuple(contour[contour[:, :, 0].argmin()][0]),  # left
            tuple(contour[contour[:, :, 0].argmax()][0]),  # right
        ]
        for ex in extremes:
            points.append(np.array(ex, dtype=float))

    if not points:
        return np.array([])
    return np.array(points)


def detect_skeleton_endpoints(binary):
    """Find endpoints of the skeleton (tips of thin features like horns, tails)."""
    # Skeletonize
    skeleton = cv2.ximgproc.thinning(binary) if hasattr(cv2, 'ximgproc') else None
    if skeleton is None:
        # Fallback: simple erosion-based skeleton
        skel = np.zeros_like(binary)
        element = cv2.getStructuringElement(cv2.MORPH_CROSS, (3, 3))
        temp = binary.copy()
        while True:
            eroded = cv2.erode(temp, element)
            opened = cv2.dilate(eroded, element)
            diff = cv2.subtract(temp, opened)
            skel = cv2.bitwise_or(skel, diff)
            temp = eroded
            if cv2.countNonZero(temp) == 0:
                break
        skeleton = skel

    # Find endpoints: pixels with only 1 neighbor in skeleton
    endpoints = []
    kernel = np.array([[1, 1, 1], [1, 0, 1], [1, 1, 1]], dtype=np.uint8)
    neighbor_count = cv2.filter2D((skeleton > 0).astype(np.uint8), -1, kernel)
    ep_mask = (skeleton > 0) & (neighbor_count == 1)
    coords = np.argwhere(ep_mask)  # (y, x)
    if len(coords) > 0:
        endpoints = coords[:, ::-1].astype(float)  # (x, y)
    return np.array(endpoints) if len(endpoints) > 0 else np.array([])


def cluster_points(points, min_dist=25):
    """Merge points that are too close together."""
    if len(points) == 0:
        return points

    clustered = [points[0]]
    for pt in points[1:]:
        dists = [np.linalg.norm(pt - c) for c in clustered]
        if min(dists) > min_dist:
            clustered.append(pt)
        else:
            # Merge with nearest cluster
            nearest_idx = np.argmin(dists)
            clustered[nearest_idx] = (clustered[nearest_idx] + pt) / 2
    return np.array(clustered)


def select_best_points(all_points, n_target, img_size=512):
    """Select the best N points maximizing spread and feature coverage."""
    if len(all_points) <= n_target:
        return all_points

    # Score each point: prefer points far from center and from each other
    center = np.array([img_size / 2, img_size / 2])

    # Start with the point farthest from center
    dists_from_center = np.linalg.norm(all_points - center, axis=1)
    selected_idx = [np.argmax(dists_from_center)]

    # Greedily add points that maximize minimum distance to selected set
    for _ in range(n_target - 1):
        best_idx = -1
        best_min_dist = -1
        for i in range(len(all_points)):
            if i in selected_idx:
                continue
            min_dist_to_selected = min(
                np.linalg.norm(all_points[i] - all_points[j])
                for j in selected_idx
            )
            # Bonus for being far from center (captures extremities)
            score = min_dist_to_selected + dists_from_center[i] * 0.3
            if score > best_min_dist:
                best_min_dist = score
                best_idx = i
        if best_idx >= 0:
            selected_idx.append(best_idx)

    return all_points[selected_idx]


def determine_complexity(binary):
    """Determine how many template points based on image complexity."""
    # Count white pixels
    white_ratio = np.count_nonzero(binary) / binary.size

    # Count contours
    contours, _ = cv2.findContours(binary, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    n_contours = len([c for c in contours if cv2.contourArea(c) > 100])

    # Total perimeter
    total_perimeter = sum(cv2.arcLength(c, True) for c in contours if cv2.contourArea(c) > 100)

    # Complexity score
    score = white_ratio * 100 + n_contours * 2 + total_perimeter / 200

    if score > 25:
        return 13
    elif score > 18:
        return 11
    elif score > 12:
        return 9
    else:
        return 8


def extract_template(filename):
    """Extract constellation template from a single illustration."""
    path = ART_DIR / f"{filename}.webp"
    if not path.exists():
        print(f"  SKIP: {filename}.webp not found")
        return None

    gray, binary = load_and_threshold(path)
    if binary is None:
        return None

    # Determine target point count
    n_target = determine_complexity(binary)

    # Detect feature points from multiple methods
    corners = detect_corners(gray, binary)
    extremities = detect_contour_extremities(binary)
    endpoints = detect_skeleton_endpoints(binary)

    # Combine all detected points
    all_points = []
    if len(endpoints) > 0:
        all_points.append(endpoints)
    if len(extremities) > 0:
        all_points.append(extremities)
    if len(corners) > 0:
        all_points.append(corners)

    if not all_points:
        print(f"  WARN: No points detected for {filename}")
        return None

    combined = np.vstack(all_points)

    # Remove points too close to edges (margin 5%)
    margin = 512 * 0.05
    mask = (combined[:, 0] > margin) & (combined[:, 0] < 512 - margin) & \
           (combined[:, 1] > margin) & (combined[:, 1] < 512 - margin)
    combined = combined[mask]

    if len(combined) == 0:
        print(f"  WARN: No valid points for {filename}")
        return None

    # Cluster nearby points
    clustered = cluster_points(combined, min_dist=30)

    # Select best points
    selected = select_best_points(clustered, n_target)

    # Normalize to 0-1
    normalized = selected / 512.0

    # Round to 2 decimal places
    template = [[round(float(p[0]), 2), round(float(p[1]), 2)] for p in normalized]

    return template


def main():
    print(f"Extracting templates from {len(NOUN_FILENAMES)} illustrations...\n")

    templates = {}
    for idx, filename in enumerate(NOUN_FILENAMES):
        template = extract_template(filename)
        if template:
            templates[idx] = template
            n = len(template)
            print(f"  [{idx:2d}] {filename:20s} -> {n} points")
        else:
            print(f"  [{idx:2d}] {filename:20s} -> FAILED")

    # Output as JavaScript
    print(f"\n=== Generated {len(templates)}/{len(NOUN_FILENAMES)} templates ===\n")

    js_lines = ["const NOUN_TEMPLATES = {"]
    for idx in sorted(templates.keys()):
        filename = NOUN_FILENAMES[idx]
        pts = templates[idx]
        pts_str = ",".join(f"[{p[0]},{p[1]}]" for p in pts)
        js_lines.append(f"  {idx}:[{pts_str}], // {filename} ({len(pts)}pts)")
    js_lines.append("};")

    js_output = "\n".join(js_lines)

    # Write to file
    out_path = Path(__file__).parent / "generated_templates.js"
    out_path.write_text(js_output, encoding="utf-8")
    print(f"Written to: {out_path}")
    print(f"\nCopy the content into galaxy.html to replace NOUN_TEMPLATES.")


if __name__ == "__main__":
    main()
