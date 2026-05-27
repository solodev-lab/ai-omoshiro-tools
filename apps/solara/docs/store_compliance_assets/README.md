# Solara — Store Compliance Assets

このフォルダは Apple App Store / Google Play Console への提出に必要な情報を集めた **作業用** 資料群です。

## 🔴 オーナーが Console 作業する時はこの順番

| # | 作業 | 開く ファイル |
|---|---|---|
| 1 | App Store Connect の入力 (説明文 / プライバシー / 価格 / TestFlight 等) | **[apple_app_store_connect.md](apple_app_store_connect.md)** |
| 2 | Google Play Console の入力 (説明文 / データセーフティ / コンテンツ レーティング 等) | **[google_play_console.md](google_play_console.md)** |
| 3 | iOS SDK / Android SDK の Privacy Manifest + 16 KB 監査 | **[sdk_audit.md](sdk_audit.md)** |

→ コピペ用テキスト + URL or 画面遷移を全部入り。**コピペ → Save の繰り返し** で進める。

## 📚 詳細根拠 (Reviewer から質問された時の参照用)

| ファイル | 内容 |
|---|---|
| **[../store_compliance.md](../store_compliance.md)** | 審査対応の正典。Apple/Google 最新動向 + Gap analysis + 必須 disclaimer + リジェクト時リカバリ |
| [age_rating_questionnaire.md](age_rating_questionnaire.md) | 年齢制限の **詳細根拠** (なぜ Apple 4+ / Google Teen 13+ なのか + Reviewer Q&A) |
| [data_safety_form.md](data_safety_form.md) | Data Safety form の **詳細根拠** (各データタイプの収集理由 + プライバシーポリシー整合性) |

## 🌐 配信用 (オーナーが Web にアップする HTML)

| ファイル | 配信先 |
|---|---|
| なし (本フォルダ外、`/legal/solara/` ディレクトリにある) | https://solodev-lab.com/legal/solara/delete-account.html (deploy 済) |

## 📁 ファイル一覧

```
docs/store_compliance_assets/
├── README.md                            ← このファイル
├── apple_app_store_connect.md           ← Apple 入力シート (コピペ専用)
├── google_play_console.md               ← Google 入力シート (コピペ専用)
├── age_rating_questionnaire.md          ← 年齢制限 詳細根拠
├── data_safety_form.md                  ← データセーフティ 詳細根拠
└── sdk_audit.md                         ← Privacy Manifest + 16 KB 監査 手順
```

## 🗑 削除済 (前 commit との差分)

- ~~store_listing.md~~ (2026-05-28 削除、apple_/google_ paste sheets に分割統合)

## 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-05-28 | 初版 (apple_/google_ コピペシート 新規作成 + age_rating 全面修正 + 旧 store_listing 削除) |
