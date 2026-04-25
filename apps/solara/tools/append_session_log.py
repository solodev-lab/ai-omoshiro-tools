"""今セッションの作業ログを自動メモリの session_log.md へ append する。

CLAUDE.md ルール:
- 保存先: C:/Users/cojif/.claude/projects/E--AppCreate/memory/session_log.md
- 必ず append（>>）で書く（並列セッションの記録が消えるため）
- 1500行超で前半1000行を自動削除（feedback_save_everything）
"""
import os

LOG_PATH = r"C:/Users/cojif/.claude/projects/E--AppCreate/memory/session_log.md"

ENTRY = """
## 2026-04-25 セッション: Solara 続き作業（Map/Forecast/Locations/Horo 大量UI整理 + ノープロファイル案内 + 日本語フォント）

### Locations 画面
- 日付ステッパーの右端を 28x28 固定枠化、`Icons.refresh` → `Icons.today` に変更、今日状態でも薄色 disabled で常時表示（ブレ解消）
- ヘッダーの「+」ボタン削除（_addCurrent は空状態の登録ボタンで使用継続）
- profile 未設定時に Horo 画面と同じ案内カード（AntiqueGlyph reading + 「SANCTUARYでプロフィールを設定すると…」）に切替
- onNavigateToSanctuary を main → MapScreen → LocationsScreen へ伝搬

### VPパネル（Map サイド）
- インラインのアイコンピッカー（32アイコン）を削除し AlertDialog に変更
- ダイアログ仕様: 幅352px insetPadding=16、36×36px×8列×4行のグリッド（8×4=32）
- 画面外切れ問題を解消、VIEWPOINT/LOCATIONS 両タブ共通

### Forecast 画面
- ヘッダーの更新ボタン削除（自動差分更新で十分・誤解防止）
- `_forceRefresh` メソッド削除、`_load({forceRefresh})` パラメータ撤去（`force` 不使用）
- 運勢サイクル: 「次へ ▶」ボタンと「1/3」カウント表示削除、`_periodCursor`/`_resetPeriodCursors`/cursor/onCursorChange パラメータ削除
- ヒートマップ詳細カードの「Mapで見る」: 矢印削除＆金色下線追加
- 表示期間カード内年間ベスト行の「Mapで見る」も矢印削除
- 強運Top5: `#1〜#5` を 👑/🥈/🥉/⭐/✨ に変更、SizedBox 24→28、fontSize 16
- profile 未設定時に他画面と同じ案内カード表示（_noProfile flag）

### Map 画面
- **重大バグ修正**: 出生情報なしでも乱数モックスコアが表示されていた問題（誤解を招く）
- `generateMockScores` を完全削除（`map_sectors.dart` から関数本体と `dart:math` import）
- `_noProfile` フラグ追加 → 占い系オーバーレイを非表示（PolygonLayer/FortuneFilterLabel/Daily Omen/Fortune Pull Tab/Sheet）
- 中央に他画面と同じ案内カードを overlay（背景不透明度↑）
- MapScreenState を public化、`reloadProfile()` 公開メソッド追加
- main.dart から GlobalKey<MapScreenState> でタブ切替時に reload（Sanctuary でプロフィール登録後の追従）

### Horo 画面
- 各カテゴリカード（全体運/恋愛運/金運/仕事運/対話運）右上の数値スコア（82/75/68/88/71）削除
- `horo_constants.dart` の `'score'`/`'direction'` フィールドも未参照のため削除

### 日本語フォント (Noto Sans JP)
- `solara_theme.dart` で TextTheme に `fontFamilyFallback: [Noto Sans JP]` 追加
- 英字 DM Sans + 日本語 Noto Sans JP 自動フォールバック
- Stella の `RichText` を `Text.rich` に変更（RichText は DefaultTextStyle 継承しないため fallback が効かない問題を修正）
- 一時用フォント比較画面 `jp_font_preview_screen.dart` を作成→Noto Sans JP 採用後に削除（Sanctuary エントリも撤去）

### Smart App Control 解決（環境）
- Windows 11 26200.8246 で SAC を無効化 → `flutter doctor` 等が動作開始
- Microsoft 2026年3月26日の更新で SAC を再インストールなしでオフ可能に
- adb path: `C:/Users/cojif/AppData/Local/Android/sdk/platform-tools/adb.exe`
- `adb shell pm clear com.solodevlab.solara` でテストデータクリア手段確立

### コード品質チェック（Python ツール追加）
- `tools/check_file_sizes.py`: 500行超ファイル一覧（最大849行・1000行超なし＝健全）
- `tools/find_unused_code.py`: flutter analyze の unused-* 抽出 + ヒューリスティック未参照シンボル検出（共に0件）

### 注意点・継続事項
- Stella メッセージのモック文言「『再会の喜び』が…」は今後動的化必要
- Forecast の `'2026-04 に未使用となり削除済'` コメントを horo_constants に残した（履歴のため）
- Map 画面の `dart:math` import は generateMockScores 削除に伴い不要化済（map_sectors.dart からも削除）
"""

with open(LOG_PATH, "a", encoding="utf-8") as f:
    f.write(ENTRY)

print(f"Appended {len(ENTRY)} chars to {LOG_PATH}")
