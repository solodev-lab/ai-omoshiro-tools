# Solara — Google Play Data Safety form 推奨回答

> Google Play Console > アプリのコンテンツ > **データセーフティ** に入力する内容のドラフト。
> 実装の実態 (RC / Google Sign In / google_maps_flutter / google_places / Gemini API / Apple SIWA / 内部 DO) に基づく。
>
> オーナーは Console で本ファイルからコピペ + チェックボックス操作。
>
> 関連: [store_compliance.md](../store_compliance.md) §3.8 / [legal.md](../legal.md) §3
>
> 最終更新: 2026-05-28
>
> ⚠ **重要**: プライバシーポリシーと **完全一致** させること (Reviewer が line-by-line で確認する)。
> 不一致 = Apple/Google 両方で警告メール → 修正提出を求められる。

---

## A. データ収集と共有

### A.1 「このアプリは個人ユーザー データを収集または共有しますか？」

→ **はい**

### A.2 データタイプ別の宣言

各データタイプについて以下 5 項目を回答する:
- 収集する? (Collected)
- 共有する? (Shared)
- 収集は任意? (Optional)
- 目的 (Purposes、複数選択可)
- 一時的か永続か (Ephemeral or Processed)

#### Personal info (個人情報)

| データタイプ | 収集 | 共有 | 任意 | 目的 | 備考 |
|---|---|---|---|---|---|
| Name | はい (ニックネーム) | いいえ | 任意 | App functionality | DO 保存 / 占い結果には使わない |
| Email address | はい (SI 時) | いいえ | サインイン時必須 | Account management | Apple / Google SI 経由、サーバ送信なし |
| User IDs | はい (appUserId = RC 匿名 ID) | はい (RevenueCat) | 必須 | App functionality / Analytics / Fraud prevention | 個人特定不可の匿名 ID |
| Race and ethnicity | いいえ | - | - | - | - |
| Political or religious beliefs | いいえ | - | - | - | - |
| Sexual orientation | いいえ | - | - | - | - |
| Other info (出生日時) | はい | はい (Gemini) | 任意 | App functionality | 占星術計算用、相談時のみ Gemini 送信 |

#### Financial info (金融情報)

| データタイプ | 収集 | 共有 | 任意 | 目的 | 備考 |
|---|---|---|---|---|---|
| User payment info | いいえ | - | - | - | Google Play / Apple が処理、Solara は受け取らない |
| Purchase history | はい | はい (RevenueCat + Google Play) | 課金時 | Account management / App functionality | Pro 契約状況のみ |
| Credit score | いいえ | - | - | - | - |
| Other financial info | いいえ | - | - | - | - |

#### Health and fitness (健康情報) — **すべていいえ**
| データタイプ | 備考 |
|---|---|
| Health info / Fitness info | **収集しない**。健康関連の入力欄を持たない |

#### Messages (メッセージ) — **すべていいえ**
| データタイプ | 備考 |
|---|---|
| Emails / SMS / Other in-app messages | 収集しない |

#### Photos and videos — **すべていいえ**
| データタイプ | 備考 |
|---|---|
| Photos / Videos | 収集しない (カメラ・写真ライブラリ権限なし) |

#### Audio files — **すべていいえ**
| データタイプ | 備考 |
|---|---|
| Voice or sound recordings / Music files / Other audio files | 収集しない (マイク権限なし) |

#### Files and docs — **すべていいえ**
| データタイプ | 備考 |
|---|---|
| Files and docs | 収集しない |

#### Calendar — **すべていいえ**
#### Contacts — **すべていいえ**

#### Location (位置情報)

| データタイプ | 収集 | 共有 | 任意 | 目的 | 備考 |
|---|---|---|---|---|---|
| Approximate location | はい | はい (Google Maps SDK) | 任意 | App functionality | 出生地・候補地 |
| Precise location | はい | はい (Google Maps SDK) | 任意 | App functionality | 出生地・候補地・現在地での天体配置計算 |

#### Web browsing — **すべていいえ**
| データタイプ | 備考 |
|---|---|
| Web browsing history | 収集しない |

#### App activity (アプリの利用状況)

| データタイプ | 収集 | 共有 | 任意 | 目的 | 備考 |
|---|---|---|---|---|---|
| App interactions | はい (Pro / Free 利用、相談回数等) | いいえ | 必須 | Analytics / App functionality | DO 内集計のみ |
| In-app search history | いいえ | - | - | - | - |
| Installed apps | いいえ | - | - | - | - |
| Other user-generated content | はい (相談入力テキスト・出生情報) | はい (Gemini) | 相談時 | App functionality | Gemini AI に解釈生成のため送信 |
| Other actions | いいえ | - | - | - | - |

