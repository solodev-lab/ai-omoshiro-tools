"""
Solara 重複機能・未使用コード検出スクリプト
=============================================
HTMLモック内のJSを解析して:
  1. 全関数を抽出
  2. 各関数がどのDOM要素を操作するか特定
  3. 関数間の呼び出し関係（コールグラフ）を構築
  4. エントリーポイント（イベントハンドラ/onload）から到達可能か判定
  5. 同じDOM要素を操作する関数をグループ化 → 重複を検出
  6. どこからも呼ばれていない関数を検出 → 削除候補

使い方:
  python tools/dead_code_detector.py
  python tools/dead_code_detector.py --screen horoscope

出力先:
  apps/solara/specs/analysis_[画面名].md
"""

import os
import re
import sys
import argparse

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MOCKUP_DIR = os.path.join(BASE_DIR, "apps", "solara", "mockup")
SPECS_DIR = os.path.join(BASE_DIR, "apps", "solara", "specs")

SCREENS = {
    "map": {"file": "index.html", "title": "Map（世界地図・運勢方位）"},
    "horoscope": {"file": "horoscope.html", "title": "Horoscope（ホロスコープチャート）"},
    "tarot": {"file": "tarot.html", "title": "Tarot（タロット占い）"},
    "galaxy": {"file": "galaxy.html", "title": "Galaxy（銀河・星座）"},
    "sanctuary": {"file": "sanctuary.html", "title": "Sanctuary（サンクチュアリ・プロフィール）"},
}


def extract_inline_js(html_text):
    """インラインscriptの中身を全て結合して返す（行番号オフセット付き）"""
    segments = []
    for m in re.finditer(r'<script(?:\s[^>]*)?>(.*?)</script>', html_text, re.DOTALL):
        content = m.group(1)
        if not content.strip():
            continue
        # src= がある場合は外部ファイルなのでスキップ
        tag = html_text[m.start():m.start() + html_text[m.start():].index('>') + 1]
        if 'src=' in tag:
            continue
        start_line = html_text[:m.start(1)].count('\n') + 1
        segments.append({'code': content, 'start_line': start_line})
    return segments


def extract_functions(js_segments):
    """JS関数定義を全て抽出"""
    functions = {}

    for seg in js_segments:
        code = seg['code']
        offset = seg['start_line']

        # function name() { パターン
        for m in re.finditer(r'(?:async\s+)?function\s+(\w+)\s*\(([^)]*)\)', code):
            name = m.group(1)
            line = offset + code[:m.start()].count('\n')
            # 関数の本体を取得（{ から対応する } まで）
            body_start = code.index('{', m.end())
            body = extract_body(code, body_start)
            functions[name] = {
                'name': name,
                'params': m.group(2).strip(),
                'line': line,
                'body': body,
                'type': 'function',
            }

        # const/var/let name = function() / (...) => パターン
        for m in re.finditer(r'(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s+)?(?:function\s*\(([^)]*)\)|(?:\(([^)]*)\)|(\w+))\s*=>)', code):
            name = m.group(1)
            line = offset + code[:m.start()].count('\n')
            params = m.group(2) or m.group(3) or m.group(4) or ''
            # 本体取得
            rest = code[m.end():]
            body = ''
            if rest.lstrip().startswith('{'):
                brace_pos = code.index('{', m.end())
                body = extract_body(code, brace_pos)
            else:
                # 式本体のアロー関数
                end = rest.find(';')
                if end > 0:
                    body = rest[:end]
            functions[name] = {
                'name': name,
                'params': params.strip(),
                'line': line,
                'body': body,
                'type': 'arrow/expr',
            }

    return functions


def extract_body(code, brace_start):
    """{ から対応する } までの本体を取得"""
    depth = 0
    i = brace_start
    while i < len(code):
        if code[i] == '{':
            depth += 1
        elif code[i] == '}':
            depth -= 1
            if depth == 0:
                return code[brace_start:i + 1]
        # 文字列リテラルをスキップ
        elif code[i] in ('"', "'", '`'):
            quote = code[i]
            i += 1
            while i < len(code) and code[i] != quote:
                if code[i] == '\\':
                    i += 1
                i += 1
        i += 1
    return code[brace_start:brace_start + 500]  # fallback


