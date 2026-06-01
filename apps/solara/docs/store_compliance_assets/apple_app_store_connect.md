# Solara — App Store Connect コピペ入力シート

> オーナー作業用の「画面別・入力欄別」コピペ専用シート。各セクションの直接 URL と
> 左サイドナビゲーション (パンくず) を明示。**コピペ → Save の繰り返し** で完了する。
>
> Solara App Apple ID: **6770092724**  Bundle ID: **com.solodevlab.solara**
> Apple Developer Team ID: **TY5JW393Q5**
>
> 関連: [store_compliance.md](../store_compliance.md) (背景・根拠) / [age_rating_questionnaire.md](age_rating_questionnaire.md) (年齢制限 詳細根拠、ただし §1.8/§1.11 は誤情報あり、4+ が正解)
>
> 最終更新: 2026-05-28

---

## 進める順序 (上から順に)

1. § A: アプリ情報 (App Information) — カテゴリ / プライバシーポリシー URL / 年齢制限
2. § B: 価格と配信状況 (Pricing and Availability)
3. § C: アプリのプライバシー (App Privacy)
4. § D: バージョン情報 (Version 1.0) — 説明文 / キーワード / スクショ
5. § E: App Review 情報 (レビュー時連絡先 + メモ)
6. § F: TestFlight (内部テスト → 外部テスト → 申請)

---

## § A. アプリ情報 (App Information)

**直接 URL**: <https://appstoreconnect.apple.com/apps/6770092724/distribution/info>

**遷移 (左サイド)**: App Store Connect > マイ App > Solara > **一般 > アプリ情報**

### A-1. ローカライズ可能な情報 (日本語)

#### 名前 (30 字以内)
```
Solara
```

#### サブタイトル (30 字以内)
```
西洋占星術と AI でひもとく自己探求
```

#### プライバシーポリシー URL
```
https://solodev-lab.com/legal/solara/privacy.html
```

### A-2. カテゴリ
- **プライマリ**: ライフスタイル (Lifestyle)
- **セカンダリ**: エンターテインメント (Entertainment)

### A-3. コンテンツの配信権

→ 「**いいえ、含まれていません**」を選択 (Solara は第三者のコンテンツや素材を含まない)

### A-4. 年齢制限 (Age Rating)

→ **対応済 (2026-05-28)**。算出結果 = **4+** (173 国・地域)。`age_rating_questionnaire.md` の §1.8/§1.11 は subagent 誤情報、4+ で正解 (公式情報確認済)。

すべての質問項目を **「なし / いいえ」** で保存 → 自動算出 4+ → 保存。

---

## § B. 価格と配信状況 (Pricing and Availability)

**直接 URL**: <https://appstoreconnect.apple.com/apps/6770092724/pricing>

**遷移 (左サイド)**: ↓ または **収益化 > 価格および配信状況**

### B-1. 価格
→ **無料**

### B-2. 配信状況
→ **すべての国または地域** (デフォルト)、日本市場メインだが世界配信で問題なし

### B-3. App Store の配信制限
- ✅ 「教育機関向け一括購入を含む」: **いいえ** (個人事業主のため)
- ✅ 「App Store プロモーション コード」: **任意** (使うときに有効化)

---

## § C. アプリのプライバシー (App Privacy)

**直接 URL**: <https://appstoreconnect.apple.com/apps/6770092724/privacy>

**遷移 (左サイド)**: **App Store > アプリのプライバシー**

### C-1. プライバシーポリシー URL
```
https://solodev-lab.com/legal/solara/privacy.html
```

### C-2. データの種類 (収集する全データを申告)

各データタイプに対して: **収集する? → リンクされている? → トラッキング? → 用途**

#### 個人情報 (Personal info)
| データ | 収集 | リンク | トラッキング | 用途 |
|---|---|---|---|---|
| 名前 (ニックネーム) | はい | はい | いいえ | App functionality |
| メールアドレス | はい (SI 時のみ) | はい | いいえ | App functionality |
| ユーザー ID (appUserId) | はい | はい | いいえ | App functionality / Analytics |
| その他のユーザー情報 (出生情報) | はい | はい | いいえ | App functionality |

#### 位置情報 (Location)
| データ | 収集 | リンク | トラッキング | 用途 |
|---|---|---|---|---|
| 正確な位置情報 | はい | はい | いいえ | App functionality |
| 大まかな位置情報 | はい | はい | いいえ | App functionality |

