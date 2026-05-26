# 層 2c: グローバル singleton

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 2 / 総行数: 145
- class/mixin/extension/enum: 2
- 関数 (top-level + method の素拾い): 5
- Navigator.push 等: 0
- Popup/Dialog 呼出: 0
- Worker URL リテラル: 0

## ファイル別

### `lib/utils/consultation_credits.dart` (90 行)

**ファイル先頭コメント:**

```
Stella / Tarot 共用クレジット残数の Single Source of Truth (singleton)。

設計理由 (2026-05-26):
  CF logs 分析で /protected/consultation/credits が 5 分間に 45 回 (1 ユーザー、
  ピーク 1 分 13 回) 叩かれていた。原因は各画面 (Sanctuary / 相談入力 /
  開始ポップアップ / Tarot カテゴリ選択 / 購入シート) がそれぞれ initState で
  fetchConsultationCredits を独立に呼んでいたこと + 旧 ConsultationCreditEvents
  (notify-only ChangeNotifier) に listener を登録した複数画面が、1 イベントで
  それぞれ refetch していたこと。1 ユーザー操作 → 4-5 件の重複 fetch + 内部
  DO 4 個 fan-out で 320+ 件まで増幅していた。

本クラスの役割:
  - クレジット状況 (ConsultationCreditStatus) を 1 個だけ保持
  - UI 各所は instance.status を build で読む (= 自分で fetch しない)
  - refresh() は in-flight dedup (同時複数 await でも HTTP は 1 本)
  - notifyListeners で全 UI を一括更新

fetch をトリガーする 4 イベント (これ以外で呼んではいけない):
  1. アプリ起動時 (main.dart で 1 回・非同期)
  2. 消費イベント直後 (相談実行 / Tarot カテゴリ draw)
  3. 購入完了 webhook 反映ポーリング (consultation_credit_sheet)
  4. app resumed (バックグラウンド復帰、別端末購入や Webhook 遅延吸収)

非・キャッシュ方針 (オーナー方針: 問題を見えなくしない):
  - TTL ベースのキャッシュは置かない (= 古いデータを返さない)
  - 「画面遷移で勝手に refresh」は廃止
  - 各 refresh は明示イベントが原因 → CF ログで「消費 N 回 ⇔ fetch N 回」
    が 1:1 で対応する。バーストが再発したら新規バグとして検出可能。
```

**imports:** dart=0 / package=1 / relative=1

- relative: `consultation_api.dart`

**型定義 (1):**

- L35 `class ConsultationCredits : ChangeNotifier`

**関数 (2 public + 1 private):**

- L60 `refresh()` — クレジット残を再取得し、変更があれば listener に通知する。
- L84 `resetForTest()`

  <details><summary>private 関数 1 件</summary>

  - L72 `_doFetch()`

  </details>


### `lib/utils/tarot_data.dart` (55 行)

**imports:** dart=1 / package=1 / relative=1

- relative: `../models/tarot_card.dart`

**型定義 (1):**

- L6 `class TarotData`
  - Loads and indexes the 78-card tarot deck from the bundled asset.

**関数 (2 public + 0 private):**

- L9 `initialize()`
- L48 `getCard()`