def find_dom_operations(body):
    """関数本体からDOM操作を抽出"""
    ops = []

    # getElementById
    for m in re.finditer(r'getElementById\s*\(\s*[\'"](\w+)[\'"]\s*\)', body):
        ops.append({'element': '#' + m.group(1), 'op': 'getById'})

    # querySelector / querySelectorAll
    for m in re.finditer(r'querySelector(?:All)?\s*\(\s*[\'"]([^"\']+)[\'"]\s*\)', body):
        ops.append({'element': m.group(1), 'op': 'querySelector'})

    # .innerHTML =
    for m in re.finditer(r'(\w+)\.innerHTML\s*[\+]?=', body):
        ops.append({'element': m.group(1) + '.innerHTML', 'op': 'write'})

    # .textContent =
    for m in re.finditer(r'(\w+)\.textContent\s*=', body):
        ops.append({'element': m.group(1) + '.textContent', 'op': 'write'})

    # .style.
    for m in re.finditer(r'(\w+)\.style\.(\w+)\s*=', body):
        ops.append({'element': m.group(1) + '.style', 'op': 'style'})

    # classList
    for m in re.finditer(r'(\w+)\.classList\.(add|remove|toggle)', body):
        ops.append({'element': m.group(1) + '.classList', 'op': 'class'})

    return ops


def find_function_calls(body, all_function_names):
    """関数本体から他の関数の呼び出しを検出"""
    calls = set()
    for name in all_function_names:
        # 関数名( のパターンで検索（定義自体は除外）
        pattern = r'(?<!\w)' + re.escape(name) + r'\s*\('
        if re.search(pattern, body):
            calls.add(name)
    return calls


def find_entry_points(html_text, js_segments):
    """エントリーポイント（イベントハンドラ）を検出"""
    entries = []

    # onclick="func()" 等のHTML属性
    for m in re.finditer(r'on(?:click|change|input|load|submit|keydown|keyup|keypress|touchstart|touchend|mousedown|mouseup)\s*=\s*["\']([^"\']+)["\']', html_text):
        handler = m.group(1)
        # 関数名を抽出
        func_match = re.match(r'(\w+)\s*\(', handler)
        if func_match:
            entries.append({'type': 'HTML属性', 'function': func_match.group(1), 'detail': handler[:50]})

    # addEventListener
    for seg in js_segments:
        code = seg['code']
        for m in re.finditer(r'\.addEventListener\s*\(\s*[\'"](\w+)[\'"]\s*,\s*(?:function|\(|(\w+))', code):
            event_type = m.group(1)
            func_name = m.group(2)
            if func_name:
                entries.append({'type': 'addEventListener', 'function': func_name, 'detail': event_type})

    # window.onload / DOMContentLoaded
    for seg in js_segments:
        code = seg['code']
        for m in re.finditer(r'window\.onload\s*=\s*(\w+)', code):
            entries.append({'type': 'window.onload', 'function': m.group(1), 'detail': ''})
        # 即時実行関数内の呼び出し（トップレベル）
        for m in re.finditer(r'^\s*(\w+)\s*\(\s*\)\s*;?\s*$', code, re.MULTILINE):
            entries.append({'type': 'トップレベル呼出', 'function': m.group(1), 'detail': ''})

    return entries


def trace_reachable(entry_functions, functions):
    """エントリーポイントから到達可能な関数を再帰的にトレース"""
    all_names = set(functions.keys())
    reachable = set()
    stack = list(entry_functions)

    while stack:
        name = stack.pop()
        if name in reachable or name not in functions:
            continue
        reachable.add(name)
        calls = find_function_calls(functions[name]['body'], all_names)
        for c in calls:
            if c != name and c not in reachable:
                stack.append(c)

    return reachable


def group_by_dom_target(functions):
    """同じDOM要素を操作する関数をグループ化"""
    element_to_funcs = {}

    for name, fn in functions.items():
        ops = find_dom_operations(fn['body'])
        fn['dom_ops'] = ops

        # getElementById で見つかった要素IDでグループ化
        for op in ops:
            if op['op'] == 'getById':
                el = op['element']
                if el not in element_to_funcs:
                    element_to_funcs[el] = []
                if name not in [f['name'] for f in element_to_funcs[el]]:
                    element_to_funcs[el].append(fn)

    return element_to_funcs


