"""
Solara M0 (リロケーションチャート) セッション完了検証
- ファイル分割状況
- テンプレート完全性
- 不要コード検出
- Worker API 動作 (relocate機能)
"""
import json
import os
import re
import sys
import urllib.request

REPO_ROOT = "E:/AppCreate"
SOLARA = f"{REPO_ROOT}/apps/solara"
LIB = f"{SOLARA}/lib"
WORKER_SRC = f"{SOLARA}/worker/src"
API = "https://solara-api.solodev-lab.com/astro/chart"


def header(title):
    print(f"\n{'='*60}\n  {title}\n{'='*60}")


def check_file_sizes():
    """ファイル分割の状況: 各画面/モジュールの行数"""
    header("1. ファイル分割確認 (行数)")
    targets = [
        "lib/screens/horoscope_screen.dart",
        "lib/screens/horoscope/horo_bottom_sheet.dart",
        "lib/screens/horoscope/horo_chart_view.dart",
        "lib/screens/horoscope/horo_chart_data.dart",
        "lib/screens/horoscope/horo_planet_table.dart",
        "lib/screens/horoscope/horo_relocation_panel.dart",
        "lib/screens/horoscope/horo_relocation_templates.dart",
        "lib/screens/horoscope/horo_constants.dart",
        "lib/screens/map_screen.dart",
        "lib/screens/locations_screen.dart",
        "lib/screens/map/map_astro.dart",
        "worker/src/astro.js",
    ]
    threshold = 1000  # 1ファイル1000行を超えたら警告
    issues = 0
    for rel in targets:
        path = f"{SOLARA}/{rel}"
        if not os.path.exists(path):
            print(f"  ❌ NOT FOUND: {rel}")
            issues += 1
            continue
        with open(path, encoding="utf-8") as f:
            lines = sum(1 for _ in f)
        flag = "⚠️ 大きい" if lines > threshold else "✅"
        print(f"  {flag} {lines:>5} lines  {rel}")
        if lines > threshold:
            issues += 1
    return issues


def check_template_completeness():
    """テンプレート完全性: 120 (10惑星×12ハウス) + 24 (ASC/MC×12星座)"""
    header("2. テンプレート完全性")
    path = f"{LIB}/screens/horoscope/horo_relocation_templates.dart"
    if not os.path.exists(path):
        print(f"  ❌ テンプレートファイル未作成: {path}")
        return 1
    with open(path, encoding="utf-8") as f:
        content = f.read()

    issues = 0
    expected_planets = ['sun', 'moon', 'mercury', 'venus', 'mars',
                        'jupiter', 'saturn', 'uranus', 'neptune', 'pluto']
    for planet in expected_planets:
        # 各惑星セクションが12個のハウス記述を持つか
        pattern = rf"'{planet}':\s*\{{(.*?)\}},\s*'?(?:[a-z]+|}})"
        m = re.search(pattern, content, re.DOTALL)
        if not m:
            print(f"  ❌ {planet}: セクション見つからず")
            issues += 1
            continue
        body = m.group(1)
        nums = re.findall(r"^\s*(\d+):\s*'", body, re.MULTILINE)
        nums = sorted({int(n) for n in nums})
        if nums == list(range(1, 13)):
            print(f"  ✅ {planet}: 12ハウス全て")
        else:
            print(f"  ❌ {planet}: {nums} (12個揃ってない)")
            issues += 1

    # ASC/MC 星座記述
    for label in ['ascInSignDescriptions', 'mcInSignDescriptions']:
        m = re.search(rf"const Map<int, String> {label}\s*=\s*\{{(.*?)\}};",
                      content, re.DOTALL)
        if not m:
            print(f"  ❌ {label}: 見つからず")
            issues += 1
            continue
        keys = re.findall(r"^\s*(\d+):\s*'", m.group(1), re.MULTILINE)
        keys = sorted({int(k) for k in keys})
        if keys == list(range(0, 12)):
            print(f"  ✅ {label}: 12星座全て")
        else:
            print(f"  ❌ {label}: {keys}")
            issues += 1

    # 「この土地では」の残存チェック
    dust = content.count("この土地では")
    if dust == 0:
        print(f"  ✅ 「この土地では」: 完全削除")
    else:
        print(f"  ❌ 「この土地では」: {dust}箇所残存")
        issues += 1

    return issues


