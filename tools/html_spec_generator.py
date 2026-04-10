"""
Solara HTML仕様書 自動生成スクリプト
=====================================
HTMLモックから各画面の仕様書（Markdown）を生成する。

使い方:
  python tools/html_spec_generator.py

出力先:
  apps/solara/specs/spec_[画面名].md
"""

import os
import re
from html.parser import HTMLParser

# --- 設定 ---
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MOCKUP_DIR = os.path.join(BASE_DIR, "apps", "solara", "mockup")
SPECS_DIR = os.path.join(BASE_DIR, "apps", "solara", "specs")
SHARED_CSS_PATH = os.path.join(MOCKUP_DIR, "shared", "styles.css")

# 対象画面
SCREENS = {
    "map": {"file": "index.html", "title": "Map（世界地図・運勢方位）"},
    "horoscope": {"file": "horoscope.html", "title": "Horoscope（ホロスコープチャート）"},
    "tarot": {"file": "tarot.html", "title": "Tarot（タロット占い）"},
    "galaxy": {"file": "galaxy.html", "title": "Galaxy（銀河・星座）"},
    "sanctuary": {"file": "sanctuary.html", "title": "Sanctuary（サンクチュアリ・プロフィール）"},
}


# =========================================================
#  CSS パーサー: styles.css + インラインCSS から値を抽出
# =========================================================
def parse_css_blocks(css_text):
    """CSSテキストからセレクタ→プロパティ辞書を返す"""
    rules = {}
    # コメント除去
    css_text = re.sub(r'/\*.*?\*/', '', css_text, flags=re.DOTALL)
    # @keyframes, @import, @media は一旦スキップ（ネストの中身は無視）
    css_text = re.sub(r'@keyframes\s+[\w-]+\s*\{[^}]*(\{[^}]*\}[^}]*)*\}', '', css_text, flags=re.DOTALL)
    css_text = re.sub(r'@import[^;]+;', '', css_text)

    # セレクタ { プロパティ } のパターン
    pattern = re.compile(r'([^{}]+?)\{([^}]*)\}', re.DOTALL)
    for m in pattern.finditer(css_text):
        selector = m.group(1).strip()
        if selector.startswith('@'):
            continue
        props_text = m.group(2).strip()
        props = {}
        for line in props_text.split(';'):
            line = line.strip()
            if ':' in line:
                key, val = line.split(':', 1)
                props[key.strip()] = val.strip()
        if props:
            rules[selector] = props
    return rules


def load_css_variables(css_text):
    """CSS変数（:root）を解決"""
    variables = {}
    root_match = re.search(r':root\s*\{([^}]+)\}', css_text)
    if root_match:
        for line in root_match.group(1).split(';'):
            line = line.strip()
            if line.startswith('--'):
                key, val = line.split(':', 1)
                variables[key.strip()] = val.strip()
    return variables


def resolve_var(value, variables):
    """var(--name) を実際の値に置換"""
    def replacer(m):
        var_name = m.group(1).split(',')[0].strip()
        return variables.get(var_name, m.group(0))
    return re.sub(r'var\((--[\w-]+)(?:,[^)]+)?\)', replacer, value)


# =========================================================
#  HTML パーサー: body 内の要素を木構造で取得
# =========================================================
class BodyElementParser(HTMLParser):
    """HTMLのbody内要素を解析"""

    # インラインの要素はスキップ
    SKIP_TAGS = {'script', 'style', 'link', 'meta', 'head', 'html', 'br', 'hr', 'img', 'input', 'source'}
    # 意味のある属性
    IMPORTANT_ATTRS = {'id', 'class', 'data-screen', 'data-tab', 'data-type', 'role', 'aria-label', 'placeholder'}

    def __init__(self):
        super().__init__()
        self.in_body = False
        self.elements = []  # (depth, tag, attrs_dict, text_preview)
        self.depth = 0
        self.current_text = ""
        self.skip_depth = 0  # script/style 内をスキップ

    def handle_starttag(self, tag, attrs):
        if tag == 'body':
            self.in_body = True
            return
        if not self.in_body:
            return
        if tag in ('script', 'style'):
            self.skip_depth = self.depth + 1
            return
        if self.skip_depth > 0:
            return

        attrs_dict = dict(attrs)
        important = {k: v for k, v in attrs_dict.items() if k in self.IMPORTANT_ATTRS}

        self.elements.append({
            'depth': self.depth,
            'tag': tag,
            'attrs': important,
            'id': attrs_dict.get('id', ''),
            'class': attrs_dict.get('class', ''),
            'text': '',
        })
        self.depth += 1

    def handle_endtag(self, tag):
        if tag == 'body':
            self.in_body = False
            return
        if tag in ('script', 'style'):
            self.skip_depth = 0
            return
        if self.skip_depth > 0:
            return
        if self.in_body and self.depth > 0:
            self.depth -= 1

    def handle_data(self, data):
        if self.skip_depth > 0 or not self.in_body:
            return
        text = data.strip()
        if text and self.elements:
            # 最後の要素にテキストを追加
            if len(self.elements[-1]['text']) < 60:
                self.elements[-1]['text'] = text[:60]


