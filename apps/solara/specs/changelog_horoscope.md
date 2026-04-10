# Horoscope画面 変更ログ

> HTMLモックを修正したら、ここに記録する。
> Flutter移植時にこのログを確認して、最新仕様で移植する。

## 記入フォーマット
```
## YYYY-MM-DD: 変更の要約
- 変更前: ○○
- 変更後: ○○
- 理由: ○○
- HTML反映済み: YES/NO
- Flutter反映済み: YES/NO
```

---

## 変更履歴

## 2026-04-09: アスペクトフィルター ボトムシート同期バグ修正
- 変更前: ボトムシートのフィルターチップをタップすると、renderChart()→buildBSFilterContent()でDOMが上書きされ、変更が消えていた
- 変更後: buildBSFilterContent()の後にsyncFilterChips()でactiveFiltersの状態を再反映
- 理由: フィルターが効かないバグ
- HTML反映済み: YES
- Flutter反映済み: NO

## 2026-04-09: Flutter Horo画面 HTML差分修正（大量）
- 変更前: orb値が教科書的（8/6/5度）、マイナーアスペクト未実装、惑星グループフィルター欠落、星読みタブにランク数値あり、BSに余分な運勢タブ、Fortuneカルーセルにスコア/方位なし
- 変更後:
  1. orb値をHTML準拠（全て2度、マイナー1度）に修正
  2. semisextile(30°) / semisquare(45°) の2種追加（計8種）
  3. 惑星グループフィルター(C)追加（個人/社会/世代天体）+ fortuneフィルター連動
  4. BS運勢タブ削除、astrologyモード時BS非表示、モード切替時resetFilters追加
  5. 星読みタブからスコア数値/スコアバー削除、方位アドバイスボックス追加
  6. Fortuneカルーセルにスコア表示+方位アドバイス追加、カテゴリ専用bg/border色適用
  7. アスペクト個別表示/非表示トグル機能追加
  8. Transitタブのnpモード時ラベル動的変更（☆ 進行）
- 理由: dead_code_detector + HTML全量比較で差分を特定
- HTML反映済み: YES
- Flutter反映済み: YES
