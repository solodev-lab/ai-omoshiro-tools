"""Verify file split status and line counts for all screens"""
import os
import sys

LIB = "lib"
SCREENS = "lib/screens"

def count_lines(path):
    with open(path, "r", encoding="utf-8") as f:
        return sum(1 for _ in f)

def scan_dir(base):
    results = []
    for root, dirs, files in os.walk(base):
        for f in files:
            if f.endswith(".dart"):
                full = os.path.join(root, f).replace("\\", "/")
                results.append((full, count_lines(full)))
    return sorted(results)

print("=" * 60)
print("SOLARA FILE SPLIT VERIFICATION")
print("=" * 60)

# Total
all_files = scan_dir(LIB)
total = sum(c for _, c in all_files)
print(f"\nTotal: {len(all_files)} files, {total} lines\n")

# Screen split check
screen_dirs = {
    "map": ("map_screen.dart", "map/"),
    "horoscope": ("horoscope_screen.dart", "horoscope/"),
    "observe": ("observe_screen.dart", "observe/"),
    "galaxy": ("galaxy_screen.dart", "galaxy/"),
    "sanctuary": ("sanctuary_screen.dart", "sanctuary/"),
}

print("-" * 60)
print(f"{'Screen':<15} {'Main':<8} {'Sub Files':<12} {'Sub Lines':<12} {'Total':<8} {'Status'}")
print("-" * 60)

all_ok = True
for name, (main_file, sub_dir) in screen_dirs.items():
    main_path = os.path.join(SCREENS, main_file).replace("\\", "/")
    sub_path = os.path.join(SCREENS, sub_dir).replace("\\", "/")

    main_lines = count_lines(main_path) if os.path.exists(main_path) else 0

    sub_files = []
    sub_total = 0
    if os.path.isdir(sub_path):
        for f in os.listdir(sub_path):
            if f.endswith(".dart"):
                fp = os.path.join(sub_path, f)
                lines = count_lines(fp)
                sub_files.append((f, lines))
                sub_total += lines

    total_screen = main_lines + sub_total
    status = "OK" if main_lines <= 850 else "OVER 850"
    if main_lines > 850:
        all_ok = False

    print(f"{name:<15} {main_lines:<8} {len(sub_files):<12} {sub_total:<12} {total_screen:<8} {status}")

    for sf, sl in sorted(sub_files):
        print(f"  {'':>13} {sf:<30} {sl} lines")

print("-" * 60)

# Other directories
print("\nOther directories:")
for d in ["lib/models", "lib/theme", "lib/utils", "lib/widgets"]:
    if os.path.isdir(d):
        files = scan_dir(d)
        total_d = sum(c for _, c in files)
        print(f"  {d:<25} {len(files)} files, {total_d} lines")

print()
if all_ok:
    print("ALL SCREENS: Main files under 850 lines. Split OK.")
else:
    print("WARNING: Some main files exceed 850 lines!")
    sys.exit(1)