# =========================================================
#  JS パーサー: イベント・関数・API呼び出しを抽出
# =========================================================
def extract_js_info(html_text):
    """インラインJSからイベント、関数定義、API呼び出しを抽出"""
    # インラインscript部分を取得
    scripts = re.findall(r'<script(?:\s[^>]*)?>(.+?)</script>', html_text, re.DOTALL)
    # 外部srcのスクリプトは除外
    inline_scripts = []
    for i, s in enumerate(scripts):
        # srcがある場合のscriptタグは中身が空
        if s.strip():
            inline_scripts.append(s)

    js_text = '\n'.join(inline_scripts)

    # --- イベントリスナー ---
    events = []
    # addEventListener パターン
    for m in re.finditer(
        r"""(?:getElementById|querySelector|querySelectorAll)\s*\(\s*['"]([^'"]+)['"]\s*\)[\s\S]*?\.addEventListener\s*\(\s*['"](\w+)['"]""",
        js_text
    ):
        events.append({'target': m.group(1), 'event': m.group(2)})

    # 変数.addEventListener パターン
    for m in re.finditer(
        r"""(\w+)\.addEventListener\s*\(\s*['"](\w+)['"]""",
        js_text
    ):
        target = m.group(1)
        if target not in ('document', 'window'):
            events.append({'target': target, 'event': m.group(2)})
        else:
            events.append({'target': target, 'event': m.group(2)})

    # onclick= in HTML
    for m in re.finditer(r'onclick\s*=\s*["\']([^"\']+)["\']', html_text):
        events.append({'target': '(HTML属性)', 'event': 'click', 'handler': m.group(1)})

    # --- 関数定義 ---
    functions = []
    # function name() パターン
    for m in re.finditer(r'(?:async\s+)?function\s+(\w+)\s*\(([^)]*)\)', js_text):
        functions.append({'name': m.group(1), 'params': m.group(2).strip()})
    # const name = (...) => パターン
    for m in re.finditer(r'(?:const|let|var)\s+(\w+)\s*=\s*(?:async\s+)?\(?([^)]*)\)?\s*=>', js_text):
        functions.append({'name': m.group(1), 'params': m.group(2).strip()})

    # --- API呼び出し ---
    api_calls = []
    for m in re.finditer(r'fetch\s*\(\s*[`\'"]([^`\'"]*)[`\'"]', js_text):
        api_calls.append(m.group(1))
    for m in re.finditer(r'fetch\s*\(\s*(\w+)', js_text):
        var_name = m.group(1)
        if var_name not in ('response', 'data', 'result', 'error'):
            api_calls.append(f'${{{var_name}}}（変数）')

    # --- グローバル変数/定数 ---
    globals_list = []
    for m in re.finditer(r'^(?:const|let|var)\s+(\w+)\s*=\s*(.{1,80})', js_text, re.MULTILINE):
        name = m.group(1)
        val_preview = m.group(2).strip().rstrip(';')
        if not name.startswith('_') and name[0].isupper() or name.upper() == name:
            globals_list.append({'name': name, 'value': val_preview[:60]})

    return {
        'events': events,
        'functions': functions,
        'api_calls': api_calls,
        'globals': globals_list,
        'js_lines': len(js_text.splitlines()),
    }


# =========================================================
#  インラインCSS抽出
# =========================================================
def extract_inline_css(html_text):
    """<style>タグ内のCSSを全て結合"""
    styles = re.findall(r'<style[^>]*>(.*?)</style>', html_text, re.DOTALL)
    return '\n'.join(styles)