#### ユーザー コンテンツ (User content)
| データ | 収集 | リンク | トラッキング | 用途 |
|---|---|---|---|---|
| その他のユーザー コンテンツ (相談入力テキスト) | はい | はい | いいえ | App functionality |

#### 識別子 (Identifiers)
| データ | 収集 | リンク | トラッキング | 用途 |
|---|---|---|---|---|
| ユーザー ID | はい | はい | いいえ | Analytics |
| デバイス ID | はい | はい | いいえ | Analytics |

#### 購入情報 (Purchases)
| データ | 収集 | リンク | トラッキング | 用途 |
|---|---|---|---|---|
| 購入履歴 | はい | はい | いいえ | App functionality |

#### 使用状況データ (Usage Data)
| データ | 収集 | リンク | トラッキング | 用途 |
|---|---|---|---|---|
| プロダクトのインタラクション | はい | はい | いいえ | Analytics |

#### 診断 (Diagnostics)
→ **収集しない** (Firebase Crashlytics 未導入)

#### 連絡先情報 (Contact Info の他カテゴリ) / 健康とフィットネス / 財務情報 / 機密情報 / 検索履歴 / 閲覧履歴 / その他のデータ
→ **すべて収集しない**

---

## § D. バージョン情報 (Version 1.0)

**直接 URL**: <https://appstoreconnect.apple.com/apps/6770092724/distribution>

**遷移 (左サイド)**: **配信 > iOSアプリ 1.0 提出準備中**

### D-1. プロモーション テキスト (170 字以内、リリース後も変更可)
```
Solara は出生図とトランジットを土台に、AI が一人ひとりの解釈を紡ぐ西洋占星術の自己探求アプリです。タロット、地図上のアストロカートグラフィ、Stella との相談で、今の内的な季節を読み解きます。本アプリの読み解きは娯楽および自己内省のためのものです。
```

### D-2. 説明 (Description、4000 字以内)
```
【ご利用前のおしらせ】
Solara は娯楽および自己探求のためのアプリです。
占星術・タロット・AI 相談はいかなる種類の専門的助言
(医療・法律・金融・心理) も提供しません。
将来の出来事を予測・保証するものではありません。

──────────────

Solara は、西洋占星術の精密な計算エンジンを土台に、
AI が一人ひとりに合わせた解釈の言葉を紡ぐ自己探求アプリです。
出生図・トランジット・プログレスの 3 層構造で、
今のあなたを取り巻く星の動きを多角的に読み解きます。

■ 主な機能

✦ 出生図 (ネイタルチャート)
高精度の天体計算エンジンで、生まれた瞬間の星の配置を描画します。
出生時刻が分からない場合でも、ハウスに依存しない読み解きが可能です。

✦ 今日の占い (Horoscope)
AI が出生図と今日のトランジットを掛け合わせ、その日の星の動きを解釈します。
全体・恋愛・豊かさ・仕事・対話の 5 カテゴリを 1 日 1 回お届けします。

✦ タロット (Tarot)
AI 解釈付きのタロットドロー。78 枚のカードと月相・エレメントを統合し、
今の流れに寄り添う言葉を Stella (専属の占星術解釈エンジン) が紡ぎます。

✦ アストロカートグラフィ (地図占星術)
地図上に天体ラインを描画し、世界中の場所で星の影響がどう変わるかを可視化します。
あなたの出生図がその地でどう作動するか、視覚的に読み解けます。

✦ 方角占い + Map Fortune
現在地から見た 16 方位ごとに星のエネルギーをスコア化します。
お出かけ・旅行・移住の参考にお使いください。

✦ Stella との相談 (Cosmic Pro)
お出かけ・旅行・移住先などのテーマで、Stella と対話形式で読み解きます。
複数の候補地を、占星術的な「在るエネルギー」の観点で比較できます。

✦ 西暦年運勢ヒートマップ
1 年を通した日々の星の動きを、色のグラデーションで可視化します。
内的なサイクルを俯瞰して捉えられます。

✦ Galaxy (天体イベント可視化)
新月・満月・水星逆行などのタイミングを、星座の動きとして体感できます。

■ AI による解釈について

本アプリの解釈文 (タロット・Stella 相談・今日の占い) は、
Google の Gemini AI が生成しています。
あなたの出生情報 (生年月日・出生時刻・出生地) と相談入力テキストは、
解釈生成のために Google のサーバーへ送信されます。
初回起動時に明示的な同意をいただきます。

■ Cosmic Pro (サブスクリプション)

無料機能だけでも 1 日 1 回の今日の占いとタロット 1 枚を楽しめます。
Cosmic Pro にご登録いただくと、以下が追加で開放されます:

・Stella との相談 (週 100 回まで)
・全カテゴリの今日の占い (恋愛・豊かさ・仕事・対話)
・タロットのテーマ別ドロー (Pro 限定機能)
・西暦年運勢ヒートマップの全期間表示

価格・期間・自動更新の詳細は購入画面でご確認いただけます。
解約は iOS の場合「設定 > Apple ID > サブスクリプション」、
Android の場合「Google Play > サブスクリプション」からいつでも行えます。
解約は次回更新日の 24 時間前までに行ってください。

■ プライバシーと安全

・出生情報はサインインなしでも入力できます (匿名利用可)
・アカウントの削除はアプリ内 (Sanctuary > アカウント > 削除) から数タップで完了します
・Apple サインインの場合、削除時に Apple 側の連携も自動解除されます

■ 重要なご案内 (再掲)

Solara が提供する占星術・タロット・AI 相談は、すべて娯楽および自己探求の
ためのものです。医療・法律・金融・心理に関する専門的な助言ではありません。
将来の出来事を予測・保証するものでもありません。
重要な意思決定は、ご自身の意思と専門家への相談に基づいて行ってください。
```