#### Web app communications — **すべていいえ**

#### App info and performance (アプリ情報とパフォーマンス)

| データタイプ | 収集 | 共有 | 任意 | 目的 | 備考 |
|---|---|---|---|---|---|
| Crash logs | いいえ | - | - | - | Firebase Crashlytics 未導入 |
| Diagnostics | いいえ | - | - | - | 同上 |
| Other app performance data | いいえ | - | - | - | - |

#### Device or other IDs

| データタイプ | 収集 | 共有 | 任意 | 目的 | 備考 |
|---|---|---|---|---|---|
| Device or other IDs | はい | はい (RevenueCat) | 必須 | Analytics / Fraud prevention | Android ID / iOS keychain (RC 内部識別) |

---

## B. セキュリティ プラクティス

### B.1 「データは送信時に暗号化されますか？」
→ **はい**
理由: すべての API 通信は HTTPS (TLS 1.2+)、Cloudflare Workers 経由

### B.2 「データの削除をリクエストする方法をユーザーに提供していますか？」
→ **はい**
理由:
- アプリ内: Sanctuary > アカウント > 削除 (即時、Apple Token Revocation + RC DELETE + DO purge)
- Web: https://solodev-lab.com/legal/solara/delete-account.html (メール窓口あり)

### B.3 「このアプリは、ファミリー向けプログラムに準拠していますか？」
→ **いいえ**
(13+ アプリのため Families Policy 適用外)

### B.4 「独立したセキュリティ レビューを通過していますか？」
→ **いいえ**
(オプション項目、未受審で問題なし)

---

## C. アカウント削除 (2024 義務化)

### C.1 「ユーザーがこのアプリのアカウントを削除する方法を提供していますか？」
→ **はい**

### C.2 削除リクエストの方法 (アプリ内 / Web / メール の組み合わせ)
- ✅ アプリ内 (Sanctuary > アカウント > 削除)
- ✅ Web (https://solodev-lab.com/legal/solara/delete-account.html)
- メール ( delete-account.html 内に mailto: リンクあり)

### C.3 「アカウント削除 URL」
→ `https://solodev-lab.com/legal/solara/delete-account.html`

### C.4 「アプリの削除によって、ユーザー データもすべて削除されますか？」
→ **いいえ** (アプリ削除でアカウントデータは残る、アプリ内 or Web からの削除リクエストが必要)

ただし:
- 端末内ローカル データ (相談履歴・お気に入り等) はアプリ削除で消える
- サーバー側の Pro 契約・購入クレジット・アカウント情報は削除リクエスト必要

---

## D. Generative AI 関連 (新セクション、今後必須化見込)

Google Play Console は 2026-04-15 全面施行の Gen AI Policy 対応として、本フォーム内に
**Generative AI** セクションを追加予定 (現状任意項目)。先回りで以下を記載しておく:

### D.1 アプリは生成 AI を使用していますか？
→ **はい**

### D.2 用途
- 占星術解釈の文章生成 (Tarot / Stella 相談 / 今日の占い)

### D.3 モデル
- Google Gemini API (gemini-2.5-flash / gemini-flash-latest)

### D.4 ユーザーの入力データを AI 学習に使用しますか？
→ **いいえ** (Google Gemini API の Standard tier では学習に使用されない)

### D.5 安全策
- Gemini safety settings は default 設定で運用
- Worker 側 prompt に医療・法律・金融・投資・自傷の断定禁止を組込済
- アプリ内に「不適切な内容を報告」ボタンを全 AI 結果画面に設置 (`/protected/report-ai-output`)
- 初回起動時に「Gemini に送信する」明示同意を取得

---

## E. プライバシーポリシーとの整合性チェックリスト

提出前に **プライバシーポリシー (privacy.html) に以下が明記されているか** 確認:

- [ ] 収集する個人情報 (名前 / メール / 出生情報 / 位置 / 課金履歴 / 利用統計 / デバイス ID) の列挙
- [ ] 第三者 SDK と共有 (RevenueCat / Google Maps / Google Sign In / Apple Sign In / Gemini API) の明示
- [ ] **Gemini API への送信** (出生情報 + 相談入力テキスト) を line-by-line で
- [ ] HTTPS 暗号化の明記
- [ ] アプリ内削除 + Web 削除窓口の案内
- [ ] データ保持期間 (法的義務分は 7 年、それ以外は削除リクエスト即時)
- [ ] 連絡先 (`usin.kodima@gmail.com`)

🔴 ここで Data Safety form と一致してない項目があると、提出後の Reviewer 確認で警告メール → 修正要求 → 修正提出の遅延が発生する。

---

## F. 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-05-28 | 初版作成 (G11 対応) |
