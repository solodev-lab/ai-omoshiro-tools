# Tarot画面 変更ログ

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

## 2026-04-09: デッドコード1関数を削除
- 変更前: selectLocation が存在（.loc-btn要素も存在しない）
- 変更後: selectLocation を削除。getLocationLabel は残存
- 理由: どこからも呼ばれないデッドコード。対応するUI要素も存在しない
- HTML反映済み: YES
- Flutter反映済み: N/A（移植不要）