### D-3. キーワード (100 字以内、カンマ区切り、半角)
```
西洋占星術,出生図,トランジット,タロット,アストロカートグラフィ,星読み,自己探求,内省
```

### D-4. サポート URL
```
https://solodev-lab.com/legal/solara/
```

### D-5. マーケティング URL (任意、空でも可)
```
https://solodev-lab.com/legal/solara/
```

### D-6. What's New in this Version (バージョン 1.0 初回なので)
```
v1.0.0 — はじめての公開バージョン
・西洋占星術の出生図・トランジット・プログレス
・今日の占い、タロット、Stella との相談
・地図上のアストロカートグラフィと方角占い
```

### D-7. App Store スクリーンショット (画像アップロード)

**必須サイズ**:
- **6.7-inch (iPhone 15 Pro Max)**: 1290 × 2796 px
- **6.5-inch (iPhone 11 Pro Max)**: 1242 × 2688 px

**推奨内容** (各 6.7-inch + 6.5-inch、合計最低 6 枚):

| # | 画面 | キャッチコピー |
|---|---|---|
| 1 | Sanctuary (出生図) | 「あなたの出生図を読み解く」 |
| 2 | 今日の占い (Horoscope) | 「AI が今日の星の動きを解釈する」 |
| 3 | Map (アストロカートグラフィ) | 「世界地図で星の影響を見る」 |
| 4 | Tarot 結果 | 「タロットの解釈を Stella が紡ぐ」 |
| 5 | Stella 相談 結果 | 「お出かけ・旅行先を星の観点で見つける」 |
| 6 | Galaxy | 「天体イベントを体感する」 |

🔴 **キャッチコピーで NG**: 「占い」「運勢」「予言」「的中」「保証」 (Apple 2.3.10 検出対象)

### D-8. App アイコン (1024 × 1024 px、透過なし PNG)
→ ✅ 生成済: `docs/store_compliance_assets/icons/apple_app_store_icon_1024.png` (1024×1024, RGB / **alpha なし**, 938KB)。
  unsealed 8芒星メダルを `tools/make_app_icon.py` で書き出し。Build にも同梱 (Icon-App-1024x1024@1x.png, remove_alpha_ios) されており、通常は Xcode アップロードで自動受領。手動入稿が必要な場合はこのファイルを使う。

### D-9. App プレビュー (動画、任意)
→ 初回公開はスキップで OK。後で追加可能。

### D-10. ビルド (TestFlight 経由)
→ Codemagic で v+13 build を TestFlight にアップロード後、ここで該当 build を選択。

---

## § E. App Review 情報 (レビュー時連絡先 + メモ)

**遷移**: § D の同じ画面の下部にある「App Review 情報」セクション。