# =========================================================
#  仕様書 Markdown 生成
# =========================================================
def generate_spec(screen_name, screen_info, shared_css_text, shared_variables):
    """1画面分の仕様書を生成"""
    html_path = os.path.join(MOCKUP_DIR, screen_info['file'])
    with open(html_path, 'r', encoding='utf-8') as f:
        html_text = f.read()

    total_lines = len(html_text.splitlines())

    # --- CSS解析 ---
    inline_css = extract_inline_css(html_text)
    inline_rules = parse_css_blocks(inline_css)
    shared_rules = parse_css_blocks(shared_css_text)

    # 全CSS変数
    inline_vars = load_css_variables(inline_css)
    all_variables = {**shared_variables, **inline_vars}

    # --- HTML要素解析 ---
    parser = BodyElementParser()
    parser.feed(html_text)
    elements = parser.elements

    # --- JS解析 ---
    js_info = extract_js_info(html_text)

    # === Markdown生成 ===
    lines = []
    lines.append(f"# {screen_info['title']}")
    lines.append(f"")
    lines.append(f"**ソースファイル**: `mockup/{screen_info['file']}`")
    lines.append(f"**HTML行数**: {total_lines}行（うちJS約{js_info['js_lines']}行）")
    lines.append(f"**イベント数**: {len(js_info['events'])}個")
    lines.append(f"**API呼び出し**: {len(js_info['api_calls'])}箇所")
    lines.append(f"")

    # --- 日本語メモセクション（手動記入用） ---
    lines.append(f"---")
    lines.append(f"## この画面の説明（日本語メモ）")
    lines.append(f"")
    lines.append(f"> ここにオーナーが日本語で画面の説明を書く。")
    lines.append(f"> 例：「世界地図が表示される。タップした場所の運勢が見れる。」")
    lines.append(f"")

    # --- 要素一覧 ---
    lines.append(f"---")
    lines.append(f"## 要素一覧（HTML上から順）")
    lines.append(f"")

    # 深さ2まで表示（深すぎるとノイズになる）
    MAX_DISPLAY_DEPTH = 3
    elem_count = 0
    for el in elements:
        if el['depth'] > MAX_DISPLAY_DEPTH:
            continue
        elem_count += 1
        indent = "  " * el['depth']
        tag = el['tag']
        el_id = el['id']
        el_class = el['class']

        # 識別子
        identifier = ""
        if el_id:
            identifier = f"#{el_id}"
        elif el_class:
            first_class = el_class.split()[0]
            identifier = f".{first_class}"

        # CSS値を探す
        css_props = {}
        if el_id:
            for selector in [f"#{el_id}", f"{tag}#{el_id}"]:
                if selector in inline_rules:
                    css_props.update(inline_rules[selector])
                if selector in shared_rules:
                    css_props.update(shared_rules[selector])
        if el_class:
            for cls in el_class.split():
                for selector in [f".{cls}", f"{tag}.{cls}"]:
                    if selector in inline_rules:
                        css_props.update(inline_rules[selector])
                    if selector in shared_rules:
                        css_props.update(shared_rules[selector])

        # 重要なCSSプロパティだけ表示
        IMPORTANT_CSS = [
            'width', 'height', 'max-width', 'min-height',
            'font-size', 'font-weight', 'font-family',
            'color', 'background', 'background-color',
            'padding', 'margin', 'border-radius',
            'position', 'top', 'left', 'right', 'bottom',
            'display', 'flex-direction', 'gap', 'z-index',
            'opacity', 'overflow',
        ]
        css_display = {}
        for prop in IMPORTANT_CSS:
            if prop in css_props:
                val = resolve_var(css_props[prop], all_variables)
                css_display[prop] = val

        # 1行にまとめる
        text_hint = f' — テキスト:「{el["text"][:30]}」' if el['text'] else ''
        css_hint = ""
        if css_display:
            css_parts = [f"{k}:{v}" for k, v in list(css_display.items())[:6]]
            css_hint = f"\n{indent}  CSS: {'; '.join(css_parts)}"

        lines.append(f"{indent}{elem_count}. `<{tag}{' ' + identifier if identifier else ''}>`{text_hint}{css_hint}")

    lines.append(f"")
    lines.append(f"**要素総数（depth≤{MAX_DISPLAY_DEPTH}）**: {elem_count}個")
    lines.append(f"")

    # --- インタラクション一覧 ---
    lines.append(f"---")
    lines.append(f"## インタラクション一覧（イベントハンドラ）")
    lines.append(f"")

    if js_info['events']:
        seen = set()
        for i, ev in enumerate(js_info['events'], 1):
            key = f"{ev['target']}_{ev['event']}"
            if key in seen:
                continue
            seen.add(key)
            handler = ev.get('handler', '')
            handler_hint = f" → `{handler}`" if handler else ""
            lines.append(f"{i}. **{ev['target']}** の `{ev['event']}` イベント{handler_hint}")
            lines.append(f"   > 動作メモ:（ここに日本語で何が起きるか書く）")
            lines.append(f"")
    else:
        lines.append(f"（イベントなし）")
        lines.append(f"")

    # --- 関数一覧 ---
    lines.append(f"---")
    lines.append(f"## 関数一覧（インラインJS）")
    lines.append(f"")

    if js_info['functions']:
        for i, fn in enumerate(js_info['functions'], 1):
            params = fn['params'] if fn['params'] else '（なし）'
            lines.append(f"{i}. `{fn['name']}({fn['params']})` — 説明:（ここに日本語で書く）")
    else:
        lines.append(f"（関数定義なし）")
    lines.append(f"")

    # --- API呼び出し ---
    lines.append(f"---")
    lines.append(f"## API呼び出し")
    lines.append(f"")

    if js_info['api_calls']:
        for i, url in enumerate(js_info['api_calls'], 1):
            lines.append(f"{i}. `{url}`")
            lines.append(f"   > 用途:（ここに日本語で書く）")
            lines.append(f"")
    else:
        lines.append(f"（API呼び出しなし）")
        lines.append(f"")

    # --- CSS変数（このページで使われているもの） ---
    lines.append(f"---")
    lines.append(f"## 使用CSS変数")
    lines.append(f"")
    lines.append(f"| 変数名 | 値 |")
    lines.append(f"|--------|-----|")
    # HTMLとインラインCSS内で参照されているvar()を探す
    used_vars = set(re.findall(r'var\((--[\w-]+)', html_text))
    used_vars.update(re.findall(r'var\((--[\w-]+)', inline_css))
    for var_name in sorted(used_vars):
        val = all_variables.get(var_name, '（未定義）')
        lines.append(f"| `{var_name}` | `{val}` |")
    lines.append(f"")

    return '\n'.join(lines)


