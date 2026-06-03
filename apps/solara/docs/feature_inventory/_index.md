# Solara Feature Inventory — Index

> Solara の機械抽出機能インベントリ。
> 各層のファイルは `extract.py` が自動生成する raw 素材。
> 人手版 (機能の意味を整理した版) は `../feature_inventory.md` を参照。

## 層構成

| 層 | 名称 | ファイル数 | Markdown |
| --- | --- | --- | --- |
| 0 | Worker (バックエンド計算式) | 27 | [00_worker.md](00_worker.md) |
| 1a | 純計算ユーティリティ | 9 | [01a_pure_calc.md](01a_pure_calc.md) |
| 1b | 静的データ辞書 | 15 | [01b_static_data.md](01b_static_data.md) |
| 1c | モデルクラス | 4 | [01c_models.md](01c_models.md) |
| 2a | API/Worker ラッパ | 10 | [02a_api_wrappers.md](02a_api_wrappers.md) |
| 2b | 永続化/キャッシュ | 9 | [02b_persistence.md](02b_persistence.md) |
| 2c | グローバル singleton | 5 | [02c_globals.md](02c_globals.md) |
| 3a | 共通ウィジェット (純粋) | 27 | [03a_widgets_pure.md](03a_widgets_pure.md) |
| 3b | テーマ・装飾 | 3 | [03b_theme.md](03b_theme.md) |
| 3c | 演出ウィジェット (animated) | 5 | [03c_widgets_anim.md](03c_widgets_anim.md) |
| 4a | Map 画面 | 25 | [04a_map.md](04a_map.md) |
| 4b | Horoscope 画面 | 23 | [04b_horoscope.md](04b_horoscope.md) |
| 4c | Observe (Tarot) 画面 | 12 | [04c_observe.md](04c_observe.md) |
| 4d | Galaxy 画面 | 10 | [04d_galaxy.md](04d_galaxy.md) |
| 4e | Sanctuary 画面 | 10 | [04e_sanctuary.md](04e_sanctuary.md) |
| 4f | サブ画面 (Forecast / Locations / Philosophy / Font Preview) | 32 | [04f_subscreens.md](04f_subscreens.md) |
| 5 | 連携層 (main.dart / PopScope / IndexedStack) | 1 | [05_main.md](05_main.md) |

## 全体統計

- Dart ファイル: 200
- Worker JS ファイル: 27
- Worker エンドポイント総数: 34
- Dart class/mixin/extension/enum 総数: 486
- Dart 関数総数 (素拾い): 1631

## 対整合チェック

- [coverage_report.md](coverage_report.md) を参照。
- #1 機械 → Doc / #2 Doc → 機械 / #3 Worker ↔ Flutter / #4 画面 ↔ 機能 を集計済み。
- #5 import 依存グラフ / #6 ハッシュ stamp / #7 astro_glossary 対整合 も集計済み。

## 未分類ファイル (要 override)

- (なし)
