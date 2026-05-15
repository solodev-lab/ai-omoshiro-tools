"""
Solara (ii) AI 相談 Stage 3 (Phase 2-2) 静的検証スクリプト

検証内容:
  Worker 側
    1. consultation.js が存在し handleConsultation を export
    2. callGemini を fortune.js から import
    3. プロンプト 9 項目ガード (吉凶禁止 / 候補差別化 / 悩み照射 /
       無いものを在ると言わない / 強い線中心 / outro 禁止フレーズ + awareness /
       文体ハイブリッド / energyLabels / 名前ルール) のキーワードが含まれる
    4. staticFallback が export されているか、または handleConsultation 内で
       AI 失敗時に呼ばれている
    5. index.js で /astro/consultation ルートが POST 登録されている
    6. fortune.js callGemini が thinkingBudget opt を受け取れる

flutter analyze や Gemini 実呼出は別工程。このスクリプトは静的構造のみ確認。

Run: python apps/solara/worker/verify_consultation.py
"""
import os
import re
import sys

# このスクリプトは apps/solara/worker/ 配下にあるので、それを基準に解決。
# worktree でも main でも動くようにスクリプト位置から逆算する。
HERE = os.path.dirname(os.path.abspath(__file__))
SOLARA = os.path.dirname(HERE)
REPO_ROOT = os.path.dirname(os.path.dirname(SOLARA))
WORKER_SRC = os.path.join(HERE, "src")

errors = []
passes = []


def check(cond, msg_ok, msg_fail):
    if cond:
        passes.append(msg_ok)
    else:
        errors.append(msg_fail)


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


# ── 1. consultation.js ───────────────────────────────────────
consult_path = f"{WORKER_SRC}/consultation.js"
check(
    os.path.exists(consult_path),
    "consultation.js exists",
    "consultation.js NOT FOUND",
)
if not os.path.exists(consult_path):
    print("\n".join(f"  [FAIL]{e}" for e in errors))
    sys.exit(1)

consult = read(consult_path)

check(
    "export async function handleConsultation" in consult,
    "handleConsultation export found",
    "handleConsultation export MISSING",
)
check(
    "import { callGemini } from './fortune.js'" in consult,
    "callGemini imported from fortune.js",
    "callGemini import MISSING",
)

# 9 項目プロンプトガードのキーワード (必須語)
guards = [
    ("吉凶判定をしない", "Guard 1: 吉凶判定禁止"),
    ("ラッキー", "Guard 1/6: ラッキー 禁止フレーズ"),
    ("Soft", "Guard 1: Soft/Hard 独立"),
    ("Hard", "Guard 1: Soft/Hard 独立"),
    ("候補ごとに性格を鋭く差別化", "Guard 2: 差別化"),
    ("相談者の悩み", "Guard 3: 悩み照射"),
    ("線が無い候補は正直に", "Guard 4: 無いものを在ると言わない"),
    ("最も近い", "Guard 5: 強い線中心"),
    ("選ぶのはあなた", "Guard 6: outro 禁止フレーズ"),
    ("awareness", "Guard 6: awareness 種"),
    ("世界の全部ではない", "Guard 6: 候補は全部じゃない"),
    ("見えていない最高", "Guard 6: 見えていない最高"),
    ("予想外", "Guard 6: 予想外も気づきに"),
    ("文体ハイブリッド", "Guard 7: 文体ハイブリッド"),
    ("ですます", "Guard 7: 寄り添い ですます"),
    ("だ・である", "Guard 7: 観察 だ・である"),
    ("energyLabels", "Guard 8: energyLabels フォーマット"),
    ("名前ルール", "Guard 9: 名前ルール"),
    ("呼びかけてはいけない", "Guard 9: 呼びかけ禁止"),
]
for keyword, label in guards:
    check(keyword in consult, f"Prompt: {label}", f"Prompt MISSING: {label} ({keyword!r})")

# staticFallback
check(
    "function staticFallback" in consult,
    "staticFallback function exists",
    "staticFallback function MISSING",
)
check(
    "fallback: true" in consult or "fallback: 'fallback'" in consult or "fallback:true" in consult,
    "fallback flag set in static fallback",
    "fallback flag MISSING in static fallback",
)
check(
    "staticFallback(" in consult and "catch" in consult,
    "staticFallback wired to catch (AI failure path)",
    "staticFallback NOT wired to catch block",
)

# thinkingBudget 利用
check(
    "thinkingBudget: 1024" in consult,
    "thinkingBudget: 1024 set",
    "thinkingBudget NOT set to 1024",
)

# 出力スキーマ
for key in ("intro", "candidates", "outro"):
    check(
        f'"{key}"' in consult,
        f'output schema "{key}" present',
        f'output schema "{key}" MISSING',
    )

# ── 2. index.js ルート登録 ───────────────────────────────────
index_path = f"{WORKER_SRC}/index.js"
index = read(index_path)
check(
    "import { handleConsultation } from './consultation.js'" in index,
    "handleConsultation imported in index.js",
    "handleConsultation import MISSING in index.js",
)
route_re = re.compile(
    r"path\s*===\s*'/astro/consultation'\s*&&\s*request\.method\s*===\s*'POST'",
)
check(
    bool(route_re.search(index)),
    "/astro/consultation POST route registered",
    "/astro/consultation route NOT found in index.js",
)

# ── 3. fortune.js callGemini opts ────────────────────────────
fortune = read(f"{WORKER_SRC}/fortune.js")
check(
    "thinkingBudget" in fortune,
    "callGemini supports thinkingBudget opt",
    "callGemini DOES NOT support thinkingBudget (fortune.js needs update)",
)
check(
    "thinkingConfig" in fortune and "thinkingBudget" in fortune,
    "thinkingConfig wired into generationConfig",
    "thinkingConfig NOT wired into generationConfig",
)
check(
    "maxOutputTokens" in fortune and "maxOutputTokens = 2048" in fortune,
    "callGemini supports maxOutputTokens opt with default 2048",
    "callGemini maxOutputTokens opt MISSING",
)

# ── 集計 ────────────────────────────────────────────────────
print("=== Verify Consultation (Phase 2-2) ===")
print(f"  PASS: {len(passes)}")
print(f"  FAIL: {len(errors)}")
print()
for p in passes:
    print(f"  [OK]{p}")
if errors:
    print()
    for e in errors:
        print(f"  [FAIL]{e}")
    sys.exit(1)

print("\nAll structural checks passed.")