def check_dead_code():
    """未使用 import, 未使用変数, 残存 TODO/FIXME"""
    header("3. 不要コード検出")
    issues = 0

    files = [
        "lib/screens/horoscope_screen.dart",
        "lib/screens/horoscope/horo_bottom_sheet.dart",
        "lib/screens/horoscope/horo_planet_table.dart",
        "lib/screens/horoscope/horo_relocation_panel.dart",
        "lib/screens/horoscope/horo_relocation_templates.dart",
        "lib/screens/map_screen.dart",
        "lib/screens/locations_screen.dart",
        "lib/screens/map/map_astro.dart",
    ]
    for rel in files:
        path = f"{SOLARA}/{rel}"
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as f:
            content = f.read()
        # TODO/FIXME 検出 (このセッションで追加された分のみ)
        todos = re.findall(r"//\s*(TODO|FIXME|XXX|HACK)[\s:].*", content)
        if todos:
            print(f"  ⚠️ {rel}: {len(todos)}個の TODO/FIXME")
            issues += 1
        # console.log 残存 (Dart では print)
        prints = re.findall(r"^\s*print\s*\(", content, re.MULTILINE)
        if prints:
            print(f"  ⚠️ {rel}: {len(prints)}個の print()")
    if issues == 0:
        print("  ✅ TODO/FIXME/print デバッグ残存なし")
    return issues


def check_duplicate_definitions():
    """重複定義 (同名のクラス/定数)"""
    header("4. 重複定義チェック")
    # planetNamesJP の重複は意図せざる重複の代表例
    issues = 0
    targets = ['planetNamesJP', 'signNames', 'signColors', 'planetGlyphs']
    for name in targets:
        # search across horoscope/ folder
        found = []
        for root, _, files in os.walk(f"{LIB}/screens/horoscope"):
            for fn in files:
                if not fn.endswith(".dart"):
                    continue
                path = os.path.join(root, fn)
                with open(path, encoding="utf-8") as f:
                    content = f.read()
                # `const planetNamesJP = ` または `const Map<...> planetNamesJP = `
                if re.search(rf"const(?:\s+Map<[^>]+>)?\s+{name}\s*=", content):
                    found.append(os.path.relpath(path, SOLARA))
        if len(found) > 1:
            print(f"  ❌ {name}: 重複定義 {found}")
            issues += 1
        elif len(found) == 1:
            print(f"  ✅ {name}: 単一定義 ({found[0]})")
        else:
            print(f"  ⚠️ {name}: 定義見つからず")
    return issues


def fetch(body):
    req = urllib.request.Request(
        API, data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json",
                 "User-Agent": "Mozilla/5.0 SolaraTest"})
    return json.loads(urllib.request.urlopen(req, timeout=30).read())


def check_worker_api():
    """Worker API: relocate パラメータが期待通りに作用するか"""
    header("5. Worker API リロケーション動作")
    issues = 0
    base = {"birthDate": "1990-01-01", "birthTime": "12:00",
            "birthLat": 35.6762, "birthLng": 139.6503,
            "birthTz": 9, "mode": "natal"}
    try:
        natal = fetch(base)
    except Exception as e:
        print(f"  ❌ Worker接続失敗: {e}")
        return 1

    # NY relocate
    relocated = fetch({**base, "relocateLat": 40.7128, "relocateLng": -74.0060})

    # natal惑星位置は変わらないはず
    if natal["natal"]["sun"] == relocated["natal"]["sun"]:
        print(f"  ✅ natal sun: {natal['natal']['sun']} (relocate後も不変)")
    else:
        print(f"  ❌ natal sun: {natal['natal']['sun']} → {relocated['natal']['sun']} (変わるべきでない)")
        issues += 1

    # ASC/MCは変わるはず
    if natal["asc"] != relocated["asc"]:
        print(f"  ✅ ASC: {natal['asc']} → {relocated['asc']} (変化あり)")
    else:
        print(f"  ❌ ASC: relocate後も不変 (変わるべき)")
        issues += 1

    if natal["mc"] != relocated["mc"]:
        print(f"  ✅ MC: {natal['mc']} → {relocated['mc']} (変化あり)")
    else:
        print(f"  ❌ MC: relocate後も不変")
        issues += 1

    # housesも変わる
    if natal["houses"] != relocated["houses"]:
        print(f"  ✅ houses: 変化あり")
    else:
        print(f"  ❌ houses: relocate後も不変")
        issues += 1

    # 0/0 を渡したら relocate無効になるか
    zero_relocate = fetch({**base, "relocateLat": 0, "relocateLng": 0})
    if zero_relocate["asc"] == natal["asc"]:
        print(f"  ✅ relocateLat=0,lng=0: 出生地ハウスにフォールバック")
    else:
        print(f"  ❌ relocateLat=0,lng=0: 0/0 で relocate計算されている (バグ)")
        issues += 1

    return issues


def main():
    print(f"\n🔍 Solara M0 セッション検証スクリプト")
    print(f"   対象: {SOLARA}")

    total = 0
    total += check_file_sizes()
    total += check_template_completeness()
    total += check_dead_code()
    total += check_duplicate_definitions()
    total += check_worker_api()

    header("検証結果")
    if total == 0:
        print("  ✅ すべての検査をパス")
    else:
        print(f"  ⚠️ 検出された問題: {total}件")
    sys.exit(0 if total == 0 else 1)


if __name__ == "__main__":
    main()