def analyze_screen(screen_name, screen_info):
    """1画面を解析"""
    html_path = os.path.join(MOCKUP_DIR, screen_info['file'])
    with open(html_path, 'r', encoding='utf-8') as f:
        html_text = f.read()

    # JS抽出
    js_segments = extract_inline_js(html_text)

    # 関数抽出
    functions = extract_functions(js_segments)
    all_names = set(functions.keys())

    # コールグラフ構築
    for name, fn in functions.items():
        fn['calls'] = find_function_calls(fn['body'], all_names - {name})
        fn['called_by'] = set()

    for name, fn in functions.items():
        for callee in fn['calls']:
            if callee in functions:
                functions[callee]['called_by'].add(name)

    # エントリーポイント検出
    entries = find_entry_points(html_text, js_segments)
    entry_func_names = set(e['function'] for e in entries)

    # 到達可能性トレース
    reachable = trace_reachable(entry_func_names, functions)

    for name, fn in functions.items():
        fn['reachable'] = name in reachable

    # DOM操作グループ化
    dom_groups = group_by_dom_target(functions)

    # 重複検出: 同じDOM要素を操作する関数が2つ以上
    conflicts = {}
    for el, funcs in dom_groups.items():
        if len(funcs) >= 2:
            conflicts[el] = funcs

    # 未使用関数
    unreachable = [fn for name, fn in functions.items() if not fn['reachable']]
    unreachable.sort(key=lambda f: f['line'])

    return {
        'functions': functions,
        'entries': entries,
        'reachable': reachable,
        'dom_groups': dom_groups,
        'conflicts': conflicts,
        'unreachable': unreachable,
    }


