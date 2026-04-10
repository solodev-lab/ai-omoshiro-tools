# Galaxy画面 変更ログ

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

## 2026-04-09: デッドコード3関数を削除
- 変更前: triggerConstellationFormation / generateConstellationName / _nameHash が存在
- 変更後: 3関数を削除（約220行）。closeFormationOverlayは残存
- 理由: どこからも呼ばれないデッドコード。dead_code_detector.py + 手動クロスチェックで確認
- HTML反映済み: YES
- Flutter反映済み: N/A（移植不要）