# =========================================================
#  メイン実行
# =========================================================
def main():
    # 出力ディレクトリ作成
    os.makedirs(SPECS_DIR, exist_ok=True)

    # 共通CSS読み込み
    with open(SHARED_CSS_PATH, 'r', encoding='utf-8') as f:
        shared_css_text = f.read()
    shared_variables = load_css_variables(shared_css_text)

    print("=" * 50)
    print("Solara 仕様書自動生成")
    print("=" * 50)

    for screen_name, screen_info in SCREENS.items():
        print(f"\n  生成中: {screen_info['title']}...")
        spec_content = generate_spec(screen_name, screen_info, shared_css_text, shared_variables)

        output_path = os.path.join(SPECS_DIR, f"spec_{screen_name}.md")
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(spec_content)
        print(f"  → {output_path}")

    # 共通CSS変数の一覧も出力
    print(f"\n  生成中: 共通CSS変数一覧...")
    var_lines = ["# Solara 共通デザイントークン", ""]
    var_lines.append("**ソースファイル**: `mockup/shared/styles.css`")
    var_lines.append("")
    var_lines.append("| 変数名 | 値 | 用途メモ |")
    var_lines.append("|--------|-----|---------|")
    for name, val in sorted(shared_variables.items()):
        var_lines.append(f"| `{name}` | `{val}` | （ここに日本語で書く） |")
    var_lines.append("")

    var_path = os.path.join(SPECS_DIR, "shared_tokens.md")
    with open(var_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(var_lines))
    print(f"  → {var_path}")

    print(f"\n{'=' * 50}")
    print(f"完了！ 出力先: {SPECS_DIR}")
    print(f"{'=' * 50}")


if __name__ == '__main__':
    main()
