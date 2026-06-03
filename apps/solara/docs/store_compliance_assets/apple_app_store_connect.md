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
Solara: Astrolabe
```

#### サブタイトル (30 字以内)
```
時と場所を読む、人生のアストロラーベ
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
これまでの占星術は「あなたがどんな人か」を語ってきました。Solaraはその先へ——「いつ・どこで・何をするか」まで、星で照らします。世界地図の惑星ラインと方位のエネルギーが結びつき、星の力を“意図して”味方にできる。人生の舵を、もう一度あなたの手に。
```

### D-2. 説明 (Description、4000 字以内)
```
これまでの占星術は、「あなたがどんな人か」を映してきました。
Solara が照らすのは、その先——「いつ・どこで・何をするか」。
星から「時」と「場所」を読み解く、あなただけのアストロラーベ。

世界地図にあなたの惑星のラインが広がり、立つ場所と時間によって、主役の星が変わっていく。Solara は、占星術師のジム・ルイス氏が体系化したアストロカートグラフィ（ACG／CCG）と“方位”のエネルギーを一つに編み込み、「今この瞬間」と「向かう場所」のエネルギーを、言葉にして手渡す星読みアプリです。

星に振り回されるのではなく、星を“意図して”味方につける。
基準点はどこにする？ 日時はいつにする？——決めるのは、あなた自身。
さあ、人生の舵を、もう一度あなたの手に。

※ Solara は娯楽および自己探求のためのアプリです。医療・法律・金融・心理の助言や、将来の予測・保証は行いません。

──────────────

■ Solara にできること

◇ 世界地図で“星の地形”を読む（ACG／CCG）
あなたの星が、世界のどこで、いつ強く働くのか。地図上のラインで一目に。旅・引っ越し・行きたい街を、星の視点で選べます。

◇ 今いる場所から、16方位のエネルギー
現在地を中心に、どの方角に星のエネルギーが満ちているか。「今日はどちらへ？」の、小さな道しるべに。

◇ 行き先を、見比べる
職場・お店・デート先など気になる場所を登録し、日時×目的のエネルギーで並べて選べます。

◇ あなただけの読み解き、毎日
出生図 ×「今日」の星を掛け合わせ、12星座の一言では終わらない、あなた自身の言葉を紡ぎます。

◇ Stella との対話 ／ タロット ／ 一年のリズム ／ 美しい出生図 ／ 育つ星座のアーカイブ
気になる候補地を比べ、78枚のカードに今を映し、365日の星の波を俯瞰し、生まれた瞬間の空を眺め、記録を重ねるごとに星座を育てる——知るための入り口を、いくつも。

──────────────

■ Stella は、いつもあなたの味方

Solara をつくったのは、現役の占星術師。物心ついた頃から、数えきれない人生相談に向き合ってきました。その経験とノウハウ、そして「あなたに幸せになってほしい」という願いを、アプリの中に棲む解釈エンジン “Stella” に託しています。

Solara が見せるのは、未来の言い当てではなく、膨大な星のデータから導いた“ひとつの解釈”。それをどう受け取り、どう動くかは、あなた次第。星も、Stella も、いつだってあなたの味方です。

──────────────

■ 無料でできること
・世界地図の星のライン（ACG／CCG）4フレームすべて
・毎日の星読み（全体運）と、1日1回のタロット
・Stella との相談 週3回
・あなたの記録の永久保存・検索・シェア

■ Cosmic Pro ― 星と地に重なる景色を、もっと深く
・おでかけの「時刻」を指定し、“30分後の変化”まで読める。CCG の星の線は地球の自転で動き、その場の主役の星が静かに入れ替わります。
・Stella との相談が 週100回 に。
・星読みは全5カテゴリ＋深い読み。タロットは全7カテゴリをクレジット消費なしで、知りたいことを直接質問できます。
・アスペクトライン 40本→120本、天頂帯・天底帯、引越しシミュレーション、そして5年先までの予測まで。
価格・期間・自動更新は購入画面に表示されます。解約はいつでも可能です（次回更新日の24時間前まで）。

■ ご利用にあたって
・サインインなしで使えます（匿名OK）。出生情報はあなたの読み解きのためだけに使われ、アカウントはアプリ内からいつでも削除できます。
・タロット・Stella・今日の読み解きの文章は、Google の生成AI「Gemini」が作成します。出生情報（生年月日・出生時刻・出生地）、現住所と入力テキストは、文章生成のため Google のサーバーへ送信されます。初回起動時に同意をお願いします。

【重要なご案内】Solara の占星術・タロット・相談は、すべて娯楽および自己探求のためのものです。専門的な助言（医療・法律・金融・心理）ではなく、将来を予測・保証するものでもありません。大切な選択は、ご自身の意思と専門家への相談に基づいて行ってください。
```

### D-3. キーワード (100 字以内、カンマ区切り、半角)
```
ホロスコープ,星占い,12星座,占星術,タロット,占い,相性,運勢,地図占星術,引っ越し,旅行,方角,パワースポット,ネイタルチャート,月星座,新月,満月,水星逆行,星読み,スピリチュアル
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
・占星術の出生図・トランジット・プログレス
・今日の占い、タロット、Stella との相談
・地図上のアストロカートグラフィと方角占い
```

### D-7. App Store スクリーンショット (画像アップロード)

**必須サイズ**:
- **6.7-inch (iPhone 15 Pro Max)**: 1290 × 2796 px
- **6.5-inch (iPhone 11 Pro Max)**: 1242 × 2688 px

**推奨内容** (各 6.7-inch + 6.5-inch、合計最低 6 枚):

| # | ファイル | 見出しキャッチコピー |
|---|---|---|
| 01 | 01_map_energy | 行く先のエネルギーが、地図でわかる。 |
| 02 | 02_acg_ccg | 行く土地と動く時で、主役の星が変わる。 |
| 03 | 03_locations | その日時・その場所のエネルギーが全部わかる。 |
| 04 | 04_search_energy | 検索した店のエネルギーが、ひと目で並ぶ。 |
| 05 | 05_stella_result | お出かけも、移住も。ぜんぶ星に相談。 |
| 06 | 06_horoscope | 精密な出生図が、すべての土台。 |
| 07 | 07_cycle | 恋も、豊かさも。めぐる季節を、先に。 |
| 08 | 08_heatmap | 1年の星のリズムを、色で見渡す。 |
| 09 | 09_star_reading | 星が語る、今日のあなたへの指針。 |
| 10 | 10_tarot | タロットが照らす、心の奥の答え。 |
| 11 | 11_star_atlas | 夜空にあなただけの星座が生まれる。 |

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
Solara — 占星術による自己探求アプリのテスト版です。
出生図・トランジット・プログレスを土台にした星読み、Stella が紡ぐタロット解釈、
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
