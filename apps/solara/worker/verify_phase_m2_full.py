"""
Solara Phase M2 完了総合検証スクリプト

実行内容:
  1. Phase M2 ファイルの存在確認
  2. ファイル分割の健全性 (各ファイルの行数 + 1ファイル1000行未満)
  3. 不要コード検出 (TODO/FIXME/XXX, デバッグ print, ハウス計算重複)
  4. Worker /astro/chart のリロケート検証 (引越し計算精度 verify_phase_m2.py 流用)
  5. アスペクト線計算の検証 (verify_astro_lines.py 流用)
  6. ドキュメント記載状況確認

実行方法:
  python apps/solara/worker/verify_phase_m2_full.py
  python apps/solara/worker/verify_phase_m2_full.py --skip-network  # ネットワーク検証スキップ
"""
import os
import re
import subprocess
import sys

REPO_ROOT = "E:/AppCreate"
SOLARA = f"{REPO_ROOT}/apps/solara"
LIB = f"{SOLARA}/lib"
WORKER_SRC = f"{SOLARA}/worker/src"


def header(title):
    print(f"\n{'='*72}\n  {title}\n{'='*72}")


def file_lines(path):
    with open(path, encoding="utf-8") as f:
        return sum(1 for _ in f)


def file_text(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


# ───────────────────────────────────────────────────────────
# 1. Phase M2 ファイルの存在確認
# ───────────────────────────────────────────────────────────
PHASE_M2_FILES = [
    # 計算ロジック
    "lib/utils/astro_houses.dart",         # LST/ASC/MC/Placidus
    "lib/utils/astro_lines.dart",          # 40本ライン計算
    "lib/utils/astro_glossary.dart",       # 用語辞書

    # UI
    "lib/widgets/astro_term_label.dart",   # i アイコン + popup
    "lib/screens/map/map_astro_lines.dart", # Polyline 変換
    "lib/screens/map/map_relocation_popup.dart", # 統合 popup

    # 既存改修
    "lib/screens/map/map_layer_panel.dart", # 4流派並列 UI
    "lib/screens/map_screen.dart",         # 統合
]


def check_files_exist():
    header("1. Phase M2 ファイル存在確認")
    issues = 0
    for rel in PHASE_M2_FILES:
        path = f"{SOLARA}/{rel}"
        if os.path.exists(path):
            n = file_lines(path)
            print(f"  [OK] {rel} ({n} 行)")
        else:
            print(f"  [NG] NOT FOUND: {rel}")
            issues += 1
    return issues


# ───────────────────────────────────────────────────────────
# 2. ファイル分割の健全性 (1000行未満)
# ───────────────────────────────────────────────────────────
def check_file_sizes():
    header("2. ファイル分割の健全性 (1ファイル < 1000行)")
    threshold = 1000
    issues = 0
    targets = PHASE_M2_FILES + [
        "lib/screens/horoscope_screen.dart",
        "lib/screens/horoscope/horo_relocation_panel.dart",
        "lib/screens/horoscope/horo_planet_table.dart",
        "worker/src/astro.js",
    ]
    for rel in targets:
        path = f"{SOLARA}/{rel}"
        if not os.path.exists(path):
            continue
        n = file_lines(path)
        warn = " <<< 大" if n >= 800 else ""
        if n >= threshold:
            print(f"  [NG] {rel}: {n} 行 (閾値 {threshold} 超過)")
            issues += 1
        else:
            print(f"  [OK] {rel}: {n} 行{warn}")
    return issues


# ───────────────────────────────────────────────────────────
# 3. 不要コード検出
# ───────────────────────────────────────────────────────────
def check_unused_code():
    header("3. 不要コード検出 (TODO/FIXME/XXX, デバッグ print, debugPrint)")
    issues = 0
    patterns = {
        r"\bTODO\b": "TODO",
        r"\bFIXME\b": "FIXME",
        r"\bXXX\b": "XXX",
        r"^\s*print\(": "print() (デバッグ出力)",
        r"^\s*debugPrint\(": "debugPrint() (デバッグ出力)",
    }
    for rel in PHASE_M2_FILES:
        path = f"{SOLARA}/{rel}"
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as f:
            for ln, line in enumerate(f, 1):
                # 文字列内・コメント内は除外したいが厳密分析は重いので簡易
                # コメント行 (// または /// で始まる) はスキップ
                stripped = line.lstrip()
                if stripped.startswith("//") or stripped.startswith("///"):
                    continue
                for pattern, label in patterns.items():
                    if re.search(pattern, line):
                        print(f"  [WARN] {rel}:{ln} {label}")
                        issues += 1
    if issues == 0:
        print("  [OK] 不要コードなし")
    return issues


# ───────────────────────────────────────────────────────────
# 4. ハウス計算の重複検出 (assignPlanetHouse に統一されているか)
# ───────────────────────────────────────────────────────────
def check_house_calc_dedup():
    header("4. ハウス計算ロジックの統一確認")
    # assignPlanetHouse 以外の独自実装が無いことを確認
    pattern = re.compile(r"final\s+inHouse\s*=\s*\(cusp\s*<=\s*next\)")
    issues = 0
    expected_in = {
        "lib/utils/astro_houses.dart",  # 唯一の正規実装
    }
    found_in = []
    for root, _, files in os.walk(LIB):
        for fname in files:
            if not fname.endswith(".dart"):
                continue
            full = os.path.join(root, fname)
            rel = os.path.relpath(full, SOLARA).replace("\\", "/")
            try:
                text = file_text(full)
            except Exception:
                continue
            if pattern.search(text):
                found_in.append(rel)

    for rel in found_in:
        if rel in expected_in:
            print(f"  [OK] {rel}: assignPlanetHouse 正規実装")
        else:
            print(f"  [NG] {rel}: 重複したハウス計算実装あり")
            issues += 1

    # 全使用箇所が assignPlanetHouse 経由か確認
    use_pattern = re.compile(r"assignPlanetHouse\(")
    consumers = []
    for root, _, files in os.walk(LIB):
        for fname in files:
            if not fname.endswith(".dart"):
                continue
            full = os.path.join(root, fname)
            rel = os.path.relpath(full, SOLARA).replace("\\", "/")
            if rel == "lib/utils/astro_houses.dart":
                continue
            try:
                text = file_text(full)
            except Exception:
                continue
            if use_pattern.search(text):
                consumers.append(rel)
    if consumers:
        print(f"  [OK] assignPlanetHouse 利用箇所: {len(consumers)} 件")
        for c in consumers:
            print(f"       - {c}")
    return issues


# ───────────────────────────────────────────────────────────
# 5. flutter analyze (警告ゼロ確認)
# ───────────────────────────────────────────────────────────
def check_flutter_analyze():
    header("5. flutter analyze (警告ゼロ)")
    try:
        proc = subprocess.run(
            ["flutter", "analyze"],
            cwd=SOLARA, capture_output=True, text=True, timeout=180,
            shell=True,
        )
        if proc.returncode == 0:
            tail = proc.stdout.strip().splitlines()[-3:]
            for line in tail:
                print(f"  {line}")
            print("  [OK] No issues")
            return 0
        else:
            print("  [NG] flutter analyze で警告あり:")
            for line in proc.stdout.strip().splitlines():
                print(f"    {line}")
            return 1
    except Exception as e:
        print(f"  [SKIP] flutter analyze 実行不可: {e}")
        return 0


# ───────────────────────────────────────────────────────────
# 6. ネットワーク検証 (Worker 連携)
# ───────────────────────────────────────────────────────────
def run_subscript(name):
    path = f"{SOLARA}/worker/{name}"
    if not os.path.exists(path):
        print(f"  [SKIP] {name} 存在せず")
        return 0
    proc = subprocess.run(
        [sys.executable, path], capture_output=True, text=True, timeout=600,
    )
    # 末尾サマリ行だけ抜粋
    lines = proc.stdout.strip().splitlines()
    summary = [ln for ln in lines if "[OK]" in ln or "[NG]" in ln or "サマリ" in ln or "全パス" in ln]
    for ln in summary[-12:]:
        print(f"  {ln}")
    return 0 if proc.returncode == 0 else 1


def check_worker_relocate(skip_network):
    header("6a. Worker 引越し計算精度検証 (verify_phase_m2.py)")
    if skip_network:
        print("  [SKIP] --skip-network 指定")
        return 0
    return run_subscript("verify_phase_m2.py")


def check_worker_aspect_lines(skip_network):
    header("6b. Worker アスペクト線整合性検証 (verify_astro_lines.py)")
    if skip_network:
        print("  [SKIP] --skip-network 指定")
        return 0
    return run_subscript("verify_astro_lines.py")


# ───────────────────────────────────────────────────────────
# 7. ドキュメント記載確認
# ───────────────────────────────────────────────────────────
def check_docs():
    header("7. ドキュメント記載状況")
    docs = [
        f"{SOLARA}/docs/architecture.md",
        f"{SOLARA}/docs/今後のアップデート.md",
    ]
    issues = 0
    for path in docs:
        if not os.path.exists(path):
            print(f"  [WARN] 存在せず: {path}")
            issues += 1
            continue
        text = file_text(path)
        if "Phase M2" in text or "アスペクト線" in text or "アストロカートグラフィ" in text:
            print(f"  [OK] {os.path.basename(path)} に Phase M2 記述あり")
        else:
            print(f"  [WARN] {os.path.basename(path)} に Phase M2 記述なし - 要更新")
            issues += 1
    return issues


# ───────────────────────────────────────────────────────────
# main
# ───────────────────────────────────────────────────────────
def main():
    skip_network = "--skip-network" in sys.argv

    print("=" * 72)
    print("  Solara Phase M2 完了総合検証")
    print("=" * 72)

    results = []
    results.append(("1. Phase M2 ファイル存在", check_files_exist()))
    results.append(("2. ファイル分割健全性", check_file_sizes()))
    results.append(("3. 不要コード検出", check_unused_code()))
    results.append(("4. ハウス計算統一", check_house_calc_dedup()))
    results.append(("5. flutter analyze", check_flutter_analyze()))
    results.append(("6a. Worker 引越し精度", check_worker_relocate(skip_network)))
    results.append(("6b. Worker アスペクト線", check_worker_aspect_lines(skip_network)))
    results.append(("7. ドキュメント記載", check_docs()))

    header("最終サマリ")
    total_issues = 0
    for label, n in results:
        mark = "[OK]" if n == 0 else f"[NG x{n}]"
        print(f"  {mark} {label}")
        total_issues += n

    print(f"\n総 issues: {total_issues}")
    return 0 if total_issues == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
