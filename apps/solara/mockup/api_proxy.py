"""
Solara API Proxy — Gemini 2.5 Flash
タロット鑑定 + ホロスコープ星読み を生成するローカルプロキシ
"""
import http.server
import json
import urllib.request
import urllib.error
import os
import re

PORT = 3915

def load_env():
    env_path = os.path.join(os.path.dirname(__file__), '..', '..', '..', '.env')
    env_path = os.path.normpath(env_path)
    if not os.path.exists(env_path):
        return
    with open(env_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, val = line.split('=', 1)
                os.environ.setdefault(key.strip(), val.strip())

load_env()

GEMINI_API_KEY = os.environ.get('GEMINI_API_KEY', '')
MODEL = 'gemini-2.5-flash'
GEMINI_API_URL = f'https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent?key={GEMINI_API_KEY}'

# ========== Tarot ==========
TAROT_SYSTEM = """あなたはSolaraの占星術タロットリーダーです。
引かれたカードの意味を読み解き、鑑定文を生成してください。

ルール:
- 450文字程度の鑑定文を生成すること
- カードの象徴・エレメント・支配惑星の意味を自然に織り込むこと
- 具体的な行動アドバイスを含めること
- スピリチュアルすぎず、日常に寄り添うトーンで書くこと

出力形式（厳守）:
鑑定文をそのまま書いた後、最終行に「---」だけの行を置き、その次の行に絵文字1つで始まる短いアドバイス1文を書いてください。
コードブロックやJSON形式は使わないでください。"""

def build_tarot_message(data):
    card_name = data.get('nameJP', '') or data.get('nameEN', '')
    card_en = data.get('nameEN', '')
    keyword = data.get('keyword', '')
    element = data.get('element', '')
    planet = data.get('planet', '')
    mood = data.get('mood', 0)
    date = data.get('date', '')
    position = '逆位置' if data.get('reversed') else '正位置'
    element_jp = {'fire': '火', 'water': '水', 'air': '風', 'earth': '地'}.get(element, element)
    mood_desc = ''
    if mood is not None:
        m = float(mood)
        if m >= 0.5: mood_desc = '気分は高揚しています'
        elif m >= 0: mood_desc = '穏やかな気分です'
        elif m >= -0.5: mood_desc = '少し沈んだ気分です'
        else: mood_desc = '深く内省的な状態です'
    return f"""本日 {date} に引かれたカード:
カード名: {card_name} ({card_en})
位置: {position}
キーワード: {keyword}
エレメント: {element_jp}
支配惑星: {planet}
現在のムード: {mood_desc}

このカードの鑑定文を生成してください。"""

# ========== Fortune (星読み) ==========
FORTUNE_SYSTEM = """あなたはSolaraの占星術リーダーです。
ホロスコープのアスペクト情報に基づいて、指定されたカテゴリの運勢鑑定文を生成してください。

ルール:
- 鑑定文には必ず実際のアスペクト情報（惑星名・角度・性質）を自然に含めること
  例: 「太陽と木星がトライン（120°）を形成しており…」
- 具体的な行動アドバイスを含めること
- スピリチュアルすぎず、日常に寄り添うトーンで書くこと
- 全体運は450文字程度、個別運（恋愛・金運・仕事・対話）は250文字程度

出力形式（厳守）:
鑑定文をそのまま書いた後、最終行に「---」だけの行を置き、その次の行に「🧭 」で始まる方位アドバイス1文を書いてください。
コードブロックやJSON形式は使わないでください。"""

CAT_JP = {'overall': '全体運', 'love': '恋愛運', 'money': '金運', 'career': '仕事運', 'communication': '対話運'}

def build_fortune_message(data):
    cat = data.get('category', 'overall')
    cat_jp = CAT_JP.get(cat, '全体運')
    aspects = data.get('aspects', 'なし')
    patterns = data.get('patterns', '')
    date = data.get('date', '')
    length = '450文字程度' if cat == 'overall' else '250文字程度'
    return f"""本日 {date} のホロスコープ鑑定:
カテゴリ: {cat_jp}
文字数: {length}

現在のアスペクト:
{aspects}

{f'パターン: {patterns}' if patterns else ''}

この情報に基づいて{cat_jp}の鑑定文を生成してください。"""

# ========== Gemini API ==========
def call_gemini(system_prompt, user_message):
    body = json.dumps({
        'system_instruction': {'parts': [{'text': system_prompt}]},
        'contents': [{'parts': [{'text': user_message}]}],
        'generationConfig': {'temperature': 0.9, 'maxOutputTokens': 8192, 'thinkingConfig': {'thinkingBudget': 0}}
    }).encode('utf-8')
    req = urllib.request.Request(
        GEMINI_API_URL, data=body,
        headers={'Content-Type': 'application/json'}, method='POST'
    )
    resp = urllib.request.urlopen(req, timeout=30)
    result = json.loads(resp.read())
    text = result.get('candidates', [{}])[0].get('content', {}).get('parts', [{}])[0].get('text', '')
    if '---' in text:
        parts = text.split('---', 1)
        return {'reading': parts[0].strip(), 'advice': parts[1].strip() if len(parts) > 1 else ''}
    return {'reading': text.strip(), 'advice': ''}

# ========== HTTP Server ==========
class ProxyHandler(http.server.BaseHTTPRequestHandler):
    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_POST(self):
        if self.path not in ('/api/tarot-reading', '/api/fortune-reading'):
            self.send_response(404)
            self.end_headers()
            return
        if not GEMINI_API_KEY:
            self._err(500, 'GEMINI_API_KEY not set in .env')
            return
        try:
            length = int(self.headers.get('Content-Length', 0))
            data = json.loads(self.rfile.read(length))
            if self.path == '/api/tarot-reading':
                result = call_gemini(TAROT_SYSTEM, build_tarot_message(data))
            else:
                result = call_gemini(FORTUNE_SYSTEM, build_fortune_message(data))
            self._ok(result)
        except urllib.error.HTTPError as e:
            self._err(502, f'Gemini API error: {e.code}')
        except Exception as e:
            print(f'Error: {e}')
            self._err(500, str(e))

    def _ok(self, data):
        self.send_response(200)
        self._cors()
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.end_headers()
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))

    def _err(self, code, msg):
        self.send_response(code)
        self._cors()
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps({'error': msg}).encode('utf-8'))

    def log_message(self, fmt, *args):
        print(f'[proxy] {args[0]}')

if __name__ == '__main__':
    if not GEMINI_API_KEY:
        print('WARNING: GEMINI_API_KEY not found')
    else:
        print(f'Key loaded (...{GEMINI_API_KEY[-4:]})')
    print(f'Solara API proxy (Gemini Flash) on port {PORT}')
    server = http.server.HTTPServer(('127.0.0.1', PORT), ProxyHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.server_close()
