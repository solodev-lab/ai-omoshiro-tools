# Map画面 変更ログ

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

（まだ変更なし — HTMLを修正したら下に追記する）

## 2026-04-09: デッドコード2関数を削除
- 変更前: spawnImpact / launchMeteor が存在
- 変更後: 2関数を削除。パーティクル系の他関数(spawnConverge等)は残存
- 理由: どこからも呼ばれないデッドコード
- HTML反映済み: YES
- Flutter反映済み: N/A（移植不要）

## 2026-04-09: Flutter Map画面 HTML差分修正
- 変更前: 8方位セクター(blessed/mid/shadow)、Stella画面上部配置、ff-label縦並び、ズームボタンあり、CSS値多数不一致
- 変更後:
  1. セクター16方位化 + HTML準拠の分類(strong/weak/null) + カテゴリ色連動
  2. Stella位置をbottom:90pxに移動（HTML準拠）
  3. Stella CSS値修正（border-radius:16px, padding:16px 20px, fontSize:10/13px, height:1.6）
  4. ff-labelレイアウトを横並び(Row)に修正 + CSS値修正（dir幅32px, dir色#888, スコア幅28px, fontSize8px, バー高さ5px, padding 3px）
  5. ズームボタン削除（HTMLにはないため）
  6. LayerPanel幅を110→100pxに修正
- 理由: HTML全量比較で差分を特定
- HTML反映済み: YES
- Flutter反映済み: YES
- 未対応（将来タスク）: 天文学的スコア計算、天体ライン描画、パーティクルエフェクト、VP Panelスロット管理、タロットカードCTA、種まきインパクトシーケンス