def generate_report(screen_name, screen_info, analysis):
    """Markdownレポート生成"""
    lines = []
    functions = analysis['functions']
    entries = analysis['entries']
    conflicts = analysis['conflicts']
    unreachable = analysis['unreachable']
    dom_groups = analysis['dom_groups']

    lines.append(f"# {screen_info['title']} — 機能分析レポート")
    lines.append(f"")
    lines.append(f"**ソース**: `mockup/{screen_info['file']}`")
    lines.append(f"**関数総数**: {len(functions)}個")
    lines.append(f"**エントリーポイント**: {len(entries)}個")
    lines.append(f"**到達可能な関数**: {len(analysis['reachable'])}個")
    lines.append(f"**到達不可能（未使用候補）**: {len(unreachable)}個")
    lines.append(f"**DOM操作の重複箇所**: {len(conflicts)}箇所")
    lines.append(f"")

    # ============================================
    # セクション1: 重複箇所（最重要）
    # ============================================
    lines.append(f"---")
    lines.append(f"## ⚠️ 同じ場所を操作する関数（重複候補）")
    lines.append(f"")
    if conflicts:
        lines.append(f"> 同じDOM要素を複数の関数が操作している箇所。")
        lines.append(f"> 古い方を削除するか、統合を検討してください。")
        lines.append(f"")
        for el, funcs in sorted(conflicts.items()):
            lines.append(f"### `{el}`")
            lines.append(f"")
            for fn in funcs:
                status = "✅ 実行中" if fn['reachable'] else "❌ 未使用"
                called_by = ', '.join(fn['called_by']) if fn['called_by'] else 'なし'
                lines.append(f"- **[{status}]** `{fn['name']}()` (L{fn['line']})")
                lines.append(f"  - 呼出元: {called_by}")
                # DOM操作の詳細
                dom_ops_for_el = [op for op in fn['dom_ops'] if op['element'] == el]
                if dom_ops_for_el:
                    ops_str = ', '.join(set(op['op'] for op in dom_ops_for_el))
                    lines.append(f"  - 操作: {ops_str}")
            lines.append(f"")
    else:
        lines.append(f"（重複なし）")
        lines.append(f"")

    # ============================================
    # セクション2: 未使用関数
    # ============================================
    lines.append(f"---")
    lines.append(f"## ❌ 未使用関数（削除候補）")
    lines.append(f"")
    if unreachable:
        lines.append(f"> どのイベントハンドラからも到達できない関数。")
        lines.append(f"> 古い実装の残骸の可能性が高い。")
        lines.append(f"")
        for fn in unreachable:
            lines.append(f"- `{fn['name']}({fn['params']})` — L{fn['line']}")
            if fn['dom_ops']:
                targets = set(op['element'] for op in fn['dom_ops'])
                lines.append(f"  - 操作対象: {', '.join(sorted(targets))}")
            lines.append(f"  > メモ:（この関数が何だったか覚えていたら書く）")
            lines.append(f"")
    else:
        lines.append(f"（全関数が到達可能 — 未使用なし）")
        lines.append(f"")

    # ============================================
    # セクション3: エントリーポイント一覧
    # ============================================
    lines.append(f"---")
    lines.append(f"## 🎯 エントリーポイント（操作の起点）")
    lines.append(f"")
    lines.append(f"| 種類 | 関数 | 詳細 |")
    lines.append(f"|------|------|------|")
    seen_entries = set()
    for e in entries:
        key = f"{e['function']}_{e['type']}"
        if key in seen_entries:
            continue
        seen_entries.add(key)
        lines.append(f"| {e['type']} | `{e['function']}()` | {e['detail']} |")
    lines.append(f"")

    # ============================================
    # セクション4: DOM要素 → 関数マッピング
    # ============================================
    lines.append(f"---")
    lines.append(f"## 📍 DOM要素と操作する関数の対応表")
    lines.append(f"")
    lines.append(f"> 各DOM要素を「誰が」操作しているかの一覧。")
    lines.append(f"")
    for el, funcs in sorted(dom_groups.items()):
        func_names = ', '.join(f"`{fn['name']}()`" for fn in funcs)
        marker = " ⚠️" if len(funcs) >= 2 else ""
        lines.append(f"- `{el}` ← {func_names}{marker}")
    lines.append(f"")

    # ============================================
    # セクション5: 全関数一覧（コールグラフ付き）
    # ============================================
    lines.append(f"---")
    lines.append(f"## 📋 全関数一覧")
    lines.append(f"")

    sorted_funcs = sorted(functions.values(), key=lambda f: f['line'])
    for fn in sorted_funcs:
        status = "✅" if fn['reachable'] else "❌"
        calls_str = ', '.join(sorted(fn['calls'])) if fn['calls'] else 'なし'
        called_by_str = ', '.join(sorted(fn['called_by'])) if fn['called_by'] else 'なし'
        lines.append(f"### {status} `{fn['name']}({fn['params']})` — L{fn['line']}")
        lines.append(f"- 呼出先: {calls_str}")
        lines.append(f"- 呼出元: {called_by_str}")
        if fn['dom_ops']:
            targets = set(op['element'] for op in fn['dom_ops'])
            lines.append(f"- DOM操作: {', '.join(sorted(targets))}")
        lines.append(f"")

    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description='Solara 重複機能・未使用コード検出')
    parser.add_argument('--screen', type=str, help='解析する画面名 (map/horoscope/tarot/galaxy/sanctuary)')
    args = parser.parse_args()

    os.makedirs(SPECS_DIR, exist_ok=True)

    targets = SCREENS
    if args.screen:
        if args.screen not in SCREENS:
            print(f"エラー: '{args.screen}' は不明な画面名です。")
            print(f"選択肢: {', '.join(SCREENS.keys())}")
            sys.exit(1)
        targets = {args.screen: SCREENS[args.screen]}

    print("=" * 50)
    print("Solara 重複機能・未使用コード検出")
    print("=" * 50)

    for screen_name, screen_info in targets.items():
        print(f"\n  解析中: {screen_info['title']}...")

        analysis = analyze_screen(screen_name, screen_info)
        report = generate_report(screen_name, screen_info, analysis)

        output_path = os.path.join(SPECS_DIR, f"analysis_{screen_name}.md")
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(report)

        # サマリー表示
        print(f"  → {output_path}")
        print(f"    関数: {len(analysis['functions'])}個")
        print(f"    未使用候補: {len(analysis['unreachable'])}個")
        print(f"    重複箇所: {len(analysis['conflicts'])}箇所")

    print(f"\n{'=' * 50}")
    print(f"完了！ 出力先: {SPECS_DIR}")
    print(f"{'=' * 50}")


if __name__ == '__main__':
    main()
