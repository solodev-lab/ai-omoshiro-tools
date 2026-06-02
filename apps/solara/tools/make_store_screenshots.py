#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Solara ストア用スクリーンショット装飾合成スクリプト

役割:
    実機 A101FC から adb で撮った素の画面キャプチャ (720x1520, phone_raw/) を、
    Google Play 規定サイズ 1080x1920 (9:16) の "装飾フレーム" に合成する。

    レイアウト: 宇宙グラデ背景 + 微光の星 + 金のグロー + 日本語キャッチコピー
              + 端末フレーム(ベ�られ+影+金グロー) + SOLARA ワードマーク(Cinzel)。
    ブランド配色 (金 #D4B266 + ダーク #060912 + 9芒星紋章) に統一。

    🔴 スクショは引き伸ばさない (素の 720 を等倍以下で配置) → ぼやけない。

使い方 (CWD = apps/solara):
    python tools/make_store_screenshots.py          # phone_raw/ にある全画面を合成
    python tools/make_store_screenshots.py 1         # 1番だけ合成 (サンプル確認用)
    python tools/make_store_screenshots.py 1 6 10     # 指定番号だけ

入力:  docs/store_compliance_assets/phone_raw/<slug>.png        (番号なし=内容名)
出力:  docs/store_compliance_assets/phone_screenshots/<NN>_<slug>.png  (NN=SCREENS の並び順から自動採番)

依存: Pillow のみ (numpy 不使用)。日本語フォントは Windows 同梱 YuGothB.ttc。
"""
from __future__ import annotations

import os
import sys
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SOLARA = os.path.dirname(HERE)
RAW_DIR = os.path.join(SOLARA, "docs", "store_compliance_assets", "phone_raw")
OUT_DIR = os.path.join(SOLARA, "docs", "store_compliance_assets", "phone_screenshots")
os.makedirs(OUT_DIR, exist_ok=True)

EMBLEM = os.path.join(SOLARA, "assets", "app_icon_foreground.png")
CINZEL = os.path.join(HERE, "_fonts_Cinzel.ttf")

# ---- 日本語コピー用フォント プリセット (name -> (path, ttc_index, ファイル接尾辞)) ----
# 既定は mincho (游明朝デミボールド)。--font <name> で切替 (既定以外は接尾辞付き=比較用別名出力)。
FONT_PRESETS = {
    "mincho":    (r"C:\Windows\Fonts\yumindb.ttf",       0, ""),          # 游明朝デミボールド (既定・上品/神秘的)
    "yugo":      (r"C:\Windows\Fonts\YuGothB.ttc",       0, "_yugo"),     # モダン太ゴシック (高視認)
    "biz":       (r"C:\Windows\Fonts\BIZ-UDGothicB.ttc", 0, "_biz"),      # BIZ UDゴシック太 (親しみ/高視認)
    "bizmin":    (r"C:\Windows\Fonts\BIZ-UDMinchoM.ttc", 0, "_bizmin"),   # BIZ UD明朝 (やわらか明朝)
    "meiryo":    (r"C:\Windows\Fonts\meiryob.ttc",       0, "_meiryo"),   # メイリオ太 (丸み)
}
# 実行時に main() で書き換える (既定 mincho)。
_JP_PATH = FONT_PRESETS["mincho"][0]
_JP_INDEX = FONT_PRESETS["mincho"][1]
_SUFFIX = FONT_PRESETS["mincho"][2]

# ---- キャンバス / 配色 ----
W, H = 1080, 1920
GOLD = (212, 178, 102)
GOLD_BRIGHT = (236, 206, 132)
WARM_WHITE = (246, 242, 231)
SUB_GREY = (171, 178, 196)
SUB_TEXT = (212, 198, 166)   # サブ見出し用 (暖色寄りの淡いゴールドグレー)
BG_TOP = (6, 9, 18)
BG_MID = (16, 23, 40)
BG_BOT = (4, 6, 12)

# ---- 端末フレーム寸法 ----
SCREEN_W = 556          # スクショ表示幅 (見出し+サブ見出しの2段組分やや縮小、720->556=等倍以下)
BEZEL = 14
SCREEN_RADIUS = 30
PHONE_RADIUS = 42
PHONE_TOP = 560         # 端末上端 y (上部にコピー2段を置くため下げる)

# ---- 各画面のキャッチコピー (行ごとに分割) ----
# raw ファイル名 prefix(NN_) と対応。headline は表示順に1行ずつ。
# 表示順 = このリスト順。出力ファイル名は <NN>_<slug>.png (NN は並び順から自動採番)。
# 並べ替えはこのリストの順序を入れ替えるだけ (素材 phone_raw/<slug>.png はそのまま)。
SCREENS = [
    {"slug": "map_energy",
     "lines": ["行く先の運気が、", "地図でわかる。"],
     "sub":   ["16方位ごとのエネルギーを色で可視化。", "今日いい方角が、ひと目で。"],
     "stats": {"head": "今の空を、方位で読む。",
               "items": [["16", "方位"], ["5", "目的別スコア"],
                         ["10", "惑星から算出"], ["3", "層を合算"]]}},
    {"slug": "acg_ccg", "raw": "acg", "raw2": "ccg", "labels": ["ACG", "CCG"],
     "lines": ["行く土地と動く時で、", "運命は変わる。"],
     "sub":   ["土地で読む星のライン（ACG）と、日付で動くライン（CCG）。",
               "最大120本で、場所と時間の両面から運命を読む。"],
     "stats": {"items": [["120", "本のライン"], ["10", "惑星"],
                         ["4", "アングル"], ["4", "解析モード"]]}},
    {"slug": "locations",
     "lines": ["その日時・その場所の", "エネルギーが全部わかる。"],
     "sub":   ["職場や学校などを登録し、日時×目的別の", "スコアで見比べられる。"],
     "stats": {"head": "場所の運気を、数字で比較。",
               "items": [["5", "目的別スコア"], ["16", "方位"],
                         ["10", "惑星"], ["3", "層を合算"]]}},
    {"slug": "search_energy",
     "lines": ["検索した店の運気が、", "ひと目で並ぶ。"],
     "sub":   ["カフェやお店を目的別エネルギーで採点。", "デートや会食の場所を、迷わず選べる。"],
     "stats": {"head": "店ごとの運気を、即比較。",
               "items": [["5", "目的別エネルギー"], ["16", "方位"],
                         ["10", "惑星から算出"], ["3", "層を合算"]]}},
    {"slug": "stella_result", "raw": "stella_input", "raw2": "stella_result",
     "labels": ["相談", "結果"],
     "lines": ["お出かけも、移住も。", "ぜんぶ星に相談。"],
     "sub":   ["毎日のお出かけから、人生の移住まで。",
               "場面とテーマを選ぶだけで星が読み解く。"],
     "stats": {"items": [["246", "国・地域"], ["488,270", "都市"],
                         ["10", "惑星"], ["1,500", "地点採点"]]}},
    {"slug": "horoscope",
     "lines": ["精密な出生図が、", "すべての土台。"],
     "sub":   ["天体・アスペクト・ハウスを本格計算。", "Tスクエア等レア配置の成立日も予測。"],
     "stats": {"head": "本格占星術を、フル計算。",
               "items": [["10", "惑星"], ["12", "ハウス"],
                         ["8", "アスペクト種"], ["3", "層を重ねる"]]}},
    {"slug": "cycle",
     "lines": ["モテ期も強運日も、", "先に知る。"],
     "sub":   ["1年の運勢の波と、ベストな日を", "ランキングで表示。"],
     "stats": {"head": "運気の波を、先読み。",
               "items": [["5", "運気の波"], ["Top5", "強運日"],
                         ["365", "日を精査"], ["10", "惑星から算出"]]}},
    {"slug": "heatmap",
     "lines": ["1年の運気を、", "ひと目で。"],
     "sub":   ["365日をカテゴリ別の色で表示。", "Proなら最大5年先の運気まで見通せる。"],
     "stats": {"head": "1年を、色で見渡す。",
               "items": [["365", "日を可視化"], ["5", "年先(Pro)"],
                         ["5", "目的別カテゴリ"], ["10", "惑星から算出"]]}},
    {"slug": "star_reading",
     "lines": ["星が語る、", "今日のあなたへの指針。"],
     "sub":   ["総合運から恋愛・金運・仕事・対話まで、", "今日の星をカテゴリ別に読み解く（Proは全5種）。"]},
    {"slug": "tarot",
     "lines": ["タロットが照らす、", "心の奥の答え。"],
     "sub":   ["占星術と重ねた、あなただけの一枚。", "Proは質問を直接入力・ジャンル指定もできる。"]},
    {"slug": "star_atlas",
     "lines": ["夜空にあなただけの", "星座が生まれる。"],
     "sub":   ["記録を重ねるほど、星座が育つ。"]},
]


def _lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def make_background() -> Image.Image:
    """縦グラデ + 微光の星 + 中央やや下に金のラジアルグロー。"""
    bg = Image.new("RGB", (W, H))
    px = bg.load()
    mid_y = int(H * 0.46)
    for y in range(H):
        if y < mid_y:
            c = _lerp(BG_TOP, BG_MID, y / mid_y)
        else:
            c = _lerp(BG_MID, BG_BOT, (y - mid_y) / (H - mid_y))
        for x in range(W):
            px[x, y] = c

    # 金のラジアルグロー (端末の背後)
    glow = Image.new("L", (W, H), 0)
    gd = ImageDraw.Draw(glow)
    cx, cy = W // 2, int(H * 0.55)
    gd.ellipse([cx - 430, cy - 470, cx + 430, cy + 470], fill=70)
    glow = glow.filter(ImageFilter.GaussianBlur(160))
    gold_layer = Image.new("RGB", (W, H), GOLD)
    bg = Image.composite(gold_layer, bg, glow)

    # 微光の星 (決定論: seed 固定)
    draw = ImageDraw.Draw(bg, "RGBA")
    rnd = random.Random(7)
    for _ in range(150):
        x = rnd.randint(0, W - 1)
        y = rnd.randint(0, H - 1)
        r = rnd.choice([0, 0, 0, 1, 1, 2])
        a = rnd.randint(30, 150)
        col = rnd.choice([(255, 255, 255), (255, 255, 255), GOLD_BRIGHT])
        draw.ellipse([x - r, y - r, x + r, y + r], fill=col + (a,))
    return bg


def _font(path, size, index=0):
    try:
        return ImageFont.truetype(path, size, index=index)
    except Exception:
        return ImageFont.truetype(path, size)


def _line_w(draw, text, font):
    box = draw.textbbox((0, 0), text, font=font)
    return box[2] - box[0]


def fit_font(draw, lines, max_w, start=72, min_size=46):
    """全行が max_w に収まる最大フォントサイズを返す。"""
    size = start
    while size > min_size:
        f = _font(_JP_PATH, size, _JP_INDEX)
        if all(_line_w(draw, ln, f) <= max_w for ln in lines):
            return f
        size -= 2
    return _font(_JP_PATH, min_size, _JP_INDEX)


def draw_centered_lines(img, lines, top_y, font, fill, line_gap=1.22):
    draw = ImageDraw.Draw(img)
    ascent, descent = font.getmetrics()
    lh = int((ascent + descent) * line_gap)
    y = top_y
    for ln in lines:
        w = _line_w(draw, ln, font)
        x = (W - w) // 2
        # ほのかな影で可読性を上げる
        draw.text((x + 2, y + 2), ln, font=font, fill=(0, 0, 0, 160))
        draw.text((x, y), ln, font=font, fill=fill)
        y += lh
    return y


def draw_wordmark(img, y):
    """SOLARA を Cinzel + トラッキングで金色描画 (中央)。"""
    draw = ImageDraw.Draw(img)
    text = "SOLARA"
    f = _font(CINZEL, 44)
    tracking = 10
    widths = [_line_w(draw, ch, f) for ch in text]
    total = sum(widths) + tracking * (len(text) - 1)
    x = (W - total) // 2
    for ch, w in zip(text, widths):
        draw.text((x, y), ch, font=f, fill=GOLD)
        x += w + tracking


def round_mask(size, radius):
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size[0], size[1]], radius=radius, fill=255)
    return m


def load_shot(path, sw):
    """スクショを幅 sw に等倍以下リサイズ + 角丸。"""
    shot = Image.open(path).convert("RGBA")
    scale = sw / shot.width
    sh = round(shot.height * scale)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    shot.putalpha(round_mask((sw, sh), SCREEN_RADIUS))
    return shot


def paste_phone(canvas, shot, phone_x, phone_y, label=None):
    """影+金グロー+ベゼル+スクショ を 1 台分合成し、(canvas, box) を返す。"""
    sw, sh = shot.size
    phone_w = sw + 2 * BEZEL
    phone_h = sh + 2 * BEZEL
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [phone_x, phone_y + 26, phone_x + phone_w, phone_y + phone_h + 26],
        radius=PHONE_RADIUS, fill=(0, 0, 0, 150))
    canvas = Image.alpha_composite(canvas, shadow.filter(ImageFilter.GaussianBlur(34)))
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle(
        [phone_x - 6, phone_y - 6, phone_x + phone_w + 6, phone_y + phone_h + 6],
        radius=PHONE_RADIUS + 6, fill=GOLD + (110,))
    canvas = Image.alpha_composite(canvas, glow.filter(ImageFilter.GaussianBlur(26)))
    bez = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(bez).rounded_rectangle(
        [phone_x, phone_y, phone_x + phone_w, phone_y + phone_h],
        radius=PHONE_RADIUS, fill=(16, 18, 26, 255), outline=GOLD + (180,), width=2)
    canvas = Image.alpha_composite(canvas, bez)
    canvas.alpha_composite(shot, (phone_x + BEZEL, phone_y + BEZEL))
    if label:
        draw_label_chip(canvas, phone_x + phone_w // 2, phone_y - 50, label)
    return canvas, (phone_x, phone_y, phone_w, phone_h)


def draw_label_chip(canvas, cx, top_y, text):
    """端末上の小さなゴールドのラベルピル (ACG/CCG・相談/結果 等)。ASCII は Cinzel、和文は JP。"""
    d = ImageDraw.Draw(canvas)
    f = _font(CINZEL, 30) if text.isascii() else _font(_JP_PATH, 27, _JP_INDEX)
    box = d.textbbox((0, 0), text, font=f)
    tw = box[2] - box[0]
    th = box[3] - box[1]
    padx, pady = 22, 10
    w = tw + 2 * padx
    h = th + 2 * pady + 4
    x0 = cx - w // 2
    d.rounded_rectangle([x0, top_y, x0 + w, top_y + h], radius=h // 2,
                        fill=(16, 18, 26, 235), outline=GOLD + (210,), width=2)
    d.text((cx - tw // 2 - box[0], top_y + pady - box[1] + 2), text, font=f, fill=GOLD)


def draw_stats_overlay(canvas, box, stats):
    """端末下部に半透明パネルで「解析量」を具体的数値で重ねる (Stella 用)。"""
    px, py, pw, ph = box
    m = 16
    x0, x1 = px + m, px + pw - m
    y1 = py + ph - m
    panel_w = x1 - x0
    cx = (x0 + x1) // 2
    head = stats.get("head", "")
    foot = stats.get("foot", "")
    items = stats.get("items", [])
    rows = (len(items) + 1) // 2
    panel_h = 70 + rows * 116 + (46 if foot else 16)
    y0 = y1 - panel_h
    panel = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(panel).rounded_rectangle(
        [x0, y0, x1, y1], radius=22, fill=(8, 11, 20, 232), outline=GOLD + (160,), width=2)
    canvas = Image.alpha_composite(canvas, panel)
    d = ImageDraw.Draw(canvas)
    if head:
        hf = _font(_JP_PATH, 29, _JP_INDEX)
        hw = d.textbbox((0, 0), head, font=hf)[2]
        d.text((cx - hw // 2, y0 + 18), head, font=hf, fill=WARM_WHITE)
    numf = _font(CINZEL, 50)
    labf = _font(_JP_PATH, 23, _JP_INDEX)
    cellw = panel_w // 2
    gy = y0 + 66
    for idx, (num, lab) in enumerate(items):
        r, c = idx // 2, idx % 2
        ccx = x0 + c * cellw + cellw // 2
        ny = gy + r * 116
        nw = d.textbbox((0, 0), num, font=numf)[2]
        d.text((ccx - nw // 2, ny), num, font=numf, fill=GOLD_BRIGHT)
        lw = d.textbbox((0, 0), lab, font=labf)[2]
        d.text((ccx - lw // 2, ny + 58), lab, font=labf, fill=SUB_TEXT)
    if foot:
        ff = _font(_JP_PATH, 22, _JP_INDEX)
        fw = d.textbbox((0, 0), foot, font=ff)[2]
        while fw > panel_w - 20 and ff.size > 16:
            ff = _font(_JP_PATH, ff.size - 1, _JP_INDEX)
            fw = d.textbbox((0, 0), foot, font=ff)[2]
        d.text((cx - fw // 2, y1 - 38), foot, font=ff, fill=SUB_TEXT)
    return canvas


def draw_stats_bar(canvas, boxes, stats):
    """2枚配置 (ACG+CCG) の下に横一列の数値バーを置く。(canvas, 下端y) を返す。"""
    x0 = min(b[0] for b in boxes)
    x1 = max(b[0] + b[2] for b in boxes)
    top = max(b[1] + b[3] for b in boxes) + 16
    items = stats.get("items", [])
    h = 92
    panel = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(panel).rounded_rectangle(
        [x0, top, x1, top + h], radius=20, fill=(8, 11, 20, 232), outline=GOLD + (160,), width=2)
    canvas = Image.alpha_composite(canvas, panel)
    d = ImageDraw.Draw(canvas)
    numf = _font(CINZEL, 38)
    labf = _font(_JP_PATH, 19, _JP_INDEX)
    n = max(1, len(items))
    cellw = (x1 - x0) // n
    for idx, (num, lab) in enumerate(items):
        ccx = x0 + idx * cellw + cellw // 2
        nw = d.textbbox((0, 0), num, font=numf)[2]
        d.text((ccx - nw // 2, top + 14), num, font=numf, fill=GOLD_BRIGHT)
        lw = d.textbbox((0, 0), lab, font=labf)[2]
        d.text((ccx - lw // 2, top + 60), lab, font=labf, fill=SUB_TEXT)
    return canvas, top + h


def compose_one(screen, pos) -> str:
    slug = screen["slug"]
    raw = screen.get("raw", slug)   # 素材ファイルの上書き (別バージョン生成用)
    raw_path = os.path.join(RAW_DIR, raw + ".png")
    if not os.path.exists(raw_path):
        return ""
    canvas = make_background().convert("RGBA")

    # --- 端末スクショ配置 (raw2 があれば ACG+CCG 2枚を staggered 配置) ---
    raw2 = screen.get("raw2")
    if raw2:
        labels = screen.get("labels", [None, None])
        sw = 440
        layout = [(raw, labels[0], 86, 548), (raw2, labels[1], 526, 640)]
        boxes = []
        for rname, lab, ph_x, ph_y in layout:
            rp = os.path.join(RAW_DIR, rname + ".png")
            if not os.path.exists(rp):
                continue
            canvas, box = paste_phone(canvas, load_shot(rp, sw), ph_x, ph_y, label=lab)
            boxes.append(box)
    else:
        sw = SCREEN_W
        ph_x = (W - (sw + 2 * BEZEL)) // 2
        canvas, box = paste_phone(canvas, load_shot(raw_path, sw), ph_x, PHONE_TOP)
        boxes = [box]
    if not boxes:
        return ""

    # --- 紋章 (上部中央) ---
    if os.path.exists(EMBLEM):
        em = Image.open(EMBLEM).convert("RGBA")
        ew = 82
        eh = round(em.height * ew / em.width)
        em = em.resize((ew, eh), Image.LANCZOS)
        canvas.alpha_composite(em, ((W - ew) // 2, 44))

    # --- 見出し (つかみ) ---
    draw = ImageDraw.Draw(canvas)
    lines = screen["lines"]
    font = fit_font(draw, lines, max_w=940, start=66)
    end_y = draw_centered_lines(canvas, lines, top_y=150, font=font, fill=WARM_WHITE)

    # 金の下線アクセント
    bar_w = 150
    bx = (W - bar_w) // 2
    by = end_y + 8
    ImageDraw.Draw(canvas).rounded_rectangle(
        [bx, by, bx + bar_w, by + 5], radius=3, fill=GOLD,
    )

    # --- サブ見出し (機能の中身=訴求の本体。文字で凄さを伝える) ---
    sub = screen.get("sub", [])
    if sub:
        subfont = fit_font(draw, sub, max_w=900, start=38, min_size=27)
        draw_centered_lines(canvas, sub, top_y=by + 28, font=subfont,
                            fill=SUB_TEXT, line_gap=1.32)

    # --- 数値オーバーレイ (解析量を具体的数値で重ねる) ---
    stats = screen.get("stats")
    bottom = max(b[1] + b[3] for b in boxes)
    if stats:
        if len(boxes) == 1:
            canvas = draw_stats_overlay(canvas, boxes[0], stats)
        else:
            canvas, bar_bottom = draw_stats_bar(canvas, boxes, stats)
            bottom = max(bottom, bar_bottom)

    # --- ワードマーク (最下段の下) ---
    draw_wordmark(canvas, y=bottom + 40)

    out_name = screen.get("out") or f"{pos:02d}_{slug}"  # 出力名の上書き (別バージョン用)
    out_path = os.path.join(OUT_DIR, out_name + _SUFFIX + ".png")
    canvas.convert("RGB").save(out_path, "PNG")
    return out_path


def main():
    global _JP_PATH, _JP_INDEX, _SUFFIX
    args = sys.argv[1:]

    # --font <name> を抜き出して書体を切替 (出力ファイル名に接尾辞が付く)
    if "--font" in args:
        i = args.index("--font")
        name = args[i + 1]
        if name not in FONT_PRESETS:
            sys.exit(f"[make_store] unknown font '{name}'. choices: {', '.join(FONT_PRESETS)}")
        _JP_PATH, _JP_INDEX, _SUFFIX = FONT_PRESETS[name]
        del args[i:i + 2]

    want = {int(a) for a in args} if args else None

    done = 0
    for i, s in enumerate(SCREENS, 1):
        if want is not None and i not in want:
            continue
        out = compose_one(s, i)
        if out:
            print(f"[OK] {os.path.relpath(out, SOLARA)}")
            done += 1
        else:
            print(f"[skip] {i:02d}_{s['slug']} (raw 未撮影)")
    print(f"\n{done} 枚生成 -> {os.path.relpath(OUT_DIR, SOLARA)}")


if __name__ == "__main__":
    main()
