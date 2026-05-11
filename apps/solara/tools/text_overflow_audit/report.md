# Solara Text Overflow 監査レポート
対象: `apps/solara/lib/**/*.dart` (除外: ['.dart_tool', 'test', 'tools'])
検出総数: **0** 箇所

## カテゴリ別サマリ
| 重大度 | カテゴリ | 件数 |
|---|---|---|
| 🔴🔴🔴 | 🔴 Row 直下の裸 Text (Flexible なし & overflow 設定なし) — 最優先 | 0 |
| 🔴🔴⚪ | 🟡 Row 直下、Flex でラップ済みだが overflow 未設定 | 0 |
| 🔴🔴⚪ | 🟡 Row 直下、overflow 設定済みだが Flexible で囲まれていない | 0 |

## ファイル別チェックリスト

各箇所を確認・修正したらチェックを入れてください。

