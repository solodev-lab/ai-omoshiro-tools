"""
EN化スコープ計測: lib/ 配下の Dart から「日本語を含む箇所」を
  (A) コメント行 (// /// 始まり、/* */ ブロック)
  (B) 文字列リテラル内 (UI訳の対象候補)
に分離してカウントする。完璧なパーサではなく見積もり用ヒューリスティック。
"""
import re
import pathlib
import collections

JP = re.compile(r'[ぁ-んァ-ヶ一-龯ー]')
# 文字列リテラル (シングル/ダブル、エスケープ簡易対応)
STR_LIT = re.compile(r'''(?:'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*")''')

root = pathlib.Path("lib")
files = sorted(root.rglob("*.dart"))

total_comment_lines = 0
total_str_literals_jp = 0   # 日本語を含む文字列リテラルの数
per_file = collections.Counter()  # file -> 日本語文字列リテラル数

for f in files:
    text = f.read_text(encoding="utf-8", errors="replace")
    file_str_jp = 0
    local_block = False
    for line in text.splitlines():
        stripped = line.strip()
        if local_block:
            if JP.search(line):
                total_comment_lines += 1
            if "*/" in line:
                local_block = False
            continue
        if stripped.startswith("/*"):
            if JP.search(line):
                total_comment_lines += 1
            if "*/" not in stripped:
                local_block = True
            continue
        if stripped.startswith("//") or stripped.startswith("///"):
            if JP.search(line):
                total_comment_lines += 1
            continue
        for m in STR_LIT.finditer(line):
            if JP.search(m.group(0)):
                file_str_jp += 1
    if file_str_jp:
        per_file[str(f)] = file_str_jp
    total_str_literals_jp += file_str_jp

print(f"対象ファイル数: {len(files)}")
print(f"日本語を含むコメント行(概算): {total_comment_lines}")
print(f"日本語を含む文字列リテラル数(UI訳の対象候補・概算): {total_str_literals_jp}")
print()
print("=== 文字列リテラル(日本語)が多い上位25ファイル ===")
for path, n in per_file.most_common(25):
    print(f"{n:5d}  {path}")
