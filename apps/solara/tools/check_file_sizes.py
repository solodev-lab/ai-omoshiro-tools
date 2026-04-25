"""ファイル分割の健全性チェック。

500行を超える .dart ファイルを分割候補として警告する。
1000行超は強い分割推奨、500-1000行は要検討。
"""
import os
import sys

THRESHOLD_WARN = 500
THRESHOLD_STRONG = 1000

def main():
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    lib_dir = os.path.join(repo_root, "lib")
    if not os.path.isdir(lib_dir):
        print(f"ERROR: lib not found at {lib_dir}", file=sys.stderr)
        sys.exit(1)

    big = []
    total_files = 0
    total_lines = 0
    for root, _, files in os.walk(lib_dir):
        for f in files:
            if not f.endswith(".dart"):
                continue
            path = os.path.join(root, f)
            with open(path, "r", encoding="utf-8") as fh:
                lines = sum(1 for _ in fh)
            total_files += 1
            total_lines += lines
            if lines > THRESHOLD_WARN:
                rel = os.path.relpath(path, repo_root).replace("\\", "/")
                big.append((lines, rel))

    big.sort(reverse=True)
    print(f"=== File size report (lib/) ===")
    print(f"Total files: {total_files}")
    print(f"Total lines: {total_lines}")
    print(f"Average:     {total_lines // max(1, total_files)} lines/file")
    print()
    print(f"--- Files over {THRESHOLD_WARN} lines ---")
    if not big:
        print("  (none)")
        return
    for lines, rel in big:
        marker = "!! STRONG SPLIT" if lines > THRESHOLD_STRONG else "?  REVIEW"
        print(f"  {marker:18s} {lines:5d}  {rel}")

if __name__ == "__main__":
    main()