### E-1. サインイン情報 (テスト アカウント)
- **ユーザー名**: (Apple SIWA テスト用の Apple ID メールアドレス)
- **パスワード**: (上記 Apple ID のパスワード)

🔴 重要: **Apple Reviewer がアプリ内 Sign in with Apple をテストできるアカウント**を必ず提供。`sign in required` のままだと Reject される。

### E-2. 連絡先情報
- **名 (First Name)**: 宏治
- **姓 (Last Name)**: 林
- **電話番号**: 090-9207-6232
- **メールアドレス**: usin.kodima@gmail.com

### E-3. メモ (Notes、Reviewer 向け、英語推奨)
```
Solara differentiates from generic horoscope apps by integrating:
- Personalized AI interpretations (Gemini) with user consent on first launch
- Astrocartography (planetary lines on world map) — geographic divination
- Stella AI consultation for travel/relocation candidates (Cosmic Pro)
- 3-layer transit reading (natal/transit/progressed)

Not a stock fortune-telling app. Entertainment & self-reflection tool only.
Medical/legal/financial advice is explicitly disclaimed (in-app + on-screen footer).
AI output reporting button available on every AI-generated result.

Account deletion: in-app (Sanctuary > Account > Delete) + web URL
(https://solodev-lab.com/legal/solara/delete-account.html)

Apple Sign In Token Revocation is implemented via Cloudflare Worker
(/auth/revoke) per Guideline 5.1.1(v).

Privacy Manifest: All native plugins (RC / Google Sign-In / Apple Sign-In /
flutter_map etc.) ship with PrivacyInfo.xcprivacy in their latest versions.

Test account credentials are provided in the Sign-In Information section above.
```

### E-4. デモ アカウント関連情報 (任意)
→ Cosmic Pro 機能をレビュー時に試すための「サンドボックス Apple ID」を上記サインイン情報欄に記載済の場合は、ここで追加情報は不要。

---

## § F. TestFlight

**直接 URL**: <https://appstoreconnect.apple.com/apps/6770092724/testflight/groups>

**遷移 (左サイド)**: **TestFlight** タブ

### F-1. テスト情報 (内部 / 外部 共通の説明文)

#### Beta App 説明
```
Solara — 西洋占星術と AI による自己探求アプリのテスト版です。
出生図・トランジット・プログレスを土台にした星読み、AI が紡ぐタロット解釈、
地図上のアストロカートグラフィ、Stella との相談 (Cosmic Pro 機能) をお試しください。
```

#### Feedback Email
```
usin.kodima@gmail.com
```

#### Marketing URL (任意)
```
https://solodev-lab.com/legal/solara/
```

#### Privacy Policy URL
```
https://solodev-lab.com/legal/solara/privacy.html
```

### F-2. 内部テスター
→ オーナーの App Store Connect ユーザー (kojifo369@gmail.com) を内部テスターとして追加。最大 100 名まで。

### F-3. 外部テスター (Beta App Review 必要)
→ 外部テスター用のテスト情報入力後、Apple のレビュー (~24h) を経て公開可能。Solara のレビューに使う Apple ID も「外部テスター」として招待しておくと、本番レビュー時に同じビルドで使える。

### F-4. ビルド アップロード
→ Codemagic で v+13 build を TestFlight にアップロード (codemagic.yaml の `submit_to_testflight: true` で自動)。

---

## § G. ストア審査 提出 (Submit for Review)

**遷移**: § D のページ右上の **「審査へ提出」** ボタン

🔴 **すべての必須項目が埋まっている** ことを確認してから押す:
- ✅ アプリ情報 (§A)
- ✅ 価格と配信状況 (§B)
- ✅ App Privacy (§C)
- ✅ バージョン情報 + スクショ + ビルド (§D)
- ✅ App Review 情報 + Sign-In アカウント + メモ (§E)
- ✅ TestFlight に動作確認済ビルドあり (§F)

提出後の流れ:
1. 「審査待ち」(数日〜数週間)
2. 「審査中」(数時間〜1日)
3. 「準備完了」(承認) or 「リジェクト」(理由付き)
4. リジェクト時は Resolution Center で対応 ([store_compliance.md](../store_compliance.md) §6 参照)

---

## 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-05-28 | 初版 (旧 store_listing.md + age_rating_questionnaire.md の Apple 部分を統合 + URL/遷移明記) |
