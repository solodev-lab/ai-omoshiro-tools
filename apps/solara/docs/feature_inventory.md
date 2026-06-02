# Solara Feature Inventory (人手版)

> Solara が「いま何を持っているか」を人手で整理した中核ドキュメント。
> 機械抽出の raw は [`feature_inventory/_index.md`](feature_inventory/_index.md) から各層に。
>
> **この文書のスコープ**: 課金要素検討の土台として、Solara の機能を層別に把握する。
> 関数 1 個ずつの中身は掘らない (「呼んでいる事実」のみ記録)。
>
> **更新フロー** (各層着手時):
> 1. `apps/solara/tools/feature_extractor/extract.py` 再実行
> 2. `feature_inventory/0X_*.md` を読みながら本ファイルに人手記述
> 3. 完了後 `extract.py` 再実行 → `feature_inventory/coverage_report.md` の #1/#2 で漏れチェック
>
> **構築進捗**:
> - [x] 層 0: Worker (バックエンド計算式) — 2026-05-14 完成
> - [x] 層 1a: 純計算ユーティリティ — 2026-05-14 完成
> - [x] 層 1b: 静的データ辞書 — 2026-05-14 完成
> - [x] 層 1c: モデルクラス — 2026-05-14 完成
> - [x] 層 2a: API/Worker ラッパ — 2026-05-14 完成
> - [x] 層 2b: 永続化/キャッシュ — 2026-05-14 完成
> - [x] 層 2c: グローバル singleton — 2026-05-14 完成
> - [x] 層 3a: 共通ウィジェット (純粋) — 2026-05-14 完成
> - [x] 層 3b: テーマ・装飾 — 2026-05-14 完成
> - [x] 層 3c: 演出ウィジェット (animated) — 2026-05-14 完成
> - [x] 層 4a: Map 画面 — 2026-05-14 完成
> - [x] 層 4b: Horoscope 画面 — 2026-05-14 完成
> - [x] 層 4c: Observe (Tarot) 画面 — 2026-05-14 完成
> - [x] 層 4d: Galaxy 画面 — 2026-05-14 完成
> - [x] 層 4e: Sanctuary 画面 — 2026-05-14 完成
> - [x] 層 4f: サブ画面 (Forecast / Locations / Philosophy / Font Preview) — 2026-05-14 完成
> - [x] 層 5: 連携層 (main / PopScope / IndexedStack) — 2026-05-14 完成 ← **全 17 層完了**

---

## 層 0: Worker (バックエンド計算式)

### 0.1 概要

Solara のバックエンドは **Cloudflare Workers** で稼働。本番 URL: `https://solara-api.solodev-lab.com`。
クライアント側で `solaraWorkerBase` 定数を参照 ([utils/solara_api.dart:17](../lib/utils/solara_api.dart)、ハードコード禁止 = [`project_solara_worker_url.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_worker_url.md))。

主な役割は 4 種:

| 役割 | 例 | 設計上の特徴 |
|---|---|---|
| **天体計算 (純数学)** | `/astro/chart`, `/astro/forecast`, `/astro/daily-transits`, `/astro/events`, `/tz` | `astronomy-engine` npm に依存。理論上は Dart 完結も可能 (実際に `astro_houses.dart`, `astro_lines.dart` は Dart 移植済み)。**Pro 機能の境界としては「無料公開層」になりやすい** |
| **AI narrative 仲介 (Gemini)** | `/fortune`, `/tarot`, `/relocation`, `/astro/consultation2` (V2 現役), `/astro/consultation` (旧・後方互換), ~~`/astro/line-narrative`~~ | Gemini API key 秘匿のため Worker 必須。**課金で守るべき最大の対象** — 1 リクエスト = Gemini コスト発生。相談は Free 試食クレジット制 (下記 0.2.1)。**Flutter は V2 `/astro/consultation2` を呼ぶ** (全要素統合: client 最小入力→Worker 全計算、2026-05-24) |
| **検索プロキシ** | `/search` | Google Places (主) + Nominatim (フォールバック)。Google Places は月 1 万 req 無料枠 |
| **地図タイル中継** | `/tiles/osm/*` | OSM 系を Worker UA で取得、edge cache 24h。アプリ直叩きだと 403 (UA 不足) |

### 0.2 セキュリティ現状と次フェーズ

**現状** (2026-05-14):
- CORS は `solodev-lab.github.io`, `solodev-lab.com`, `localhost` のみ ([index.js:15-20](../worker/src/index.js))
- per-endpoint memory rate limit (forecast=6/min, tiles=600/min, default=30/min)
- forecast は KV 月次クォータ 60 req/IP/month

**Pro 公開時 (未実装、必須)** — [`project_solara_security_principles.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_security_principles.md):
- ルート物理分離 (`/public/*`, `/auth/*`, `/protected/*`)
- App Attest / Play Integrity でアプリ改変対策
- RevenueCat Trusted Entitlements `.enforced` でクライアント単独 isPro 判定禁止
- Gemini 呼出 4 系 (`/fortune`, `/tarot`, `/relocation`, future) を `/protected/*` 配下へ

### 0.2.1 Stella 相談 クレジット制 (2026-05-23、設計 `project_solara_stella_free_credits.md`)

相談は「Free に試食枠を開いた看板 Gemini 機能」。**1 クレジット = Stella 生成 1 回**
(V2 では 1 クレジット = 1 候補。「別の候補地」も 1 消費)。Flutter 現役は V2 `/astro/consultation2`
(全要素統合)、旧 `/astro/consultation` は deployed app 後方互換で Worker 側に温存。設計詳細は
[`project_solara_stella_free_credits.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_stella_free_credits.md)。

- **品質**: Free も Pro も同等 (thinking ON・全モード・出し直し可)。違いは**回数だけ**。
- **消費順 (非 Pro)**: 無料週次クレジット → 使い切ったら購入残高。両方尽きたら 402。
  - **無料週次**: `CONSULTATION_FREE_WEEKLY` (default 3)、端末 ID × ISO 週 (月曜 UTC リセット)。
    端末 ID = iOS `ios:{keyId}` / それ以外 `usr:{appUserId}` (再インストール farming 耐性)。
  - **購入残高**: 消費型 IAP。**アカウント appUserId 紐付け** (サインイン必須、機種変で失わない)。失効しない。
- **モード制限**: `CONSULTATION_FREE_MODES` (default 全3) = 非 Pro がアクセスできるモード。対象外は 402
  `consultation_pro_only_mode`。env で `daily` だけ等に絞れる。
- **Pro**: 当初は無制限。2026-05-27 に **Pro 週次キャップ 100 回/週** 導入 (詳細は §0.2.3)。
  共通ゲート `consumeReadingCreditGate` を通る Tarot カテゴリは引き続き Pro 無制限 (キャップ無し)。
- **消費タイミング**: 実際に Stella 生成が成功した時だけ (静的 fallback は消費しない)。
- **ゲート**: `index.js` `gateConsultation` (middleware 通過後・生成前)。`consultationCreditStatus` が残数を算出
  (生成レスポンスへの添付 + 状況 endpoint で共用)。
- **DO 表/endpoint**:
  - `consultation_credits` (無料週次) + `/consultation-credit-get` `/consultation-credit-bump`
  - `consultation_purchased` (購入残高) + `/consultation-purchased-get` `/consultation-purchased-spend`
    `/consultation-credit-grant` (RC Webhook から付与、event_id 冪等)
- **付与経路**: RC Webhook `NON_RENEWING_PURCHASE` で `product_id` が `CONSULTATION_CREDIT_PRODUCTS`
  ("商品ID:付与数" CSV) にあれば残高 +N (`revenuecat.js`、cosmic_pro entitlement とは無関係に処理)。
- **状況 endpoint**: `/protected/consultation/credits` → {pro, freeRemaining, freeLimit, purchasedBalance}。
  クライアントの残数表示・購入後の残高更新に使う。
- **コスト多層防御**: 相談は middleware の日次クォータ (2026-05-25: **Free30 / Pro50**、旧 Free5/Pro100 から変更) も 1 消費 (週次/購入とは別軸のバックストップ、Pro「無制限」のテール乱用を物理遮断)。env `APP_ATTEST_QUOTA_FREE/PRO`、実ブロックは enforced 化時に発動。
- **クライアント**: 入口 Pro ゲート撤廃 (Free も入力画面へ)、402 で「追加クレジット購入 / Cosmic Pro」box、
  `consultation_credit_sheet.dart` が消費型購入シート (3個/10個 + Pro 誘導、購入前サインイン必須、
  付与は Webhook ラグをポーリングで吸収)。
- **残数表示の集約 (2026-05-26 整理)**: 結果画面上部の残数バナー (旧 `_FreeCreditsBanner`) と
  内的季節バナー (旧 `_InnerSeasonBanner`) は撤去 (内的季節文は AppBar の「この読み解きについて」
  popup に残置)。クレジット残は以下 2 か所に集約:
  - **Sanctuary 最上部**: `_credits` セル (タップで `showConsultationCreditSheet` 起動・購入導線)。
    アプリ復帰 / 購入完了 / 相談実行で **自動再フェッチ**。
  - **入力画面の開始ポップアップ** (`_StartConsultPopup`): タイトルが文脈反映
    (free>0 → 「無料クレジットを使う」/ free=0 で paid>0 → 「有料クレジットを使う」/ 両方0 → 「クレジットを使う」)、
    バッジは **無料 / 有料の 2 行**を常時表示。表示直前に `_refreshCreditsFresh` で再フェッチして古値防止。
- **クロス画面の同期機構** (2026-05-26 設計変更): `ConsultationCredits` (state-holder
  ChangeNotifier singleton、`utils/consultation_credits.dart`)。
  `ConsultationCredits.instance`
  クレジット残数 (`ConsultationCreditStatus`) を 1 個だけ保持し、UI 各所 (Sanctuary 上部 /
  開始 popup / 購入シート / Tarot カテゴリ popup) は build で `instance.status` を読む
  (自分で fetch しない)。`refresh()` は **in-flight dedup** あり (同時複数 await でも HTTP は
  1 本)。fetch をトリガーするのは 4 イベントのみ: ① アプリ起動 (main.dart) ② 消費直後
  (相談実行 / Tarot draw) ③ 購入完了ポーリング (consultation_credit_sheet) ④ app resumed
  (main.dart の SolaraHome 1 箇所に集約)。
  設計変更前は notify-only な旧 `ConsultationCreditEvents` で各 listener が独立に fetch →
  5 分間 45 回 (DO 内部含め 320+ 件) のバーストが CF logs で観測されたため state holder 型に
  再設計。Sanctuary 等の listener は `setState(() {})` を呼ぶだけで自分で fetch しない。

#### タロットカテゴリ (同じクレジット財布、2026-05-23 追加 / 2026-05-26 UI 改修)
**1 クレジット = AI 占い 1 回**は相談とタロットで共通 (同じ財布)。`/protected/tarot` も
共通ゲート (`consumeReadingCreditGate` / `consumeReadingCredit`) を使う:
- **全体運 (category なし)**: 無料・1 日 1 回。日付境界は「1日の開始時刻」設定基準の論理日 (`SolaraStorage.logicalTodayKey`)。引いた後にリセット時刻を後ろへずらして再ドローする不正は単調ガード (`hasDrawnFreeTarotToday`/`markFreeTarotDrawn`) でブロック。クレジット消費なし。
- **カテゴリ指定 (love/money/work/communication/healing/newStart)**: 非 Pro は 1 クレジット消費
  (無料週次→購入残高)。Pro は無制限。`tarot.js` がカテゴリを prompt に反映。
- 402 (クレジット切れ) → `fortune_api.TarotReading.creditExhausted` → `observe_screen` が
  購入/Pro シート (相談と共通の `showConsultationCreditSheet`) を出す。
- 自由記入欄 (question) は引き続き Pro 限定 (A3、`observe_question_field`)。
- 共通ゲートは `consultation_*` の DO 表/env をそのまま共用 (履歴的命名だが汎用「占いクレジット」)。

##### 2026-05-26 UI 改修 (カテゴリ tap → 確認 POPUP)
カテゴリ chip tap で即座にカードタップ可能だった旧 UI が「カードを何度もタップして連続消費できる」問題を持っていたため、確認 POPUP を挟む形式に再設計:
- **新規 `_TarotCategoryPopupBody`** (`tarot_category_popup.dart`, `showTarotCategoryPopup`):
  カテゴリ確認 popup。タイトルが次に消費されるクレジット種別 (free>0 → 「無料」/ paid>0 → 「有料」) を反映。
  無料/有料の両方を 2 行で常時表示 (相談の `_StartConsultPopup` と同じ視覚規約)。
  「引く」=proceed=true、「キャンセル」/×/外タップ=proceed=false、「クレジットを購入」=onBuy 呼出。
- **`_categoryConfirmed` フラグ** (`observe_screen.dart`):
  POPUP 「引く」で true、カードタップ + API 成功で false にリセット。`_drawCard` 冒頭で
  `if (isCategoryDraw && !_categoryConfirmed) return;` ガード = 連打不可。
- **`_onCategoryChipTap` ディスパッチ**:
  全体運 tap (key=null): カテゴリ選択中なら 2 秒トースト `_showOverallNoCostToast` + 全体運化、
  元から全体運なら無音。Pro カテゴリ tap: POPUP なしで即確定 (無制限のため摩擦不要)。
  非 Pro カテゴリ tap: 残数 `ConsultationCredits.refresh()` → POPUP → 「引く」で確定。
- **残数の即時反映**: 消費成功時に `ConsultationCredits.instance.refresh()` (singleton) →
  全画面 (Sanctuary 上部 / Start popup) が listener 経由で一気に更新。
- **テスト**: `test/tarot_category_popup_test.dart` (9 件) でタイトル切替・各ボタンの戻り値・onBuy 呼出を網羅。

### 0.2.2 Stella相談 V2 (全要素統合) — 設計ノートと気付き (2026-05-24)

> 公開前ラスト本丸として相談を「アプリ全要素を統合する核心機能」に作り直した記録。
> 設計の全決定はメモリ `project_solara_consultation_full_integration.md` が一次資料。
> ここは**仕様の要約 + 結果出力の考え方 + 技術的な気付き**を 1 か所にまとめた版
> (バラバラに散らさないための統合ドキュメント)。

#### 仕様の核 (V1 → V2 で何が変わったか)
- **需要側 (ユーザーの問い) から設計**: 「ユーザーがこう問う → だからこの占星術データを使う」。
  相談の背骨 = 5 つの問い: ① テーマ / ② 場面 / ③ いつ / ④ どこで / ⑤ だれと / ⑥ どうなりたい(願い)。
- **4 つのつまみモデル** (組合せ表でなくシンセの 4 スライダー): エンジンは常に同じフル計算
  (ネイタル+リロケ+トランジット+プログレス) を回し、問いは「どのデータが在るか」でなく
  同じ計算に **フィルタ / 重み / レンズ** をかける。時間つまみ(日付)・焦点つまみ(テーマ+誰と)・
  場所つまみ(場面)・レンズつまみ(願い)。
- **全サーバー計算 + client 最小入力**: client は「誕生+自宅+5問+preset」(約 1KB) だけ送り、
  Worker がチャート/線/sectorEnergy/候補選定(レンズ回転)/リロケハウスを全計算 → Stella ナレーション。
  client 候補生成 (`consultation_engine.dart`) と Dart 版 `world_cities.dart` は撤去。
- **候補は 1 つずつ**: 最初の取得で「一番強い見出し候補」、「別の候補地」で excluded を足して
  次の候補を 1 枚ずつ。出し直しごとにレンズが回る (合成最強→アスペクト再合成→ランダム、§0.2.18)。
  **1 クレジット = 1 候補**。枯渇 (これ以上活きた候補が無い) は案Y=正直に止めて代替を提案、クレジットは消費しない。
- **影響プール = 全データ**: 4 アングル合線 + アスペクト線(合/トライン/スクエア/セクスタイル) +
  天頂帯/天底帯(緯度効果) を、フレーム横断(natal+transit+progressed、旅行は ≤3 日サンプリング)で集める。
- **入口 3 導線**: Map タップ / Daily Transit / 検索結果詳細「✦ Stella に相談」。

#### 2026-05-25 改善 (実機テスト起点)
- **おでかけの時間帯指定 (任意)**: `ConsultationWhen.timeBand` (morning/midday/evening/night/lateNight)。
  おでかけ場面のみチップ表示 (`_TimeBandSelector`)。指定時は Worker がその時間帯を語りの主役にし、
  予定外の時間帯に逸れない。未指定時は特定時間帯を断定しない (昼の予定なのに朝/夜更けを語る白け防止)。
  時間帯境界 (`consultation_engine.timeOfDayBucket`) は 5 帯: 朝5-10/昼10-15/夕方15-19/夜19-23/夜更け23-5
  (日をまたぐ。明け方 dawn は廃止)。
- **場所名の呼び方 (`ConsultationPoint.placeKind`)**: `placeReference` (consultation_v2.js) が分岐。
  `named`=検索で選んだ具体地点 → その場所名 (店/公園/会社/学校) をそのまま使い都市名に丸めない
  (例「JR名古屋高島屋」を「名古屋」にしない)。`saved`=ViewPoint/Locations 登録地 → 「(登録名)という場所」。
  null=従来 (都市候補=地域/半径スコープは従来の都市名分岐を温存)。
- **具体地点ピッカー**: 🔭ViewPoint + 📍Locations の 2 グループから保存地点を選べる (従来 Locations のみ)。
  presentational widget は `consultation_input_picker_widgets.dart` (part) に分離。
- **コスト**: thinking budget 1024→512 (consultation/consultation_v2/fortune/tarot、原価半減・品質維持)。
  詳細はメモリ `project_gemini_api_cost.md`。

#### 結果出力の考え方 (Stella の語りルール — 設計哲学の番人)
- **吉凶を出さない**: Soft(流れ・調和) と Hard(摩擦・課題) は独立した 2 エネルギー。
  total/比率/赤緑で 1 つの良し悪しに潰さない。「ラッキー/良い/悪い/吉凶」を使わない。
  Hard は「悪い」でなく「向き合う招待」として描く。
- **読心の禁止**: 相手や第三者の私的な気持ちを事実として断定しない (Stella は相談者チャート
  しか持たない=相手の心のデータが無い)。「彼はこう思っている」は捏造。代わりに
  「**あなたが何を意識し・どう動き・いつ動くか**」へ変換する (オーナーの占い哲学そのもの)。
- **距離(km)は本文に出さない**: 有無・質で語る。エビデンスページのみ km 提示 +
  「距離はエネルギーの有無を決めない。惑星ははるか遠方、地上の数百 km は圏内かどうかの差」。
- **時間は現地の時間帯のみ**: 時計の数字・TZ 名を出さない (朝/昼/夕/夜/夜更け/明け方)。
  旅行先は旅行先の現地時間で言う (経度→現地太陽時)。
- **正直フォールバック**: テーマ該当の強い線が近距離に無ければ無理に持ち上げず
  「テーマ線が遠い、静かでニュートラルな場」と正直に描く (本物の強さ > 作られた多様性)。
- **内的季節 = ライフステージ補正**: 年齢の数字を使わず、進行の月(サイン+ハウス)/進行の太陽で
  「今のあなたは〜の内的な季節」と一文の枠を作り、土地のエネルギーを重ねる。専門用語は出さない。
- **候補選定 = レンズ回転** (2026-05-29 リデザイン、旧「候補多様性 案C」を置換 → §0.2.18):
  1 回目=多線合成最強 / 2 回目=アスペクト線主役の再合成 / 3 回目以降=ランダム。
  ナレーション側は従来通り 1 候補に関係し合う ~2 ファクター、可能なら Soft+Hard を 1 つずつで「幅」を出す。
- **出生時刻不明でも品質を落とさない**: サイン/帯/遅い惑星/アスペクトでフル出力。
  困るのは移住のみ (ハウス/角が要る)。正午仮定でごまかさず、エビデンス末尾に控えめに注記。

#### 技術的な気付き (検証で分かったこと)
- 🌟 **サーバー側の CPU コストは意外とかからない**: 1 相談あたり最悪 ≈ 189ms
  (30 天体エフェメリス 1.8ms + world 762 都市スコアでも 80〜130ms + リロケ Placidus ×5 は無視可)。
  Worker CPU 上限 (paid 既定 30,000ms) の **1% 未満**。Gemini 待ちは I/O で CPU 計上外。
  → 「全部サーバーで計算する秘匿アーキ」でも CPU は全くボトルネックにならない (GO)。
- 💰 **コストも問題なし**: gemini-2.5-flash で **~$0.007/候補 (約 1 円)**。Free 週 3 で週 ~3 円/人。
  追加クレジット small(3 個 $2.99) の原価 3 円 = 粗利 ~99%。出力を長くする余地も大きい。
- 📶 **データ通信量が最小**: client の上り ~1KB / 下り = 候補テキスト数 KB。
  Solara のデータ食いは地図タイルで、相談はテキストのみで極小 (データ制限を圧迫しない)。
- 🎯 **全サーバー計算が 3 つ同時に最良**: ① ユーザーのデータ通信最小 ② 秘匿最大 (計算が全部
  サーバー・通信に出るのは入力と結果だけ) ③ client 最シンプル (チャート/線の受け渡し不要)。
- 🔒 **秘匿の線引き**: 表示しているもの (チャート/ACG線/方位スコア) は隠せない・隠さない。
  本当の秘密は「データそのもの」でなく「**どう扱うか** (意図・視点・重み・選び方・プロンプト)」。
  → エビデンスチップは占星術ファクターだけ見せ、重み付け・多様性ロジック・プロンプトは見せない。

#### 実装の所在 (層別)
- Worker (層 0): `consultation_engine.js` (秘伝計算 8 ステップ) / `consultation_v2.js`
  (Stella プロンプト + Gemini) / `index.js` `POST /protected/astro/consultation2` (クレジット 1=1 候補)。
- Flutter API (層 2a): `consultation_v2_api.dart` (+ `consultation_v2_request.dart` part) =
  `fetchConsultationV2` + 型群。クレジット系は `consultation_api.dart` (スリム化) に温存。
- Flutter 画面 (層 4f): 入力 `consultation_input_screen.dart` (+ widgets/when_scope/examples/picker/
  logic/start_popup part) / 結果 `consultation_result_screen.dart` (+ widgets/card/credit/share part) /
  履歴 `consultation_history_screen.dart` (+ widgets part) / レコード `consultation_record.dart`。
  履歴は **お気に入り登録** (各カードの ★ ボタン → `ConsultationRecord.favorite` + `SolaraStorage.setConsultationFavorite`) と
  **「すべて / ★ お気に入り」フィルタ** に対応 (favorite は JSON で true のときのみ保存)。

#### 2026-05-27 修正: placeKind が pipeline で消える列挙忘れバグ修正
- **症状**: 検索詳細から相談 → 結果で「JR名古屋高島屋」が「名古屋のこの場所」に丸められた。
- **根因**: `runConsultationPipeline` (consultation_engine.js) の最終 return で candidate を
  再構築する際、`buildCandidatePool` で乗せた `placeKind` を列挙していなかった (`...candidate` の
  スプレッドではなく明示列挙で書いていた)。`placeReference` (consultation_v2.js) は
  `candidate.placeKind === 'named'` を判定するため、消えると L84 のフォールバック分岐
  「都市名で呼んでよい・店舗名は出さない」に落ちて、店名が都市名に丸められた。
- **修正**: candidate の return に `placeKind: candidate.placeKind || null` を 1 行追加 +
  `candidateMeta` (consultation_v2.js) も同様。
- **再発防止**: `consultation_engine.test.js` に end-to-end テスト 3 件追加
  (`pipeline point scope: placeKind=named を candidate に保持` 等)。
  `placeReference` 単体テストだけでは検出できなかった「pipeline → placeReference」の透過テストを追加。

#### 0.2.18 候補選定リデザイン Phase A: レンズ回転 + 16方位 + 多線合成 + 案Y (2026-05-29)

> **位置づけ**: アプリの根幹機能 (Stella 相談の候補地選定) の再設計。旧「候補多様性 案C」
> (`signatureFamily` / `diversifyOrder` = 主役を毎回ズラして見栄えの幅を作る) を撤去し、
> 「本物の強さ順 → 質の違う 2 枚目 → ランダム」の **3 段レンズ回転** に置換した。
> Phase A = Worker エンジン (deterministic 計算) のみ。Phase B (D1+GeoNames 都市プール拡張・
> おでかけを実在の町に) は §0.2.19 で完了。Phase C (Flutter: avoid-window 永続化 N=Pro9/Free6・
> no-home=案ア・「自宅」→「現住所」表記・sparse/枯渇 UI) は未着手。

- **16 方位化** (`BEARING_DEFS` 8→16, `BEARING_JP`): おでかけ/方位スコープの合成点を 22.5° 刻みの
  16 方位 (北/北北東/…/北北西) に倍増。ラベルも 16 個。8 方位では「別の方角」を押すと粗く飛んでいた。
- **多線合成 `compositeStrengthOf`** (decay 0.6 の幾何級数和): 候補の主キーを「最強 1 本 (topStrength)」
  から「上位ファクターの減衰総和」に変更。**強 1 本 > 弱多数** かつ **厚い場 (複数中強線) > 単線** を
  区別する (線数インフレ防止)。`byRank` の第 1 ソートキーを compositeStrength に。
- **レンズ回転 `selectCandidate(scored, excluded, attempt, randomFn)`**: 出し直し回数 `attempt`
  (= excluded.length) でレンズを切替。
  - **1 回目 (attempt 0)** = 多線合成最強 (lens='composite')。lively (= honestQuiet でない) の先頭。
  - **2 回目 (attempt 1)** = アスペクト線主役の再合成 (lens='aspect', `aspectStrengthOf`)。
    trine/square=1.0・sextile=0.85・conjunction=0.35・帯=0.2 で再重み付け → 合成順とは別の「質の違う」土地。
  - **3 回目以降 (attempt ≥2)** = lively からランダム (lens='random', randomFn 注入可でテスト可能)。
  - 具体地点 (isPoint, scored 1 件) は attempt 不問で常に単一返し (lens='point')。
- **案Y = 正直に枯渇 + 非消費**: lively が尽きたら candidate=null + `exhausted:true` + `exhaustedReason`
  (`emptyPool` / `noFresh` / `allQuiet`) + `suggestions` (`suggestionsFor(scope)` =
  widenRadius/bearing/point/world のコード配列)。`consultationConsumed` が `!result.exhausted` を
  見るため枯渇は自動的にクレジット非消費。**1 回目で全部静か (allQuiet) は枯渇にせず**、最強の静かな場を
  fallbackHonest として返す (= 本物の読み・課金する)。枯渇は 2 回目以降にだけ起きる。
- **meta 拡張**: 成功 candidate に `compositeStrength` (×1000 丸め)、meta に `lens` / `attempt` を追加。
- **撤去**: `signatureFamily` / `diversifyOrder` (engine + test の参照のみ → 死蔵化を確認して削除)。
- **テスト**: `consultation_engine.test.js` 33 件 pass (compositeStrengthOf 減衰 / aspectStrengthOf 再重み /
  レンズ 3 段 attempt 0/1/2 / allQuiet fallbackHonest / 枯渇 3 reason / suggestionsFor / 16方位 length=16)。
  `consultation_v2.test.js` 24 件 pass (excluded 出し尽くし→exhausted は 16 方位全列挙に更新)。
  `consultation_credits.test.js` 30 件 pass (exhausted は非課金を維持)。

#### 0.2.19 候補選定リデザイン Phase B: D1 グローバル都市プール + おでかけ実在の町 (2026-05-29)

> **位置づけ**: §0.2.18 (Phase A) の続き。旧キュレート 762 都市 (`world_cities.js`) を
> **Cloudflare D1 のグローバル都市プール (GeoNames ベース)** に置換し、
> おでかけを「合成16方位」から **実在の町** に切り替える。Worker のみ (Flutter は Phase C)。
> **安全機構**: D1 binding (`env.DB`) が無い間は engine が従来 `worldCities`(762) に自動フォールバック
> するので、worker を先に deploy しても挙動は不変 (= v+17 クライアントに無影響)。owner が
> wrangler で D1 を有効化 + redeploy した瞬間に おでかけ が実在の町へ切り替わる (Phase C 配信と同期させる)。

- 🔴 **現行 D1 実測 (2026-06-02 照会)**: `cities` テーブル **488,270 行 / 246 の国・地域 = 全世界**。
  区・特別区など細粒度も `tools/seed_d1_subdivisions.py` で追加投入済。設計時の「約169,000 (cities1000)」は旧推定で
  実体はより多い。照会: `npx wrangler d1 execute solara-cities --command "SELECT COUNT(*) AS n FROM cities" --remote`。
- **seed**: `tools/seed_d1_cities.py` が GeoNames cities1000.zip + admin1CodesASCII を DL→パースし、
  `worker/migrations/0001_cities.sql` (スキーマ: lat/lng・(country,population)・population の 3 index) と
  `_geonames_cache/cities_data.sql` (約 12MB, gitignore, `wrangler d1 import` 用) を生成。
  名前戦略 (実測 GeoNames col1 name は JP でもローマ字): **JP=alternatenames の CJK 最短** (例 厚木/鎌倉)、
  **非JP=かな最短** (例 パリ/ロンドン、漢字のみは中国語誤認回避で除外)、無ければローマ字。
  region は JP のみ admin1→日本語県名 (47 県 100% マップ)、非 JP は null (region は表示専用・本文非使用)。
- **`buildCandidatePool` を async 化** (`{ scope, home, mode, env }` → `{ candidates, sparse, nearbyCount, source }`)。
  `runConsultationPipeline(request, env)` も async 化し `consultation_v2.handleConsultationV2` が `await`。
  - **局所 (おでかけ/近傍半径)** = D1 bounding-box (lat/lng 矩形 → JS で haversine 円精密化, 人口フロアなし)。
    実在の町を `townRowToCandidate` 化: `directionFromHome`(表示用「南西」等)/`directionCode`/`distanceKm` を付与、
    **`bearing` は敢えて立てない** (placeReference の「方角だけ・地名禁止」分岐に落ちるのを防ぎ町名を名指しさせる)。
  - **広域 (地域/自国/世界)** = D1 で **人口フロア + 人口順 + LIMIT N**。世界≥30万 / 地域≥10万 / 自国≥5万、
    N=`CONSULTATION_WIDE_LIMIT`(1000)。scorePool が粗ランク後 `FULL_SCORE_LIMIT`(48) しか full 採点しないため、
    プールが 1000 でも CPU は数十 ms に収まる (N は主に D1 read 量・payload を抑える役)。
  - **D1 binding 無し** = 全スコープ従来挙動 (`fallback-bearing`/`fallback-radius`/`fallback-region`/…)。
- **sparse**: 局所 bounding-box の件数が `CONSULTATION_SPARSE_MIN`(6) 未満で `meta.sparse=true` + `nearbyCount`。
  枯渇 (案Y) とは別物 (sparse はヒント用・候補は出す)。`consultation_v2` が `meta` で透過 → Phase C UI が消費。
- **env** (`wrangler.toml [vars]`, deploy だけで調整可): `CONSULTATION_DAILY_RADIUS_KM`(50) /
  `CONSULTATION_LOCAL_LIMIT`(1500) / `CONSULTATION_WORLD_MIN_POP`(300000) / `…_REGION_MIN_POP`(100000) /
  `…_COUNTRY_MIN_POP`(50000) / `CONSULTATION_WIDE_LIMIT`(1000) / `CONSULTATION_SPARSE_MIN`(6)。
- **owner 作業 (Cloudflare ログイン要)**: `wrangler d1 create solara-cities` → `wrangler.toml` の
  `[[d1_databases]]` (binding="DB") を database_id 入りでコメント解除 → `d1 execute --remote --file=0001_cities.sql` (schema) →
  `d1 execute --remote --yes --file=cities_data.sql` (約16.9万行・数分。**d1 import は v4 廃止 → execute --file**) →
  `wrangler deploy`。正確なコマンドは wrangler.toml の `[[d1_databases]]` コメントに同梱。
- **テスト**: `consultation_engine.test.js` 38 件 pass (D1 モックで bounding-box 50km 外除外 / sparse /
  人口フロア+LIMIT 可変 / 自国・地域フィルタ / countriesInGroup / bearing16 / フォールバック分岐)。
  `consultation_v2.test.js` 25 件 pass (D1 おでかけで candidateMeta→candidate に方角ラベル・町名がプロンプトに出る)。
  `consultation_credits.test.js` 30 件 pass。
- **Phase C-1 (§0.2.20 で完了)** / **Phase C-2 未着手**: 純 Flutter の表示反映 (実在の町・現住所表記・
  sparse/枯渇 UI・no-home=案ア) は §0.2.20。avoid-window 永続化 (N=Pro9/Free6, theme×scope) は worker
  追補 (avoid フィールド) を伴うため C-2 として分離・未着手。

#### 0.2.20 候補選定リデザイン Phase C-1: Flutter で実在の町・現住所・sparse/枯渇 UI を反映 (2026-05-29)

> **位置づけ**: §0.2.18-§0.2.19 (Phase A/B = worker) が返す新フィールドを Flutter 側で消費し、
> 「実在の町デプロイ」を ship-ready にする純 Flutter ラウンド (worker 変更なし)。avoid-window (C-2) は
> worker 追補を伴うため分離 (未着手)。本ラウンドの表示は **D1 binding 有効化前は従来挙動と同じ**
> (worker が D1 無し時に合成方位フォールバックするため・§0.2.19)。

- **API モデル拡張** (`consultation_v2_api.dart` / `consultation_v2_request.dart`):
  `ConsultationV2Candidate` に `directionFromHome` / `directionCode` / `distanceKm`、
  `ConsultationV2Reading` に `sparse` / `nearbyCount` (worker `meta` から)、
  `ConsultationV2Result` (exhausted) に `exhaustedReason` / `suggestions` を追加・パース。
- **実在の町表示** (`consultation_result_card.dart`): 字幕を「県名/国名 + 方角・距離」に再構成
  (例「神奈川県 · 南西 約30km」)。生の国コード「JP」を出さず、JP は県名・海外は `_kCountryJa` で
  日本語国名 (未知コードは非表示) に変換。`bearing` 立つ合成方位候補 (D1 無しフォールバック) は従来バッジ維持。
- **「自宅」→「現住所」** (`consultation_input_widgets.dart` / `consultation_input_screen.dart` /
  `consultation_history_screen.dart`): scope ラベル「現住所から半径」、距離 Section「現住所からの距離」、
  no-home 注記を「現住所が未設定です…『具体地点』は今すぐ使えます」に (案ア=具体地点を促す)。
- **sparse ヒント** (`_SparseHint` in `consultation_result_widgets.dart`): `reading.sparse` 時に
  「この近くは候補が少なめです (近くの候補は N 件ほど)。半径を広げる・方角を変えると…」を控えめ表示。
- **枯渇 = 案Y パネル** (`_ExhaustionPanel`): 出し尽くし時に snackbar でなく、理由
  (allQuiet/noFresh/emptyPool) のヘッドライン + 代替提案 (widenRadius/bearing/point/world を日本語チップ化) +
  **「※ この案内ではクレジットを消費していません」** を出す。`_loadNext` が `exhaustedReason`/`suggestions` を state に保持。
- **no-home = 案ア**: 既存挙動が既に正しい (`_canStart` が bearing/radius/country を home 無しで弾く・
  出生地フォールバックしない・point は home 不要)。注記に「具体地点は今すぐ使える」を追記して案内を補強。
- **テスト**: `consultation_ui_test.dart` 12 件 pass (§0.2.15 の 2 行タイル化/preset フロー変更で stale 化
  していた 3 件も現行 UI に追従修正 + Phase C 新規 2 件: 案Y 代替提案パネル / 実在の町字幕)。
  Flutter 相談テスト計 72 件 pass。`flutter analyze` クリーン。

#### 0.2.21 候補選定リデザイン Phase C-2: 無連続 avoid-window (2026-05-29)

> **位置づけ**: §0.2.18-§0.2.20 の最終ピース。theme×scope ごとに直近に提示した地名を覚えておき、
> 次の相談で同じ土地の繰り返しを避ける (Pro 9 / Free 6 件)。worker 追補 (`avoid` フィールド) を伴う。

- **設計上の肝 (excluded と avoid の分離)**: 旧来 `excluded` は「no-repeat フィルタ」と
  「レンズ回転の attempt カウンタ」(`attempt = excluded.length`) を兼ねていた。avoid-window の履歴を
  そのまま `excluded` に詰めると、新規相談の 1 回目でも attempt=N → いきなりランダムレンズになり
  「1 回目=合成最強」が壊れる。そこで **`avoid` を別フィールドにし、フィルタには効くが attempt には
  数えない**ようにした。
- **worker** (`consultation_engine.runConsultationPipeline`): `avoid=[]` を受け、
  `attempt=excluded.length` は不変、`selectCandidate` には `[...excluded, ...avoid]` を渡す。
  **安全策**: 新規相談 (attempt 0) で avoid-window のせいだけで枯渇したら avoid を無視して必ず 1 枚出す
  (先週見た土地でも、他に新鮮な候補が無ければ正直に出す = fresh 相談で「何も無い」を防ぐ)。
  出し直し (attempt≥1) は avoid 全滅なら従来どおり枯渇 (案Y)。handler は body を透過するので変更不要。
- **Flutter リクエスト** (`ConsultationRequest.avoid`): toJson (非空時) / copyWith / fromProfile に追加。
- **永続化** (`SolaraStorage`, key=`theme:scopeKind`, JSON マップ 1 キー `solara_consultation_avoid_v1`):
  `getConsultationAvoid(key)` / `pushConsultationAvoid(key, name, maxN)` (最新を末尾・最新 maxN に trim) /
  `clearConsultationAvoid()` (履歴「すべて削除」と連動)。
- **結果画面** (`consultation_result_screen`): 新規相談の開始時に window スナップショットを固定し、
  初回 + 出し直しの全リクエストに `avoid` として送る (具体地点 scope と履歴閲覧は対象外 = null キー)。
  提示した候補名は `_pushShownToAvoid` で window に積む (N = Pro 9 / Free 6, best-effort)。
- **テスト**: worker `consultation_engine.test.js` 40 件 pass (avoid は別候補にするが attempt/レンズ不変 /
  安全策で attempt0 は必ず 1 枚 / 出し直しは枯渇)。Flutter `consultation_ui_test` に avoid 往復テスト追加
  (送信 + 表示候補の積み上げ)。`flutter analyze` クリーン。
- **D1 障害耐性 (本番前手当て)**: `buildCandidatePool` の D1 分岐 (局所/広域) を try/catch で囲み、
  D1 が一時的に落ちても従来 worldCities/合成方位に degrade する (おでかけ/広域を 500 にしない・
  console.warn でログ)。テストに throwing D1 モックで degrade を検証。
- **これで Phase A/B/C 完了**。残るは D1 binding 有効化 + deploy (実在の町の本番切替) と app ビルド。

### 0.2.3 Pro 週次キャップ 100 回/週 (2026-05-27)

> **設計の柱**: 「Pro 無制限」を Gemini API 課金破綻防止のために 100 回/週でハードキャップ化。
> 100 を超えたら購入クレジットへフォールバック、それも 0 なら 402 で停止 + 月曜 UTC リセット。
> Free との対称性 (週次キャップ + 購入残高 + 402 paywall) を保ち、消費順だけが違う。

#### 設計判断
- **値の根拠**: 100/週 ≈ 月 430 回 ≈ **日平均 14 回 < 20 回/日 breakeven**。バースト
  (1 日 100 連発) があっても月平均で見れば赤字を回避できる。
- **別キーで管理**: `consultation_pro_credits` 表 (`device_key` PK + `week_bucket` + `used`)
  を `consultation_credits` (Free 週次) とは**別表**で持つ。Free → Pro upgrade した瞬間
  Pro 100 がフルで使え、Pro → Free 失効後も対称に Free 3 がフル。共用キーだと tier 変更ごとに
  マイグレーション挙動を考えないといけない (バグ温床) ため別表で完全分離。
- **Pro の消費順**: ① Pro 週次カウンタ → ② 購入クレジット残高 → ③ 402
  `consultation_pro_weekly_exhausted`。Free と完全に対称 (Free は無料週次 → 購入 → 402)。
- **ストア表記**: 公開前なので「無制限」表記は撤去 (Sanctuary の旧 "Unlimited Credits" 表示も
  「Pro 残 X / 100 ・ 購入 N (月曜補充)」に書き換え)。
- **Tarot は据え置き**: 共通ゲート `consumeReadingCreditGate` は変更せず、Pro 週次キャップは
  Stella 専用 `gateConsultation` でのみ発火。Tarot カテゴリは Pro 無制限のまま (オーナー方針)。

#### 実装の所在 (層別)
- DO (層 0): `attestation_state.js` `consultation_pro_credits` テーブル +
  `_consultationProCreditGet` / `_consultationProCreditBump` メソッド +
  `/consultation-pro-credit-{get,bump}` 経由 endpoint。構造は `consultation_credits` と完全対称。
- Worker (層 0): `index.js`
  - 新 helper `consultationProWeekly(env)` (default 100、env `CONSULTATION_PRO_WEEKLY` で上書き)
  - `gateConsultation` の Pro 分岐を「無制限 bypass」→「週次 → 購入 → 402」に書き換え
  - `consumeReadingCredit` に `source: 'pro_weekly'` 分岐追加 (旧 `gate.isPro` 早期 return は撤去)
  - `consultationCreditStatus` が Pro 時に `proRemaining/proLimit/weekBucket` も返すよう拡張
  - `/protected/astro/consultation2` レスポンスに `proCreditsRemaining/proCreditsLimit/isPro/
    weekBucket/purchasedBalance` を必ず添付 (Pro/非 Pro 両方とも)
- Flutter API (層 2a): `consultation_api.dart`
  - `ConsultationCreditStatus` に `proRemaining/proLimit/weekBucket` 追加 + `hasAny` を tier-aware に
  - `ConsultationBlock.proWeeklyExhausted` 追加 + `consultationBlockFromCode` で
    `consultation_pro_weekly_exhausted` → 新 enum 値にマップ
  - `consultation_v2_api.dart` `ConsultationV2Result` に `proCreditsRemaining/proCreditsLimit` 追加
- Flutter 画面 (層 4):
  - **Sanctuary 上部** (`sanctuary_screen.dart` `_buildCreditRow`): Pro 時は旧 "Unlimited
    Credits" 表示を撤去し「✦ Pro 残 X / 100 ・ 購入 N （月曜補充）」に統一。タップで購入シート起動。
  - **相談開始 popup** (`consultation_start_popup.dart` `_StartConsultPopup`): Pro でも表示対象に
    (`_onStartPressed` の Pro auto-skip 撤去)。タイトル/バッジを tier-aware に
    (Pro 時は「Pro 週次クレジット 残り X / 100 回 (毎週月曜日に補充・Pro 加入中)」)。
  - **結果画面 paywall** (`consultation_result_credit_widgets.dart` `_ConsultationBlockedBox`):
    `proWeeklyExhausted` variant 追加 (「今週の Pro 相談上限に達しました。月曜リセット or 追加
    クレジット購入」)。「Cosmic Pro で無制限にする」サブボタンは Pro 切れには出さない (既に Pro)。

#### 検証
- worker test 全 **243/243 pass** (+5 net、Pro 99→100 ぎりぎり / 100→購入フォールバック / 100+0→402 /
  env 上書き / Android appUserId 経由 deviceKey)。
- flutter test 全 **238/238 pass** (1件は事前既知の `widget_test.dart` Timer pending、本変更と無関係)。
  新規 `consultation_v2_api_test.dart`: `proWeeklyExhausted` マップ + Pro 200 解析。
  `consultation_credits_test.dart`: `hasAny` を Pro 週次 0 + 購入 0 で false など 4 ケースに再構成。
- flutter analyze クリーン (既存 2 件の `app_attest_client_android_test.dart` 警告は事前)。
- extract.py 再生成: stamp diff +0 -0 ~8 (新規ファイル無し、既存改修のみ)。
  audit.py: 新規 HARD 違反なし (`sanctuary_screen.dart` は 1459→1435 でむしろ -24、
  `consultation_v2_api.dart` 373→388 で WARN 内)。

### 0.2.4 課金堅牢化 5 ステップ + 監査対応 7 項目 (2026-05-27 夜セッション)

> **設計の柱**: Pro 同期遅延の窓 (RC Webhook 遅延 / sandbox 圧縮 renewal / 解約直後 / ネットワーク断後) で
> 購入クレジットが誤消費されるバグを潰す + RC/Apple/Google の最新公式ガイダンスへの完全準拠。
> 詳細設計と他アプリ流用は `docs/iap_auth_revenuecat_patterns.md` (top-level)、Solara 固有実装は
> `apps/solara/docs/revenuecat_webhook.md` v2.3。

#### 課金堅牢化 5 ステップ (購入クレジット誤消費の防止)

| Step | 内容 | 主な変更ファイル |
|---|---|---|
| 1 | クライアント entitlement snapshot を `/protected/*` body に注入 (`__clientEntitlement: {isPro, verification, expiresAtMs, productId}`) | `purchases_service.dart clientEntitlementSnapshot` + `app_attest_client.dart withAppUserIdMerged` 拡張 |
| 2 | Worker `gateConsultation` / `consumeReadingCreditGate` / `consultationCreditStatus` に `proSyncReconcile` 経由を組込 | `index.js` |
| 3 | RC REST `/v1/subscribers/{id}` で source-of-truth 再検証 (30s memcache) + `DELETE` も併設 | 新規 `worker/src/auth/rc_rest.js` |
| 4 | DO スキーマに `grace_expires_at` 追加 + Webhook BILLING_ISSUE で `grace_period_expiration_at_ms` を保存 + `_entitlementGet` で `MAX(expires_at, grace_expires_at)` 判定 | `attestation_state.js` migration + `webhooks/revenuecat.js` |
| 5 | DO `last_event_timestamp_ms` 追加 + Webhook `event_timestamp_ms` で厳密 out-of-order 判定 (legacy: 受信時刻 fallback) | `attestation_state.js _entitlementUpsert` |

#### 監査対応 7 項目

| # | 対応 | 主な変更ファイル |
|---|---|---|
| #1 | RC `DELETE /v1/subscribers/{id}` (GDPR Right to Erasure) | `rc_rest.js deleteSubscriberViaRC` + `index.js handleAccountDelete` 4 段階化 |
| #2 | Webhook TRANSFER で `transferred_from/to` 配列を見て旧/新 owner 判定 | `webhooks/revenuecat.js` |
| #3 | `SUBSCRIPTION_EXTENDED` を `ACTIVE_EVENT_TYPES` に追加 | `webhooks/revenuecat.js` |
| #4 | paywall 自動更新文言を Apple 3.1.2(a) 必須 3 項目準拠に書換 (「払い戻し不可」削除 = 3.1.1 違反回避) | `paywall_widgets.dart _buildAutoRenewNotice` |
| #5 | App Attest / Play Integrity の enforced 化リマインダー (2026-05-29 頃判断) | `MEMORY.md` |
| #6 | 未知 webhook event を IGNORE 倒し (旧: isActive=false で upsert → 誤失効事故あり) | `webhooks/revenuecat.js` |
| #7 | Apple Sign In Token Revocation (`auth/revoke`) — ES256 client_secret JWT + Flutter で fresh authorizationCode 再取得 | 新規 `worker/src/auth/apple_revoke.js` + `solara_auth.dart _getFreshAppleAuthorizationCode` |

#### Pro 購入直後の自己治癒 (副次効果)

`main.dart` に `ProStatus.instance.addListener` を新規配線し、Pro 状態変化時に `ConsultationCredits.refresh()` を自動発火。
Worker 側 `consultationCreditStatus` も `proSyncReconcile` 経由になったため、Pro 購入直後 (RC Webhook 着信前) でも:
1. クライアント RC SDK は即時 Pro 認識 (ProStatus listener)
2. ConsultationCredits.refresh() が `__clientEntitlement` 付きで /protected/consultation/credits を叩く
3. Worker reconcile が RC REST で再確認 → memory cache 修復 + Pro 経路で `proRemaining=100, proLimit=100` を返す
4. Sanctuary 残数表示が「Pro 残 100/100」に即時更新 (~1 秒)

旧バグ「Pro 購入直後 0/0 表示」は **3 層防御 (server reconcile + client trigger + UI defense「Pro 残 確認中」表示)** で完全に塞がれた。

#### 実装の所在 (層別)

- DO (層 0): `attestation_state.js`
  - `user_entitlements` に `grace_expires_at` + `last_event_timestamp_ms` 列を migration で追加 (try/catch で冪等)
  - `_entitlementGet` を `MAX(expires_at, grace_expires_at)` 判定に変更
  - `_entitlementUpsert` を `event_timestamp_ms` 優先 + 受信時刻 fallback の out-of-order 判定に強化
- Worker (層 0): `index.js`
  - 新 helper `consultationClientEntitlement(body)` / `proSyncReconcile(env, appUserId, body, origin)`
  - `gateConsultation` / `consumeReadingCreditGate` / `consultationCreditStatus` 3 ヶ所から `proSyncReconcile` 経由
  - `handleAccountDelete` を 4 段階削除 (DO + memory + RC + Apple revoke、後 3 段は best-effort)
  - `jsonStatus(status, payload, origin, extraHeaders?)` で `Retry-After: 30` 等を載せられるよう拡張
- Worker (層 0): 新規 `auth/rc_rest.js`
  - `reverifyEntitlementViaRC` (GET subscribers + grace 込み effective expiry 計算 + 30s memcache)
  - `deleteSubscriberViaRC` (DELETE subscribers + reverify cache invalidate)
- Worker (層 0): 新規 `auth/apple_revoke.js`
  - `buildAppleClientSecret` (ES256 + P-256 で client_secret JWT 生成、WebCrypto API のみ使用)
  - `revokeAppleToken` (POST `https://appleid.apple.com/auth/revoke`、鍵未設定なら `secrets_missing` で no-op)
- Worker (層 0): `webhooks/revenuecat.js`
  - `ACTIVE_EVENT_TYPES` に `SUBSCRIPTION_EXTENDED` 追加
  - TRANSFER 判定を `transferred_from/to` 配列ベースに書換
  - 未知 event 種別を「副作用なし 200 ignored 返却」に倒す (DO は touch しない)
  - `grace_period_expiration_at_ms` / `event_timestamp_ms` を `_entitlementUpsert` に passthrough
- Flutter API (層 2a):
  - `purchases_service.dart` に `_lastCustomerInfo` + `clientEntitlementSnapshot` getter (Trusted Entitlements verification 込み)
  - `app_attest_client.dart` の `_withAppUserId` を `__clientEntitlement` も merge するよう拡張
  - `consultation_api.dart` に `ConsultationBlock.proSyncPending` + `consultationBlockFromCode` で `pro_sync_pending` マップ
  - `consultation_v2_api.dart` で 425 ステータスを block として扱う
  - `solara_auth.dart` `deleteAccount` で provider==apple なら `getAppleIDCredential` を再起動 → fresh authorizationCode を Worker に渡す
- Flutter 画面 (層 4):
  - `main.dart` に `ProStatus.instance.addListener` 新規配線 → `ConsultationCredits.refresh()` 自動発火
  - `sanctuary_screen.dart _buildCreditRow` で proRemaining/proLimit 両 null 時に「Pro 残 確認中」表示
  - `consultation_result_credit_widgets.dart _ConsultationBlockedBox` に `proSyncPending` ケース追加 (購入/Pro 誘導なし、「Pro 状態を同期しています」)
  - `consultation_credit_sheet.dart _pollUntilGranted` の polling 間隔を 1500ms → 500ms に短縮 (購入後シート閉じる体感 ~0.5 秒)
  - `paywall_widgets.dart _buildAutoRenewNotice` を Apple 3.1.2(a) 準拠文言に書換 (「払い戻し不可」削除)
  - `sanctuary_account_section.dart` 削除確認 dialog に Apple 再認証告知を追加

#### env / secret 追加 (本セッションで)

| 種別 | キー | 用途 | 設定方法 |
|---|---|---|---|
| Secret | `REVENUECAT_SECRET_KEY` | RC REST API (reverify + DELETE) | 本セッションで `wrangler secret put` 済 |
| Secret | `APPLE_SIWA_PRIVATE_KEY` | Apple Token Revocation の P8 鍵 | 後日 (鍵未設定なら no-op skip) |
| Public env | `APPLE_SIWA_SERVICE_ID` | Apple Sign In Service ID | 後日 (wrangler.toml) |
| Public env | `APPLE_SIWA_KEY_ID` | Apple Authentication Key ID (10 桁) | 後日 (wrangler.toml) |

詳細手順は メモリ `project_solara_apple_siwa_revoke_setup.md` 参照。

#### 検証
- worker test **295/295 pass** (+19 net: pro_sync_pending +29 / revenuecat_webhook +5 / apple_revoke +7、回帰なし)
- flutter test **243/244 pass** (1 件は事前既知 `widget_test.dart: Solara app launches`、本変更と無関係)
- flutter analyze クリーン (既存 2 件の `app_attest_client_android_test.dart` 警告は事前)
- audit.py: 新規 HARD 違反なし。本セッション変更ファイル:
  - sanctuary_screen.dart 1441 (既存 HARD、+6 行)
  - solara_auth.dart 459 (WARN、+27 行で Apple authorizationCode 再取得追加)
  - paywall_widgets.dart 451 (WARN、文言書換のみ実質変化なし)
  - purchases_service.dart 308 (WARN、+46 行で clientEntitlementSnapshot 追加)
  - app_attest_client.dart 476 (WARN、+13 行で __clientEntitlement merge)
  - consultation_credit_sheet.dart 348 (WARN、polling 値変更のみ)
  - 新規ファイル 3 個: `worker/src/auth/rc_rest.js` / `worker/src/auth/apple_revoke.js` / `lib/utils/consultation_api.dart proSyncPending enum` (既存ファイルへの追加)
- 重複コード: 装飾ボイラープレートのみ、ロジック重複 0。未使用 private 0。

### 0.2.5 Apple/Google 審査対応 G1-G11 完了 + 出荷ドラフト集約 (2026-05-28 セッション)

> **設計の柱**: 公開前のリジェクト/警告リスク削減。Apple 2025-11-13 改定 (5.1.2(i) 第三者 AI 明示同意) +
> Google 2026-04-15 Gen AI policy 施行 (in-app reporting 必須) + Privacy Manifest 必須 + 占い系 4.3(b)
> Spam 対策の最新要件に先回りで完全準拠 + 出荷ドラフト 6 件を `docs/store_compliance_assets/` に集約。
> 詳細: `docs/store_compliance.md` (正典) + `docs/store_compliance_assets/README.md` (作業ガイド)。

#### コード変更 (G1-G3、新規 widget/screen 4 個)

| Gap | 内容 | 主な変更ファイル |
|---|---|---|
| G1 | `AiConsentScreen` (Apple 5.1.2(i)): 初回起動時 Gemini 送信同意モーダル。SolaraStorage に永続化 (`_aiConsentAtKey`) | 新規 `lib/screens/ai_consent_screen.dart` + `solara_storage.dart {load,save,has}AiConsentAt/Now` + `main.dart SolaraApp` StatefulWidget 化 |
| G2 | `AiReportButton` (Google Gen AI Policy 2026-04-15): Tarot/Horo/Stella 全結果画面に「不適切な内容を報告」+ 7 理由 + 自由記述 BottomSheet | 新規 `lib/widgets/ai_report_button.dart` + 新規 `lib/utils/ai_report_api.dart` (`AiReportApi.reportAiOutput`) + Worker 新規 `src/ai_report.js` (`handleAiReport`) + `src/index.js` routing |
| G3 | `AiDisclaimerFooter` (Apple 4.0 + Google Misleading): 全 AI 結果画面常時 footer「✦ AI 生成・娯楽目的」 | 新規 `lib/widgets/ai_disclaimer_footer.dart` |

#### 他コード変更 (本セッションで併発)

| Gap | 内容 |
|---|---|
| OSM Attribution | `lib/screens/map/map_styles.dart` に `buildOsmAttribution()` + `buildOsmAttributionCompact()` ヘルパー、3 画面 (Map / consultation_place_picker / location_picker_minimap) に挿入 (OSM ODbL 必須要件) |
| Stella V2 + Horo prompt safety guard | `worker/src/consultation_v2.js` rule #11 + `worker/src/fortune.js` ja/en 両方に medical/legal/financial/investment/self-harm 断定禁止 + 「必ず/絶対」禁止追加 (Tarot と対称化) |
| iOS Info.plist 整理 | `ios/Runner/Info.plist` から不要な `NSLocationAlwaysAndWhenInUseUsageDescription` 削除 (Background 未使用)、`WhenInUse` 文言を具体化 |

#### ドキュメント集約 (G4 / G6 / G7 / G9 / G11 / G8 / G10)

| Gap | 成果物 |
|---|---|
| G4 | `legal/solara/delete-account.html` (本番配信、solodev-lab.com に GitHub Pages 経由 deploy 済) + `lib/utils/legal_urls.dart accountDeletion` 定数 |
| G6+G7 | `docs/store_compliance_assets/apple_app_store_connect.md` (Apple Console コピペシート、§A-G の全画面 + URL/遷移 明記) + `google_play_console.md` (Play Console コピペシート、§A-F) |
| G9 | `docs/store_compliance_assets/age_rating_questionnaire.md` (4+ 正解版に全面書き直し。subagent 誤情報の Fortune Telling / AI Unpredictability 項目を削除、Apple 新質問票には実在しないことを公式確認済) |
| G11 | `docs/store_compliance_assets/data_safety_form.md` (Google Data Safety form 全項目別推奨回答) |
| G8+G10 | `docs/store_compliance_assets/sdk_audit.md` (Privacy Manifest + 16 KB page size 監査手順、`flutter pub upgrade` + Xcode Validate App + apkanalyzer) |
| G5 | 確認のみ (`sanctuary_account_section.dart` L58 + `paywall_screen.dart` L89 で Platform 分岐済、コード変更不要) |

#### Apple SIWA Token Revocation 本稼働 (本セッション最初に並行実施)

- Apple Developer Console で Service ID `com.solodevlab.solara.signin` + Authentication Key `D8BGKZW2AJ` 発行
- `wrangler.toml` に `APPLE_SIWA_SERVICE_ID` + `APPLE_SIWA_KEY_ID` 追記
- `wrangler secret put APPLE_SIWA_PRIVATE_KEY` で `.p8` を Cloudflare Workers secret 登録
- Worker version `2957ebc6` で deploy 済、`apple_revoke.js` が `secrets_missing` skip から **本稼働へ遷移**
- `.p8` 保管: `C:\Users\cojif\OneDrive\ドキュメント\Solaraファイル\App Store Connect API\AuthKey_D8BGKZW2AJ.p8` (OneDrive 同期でクラウドバックアップ)

#### AAB v+13 ビルド

- `apps/solara/build/app/outputs/bundle/release/app-release.aab` (111.3 MB、2026-05-28 01:22)
- versionCode 12 → 13、`build_release.py` で全 dart-define (`SOLARA_GCP_PROJECT_NUMBER` / `SOLARA_RC_ANDROID_KEY` / `SOLARA_GOOGLE_SERVER_CLIENT_ID`) 自動注入
- G1-G3 + OSM Attribution + safety guard + Info.plist 整理 全部反映
- シンボル: `apps/solara/build/symbols/aab/1.0.0+13/` (arm/arm64/x64、約 13 MB)

#### App Store Connect Age Rating = 4+ 確定 (2026-05-28 オーナー Console 操作)

オーナーが Apple Console で新質問票 (2025-07 改訂、2026-01-31 期限) 7 ステップ全て「なし / いいえ」回答
→ **算出 4+ で 173 国・地域に適用**。同類占星術/タロットアプリ (Co-Star / CHANI / Tarot Card Reading)
も 4+ で運用中で実例多数あり。`age_rating_questionnaire.md` 旧版の §1.8/§1.11 が subagent 推測の
誤情報 (Apple 新質問票に「Fortune Telling」「AI 予測不可能性」専用項目は存在しない) と公式確認済。

#### 検証
- flutter analyze: クリーン (既存 2 件のみ、新規 issue ゼロ)
- worker test **53/53 pass** (fortune / consultation_v2 / integrity_endpoints、`ai_report` 追加で破綻なし)
- audit.py 再生成: **189 .dart files** (新規 4 件 = `ai_consent_screen` / `ai_report_api` / `ai_report_button` / `ai_disclaimer_footer`)。新規 HARD 違反ゼロ (`ai_report_button.dart` のみ 307 行で WARN、許容範囲)。
- 重複コード: Flutter 装飾構文 ( `),` / `],` / `style: TextStyle(` 等) のみ、ロジック重複 0。未使用 private 0。TODO/print 残置は既存のみで新規追加なし。
- coverage_report.md 再生成: 新規クラス `AiConsentScreen` / `AiDisclaimerFooter` / `AiReportApi` / `AiReportButton` が #1 漏れリストに上がっていたが、本節への記載で解消。

#### 残オーナー手作業 (次セッション以降)

1. **Play Console 内部テスト** に AAB v+13 アップロード → リリースノート: 「v1.0.0 — はじめての公開バージョン...」
2. **A101FC 実機検証**: G1 同意モーダル (初回起動) + G2 報告ボタン (Stella/Tarot/Horo 各結果末尾) + G3 disclaimer footer (同じく) + 既存 MEMORY 7 項目 (Pro 残数 / Stella 12 連発 / 削除 / 購入後シート 0.5 秒 等)
3. **App Store Connect 入力**: `apple_app_store_connect.md` の §D (説明文 / キーワード / スクショ) + §E (Reviewer 情報) + §F (TestFlight)
4. **Play Console 入力**: `google_play_console.md` の §A (説明文) + §C-6 (データセーフティ) + §C-7 (アカウント削除 URL = `https://solodev-lab.com/legal/solara/delete-account.html`)
5. **スクショ撮影 (6 枚)**: 推奨内容は `apple_app_store_connect.md` §D-7 (Sanctuary / Horo / Map / Tarot / Stella / Galaxy)
6. **SDK 監査**: `sdk_audit.md` §2 (`flutter pub upgrade` + Xcode Validate App + apkanalyzer で .so の 16 KB alignment 確認)
7. **iOS Codemagic ビルド**: codemagic.yaml の `submit_to_testflight: true` で TestFlight 自動アップロード
8. **クローズドテスト 12×14** (オーナーが個人 Play Console アカウントの場合のみ、法人なら不要)

### 0.2.6 AiConsentScreen 6 章構造化 + 背景画像追加 (2026-05-28 セッション後半)

> §0.2.5 で実装した G1 (AiConsentScreen) を、オーナーと審査要件の章立てを照合しながら
> 6 章構造へ再整理。開発者からのユーザー向け挨拶 (§0「はじめに」) + 4 つの審査目的 (§1-§4) +
> 同意 UX 運用 (§5) を分離。プライバシーポリシー/利用規約への直リンク追加 + 背景画像
> (Gemini 3.1 Flash 生成) + 「同意しない」モーダル文言更新 + AAB v+14 ビルド。

#### 章構造の再設計

| § | タイトル | 役割 | 審査要件 |
|---|---|---|---|
| §0 | はじめに | 開発者からのユーザー向け挨拶、エビデンスベース設計の宣言、占い師としての関わり | (Apple 4.3(b) Spam 対策の競合差別化) |
| §1 | 本アプリは娯楽・自己探求を目的としています | 機能列挙 (5 機能) + 専門助言否定 + 将来予測否定 | Apple 4.3(b) Spam + 1.4.1 Medical |
| §2 | 第三者へのデータ送信について | Apple/Google (デバイス認証) + Gemini AI (占い解釈) + RC (課金) の 3 サービスを並列開示 | Apple 5.1.2(i) |
| §3 | Gemini AI が生成するコンテンツについて | タロット/Stella/星読み/リロケーション の AI 利用機能を列挙 | Google Gen AI Policy |
| §4 | 重要な意思決定について | 「参考情報」+ 不正確性警告 + 自己責任 + プライバシー/規約リンク | 占い系特有のリスク回避 |
| §5 | 同意の取扱いについて | 同意して始める/同意しない 各々の動作、アンインストール案内 | (運用) |

#### コード変更

- `lib/screens/ai_consent_screen.dart` 全面書き換え (191 → 353 行、StatelessWidget 維持):
  - 6 章構造の `_Section` ヘルパー新設 (旧 `_ParagraphSection` を置換、`footer` Widget 引数追加)
  - `_LegalLinks` / `_LinkPill` 新設 ([LegalUrls](../lib/utils/legal_urls.dart).privacyPolicy/.termsOfService への外部ブラウザリンク)
  - `_handleDecline` モーダル文言更新 (Gemini AI 特定削除 → 汎用化、§5 と整合)
  - 背景画像 `assets/onboarding-bg/ai_consent.webp` を `Stack + Image.asset` で表示、半透明 overlay で文字読みやすさ確保
- `assets/onboarding-bg/ai_consent.webp` 新規 (288 KB、768×1376、Gemini 3.1 Flash 生成、forging.webp に寄せた歓迎演出)
- `pubspec.yaml` に `assets/onboarding-bg/` 追加 + version `1.0.0+13` → `1.0.0+14`

#### 背景画像生成

- `mockup/generate_ai_consent_bg.py` 新規 (3 案バッチ生成スクリプト、`generate_backgrounds_mystical.py` パターン流用)
- `mockup/ai_consent_bg_drafts/` に P1-P3 PNG 3 案保管 (元絵保護ルール、削除しない)
- 採用: **P1** (大銀河 + 中央光輝核 + 上部太陽月12星座アーチ + 下部金薔薇枠、forging.webp との統一感)

#### AAB v+14 ビルド

- `apps/solara/build/app/outputs/bundle/release/app-release.aab` (111.6 MB、2026-05-28 14:57)
- versionCode 13 → 14、`build_release.py aab --release-mode` で全 dart-define 自動注入
- AiConsent 改修 + 背景画像追加 反映
- シンボル: `build/symbols/aab/1.0.0+14/` (arm/arm64/x64)

#### 検証

- flutter analyze: **No issues found** (23.5s)
- extract.py 再生成: stamp diff `+0 -0 ~1` (`ai_consent_screen.dart` のみ更新)
- audit.py 再生成: 行数違反 77 / 重複 20 / TODO 4 / print 1 / 未使用 0。**新規 HARD ゼロ** (`ai_consent_screen.dart` 353 行は WARN 範囲、許容)。

### 0.2.7 AiConsent alpha 調整 + Sanctuary 解約リンク + 法務 HTML 5 ファイル AiConsent 6 章整合 (2026-05-28 セッション末)

> §0.2.6 の AiConsent 6 章構造を、オーナーと表現を 1 つずつ照合しながらブラッシュアップ + 法務 HTML
> 5 ファイル (privacy / terms / scta-ios / scta-android / cancel) との文言整合 + Sanctuary 解約導線 UX 改善。
> AAB ビルドは保留 (オーナー指示)。

#### コード変更

- `lib/screens/ai_consent_screen.dart`: 背景画像オーバーレイ alpha **0.55 → 0.70** (文字読みやすさ強化、背景控えめ化)
- `lib/screens/sanctuary_screen.dart` `_buildProActiveBanner()`:
  - 「更新と解約は端末のサブスクリプション設定から。」説明文を削除
  - 新規「↗ 解約方法」リンクボタン (InkWell + Icon.open_in_new) を追加
  - タップで `openSubscriptionSettings(context)` を呼出 (端末の定期購入画面に直接遷移)
- `lib/screens/sanctuary/sanctuary_legal_menu.dart`:
  - 新規 public `openSubscriptionSettings(BuildContext)` 関数追加
  - iOS = `LegalUrls.iosSubscriptionsDeepLink` (設定アプリ → Apple ID → サブスク)
  - Android = `LegalUrls.androidSubscriptionsDeepLink` (Play Store → 定期購入)
  - その他 = `LegalUrls.howToCancel` (Web)
  - 既存 `_openCancelGuide()` も同関数を内部呼出に置換 (重複解消)
- `pubspec.yaml`: version `1.0.0+14 → +15` (alpha 修正用、Sanctuary 修正は次回ビルドで +16 へ)

#### 法務 HTML 5 ファイル AiConsent 6 章整合

| ファイル | 修正内容 |
|---|---|
| `legal/solara/privacy.html` | A: 冒頭「アプリの位置づけ」段落追加 / B: §1-1 機能列挙を AiConsent §1 と同じ 5 区分化 / C: §3-2 デバイス認証情報 (App Attest / Play Integrity) を先頭に追加 + §4 第三者リスト Apple Inc. / Google LLC に App Attest / Play Integrity 明記 / D: §7 免責を「娯楽・自己探求」「参考情報」表現に整合 / E: 「Stella の「相談」機能」→「Stella 相談」表記統一 |
| `legal/solara/terms.html` | A: 冒頭追加 / B: 第 3 条 3-1 Pro 提供内容を Pro 週次キャップ 100/週 + タロット Pro 特典 (カテゴリクレジット不要+テキスト入力欄) + 星読み 5 カテゴリ (Free は「全体」のみ) に正確化 / C: 第 4 条 (1)(2) 免責を 4→5 項目化 (「参考情報」「鵜呑みにせず」追加) / D: 第 8 条「Stella による解釈テキスト」→「Stella 相談による解釈」3 箇所統一 |
| `legal/solara/scta-ios.html` | 免責事項 (1 箇所) を terms 第 4 条と整合 (「娯楽および自己探求のためのコンテンツ」+「将来予測ではない」追加) |
| `legal/solara/scta-android.html` | 同上 (Android 版、内容は scta-ios と統一) |
| `legal/solara/cancel.html` | 変更なし (AiConsent 6 章との接点が薄い、解約手順のみ) |

#### 検証

- flutter analyze: **No issues found** (45.1s、ai_consent / sanctuary / sanctuary_legal_menu 3 ファイル)
- extract.py 再生成: stamp diff `+0 -0 ~3` (`ai_consent_screen.dart` / `sanctuary_screen.dart` / `sanctuary_legal_menu.dart`)
- audit.py 再生成: 行数違反 77 / 重複 20 / TODO 4 / print 1 / 未使用 0。前回と同じ統計 = 新規 HARD/重複追加ゼロ。

#### iPhone / Android 解約 deep link 動作

- A101FC (Android): Sanctuary > Cosmic Pro 加入中バナー > 解約方法 → Play Store の定期購入画面に直接遷移 (実機確認済)
- iPhone (iOS): 同じ URL (`https://apps.apple.com/account/subscriptions`) で「設定アプリ → Apple ID → サブスクリプション」に自動遷移 (Apple 公式 deep link 仕様、TestFlight で実機確認予定)

### 0.2.8 PaywallScreen Suno 風リデザイン (2026-05-28 セッション、§0.2.7 同日)

> オーナーが提示した Suno のサブスク管理画面 (スクショ 3 枚) を参考に、Cosmic Pro ペイウォールの UX を全面刷新。
> 「Free と Pro の違いが一目で分かる」「購入の決め手になる」を狙う。
> **Apple 3.1.2 + B5 必須項目は完全温存** (`feedback_legal_text_no_unilateral_changes`)。
> 設計詳細: memory `project_solara_paywall_suno_redesign.md`

#### 画面構成 (上から下)

1. AppBar (`✦ Cosmic Pro`)
2. Hero (Cosmic Pro タイトル + 一文紹介、温存)
3. **Monthly / Annual トグル** (SAVE 50% バッジ、初期選択 Annual)
4. **Free カード** (機能 5 項目 + 「現在のプラン」バッジ、非 Pro 時のみ)
5. **Pro カード** (ハイライト枠、選択中 billing の価格 + 月換算 + 7 日トライアル明記 + 機能 6 項目 + CTA)
6. **比較テーブル** (Free vs Pro、3 セクション = 相談・占い / 地図機能 / 記録、合計 7 行)
7. **FAQ アコーディオン** (5 問、ExpansionTile)
8. **自動更新明記** (🛡 Apple 3.1.2(a) 文言、温存)
9. **法的リンク 4 種** (🛡 解約 / 利用規約 / プライバシー / 特商法、温存)
10. **購入を復元** (🛡 温存)

#### ファイル分割 (HARD 500 行回避)

旧: `paywall_screen.dart` 295 + `paywall_widgets.dart` 451 = 計 746 行 / 2 ファイル
新: 4 ファイル構成 (全 WARN 範囲、新規 HARD ゼロ)

| ファイル | 行 | 役割 |
|---|---|---|
| `paywall_screen.dart` | 313 (WARN) | State + Offerings 取得 + サインイン強制 + 購入 / 復元 / 解約 deep link + `BillingCycle` enum + `_setBilling` ラッパー |
| `paywall_widgets.dart` | 413 (WARN) | Hero + トグル + Free/Pro 2 カード + 機能 bullet (Suno 風 core) |
| `paywall_comparison.dart` | 267 (新規) | 比較テーブル + FAQ アコーディオン |
| `paywall_legal_links.dart` | 197 (新規) | 🛡 法務必須 3 ウィジェット + 補助 (ストア準備中 / エラーパネル / 期間ラベル) |

#### 技術メモ

- `extension _PaywallWidgets on _PaywallScreenState` から `setState` を直接呼ぶと `invalid_use_of_protected_member` 警告。`_setBilling(BillingCycle)` ラッパーを State 内に置いて回避。
- Pro カード CTA は ProStatus.isPro で分岐: 未加入 → `FilledButton`「年額/月額プランを始める」/ 加入中 → `OutlinedButton`「定期購入を管理」(= `_openCancelGuide` 再利用)。
- 年額選択時の月換算ヒントは `product.price / 12` を端数丸めで「月あたり ¥750 相当」と表示 (i18n は後回し)。
- 法務 HTML (`legal/solara/terms.html` 第 3 条 3-1 = §0.2.7 で整合済) と Pro 機能リストは一致 (Stella 100/週 / タロット特典 / 星読み 5 カテゴリ / アスペクト 120 本 / ACG 全機能 / 記録検索)。
- FAQ 5 問は memory `project_solara_paywall_suno_redesign` ドラフトに準拠。Suno 固有の「モデル違い」は Solara に存在しないため「Free vs Pro 違い」に置き換え。

#### 機械分類の盲点

- `BillingCycle` enum は `paywall_screen.dart` トップレベル定義。`05_main` に分類されるが実質はペイウォール状態。`PATH_OVERRIDES` で `04f_subscreens` に明示分類予定 (次回 extract メンテで対応)。
- 4 ファイル間で `part of` 連鎖。`feature_inventory/04f_subscreens.md` 機械抽出では `paywall_comparison.dart` / `paywall_legal_links.dart` も同じ scope。

#### 検証

- `flutter analyze` (4 ファイル + 全体): **No issues found** (lib/ 側新規 issue ゼロ、test 側既存 issue 2 件は変動なし)
- `extract.py` 再生成: stamp diff `+1 -0 ~2` (paywall_comparison.dart 新規 + paywall_screen.dart / paywall_widgets.dart 更新、その後 `+0 -0 ~2` で同期完了)
- `audit.py`: 行数違反 78 / 重複 20 / TODO 4 / print 1 / 未使用 0。前回 §0.2.7 末の 77 から +1 (= paywall_screen.dart が 295 OK → 313 WARN に昇格)。**新規 HARD ゼロ達成**。
- paywall_widgets.dart は 537 → 413 行で HARD 退避 (`_buildStoreUnavailable` / `_buildErrorPanel` / `_periodLabel` / `_introPeriodLabel` を paywall_legal_links.dart に移動)。
- AAB v+16 ビルドは保留 (オーナー指示、本セッションはコード実装まで)。次セッションで alpha 0.70 + Sanctuary 解約リンク + Suno リデザインを反映した v+16 を一括ビルド。

### 0.2.9 Pro 再契約時の Pro 週次クレジット 100 リセット (2026-05-29 セッション)

> 実機 (A101FC) で「同一週に Pro 解約 → 再契約」した結果、Pro 残数が解約前 (84/100) のまま継続する事象をオーナーが発見。
> 「新しく支払いを行ったのだから残数は 100 にして」(オーナー指示 2026-05-29) を仕様化。
> 実ユーザーで起きる頻度は低いが、新規 IAP 取引のたびに残数を 100 から始めるのが直感的。

#### コード変更

- `worker/src/auth/attestation_state.js`:
  - `consultation_pro_credits` テーブルに `app_user_id TEXT` 列追加 + index (try/catch migration、既存行は NULL のまま残るが月曜リセットで自然解消)
  - `_consultationProCreditBump` に `appUserId` 引数追加 (オプショナル、`COALESCE(?, app_user_id)` で既存値を保護)
  - **新規 `_consultationProCreditResetAll({ appUserId })`**: `DELETE FROM consultation_pro_credits WHERE app_user_id = ?` で同一ユーザの全 device_key 行を消す → 次回 get は used=0 = 残 100
  - DO dispatch に `/consultation-pro-credit-reset-all` 追加
- `worker/src/index.js`:
  - `consumeReadingCredit` の pro_weekly bump 呼出で `gate.appUserId` を渡す
  - `consultationCreditsGate` の pro_weekly allow 戻り値に `appUserId` を含める
- `worker/src/webhooks/revenuecat.js`:
  - INITIAL_PURCHASE 受信 + entitlement-upsert 成功 + alreadyProcessed=false + skippedOutOfOrder=false の AND 条件で `/consultation-pro-credit-reset-all` を best-effort 呼出
  - 失敗時も webhook は 200 維持 (RC リトライ不要、月曜リセットで自然解消の二段構え)
  - response body に `proCreditReset: {ok, deleted}` を追加 (CF Logs で観察可)
- `worker/test/revenuecat_webhook.test.js`:
  - 既存 2 件修正: `calls.length === 1` → `=== 2` (entitlement-upsert + reset-all)
  - **新規 5 件追加**:
    - `INITIAL_PURCHASE で reset-all を呼ぶ (新規 IAP 取引)` — 呼出 + appUserId + deleted カウント検証
    - `RENEWAL では reset-all を呼ばない (継続契約)`
    - `PRODUCT_CHANGE (月額↔年額切替) では reset-all を呼ばない`
    - `INITIAL_PURCHASE + skippedOutOfOrder=true なら reset-all をスキップ`
    - `reset-all 失敗でも webhook は 200 (best-effort)`

#### 設計判断 (オーナー決定)

| 項目 | 決定 | 根拠 |
|---|---|---|
| リセットトリガー | **INITIAL_PURCHASE のみ** | 「新規 IAP 取引 = 新たな支払い」が要望と最も整合。RENEWAL/UNCANCELLATION/PRODUCT_CHANGE は継続なのでリセット不要 |
| 購入クレジット (`consultation_purchased`) | **そのまま残す** | 「失効なし」規約 (`legal/solara/terms.html`) を維持。リセットすると法務リスク |
| 既存行 (migration 前の app_user_id=NULL) | **対象外** | 月曜リセットで自然解消、強制 backfill しない (副作用回避) |
| 冪等性 | **alreadyProcessed / skippedOutOfOrder ならスキップ** | RC が同 event_id 再送 / 古い event を新しい状態に上書きしない |
| 失敗時の挙動 | **webhook 200 best-effort** | RC のリトライで重複リセットが起きないように。次の月曜リセットで自然解消 |

#### 検証

- worker テスト: **300 件全 pass** (前回 295 + 新規 5)
- flutter analyze: No issues (lib/ 側無傷)
- extract.py: stamp diff `+0 -0 ~5` (Flutter 側 paywall + popup 5 ファイル追従)
- audit.py: 78 / 20 / 4 / 1 / 0 (前回と同じ、新規 HARD ゼロ)
- 実機検証は次セッション (AAB v+16 + Worker deploy 後): 「実機で Pro 解約 → 再契約 → Sanctuary バナーが Pro 残 100 / 100 になる」

#### 未実施 (次セッション)

- Worker deploy (`cd apps/solara/worker && npx wrangler deploy`)
- AAB v+16 ビルド (alpha 0.70 + Sanctuary 解約リンク + Suno リデザイン + 本変更を一括反映)
- A101FC 実機で「同一週に Pro 解約 → 再契約 → 100/100 表示」確認

### 0.2.10 Forecast 永久キャッシュ + Worker CPU 上限引き上げ (2026-05-29 セッション)

> CF Logs 分析中に発見: 2026-05-28 20:01:20 に `/public/astro/forecast` で **`outcome=exceededCpu` (status=503)** が 1 件発生。
> オーナーが「Forecast 画面で今年・来年・再来年と連続切替」した時の挙動と一致。
> 解析した結果、デフォルト Workers CPU time per invocation (1000ms) を forecast 1 回の計算が踏み越えうると判明。

#### 原因
- `astro.js computeForecast`: 1 リクエストで 365 日分 × `scoreOneDate` (= transit × natal アスペクト計算) を実行
- 実測 CPU: 同セッションで 3 回連続実行時に **328ms → 1017ms (503) → 924ms** と推移
- 出生情報を元に決定論的 (= 同じ出生 + 同じ暦年 = 同じ結果)、ただし初回 fetch は重い

#### 設計判断 (オーナー決定 2026-05-29)
1. **forecast キャッシュは「永久キャッシュ」に変更**:
   - v1 (旧): 今日起点ローリング 1 年 → 6h cooldown 必要
   - v2 (現行): 暦年 1/1〜12/31 ベース → 結果は完全に決定論的、再 fetch 不要
   - 出生情報変更 → profileHash 変動 → 自動的に新規 fetch (旧キャッシュは参照されないだけで残置害なし)
   - 「force=true (UI からの強制リフレッシュ)」のときだけ再 fetch
2. **CPU 上限引き上げ**: 永久キャッシュでも初回 fetch 1 回は走るので、`wrangler.toml [limits] cpu_ms = 30000` で Workers Standard プランの最大 30 秒に。追加課金なし。

#### コード変更
- `worker/wrangler.toml`:
  - `[limits]` セクション新規追加 (`cpu_ms = 30000`)
- `lib/utils/forecast_cache.dart`:
  - `ForecastRepo.fetchFull()` 内の cooldown 判定を撤廃: `cooldownRemaining > 0` なら cached を返すロジック → `cached != null` なら常に返すロジックに
  - `_cooldownHours = 6` 定数 / `cooldownRemaining()` / `_markFetched()` / `_coolKey()` は将来 force=true 連打抑制復活のため残置 (現状 dead code、コメントで明記)

#### 効果

| 項目 | Before | After |
|---|---|---|
| 1 ユーザ × 1 年の forecast fetch 頻度 | 6 時間ごとに 1 回 (継続使用なら無限) | **生涯 1 回** (出生情報変更まで) |
| 503 exceededCpu 発生条件 | デフォルト 1000ms 超 (年連続切替で再現可) | デフォルト 30000ms 超 (Forecast 計算では実質起きない) |
| クライアントコスト | 0 (端末 SharedPreferences、1 年 ≈ 180KB / 5 年 ≈ 900KB) | 同上 |
| サーバ (CF) コスト | リクエスト課金 | **削減** (キャッシュ hit はリクエスト自体走らない) |

#### 検証
- flutter analyze: No issues found (lib/ 側無傷)
- worker テスト: 300/300 全 pass (前回と同じ、ロジック変更なし、設定のみ追加)
- 実機検証は Worker deploy + AAB v+16 上げ後 (次セッション)

#### 未実施 (次セッション)
- Worker deploy で cpu_ms=30000 を本番反映
- Flutter 側は AAB v+16 で同梱

### 0.2.11 map_screen の chart fetch debounce 250ms (2026-05-29 セッション)

> CF Logs 分析中に発見: 20:17:55 〜 20:17:59 の 3.84 秒で `/public/astro/chart` を **13 回連続 fetch**。
> 原因解析した結果、`MapTimeSlider` の ◀▶ 1 日ステッパ (`_stepDay`) は **即時 commit (debounce なし)** で、
> 高速タップごとに `_loadProfileAndChart` → `fetchChart` が走る設計だった。
> ユーザは最後のタップ結果しか見ないので、中間 12 fetch は無駄。本番 Pro 公開後の負荷対策として実装。

#### 既存状況
- map_screen の chart cache: `_chartCacheByDate` で 10 分バケットキャッシュ済 (50 件 LRU)
- スライダー (`Slider.onChangeEnd`): リリース時のみ commit (debounce なし問題は薄い)
- **ステッパボタン**: `_stepDay(±1)` / `_stepHour(±1)` は即 `widget.onCommit()` → 連打すると 1 タップ 1 fetch
- サーバ rate limit: chart bucket = default = 30 req/分/IP (1 IP の極端連打は CF 側で 429、ただし本番 100 ユーザ × 各 13 連打 = 累積 1300 req/分は通る)

#### 設計判断 (オーナー決定 2026-05-29)
- **クライアント debounce 250ms** を `_loadProfileAndChart` 呼出経路に追加
- 即時実行が必要な経路 (`initState` / `reloadProfile`) は debounce バイパスで維持
- 体感遅延 250ms は許容 (UX 影響なし)

#### コード変更
- `lib/screens/map_screen.dart`:
  - `_chartFetchDebounce` Timer フィールド追加
  - `_scheduleLoadChart({DateTime? targetDate})` ラッパー追加 (250ms debounce)
  - `MapTimeSlider.onCommit` → `_scheduleLoadChart` 経由
  - `MapDailyTransitScreen.onJumpToTime` → `_scheduleLoadChart` 経由
  - `dispose` で `_chartFetchDebounce?.cancel()`

#### 効果

| シナリオ | Before | After |
|---|---|---|
| ◀▶ ステッパ 13 連打 (実観測 2026-05-28) | 13 fetch | **1 fetch** (最後のタップのみ) |
| スライダー連続 commit | 各 commit 即 fetch | 250ms 静止後に 1 fetch |
| Forecast→Map 連続日付ジャンプ | 各ジャンプ 1 fetch | 250ms 集約 |
| 単発タップ (普通の操作) | 1 fetch (即時) | 1 fetch (250ms 遅延、体感ほぼなし) |
| 100 ユーザ同時 13 連打 | 累積 1300 req | **累積 100 req** (各ユーザ 1 fetch) |

#### 検証
- flutter analyze: No issues found
- extract.py: stamp diff `+0 -0 ~1` (map_screen.dart 1 ファイル変更)
- audit.py: 78 / 20 / 4 / 1 / 0 (前回と同じ、新規 HARD ゼロ)

### 0.2.12 audit.py 行数閾値を 3 段階化 (NOTICE 300 / WARN 500 / HARD 1000) (2026-05-29 セッション末)

> Solara 実態データ分析の結果、旧閾値 (WARN 300 / HARD 500) は厳しすぎたため再設計。
> 旧 HARD 500 では 32 ファイル / 全 191 (16.8%) が違反 → 「HARD ゼロ運用」が事実上不可能で警告が形骸化していた。

#### 実態データ (2026-05-29 時点、lib/ 配下 191 ファイル)

| 統計 | 値 |
|---|---|
| 中央値 | 248 行 |
| 平均値 | 330 行 |
| 最大値 | 3099 行 (map_screen.dart) |
| 旧 HARD ≥500 違反 | 32 ファイル (16.8%) |
| 800 行以上 | 9 ファイル (4.7%) |
| 1000 行以上 | 7 ファイル (3.7%) |

#### 新閾値設計

| レベル | 行数 | 性格 | 現状違反数 | 表示色 |
|---|---|---|---|---|
| 🟢 OK | <300 | 健全 | 113 個 | (表示なし) |
| 🟡 NOTICE | 300-499 | 「設計を意識するライン」 (旧 WARN) | 46 個 | 🟡 |
| 🟠 WARN | 500-999 | 「分割を検討すべき」 (旧 HARD) | 25 個 | 🟠 |
| 🔴 HARD | ≥1000 | 「即時分割急務、PR ブロッカー想定」 | 7 個 | 🔴 |

#### HARD 7 ファイル (リファクタ優先順位)

1. `map_screen.dart` 3099 行 — 3 ファイル分割で全部消える
2. `map_daily_transit_screen.dart` 1923 行 — 2 分割
3. `sanctuary_screen.dart` 1473 行 — セクション別 part 分割
4. `sanctuary_title_diagnosis.dart` 1385 行
5. `galaxy_screen.dart` 1275 行
6. `forecast_screen.dart` 1084 行
7. `daily_transit_data.dart` 1013 行 — データ専用なら許容圏か

#### コード変更
- `tools/code_audit/audit.py`:
  - `LINE_NOTICE = 300` 新規、`LINE_WARN = 500`、`LINE_HARD = 1000` に再定義
  - `check_line_count` を 3 段階返却に対応
  - main 出力でレベル別カウントを「HARD N / WARN M / NOTICE L」形式に
  - 絵文字: 🔴 HARD / 🟠 WARN / 🟡 NOTICE (旧: 🔴 / 🟡 の 2 種)
- `tools/verify_code.py`:
  - `FILE_SIZE_CRIT = 900 → 1000` (audit.py の HARD と整合)
  - docstring に「閾値は 2026-05-29 に audit.py と整合」と明記

#### exit code
- HARD (≥1000) が 1 個でもあれば exit 1 (= 公開ブロッカー想定)
- WARN / NOTICE のみなら exit 0

#### 検証
- audit.py 再実行: 行数 HARD 7 / WARN 25 / NOTICE 46 / 重複 20 / TODO 4 / print 1 / 未使用 0
- 既存の機能・出力は後方互換 (重複・TODO・print・未使用は同じロジック)

### 0.2.13 ACG モード UI 改善 — タイトル × ボタン拡大 + 天頂帯/天底帯 視認性向上 (2026-05-29 セッション)

> 実機検証で「ACG モードの上部 ✕ ボタンが押しにくい」「天頂帯/天底帯がほとんど見えない (特に天底帯)」のフィードバックを反映。タップ領域とラインの視覚密度を再設計した。

#### ① バナー (タイトル + ❓ + ✕) のタップ領域拡大

[`map_astro_carto.dart` AstroCartoBanner](../lib/screens/map/map_astro_carto.dart) (L34):
- 旧: ❓/✕ ともに padding `EdgeInsets.symmetric(h:4, v:2)` + icon 16/14 → 実効 ~24×20px → タップ困難
- 新: padding `h:10, v:10` + icon 18/18 → 実効 ~38×38px (Material 推奨 48 には未満だがバナー UI 制約下で最大化)
- バナー総高さの肥大を抑えるため container 外側 padding `vertical: 8 → 3` (= バナー総高さ +12px に留めた)
- ✕ の色も `0xFFAAAAAA → 0xFFCCCCCC` で視認性向上

#### ② 天頂帯・天底帯 (latitude bands) の視認性向上

[`map_astro_lines.dart buildAstroLatitudeBandPolylines`](../lib/screens/map/map_astro_lines.dart) (L221):

| 項目 | 旧 | 新 |
|---|---|---|
| `opacityBase` | 0.22 | **0.48** |
| 天底色暗化倍率 | 0.60 | **0.80** |
| 天底追加 ×0.85 減衰 | あり | **撤廃** |
| 天頂帯 strokeWidth | 1.4 | **1.8** |
| 天底帯 strokeWidth | 1.2 | **1.6** |

実 alpha 換算:
- 天頂帯: 0.22 → 0.48 (約 2.2 倍可視化)
- 天底帯: 0.19 → 0.48 (約 2.6 倍 + 色暗化緩和)
- 識別性: 破線パターン (5/6 dashed) で天頂/天底の区別を担保 (旧来通り)

#### 検証
- flutter analyze: No issues (2 files、3.1s)
- extract.py stamp diff `+0 -0 ~2`

### 0.2.14 Daily ボタン「今日固定 TOP カテゴリ」+ popup Header 初回 1.5s halo + Galaxy 3 演出も 0 時切替 (2026-05-29 セッション)

> 実機検証で「Daily チップアイコンが 1 日の途中で変わる」のフィードバックを発見。原因は `_topCategory` が MapTimeSlider/Forecast ジャンプの `targetDate` に追従する設計だったため。Daily 系 UI 専用の「今日固定」TOP カテゴリ系統を新設。同時に Sanctuary subtitle 文言「タロットのみ」と整合させるため Galaxy 3 演出も Sanctuary リセット時刻設定から独立させた。

#### 4 つの主変更

##### ④-1 端末日付 0 時固定キー API 新設

[`solara_storage.dart`](../lib/utils/solara_storage.dart) (L111-115 + 620-639):
- `static String localDateKey()` — `now.year-month-day` (Sanctuary 設定無視、常に 0 時切替)
- `static Future<bool> wasLocalOverlayShownToday(String type)`
- `static Future<void> markLocalOverlayShown(String type)`
- 専用ストレージキー: `solara_local_overlay_shown_<type>_<YYYY-MM-DD>`
- 既存 `logicalTodayKey()` / `wasOverlayShownToday` / `markOverlayShown` (タロット用、リセット時刻追従) は温存

##### ④-2 Daily Transit Badge + Galaxy 3 演出を 0 時固定キーへ移行

[`map_screen.dart`](../lib/screens/map_screen.dart) (`dominant_fortune` overlay):
- `wasOverlayShownToday → wasLocalOverlayShownToday`
- `markOverlayShown → markLocalOverlayShown`

[`galaxy_screen.dart`](../lib/screens/galaxy_screen.dart) + [`new_moon_overlay.dart`](../lib/widgets/new_moon_overlay.dart) + [`full_moon_overlay.dart`](../lib/widgets/full_moon_overlay.dart) + [`catasterism_overlay.dart`](../lib/widgets/catasterism_overlay.dart):
- 全 8 箇所の `wasOverlayShownToday('new_moon'|'full_moon'|'catasterism')` / `markOverlayShown(...)` を local 版へ
- Sanctuary picker subtitle 「タロットのみ」と完全整合 (タロットだけが Sanctuary リセット時刻に追従)

##### ④-3 `_dailyChipCategory` 6 点平均算出

[`map_screen.dart`](../lib/screens/map_screen.dart) (L300-319, L495-562):
- 新 state: `_dailyChipCategory`, `_dailyChipDateKey`, `_computingDailyChip`
- 端末 0/4/8/12/16/20 時の 6 点で `fetchChart()` → `scoreAll()` → fScores 16 方位合計を加算 → argmax
- 端末日付 `localDateKey()` でキャッシュ、翌日に切替わるまで Worker 再 fetch なし (1 日 6 回のみ)
- `_loadProfileAndChart` 完了時に `unawaited(_recomputeDailyChipCategoryIfNeeded())` で fire-and-forget
- 確定後 `_checkDailyBadgeState()` を再評価 (halo 発光状態を即時更新)

##### ④-4 Daily チップ + popup Header + アニメ + 判定 — 全て `_dailyChipCategory` に統一

- `MapMenuChips.topCategory: _dailyChipCategory ?? _topCategory` (チップアイコン)
- `MapDailyTransitScreen.topCategory: _dailyChipCategory ?? _topCategory` (popup TOP バナー)
- `_onDailyBadgeTap` 内 `kind = _dailyChipCategory ?? _topCategory` (アニメ演出)
- `_checkDailyBadgeState` で `effectiveCategory = _dailyChipCategory ?? _topCategory`

→ 結果: 時刻スライダー操作で `_topCategory` が動いてもチップ + popup TOP + アニメは「今日固定」で不変

#### popup Header 初回 1.5s 金色 halo (1 日 1 回)

[`map_screen.dart`](../lib/screens/map_screen.dart) (`_onOverlayComplete` 修正、`daily_header_glow` キーで永続化):

```dart
final glowSeen = await SolaraStorage.wasLocalOverlayShownToday('daily_header_glow');
final shouldGlow = !glowSeen;
if (shouldGlow) await SolaraStorage.markLocalOverlayShown('daily_header_glow');
setState(() {
  _dailyTransitOpen = true;
  _dailyHeaderGlowOnce = shouldGlow;
});
```

[`map_daily_transit_screen.dart _Header`](../lib/screens/map/map_daily_transit_screen.dart):
- StatelessWidget → StatefulWidget へ昇格
- `SingleTickerProviderStateMixin` + `AnimationController` (1500ms)
- TweenSequence: fade-in 400ms → 維持 500ms → fade-out 600ms (最大 alpha 0.55)
- Stack の `Positioned.fill` で headerBox 上に DecoratedBox を重ね、border + 2 段 boxShadow (blur 20+36, spread 4+8) で金色グロー
- 1 日 1 回ガード: `daily_header_glow` 永続キー (0 時固定)
- popup を閉じる時 (`_onDailyTransitClose`) に `_dailyHeaderGlowOnce = false` リセット (Stack の旧 widget が glow 再生し始めるのを防ぐ)

#### 基準地点 dropdown の RIGHT OVERFLOW 修正

[`map_daily_transit_screen.dart _buildVpDropdownWithGuide`](../lib/screens/map/map_daily_transit_screen.dart) (L925):
- 旧: `Row(MainAxisSize.min) + Flexible(Text)` → `isExpanded: true` の DropdownButton 内で制約が届かず overflow
- 新: `Row(MainAxisSize.max) + Expanded(Text)` で確実に ellipsis (`...`) 短縮表示

#### 検証
- flutter analyze: No issues (7 files、6.3s)
- extract.py stamp diff `+0 -0 ~7`

### 0.2.15 Stella 相談入力タイル「おでかけ／イベント」化 + 初期選択 null + 用語完全統一 (2026-05-29 セッション)

> 「自宅での事柄を Stella に相談したい場合、『おでかけ』だけだと設定しにくい」のフィードバックから、daily モードに「イベント」概念を追加 (= 自分が動かなくても、その場所で始まる事も含む)。同時に「どの経路から入っても初期選択は無し」に統一。

#### ① 入力タイル 2 行ラベル化

[`consultation_input_widgets.dart`](../lib/screens/consultation/consultation_input_widgets.dart) (L17-22):
```dart
const _modeChoices = <_ModeChoice>[
  _ModeChoice('daily', 'おでかけ\nイベント'),
  _ModeChoice('travel', '旅行'),
  _ModeChoice('migration', '移住'),
];
```
- `_ModeRow` の Text に `textAlign: TextAlign.center` + `height: 1.25` 追加
- IntrinsicHeight + stretch で 3 タイルの高さは自動で揃う
- Worker 側 mode key は `'daily'` のまま不変 → 既存 7 箇所の `_mode == 'daily'` ロジックに影響なし

#### ② 初期選択を null 化 (preset 経路含む全経路)

[`consultation_input_screen.dart`](../lib/screens/consultation/consultation_input_screen.dart) (L131):
- 旧: `if (widget.presetTarget != null) { _mode = 'travel'; _scopeKind = 'point'; }` を撤廃
- 新: どの経路 (Map preset / Daily Transit / Sanctuary) でも `_mode` / `_scopeKind` ともに初期 null
- preset の地点情報は保持: ユーザーが mode を選んだ瞬間に `_onModeChanged` 内の既存ロジック (`if (widget.presetTarget != null) _scopeKind = 'point'`) で自動的に scope=point に進む

#### ③ 用語完全統一 (タイル + 履歴 + Pro 訴求 + 共有テキスト)

| 場所 | 表記 | 理由 |
|---|---|---|
| 入力タイル | `おでかけ\nイベント` (2 行) | 主入口、両概念を強調 |
| 履歴カード | `おでかけ・イベント` (1 行・中黒) | 縦スペース無 |
| Pro 訴求文 (paywall body / desc) | `おでかけ・イベント以外の相談 (移住・旅行)...` | 文章内 |
| 共有テキスト | `おでかけ・イベント` (1 行) | フォーマット出力 |

変更ファイル:
- [`consultation_history_screen.dart:39`](../lib/screens/consultation/consultation_history_screen.dart#L39): `_modeLabel['daily']`
- [`consultation_result_credit_widgets.dart:37`](../lib/screens/consultation/consultation_result_credit_widgets.dart#L37): paywall body
- [`consultation_result_screen.dart:252`](../lib/screens/consultation/consultation_result_screen.dart#L252): paywall desc
- [`consultation_share.dart:36`](../lib/utils/consultation_share.dart#L36): `_modeLabel['daily']`

#### 検証
- flutter analyze: No issues (2+4 files)
- extract.py stamp diff: `+0 -0 ~2` (タイル変更) → `+0 -0 ~4` (用語統一)

### 0.2.16 相談履歴に「いつ」表示 + categoryColors 連動チップ色 + VP/Loc「現住所」表記 (2026-05-29 セッション)

> 履歴一覧で「いつ・どの時間帯を対象に相談したか」が一目で分かるよう情報密度を上げ、テーマチップの色を Map と統一 (扇・スコアバーと同色)。同時に VP/Loc の home slot は住所文字列ではなく「現住所」と表示する。

#### ① ConsultationRecord に when 系 5 フィールド追加

[`consultation_record.dart`](../lib/utils/consultation_record.dart):
- 新フィールド: `whenKind`, `whenDate`, `whenStart`, `whenEnd`, `whenTimeBand` (全 nullable)
- `fromReadings()` に `ConsultationWhen? when` 引数追加 → 5 フィールドへ自動展開
- `toJson()` / `fromJson()` 対応 (nullable で旧データ欠落許容、後方互換維持)
- `copyWith()` 同期 (新フィールドは保持のみ、変更不可)
- 旧 JSON ラウンドトリップテスト 18 件全 pass = 完全互換

#### ② result screen の auto-save に `when: req.when` 追加

[`consultation_result_screen.dart:294`](../lib/screens/consultation/consultation_result_screen.dart#L294) の `_persist()`:
- `ConsultationWhen` をそのままレコードに保存 → 履歴で再現

#### ③ 履歴画面に「いつ」行を追加

[`consultation_history_widgets.dart`](../lib/screens/consultation/consultation_history_widgets.dart):
- 新ヘルパ:
  - `_whenLabel`: kind 別整形
    - `date` → `2026/05/30`
    - `range` → `5/30〜6/2`
    - `within6mo/within1yr/in3yr/in5yrPlus` → `半年以内` 等
    - null + mode='daily' → `今日` (デフォルト推測)
    - null + mode='migration' → `未定` (デフォルト推測)
    - null + mode='travel' → null (旧データ欠落、行ごと非表示)
  - `_timeBandLabelOrNull`: `morning→朝` 等 5 種
- Row 3 新設 (Row 2 の下): `📅 [whenLabel] ⏰ [timeBand]` 横スクロール可

#### ④ テーマチップを Map と同じ categoryColors で着色

[`consultation_history_screen.dart`](../lib/screens/consultation/consultation_history_screen.dart):
- `import '../map/map_constants.dart' show categoryColors;` で Map の色マップ流用
- `_themeColor(theme)` ヘルパ: 5 テーマ (love/money/work/communication/healing) は `categoryColors` から、`newStart` のみ独自定義 `0xFFFFB07C` (夜明けオレンジ)
- 「変化・新たな出発」は Map に存在しないテーマ → 独自色で差別化

[`consultation_history_widgets.dart _MetaChip`](../lib/screens/consultation/consultation_history_widgets.dart):
- `Color? color` 引数追加
- bg = `color.withAlpha(0x22)` / border = `color.withAlpha(0x66)` / text = full color
- 旧 hardcode gold は default に残し後方互換

#### ⑤ 具体地点ピッカー: home は「現住所」表記 + Worker に「現住所」を送信

[`consultation_input_picker_widgets.dart _LocationChip`](../lib/screens/consultation/consultation_input_picker_widgets.dart) (L97):
- 旧: `slot.name` (= `profile.homeName` = ユーザー入力住所、例「東京都渋谷区」) をチップに表示
- 新: `slot.isHome ? '現住所' : slot.name`

[`consultation_input_picker.dart _onSlotTap`](../lib/screens/consultation/consultation_input_picker.dart) (L138):
- 旧: `_PickedSpecific(name: s.name, placeKind: 'saved')` → Worker に住所文字列が flow
- 新: `_PickedSpecific(name: s.isHome ? '現住所' : s.name, placeKind: 'saved')`

データフロー:
```
[chip] 🏠 現住所 → [選択中カード] ✓ 現住所
  → [Worker placeReference] 「『現住所』という場所」
  → [結果本文・タイトル] 住所文字列が一切出ない
```

Worker [`consultation_v2.js:78-83`](../worker/src/consultation_v2.js#L78) の既存 `placeKind='saved'` 分岐がそのまま機能 (変更不要、テスト 21/21 pass で保護)。

#### 検証
- flutter analyze: No issues
- Flutter tests: 18/18 pass (history + favorite)
- Worker tests: 21/21 pass (consultation_v2)
- extract.py stamp diff: `+0 -0 ~4` (record + history) → `+0 -0 ~2` (picker)

### 0.2.41 起動スプラッシュ + 相談時刻表示 + Map/Popup UX 一括改善 (2026-06-01 セッション)

> オーナー実機フィードバック起点の UI/UX 改善 9 件を 1 セッションで実施。新規 HARD 化ゼロ。

#### A. 起動スプラッシュ (新規 `lib/widgets/solara_splash.dart`)
- コールド起動時に `SolaraHome` (Map タブ) の上へ被せ、Map 初期化の待ち時間を埋める (`main.dart` の `home:` を `SolaraSplash(child: SolaraHome())` でラップ)。同意未取得 (AiConsent) 時は出さない。
- 起動ごとに 3 枚 (`assets/splash-bg/{gold,azure,rose}.webp`、称号儀式 `ceremony.webp` 調 = 純黒 + 金アールヌーヴォー四隅 + 中央発光四芒星、Gemini 3.1 Flash 生成) からランダム 1 枚。
- フェードイン 700ms → ホールド 1500ms → フェードアウト 800ms (計 3.0s) で自動消滅。中央やや下 (`Alignment(0,0.42)`) に `Solara` (Cinzel) + サブタイトル `Follow Stella through the living stars.` (Cormorant) を重ねる。生成スクリプト = `mockup/generate_splash_backgrounds.py`。

#### B. 相談 時刻指定まわり (オーナー要望)
- 時刻指定時に時間帯チップ (5 枠) を**自動選択しない** (`_pickHour` で `_whenTimeBand=null`)。Worker へ送る語りバンドは `_buildWhen` が `bandFromHour(_whenHour)` で導出 (UI チップ選択と Worker payload を分離 → narrative 品質は不変)。
- 結果カードの時間帯行は、時刻指定時はバンド名でなく「**15:00**」を表示 (`_TimeWindowRow.specifiedHour`)。ライブは `request.when.atUtcMs`、履歴は新規 `ConsultationRecord.whenAtUtcMs` から復元。履歴一覧カードも同様 (`consultation_history_widgets.dart`)。
- レコードに `whenAtUtcMs` (int?) を追加 (nullable・旧レコード互換)。

#### C. その他 UI 修正
- Map: 「✦ Stella に相談」ボタンを現在地ボタンと同寸 (52→40px)。
- Galaxy 最下部: ラベルを Cinzel(大文字専用) → Cormorant で「Stella」表示、size 13、本文 19→14、本文の前後ダブルクォート撤去。
- Paywall: 拠点数表記を「保存拠点数 10か所」/ 比較表「5か所 / 10か所」に統一。
- Sanctuary: Pro 称号再診断の案内ダイアログを枠内スクロール対応 (本文だけ `Flexible+SingleChildScrollView`、ヘッダ/ボタン固定 → 小型端末でボタンが押し出される不具合を解消)。
- Map: ☰ 表示メニュー / 📍 地点メニューを横一杯に (`left:60→16`。左サイドボタンが下端へ移動済みで余白列が不要に)。
- Map: 検索結果詳細 (`SearchFocusPopup`) 表示中の端末 back を右上 × と同一動作に (詳細だけ閉じて検索結果一覧へ。Map まで戻さない)。
- `info_popup`: 本文の `right:26` 余白列を撤去し本文を枠の右端まで使用 (× は最上行右上に float のみ)。全 28 利用箇所に一括適用。

#### 検証
- flutter analyze: lib/ クリーン (既存 test 2 件のみ)
- Flutter tests **275 pass** / Worker tests **345 pass**
- extract.py stamp diff `+0 -0 ~0` (完全同期) / audit.py 行数 **HARD 7 (新規ゼロ)** / WARN 29 / 重複 20 (全て `),` 等の構造的誤検出) / 未使用候補 0

> 注: §0.2.42〜§0.2.45 (NavBar 光点スライド / スプラッシュ調整 / 相談結果↔Map 戻り導線 /
> スプラッシュ撤去) は git 履歴にあるが本人手版は未バックフィル (機械抽出 `feature_inventory/` は同期済)。

### 0.2.46 月イベント通知の取りこぼし対策 B+C+A (2026-06-01 セッション、commit `d029b99`)

> 新月→満月→刻星化の月サイクル儀式 (層 4d Galaxy) は overlay が `initState` (コールド起動)
> でしか発火判定されず、warm resume / 別タブからの Galaxy 入室 / 「アプリを開かない日」で
> 取りこぼしていた。通知拒否でもアプリ内で拾い、許可すれば OS 通知で外から呼び戻す 3 段改善。
> 新規 HARD ゼロ。§0.2.42 (NavBar 光点スライド) を土台に C のバッジを追加。

#### B. overlay 発火の再判定 (アプリ内・許諾不要)
- `galaxy_screen.dart` に公開メソッド `recheckMoonEvents()` 新設。日付と intention だけ軽量に
  読み直して `_checkMoonOverlay` を呼ぶ (重い `_loadData` は呼ばない / overlay・replay 中は no-op)。
- `main.dart`: `_onTabTap` の Galaxy 入室時 + `didChangeAppLifecycleState` の resumed で呼ぶ
  → コールド起動だけでなく warm resume・別タブからの入室でも当日イベントを拾う。

#### C. NavBar バッジ + Map 案内 (アプリ内・許諾不要)
- 新規 `utils/moon_event_status.dart`: `MoonEventKind` enum + `MoonEventStatus.pendingToday(now)`。
  overlay 発火条件 (新月/満月/刻星化 + `wasLocalOverlayShownToday`) を **一本化**し、`_checkMoonOverlay`
  もこれを使う形にリファクタ (バッジ/案内と overlay の条件乖離を防ぐ単一の真実)。
- `solara_nav_bar.dart`: `showGalaxyBadge` 追加。Galaxy(idx3) アイコン右上に静的ゴールド点 (滞在中は
  非表示・tick なし)。
- 新規 `screens/map/map_moon_notice.dart`: Map 上部 (時刻スライダー直下) の案内バナー。種別→文言
  (ロケール対応)、タップで閉じるのみ (Galaxy へ遷移しない)。
- `main.dart`: `_pendingMoonKind` + `_refreshMoonStatus()` (起動 postFrame / resume / タブ切替 /
  overlay 開閉で更新) が NavBar バッジ (`!=null`) と `MapScreen.showMoonNotice(kind)` を駆動。

#### A. ローカル通知エンジン + Sanctuary トグル (許諾要・OS 通知)
- 依存追加: `flutter_local_notifications ^21.0.0` / `timezone ^0.11.0` / `flutter_timezone ^5.1.0`。
  **permission_handler 不採用** (iOS で未使用権限をバイナリに含め App Store リジェクト要因)
  → プラグイン内蔵 API で許諾完結。**exact alarm 不使用** (Android 13+ で原則拒否・審査制限)
  → `AndroidScheduleMode.inexactAllowWhileIdle`。
- 新規 `utils/moon_notification_service.dart`: init (timezone + 通知チャンネル) / isAuthorized /
  requestPermission / `rescheduleAll` (cancelAll → 新月・満月・刻星化 + 惑星イベントを **当日朝 9:00**
  に予約。マスタ OFF / OS 未許可なら cancel のみ) / disable / enableFromToggle /
  `runSoftAskIfNeeded` (Apple 4.5.4 準拠で初回起動では出さず、新月 Set Intention 直後に自前
  ソフトアスク → 受諾で OS 許諾。2 回上限・サイクル 1 回の back-off)。
- 惑星イベントは `CelestialEvents.fetchCycleEvents` の `localDate`/`localDescJP` を当日朝に通知
  (上限 30、オフライン時は次回 reschedule で再試行)。
- `solara_storage.dart`: 通知マスタスイッチ + ソフトアスク back-off (declines / cycle) を永続化。
- `sanctuary_screen.dart`: App 設定群 (Language 隣) に通知トグル `_NotificationToggleItem` を復活
  (HTML mock の "Notifications" は実装が無かったダミー)。許諾不可時は SnackBar で設定誘導。
- reschedule トリガー: 起動 `main()` / 新月 Set Intention / Galaxy overlay close (儀式完了反映)。

#### native 設定 (最新公式準拠、2026-06 調査)
- `android/app/build.gradle.kts`: `isCoreLibraryDesugaringEnabled` + `desugar_jdk_libs:2.1.4`
  (v21 必須。本 env は compileSdk 36 / AGP 8.11.1 / Gradle 8.14 で要件充足)。
- `AndroidManifest.xml`: `POST_NOTIFICATIONS` + `RECEIVE_BOOT_COMPLETED` + `ScheduledNotification(Boot)Receiver`。
- `proguard-rules.pro` #12: flutter_local_notifications / GSON keep (R8 minify + shrinkResources 対策)。
- `ios/Runner/AppDelegate.swift`: `UNUserNotificationCenter` delegate (`import UserNotifications`)。
- `pubspec.yaml`: version **1.0.0+25 → +26**。

#### 検証
- flutter analyze lib: クリーン
- extract.py stamp diff `+1 -0 ~4` → 同期後 `+0 -0 ~0`
- moon_phase + widget test 36 green
- **flutter build appbundle --release 成功 (114.8MB)** = R8 + desugaring + manifest merge +
  通知プラグインのネイティブ統合が実ビルドで全通過
- audit.py: 行数 **HARD 7 (新規ゼロ)** / WARN 30 / 重複 20 (全て `),` 等の構造的誤検出) /
  未使用候補 0。新規 3 ファイルは moon_notification_service 312 (NOTICE) / 他 2 は <300

#### 未検証 (次セッションへ)
- **実機 (A101FC) での通知実発火 + 端末再起動後の予約永続化** — ビルド成功はリンク/設定の正しさ
  のみ保証、実発火は別。
- **iOS は Mac/CI でのビルド検証が必要** (Windows ではビルド不可、コードは analyze クリーン)。
- アップロード用 AAB は dart-define (GCP / RC android / Google serverClientId) 付きで再ビルド要。

### 0.2.47 アプリアイコン刷新 + ストア素材一式 + AAB +27 (2026-06-01 セッション、commit `addf6bb` push 済)

> コードレイヤ変更なし (extract `+0 -0 ~0`)。アセット/設定/ストア素材のみ。新規 HARD ゼロ。

#### アプリアイコン (launcher)
- 原画 `mockup/share-assets/menu-icons/v2/unsealed.png` (1024 黒背景の9芒星メダル)。
- `tools/make_app_icon.py` (新規) が `assets/app_icon.png` (フル・iOS/Androidレガシー用) と
  `assets/app_icon_foreground.png` (紋章を 66% = 円マスク径72dp相当に縮小・透明・アダプティブ前景用) を生成。
- `pubspec.yaml` `flutter_launcher_icons`: image_path/foreground を新アセットへ、adaptive 背景 `#080C14`→`#000000`、`remove_alpha_ios:true` 追加。`dart run flutter_launcher_icons` で全解像度再生成。
- 🔴 罠: `mipmap-anydpi-v26/ic_launcher.xml` は flutter_launcher_icons に上書きされず旧 `inset 16%` が残る → 手動除去 (前景の二重縮小を防ぎ円マスクで金リング flush)。
- version `1.0.0+26 → +27`。

#### ストア掲載素材 (`docs/store_compliance_assets/`)
- `icons/google_play_icon_512.png` (512² 32bit不透明) / `icons/apple_app_store_icon_1024.png` (1024² RGB透過なし)。
- `feature_graphic/feature_graphic_{A,B,C}.png` (1024×500) を `tools/make_feature_graphic.py` で生成、**C (astromap) 採用**。文言「SOLARA / 占星術でひもとく自己探求」(NG ワード回避・AI 表記不使用)。Cinzel は `.gitignore` (tools/_fonts_*.ttf)。
- 掲載ドキュメント A-4 / A-5 / D-8 を新ファイル参照に更新。

#### 検証
- flutter analyze: lib/ クリーン (既存 test 2 件のみ) / AAB +27 ビルド成功 (112.7MB, dart-define 全注入)。
- audit.py **HARD 7 (新規ゼロ・行数増は §0.2.46 由来) / WARN 30 / 重複 20 (全て `),`) / 未使用候補 0**。
  find_unused_code.py の 2 候補 (`GalaxyArchiveSortLabel.jp` / `DominantFortuneKindToCategoryIcon.toCategoryIcon`) は両方 extension で使用中 = 誤検出。

### 0.2.48 星読みコールド仮表示 根治 + ストアスクショ一式 + AAB +28 (2026-06-02)

> コードは層 2a/認証 1 ファイルのみ (`app_attest_client.dart`)。他はアセット/ツール/ドキュメント。

#### 🐛 コールド起動時の AI 仮表示 根治 (commit `1eb86fa`)
- 症状: コールド起動直後の星読み/タロット/Stella が「Stella の声が届きませんでした。仮テキストを表示中」(`horo_fortune_cards._errorBanner`)。
- 真因: `addHeaders` が `await initialize()` (`androidPrepareIntegrityServer` warmup・冷時数十秒〜2分) を**未 time-box** で待つ → challenge/verify が 8s キャップ済みでも addHeaders 全体が initialize で詰まり、`fetchFortune` の 60s タイムアウトを食い潰す。c912622 の 8s キャップは challenge/verify のみで initialize が穴だった。+27 でも再発 (A101FC 実機 + `wrangler tail` で 200 が 60s 超過後に届くのを実証)。Gemini/課金/サーバは正常。
- 修正: `await initialize().timeout(_kAttestStepTimeout)` + try/catch。間に合わなければ degrade (ヘッダ無しで続行・log_only 通過 / verify 側 8s キャップと整合)。warmup は memoize で裏継続し次回 warm。
- version `1.0.0+27 → +28`。

#### ストア用スマホスクショ 11 枚 + 生成ツール (commit `f3cb781`〜`ec7d7d4`)
- `tools/make_store_screenshots.py` (新規・PIL): 実機 720×1520 adb キャプチャ → 1080×1920 装飾 (游明朝/金縁/9芒星紋章/SOLARA + 見出し+サブ見出し+数値オーバーレイ)。`docs/store_compliance_assets/phone_screenshots/` に 11 枚。raw (個人データ) は `.gitignore`。SCREENS リスト順で自動採番=並べ替え容易。手順は memory `reference_solara_store_screenshots.md`。
- Play8 = Map / ACG+CCG(2枚配置) / Locations / 検索エネルギー / Stella相談(入力+結果の2画面+解析説明+数値) / ホロ / サイクル / ヒートマップ。
- 掲示数値はすべて実コード/D1 実測: 16方位 / 最大120本ライン / 12ハウス / 8アスペクト種 / **246 国・地域** / **488,270 都市** / 1,500 地点採点 / Pro 週100回 / 最大5年先。

#### 検証
- audit.py **HARD 7 (新規ゼロ) / WARN 31 / NOTICE 45 / 重複 20 (全て `),` 等 構造的) / TODO 4 / print 1 / 未使用候補 0**。
- find_unused_code.py の 2 候補 (`GalaxyArchiveSortLabel.jp` / `DominantFortuneKindToCategoryIcon.toCategoryIcon`) は両方 extension 実使用 (grep 裏取り) = 誤検出 = **削除対象ゼロ**。
- flutter analyze クリーン / extract `+0 -0 ~0`。
- 都市データ正典訂正: D1 `solara-cities` 実測 **488,270 行 / 246 国・地域** (§0.2.19 の旧見積「約169,000」を本セッションで更新)。`world_cities.js`(762) はフォールバック。

### 0.2.49 検索2パターン + 相談戻りチップ プロセス死復元 + クレジット特典導線 + 現住所表記 (2026-06-02 PM、commit `10a628d`)

> 層をまたぐ機能追加 5 件。新規 HARD ゼロ (map_screen 3561→3628 増だが既存 HARD 内)。
> Worker rank は本セッションで deploy 済 (version `4b112d82`、後方互換のため現行配布アプリに無影響)。

#### ① 検索結果の2パターン (中心点 / 知名度) — 層 0 + 層 4a
- 並び替えではなく**取得候補の中身が変わる**。Google Places (New) Text Search の `rankPreference` を
  「中心点 = DISTANCE (地図中心=現住所からの近さ優先)」「知名度 = RELEVANCE (既定)」で切替。
  pageSize は 20 据置 (= 1 リクエスト/検索 = 課金増ほぼゼロ。Google が順位を変え上位 20 件の中身が変わる)。
- `worker/src/index.js`: `/public/search` に `rank` (distance|relevance) 受領。未指定は relevance
  フォールバック (旧クライアント互換)。`worker/src/search.js`: distance のとき `rankPreference:'DISTANCE'`。
- `map_search.dart`: `searchPlaces(rank:)` + `SearchResultList` ヘッダに `[中心点｜知名度]` トグル + ヘルプ popup。
- `map_screen.dart`: `_searchRank` (既定 distance) / `_changeSearchRank` (保存済み `_searchOriginCenter`
  で同一キーワード即再検索) / `captureMapRestore`・`_applySearchRestore` に rank 追加 (プロセス死復元でも保持)。
- 新規 `worker/test/search.test.js` 4 件 (fetch mock で rankPreference 検証)。

#### ② 相談戻りチップを プロセス死復元 対象に — 層 1c + 層 2c + 層 5
- 🗺「Map画面でみる」で `popUntil` により相談ルートを破棄するため live 状態はメモリ専用 singleton
  (`ConsultationReturn`) のみ。低 RAM 端末で Google マップ往復中に OS kill → コールド再起動で
  検索/シートは復元されるがチップだけ消えていた穴を塞ぐ。
- `ConsultationV2Reading.toJson` (既存 fromJson と往復) / `ConsultationRequest.fromJson`
  (+ `ConsultationWhen/Scope/Point.fromJsonOrNull`) / `ConsultationResumeState.toJson/fromJson` /
  `ConsultationReturn.captureRestore/restoreFrom` を追加。
- `main.dart`: `_saveRestoreSnapshot` で capture (`snap['consultReturn']`)、`_restoreLastScreen` で
  restore。`route` 復元 (ConsultRestore) とは排他 (🗺 で pop=チップ側 / チップ take()=route 側)。
- 新規 `test/consultation_return_restore_test.dart` 3 件 (往復 / capture-restore / 壊れ snapshot 握り潰し)。

#### ③ クレジット特典の導線追加 — 層 2a/2b + 層 3a + 層 4a/4b + 層 5
- **未設定カード訴求**: プロフィール未設定カード (Map `_buildNoProfileGuide` / 共通
  `widgets/no_profile_guide.dart` = Forecast・Locations / `horo_backdrop.dart` = Horo) に
  共通見出し「✦ 出生情報と現住所を登録すると、無料クレジットを3つプレゼント」を追加。機能説明
  (方位スコア / ホロスコープ) は各画面の文言を維持。文言はウェルカムバナー承認済み表現に統一。
- **サインインお祝いスナックバー**: 初回 Google/Apple サインインで +3 (signin grant) が
  **新規付与されたときだけ** お祝い。`solara_auth.dart` の `_onSignedInCredits` で結果を捕捉し
  one-shot シグナル `pendingSigninGrantAmount` + notifyListeners。`main.dart` (SolaraHome) が
  SolaraAuth を中央 listen して SnackBar 表示 (Sanctuary / 相談ダイアログ等 どこでサインインしても出る)。
  `alreadyGranted` (再サインイン) / 失敗時は祝わない。
- **サインイン勧誘バナー D (addSignin)**: `map_welcome_banner.dart` に 4 つ目のモード。表示条件は
  優先順位 B→C→D で `granted && C消化後(consultUsed) && !isSignedIn && !signinDismissed`。
  CTA「サインインする」→ Sanctuary。✕ で永続非表示 (`solara_storage` の signinDismissed)。
  サインイン後は Map 復帰時 (reloadProfile→再評価) に自動で消える。
- signin grant は profile grant と別冪等キー (`welcome_signin:{appUserId}` vs
  `welcome_profile:{deviceKey}`) のため**両方もらえて最大 6**。

#### ④ 現住所表記の統一 — 層 4f
- `locations_screen.dart` の Locations 一覧 `_buildRow` で HOME 行を住所文字列 (例: 名古屋市東区) →
  「現住所」固定。VIEWPOINT プルダウン / map_viewpoint_menu と統一 (個人情報的住所を一覧に出さない)。

#### 検証
- audit.py: 行数 **HARD 7 (新規ゼロ)** / WARN 32 / NOTICE 45 / 重複 20 (全て `),` 等 構造的) /
  TODO 4 / print 1 (いずれも意図的) / 未使用 private 0。
- find_unused_code.py の 2 候補 (`GalaxyArchiveSortLabel.jp` / `DominantFortuneKindToCategoryIcon.toCategoryIcon`)
  は grep 裏取りで両方 extension 実使用 = 誤検出 = **削除対象ゼロ**。
- extract.py stamp diff `+0 -0 ~14` (変更 14 ファイル反映)。coverage #3 で `/public/search`・
  `/protected/consultation/welcome-grant` ともに「一致」、Flutter→Worker 孤立なし、#7b 壊れ 0。
- flutter analyze クリーン (既知 test 2件のみ)。
- check_file_split.py: part-of 構造破綻なし。**HARD7 のファイル分割自体は引き続き未着手** (専用セッション)。

#### 未実施 (次セッションへ)
- **pubspec +28→+29 bump + AAB 再ビルド** (本セッションの Flutter 変更を本番反映する場合。Worker rank
  は deploy 済なので AAB 無しでも現行アプリは無影響)。
- **実機 A101FC 検証**: 検索トグル中心点/知名度 (実機確認済) / 未設定カード特典訴求の表示 (要新規状態) /
  サインインお祝いスナックバー + 勧誘バナー D の遷移。
- **HARD7 ファイル分割** (専用セッション、map_screen 3628 から)。

### 0.2.50 CFログ点検 — grant系 attestation warm-retry + 星読みGemini MAX_TOKENS切れ根治 (2026-06-02)

> CF Workers ログ 3 本 (5/31〜6/2、計 ~3,800 entries) を全件解析し、3 系統の異常を切り分け。
> コード変更が必要だったのは 2 件 (#1 Flutter / 星読み Worker)。#2 (UNRECOGNIZED_VERSION) と
> #3 (404 entitlement-get) は**仕様通り**でコード変更不要と確認。

#### ① grant 系 attestation の warm リトライ — 層 2a + 層 2b (Flutter)
- **症状**: `welcome-grant` / `migrate-purchased` が cold/stale warmup 時に attestation ヘッダ無しで
  送信され Worker が `missing_attestation_headers` を log_only warn (= enforced 化の would_block≠0
  ブロッカー + 将来 enforced 時の farming 穴)。原因は `addHeaders` の 8s degrade (コールド対策の副作用)。
- `app_attest_client.dart`: `addHeadersWithWarmRetry` (degrade 検知→**本送信の前に** warmup 完了を
  最大 12s 待ってヘッダ付け直し→送信は 1 回のみ) / `ensureWarm` / 静的 `hasAttestationHeader` /
  純ロジック top-level `warmRetryAttach` (プラットフォーム非依存・テスト可能) を追加。
- `consultation_api.dart`: `grantWelcomeCredits` / `migratePurchasedCredits` を warm-retry 経由に変更。
  両 endpoint は Worker 側冪等なので二重付与無し。credits 等 latency-sensitive な read は 8s degrade 維持
  (UX 優先・オーナー方針)。
- 新規 `test/app_attest_client_warm_retry_test.dart` 9 件 (warmRetryAttach 全 4 分岐 + bypass 安全動作)。
- 反映 = 次の AAB ビルド (Worker 変更なし)。

#### ② 星読み (fortune) Gemini MAX_TOKENS 切れ根治 — 層 0 (Worker)
- **症状**: `/protected/fortune` が 5/31〜6/1 のログで 500×5 (`Gemini MAX_TOKENS: output truncated`
  → non-JSON)。原因は `fortune.js` が `thinkingBudget:512` を渡すのに `maxOutputTokens` 未指定
  (= default 2048)。thinking が maxOutputTokens に算入され本文余地が ~1536 しか残らず、長めの星読みで
  切れていた。**tarot.js が 2026-05-26 に直したのと同一バグ**が fortune に残存。リトライ 2 回で同じ
  MAX_TOKENS を繰り返し wall 52-62s まで粘って失敗 = レイテンシ/コストも浪費。
- `fortune.js`: `maxOutputTokens: 4096` 明示。`consultation_v2.js`: `2048→4096` (同一構造の予防。
  候補1つで通常収まるが latent risk)。maxOutputTokens は**上限**で Gemini は実出力分のみ課金 =
  コスト増なし (むしろ無駄リトライ消滅で減)。worker test 42 件 green。
- 反映 = `wrangler deploy` (Worker のみ・AAB 不要)。

#### ③ コード変更不要だった 2 件 (記録)
- **UNRECOGNIZED_VERSION** (Play Integrity): サイドロード (Play 経由以外の install) の検証ビルド由来。
  `play_integrity_design.md` Q4 で「PLAY_RECOGNIZED 必須 = サイドロード排除」と確定済の意図的仕様。
  Worker の拒否ロジック正常。**enforced 化前の実機検証は必ず Play Internal Testing 経由で install** すること
  (adb / `flutter run` だとオーナー自身のテストが 401 になる)。
- **404 entitlement-get**: DO の「Pro 記録なし = 無料ユーザー」の正常規約。`lookupIsPro` が 404 を
  Free と正しく解釈 (購読した瞬間 200 化を log で実証)。バグではない。
- (参考) ボットスキャナ (PHP webshell / `.env` / `.git` 総当たり) は Worker が 404/429 で全撃退・
  正規アプリ通信への影響ゼロ・シークレット漏洩ゼロ。防御は健全。

#### 検証
- flutter analyze クリーン / Flutter test 33 件 green (warm-retry 9 + 関連 24) / worker test 42 件 green。
- extract.py stamp diff `+0 -0 ~4` (Flutter 2 + Worker 2)。coverage #3 エンドポイント増減なし・対整合維持。
- audit.py: **HARD 7 (新規ゼロ)**。app_attest_client.dart 503→576 (WARN 据置)。未使用候補 新規ゼロ。

### 0.2.51 Gemini thinking暴走 (thinkingBudget:null) 根治 — コスト約1/9 + 星読み500の真因 (2026-06-02 夜)

> §0.2.50 の maxOutputTokens 4096 は**部分修正**だった。usageMetadata を直接実測した結果、
> 星読み500とコスト高騰の**真因は `thinkingBudget: thinking ? 512 : null` の `null`** と判明。

#### 実測 (gemini-2.5-flash・本物プロンプト・usageMetadata 直接計測)
- **`thinkingBudget: null` は thinking OFF ではない**。Gemini 2.5 Flash の**動的(default)thinkingが暴走** (実測 ~3,900 思考トークン)。
- 結果、**無料星読み 1回 ¥1.64 = Pro(thinking 512)の 4.8倍**。しかも 3,900tok が maxOutputTokens を突破し
  **MAX_TOKENS→non-JSON→500** (= CFログの星読み500の正体。max 4096 でも null は再truncを実測 = §0.2.50 では塞ぎ切れていなかった)。
- 品質比較: Pro(512) ≈ Free(0)、むしろ Free(0) がハウス/プログレスまで網羅する回もあり**差なし**。
  thinkingBudget=0 を 6回 (カテゴリ変えて) 実測 = **6/6 STOP・JSON妥当・適切長・平均 ¥0.172**。

#### 修正
- `fortune.js` / `tarot.js`: callGemini 呼出を **`thinkingBudget: 0`** (Free/Pro 問わず真に OFF)。
  `body.thinking` は API 互換で受けるが参照しない (fortune は思考で品質が上がらないため)。¥1.64→¥0.17 (約1/9) + 500根絶。
- `fortune.js` / `tarot.js` の `callGemini` **default を `null`→`0`** に。指定漏れ呼出 (`relocation.js` /
  `line_narrative.js`) も自動で thinking OFF 化 = 同型の暴走を根絶 (relocation は narrative なので 0 が妥当)。
- **`consultation_v2.js` / `consultation.js` も `thinkingBudget: 0`** (当初 512 維持と判断したが、
  追加実測で覆った)。相談も「決定論的エンジン runConsultationPipeline が選んだ候補地のナレーション」で
  Gemini は推論しない。512 vs 0 を 5テーマ厳密比較 → **全件 STOP/JSON妥当・品質同等 (0 の方が簡潔)・40%減
  (¥0.48→¥0.29)**。結論: **Solara の Gemini 経路は全て narration で thinking 不要 → 全経路 0**。
- maxOutputTokens 4096 (§0.2.50) は安全網として残置 (thinking:0 なので実害 ~300tok で STOP、課金は実出力分のみ=増えない)。

#### コスト影響 (オーナーの「47円は多い/ユーザー増でやばい」への回答)
- 6/1 課金は全テキスト Gemini (画像生成なし確認済)。大多数の無料ユーザーが**一番高い暴走パス**を通っていた。
- 本修正で無料 fortune/tarot が約 1/9。星読みは 1日1回キャッシュ + 相談/タロットはクレジット制で**1ユーザーあたり上限**があり、
  スケール時のテキストコストは bounded。青天井の主費目は画像生成 (別管理) のまま。

#### 検証
- worker test 42 件 green / `node --check` fortune・tarot OK / extract `~N` (worker 2 ファイル) / 実測 2 系統 (トークン内訳 + 安定性6回)。
- 反映 = `wrangler deploy` (Worker のみ)。Flutter 変更なし。

### 0.2.52 拠点(リロケーション)を「ライン近接デルタ」静的無料機能へ作り替え (2026-06-02 夜)

> 旧拠点パネルは「出生地ハウス vs 現住所ハウス」の差分で、近距離移動ではハウスが変わらず
> 「変化なし」だらけ + Pro(Gemini)解説も生成されず "何に金払った?" 問題があった (オーナー実機で確認)。
> オーナーの気づき: ハウスは変わらなくても緯度経度が変わる → **各惑星ラインへの距離は必ず変わる**。
> これを主役にすれば「変化なし」が原理消滅し、Solara の核心 (マップの惑星ライン) と地続きになる。

#### コンセプト転換
- 「ハウスが変わったか」→「**どの惑星ラインに近づいた / 遠ざかったか (デルタ)**」を主役に。
- **全て静的** (Gemini 不使用 = ¥0)・**全員無料** (Pro 限定を撤廃)。実測で Solara の Gemini は全経路
  ナレーションのみ (§0.2.51) と確定済 → 拠点も静的合成で情報は同等。吉凶禁止に沿い「強まる/やわらぐ」中立表現。

#### 計算 (既存資産の再利用)
- 新規 `horoscope/horo_relocation_lines.dart`: `astro_lines.dart` の `buildAstroLines` + `minDistanceKmToLine`
  を使い、**7惑星(太陽/月/水/金/火/木/土) × 4アングル(MC/IC/ASC/DSC) = 28本** (本線のみ) について
  出生地・現住所からの距離を出し **delta = 現住所 − 出生地** を算出。
  🔴 ランキングは **現住所から近い順 (homeKm 昇順)**。当初 |delta| 順にしたが、実例 (岐阜→名古屋) で
  全ラインが 6700〜7700km 彼方・移動40kmで一律~30km変化 → 地球裏の無関係ラインが上位に来る欠陥を発見し是正。
  「現住所で近い (=その地で効く) ライン」を出すのが正、近/遠は副情報。上位4本表示。外惑星・アスペクト線は除外。
- 意味文 = 惑星の性質(7語・新規) × アングル領域(4語) × 方向(近/遠) × 度合い(わずかに/はっきりと/大きく) の合成。
  **km は非表示**・増減は言葉のみ (オーナー指示)。吉凶禁止 (強まる/やわらぐ)。
  ハウス変化は **変化した惑星だけ** 副次表示 + 静的コメント (fromHouse領域→toHouse領域)。

#### UI / 配線
- `horo_relocation_panel.dart` を StatefulWidget で全面書き換え (Pro/Gemini/teaser/ProStatus 連動を撤去、
  330行 NOTICE)。座標 (birth/home Lat/Lng) を props 追加 → `horo_bottom_sheet.dart` の `case 'relocate'` で
  `_profile` から渡す (part-of で State 共有)。
- 「ほぼ同じ場所」(max|delta|<1km) は移動なし案内のみ。

#### 撤去 / 残置
- 削除: `horo_relocation_pro_teaser.dart` / `horo_relocation_templates.dart` (静的ハウス文テンプレ、孤立化) /
  `fortune_api.dart` の `RelocationNarrative` + `fetchRelocationNarrative` (+ `solaraRelocationUrl` import)。
- paywall: 「リロケーション解説 Free=静的/Pro=Stella動的」行を `拠点(ライン近接)解説 ✓/✓` に、
  「リロケーション Stella動的解説」Pro bullet を撤去 (引越しシミュレーション=マップ別機能は残置)。
- 残置: Worker `/protected/relocation` (旧アプリ互換・新アプリは呼ばない)。

#### Map 引越 popup へ横展開
- 同じ `computeRelocationLineDeltas` + `relocationLineDeltaSentence` を **`map_relocation_popup.dart`** にも適用。
  ACG/引越レイヤーで地図上の地点をタップした popup に「**比較ベース(現住所/出生地) → タップ地点**で近づく/遠ざかる
  星のライン」上位3本を解説表示 (`_buildLineDeltaSection`)。`computeRelocationLineDeltas(base→tap)` は
  **`map_screen._buildRelocationPopup` でタップ時に1回算出**して `lineDeltas` で渡す (popup 再描画での 120 本再計算回避)。
- これで「ホロスコープ拠点タブ (出生地→現住所)」と「マップ地点タップ (現住所→候補地)」が同一の言葉・体験になる。

#### 検証
- flutter analyze クリーン / 新規 `test/horo_relocation_lines_test.dart` 8件 green
  (28本/conjunction限定/外惑星除外, **homeKm昇順**, 同一地点≈0, 移動で非ゼロ, 近→強まる・遠→やわらぐ中立, 度合い閾値, ハウスコメント)
  / 全テスト 295件 green。
- extract `+1 -2 ~5` (拠点) → `~2` (map_screen/popup 横展開) / audit **HARD 7 (新規ゼロ)**・未使用候補 0。
- 反映 = 次の AAB ビルド (Flutter のみ・Worker 変更なし)。

### 0.3 Horo「今日の占い」1 日 1 回固定 + プロンプト刷新 (2026-05-27)

> **設計の柱**: 「30 回までは OK」のような曖昧な防衛をやめ、「**1 日 1 回・変更しない**」を
> サーバ側で hard cap として強制する。プロフィール変更 / アプリ kill 再起動 / 出生時刻ずらし等の
> バイパスを全て無効化する。日付境界は端末の local TZ (= JST 0 時) を使う。

#### 設計判断
- **キャッシュキー**: `(app_user_id, local_date, category, lang)` の 4 タプル。プロフィール (出生情報)
  ハッシュは含めない = **プロフィール変更で結果は変わらない**。これが「変更しない事にする」の核心。
- **日付境界**: 端末の local TZ (`DateTime.now()` から生成した `YYYY-MM-DD`)。UTC 0 時だと JST 9 時で
  切替わって違和感が出るため。サーバはこの文字列をそのままキーに使う。
- **Free → Pro 昇格**: 別カテゴリは独立キーなので、同日中でも Pro 昇格で残り 4 カテゴリ追加生成可。
- **出生情報を誤登録していた既存ユーザ**: 翌日まで待つ (今日の reading は固定)。
- **匿名ユーザ (`__appUserId` 無し) / 不正 date 形式**: cache スキップ (機能は壊れない)。

#### プロンプト改訂 — ハウス偏重の根治
2026-05-25 deploy `21ae8c9` の 3 層化 (土台/主役/背景) だけでは「ハウスばかり」問題が残っていた。
実機で `wrangler tail` してデバッグログを観察した結果、`transitN=12 / progN=4 / hasHouses=true /
patternsActive=[]` と素材は十分にあるのに、prompt の構造的偏り (土台セクションが情報量 5+ vs 主役 0-3)
+ 「ハウスを織り込め」と明示命令 + 120-200 字の狭い枠、が原因で LLM がハウス語を優先していた。

**改訂内容** (fortune.js `buildPrompt`):
- **文字数拡張**: reading 120-200 → **200-300 字** / advice 40-80 → **130-180 字**。
- **明示指示の強化**: 「文章の中心は今日のトランジット相が出生天体をどう刺激しているか」+ 具体例
  「水星が出生火星にオポジション → 言葉に火花が散る」を構成ルールに含める。
- **ハウス頻度制限**: 「ハウスへの言及は任意・本文中で最大 1 回まで」「ハウス番号 (5H, 7H 等)
  や領域名 (恋愛/家庭/職場/結婚) を 2 回以上連発しない」と明示。
- **出生図アスペクト**: 「前提として最大 1 回・1 文以内」と縮約。
- **ニックネーム完全禁止** (2026-05-27 オーナー決定): `userName` を一切 prompt に渡さず、
  構成ルールに「名前・ニックネーム・敬称は冒頭も本文中も使うな・読者の呼び方は『あなた』または
  主語省略のみ」と明示。Worker は `userName` を受け取るが build に使わない (API surface は不変)。

**実機 before/after 検証**:
| 項目 | Before (旧プロンプト) | After (新プロンプト) |
|---|---|---|
| reading 文字数 | 約 170 字 | 約 240 字 |
| ハウス言及 | 3 回 (5H/8H/1H) | 1 回 (1H のみ) |
| トランジット相 | 1 件のみ | 4 件中心 |
| 出生図アスペクト | 多用 | 1 件のみ |
| 連発 | 領域名 3 つ | クリア |

#### 実装の所在 (層別)
- DO (層 0): `attestation_state.js` `fortune_readings` テーブル
  ((app_user_id, local_date, category, lang) PK + reading/advice/score/generated_at)
  + `_fortuneReadingGet` / `_fortuneReadingSet` メソッド。
  14 日より古い行は SET 時に毎回 cleanup (DAU 1500 × 5cat × 14日 ≒ 100K 行で頭打ち)。
  `ON CONFLICT DO NOTHING` で並行リクエスト安全 (初回勝ち)。
- Worker (層 0): `fortune.js` `handleFortune` が DO `/fortune-reading-get` を最初に叩き、
  hit ならそのまま返す (Gemini 呼ばない)。miss なら Gemini 呼出 → `/fortune-reading-set` で保存。
  `__appUserId` (middleware が注入) と `date` (端末 local) が両方揃ったときだけ cache 経由化。
- Flutter (層 2b): `fortune_cache.dart` `FortuneCacheRepo` は **そのまま残す** (= 「即時表示」の
  fast path として機能)。サーバ cache は「無駄な Gemini 呼出を完全に潰す」役割で、両者は補完関係。
- 検証: `worker/test/fortune.test.js` 9 件 (cache hit/miss / 別 category・lang・date は独立 /
  プロフィール変更でも同一結果 / appUserId 不在で cache スキップ等)。

#### 知っておくべき副次効果
- **クライアントの永続キャッシュバイパス手段**は技術的に可能 (Sanctuary で birth time を未使用値に
  変更 → アプリ kill → Horo 開く)。ただし server cache はそれでも同じ結果を返すため**実害なし**。
  以前は「30 回までは OK」の曖昧な防衛だったが、今は per-user per-day per-category per-lang で
  Gemini 呼出が 1 回に固定された (Free=1/日、Pro=5/日)。コストが完全に予測可能になった。
- **デバッグ用に「再生成したい」**: 当日中は不可 (server cache でロック)。翌日 0 時 (JST) で
  自然解禁。緊急時のみ wrangler で DO の該当行を削除する管理者操作で対応。

### 0.4 エンドポイント一覧 (13 個)

> 🔴 **この表は 2026-05-14 時点のスナップショット (旧 top-level path 表記)**。その後
> commit `ab79bbd` で `/public/*` `/protected/*` `/auth/*` `/webhooks/*` へ物理分離され、
> Phase 1 で App Attest / Play Integrity / RevenueCat Webhook / **アカウント削除
> (`/protected/account/delete` → DO `/account-purge`)** 等が追加された。
> **現在のエンドポイント全量 (機械抽出 = 28 path) は [`feature_inventory/00_worker.md`](feature_inventory/00_worker.md) が正典**。
> 下表は「Gemini 課金対象がどれか」の歴史的整理として残す。

| # | path | method | 用途 | Gemini | Flutter 呼出元 | 状態 |
|---|---|---|---|---|---|---|
| 1 | `/health` | GET | CF ヘルスチェック | - | (CF が叩く) | 健全・保持 |
| 2 | `/tiles/osm/*` | GET | OSM タイル中継 (`hot` のみ実利用、`standard`/`cyclosm` は allowlist 残置) | - | [map_styles.dart](../lib/screens/map/map_styles.dart), [map_screen.dart:368](../lib/screens/map_screen.dart) | 健全 |
| 3 | `/astro/chart` | POST | 出生図計算 (natal/transit/progressed + ASC/MC/DSC/IC + 全アスペクト) | - | [map_astro.dart](../lib/screens/map/map_astro.dart) (Map + Horo 共用の chart fetcher) | 健全・心臓 |
| 4 | `/astro/forecast` | POST | 日次スコア時系列計算 (1〜5 年) | - | [forecast_cache.dart](../lib/utils/forecast_cache.dart) | 健全 + KV 月次クォータ |
| 5 | `/astro/predict` | POST | (旧) 60 日アスペクト予測 | - | **(呼出なし)** | **死んだ endpoint** — [architecture.md:632](architecture.md) に「(未接続)」明記。test.js のみで参照 |
| 6 | `/astro/daily-transits` | POST | 1 日分の惑星 × 4 アングル (ASC/MC/DSC/IC) 通過時刻 + natal アスペクト併記 | - | [daily_transits_api.dart](../lib/utils/daily_transits_api.dart) | 健全 |
| 7 | `/astro/events` | GET | 月別天体イベント (ingress / retrograde / eclipse) | - | [celestial_events.dart](../lib/utils/celestial_events.dart) | 健全 |
| 8 | `/astro/line-narrative` | POST | (旧) A*C*G ラインの AI 解説 | あり | **(呼出なし)** | **死んだ endpoint** — [`project_solara_v7_integration.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_v7_integration.md) に「AI 解説撤去済み」。`line_narrative.js` ファイル本体も削除候補 |
| 9 | `/tz` | GET | 緯度経度 → IANA タイムゾーン名 | - | [solara_api.dart](../lib/utils/solara_api.dart) | 健全 |
| 10 | `/search` | GET | 場所名検索 (Google Places primary + Nominatim fallback) | - | [map_search.dart](../lib/screens/map/map_search.dart) | 健全 |
| 11 | `/fortune` | POST | カテゴリ別占い文 + リロケーション narrative 生成 | あり (gemini-2.5-flash) | [fortune_api.dart](../lib/utils/fortune_api.dart) | 健全 |
| 12 | `/tarot` | POST | タロットカード解説生成 (1 枚引き Phase A) | あり (TAROT_MODEL_PRIMARY env var) | [fortune_api.dart](../lib/utils/fortune_api.dart) | 健全 |
| 13 | `/relocation` | POST | リロケーション (出生地 → 現住所/引越し先) 解説生成 | あり | [fortune_api.dart](../lib/utils/fortune_api.dart) | 健全 |

### 0.5 死んだ endpoint の整理 (削除候補)

**Worker 側に残骸として存在するが、Flutter 側から呼ばれていない endpoint**:

#### `/astro/predict` (`computePredictions`)
- **証拠**:
  - [architecture.md:632](architecture.md) で「(未接続)」と明記
  - `lib/**` Grep 結果 = 0 件、`worker/test.js` のみで参照
- **削除アクション**:
  - [worker/src/astro.js:462-528](../worker/src/astro.js) の `computePredictions` 削除
  - [worker/src/index.js:5](../worker/src/index.js) の import から削除
  - [worker/src/index.js:246-253](../worker/src/index.js) のルート分岐削除
  - [worker/test.js:52-54](../worker/test.js) のテスト削除
  - [architecture.md:632](architecture.md) の表から行削除
- **インパクト**: 約 100 行削減。クライアント影響なし。

#### `/astro/line-narrative` (`handleLineNarrative`, `worker/src/line_narrative.js`)
- **証拠**:
  - [`project_solara_v7_integration.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_v7_integration.md) と [00_worker.md:13](feature_inventory/00_worker.md) の機械検出
  - Flutter 側 `map_line_narrative_sheet.dart` は 2026-05-11 以降「静的辞書のみ」に変更済み (= AI 呼出無し)
- **削除アクション**:
  - [worker/src/line_narrative.js](../worker/src/line_narrative.js) ファイル全削除 (266 行)
  - [worker/src/index.js:12](../worker/src/index.js) の import 削除
  - [worker/src/index.js:355](../worker/src/index.js) のルート分岐削除
- **インパクト**: 約 280 行削減。Gemini 呼出 1 系統撤去 (= 攻撃面減)。

**削除タイミング判断**: 課金実装 (Phase 1 Worker 物理分離) と同時に行う方が安全。それまでは「機能停止中だが Worker 側にコードが残っている」状態を許容。今すぐ削除しても害はないが、必須でもない。

### 0.6 ファイル別 役割表

| ファイル | 行 | 役割 | エクスポート | 外部依存 |
|---|---|---|---|---|
| [`index.js`](../worker/src/index.js) | 373 | メインルーター + CORS + Rate Limit + KV クォータ + OSM タイル中継 | (`fetch` handler) | `caches.default`, `FORECAST_KV` (任意 binding) |
| [`astro.js`](../worker/src/astro.js) | 882 | 天体計算エンジン (純数学) | `computeChart`, ~~`computePredictions`~~, `computeForecast`, `computeMonthEvents` | `astronomy-engine` npm |
| [`daily_transits.js`](../worker/src/daily_transits.js) | 273 | 拠点での 1 日分の惑星 × 4 アングル通過時刻 | `computeDailyTransits` | `astronomy-engine` (`SearchHourAngle`, `SearchRiseSet`) |
| [`fortune.js`](../worker/src/fortune.js) | 294 | Gemini 占い文生成 + カテゴリスコア計算 (`computeCategoryScore`) | `computeCategoryScore`, `callGemini`, `handleFortune` | Gemini API (`GEMINI_API_KEY`) |
| [`tarot.js`](../worker/src/tarot.js) | 200 | Gemini タロット解説生成 (モデル切替対応) | `handleTarot` | Gemini API (`GEMINI_API_KEY`), env `TAROT_MODEL_PRIMARY` / `_FALLBACK` |
| [`relocation.js`](../worker/src/relocation.js) | 183 | Gemini リロケーション解説生成 | `handleRelocation` | Gemini API (`GEMINI_API_KEY`) |
| [`search.js`](../worker/src/search.js) | 144 | Google Places (New) primary + Nominatim fallback | `searchPlace` | `GOOGLE_PLACES_KEY` (任意, 未設定なら Nominatim 直行) |
| [`tzlookup.js`](../worker/src/tzlookup.js) | 90 | bbox ヒューリスティック + 経度ベース fallback の IANA tz 推定 | `lookupTimezone` | (なし、自前テーブル) |
| ~~[`line_narrative.js`](../worker/src/line_narrative.js)~~ | 266 | ~~A*C*G ライン AI 解説~~ | ~~`handleLineNarrative`~~ | (削除候補) |

### 0.7 計算系の区分け (課金検討用)

層 0 の計算は **「Worker のみ実装」「Worker + Dart 並行実装」「Dart のみ実装」** の 3 種類が混在。Pro 機能境界を引くときに重要:

| 計算 | Worker | Dart 移植 | 備考 |
|---|---|---|---|
| Natal chart (出生図) | `computeChart` | (一部のみ) | 完全 Dart 移植は未完。現状は Worker 必須 |
| 12 ハウス (Placidus) + ASC/MC 任意座標再計算 | (computeChart 内) | [`astro_houses.dart`](../lib/utils/astro_houses.dart) | Phase M2 で Dart 完結 (リロケーション/ACG 用)。**Worker と Dart 両方で実装あり** |
| アスペクトライン (40 本コンジャンクション) | (computeChart 内) | [`astro_lines.dart`](../lib/utils/astro_lines.dart) | Phase M2 で Dart 完結 (ACG 描画のため)。**両方で実装あり** |
| Forecast (日次スコア時系列) | `computeForecast` | (なし) | Worker 必須、計算コストが高く KV クォータ対象 |
| Daily transits | `computeDailyTransits` | (なし) | Worker 必須 (`astronomy-engine` の SearchHourAngle/SearchRiseSet 依存) |
| 天体イベント (ingress/retrograde/eclipse) | `computeMonthEvents` | (なし) | Worker 必須 |
| Timezone lookup | `lookupTimezone` | (なし) | Worker 必須 (テーブルが大きい) |
| AI narrative 4 系 | `/fortune`, `/tarot`, `/relocation`, ~~`/line-narrative`~~ | (Gemini なので原理上クライアント実装不可) | **課金で守る最大対象** |
| Place 検索 | `/search` | (なし) | Google Places key 秘匿のため Worker 必須 |
| Map タイル | `/tiles/osm/*` | (なし) | UA 設定のため Worker 経由必須 |

**示唆**:
- Pro 機能を「クライアント完結」で作れば Worker コスト = 0 (例: 追加のアスペクトライン本数 120 本へ拡張 = `astro_lines.dart` だけで作れる)
- 一方、Pro 機能を AI narrative 拡張で作ると Gemini コスト線形増。**回数制限 (Free 5/day, Pro 100/day 等) で守らないと月額黒字化が崩れる**

### 0.8 Worker 側の運用ノート (重要)

- **CORS**: 開発時に `localhost` が許可されているので、ローカルでテスト可能
- **環境変数 (`wrangler secret put`)**:
  - `GEMINI_API_KEY` — 占い 4 系全部で使用
  - `GOOGLE_PLACES_KEY` — search、未設定なら Nominatim 直行
  - `TAROT_MODEL_PRIMARY`, `TAROT_MODEL_FALLBACK` — tarot モデル切替 (廃止リスク対策)
- **KV bindings**: `FORECAST_KV` — forecast 月次クォータ用。未設定なら `checkKvForecastQuota` は no-op
- **テスト**: [`worker/test.js`](../worker/test.js) で `computeChart` / `computePredictions` の単体実行可能 (`node test.js`)。**ただし `/astro/predict` 用テストは死んだ endpoint のため削除推奨**

### 0.9 機械抽出への参照

層 0 の機械抽出 raw: [`feature_inventory/00_worker.md`](feature_inventory/00_worker.md)
対整合チェック結果: [`feature_inventory/coverage_report.md`](feature_inventory/coverage_report.md)

---

## 層 1a: 純計算ユーティリティ

### 1a.1 概要

`lib/utils/` 配下の 5 ファイル / 計 1,424 行。**副作用なし** (http なし、storage なし、initialize なし)。
画面間で広く共有される数学・データ変換のみ。**Dart 完結 = Worker 呼出ゼロ**。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済): 当初は静的辞書ヘルパー 3 本 (`astro_glossary.dart`, `celestial_event_meanings.dart`, `planet_intro.dart`) も `Map<>` リテラル数ヒューリスティックで 1a に入っていたが、`extract.py` の `PATH_OVERRIDES` で 1b に明示移動。これにより 1a は「真の純計算ユーティリティのみ」を保持する状態に整理された。

### 1a.2 ファイル別 役割 + 呼出元 (5 本)

| # | ファイル | 行 | 役割 | 主要 export | 呼出元 (画面層) | 性質 |
|---|---|---|---|---|---|---|
| 1 | [`astro_math.dart`](../lib/utils/astro_math.dart) | 30 | 角度の正規化 + 最小角距離。重複検出 ([code_audit](../tools/code_audit/audit.py) T1) で 4 ファイル散在を集約 | `normalize360`, `angDist` | astro_lines, astro_houses, [map_astro](../lib/screens/map/map_astro.dart), [horoscope_screen](../lib/screens/horoscope_screen.dart), [horo_pattern_logic](../lib/screens/horoscope/horo_pattern_logic.dart) | **基礎中の基礎、全層が依存** |
| 2 | [`astro_houses.dart`](../lib/utils/astro_houses.dart) | 208 | LST 復元 + ASC/MC/Placidus 12 ハウス Dart 完結。Phase M2 (リロケーション/ACG) 用 | `HousesResult`, `calcHousesRelocate`, `cusp`, `assignPlanetHouse` | [map_relocation_popup](../lib/screens/map/map_relocation_popup.dart), [horoscope_screen](../lib/screens/horoscope_screen.dart), [horo_relocation_panel](../lib/screens/horoscope/horo_relocation_panel.dart), [horo_planet_table](../lib/screens/horoscope/horo_planet_table.dart) | **Worker `/astro/chart` と機能重複** (両方で実装あり) |
| 3 | [`astro_lines.dart`](../lib/utils/astro_lines.dart) | 588 | 40 本アスペクト線計算 (球面三角法) + Haversine 近接検出 + GMST 計算 | `AstroFrame`, `AstroLine`, `NearbyAstroLine`, `astroFrameKey`, `gmstHoursFromUtc`, `solarArcPlanets`, `buildAstroLines`, `buildAstroLinesAt`, `findNearbyLinesScreen` | Map のみ ([map_screen](../lib/screens/map_screen.dart), map_relocation_popup, [map_line_narrative_sheet](../lib/screens/map/map_line_narrative_sheet.dart), [map_astro_lines](../lib/screens/map/map_astro_lines.dart), [map_astro_carto](../lib/screens/map/map_astro_carto.dart)) | **Pro 候補の素材** — 「アスペクトライン 120 本拡張」は本ファイル拡張で作れる (Worker 不要) |
| 4 | [`direction_energy.dart`](../lib/utils/direction_energy.dart) | 238 | Soft/Hard 独立 2 エネルギーの中核データ構造 + アスペクト寄与の集約ロジック | `DirectionEnergy`, `EnergyMode`, `AspectContribution`, `AggregatedAspect`, `classify`, `scaledBy`, `aggregateContributions` | Map のみ ([map_screen](../lib/screens/map_screen.dart), [map_fortune_sheet](../lib/screens/map/map_fortune_sheet.dart), [map_direction_popup](../lib/screens/map/map_direction_popup.dart), [map_astro](../lib/screens/map/map_astro.dart)) | **設計思想の核** ([project_solara_design_philosophy](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md))。`total = soft + hard` 禁止 |
| 5 | [`moon_phase.dart`](../lib/utils/moon_phase.dart) | 360 | Jean Meeus アルゴリズム月相計算 (14 補正項、±2-3 分精度) | `MoonPhase`, `findPreviousNewMoon`, `findNextNewMoon`, `findFullMoonInCycle`, `getPhaseDay`, `isNewMoon`, `isFullMoon`, `getCycleTotalDays`, `getCurrentDayIndex`, `getCycleId`, `getIllumination` 等 | [observe_screen](../lib/screens/observe_screen.dart) (Tarot)、[galaxy_screen](../lib/screens/galaxy_screen.dart)、[galaxy_constellation_builder](../lib/screens/galaxy/galaxy_constellation_builder.dart)、[cycle_spiral_painter](../lib/widgets/cycle_spiral_painter.dart) | Map で未使用、Observe/Galaxy 専用 |

(旧 6〜8 行: `astro_glossary.dart` / `celestial_event_meanings.dart` / `planet_intro.dart` は層 1b にオーバーライド移動済 = 1b.2 表参照)

### 1a.3 課金検討に直結する示唆

**Pro 機能の素材としての価値**:

1. **`astro_lines.dart` 拡張 = Pro 機能の最有力候補** (Worker コスト 0)
   - 現状 40 本コンジャンクション → +ハード 90° + ソフト 120°/60° 追加で 120 本に拡張可能
   - メモリ ([project_solara_launch_checklist.md](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_launch_checklist.md)) Phase 3 で予定済み
   - **インパクト**: クライアント完結なので Gemini コスト無し、Worker 負荷増無し
   - **実装範囲**: 本ファイルに新規 aspect angle 定数 + `buildAstroLines` の loop 拡張

2. **`astro_houses.dart` は Worker `/astro/chart` と機能重複**
   - 現状の Map では Worker 計算結果をそのまま使うことが多く、`astro_houses.dart` はリロケーション (本拠点 ≠ 出生地) でのみ稼働
   - Pro 機能化するなら「無制限リロケーション」が候補だが、現状でも稼働するため Pro 化の理由は弱い
   - **Worker 重複コードは保守コスト**: 今後どちらかに寄せる検討の余地あり (Dart 側に寄せれば Worker 軽量化 + オフライン耐性)

3. **`direction_energy.dart` の設計思想は譲れない**
   - `total` / `softRatio` 禁止 = UI で 1 軸表現に丸めない
   - 課金訴求文で「2 エネルギー独立評価」を売りにすることは可能 (差別化軸)
   - ただし「占い的吉凶判定をしない」のは無料機能にも適用 = Pro/Free の境界には使えない

4. **`moon_phase.dart` は Galaxy/Observe 専用**
   - Map 系の Pro 機能では使われない
   - Observe (Tarot) の Pro 拡張 (3 枚引き/5 枚引き、[project_tarot_v2_plan](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_tarot_v2_plan.md)) で月相加味の占い文を Gemini に投げる場合に活用余地

### 1a.4 Worker との重複コード (運用上の注意)

`astro_houses.dart` と `astro_lines.dart` は Worker 側の同等機能と並行実装になっている。
**検証済み精度** ([architecture.md](architecture.md)):
- 引越し計算: 全 6 ペア最大誤差 0.0122° (閾値 0.5° の 1/40)
- アスペクト線: 全 80 ケース最大誤差 0.01°

二重実装の理由 (記録):
- Phase M2 で Map タップ <50ms の高速応答を実現するため、 Worker 経由を避けて Dart 完結
- 検証用に Worker 側を残し、結果が一致することを `worker/verify_phase_m2*.py` で確認

**将来の判断ポイント**:
- 同期し続けるコスト vs どちらかを単一実装にするメリット
- 「Worker 純計算系を順次 Dart に寄せて Worker を AI 仲介専用にする」案は Pro 公開時のセキュリティ整理 (`/protected/*`) と整合する

### 1a.5 機械抽出への参照

層 1a の機械抽出 raw: [`feature_inventory/01a_pure_calc.md`](feature_inventory/01a_pure_calc.md)

---

## 層 1b: 静的データ辞書

### 1b.1 概要

`lib/utils/` 配下 + `screens/map/` + `screens/horoscope/` 由来の **11 ファイル / 計 3,830 行**。**静的データが主体** で関数は辞書取り出しヘルパーが中心。副作用なし (= 層 1a と同じく純粋)、ただし「計算」というより「世界観テキストの貯蔵庫」。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済):
- ヒューリスティック検出だけだと 5 ファイルだったが、`PATH_OVERRIDES` で 1a → 1b に 3 本、4a → 1b に 1 本、4b → 1b に 2 本を明示移動 = 計 11 本
- 移動した 6 本: `astro_glossary.dart` / `celestial_event_meanings.dart` / `planet_intro.dart` (1a 由来) + `daily_transit_data.dart` (4a 由来) + `horo_constants.dart` / `horo_aspect_description.dart` (4b 由来)

### 1b.2 ファイル別 役割 + 呼出元 (11 本)

| # | ファイル | 行 | 内容 | 主要 export | 呼出元 (画面層) | 特記 |
|---|---|---|---|---|---|---|
| 1 | [`astro_zenith_messages.dart`](../lib/utils/astro_zenith_messages.dart) | 170 | 天頂点 (Zenith Point) 解説メッセージ辞書。MC ライン上で観測者真上に来る唯一の地点の解説 | `ZenithMessage` | [map_astro_carto](../lib/screens/map/map_astro_carto.dart) (ACG モード専用) | ACG 天頂マーカータップ時に表示 |
| 2 | [`constellation_namer.dart`](../lib/utils/constellation_namer.dart) | 626 | 星座名生成 v2 (形容詞 × 名詞)、Prim MST 構築、エッジ生成、レア度算出、HUE シフト | `ConstellationNamer`, `buildName`, `rarityPercentage`, `hueShift`, `adjColor`, `computeMST`, `buildEdges`, `isFlipX`, `artAssetPath` | Galaxy 5 ファイル + [constellation_painter](../lib/widgets/constellation_painter.dart), [catasterism_formation_overlay](../lib/widgets/catasterism_formation_overlay.dart) | **計算ロジック比率高め** — 1a 寄りの側面あり (機械分類が辞書判定したのは形容詞/名詞テーブルの大きさ)。Galaxy の世界観 (= 月相サイクルの「刻星化」演出) の心臓 |
| 3 | [`cycle_story_texts.dart`](../lib/utils/cycle_story_texts.dart) | 86 | 月齢サイクル (新月/満月/刻星化) のストーリーテキスト JP/EN | `CycleStoryTexts`, `getNewMoon`, `getFullMoon`, `getCatasterism` | [new_moon_overlay](../lib/widgets/new_moon_overlay.dart), [full_moon_overlay](../lib/widgets/full_moon_overlay.dart), [catasterism_overlay](../lib/widgets/catasterism_overlay.dart) | JP/EN ネイティブ別書き (翻訳ではない)。`_isJapanese()` で切替 |
| 4 | [`solara_manifesto.dart`](../lib/utils/solara_manifesto.dart) | 141 | Solara 設計思想テキスト (3 セクション: 世界観 / 2 エネルギー / 委ねる宣言) | `SolaraManifesto`, `SolaraManifestoSection`, `getSections` | [solara_philosophy_screen](../lib/screens/solara_philosophy_screen.dart) のみ | 「占い的吉凶判定をしない」を文章化したアプリの哲学的根幹 ([project_solara_design_philosophy](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md)) |
| 5 | [`title_data.dart`](../lib/utils/title_data.dart) | 395 | 144 称号システムデータ (12 太陽部位 × 12 月部位 + 25 class) + 太陽/月星座近似算出 | `TitleClass`, `getSunSign`, `getMoonSign` | [class_card](../lib/widgets/class_card.dart), [sanctuary_screen](../lib/screens/sanctuary_screen.dart), [sanctuary_title_diagnosis](../lib/screens/sanctuary/sanctuary_title_diagnosis.dart), [class_share_card](../lib/screens/sanctuary/class_share_card.dart) | **EN 版 144 称号未実装** ([project_solara_title_system](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_title_system.md)) |
| 6 | [`astro_glossary.dart`](../lib/utils/astro_glossary.dart) | 586 | 占星術専門用語の解説辞書 + popup 表示ヘルパー (50+ エントリ: asc/mc/house/aspect/relocation/transit_acg 等) | `AstroGlossaryEntry`, `astroGlossary`, `showAstroGlossaryDialog` | [astro_term_label](../lib/widgets/astro_term_label.dart)、Map の popup 6 種、[map_relocation_popup](../lib/screens/map/map_relocation_popup.dart)、[map_line_narrative_sheet](../lib/screens/map/map_line_narrative_sheet.dart) | (1a→1b オーバーライド済) `showInfoPopup` 経由で説明 popup を表示 |
| 7 | [`celestial_event_meanings.dart`](../lib/utils/celestial_event_meanings.dart) | 52 | 天体イベント (ingress/retrograde/eclipse/conjunction/node_shift) の占星術的意味辞書 | `getEventMeaningJP` | [celestial_event_bar](../lib/widgets/celestial_event_bar.dart) のみ | (1a→1b オーバーライド済) `/astro/events` 取得結果の表示用 |
| 8 | [`planet_intro.dart`](../lib/utils/planet_intro.dart) | 559 | 10 惑星の Map マーカータップ説明テキスト (natal/transit/progressed 3 フレーム × 10 惑星 = 30 パターン) | `PlanetIntroFrame`, `PlanetIntro`, `frameOf` | [map_screen](../lib/screens/map_screen.dart)、[map_planet_intro_popup](../lib/screens/map/map_planet_intro_popup.dart) | (1a→1b オーバーライド済) Map 惑星マーカータップ時の説明源 |
| 9 | [`daily_transit_data.dart`](../lib/screens/map/daily_transit_data.dart) | 1,013 | Daily Transit 画面用 静的データ大容量: `AngleFilter` enum + ラベル/セット/意味マップ + `CategoryFilterTips` (5 カテゴリ × 外向き/内向き各 4 tips) + `planetAngleBaseText` (10 惑星 × 4 アングル = 40 パターン基本意味) + `categoryAppendix` + `categoryPlanetSets` | `AngleFilter`、`angleFilterLabel/Set/Meaning`、`CategoryFilterTips`、`planetAngleBaseText`、`categoryAppendix`、`categoryPlanetSets` | [map_daily_transit_screen](../lib/screens/map/map_daily_transit_screen.dart) のみ | (4a→1b オーバーライド済) 物理的には `screens/map/` 配下だが、実態は静的辞書。Worker `fortune.js` の `categoryPlanetSets` と一致 (要同期保守) |
| 10 | [`horo_constants.dart`](../lib/screens/horoscope/horo_constants.dart) | 86 | Horoscope 系の共有静的データ: `signs` (12 星座記号)、`signNames`、`signColors`、`planetGlyphs` (10 惑星 Unicode 記号)、`planetNamesJP`、`fortuneCategories` (5 カテゴリ)、`aspectSymbol`、`aspectTypes` (8 種 × angle/orb/quality/color)、`planetGroups` (personal/social/generational/angle)、`angleNamesJP`、`patternOrbSettings`、`patternStyles`、`fortunePlanets` | (上記全部 const) | **13 ファイル横断** ([map_relocation_popup](../lib/screens/map/map_relocation_popup.dart), [map_line_narrative_sheet](../lib/screens/map/map_line_narrative_sheet.dart), Horo 系 9 ファイル, [galaxy_screen](../lib/screens/galaxy_screen.dart) ほか) | (4b→1b オーバーライド済) 物理的には `screens/horoscope/` 配下だが、実態は cross-screen 静的辞書。`fortunePlanets` は UI フィルタチップ用 (Fortune API 用は別) |
| 11 | [`horo_aspect_description.dart`](../lib/screens/horoscope/horo_aspect_description.dart) | 116 | アスペクト説明生成: `planetInfo` (14 惑星/アングル × theme/keywords) + `aspectInfo` (8 アスペクト × name/angle/quality/summary) 静的辞書 + `buildAspectDescription` 1 関数 (惑星 + アスペクトから 3 セクション解説生成) | `planetInfo`, `aspectInfo`, `buildAspectDescription` | [map_aspect_chip](../lib/screens/map/map_aspect_chip.dart) (Daily Transit)、[horo_aspect_list](../lib/screens/horoscope/horo_aspect_list.dart)、[horo_prediction_panel](../lib/screens/horoscope/horo_prediction_panel.dart) | (4b→1b オーバーライド済) Map+Horo 共用、`buildAspectDescription` は純関数 |

### 1b.3 課金検討に直結する示唆

1. **`title_data.dart` の称号システムは Sanctuary タブの中核資産**
   - 144 称号 × class 25 = ユーザーごとの「あなただけの結果」を作る差別化要素
   - **EN 版未実装** がストア海外展開の遅延要因 ([feedback_i18n_last](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_i18n_last.md) ルールでリリース直前まで保留中)
   - 称号関連の Pro 拡張案 (例: 称号 SHARE カードの追加デザイン、月別称号変化追跡など) は本データを土台にできる

2. **`constellation_namer.dart` は Galaxy の心臓部 — Pro 候補としては弱い**
   - 既に「2026-04-25 v2 完成」状態、Pro/Free 境界に置きづらい (= Galaxy タブの基本体験)
   - 拡張余地: 「刻星化アルバム」「履歴の検索」など Pro 案 ([project_galaxy_spec](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_galaxy_spec.md))

3. **`solara_manifesto.dart` の世界観テキストは「課金訴求文」と直接対応**
   - 「占い的吉凶判定をしない、両面思想」= 既存占いアプリ群との差別化軸
   - ストア説明文・ペイウォール訴求文・公式 LP の表現に流用可能 (= マーケ素材として価値)

4. **`astro_zenith_messages.dart` は ACG モード専用 = 海外展開時の鍵**
   - 国内: マニア向け β機能
   - 海外: Solara のメイン売り (英米圏で A*C*G の歴史と認知あり、[`project_solara_astrocartography_m2`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_astrocartography_m2.md))
   - 天頂点ごとのカスタム解説は Pro 機能化候補 (例: 出生図に基づくパーソナライズ天頂点メッセージ)

### 1b.4 機械抽出への参照

層 1b の機械抽出 raw: [`feature_inventory/01b_static_data.md`](feature_inventory/01b_static_data.md)

---

## 層 1c: モデルクラス

### 1c.1 概要

`lib/models/` 配下の 4 ファイル / 計 337 行。永続化対象データの **plain Dart class** (Riverpod や json_serializable は未使用、手書きの `toJson` のみ)。
**全て Observe (Tarot) または Galaxy 専用** — Map / Horo / Sanctuary タブからは参照無し。

### 1c.2 ファイル別 役割 + 呼出元 (4 本)

| # | ファイル | 行 | class | 用途 | 呼出元 |
|---|---|---|---|---|---|
| 1 | [`daily_reading.dart`](../lib/models/daily_reading.dart) | 41 | `DailyReading` | タロット 1 日 1 引きキャッシュ (cardId, reversed, reading, stella, drawnAt) | [tarot_data](../lib/utils/tarot_data.dart), [solara_storage](../lib/utils/solara_storage.dart), Observe 系 3 ファイル |
| 2 | [`galaxy_cycle.dart`](../lib/models/galaxy_cycle.dart) | 119 | `ConstellationDot`, `GalaxyCycle` | 銀河の 1 サイクル分のデータ (新月→満月→刻星化、星座ドット配列) | [solara_storage](../lib/utils/solara_storage.dart), Galaxy 系 5 ファイル + cycle/constellation widgets |
| 3 | [`lunar_intention.dart`](../lib/models/lunar_intention.dart) | 105 | `LunarIntention`, `MidpointCheck`, `CatasterismResult` | 新月で選んだ意図 + 満月の中間チェック + 刻星化評価 | [solara_storage](../lib/utils/solara_storage.dart), Galaxy 系 + moon overlay widgets |
| 4 | [`tarot_card.dart`](../lib/models/tarot_card.dart) | 72 | `TarotCard` | 78 枚タロットカードの定義 (id, nameJP, keyword, element, planet, suit, number 等) | [tarot_data](../lib/utils/tarot_data.dart), Observe 系 |

### 1c.3 課金検討に直結する示唆

1. **永続化対象 = ユーザーの「履歴」「経験」=Solara の最大の差別化資産**
   - DailyReading, GalaxyCycle, LunarIntention, CatasterismResult はユーザーごとの体験ログ
   - クラウドバックアップ機能 (Pro 候補) はこれらの保存先 = どれを優先的にバックアップするかが設計判断
   - 削除/エクスポート/インポートも本クラス群を中心に組み立てる

2. **`TarotCard` は静的データ (78 枚固定) で、Pro 拡張対象ではない**
   - Pro 拡張は「3 枚引き / 5 枚引きスプレッド」「カード履歴の検索」など別所
   - 本 class 自体は変更不要

3. **`LunarIntention` + `CatasterismResult` は Galaxy 体験の核 — 静かな差別化**
   - 「占いをしない、意図と振り返りの記録」という Solara 独自の体験設計の中心
   - Pro 拡張: 過去サイクルのアルバム、月別ハイライト、テキストエクスポート (`getCatasterismMD` 等) が候補

4. **モデル層がここまで小さい (337 行) = 設計が素直で保守容易**
   - 永続化スキーマ拡張の影響範囲が把握しやすい
   - 課金で新たな永続化対象 (例: Pro 限定の有料カード履歴) を追加する場合、本層に class を 1〜2 個足すだけで済む

### 1c.4 機械抽出への参照

層 1c の機械抽出 raw: [`feature_inventory/01c_models.md`](feature_inventory/01c_models.md)

---

## 層 2a: API/Worker ラッパ

### 2a.1 概要

`lib/utils/` 配下 + `screens/map/map_astro.dart` (オーバーライド経由) の **7 ファイル / 計 1,440 行**。**Worker ↔ Flutter の通信境界**。
ここを把握すれば「課金時に `/protected/*` に移すべき呼出元」が全部見える。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済): `screens/map/map_astro.dart` (508 行、`/astro/chart` ラッパ) は当初 4a 検出だったが `PATH_OVERRIDES` で 2a に明示移動。Map と Horoscope が両方 import する横断利用ファイルが本層に正しく入る状態に整理された。

### 2a.2 ファイル別 役割 + 呼出 endpoint + 呼出元 (7 本)

| # | ファイル | 行 | 呼出先 endpoint | 呼出元 (主要) | 特記 |
|---|---|---|---|---|---|
| 1 | [`solara_api.dart`](../lib/utils/solara_api.dart) | 35 | `/tz` (GET) + `solaraWorkerBase` 定数 export | `sanctuary_profile_editor`, `horo_birth_panel`, Map 各所 | **`solaraWorkerBase` 定数の出元** ([`project_solara_worker_url.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_worker_url.md) ハードコード禁止)。`fetchTimezoneName` 1 関数のみ |
| 2 | [`fortune_api.dart`](../lib/utils/fortune_api.dart) | 250 | **`/fortune`, `/relocation`, `/tarot`** (POST × 3、全て Gemini 系) | [horoscope_screen](../lib/screens/horoscope_screen.dart), [observe_screen](../lib/screens/observe_screen.dart), [horo_fortune_cards](../lib/screens/horoscope/horo_fortune_cards.dart), [horo_relocation_panel](../lib/screens/horoscope/horo_relocation_panel.dart) | **課金で守るべき最大対象 = Gemini 呼出 3 系統がここに集中**。Pro 公開時に `/protected/*` 移行 + 回数制限の中心 |
| 3 | [`daily_transits_api.dart`](../lib/utils/daily_transits_api.dart) | 241 | `/astro/daily-transits` (POST) | [map_daily_transit_screen](../lib/screens/map/map_daily_transit_screen.dart), [map_aspect_chip](../lib/screens/map/map_aspect_chip.dart) | F1 機能、課金で「無制限拠点切替」の Pro 化候補 |
| 4 | [`celestial_events.dart`](../lib/utils/celestial_events.dart) | 314 | `/astro/events` (GET) | [main.dart](../lib/main.dart) (起動 initialize)、[new_moon_overlay](../lib/widgets/new_moon_overlay.dart)、[full_moon_overlay](../lib/widgets/full_moon_overlay.dart)、[celestial_event_bar](../lib/widgets/celestial_event_bar.dart)、[galaxy_screen](../lib/screens/galaxy_screen.dart) | **singleton 的に initialize**、機械分類は 2a だが層 2c 寄りの側面あり (= 層 2c.4 と整合) |
| 5 | [`reverse_geocode.dart`](../lib/utils/reverse_geocode.dart) | 50 | **Nominatim 直叩き** (`nominatim.openstreetmap.org/reverse`) | [map_vp_panel](../lib/screens/map/map_vp_panel.dart)、[horo_birth_panel](../lib/screens/horoscope/horo_birth_panel.dart) | **🔴 重要**: 唯一 Worker 経由でない外部 API 呼出。Nominatim は無料 + key 不要 + 1 req/sec 制限。Pro 公開時にレートリミット遵守 + UA 設定確認が必要 |
| 6 | [`tile_http_client.dart`](../lib/utils/tile_http_client.dart) | 42 | (Worker URL 自体は呼出さず、共有 HttpClient のみ提供) | [map_screen](../lib/screens/map_screen.dart) (`sharedTileHttpClient`)、[map_styles](../lib/screens/map/map_styles.dart) | **fd 枯渇対策** ([`feedback_http_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_http_fd_leak.md), [`project_solara_a101fc_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_a101fc_fd_leak.md))。maxConnectionsPerHost=6, idleTimeout=15s |
| 7 | [`screens/map/map_astro.dart`](../lib/screens/map/map_astro.dart) | 508 | **`/astro/chart`** (POST) + 16 方位スコア計算 | [map_screen](../lib/screens/map_screen.dart) (Map 描画の心臓)、[horoscope_screen](../lib/screens/horoscope_screen.dart) (`fetchChart` 共用) | (4a→2a オーバーライド済) **🔴 Map+Horo 共用の chart fetcher**。`ChartResult` (natal+transit+progressed+ASC/MC/DSC/IC + 全アスペクト)、`ScoreResult` (16 方位 × 5 カテゴリ Soft/Hard)、`fetchChart`、`scoreAll`、`isAngle`、`addT/addP/addCT/addCP`。リファクタ候補 (将来 `lib/utils/astro_chart_api.dart` への移動) |

### 2a.3 Worker endpoint との対応マップ (層 0 ↔ 層 2a)

| Worker endpoint | 層 2a ラッパ | Flutter 呼出元 |
|---|---|---|
| `/astro/chart` | `screens/map/map_astro.dart`'s `fetchChart` (2a オーバーライド済) | Map + Horoscope |
| `/astro/forecast` | [`forecast_cache.dart`](../lib/utils/forecast_cache.dart) (機械分類 2b、永続化込み) | Forecast 画面 |
| `/astro/predict` | **(ラッパなし)** | **死んだ endpoint** (層 0.4 で削除候補) |
| `/astro/daily-transits` | `daily_transits_api.dart` | Map Daily Transit |
| `/astro/events` | `celestial_events.dart` | main + Galaxy + 月相 overlay |
| `/astro/line-narrative` | **(ラッパなし、撤去済み)** | **死んだ endpoint** (層 0.4) |
| `/tz` | `solara_api.dart` | Sanctuary + Horo Birth |
| `/search` | (`map_search.dart` 直叩き、層 4a 分類) | Map 検索 |
| `/fortune` | `fortune_api.dart` | Horo + Observe |
| `/tarot` | `fortune_api.dart` | Observe |
| `/relocation` | `fortune_api.dart` | Horo (リロケーション) |
| `/tiles/osm/*` | `map_styles.dart` 直叩き (4a 分類) + `tile_http_client.dart` 共有 client | Map タイル描画 |
| `/health` | (Flutter 呼出なし) | CF が叩く |

**観察**:
- **Worker 経由でない直叩き**: `reverse_geocode.dart` (Nominatim)
- **ラッパが `lib/utils/` にない呼出**: `/search` (map_search.dart は 4a)、`/tiles/*` (map_styles.dart は 4a)
  - = 課金実装時に「`screens/map/` 配下の Worker 呼出箇所」も同等にチェック必須
- **オーバーライドで 2a 入りした例外**: `/astro/chart` (map_astro.dart) は物理的に `screens/map/` だが層は 2a

### 2a.4 課金検討に直結する示唆

1. **Gemini 呼出 3 系統が `fortune_api.dart` に集中** → 一括で `/protected/*` 移行可能、扱いやすい
   - 回数制限 (Free 5/day, Pro 100/day 等) の実装も本ファイル + Worker `/fortune`, `/tarot`, `/relocation` の中央で行う
   - **本ファイルの行数 (250 行) = Pro 課金の中心**

2. **`reverse_geocode.dart` (Nominatim 直叩き) は Pro 公開時に判断が必要**
   - 案 A: そのまま (= Nominatim 利用規約遵守、 UA 設定確認のみ)
   - 案 B: Worker 経由化 (`/reverse-geocode` 新規) で UA / レートリミット制御を Worker 側に集約
   - **私の推奨**: 案 B (= 攻撃面・運用面を Worker に集約)。実装コスト ~1h

3. **`celestial_events.dart` の起動 initialize は Free でも稼働させる必要**
   - main.dart で `await CelestialEvents.initialize()` = 起動時に必ず呼ばれる
   - 「無料ユーザーも天体イベントバーは表示」想定なので、`/astro/events` は `/public/*` 配下

4. **`/astro/chart` ラッパが `screens/map/` に物理的にある = 設計上の歪み**
   - `screens/map/map_astro.dart` から Horoscope が import している = Map ↔ Horo の意外な結合
   - オーバーライドで層 2a に明示移動済だが、**物理 path は未移動** = リファクタ余地あり
   - 課金実装でリファクタする好機 (ラッパを `lib/utils/astro_chart_api.dart` に切り出し)

### 2a.5 API レスポンスモデル一覧 (Worker JSON ↔ Dart 型の境界)

層 2a の各ラッパが返す **レスポンス型 / 中間モデル**。Worker の JSON をデコードした Dart 側の正規型で、画面層 (4a〜4f) はこれらを受け取って描画する。Pro 化で Worker レスポンスにフィールドを足すときは、この型も同時に更新する。

| モデル | 定義ファイル | 役割 |
|---|---|---|
| `ChartResult` | `map_astro.dart` | `/astro/chart` のレスポンス。natal + transit + progressed + ASC/MC/DSC/IC + 全アスペクト |
| `ScoreResult` | `map_astro.dart` | `ChartResult` → 16 方位 × 5 カテゴリ × Soft/Hard スコア (Map 描画用) |
| `CelestialEvents` | `celestial_events.dart` | `/astro/events` の取得 + キャッシュを担う singleton 的サービス (起動時 `initialize`) |
| `MonthEvents` | `celestial_events.dart` | 1 ヶ月分の天体イベント集合。`copyWithEvents` で API 実計算結果に差し替え可 |
| `CelestialEvent` | `celestial_events.dart` | 1 イベント (ingress / retrograde / eclipse 等) |
| `TransitAspect` | `daily_transits_api.dart` | その瞬間にトランジット惑星が natal 惑星と作るアスペクト |
| `TransitEvent` | `daily_transits_api.dart` | ある惑星が 4 アングル (ASC/MC/DSC/IC) のどれか 1 つを通過した瞬間 |
| `PlanetDailyTransits` | `daily_transits_api.dart` | 1 惑星 × 1 日分の通過イベント (最大 4 個) |
| `LatitudeBandHit` | `daily_transits_api.dart` | 緯度帯ヒット惑星 (Lewis 流の緯度効果) |
| `LatitudeBand` | `daily_transits_api.dart` | 観測時刻における緯度帯セクション (zenith / nadir のヒット惑星 + オーブ) |
| `DailyTransitsResult` | `daily_transits_api.dart` | `/astro/daily-transits` の完全レスポンス (`flatTimeline` で時刻順フラット化可) |
| `FortuneReading` | `fortune_api.dart` | `/fortune` のレスポンス (Gemini 生成の占い文) |
| `RelocationNarrative` | `fortune_api.dart` | `/relocation` のレスポンス (リロケーション解説) |
| `TarotReading` | `fortune_api.dart` | `/tarot` のレスポンス (1 枚引き Reading) |
| `ConsultationRequest` | `consultation_v2_api.dart` (+`consultation_v2_request.dart` part) | `/astro/consultation2` への最小入力 (誕生+自宅+5問 theme/mode/when/scope/withWhom/wish+isFirst+excluded)。client は候補生成せず Worker が全計算 (V2 全要素統合、2026-05-24) |
| `ConsultationV2Result` / `ConsultationV2Reading` / `ConsultationV2Candidate` / `ConsultationEvidence` / `ConsultationTimeWindow` | `consultation_v2_api.dart` | `fetchConsultationV2` の戻り。候補 1 つ + evidence + 初回のみ innerSeason/intro/outro + timeWindow + 残量。exhausted / 402 `ConsultationBlock` / 接続失敗を区別。「別の候補地」= excluded を足して再呼び出し (1 クレジット=1 候補) |
| `ConsultationCreditStatus` / `ConsultationBlock` | `consultation_api.dart` (スリム化) | クレジット残状況 + 402 paywall 理由。V2 と共有。旧 `consultation_engine.dart` / `fetchConsultation` / `ConsultationReading` は撤去 (2026-05-24 V2 移行) |

### 2a.6 機械抽出への参照

層 2a の機械抽出 raw: [`feature_inventory/02a_api_wrappers.md`](feature_inventory/02a_api_wrappers.md)

---

## 層 2b: 永続化/キャッシュ

### 2b.1 概要

`lib/utils/` 配下、**shared_preferences 等の storage import あり** の 3 ファイル / 計 907 行。
**Solara のほぼ全画面が依存** (Grep で 25 ファイルが import) = 永続化はアプリの中央集権。

### 2b.2 ファイル別 役割 + 呼出元 (4 本)

| # | ファイル | 行 | 役割 | 呼出元 |
|---|---|---|---|---|
| 1 | [`solara_storage.dart`](../lib/utils/solara_storage.dart) | 622 | **永続化中央集権ファイル**。SolaraProfile, Reading 履歴, Intention, dailyResetHour/Minute, Map style, Forecast 設定, overlay state, notTodayCount + 無料タロット日次ガード (`logicalTodayKey` / `hasDrawnFreeTarotToday` / `markFreeTarotDrawn`) 等 | main.dart + 全画面 (Sanctuary / Map / Horo / Observe / Galaxy / Forecast / Locations) + moon overlay 系 widgets |
| 2 | [`forecast_cache.dart`](../lib/utils/forecast_cache.dart) | 462 | **`/astro/forecast` 呼出 + 永続化キャッシュ + クールダウン + ◯◯期検出**。`ForecastDay`, `LifePeriod`, `ForecastCache`, `ForecastRepo`、`detectLifePeriods` (運勢サイクル抽出ロジック) | [forecast_screen](../lib/screens/forecast_screen.dart), [forecast_life_periods](../lib/screens/forecast/forecast_life_periods.dart), [forecast_top5](../lib/screens/forecast/forecast_top5.dart), [galaxy_screen](../lib/screens/galaxy_screen.dart) (?) |
| 3 | [`app_locale.dart`](../lib/utils/app_locale.dart) | 41 | 言語切替 (端末/JP/EN) の global singleton。SharedPreferences で永続化 | main.dart (`AppLocale.instance.load()`) + 言語表示する全画面 |
| 4 | [`fortune_cache.dart`](../lib/utils/fortune_cache.dart) | — | **Horo「今日の占い」の永続日次キャッシュ** (`FortuneCacheRepo`)。プロフィールハッシュ + 当日日付でカテゴリ別 `FortuneReading` を保存。再起動後も同日は fetchChart/fetchFortune をスキップ = Gemini コスト削減 (2026-05-25)。`profileHashOf` は forecast_cache から流用 | [horoscope_screen](../lib/screens/horoscope_screen.dart) `_loadFortunes` |

### 2b.3 機械分類の盲点 — `forecast_cache.dart` は実態が 2a/2b ハイブリッド

`forecast_cache.dart` は **`/astro/forecast` 呼出 (API ラッパ) + キャッシュ (永続化) + 解析 (`detectLifePeriods`)** を 1 ファイルで全部やっている。
本来は分けるべきだが、現状の Solara はこの一体型を採用。 機械分類は shared_preferences import を理由に 2b 判定したが、API ラッパとしての側面 (= 層 2a) も持つ。

これは設計判断の話で、リファクタ候補 (分割) ではあるが、現状の 462 行で 1 ファイル管理は許容範囲。

### 2b.4 課金検討に直結する示唆

1. **`solara_storage.dart` がアプリ状態の全てを握っている = クラウドバックアップ Pro 候補の中心**
   - 32 個の load/save 関数全部がバックアップ対象になりうる
   - Pro 機能: 「設定とサイクル履歴の自動バックアップ」「機種変更時の引き継ぎ」
   - 実装手段: 本クラスに `exportAll() / importAll()` を追加、Firebase Auth + Firestore か CF Worker KV 経由

2. **`forecast_cache.dart` の KV 月次クォータ (Worker 側 60/IP/month) が Pro 課金の自然な境界**
   - Free: 月 60 回まで (1 日 2 回程度)
   - Pro: 無制限 (rate limit のみ)
   - 実装は `checkKvForecastQuota` ([worker/src/index.js:73](../worker/src/index.js)) の bypass 条件追加だけ

3. **`detectLifePeriods` (運勢サイクル検出) は無料機能の差別化要素**
   - 365 日分のスコアから「◯◯期」を自動抽出する独自アルゴリズム ([architecture.md](architecture.md))
   - Pro 機能で「過去 5 年の◯◯期一覧」「来年予測の精密化」拡張案が考えられる

4. **`app_locale.dart` は i18n フェーズで本格稼働**
   - 現状: jp/en の 2 言語 ([main.dart:42](../lib/main.dart))
   - 実装は singleton で問題なし。Pro 公開で英語版リリース ([feedback_i18n_last](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_i18n_last.md)) と直結

### 2b.5 主要モデル — `SolaraProfile`

`SolaraProfile` は Solara の**中核データモデル** (出生情報 = 生年月日時 + 出生地緯度経度 + 名前 + 称号結果等)。
ほぼ全画面がこれを起点に動く (未設定なら占い系オーバーレイは全て非表示)。

**機械分類の盲点**: `SolaraProfile` は `models/` (層 1c) ではなく **`solara_storage.dart` (層 2b) 内に定義**されている。永続化ロジックとモデル定義が同一ファイルに同居している状態。リファクタするなら `models/solara_profile.dart` への切り出し候補だが、現状 storage と密結合で運用問題はないため放置許容。

関連モデル: `forecast_cache.dart` 内の `ForecastDay` / `LifePeriod` / `ForecastCache` / `ForecastRepo` も同様に「永続化ファイル内にモデル定義」パターン (2b.3 で既述のハイブリッド構造の一部)。

### 2b.6 機械抽出への参照

層 2b の機械抽出 raw: [`feature_inventory/02b_persistence.md`](feature_inventory/02b_persistence.md)

---

## 層 2c: グローバル singleton

### 2c.1 概要

`lib/utils/` 配下、**initialize/load で起動時に bundled asset を読む 1 ファイル / 55 行**。

機械分類は厳密には 1 ファイルだが、意味的には:
- 層 2a の **`celestial_events.dart`** (起動 initialize、`/astro/events` キャッシュ)
- 層 2b の **`app_locale.dart`** (起動 load、SharedPreferences)

も singleton 的振る舞いで、本層と類似の役割。Solara のグローバル singleton は実質 3 つあると見るのが正確。

### 2c.2 ファイル別 役割 + 呼出元 (1 + 概念上 2)

| # | ファイル | 行 | 役割 | 呼出元 |
|---|---|---|---|---|
| 1 | [`tarot_data.dart`](../lib/utils/tarot_data.dart) | 55 | 78 枚タロットデッキを bundled JSON asset から起動時 `initialize()` で読み込む。`getCard(id)` で照会 | main.dart (`TarotData.initialize()`) + Observe 系 (tarot_card.dart 検索) |
| (準) | [`celestial_events.dart`](../lib/utils/celestial_events.dart) | 314 | 機械分類は 2a だが singleton + initialize 構造 | (層 2a.2 参照) |
| (準) | [`app_locale.dart`](../lib/utils/app_locale.dart) | 41 | 機械分類は 2b だが singleton 構造 | (層 2b.2 参照) |

### 2c.3 main.dart 起動シーケンスとの対応

[`main.dart:15-27`](../lib/main.dart) で起動時に呼ばれる 3 つ:
1. `await TarotData.initialize()` — 78 枚 JSON 読み込み
2. `await CelestialEvents.initialize()` — 静的天体イベント JSON + キャッシュ初期化
3. `await AppLocale.instance.load()` — SharedPreferences から言語オーバーライド復元

**起動順序のリスク**:
- 3 つとも `await` で順次実行 (並列ではない) → 起動が約 200〜500ms 遅延
- Pro 公開時に「初回起動 splash」(層 4e 関連 [`project_solara_stella_revival`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_stella_revival.md)) を実装する場合、本シーケンス完了まで splash を出す形が自然

### 2c.4 課金検討に直結する示唆

1. **3 つの singleton は全て無料機能の前提** → Pro 公開で `/protected/*` 化対象外
2. **`tarot_data.dart` の TarotCard データは静的固定** → Pro 化対象ではない (= 層 1c.3 と同じ)
3. **singleton パターンの統一**: 現状 instance + Notifier (AppLocale) と static class (TarotData, CelestialEvents) が混在。Riverpod 等の状態管理導入時に整理候補

### 2c.5 機械抽出への参照

層 2c の機械抽出 raw: [`feature_inventory/02c_globals.md`](feature_inventory/02c_globals.md)

---

## 層 3a: 共通ウィジェット (純粋)

### 3a.1 概要

`lib/widgets/` 配下 + `screens/horoscope/horo_antique_icons.dart` (オーバーライド経由) の **23 ファイル / 計 5,907 行**。**`AnimationController` を持たない** widget 群 (= 機械分類のヒューリスティック)。
ただし `StatefulWidget` であっても `ScrollController` 等の純粋な state のみのもの (例: `MoonScrollingStory`, `LocationPickerMinimap`) は本層に含まれる。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済): `screens/horoscope/horo_antique_icons.dart` (295 行、`AntiqueGlyph` widget + `_AntiqueIconPainter` CustomPainter) は cross-screen で 16 ファイルから参照 (Map / Galaxy / Horo / no_profile_guide / galaxy_star_atlas)。物理 path は `screens/horoscope/` 配下のままだが、`PATH_OVERRIDES` で 3a に明示移動。

23 ファイルは性質が大きく異なるので、本章では **機能群** 単位で整理する。

| 群 | 役割 | ファイル数 | 行 |
|---|---|---|---|
| A 基礎レイアウト/装飾 | popup・glass・overflow ・用語ラベル + アンティークアイコン | 5 | 609 |
| B ナビゲーション | bottom NavBar + 5 nav icon CustomPainter | 2 | 381 |
| C カテゴリアイコン | 6 種カテゴリの Gemini WebP アイコン | 1 | 80 |
| D 空状態/案内 | プロフィール未設定時のガイドカード | 1 | 51 |
| E Sanctuary 用 | 144 称号カード + ミニマップ座標選択 | 2 | 447 |
| F 月オーバーレイ共通部 | 新月/満月/刻星化 overlay の共通 building blocks | 2 | 266 |
| G Galaxy ペインター | 星座 + サイクルスパイラル + 装飾スパイラル | 3 | 736 |
| H Cycle 天体イベント表示 | 月別イベント横スクロールバー (Galaxy 下部) | 1 | 129 |
| I Map fortune オーバーレイ painter | 5 カテゴリ × CustomPainter + 共通 builder | 6 | 3,212 |

**合計**: 23 ファイル / 5,911 行 (機械抽出 5,907 + 4 は moon_overlay.dart の re-export ヘッダ)

### 3a.2 群別 ファイル一覧 + 呼出元 + 役割

#### A. 基礎レイアウト/装飾 (5 本、計 609 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`info_popup.dart`](../lib/widgets/info_popup.dart) | 113 | `showInfoPopup`, `_InfoPopupShell` | 22 ファイル (Map / Horo / Forecast / Sanctuary / Galaxy / `astro_glossary.dart` 等) | **🔴 統一 popup ヘルパー** ([`project_solara_popup_pattern`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_popup_pattern.md))。新規 popup は必ず本関数経由 (AlertDialog/showModalBottomSheet 直書き禁止)。barrierDismissible + 右上 × + GlassPanel 互換 + 高さ画面-120px 上限 |
| [`glass_panel.dart`](../lib/widgets/glass_panel.dart) | 31 | `GlassPanel` | `map_daily_transit_screen`, `full_moon_overlay`, `new_moon_overlay`, `catasterism_overlay`, `map_direction_popup`, `solara_philosophy_screen` | 半透明暗パネル容器 (`color: 0xE60A0A14` + `glassBorder` 枠)。**2026-05-03 BackdropFilter 撤去** (Adreno saveLayer leak の Critical 対策 = [`feedback_html_costly_widgets`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_html_costly_widgets.md))。blur なしで後ろがうっすら透けるだけ |
| [`solara_safe_text.dart`](../lib/widgets/solara_safe_text.dart) | 81 | `SolaraSafeText` | (現状は本ファイルから他へ未利用、規約用ボイラープレート) | **🔴 Row/Column 内 Text の overflow 安全ラッパ** ([`feedback_text_overflow`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_text_overflow.md))。`Flexible(flex/fit, child: Text(maxLines, overflow:ellipsis))` をワンライナー化 |
| [`astro_term_label.dart`](../lib/widgets/astro_term_label.dart) | 85 | `AstroTermLabel` | `map_relocation_popup` + 各種 popup 内 (Map / Horo) | 用語 i ボタン (タップで `showAstroGlossaryDialog` 呼出 = 層 1a `astro_glossary.dart`)。`termKey` が辞書未登録なら i アイコン非表示。2026-05-11 child を Flexible でラップする overflow 修正済 |
| [`screens/horoscope/horo_antique_icons.dart`](../lib/screens/horoscope/horo_antique_icons.dart) | 295 | `AntiqueIcon` enum (12 種: reading/birthStar/crescent/compassStar/sunRays/asterisk/triangleOrnate/eightPointStar/ornateStarCrescent/cycleSpiral/flourishKey/forecast 等)、`AntiqueGlyph` widget、`_AntiqueIconPainter` CustomPainter (12 個の `_buildPath` / `_buildFills` 個別描画) | **16 ファイル横断** (Map: map_screen / map_relocation_popup 等、Horo: 11 ファイル、Galaxy: 2 ファイル、widgets/no_profile_guide ほか) | (4b→3a オーバーライド済) **アンティーク神秘画調アイコン集**。NoProfileGuide のアイコン、Horoscope 各 panel ヘッダ、Galaxy アトラス、Map ガイド等で使用 |

#### B. ナビゲーション (2 本、計 381 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`solara_nav_bar.dart`](../lib/widgets/solara_nav_bar.dart) | 163 | `SolaraNavBar` (+ `baseHeight`, `totalHeight`, `systemNavInset` static) | [main.dart](../lib/main.dart) (`SolaraHome` 直配置)、[map_planet_lines.dart](../lib/screens/map/map_planet_lines.dart) (`totalHeight` で bottom 位置計算) | HTML `shared/styles.css` に正確に合わせる bottom NavBar (h=80 + 5 タブ Expanded 分割)。**2026-04-29 Android systemNav (3 ボタン △〇□) 対応**: 閾値 30px で 3 ボタン/ジェスチャー判定、3 ボタン時のみ追加高 (`systemNav - 12`) を加算。**2026-05-03 BackdropFilter 撤去**で alpha 高めの gradient に置換 (glass_panel と同じ Adreno 対策) |
| [`nav_icons.dart`](../lib/widgets/nav_icons.dart) | 218 | `SolaraNavIcons` クラス — `SolaraNavIcons.map/horo/tarot/galaxy/sanctuary` (static factory) + 5 `_*IconPainter` (CustomPainter) | `solara_nav_bar.dart` のみ | 5 タブ用ベクター SVG 互換アイコン (HTML `shared/icons.js` exact)。Map = circle + cross-hairs + diamond、Horo = 同心円 + 十字、Tarot = card + star、Galaxy = ellipse + spiral arms + dots、Sanctuary = temple + door + circle window |

#### C. カテゴリアイコン (1 本、80 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`category_icon.dart`](../lib/widgets/category_icon.dart) | 80 | `CategoryIconKind` enum、`CategoryIcon` widget、`DominantFortuneKindToCategoryIcon` extension、`_CategoryIconKindAsset` extension | `map_menu_chips`, `map_daily_transit_screen` | 6 種 (all/love/money/work/healing/communication) の Gemini 生成 WebP アンティーク神秘画 (`assets/menu_icons/{kind}.webp`)。**2026-05-10 CustomPaint (Style D) → WebP に置換** (ベクター描画は git history 復元可能)。`DominantFortuneKind` (層 3c) → `CategoryIconKind` への変換 extension あり |

#### D. 空状態/案内 (1 本、51 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`no_profile_guide.dart`](../lib/widgets/no_profile_guide.dart) | 51 | `NoProfileGuide` | [forecast_screen](../lib/screens/forecast_screen.dart), [locations_screen](../lib/screens/locations_screen.dart), [map_screen](../lib/screens/map_screen.dart) | プロフィール未設定時 (SolaraProfile が null) のガイドカード。「設定する→」タップで `maybePop()` (シート閉) + `onNavigateToSanctuary?.call()`。**2026-05-04 集約**: Forecast/Locations にあった 1,195 char コピペを抽出 (map_screen / horo_backdrop は装飾異なるため別実装で残存) |

#### E. Sanctuary 用 (2 本、計 447 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`class_card.dart`](../lib/widgets/class_card.dart) | 306 | `ClassCard`, `ClassCardMode` enum | [sanctuary_screen](../lib/screens/sanctuary_screen.dart), [sanctuary_title_diagnosis](../lib/screens/sanctuary/sanctuary_title_diagnosis.dart), [class_share_card](../lib/screens/sanctuary/class_share_card.dart) | 25 クラスのアール・ヌーヴォー画風カード表示 (`assets/class-cards/<axis>_<court>_<nameen>.webp`)。Light/Shadow 両面、`titleLightJP` / `titleShadowJP` で「省察に長けた / 騎士」のように一言＋クラス名表示。軸別 5 色グロー (power=crimson, mind=sapphire, spirit=violet, shadow=amethyst, heart=rose-pink)。診断 reveal + シェアカード + 将来図鑑用 |
| [`location_picker_minimap.dart`](../lib/widgets/location_picker_minimap.dart) | 141 | `LocationPickerMinimap` | [sanctuary_profile_editor](../lib/screens/sanctuary/sanctuary_profile_editor.dart), [sanctuary_home_editor](../lib/screens/sanctuary/sanctuary_home_editor.dart) | Sanctuary 出生地/現住所入力で検索後の微調整用ミニマップ。**中央固定ピン + マップパン**で座標選択 (ピンドラッグでない = `IgnorePointer` で gesture を `FlutterMap` へ通す)。`didUpdateWidget` で親側 lat/lng が大きく変わったら map も追従 (≤ 0.0001 はループ防止で無視) |

#### F. 月オーバーレイ共通部 (2 本、計 266 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`moon_overlay.dart`](../lib/widgets/moon_overlay.dart) | 4 | (re-export のみ) | [galaxy_screen](../lib/screens/galaxy_screen.dart) | 後方互換用 re-export ファイル。`new_moon_overlay` / `full_moon_overlay` / `catasterism_overlay` (3 つとも層 3c) を `export 'xxx.dart'` で集約 |
| [`moon_overlay_shared.dart`](../lib/widgets/moon_overlay_shared.dart) | 262 | `revealPoeticMessage`, `moonOverlaySelectableCard`, `moonOverlayPageStructure`, `measureMoonOverlayTapGeometry`, `mysticalMoonBackdrop`, `MoonScrollingStory` (Stateful) | `new_moon_overlay`, `full_moon_overlay`, `catasterism_overlay` (層 3c の月 overlay 3 種) | **月 / 刻星化 overlay の共通 building blocks** (2026-05-06 audit T2/T7 で集約)。詩的メッセージ + 選択カード + ページ構造 (story/selection/reveal 3 段 fade) + 幾何測定 + 神秘背景 + 自動スクロール物語 (30px/s, ShaderMask フェード) |

#### G. Galaxy ペインター (3 本、計 736 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`cycle_spiral_painter.dart`](../lib/widgets/cycle_spiral_painter.dart) | 396 | `CycleSpiralPainter`, `_Vec3`, `_SpiralDot`, `_GADot`, `_Mulberry32` | [galaxy_screen](../lib/screens/galaxy_screen.dart) | **Galaxy 画面のメインペインター** — HTML `galaxy.html renderSpiral3D()` を Dart 移植。3 層 (Ghost spiral path / spiral anchor dots / reading dots at Golden Angle 55° anamorphic camera) + `_drawBackgroundStars` + `_drawStellaCore` + 接続スレッド + `hitTestDot` (タップ判定)。`breathPhase` で呼吸アニメ受け取り (本ファイルに AnimationController なし、親 galaxy_screen 側で駆動) |
| [`constellation_painter.dart`](../lib/widgets/constellation_painter.dart) | 249 | `ConstellationPainter`, `MiniConstellationPainter` | [galaxy_replay_overlay](../lib/screens/galaxy/galaxy_replay_overlay.dart), [galaxy_star_atlas](../lib/screens/galaxy/galaxy_star_atlas.dart), [catasterism_formation_overlay](../lib/widgets/catasterism_formation_overlay.dart) | 星座描画ペインター v2 (anamorphic 3D)。Major Arcana = MST edges + `NOUN_SHAPES`、Minor Arcana = field stars (独立浮遊)。`cameraAngle` 55°=分散 / 0°=整列、`progress` で漸進描画、`artImage` で星座イラスト合成、`flipX` で左右反転。`MiniConstellationPainter` は Star Atlas grid card 用の小型版 |
| [`spiral_painter.dart`](../lib/widgets/spiral_painter.dart) | 91 | `SpiralPainter` | [galaxy_screen](../lib/screens/galaxy_screen.dart) | シンプル 3 周スパイラル + 日数ドット (active/inactive) + Stella 中心グロー の装飾ペインター。`CycleSpiralPainter` (本格 3D 版) とは別の軽量版。**`MaskFilter.blur` を使うため** GPU 負荷あり ([`todo_solara_perf_audit`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/todo_solara_perf_audit.md) の監査候補) |

#### H. Cycle 天体イベント表示 (1 本、129 行)

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`celestial_event_bar.dart`](../lib/widgets/celestial_event_bar.dart) | 129 | `CelestialEventBar` | [galaxy_screen](../lib/screens/galaxy_screen.dart) | Galaxy/Cycle 画面下部に常時表示する天体イベント横スクロールバー。`/astro/events` から取った `CelestialEvent` リストを chip 表示、タップで `showInfoPopup` 経由でイベント占星術的意味を表示 (層 1a `celestial_event_meanings.dart` 参照)。イベント type → アイコン記号テーブル: ingress=➜, retrograde=℞, retrograde_end=↻, eclipse=◑, conjunction=☌, node_shift=☊ |

#### I. Map fortune オーバーレイ painter (6 本、計 3,212 行)

[`dominant_fortune_overlay.dart`](../lib/widgets/dominant_fortune_overlay.dart) (層 3c、`AnimationController` あり) が「今日の最高スコアカテゴリ」に応じて 5 painter を切り替え、**1 日の最初のタップで約 4 秒間** 全画面演出。本層 3a にあるのは Painter 本体 (state 持たない CustomPainter) + 共通 builder。

| ファイル | 行 | 主要 export | 呼出元 | 役割 |
|---|---|---|---|---|
| [`fortune_overlays/_common.dart`](../lib/widgets/fortune_overlays/_common.dart) | 40 | `FortunePainterBuilder` (abstract)、`easeOutCubic`, `easeOutBack`, `easeInOutQuad`, `stageAlpha` | 5 painter + `dominant_fortune_overlay` | 5 painter の親契約 + 共通イージング関数 (減速 / バウンド / 二次 / 3 段階 α カーブ) |
| [`fortune_overlays/communication_painter.dart`](../lib/widgets/fortune_overlays/communication_painter.dart) | 642 | `CommunicationPainterBuilder`、`_CommunicationPainter`、`_NotePair`, `_Note`, `_Stream`, `_Spark`, `_Sparkle` | `dominant_fortune_overlay` | **コミュニケーション**: ルーン文字・占星術記号・ラテン語片が羊皮紙の上を流れ、ノート pair が衝突して spark + sparkle |
| [`fortune_overlays/healing_painter.dart`](../lib/widgets/fortune_overlays/healing_painter.dart) | 498 | `HealingPainterBuilder`、`_HealingPainter`、`_PetalPalette`, `_Petal`, `_LightMote`, `_Sparkle` | `dominant_fortune_overlay` | **癒し**: 月桂樹とオリーブの葉が下→上へ螺旋で舞い上がり、aurora band + light mote |
| [`fortune_overlays/love_painter.dart`](../lib/widgets/fortune_overlays/love_painter.dart) | 581 | `LovePainterBuilder`、`_LovePainter`、`_PetalPalette`, `_RosePetal`, `_Sparkle`, `_Ray`, `_Vine` | `dominant_fortune_overlay` | **恋愛**: 中心に金の魔法陣 (sigil) が開き、薔薇の花弁が放射 + 蔓 vine + god rays |
| [`fortune_overlays/money_painter.dart`](../lib/widgets/fortune_overlays/money_painter.dart) | 693 | `MoneyPainterBuilder`、`_MoneyPainter`、`_GoldPalette`, `_GoldPiece`, `_GoldDust`, `_Sparkle` | `dominant_fortune_overlay` | **金運**: 金貨・金箔 (coin + flake) が上から落ちて積み上がる落ち物ゲーム風 + dust + sparkle |
| [`fortune_overlays/work_painter.dart`](../lib/widgets/fortune_overlays/work_painter.dart) | 758 | `WorkPainterBuilder`、`_WorkPainter`、`_MedalPalette`, `_Medallion`, `_Gear`, `_GoldDust`, `_Sparkle` | `dominant_fortune_overlay` | **仕事**: 金の勲章 medallion が回転浮遊 + 歯車 gear + final moment 演出 |

### 3a.3 機械分類の盲点

1. **`AnimationController` 有無での 3a / 3c 振り分けは概ね妥当**だが、`MoonScrollingStory` (3a) は `ScrollController.animateTo` で時間連動の動きがある (= 厳密には演出寄りの State)。それでも `AnimationController` でない点で本層採用は許容範囲。

2. **fortune_overlays/ 5 painter は CustomPainter で state を持たないため正しく 3a**。親の `DominantFortuneOverlay` (3c) が `AnimationController` の `t` を渡して描画させる構造。**画面演出として一塊で動く** = 課金検討では「動く演出」として 3c と一緒に扱う方が自然 (層 3c 章でも言及予定)。

3. **`category_icon.dart` の `DominantFortuneKindToCategoryIcon` extension** は `dominant_fortune_overlay.dart` (3c) の enum を変換するため、3a → 3c の依存方向で参照している。逆 (3c → 3a) は問題ないが、3a 同士で共有された enum を 3c に置くより `direction_energy.dart` (層 1a) に寄せる選択肢もある (将来検討)。

### 3a.4 課金検討に直結する示唆

1. **`showInfoPopup` (info_popup.dart) は全画面の説明 UX を握る中央集権ポイント**
   - 22 ファイルが本関数経由で popup を出す = ここを改修すれば全画面の popup 体験が一括で変わる
   - **Pro 機能の説明 UX** (例: 「この機能は Pro 限定」「アップグレード」訴求) は本 helper を拡張する形が自然 (新引数 `proGate: true` で「Pro バッジ + アップグレード CTA」を追加する案など)
   - barrier dismissible でユーザー摩擦少ない = ペイウォール訴求にも向いている

2. **`solara_nav_bar.dart` + `nav_icons.dart` = アプリの第一印象**
   - 5 タブ全部が無料層から見える状態 = どのタブも「初期体験」になる
   - Pro 機能をタブ単位で分けない設計 (タブは全員見えて、中の一部機能が Pro) は実装コスト低 + 訴求柔軟
   - **タブ内に「Pro バッジ」を出すなら本 widget の拡張が必要** (現状は 5 タブのみ、Pro バッジ表示の枠なし)

3. **`category_icon.dart` の WebP アセットは Pro 拡張の素材として強力**
   - Gemini 生成のアンティーク神秘画 = ストア訴求素材としての価値高
   - **Pro 限定カテゴリ追加** (例: career, family, spiritual, etc.) は本 widget + WebP アセット 1 枚追加で済む = 拡張容易

4. **`class_card.dart` (Sanctuary 144 称号) は無料機能の差別化の中心**
   - 25 クラス × 144 タイトルカード = ユーザー独自の「あなただけの結果」
   - **Pro 拡張案**: シェアカード追加デザイン、月別称号変化追跡、図鑑/コレクション (将来)
   - **EN 版未実装** ([`project_solara_title_system`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_title_system.md)) が海外展開のボトルネック

5. **fortune_overlays/ 5 painter (合計 3,212 行) は Solara 演出の半分を占める = リソース集中分野**
   - 5 カテゴリの「1 日 1 回演出」は無料機能で十分インパクトあり、Pro 化対象としては弱い
   - **Pro 拡張案**: 演出のバリエーション追加 (例: 月別テーマ painter)、または「演出を毎回再生」設定の Pro 化 (Free は 1 日 1 回固定)
   - **保守性**: 5 painter が各 500〜750 行で類似構造 = 共通 builder ([`_common.dart`](../lib/widgets/fortune_overlays/_common.dart)) が抽象化できる余地は残存

6. **`solara_safe_text.dart` は overflow 対策の規約ファイル**
   - 現状他ファイルから参照ゼロだが、これは「規約として置いてある」状態 ([`feedback_text_overflow`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_text_overflow.md))
   - i18n フェーズ ([`feedback_i18n_last`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_i18n_last.md)) で EN テキスト追加時に活用すべき (英語は日本語より長くなる傾向 = overflow 再発リスク)

7. **`glass_panel.dart` + `solara_nav_bar.dart` の Adreno saveLayer leak 対策は Pro 公開前提**
   - 2026-05-03 に BackdropFilter 撤去済 = 公開時の Critical 安定性問題は解消済
   - 将来 BackdropFilter を再導入する場合は本ファイル経由で集中管理 (= 散発再導入で同じバグ再発を防げる)

### 3a.5 機械抽出への参照

層 3a の機械抽出 raw: [`feature_inventory/03a_widgets_pure.md`](feature_inventory/03a_widgets_pure.md)

---

## 層 3b: テーマ・装飾

### 3b.1 概要

`lib/theme/` 配下 2 本 + `screens/map/map_constants.dart` (オーバーライド経由) の **3 ファイル / 計 300 行**。**色定数と HTML 一致定数の貯蔵庫**。
他層 (widgets / screens / painters) は本層を import して色 / 線スタイル / 惑星シンボルを引く構造で、Solara の見た目の **唯一の源泉**。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済):
- 当初プラン ([`project_solara_feature_extractor`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_feature_extractor.md)) では「theme/ + antique_icons + astro_glyphs 2 本」とあったが、`antique_icons.dart` / `astro_glyphs.dart` 単体ファイルは存在しない (`antique_icons` は [horo_antique_icons.dart](../lib/screens/horoscope/horo_antique_icons.dart) として Horoscope 画面層 4b に内包)
- `screens/map/map_constants.dart` (122 行、HTML `CHART_STYLE` + `TAROT.planets` 純定数) は当初 4a 検出だったが `PATH_OVERRIDES` で 3b に明示移動

### 3b.2 ファイル別 役割 + 呼出元 (3 本)

| # | ファイル | 行 | 主要 export | 呼出元 (画面層) | 性質 |
|---|---|---|---|---|---|
| 1 | [`solara_colors.dart`](../lib/theme/solara_colors.dart) | 110 | `SolaraColors` (static const Color 群 + `planetColor`, `elementColor` ヘルパー) | **19 ファイル** (widgets 9 + screens 9 + theme 1) で 143 occurrences | **色の唯一の源泉**。Soft/Hard 独立 2 エネルギー色、惑星 10 色、エレメント 4 色、月相、glass、spiral 全て格納 |
| 2 | [`solara_theme.dart`](../lib/theme/solara_theme.dart) | 68 | `SolaraTheme.dark` (ThemeData) + `_textTheme` (DM Sans + Noto Sans JP fallback) | [main.dart:40](../lib/main.dart) のみ (`MaterialApp.theme: SolaraTheme.dark`) | アプリ全体の ThemeData。**日本語フォールバック規約あり**: `fontFamilyFallback: [Noto Sans JP]` を `TextTheme.apply` で全 TextStyle に伝搬 |
| 3 | [`screens/map/map_constants.dart`](../lib/screens/map/map_constants.dart) | 122 | `ChartLineStyle` (natal/progressed/transit の線スタイル)、`PlanetMeta` (惑星シンボル + 色) | Map 系 (map_screen, map_astro_lines, map_planet_lines, map_relocation_popup, map_line_narrative_sheet, map_direction_popup ほか) | (4a→3b オーバーライド済) HTML `CHART_STYLE` と `TAROT.planets` の Dart 移植純定数。物理的には `screens/map/` 配下 |

### 3b.3 SolaraColors 色定数の構造 (`planetColor`, `elementColor`)

| 群 | 色定数 | 用途 |
|---|---|---|
| **Primary** | `solaraGoldLight` (`F9D976`), `solaraGold` (`F6BD60`), `celestialBlueLight`, `celestialBlueDark` | アプリのブランド 4 色。Gold は強調・active、Blue は背景 |
| **Typography** | `textPrimary` (`EAEAEA`), `textSecondary` (`ACACAC`) | 本文・補助文字色 |
| **🔴 Energy 2 軸** | `energySoft` (銀月色 `C8D4E8`) + `Light/Dark/Glow` 計 4 色、`energyHard` (金陽色 `D6915C`) + `Light/Dark/Glow` 計 4 色 | [`project_solara_design_philosophy`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md) の独立 2 エネルギーを色で表現。**赤=悪 / 緑=良 を絶対回避**。両方とも「正のエネルギー」 |
| **Frosted Glass** | `glassFill` (5% 白)、`glassBorder` (10% 白) | popup / panel の半透明境界 |
| **Elements** | `fire/water/air/earth` × `Start/End/Glow` 計 12 色 | 4 元素の gradient 用 |
| **Spiral** | `spiralLine`、`spiralDotActive/Inactive/Dim` | Galaxy スパイラル装飾 |
| **Planet (10 色)** | `planetSun`〜`planetPluto` | 10 惑星色。`planetColor('sun')` ヘルパーで文字列→Color |
| **Element (4 色)** | `elementWands/Cups/Swords/Pentacles` | Tarot 78 枚デッキ用。`elementColor('fire')` ヘルパーで文字列→Color (Wands ↔ fire マッピング) |
| **Moon event** | `fullMoonRing`、`newMoonCore` | 満月リング光・新月コア紫 |

**ヘルパー関数 2 本** (関数として export されている数少ない要素):
- `planetColor(String planet)` → 10 惑星色テーブル参照、未知文字列なら `solaraGold` フォールバック
- `elementColor(String element)` → 4 元素色テーブル参照、未知なら `textSecondary` フォールバック (`planetColor`/`elementColor` は Map 系・Observe 系・Galaxy 系 10 ファイルで使用)

### 3b.4 `SolaraTheme` の構造

`SolaraTheme.dark` (ThemeData) は以下を設定:

| プロパティ | 値 |
|---|---|
| `brightness` | `Brightness.dark` (全画面 dark mode 固定) |
| `scaffoldBackgroundColor` | `celestialBlueDark` (`0xFF080C14`) |
| `textTheme` | DM Sans (latin) + Noto Sans JP fallback、5 段階 (headlineLarge/Medium、bodyLarge/Medium、labelSmall) |
| `bottomNavigationBarTheme` | active=`F9D976` Gold、inactive=`rgba(255,255,255,0.35)`、label fontSize 9 + letterSpacing 0.5 (HTML 一致) |
| `colorScheme` | primary=`solaraGold`、surface=`celestialBlueDark`、onSurface=`textPrimary` |

**日本語フォールバック規約**: Latin は DM Sans、それ以外 (日本語) は Noto Sans JP。`TextTheme.apply(fontFamilyFallback: [japaneseFallback])` で 5 段階全てに伝搬。個別の Text/RichText で `fontFamily` を明示しても日本語文字は自動で Noto Sans JP に切替。

### 3b.5 機械分類の精度 + 課金検討に直結する示唆

1. **層 3b は機械分類どおり「ほぼ全画面が依存する基礎」**
   - `solara_colors.dart` は 19 ファイルから 143 回参照。グローバル定数ファイルとして適切な位置にある
   - `solara_theme.dart` は main.dart 1 箇所からの参照だが、`ThemeData` 経由で全 Widget に行き渡る

2. **Pro 機能の境界とは独立 = 「無料公開層」**
   - 色とテーマは Free/Pro 共通の UI 基盤
   - **Pro バッジ専用色** (例: `proGold`, `proGlow`) を本ファイルに追加するなら本層が自然な置き場所
   - 同様に「Pro 限定演出のアクセント色」も `solara_colors.dart` に集中させると保守が楽

3. **🔴 Soft/Hard 2 エネルギー色は譲れない世界観 — 課金訴求にも使える**
   - 「赤=悪 緑=良」回避の独自設計 ([`project_solara_design_philosophy`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md))
   - ストア説明文や Pro 訴求文に「両面評価 — 銀月色と金陽色の独立 2 エネルギー」と書くと既存占いアプリ群との差別化軸として効く
   - 色定数で表現されているので、Marketing 素材 (LP、ストア screenshot) で同じ色を使えば一貫性出る

4. **`SolaraTheme.dark` のみで `light` テーマは未実装**
   - 全画面 dark mode 固定 = アプリの世界観 (= 夜空、星座、月相)
   - **Pro 機能で `light` テーマ追加は世界観と齟齬** = 推奨しない
   - 代わりに「Pro 限定: シーズン別アクセント (Spring/Autumn/Winter)」のような派生 dark テーマなら拡張可能

5. **i18n フェーズで `Noto Sans JP fallback` の追加検討**
   - EN リリース時、英語 latin は DM Sans のみで完結する
   - 中国語・韓国語など他言語展開時は本ファイルに `Noto Sans SC/KR` fallback 追加が必要
   - ただし [`feedback_i18n_last`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_i18n_last.md) の規約で、i18n は公開直前まで保留

6. **`bottomNavigationBarTheme` 設定は実質未使用**
   - 現状の bottom NavBar は層 3a `SolaraNavBar` (カスタム widget) で描画していて、Material の `BottomNavigationBar` は使っていない
   - `ThemeData.bottomNavigationBarTheme` 設定は HTML 一致目的で残しているが、実用上は dead 設定
   - **削除しても害なし**だが、将来 Material BottomNavigationBar を使う可能性があれば残置可

### 3b.6 機械抽出への参照

層 3b の機械抽出 raw: [`feature_inventory/03b_theme.md`](feature_inventory/03b_theme.md)

---

## 層 3c: 演出ウィジェット (animated)

### 3c.1 概要

`lib/widgets/` 配下、**`AnimationController` を持つ** 5 ファイル / 計 2,160 行。
全画面 overlay として「**特定の瞬間にだけ被さる演出 widget**」を担う。本層には 2 系統が共存:

| 系統 | 用途 | 出現条件 | ファイル |
|---|---|---|---|
| **Map fortune 演出** | 今日の最高スコアカテゴリに応じた全画面演出 | Map 画面で 1 日の最初のタップ時 (4 秒間) | `dominant_fortune_overlay.dart` |
| **Galaxy moon 演出** | サイクル節目 (新月/満月/刻星化) の体験画面 | Galaxy 画面で月相が新月/満月/刻星化日に当たる時 | `new_moon_overlay.dart`, `full_moon_overlay.dart`, `catasterism_overlay.dart`, `catasterism_formation_overlay.dart` |

層 3a の moon overlay 共通部品 ([`moon_overlay_shared.dart`](../lib/widgets/moon_overlay_shared.dart)) と層 3a の 5 fortune painter (`fortune_overlays/*`) を **本層 5 widget が AnimationController + StatefulWidget でラップ駆動** している関係。

### 3c.2 ファイル別 役割 + AnimationController 数 + 呼出元 (5 本)

| # | ファイル | 行 | AnimCtrl 数 | 主要 export | 呼出元 | 性質 |
|---|---|---|---|---|---|---|
| 1 | [`dominant_fortune_overlay.dart`](../lib/widgets/dominant_fortune_overlay.dart) | 85 | **1** (4 秒) | `DominantFortuneKind` enum (love/money/healing/communication/work)、`DominantFortuneOverlay`、`kindFromKey` | [map_screen.dart](../lib/screens/map_screen.dart) (`_activeOverlay` で表示制御 + `_debugCycleOrder` で 5 種循環テスト) + 補助で [map_menu_chips](../lib/screens/map/map_menu_chips.dart), [map_daily_transit_screen](../lib/screens/map/map_daily_transit_screen.dart), [category_icon](../lib/widgets/category_icon.dart) (enum import のみ) | 層 3a `fortune_overlays/*` 5 painter のディスパッチャ。`_createBuilder(kind)` で 5 種 builder を切替、`AnimationController` の値を `CustomPaint` に渡す。`IgnorePointer` で gesture 透過。完了で `onComplete` callback (= 通常 4s) |
| 2 | [`new_moon_overlay.dart`](../lib/widgets/new_moon_overlay.dart) | 564 | **6** (fade/page/reveal/message/events/action) | `NewMoonOverlay` (`month`, `cycleId`, `onDismiss`, `onIntentionSet` 引数) | [galaxy_screen](../lib/screens/galaxy_screen.dart) (月相が新月日に当たる時) + 再 export 経由 [moon_overlay.dart](../lib/widgets/moon_overlay.dart) | **3 フェーズ** (物語 → 4 択選択 → 詩的リビール)。`LunarIntention` を `SolaraStorage.setLunarIntention` で永続化、`CelestialEvents.fetchCycleEvents` で当該サイクル天体イベントも取得 |
| 3 | [`full_moon_overlay.dart`](../lib/widgets/full_moon_overlay.dart) | 481 | **4** (fade/page/reveal/message) + `Timer` 自動クローズ | `FullMoonOverlay` (`intention`, `month`, `onDismiss` 引数) | [galaxy_screen](../lib/screens/galaxy_screen.dart) (月相が満月日に当たる時) + 再 export 経由 | **3 フェーズ** (物語 → 3 段階評価 → 詩的リビール → 3 秒余韻で自動確定)。新月で設定した `intention.choice` の中間チェック (🌊 まだ取り組み中 / ✨ 進展あり / 🌟 軽くなった) を `SolaraStorage.setMidpointCheck` で永続化 |
| 4 | [`catasterism_overlay.dart`](../lib/widgets/catasterism_overlay.dart) | 445 | **4** (fade/page/exit/glow) | `CatasterismOverlay` (`intention`, `totalDays`, `onDismiss`, `onResult?` 引数) | [galaxy_screen](../lib/screens/galaxy_screen.dart) (新月前日 = サイクル終端日) + 再 export 経由 | **3 フェーズ** (物語 → 2 択選択 → グロウパルス → フェードアウト)。「手放せた / まだ途中」の 2 値判定を `_glowCtl` で発光演出 + 600ms forward + 100ms peak + 600ms reverse で表現。次画面 `CatasterismFormationOverlay` への切替トリガを発火 |
| 5 | [`catasterism_formation_overlay.dart`](../lib/widgets/catasterism_formation_overlay.dart) | 585 | **2** (main 8 秒 / fade 1ms 値 1.0) + `_FormationPainter` CustomPainter | `CatasterismFormationOverlay` (`cycle`, `artImage?`, `onComplete` 引数)、`_FormationPainter` | [galaxy_screen](../lib/screens/galaxy_screen.dart) (catasterism_overlay の完了直後) | **🌟 8 秒 4 ステージ演出** (`SPEC.md` 準拠): CONVERGENCE 0-2s 集来 / IGNITION 2-3s 点灯 / LINKING 3-5s 連結 / COMPLETE 5-8s 完成。12 星座シンボル (`assets/zodiac-symbols/*.webp`) + 背景 (`assets/catasterism_bg.webp`) を preload、`GalaxyCycle` の MST edges を漸進描画 |

### 3c.3 共通設計パターン (4 系 moon/catasterism overlay)

`new_moon` / `full_moon` / `catasterism` 3 widget は **同形のフェーズ構造** を持ち、層 3a [`moon_overlay_shared.dart`](../lib/widgets/moon_overlay_shared.dart) の共通部品で集約済 (2026-05-06 audit T2/T7):

| 段階 | 内容 | 使用部品 |
|---|---|---|
| 物語 | 縦スクロール詩的テキスト (30 px/s 自動 + 手動で中断可) | `MoonScrollingStory` (3a) |
| 遷移 | 中点 (`_pageCtl.value >= 0.5`) で `_showStory=false` クロスフェード | `moonOverlayPageStructure` (3a) |
| 選択 | カード列タップ (new_moon=4 択 / full_moon=3 段階 / catasterism=2 値) | `moonOverlaySelectableCard` (3a) |
| 幾何測定 | `GlobalKey` から `localToGlobal` + size 取得 | `measureMoonOverlayTapGeometry` (3a) |
| リビール | 詩的メッセージ fadeIn | `revealPoeticMessage` (3a) |
| 永続化 | `LunarIntention` / `MidpointCheck` / `CatasterismResult` モデル (層 1c) | `SolaraStorage.*` (層 2b) |

**= 4 系 overlay の保守性が高い** 構造。新規 overlay 追加 (例: Pro 限定「半月チェック」) も本パターンに従えば既存部品で 80% 賄える。

### 3c.4 機械分類の精度 + 課金検討に直結する示唆

1. **`DominantFortuneOverlay` は層 3a の 5 painter 駆動主**
   - 機械分類は `AnimationController` 有無で正しく 3c
   - 実装上は 85 行と最も薄いが、3a 5 painter (3,212 行) を起動するキーストーン
   - **Pro 拡張案**: 演出を「毎回再生」設定 (Free は 1 日 1 回固定) は本ファイルの `onComplete` トリガを `map_screen` 側で制御変更すれば実装可

2. **🔴 Galaxy moon 演出 4 種 = Solara の最大差別化体験**
   - 「占いをしない、節目で自己と対話する」体験 ([`project_solara_design_philosophy`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md)) を体現
   - 新月で意図を立てる → 満月で中間チェック → 刻星化 (新月前日) で完了判定 → 形成演出 (星座) の 4 段サイクル
   - **無料機能の心臓部** = Pro 化対象としては不適切 (これを Pro 化すると Solara の独自性が見えなくなる)
   - 代わりに「過去サイクルアルバム」「履歴の検索」「カスタム背景画像」が Pro 拡張案 ([`project_galaxy_spec`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_galaxy_spec.md))

3. **`CatasterismFormationOverlay` の 8 秒演出は最も重い**
   - 12 星座シンボル + 背景画像を preload、`AnimationController` 60fps で 8s = 480 frame 描画
   - `_FormationPainter` (252 行) の `paint` 関数が重い可能性 ([`todo_solara_perf_audit`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/todo_solara_perf_audit.md))
   - **「サイクル完了の最大ご褒美」演出**として演出投資に値する重み
   - Pro 拡張案: 「形成演出を任意のタイミングで再生 (履歴アルバム)」

4. **3 系 moon overlay の AnimationController 数 (6+4+4) = メモリ・GPU 負荷**
   - `dispose()` 漏れがあれば fd 枯渇等の致命傷 ([`feedback_http_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_http_fd_leak.md) / [`project_solara_a101fc_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_a101fc_fd_leak.md))
   - 各 widget の `dispose()` で全 controller 解放を確認済 (本セッション読み合わせで確認、漏れなし)
   - Pro 拡張で AnimationController を増やす場合は dispose 必須

5. **永続化が層 2b `solara_storage.dart` に集中**
   - new_moon: `setLunarIntention`, `setNotTodayCount`
   - full_moon: `setMidpointCheck`
   - catasterism: `setCatasterismResult`
   - **クラウドバックアップ Pro** ([`solara_storage.dart`](../lib/utils/solara_storage.dart) で議論) のバックアップ対象としてこれらが最優先候補

6. **`DominantFortuneOverlay` の `kindFromKey` 関数は柔軟性源**
   - 文字列 → enum 変換ヘルパー、外部入力 (例: notification payload) からの起動を想定
   - **Pro 公開時の deep link 対応**: 「Pro 限定 push 通知から特定 overlay 起動」は本関数で実装容易

### 3c.5 機械抽出への参照

層 3c の機械抽出 raw: [`feature_inventory/03c_widgets_anim.md`](feature_inventory/03c_widgets_anim.md)

---

## 層 4a: Map 画面

### 4a.1 概要

`lib/screens/map/` 配下 + `lib/screens/map_screen.dart` の **22 ファイル / 計 12,283 行** (オーバーライド適用後)。Solara で**最大規模の画面**であり、**Pro 機能の核が最も集中する層**。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済): 当初は 25 ファイル / 13,926 行だったが、`PATH_OVERRIDES` で 3 本を他層に明示移動:
- `map_astro.dart` (508) → 層 2a (`/astro/chart` ラッパ、Map+Horo 共用)
- `map_constants.dart` (122) → 層 3b (HTML 一致純定数)
- `daily_transit_data.dart` (1,013) → 層 1b (静的テキスト辞書)

Map 画面は単に「地図を表示する」だけでなく、以下の機能を全部内包する複合体:

| 機能領域 | 概要 |
|---|---|
| 地図描画 | 4 種タイル切替 (OSM hot/standard/cyclosm Light/Dark)、ズーム制御、タイル fd 制御 |
| 16 方位スコア計算 | `/astro/chart` から取った出生図 + 拠点 + 時刻で 16 方位 × 5 カテゴリ Soft/Hard スコアを計算 |
| アスペクトラインオーバーレイ | 4 frame (natal/transit/progressed/solarArc) × 40 本コンジャンクションライン (= ACG モード) |
| Daily Transit (F1-c) | 「今日の動き」= 10 惑星 × 4 アングル (ASC/MC/DSC/IC) 通過時刻 + natal アスペクト併記 |
| 検索 + 拠点管理 | Google Places 検索 → スコア注入 → 候補から拠点保存 (`VPSlot`)、独立 `📍 地点メニュー` |
| 詳細 popup 群 | 方角タップ / 惑星マーカータップ / 引越し popup / ACG ライン popup |
| 時間操作 | ±365 日 + 時分のタイムスライダー、LIVE ボタン |

**Pro 公開時の最大対象 = `/fortune` (Gemini) + `/relocation` (Gemini) を呼ぶラッパが本層内に複数あり**。

### 4a.2 機能群別ファイル分類 (22 本)

22 ファイルを 10 群に整理 (旧 A は全削除、旧 J は 2 本に減):

| 群 | 役割 | 数 | 行 |
|---|---|---|---|
| ~~A~~ | ~~計算データ + 描画定数~~ — オーバーライドで層 2a/3b へ移動 | 0 | 0 |
| B UI 基礎部品 | 円形ボタン、Legend、タイル選択、扇状セクター | 3 | 376 |
| C HUD オーバーレイ | 左サイド 3 ボタン、検索バー、選択日バッジ、VP Pin、下部チップバー、時刻スライダー | 3 | 1,261 |
| D 検索系 | Google Places 検索 + 結果リスト + フォーカス popup + スコア注入 | 1 | 590 |
| E アスペクトライン + ACG | 4 frame × 40 本ライン + 天頂/天底マーカー + ACG モード UI | 3 | 1,686 |
| F マーカー + ロケーション | 出生地/スロットマーカー + VP Slot 永続化 + 📍 地点メニュー | 3 | 1,061 |
| G 表示メニュー | ☰ 表示ボタン展開、L1/L2 タブ、4 frame ON/OFF | 1 | 410 |
| H 詳細 popup | 方角 / 惑星 / 引越し / ACG ライン 4 種 | 4 | 1,409 |
| I 運勢シート | カテゴリスコア表示 + sources × categories グリッド | 1 | 775 |
| J Daily Transit (別画面) | F1-c タイムライン + アスペクトチップ (daily_transit_data は 1b に移動) | 2 | 2,020 |
| K 統合ハブ | map_screen.dart (56 関数、本層 22 ファイル + 他層 ラッパを統合) | 1 | 2,695 |

### 4a.3 群 A: 計算データ + 描画定数 (オーバーライド済、0 本)

旧群 A の 2 ファイルは ✅ 2026-05-14 オーバーライドで他層に明示移動済:
- `map_astro.dart` (508 行) → 層 2a (`/astro/chart` ラッパ + scoreAll、Map+Horo 共用) — 詳細は [`2a.2 表`](#2a.2) 行 7
- `map_constants.dart` (122 行) → 層 3b (HTML `CHART_STYLE` + `PlanetMeta` 純定数) — 詳細は [`3b.2 表`](#3b.2) 行 3

これにより本層 4a は「真の Map 画面 UI のみ」を保持する状態に整理された。

### 4a.4 群 B: UI 基礎部品 (3 本、376 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_widgets.dart`](../lib/screens/map/map_widgets.dart) | 51 | `MapBtn`、`LegendDot` | 円形ボタン (search/layer/vp) + Legend ドット。HTML `.search-trigger / .layer-btn / .vp-btn` 一致 |
| [`map_styles.dart`](../lib/screens/map/map_styles.dart) | 152 | `MapStyle` enum、`MapStyleConfig`、`mapStyleFromId`、`buildStyledTileLayer` | **🔴 タイル 4 種切替** ([`project_solara_map_styles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_styles.md))。`/tiles/osm/hot/*` の Worker 経由 + `sharedTileHttpClient` 使用 ([`feedback_http_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_http_fd_leak.md) 対策) |
| [`map_sectors.dart`](../lib/screens/map/map_sectors.dart) | 173 | `buildSectors`、`buildCompass`、`buildDirLabels` | **16 方位扇状セクター + 8 方向コンパス + 方位ラベル** ([`project_solara_geo_sector`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_geo_sector.md))。`activeCategory` の色 1 色 + alpha のみ可変、red/green 吉凶塗りは禁止 |

### 4a.5 群 C: HUD オーバーレイ (3 本、1,261 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_overlays.dart`](../lib/screens/map/map_overlays.dart) | 481 | `MapSideButtons`、`SearchBarOverlay`、`SearchVpChipRow`、`SelectedDateBadge`、`StatusBadge`、`VpPinVisual`、`RestOverlay`、`buildVpPinMarker`、`showSolaraDatePicker` | Map の HUD 集 9 種。左サイド 3 ボタン (🔍 検索 / ☰ 表示 / 📍 地点) は 2026-05-09 第二弾で配置確定 |
| [`map_menu_chips.dart`](../lib/screens/map/map_menu_chips.dart) | 307 | `MapMenuChips`、`_StaticChip`、`_DailyTransitChip`、`_ChipHalo` | **下部 4 チップ** (Daily / Fortune / Locations / Forecast)。Daily Transit チップは未開封状態判定あり (`_DailyTransitChip`) |
| [`map_time_slider.dart`](../lib/screens/map/map_time_slider.dart) | 473 | `MapTimeSlider` (Stateful) + public `MapTimeSliderState.closeTimeRow` | **タイムスライダー** ±365 日 (1 日刻み) + 時分 (10 分 grid step、表示は実分、`_displayMinuteJst` / `_committedMinuteJst` 分離 = 2026-05-12 Daily Transit 拡張)。LIVE ボタンで今日復帰。PopScope から `closeTimeRow` を呼ばれる |

### 4a.6 群 D: 検索系 (1 本、590 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_search.dart`](../lib/screens/map/map_search.dart) | 590 | `SearchHit`、`SearchResultList`、`SearchFocusPopup`、`directionFrom`、`distanceKmFrom`、`annotateHitsWithScores` | **🔴 Worker `/search` 呼出** (Google Places primary + Nominatim fallback)。検索結果に「現在中心からの方位スコア + 支配カテゴリ」を `annotateHitsWithScores` で注入してから表示。`SearchFocusPopup` で VIEWPOINT / LOCATION 個別登録ボタン |

### 4a.7 群 E: アスペクトライン + ACG モード (3 本、1,686 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_planet_lines.dart`](../lib/screens/map/map_planet_lines.dart) | 285 | `PlanetLineData`、`PlanetSymbolsLayer`、`buildPlanetLineData`、`buildPlanetPolylines` | 10 惑星の MC ライン (経度線) 計算 + 描画。`PlanetSymbolsLayer` は HTML `updateSymPos` の edge tracking 再現 (惑星シンボルが画面端で追従) |
| [`map_astro_lines.dart`](../lib/screens/map/map_astro_lines.dart) | 588 | `AstroFrameStyle`、`astroFrameStyles`、`AstroNadirMarker`、`AstroZenithMarker`、`buildAstroPolylines`、`buildAstroLatitudeBandPolylines`、`buildAstroZenithMarkers`、`buildAstroNadirMarkers` | **4 frame style 定義** (Natal=ゴールド、Transit=オレンジ、Prog=緑、SArc=紫) + アスペクトライン → Polyline 変換 + 天頂帯/天底帯 (latitude band) 描画 + 装飾マーカー (Lewis 理論天頂/天底点) |
| [`map_astro_carto.dart`](../lib/screens/map/map_astro_carto.dart) | 813 | `AstroCartoBanner`、`AcgFrameDef`、`AstroCartoFramePills`、`AstroCartoSubPills`、`_FramePill`、`_SubPill`、`_ScrollableRowPanel`、`AstroCartoCategoryPills`、`AstroZenithPopup` | **🔴 ACG (A*C*G) モード UI**。第 1 層 4 frame ピル + 第 2 層 sub ピル (天頂/天底/天頂帯/天底帯) + カテゴリピル + 天頂点詳細 popup。Astrocarto モードは Solara の海外市場向け売り ([`project_solara_astrocartography_m2`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_astrocartography_m2.md), [`project_solara_lewis_full_impl_plan`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_lewis_full_impl_plan.md)) |

### 4a.8 群 F: マーカー + ロケーション (3 本、1,061 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_location_markers.dart`](../lib/screens/map/map_location_markers.dart) | 295 | `BirthMarker`、`SlotMarker`、`LocationMarkerPopup`、`buildLocationMarkers`、`slotMarker` | 出生地 🌟 (多層グロー) + VP / Locations スロットマーカー + タップ詳細 bottom sheet |
| [`map_vp_panel.dart`](../lib/screens/map/map_vp_panel.dart) | 120 | `VPSlot`、`SlotManager` (singleton 的) | **🔴 VP スロット永続化**。HTML `SlotManager` の Dart 移植 + `syncHome` (プロフィール home を先頭スロットに同期) + `saveCurrentLocation` (reverse geocoding で地名取得) |
| [`map_viewpoint_menu.dart`](../lib/screens/map/map_viewpoint_menu.dart) | 646 | `MapViewpointMenu` (Stateful) | 📍 地点ボタン展開メニュー (2026-05-09 第三弾)。スロット一覧 + 保存 + リネーム + アイコン変更 + 並べ替え + 削除 |

### 4a.9 群 G: 表示メニュー (1 本、410 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_display_menu.dart`](../lib/screens/map/map_display_menu.dart) | 410 | `MapDisplayMenu` (Stateful)、`_MainTab` / `_PlanetSub` enum、`_MenuInfoRow`、`_ChipButton` | **☰ 表示メニュー** (2026-05-09 確定)。L1 タブ (Map/Planet/Astro) × L2 ボタン群 (16 方位/コンパス/MAPSTYLE / 惑星選択 / 4 frame ON/OFF / aspectAll / CHART / FORTUNE)。i ボタン付きで各カテゴリ説明 popup |

### 4a.10 群 H: 詳細 popup (4 本、1,409 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_direction_popup.dart`](../lib/screens/map/map_direction_popup.dart) | 374 | `showDirectionEnergyPopup`、`_PopupBody`、`_EnergyBar`、`_ContribRow` | **🔴 方角タップ詳細 popup**。Soft / Hard 独立 2 バー + 主要寄与アスペクト attribution ([`project_solara_design_philosophy`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md) 中核実装、吉凶判定なし) |
| [`map_planet_intro_popup.dart`](../lib/screens/map/map_planet_intro_popup.dart) | 239 | `showPlanetIntroPopup`、`_PlanetIntroBody` | 惑星マーカータップ説明 (層 1a `planet_intro.dart` 辞書 = 10 惑星 × 3 frame の説明テキスト) |
| [`map_relocation_popup.dart`](../lib/screens/map/map_relocation_popup.dart) | 652 | `MapRelocationPopup` | **🔴 引越し popup** (Phase M0 完成、[`project_solara_relocation_m0`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_relocation_m0.md))。Dart 完結 (`astro_houses.dart` + `astro_lines.dart`)。出生地 → タップ地点の ASC/MC + 12 ハウス + アスペクトライン詳細。ヘッダに **「座標取得」ボタン** (2026-05-24): タップ座標を `緯度, 経度` でクリップボードへ → Horo の `HoroLocationInput` で貼り付け可。同ボタンは `consult_entry_popup.dart` にもあり |
| [`map_line_narrative_sheet.dart`](../lib/screens/map/map_line_narrative_sheet.dart) | 232 | `MapLineNarrativeSheet`、`showLineNarrativeSheet` | ACG ライン (natal/transit) タップ詳細。**Gemini AI 解説は 2026-05-11 撤去**、静的辞書 (`aspect_lines`、`transit_acg`) ベースに統一 ([`project_solara_v7_integration`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_v7_integration.md)) |

### 4a.11 群 I: 運勢シート (1 本、775 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_fortune_sheet.dart`](../lib/screens/map/map_fortune_sheet.dart) | 775 | `FortuneFilterLabel`、`FortuneSheet`、`pctValue`、`showCategoryInfoPopup`、`_FortuneRowsList` (Stateful) | **下部運勢シート** = カテゴリスコアの sources × categories グリッド。`RawScrollbar` + `ListView` で `ScrollController` 共有。`showCategoryInfoPopup` で Map の使い方 + カテゴリ × 関連惑星ペアの説明 |

### 4a.12 群 J: Daily Transit (別画面、2 本、2,020 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_daily_transit_screen.dart`](../lib/screens/map/map_daily_transit_screen.dart) | 1,799 | `MapDailyTransitScreen` (Stateful) + 14 内部 widget (タブバー / ヘッダ / カテゴリ tips / タイムライン本体 / 行 / 高度バッジ / 緯度帯ボックス…)、`showDailyUsageGuidePopup` | **🔴 F1-c フル UI** (2026-04-29 オーナー設計)。10 惑星 × 4 アングル (ASC/MC/DSC/IC) のタイムライン + 各行 🗺 ジャンプ + 「今日の TOP」カテゴリ表示 + L3 Lewis 高度バッジ / 緯度帯。**HARD ファイル分割対象**だが pre-existing |
| [`map_aspect_chip.dart`](../lib/screens/map/map_aspect_chip.dart) | 221 | `MapAspectChip` | Daily Transit 行内の compact アスペクトチップ。soft=銀月色 / hard=金陽色 / tense=金陽色 / neutral=金色。タップで Horo 相タブ相当の詳細解説 popup |

(旧 `daily_transit_data.dart` 1,013 行は ✅ オーバーライドで層 1b に移動済 — 詳細は [`1b.2 表`](#1b.2) 行 9)

### 4a.13 群 K: 統合ハブ (1 本、2,695 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`map_screen.dart`](../lib/screens/map_screen.dart) | 2,695 | `MapScreen` (Stateful)、`MapScreenState` (public state, GlobalKey 経由 `reloadProfile` 公開) | **🔴 Map 統合ハブ**。56 関数 (public 8 + private 48)。30 ファイル import (Map 内 25 + utils 5 + screens 3)。Daily Transit / Forecast / Locations から呼ばれる onClose / onJumpToTime / onJumpToDate コールバックも全て本ファイルで配線。**HARD ファイル分割対象** (pre-existing、別タスク) |

主要な `_*` 関数群:
- ライフサイクル: `_bootstrap`, `_warmupTileConnection`, `_onTileError`, `_loadMapStyle`, `_loadProfileAndChart`, `_moveToInitialCenter`
- 検索: `_doSearch`, `_frameSearchArea`, `_restoreSearchListView`, `_selectSearchHit`, `_buildFocusedHitMarker`, `_buildSearchHitMarkers`, `_reannotateSearchResults`, `_clearAllSearch`
- スコア表示: `_displayScores`, `_sectorRankAlphaMul`, `_cycleActiveCategory`
- ACG モード: `_enterAstroCartoMode`, `_exitAstroCartoMode`, `_filteredFrames`, `_visibleAstroLines`, `_zenith/nadirMarkerFrames`, `_zenith/nadirBandFrames`
- 描画再構築: `_rebuild`, `_kickPaintInvalidation` (= [`project_solara_map_paint_invalidation`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_paint_invalidation.md) 必須対策)
- popup ヘルパー: `_buildZenithPopup`, `_buildRelocationPopup`, `_buildNoProfileGuide`, `_showSearchVpHelpPopup`
- メニュー連携: `_onDisplayMenuTap`, `_onViewpointMenuTap`, `_onSearchTap`, `_onDailyBadgeTap`, `_onOverlayComplete`, `_onDailyTransitClose`
- VP / 拠点: `_setVpOnly`, `_setVpToCurrentLocationOnly`, `_reloadLocationSlots`, `_findNearbyAstroLines`, `_geolocate`

### 4a.14 Worker / 外部呼出 (5 endpoint)

| endpoint | ファイル | 用途 |
|---|---|---|
| `/astro/chart` | [`screens/map/map_astro.dart:17`](../lib/screens/map/map_astro.dart) (2a オーバーライド済) | natal+transit+progressed+ASC/MC/DSC/IC + 全アスペクト計算 |
| `/search` | [`map_search.dart:11`](../lib/screens/map/map_search.dart) | Google Places primary + Nominatim fallback |
| `/tiles/osm/hot/*` | [`map_styles.dart:60,69`](../lib/screens/map/map_styles.dart) (2 リテラル — `osmHot` Light/Dark で別 URL) | OSM Worker 中継タイル (`/tiles/osm/hot/{z}/{x}/{y}.png`) |
| `/tiles/osm/hot/0/0/0.png` | [`map_screen.dart:368`](../lib/screens/map_screen.dart) | `_warmupTileConnection` で起動時 1 枚 prefetch |

**`/fortune` (Gemini) は本層では呼ばない** — Map から触れるのは Forecast / Horoscope 経由のみ。本層の Worker 呼出は天体計算 + 検索 + タイルの 3 種で全部 ([`project_solara_security_principles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_security_principles.md) の `/public/*` 配下想定)。

### 4a.15 機械分類の盲点 + 重要な実態 (✅ オーバーライド適用済)

1. ~~**`screens/map/map_astro.dart` は実態が層 2a**~~ — ✅ 2026-05-14 `PATH_OVERRIDES` で 2a に明示移動済。物理 path は `screens/map/` 配下のまま、リファクタ時に `lib/utils/astro_chart_api.dart` へ移すと自然
2. ~~**`map_constants.dart` は実態が層 3b 寄り**~~ — ✅ 同オーバーライドで 3b に明示移動済
3. **`map_screen.dart` 2,695 行 + `map_daily_transit_screen.dart` 1,799 行は HARD 違反** (`code_audit/audit.py` の 500 行閾値超過) — pre-existing で別タスク
4. ~~**`daily_transit_data.dart` 1,013 行は静的テキスト辞書、実態は層 1b 寄り**~~ — ✅ 同オーバーライドで 1b に明示移動済
5. **Stella 枠は撤去済** ([`project_solara_stella_revival`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_stella_revival.md)) — `map_overlays.dart` の `RestOverlay` のみ残置。常駐再追加禁止

### 4a.16 重要な仕様メモリへの参照 (確定仕様は HTML が正)

Map 関連の確定仕様 / 注意点 / 過去教訓を保持するメモリ:

| メモリ | 内容 |
|---|---|
| [`project_solara_geo_sector`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_geo_sector.md) | やってはいけないこと・廃止済み仕組み (16 方位扇状セクター、red/green 吉凶塗り禁止) |
| [`project_solara_map_render_protocol`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_render_protocol.md) | **🔴 Map 描画エラー対処プロトコル**。タイル抜け/未表示の対応、公式機構、アンチパターン |
| [`project_solara_map_nan_red_screen`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_nan_red_screen.md) | **🔴 Map ズームアウト時の赤画面 (LatLng NaN) 対策** 3 層防御 (minZoom 2.5 + cameraConstraint + onPositionChanged 検知) |
| [`project_solara_map_paint_invalidation`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_paint_invalidation.md) | **🔴 Map 黒画面対策**。5 層目 `_kickPaintInvalidation` (新規 `_mapCtrl.move` には必ずペアで呼ぶ、撤回禁止) |
| [`project_solara_map_styles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_styles.md) | マップタイル 4 種切替実装済 + 将来 MapTiler 独自紫夜空テーマ計画 |
| [`project_solara_a101fc_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_a101fc_fd_leak.md) | 🟢 A101FC fd 枯渇問題は 2026-05-06 Impeller ON で完全解消 |
| [`project_solara_lewis_full_impl_plan`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_lewis_full_impl_plan.md) | ACG/CCG Lewis 理論完全実装ロードマップ 6 フェーズ、合計 26-34h |
| [`project_solara_astrocartography_m2`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_astrocartography_m2.md) | Phase M2 真のアストロカートグラフィー設計 (議論スターター) |
| [`project_solara_relocation_m0`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_relocation_m0.md) | Phase M0 リロケーション + Phase A 静的解説完成状態 |
| [`feedback_forecast_map_separate`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_forecast_map_separate.md) | FORECAST と Map スコアは別計算、Map ジャンプリンク追加しない |
| [`project_solara_i18n_score_bar_labels`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_i18n_score_bar_labels.md) | i18n フェーズで Map スコアバー srcLabels/categoryLabels を英訳する確定案 (B 案) |

### 4a.17 課金検討に直結する示唆

層 4a は **Solara で Pro 機能が最も集中する層**。Map 全体が「無料で見える基盤 + Pro で深まる体験」の戦略の中心。

1. **🔴 Pro 機能の最有力候補ベスト 3 (本層 + 関連層から導出)**
   - **(a) アスペクトライン拡張 (40 → 120 本)** — 層 1a `astro_lines.dart` + 本層 `map_astro_lines.dart` を拡張。Worker コスト 0、クライアント完結。ハード 90° + ソフト 120°/60° 追加で 3 倍
   - **(b) Daily Transit (F1-c) 無制限拠点切替** — 現状 `_selectVp` で `vpSlot` 切替時に再 fetch。Free は home + 現在地 2 拠点制限、Pro は無制限スロット (`SlotManager.slots` 上限解除)
   - **(c) ACG モード 4 frame 同時表示 = Pro 限定** — 現状全員見えているが、Pro 化候補。`map_screen.dart._enterAstroCartoMode` で isPro チェック追加

2. **Gemini 呼出は本層に無いが、Forecast/Horoscope から本層に戻ってくる連携あり**
   - `_openForecast`, `_openLocations` で別画面遷移 → そこから `/fortune`, `/relocation` を呼ぶ
   - **Map 単体は `/public/*` で十分**、Pro ゲートは Forecast/Horoscope 側に置く

3. **タイル消費 = 月額コスト要因**
   - `/tiles/osm/hot/*` は edge cache 24h で抑えられるが、ヘビーユーザーは月数千 req
   - Free は標準 OSM のみ、Pro は MapTiler 独自紫夜空テーマ ([`project_solara_map_styles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_map_styles.md) 将来計画) で差別化 = MapTiler 月額の Pro 課金で回収

4. **永続化 (`VPSlot` / `SlotManager`) はクラウドバックアップ Pro の中心 (Map 側)**
   - 拠点 (出生地 / 自宅 / 旅行先) は **ユーザーの最大の個人データ** = 引越し時の引き継ぎ需要
   - `solara_storage.dart` (層 2b) の `exportAll/importAll` 拡張時に本層の `SlotManager` も含める

5. **`map_screen.dart` 2,695 行 + 56 関数の HARD 違反は Pro 公開前に分割推奨**
   - 候補: ACG モード制御 (`_enterAstroCartoMode` 周辺) を `map_acg_controller.dart` へ
   - 候補: 検索系 (`_doSearch`, `_frameSearchArea`, `_restoreSearchListView`...) を `map_search_controller.dart` へ
   - 候補: build subtree (`_buildBody` 880 行) を分割
   - **緊急度低 (動作には影響なし)**、保守性向上の課金実装段階で着手

6. **Phase M2 残作業の Pro 化判断**
   - [`project_solara_lewis_full_impl_plan`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_lewis_full_impl_plan.md) の L1〜L6 のうち、L3 Lewis 緯度帯 + L4 オーブ塗り は実装済 (`map_astro_lines.dart` + Daily Transit `_LatitudeBandBox`)
   - 残作業 L5/L6 (惑星イベント深化 + オーブ深化) は **Pro 限定で追加**する選択肢あり
   - 「無料は基本 ACG、Pro は Lewis 完全実装 (オーブ塗り / 緯度帯重畳)」の差別化が成立

7. **`map_planet_lines.dart` の `PlanetSymbolsLayer` は HTML 移植が完了済 = 独自性源**
   - 惑星シンボル edge tracking (画面端で惑星が追従) は商用 ACG アプリでも珍しい実装
   - Pro 訴求文素材として価値

8. **検索 (`map_search.dart`) の `annotateHitsWithScores` は無料機能の差別化**
   - Google Places の検索結果に「現在中心からの方位スコア + 支配カテゴリ」を自動注入
   - 競合の地図アプリ + 占いアプリには無い体験 = 無料層の魅力強化に投資する箇所

### 4a.18 機械抽出への参照

層 4a の機械抽出 raw: [`feature_inventory/04a_map.md`](feature_inventory/04a_map.md)

---

## 層 4b: Horoscope 画面

### 4b.1 概要

`lib/screens/horoscope/` 配下 + `lib/screens/horoscope_screen.dart` の **22 ファイル / 計 5,257 行** (オーバーライド適用後)。Map (4a) と並ぶ大規模画面だが、規模は約 4 割 (Map = 13,926 行 vs Horo = 5,257 行)。

**機械分類の精度** (✅ 2026-05-14 オーバーライド適用済): 当初は 25 ファイル / 5,754 行だったが、`PATH_OVERRIDES` で 3 本を他層に明示移動:
- `horo_antique_icons.dart` (295) → 層 3a (16 ファイル横断のアンティークアイコン widget)
- `horo_constants.dart` (86) → 層 1b (signs/planetGlyphs/aspectSymbol/aspectTypes/fortunePlanets 等、13 ファイル横断)
- `horo_aspect_description.dart` (116) → 層 1b (planetInfo/aspectInfo 静的辞書 + `buildAspectDescription` 関数、Map+Horo 共用)

Horoscope の機能領域:

| 機能領域 | 概要 |
|---|---|
| 出生図表示 | 12 星座輪 + 10 惑星 + 4 アングル + アスペクト線描画 (HoroChartWheelPainter) |
| 占いカード生成 | Gemini `/fortune` 経由でカテゴリ別占い文を表示 (5 カテゴリ: 恋愛/豊かさ/仕事/対話/全体) |
| アスペクト一覧 + 解説 | 全アスペクトをリスト表示、タップで `buildAspectDescription` (1b) で解説生成 |
| パターン予測 | Grand Trine / T-Square / Yod の検出 (`detectPatterns`) + 未来予測 (`predictPatternCompletions`) |
| リロケーション | 出生地 → 現住所のチャートを Dart で再計算 + Phase A 静的テンプレ + Phase B Gemini `/relocation` |
| Transit / Progressed 切替 | 現在の星位を natal に重ねる、または進行宮を表示 |
| 出生情報編集 | 地名・日時・座標を直接入力 + reverse geocoding 連動 |

**Pro 公開時の最大対象**: `/fortune` と `/relocation` (Gemini) 呼出が本層に集中。Pro 化候補は **占いカード回数制限 + リロケーション無制限**。

### 4b.2 機能群別ファイル分類 (22 本)

22 ファイルを 8 機能群に整理:

| 群 | 役割 | 数 | 行 |
|---|---|---|---|
| A 統合ハブ | horoscope_screen.dart (24 関数、12 import) | 1 | 754 |
| B 画面分割 extension | `_HoroBackdrop` / `_HoroBottomSheet` / `_HoroChartView` (HoroscopeScreenState 拡張) | 3 | 529 |
| C チャート描画 | チャート輪 + 装飾リング + 惑星グリフ | 3 | 1,014 |
| D データ生成ロジック | `_HoroChartData` extension + pattern_logic 純関数 | 2 | 410 |
| E 共有 UI 部品 | 惑星アイコン / 星座アイコン / アスペクトチェック / 時分ドロップダウン / 情報行 / 解説セクション | 3 | 373 |
| F パネル群 | 出生情報 / リロケーション / 占いカード / パターン予測 / Transit / フィルタ / 惑星表 / アスペクト一覧 | 8 | 1,967 |
| G 静的データ (Horo 内部) | リロケーション解説テンプレ (Phase A) | 1 | 196 |
| H barrel | bottom_panels barrel (旧 1,282 行ファイル分割の互換) | 1 | 14 |

### 4b.3 群 A: 統合ハブ (1 本、754 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`horoscope_screen.dart`](../lib/screens/horoscope_screen.dart) | 754 | `HoroscopeScreen` (Stateful)、`HoroscopeScreenState` (public state、`wakeAnimations` / `pauseAnimations` / `loadProfile` を外部公開) | **Horoscope 統合ハブ**。24 関数 (public 7 + private 17)、12 import (Horo 内 7 + utils 4 + map_astro 1)。Map と同じ `/astro/chart` を `map_astro.dart` の `fetchChart` 経由で呼ぶ (= 層 2a で記述した Map+Horo 共用境界)。`pauseAnimations` で Anim + 寿命タイマー停止 = raster 0% (タブ離脱時の負荷低減) |

主要な `_*` 関数群:
- ライフサイクル: `_resetAnimLifeTimer`, `_stopAnimations`, `_startRotTimer`, `_syncRotationByMode`
- データ取得: `_currentCacheKey`, `_refreshCacheKey`, `_fetchRealChart` (map_astro の fetchChart を呼ぶ), `_loadFortunes` (fortune_api.dart の fortune fetch)
- 状態管理: `_applyWorkingProfile`, `_resetWorkingProfile`, `_profilesEqual`, `_onTransitUpdate`
- UI ヘルパー: `_planetHouse`, `_menuItem`, `_buildHouseModeToggle`, `_toggleSegment`, `_setRelocateMode`

### 4b.4 群 B: 画面分割 extension (3 本、529 行)

`HoroscopeScreenState` を Dart の `extension` 構文で 3 ファイルに分割。各 extension は同じ State インスタンスにアクセスする (analyzer 抑制コメント `invalid_use_of_protected_member` 付き)。

| ファイル | 行 | extension | 役割 |
|---|---|---|---|
| [`horo_backdrop.dart`](../lib/screens/horoscope/horo_backdrop.dart) | 114 | `_HoroBackdrop` | 神秘的背景 (`_mysticalBackdrop`) + プロフィール未設定ガイド (`_buildNoProfile`) |
| [`horo_bottom_sheet.dart`](../lib/screens/horoscope/horo_bottom_sheet.dart) | 224 | `_HoroBottomSheet` | bottom sheet 高さ算出 + タブ切替 + content build (Aspect/Pattern/Transit/Relocate 4 タブ) |
| [`horo_chart_view.dart`](../lib/screens/horoscope/horo_chart_view.dart) | 191 | `_HoroChartView` | 12 星座画像配置 + チャート横スクロール (ピンチズーム) + レジェンド |

### 4b.5 群 C: チャート描画 (3 本、1,014 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`horo_chart_painter.dart`](../lib/screens/horoscope/horo_chart_painter.dart) | 702 | `HoroChartWheelPainter`、`HoroLegendItem`、`_SpreadItem` | **🔴 Horoscope のメイン描画**。12 星座輪 + 10 惑星配置 + 4 アングル + アスペクト線 + ハウス分割。`_spreadOverlappingPlanets` で密集惑星の自動スプレッド (重なり回避)、`_drawVectorGlyph` でベクター惑星グリフ描画 |
| [`horo_ornament_painter.dart`](../lib/screens/horoscope/horo_ornament_painter.dart) | 139 | `HoroOrnamentPainter` | チャート外周の装飾リング + 6 芒星マーカー + 内側ハロ |
| [`horo_astro_glyphs.dart`](../lib/screens/horoscope/horo_astro_glyphs.dart) | 173 | `planetGlyph(String key)` + 10 惑星 private path builder | 10 惑星のベクター Path (`_sun`〜`_pluto`)。チャート描画と panel_shared から使用 |

### 4b.6 群 D: データ生成ロジック (2 本、410 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`horo_chart_data.dart`](../lib/screens/horoscope/horo_chart_data.dart) | 214 | `_HoroChartData` extension | モックチャート生成 + transit/progressed 惑星算出 + アスペクト再計算 (`_recalcAspects`、`_addAspect`、`_approxSunLon`、`_aspectPassesFilter`) |
| [`horo_pattern_logic.dart`](../lib/screens/horoscope/horo_pattern_logic.dart) | 196 | `hasPersonal`、`enoughNatal`、`triKey`、`mockLon` | パターン検出ロジックの純関数。Grand Trine / T-Square / Yod の検出 + パターン完了予測 |

### 4b.7 群 E: 共有 UI 部品 (3 本、373 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`horo_panel_shared.dart`](../lib/screens/horoscope/horo_panel_shared.dart) | 307 | `PlanetVectorIcon`、`ZodiacImageIcon`、`HoroAspectCheckmark`、`HoroHourMinuteDropdown`、`horoAntiqueHeader`、`horoPlanetOrAngleName`、`horoActivePatternKey`、`horoPredictionKey` | Horo panel 系の共有部品集。`PlanetVectorIcon` (惑星グリフ表示)、`ZodiacImageIcon` (星座 webp + 黒透過)、`HoroAspectCheckmark` (☑ 描画)、`HoroHourMinuteDropdown` (時分入力 dropdown) |
| [`horo_desc_section.dart`](../lib/screens/horoscope/horo_desc_section.dart) | 31 | `HoroDescSection` | 「ラベル + 本文」セクション共通枠 (アスペクト/パターン解説で使用) |
| [`horo_info_row.dart`](../lib/screens/horoscope/horo_info_row.dart) | 35 | `HoroInfoRow` | 「ラベル + 値」情報行 (panel 共通) |

### 4b.8 群 F: パネル群 (9 本、2,170 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`horo_birth_panel.dart`](../lib/screens/horoscope/horo_birth_panel.dart) | 336 | `HoroBirthPanel` (Stateful) | **🔴 出生情報入力フォーム** (インライン化済 [`project_solara_horo_birth_inline_form`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_horo_birth_inline_form.md))。名前・日時 + 位置入力は `HoroLocationInput` (下記) に委譲。Sanctuary editor と分離 |
| [`horo_location_input.dart`](../lib/screens/horoscope/horo_location_input.dart) | 271 | `HoroLocationInput` (Stateful) | **位置入力共通ウィジェット** (Birth/Transit 両用)。座標貼り付け (Map「座標取得」でコピーした `緯度, 経度` をクリップボードから取込) + 緯度経度横並び手入力 + reverse geocoding 連動 (地名/TZ 自動)。`showTimezone` で TZ 欄 ON/OFF |
| [`horo_relocation_panel.dart`](../lib/screens/horoscope/horo_relocation_panel.dart) | 422 | `HouseShift`、`HoroRelocationPanel` (Stateful) | **🔴 リロケーション panel** ([`project_solara_relocation_m0`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_relocation_m0.md))。Dart `astro_houses.dart` で現住所チャート再計算 + Phase A 静的テンプレ (`horo_relocation_templates.dart`) + Phase B Gemini `/relocation` (`fortune_api.dart`)。ASC/MC 変化 + 12 ハウス全惑星のシフト表示 |
| [`horo_fortune_cards.dart`](../lib/screens/horoscope/horo_fortune_cards.dart) | 240 | `HoroAstrologyView` | **🔴 Gemini 占いカード表示**。`fortune_api.dart` 経由 `/fortune` で 5 カテゴリ占い文取得 + skeleton loading + error/edit バナー |
| [`horo_prediction_panel.dart`](../lib/screens/horoscope/horo_prediction_panel.dart) | 235 | `HoroPredictionPanel` | パターン予測 panel。アクティブなパターン + 未来予測を `buildAspectDescription` (1b) で解説生成、`showInfoPopup` で詳細表示 |
| [`horo_transit_panel.dart`](../lib/screens/horoscope/horo_transit_panel.dart) | 188 | `HoroTransitPanel` (Stateful) | Transit/Progress (任意日時の星位) を natal に重ねる panel。日付+時刻に加え **場所欄 (`HoroLocationInput`) を持つ** (2026-05-24, option 1)。場所は relocate ハウス=ASC/MC 計算用 (惑星は地心で場所非依存)。初期=現住所→出生地。`onUpdate(when, lat, lng)` で親へ |
| [`horo_planet_table.dart`](../lib/screens/horoscope/horo_planet_table.dart) | 160 | `HoroPlanetTable` | 10 惑星 + ASC/MC + 12 ハウス一覧表 (`_planetHouse` で位置算出) |
| [`horo_aspect_list.dart`](../lib/screens/horoscope/horo_aspect_list.dart) | 184 | `HoroAspectList` | 全アスペクト一覧。タップで `_showAspectDescription` → `buildAspectDescription` (1b) 解説 popup |
| [`horo_filter_panel.dart`](../lib/screens/horoscope/horo_filter_panel.dart) | 134 | `HoroFilterPanel` | アスペクト/パターン絞込チップ (フィルタ + exclusive chip 排他選択) |

### 4b.9 群 G: 静的データ (Horo 内部) (1 本、196 行)

| ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|
| [`horo_relocation_templates.dart`](../lib/screens/horoscope/horo_relocation_templates.dart) | 196 | (惑星 × ハウス) 解説テンプレ const Map | Phase A 静的テンプレ (将来 Gemini 動的生成と同データ構造で互換)。`horo_relocation_panel.dart` のみが import (`fortune_api.dart` はコメント参照のみ) = Horoscope-only 静的データ |

### 4b.10 群 H: barrel (1 本、14 行)

| ファイル | 行 | 役割 |
|---|---|---|
| [`horo_bottom_panels.dart`](../lib/screens/horoscope/horo_bottom_panels.dart) | 14 | 旧 1,282 行 `horo_bottom_panels.dart` の分割互換 barrel。既存 import 互換のため残置 |

### 4b.11 Worker / 外部呼出

**本層は直接の Worker URL リテラルを持たない** (機械抽出で 0 リテラル確認済)。経由する Worker は層 2a 経由:

| 経由 | endpoint | 用途 |
|---|---|---|
| `map_astro.dart` (2a) | `/astro/chart` | natal+transit+progressed+ASC/MC/DSC/IC + 全アスペクト取得 (Map と同じ fetcher) |
| `fortune_api.dart` (2a) | `/fortune` (Gemini) | 5 カテゴリ占い文生成 |
| `fortune_api.dart` (2a) | `/relocation` (Gemini) | リロケーション解説生成 (Phase B) |
| `solara_api.dart` (2a) | `/tz` | 緯度経度→タイムゾーン解決 (`horo_location_input` 経由、Birth/Transit 両用) |
| `reverse_geocode.dart` (2a) | Nominatim 直叩き | 緯度経度→地名 (`horo_location_input` 経由、Birth/Transit 両用) |

= **Gemini 呼出 2 系統 (`/fortune` + `/relocation`) が Horoscope に集中**。Map (4a) は Gemini ゼロ、Horoscope が Gemini 中央。

### 4b.12 機械分類の盲点 + 重要な実態 (✅ オーバーライド適用済)

1. ~~**`horo_antique_icons.dart` は実態が層 3a**~~ — ✅ 2026-05-14 `PATH_OVERRIDES` で 3a に明示移動済。16 ファイル cross-cutting (Map/Galaxy/Horo/no_profile_guide/galaxy_star_atlas)
2. ~~**`horo_constants.dart` は実態が層 1b**~~ — ✅ 同オーバーライドで 1b に明示移動済。13 ファイル cross-screen (Map relocation/line_narrative + Horo 9 + Galaxy も)
3. ~~**`horo_aspect_description.dart` は実態が層 1b**~~ — ✅ 同オーバーライドで 1b に明示移動済。Map (map_aspect_chip) + Horo (3 ファイル) 共用
4. **`horoscope_screen.dart` 754 行は code_audit の WARN 範囲** (HARD 閾値 500 行は超える) — pre-existing で別タスク
5. **`horo_chart_painter.dart` 702 行も WARN/HARD 境界** — チャート描画は責任明確で許容範囲。分割すると `_spreadOverlappingPlanets` 等の連携が複雑化

### 4b.13 重要な仕様メモリへの参照

| メモリ | 内容 |
|---|---|
| [`project_solara_horo_birth_inline_form`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_horo_birth_inline_form.md) | Horo Birth Panel インライン入力フォーム化 (Sanctuary と完全分離・別画面 push 廃止) |
| [`project_solara_relocation_m0`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_relocation_m0.md) | Phase M0 リロケーション + Phase A 静的解説完成状態 |
| [`project_solara_message_tone`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_message_tone.md) | Solara 世界観テキスト文体ルール (Stella=ですます / 真理=体言止) — Horoscope 占いカードに適用 |

### 4b.14 課金検討に直結する示唆

1. **🔴 Gemini 呼出 2 系統が本層に集中 = 課金で守るべき中央**
   - `/fortune` (5 カテゴリ占い文) + `/relocation` (引越し解説) は両方とも `fortune_api.dart` (2a) 経由
   - **回数制限の自然な実装ポイント**: Free は 1 日 1 回 (全カテゴリ一括)、Pro は無制限再生成 + 過去履歴閲覧
   - 既存 KV 月次クォータ (`forecast` だけ実装) と同様の per-IP/per-user カウンタを `/fortune` + `/relocation` にも導入

2. **リロケーション Pro 化候補**
   - Phase A 静的テンプレは無料、Phase B Gemini 動的解説は Pro 限定
   - 既に Phase A/B 並走実装済 ([`project_solara_relocation_m0`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_relocation_m0.md)) なので、Pro ゲートだけ追加すれば差別化が成立
   - 「無料は型通りの解説、Pro はあなた専用の AI 解説」が訴求しやすい

3. **パターン検出 (`horo_pattern_logic.dart`) は Solara 独自の差別化**
   - Grand Trine / T-Square / Yod 検出 + 未来予測は商用占いアプリでも珍しい
   - 無料機能の魅力強化に投資する箇所 = Pro 化対象としては弱い

4. **`horo_chart_painter.dart` の HoroChartWheelPainter は Horoscope の心臓**
   - 12 星座輪 + 惑星スプレッド (`_spreadOverlappingPlanets`) は HTML 移植完了済
   - **Pro 拡張案**: 星座 + 惑星のカスタム配色 (デフォルト + Pro 限定 5 テーマ)、12 星座 webp 高精細版差し替え

5. **占いカード (`horo_fortune_cards.dart`) の skeleton loading は UX 投資**
   - Gemini 応答 3〜5 秒待機中に skeleton 表示で離脱率低減
   - Pro 機能で「カード保存 / シェア / 過去履歴閲覧」を追加すると価値が上がる

6. **`horoscope_screen.dart` 754 行は分割候補だが緊急度低**
   - 既に `_HoroBackdrop` / `_HoroBottomSheet` / `_HoroChartView` extension で 519 行を切り出し済 (本来は 1,273 行相当)
   - さらに分割するなら `_HoroFortune` (fortune loading) / `_HoroAnim` (lifecycle) 追加が候補

### 4b.15 機械抽出への参照

層 4b の機械抽出 raw: [`feature_inventory/04b_horoscope.md`](feature_inventory/04b_horoscope.md)

---

## 層 4c: Observe (Tarot) 画面

### 4c.1 概要

`lib/screens/observe/` 配下 + `lib/screens/observe_screen.dart` の **5 ファイル / 計 1,564 行**。Solara の Tarot タブ (画面名 "Observe" = HTML `tarot.html` の Dart 移植)。

**機械分類の精度** (✅ オーバーライド不要): 5 ファイル全て Observe-only、cross-cutting なし。`observe_constants.dart` (TAROT_READINGS templates、要素別 4 種) も Observe 内のみで参照 = 層維持。

Observe の機能領域:

| 機能領域 | 概要 |
|---|---|
| 1 日 1 引きタロット | 78 枚デッキから 1 枚引き、`DailyReading` (層 1c) に永続化 |
| カード表示演出 | 3D 反転 (`Observe3DCard`)、要素別タロット解説 (火/水/風/地) |
| Gemini 解説生成 | `/tarot` 経由でカードに応じた解説文を生成 (Phase A、要素別テンプレ fallback) |
| 履歴閲覧 | 過去引いたカードの一覧 (`ObserveHistoryPanel`) + 同期入力 |
| 占卓演出 | 5 惑星配置 + 流れ星 + 太陽 blaze の背景シーン (`TarotAltarScene`) |

**Pro 公開時の最大対象**: `/tarot` (Gemini) 呼出が本層に集中、現状は 1 日 1 回固定 = 永続化規律。Pro 化候補は **3 枚引き / 5 枚引きスプレッド** ([`project_tarot_v2_plan`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_tarot_v2_plan.md))。

### 4c.2 ファイル別 役割 + 呼出元 (5 本)

| # | ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|---|
| 1 | [`observe_screen.dart`](../lib/screens/observe_screen.dart) | 524 | `ObserveScreen` (Stateful)、`_ObserveScreenState` | **🔴 Observe 統合ハブ**。17 関数 (public 4 + private 13)、10 import (utils 4 + models 2 + observe 内 4)。`/tarot` (Gemini) を `fortune_api.dart` の `fetchTarotReading` 経由で呼出、失敗時は `_generateReadingStatic` (要素別テンプレ fallback)。`_startTypewriter` で解説文を typewriter 演出 |
| 2 | [`tarot_altar_scene.dart`](../lib/screens/observe/tarot_altar_scene.dart) | 500 | `TarotAltarScene` (Stateful、TickerProvider)、`_TarotAltarSceneState`、`_PlanetDef`、`_AltarLayout` | **占卓背景シーン** ([`project_solara_tarot_altar`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_tarot_altar.md))。5 惑星楕円配置 (北=Moon / 東=Venus 等)、`_scheduleNextMeteor` / `_triggerMeteor` で流れ星演出、`_buildSunBlaze` で太陽光、`_planetSprite` で惑星描画 |
| 3 | [`observe_history.dart`](../lib/screens/observe/observe_history.dart) | 287 | `ObserveHistoryPanel` (Stateful)、`_SyncInput` (Stateful) | 過去引いたタロット履歴 panel。`_confirmClearHistory` で全消去、`_buildHistoryCard` / `_buildHistoryDetail` でカード一覧。`_SyncInput` は同期コード入力用 (将来の引き継ぎ機能用) |
| 4 | [`observe_card_widgets.dart`](../lib/screens/observe/observe_card_widgets.dart) | 198 | `Observe3DCard`、`ObserveCardBack`、`ObserveCardFront`、`ObserveCardInfo` | **3D カード演出 4 種**。`Observe3DCard` は Y 軸反転 (flip) widget、`ObserveCardBack` / `Front` は表裏、`ObserveCardInfo` は要素 + 惑星 + 番号表示 |
| 5 | [`observe_constants.dart`](../lib/screens/observe/observe_constants.dart) | 55 | `tarotReadings` (要素別 4 種 × 2 テンプレ = 8 文)、`planetInfo` (10 惑星 × symbol/nameJP/color)、`elementColors` / `elementNames` / `elementEmojis` (4 元素 × 3 表現) | **静的データ**。Gemini fallback 用のテンプレ文 + 4 元素テーブル。`observe_screen` のみが参照 = Observe-only |

### 4c.3 Worker / 外部呼出

| endpoint | ファイル | 用途 |
|---|---|---|
| `/tarot` (POST、Gemini) | 経由: [`fortune_api.dart`](../lib/utils/fortune_api.dart) (2a) → `fetchTarotReading` | カード + 要素 + 月相 + Stella コンテキストから Gemini で解説文生成。失敗時 null fallback → 要素別テンプレ |

**本層は直接の Worker URL リテラルなし** (機械抽出で 0 リテラル確認済)。Map (4a) は Worker 5 リテラル / Horo (4b) は 0 / Observe (4c) も 0 = Gemini 呼出は全て `fortune_api.dart` (2a) 経由で統一。

### 4c.4 依存関係 (層を跨ぐ参照)

| 依存先 | 用途 |
|---|---|
| `models/tarot_card.dart` (1c) | 78 枚カード定義 (`TarotCard`) |
| `models/daily_reading.dart` (1c) | 1 日 1 引きキャッシュ (`DailyReading`) |
| `utils/tarot_data.dart` (2c) | 78 枚デッキ起動時 initialize singleton |
| `utils/fortune_api.dart` (2a) | `/tarot` Gemini 呼出 |
| `utils/moon_phase.dart` (1a) | カード解説生成時の月相コンテキスト |
| `utils/solara_storage.dart` (2b) | 履歴永続化 (`getDailyReading` / `saveDailyReading` / `clearReadingHistory`) |

### 4c.5 機械分類の盲点 + 重要な実態

1. **5 ファイル全て Observe-only = 機械分類が正しい状態** — `_classify_screen` で `screens/observe/` → 4c 判定が機能している
2. **`tarot_altar_scene.dart` (500 行) は AnimationController あり** だが、画面専用の演出シーンなので 4c が正しい (= 3c 横断 widget とは異なる)
3. **`observe_screen.dart` 524 行は code_audit の WARN 範囲**だが、`_buildDrawPanel` / `_buildReadingPanel` / `_buildLoadingIndicator` 3 build subtree でちょうど 500 行を超えるレベル。許容範囲

### 4c.6 重要な仕様メモリへの参照

| メモリ | 内容 |
|---|---|
| [`project_tarot_v2_plan`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_tarot_v2_plan.md) | タロットアプリ v2 計画 (本格占いプラットフォーム化、カード画像生成、選択式 UI、複合占術) — **Pro 拡張の主要設計** |
| [`project_solara_tarot_cards`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_tarot_cards.md) | Tarot 未実装 Phase 2 (トランジットタロット・拠点設定 UI) |
| [`project_solara_tarot_altar`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_tarot_altar.md) | Tarot 占卓シーン現状設定 (5 惑星配置・楕円半径・流れ星仕様・生成スクリプト) |
| [`project_seimei_tarot`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_seimei_tarot.md) | 独自占術「姓名×タロット」設計 (母音重視 9 分類、変換テーブル、動画集客構想) |

### 4c.7 課金検討に直結する示唆

層 4c は **Pro 機能の差別化最有力候補**。Tarot は商用占いアプリで最も人気のジャンル、Solara はここで独自路線 (両面思想 + AI 解説 + 月相連動) を打ち出せる位置。

1. **🔴 Pro 機能の最有力候補ベスト 3 (本層から導出)**
   - **(a) 3 枚引き / 5 枚引きスプレッド** ([`project_tarot_v2_plan`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_tarot_v2_plan.md)) — Free は 1 日 1 引き、Pro は無制限 + 多枚引き。`_drawCard` の枚数制御 + UI 追加で実装可
   - **(b) 任意カード手動選択 (選択式 UI)** — 同上 v2 計画。「気になるカードを選んで読む」体験は商用差別化軸
   - **(c) 過去履歴の検索 + フィルタ** — 現状 `ObserveHistoryPanel` は時系列のみ。Pro は要素別 / 期間別 / キーワード検索追加

2. **`/tarot` Gemini 呼出の回数制限 = Free/Pro の自然な境界**
   - 現状 1 日 1 回固定。境界は「1日の開始時刻」設定基準の論理日 + 単調ガード (`_checkTodayReading` / `hasDrawnFreeTarotToday`)
   - Free は 1 日 1 回維持、Pro は無制限再生成 (= 引き直し)
   - `fortune_api.dart` の Gemini 呼出に per-IP/per-user カウンタを追加 (Horoscope の `/fortune` と同じ仕組み)

3. **独自占術「姓名 × タロット」** ([`project_seimei_tarot`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_seimei_tarot.md))
   - 母音重視 9 分類 + 変換テーブルで姓名と日付からカードを推定
   - 動画集客構想付き = **Pro 限定の独自占術** として位置付ければ集客効果も
   - 現状未実装、新規 panel + utils 関数で実装可

4. **`tarot_altar_scene.dart` の占卓背景は無料機能の魅力源**
   - 5 惑星 + 流れ星 + 太陽 blaze の演出は商用 Tarot アプリでも珍しい
   - Pro 化対象としては弱いが、無料層の魅力強化に投資する箇所
   - Pro 拡張案: 「占卓を月相 / 時刻で変える」(満月時は満月、新月時は新月の背景)

5. **`tarotReadings` 静的テンプレは「Gemini 失敗時の fallback」**
   - 要素別 4 種 × 2 テンプレ = 8 文のみ、繰り返し感あり
   - **Pro 拡張案**: テンプレ拡張 (要素 × 月相 × 引き枚数で多様化)、または Pro は常に Gemini 動的、Free は静的テンプレ + Gemini 1 日 1 回

6. **`Observe3DCard` の 3D flip は HTML 移植完了済 = 独自性源**
   - Y 軸反転 + perspective transform で物理感のあるカードフリップ
   - Pro 拡張案: 反転速度 / 効果音 / カード素材 (デフォルト + Pro 5 種) のカスタマイズ

7. **`DailyReading` モデル (1c) のクラウドバックアップ Pro**
   - 過去履歴は **ユーザーの最大の体験ログ** = 引き継ぎ需要
   - 機種変更時に履歴消失すると離脱リスク = Pro 課金で守る価値

### 4c.8 機械抽出への参照

層 4c の機械抽出 raw: [`feature_inventory/04c_observe.md`](feature_inventory/04c_observe.md)

---

## 層 4d: Galaxy 画面

### 4d.1 概要

`lib/screens/galaxy/` 配下 + `lib/screens/galaxy_screen.dart` の **6 ファイル / 計 2,408 行**。Solara の Galaxy タブ = **「占いをしない、節目で自己と対話する」体験の心臓部**。

**機械分類の精度** (✅ オーバーライド不要): 6 ファイル全て Galaxy 専用、cross-cutting なし。

Galaxy の機能領域:

| 機能領域 | 概要 |
|---|---|
| 月相サイクル可視化 | 新月→満月→刻星化 (catasterism) の 1 サイクル全日数を 3 層スパイラルで表示 |
| Stella メッセージ | 月相連動メッセージ表示。新月/満月の当日・72h 以内は発生時刻 (端末ローカル) を告知優先、それ以外は月齢を 3 日ごと 10 区分に分けた癒しメッセージ (日英各 100・日替わりランダム、`galaxy_stella_messages.dart`) |
| 意図と振り返り記録 | 新月で `LunarIntention` 入力 → 満月で `MidpointCheck` → 刻星化で `CatasterismResult` |
| 星座生成 (= 刻星化) | サイクル完了時に MST edges + 形容詞 × 名詞で星座生成 (`constellation_namer`) |
| Star Atlas (図鑑) | 過去刻星化した星座コレクション (61 星座まで) |
| 天体イベントバー | `/astro/events` 取得結果を画面下部に常時横スクロール表示 |
| Replay overlay | 過去サイクルの星座を再生表示 |

**Pro 公開時の立場**: 本層は **Solara の最大差別化体験 = Pro 化対象として不適切**。Pro 化すると独自性が消える。代わりに「過去サイクルアルバム」「形成演出の任意再生」「カスタム背景画像」が Pro 拡張案 ([`project_galaxy_spec`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_galaxy_spec.md))。

### 4d.2 ファイル別 役割 + 呼出元 (6 本)

| # | ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|---|
| 1 | [`galaxy_screen.dart`](../lib/screens/galaxy_screen.dart) | 1,269 | `GalaxyScreen` (Stateful)、`GalaxyScreenState` (public state、`regenerateBackground` / `pauseMotion` を外部公開) | **🔴 Galaxy 統合ハブ**。41 関数 (public 9 + private 32)、19 import (層 1a/1b/1c/2a/2b/3a/3c/widgets + galaxy 内 5)。本層で最大規模、画面のほぼ全部の状態とロジックが集中 |
| 2 | [`galaxy_star_atlas.dart`](../lib/screens/galaxy/galaxy_star_atlas.dart) | 460 | `GalaxyStarAtlasTab`、`_AtlasHeader`、`_ConstellationCard`、`_EmptyState` | **STAR ATLAS タブ** (HTML `.atlas-content` 移植)。過去刻星化した星座のグリッドコレクション (最大 61 星座 = `constellation_namer` の名詞テーブル数)。`MiniConstellationPainter` (3a) で各カード描画 |
| 3 | [`galaxy_replay_overlay.dart`](../lib/screens/galaxy/galaxy_replay_overlay.dart) | 160 | `GalaxyReplayOverlay` (Stateless) | 過去サイクルの星座を再生表示する overlay。`ConstellationPainter` (3a) で full-size 描画、`cameraAngle` 制御で anamorphic 3D 効果 |
| 4 | [`galaxy_constellation_builder.dart`](../lib/screens/galaxy/galaxy_constellation_builder.dart) | 130 | (関数のみ、class なし) | サイクル完了時の星座構築ヘルパー。`daily_reading` 履歴 + `moon_phase` + `tarot_data` + `constellation_namer` を組み合わせて 1 サイクル分の `GalaxyCycle` (1c) を生成 |
| 5 | [`galaxy_sample_data.dart`](../lib/screens/galaxy/galaxy_sample_data.dart) | 101 | `injectGalaxySampleData`、`_buildSampleFromTemplate` | **デモ用サンプルデータ注入**。Cycle に 25 個の星 + Star Atlas に 61 全星座を仮データで埋める。開発・デモ用 (本番ユーザーには表示されない) |
| 6 | [`galaxy_stella_messages.dart`](../lib/screens/galaxy/galaxy_stella_messages.dart) | 288 | `moonHealingMessage(now, isJP)` (関数のみ、class なし) | **Stella 癒しメッセージ辞書**。月齢を 3 日ごと 10 区分に分け、各区分に月相に沿った癒しメッセージを日英各 10 個 (計 200)。日付シードで日替わりランダム選択 (再描画では固定)。文面方針: 時間帯を断定しない / 分かりにくい比喩を避ける / どんな状態も否定しない / 見守る「私たち」の声。`galaxy_screen._buildStellaMessage` が月相告知の無い日に呼ぶ |

### 4d.3 `galaxy_screen.dart` の主要関数 (41 関数)

最大規模の単一ファイル (1,269 行) の中身を把握:

**ライフサイクル + 状態**
- `regenerateBackground` (public) — タブ切替時にネビュラ位置/色/星を再生成
- `pauseMotion` (public) — タブ離脱時 Timer 即停止 = raster 0%
- `_wakeMotion` / `_onMotionTick` — モーション再開と tick 処理
- `_loadData` — `SolaraStorage` から `LunarIntention` / `CatasterismResult` / 履歴を読込
- `_loadArtImage` — 星座イラスト画像の preload
- `_initNebulaPositions` / `jitter` — 背景のランダム配置

**月相 overlay 制御 (4d → 3c の連携)**
- `_checkMoonOverlay` — 月相日判定 → 新月 / 満月 / 刻星化 overlay 表示
- `_buildMoonOverlay` — NewMoonOverlay / FullMoonOverlay / CatasterismOverlay (3c) 分岐
- `_onCatasterismResult` — 刻星化結果保存 → 次画面 (`CatasterismFormationOverlay` 3c) へ
- `_onFormationComplete` — 形成演出完了 → 次サイクル開始

**Cycle タブ (= メイン表示)**
- `_buildCycleTab` — 3 層スパイラル (`CycleSpiralPainter` 3a) + Stella メッセージ + バッジ
- `_buildDayBadge` / `_buildMoonBadge` — サイクル日カウント + 月相バッジ
- `_buildStellaMessage` — 月相連動メッセージ。新月/満月の当日・72h 以内は発生時刻 (端末ローカル) 告知を優先、それ以外は `moonHealingMessage` (月齢別の癒しメッセージ・日替わり) にフォールバック
- `_moonPhaseDescription` — 月相の文字列表現

**ドット タップ / ドラッグ (= スパイラル操作)**
- `_onDragStart` / `_onDragUpdate` / `_onDragEnd` / `_onTapUp` — ジェスチャー処理
- `_showDotPopup` / `_hideDotPopup` / `_buildDotPopup` — タップ詳細 popup

**Replay**
- `_openReplay` / `_closeReplay` — Replay overlay の表示制御

**デバッグトリガ** (オーナー検証用)
- `_buildDebugTriggerRow` / `_buildDebugBtn` — 4 ボタン (新月 / 満月 / 刻星化 / サイクル完了)
- `_debugTriggerNewMoon` / `_debugTriggerFullMoon` / `_debugTriggerCatasterism` / `_debugTriggerCycleCompletion`

**ヘルプ**
- `_showGalaxyUsageGuide` — `showInfoPopup` で使い方説明

### 4d.4 依存関係 (層を跨ぐ参照)

Galaxy は 1b/1c/2a/2b/3a/3c に強く依存:

| 依存先層 | ファイル | 用途 |
|---|---|---|
| 1a 純計算 | `moon_phase.dart` | 月相計算 (Jean Meeus アルゴリズム、新月時刻 + 満月時刻 + サイクル日数) |
| 1b 静的辞書 | `constellation_namer.dart` (Galaxy の心臓的 dictionary)、`cycle_story_texts.dart`、`horo_constants.dart` | 星座名生成 + 月相ストーリー + 共有定数 |
| 1c モデル | `galaxy_cycle.dart`、`lunar_intention.dart`、`daily_reading.dart` | 永続化対象 3 種 |
| 2a API | `celestial_events.dart` | `/astro/events` で天体イベント取得 |
| 2b 永続化 | `solara_storage.dart` | `LunarIntention` / `MidpointCheck` / `CatasterismResult` / 履歴の保存 |
| 2c global | `tarot_data.dart` | 78 枚デッキ起動時 initialize singleton (Galaxy はカード履歴と組合せる) |
| 3a 共通 widget | `cycle_spiral_painter.dart`、`constellation_painter.dart` (full + mini)、`celestial_event_bar.dart`、`info_popup.dart`、`horo_antique_icons.dart` (4b→3a override 経由) | スパイラル描画 + 星座描画 + 天体イベントバー + popup + アイコン |
| 3c 演出 | `catasterism_formation_overlay.dart`、`moon_overlay.dart` (re-export = NewMoon / FullMoon / Catasterism 3 種) | 月 overlay 4 種の駆動主 |

### 4d.5 Worker / 外部呼出

| 経由 | endpoint | 用途 |
|---|---|---|
| `celestial_events.dart` (2a) | `/astro/events` (GET) | 月別天体イベント (ingress / retrograde / eclipse) を画面下部バーに表示 |

**Gemini 呼出は 0** — Galaxy は AI 解説を使わない、純粋な可視化 + 自己対話の場 ([`project_solara_design_philosophy`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md))。

### 4d.6 機械分類の盲点 + 重要な実態

1. **5 ファイル全て Galaxy-only = 機械分類が正しい状態**
2. **`galaxy_screen.dart` 1,167 行は HARD 違反** (`code_audit/audit.py` の 500 行閾値超過) — pre-existing
   - 候補: Replay 制御 (`_openReplay` / `_closeReplay` / `_buildReplayOverlay`) を `galaxy_replay_controller.dart` へ
   - 候補: デバッグトリガ 4 関数 (`_debugTrigger*`) を `galaxy_debug.dart` へ (現状本番でも `_buildDebugTriggerRow` ボタン残置)
   - 候補: タップ/ドラッグ 4 関数を `galaxy_gesture.dart` へ
   - **緊急度低 (動作には影響なし)**、Pro 公開前のリファクタ候補
3. **デバッグトリガ 4 ボタンは本番にも残置** — オーナーが新月/満月/刻星化体験をすぐ確認できるよう保持。`kDebugMode` ガード未適用 (将来検討)

### 4d.7 重要な仕様メモリへの参照

| メモリ | 内容 |
|---|---|
| [`project_galaxy_spec`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_galaxy_spec.md) | **🔴 Galaxy 未実装タスク**: 星座イラスト未生成 (61 種のうち未生成あり) + Flutter 移植進捗 + 天体イベント 2027+ 対応 |
| [`project_solara_design_philosophy`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md) | 🔴 Solara 全機能上位ルール: Soft/Hard 独立 2 エネルギー、吉凶判定禁止、total/ratio/赤緑色分け禁止 — **Galaxy は本ルールに忠実な実装** |
| [`project_solara_message_tone`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_message_tone.md) | Solara 世界観テキスト文体ルール (Stella=ですます / 真理=体言止) — Galaxy Stella メッセージに適用 |

### 4d.8 課金検討に直結する示唆

層 4d は **Solara の独自性の心臓 = Pro 化対象として不適切**。代わりに「体験の深さ」を強化する Pro 拡張が向く。

1. **🔴 Galaxy 本体は Pro 化しない**
   - 月相サイクル + 新月意図 + 満月チェック + 刻星化 = Solara の最大差別化体験
   - 「占いをしない、節目で自己と対話する」哲学を体現
   - Pro 化すると Solara の独自性が見えなくなる = **無料機能の中心として保護**

2. **Pro 拡張案 (Galaxy 周辺)**
   - **(a) 過去サイクルアルバム**: `GalaxyCycle` 履歴の長期保存 + 検索 + 月別ハイライト
   - **(b) 形成演出 (`CatasterismFormationOverlay`) の任意再生**: 「お気に入りの刻星化体験を見返す」
   - **(c) カスタム背景画像**: Galaxy 背景ネビュラを Pro 限定 5 種から選択
   - **(d) 星座テキストエクスポート**: `CatasterismResult` を Markdown / 画像で書き出し (シェア)
   - **(e) 星座イラスト高精細版差し替え**: ([`project_galaxy_spec`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_galaxy_spec.md)) Pro 限定で 61 種完全版アクセス

3. **`constellation_namer.dart` (1b) は Galaxy の心臓**
   - 形容詞 × 名詞テーブル + MST 構築 + レア度算出
   - 既に「2026-04-25 v2 完成」状態、Pro/Free 境界に置きづらい
   - Pro 拡張は「希少星座出現確率」を Pro で表示するくらい (= 訴求弱め)

4. **`LunarIntention` / `MidpointCheck` / `CatasterismResult` のクラウドバックアップ Pro**
   - 過去サイクルの意図と振り返りはユーザー最大の体験ログ
   - 機種変更時消失で離脱リスク = **Pro 課金で守る最優先データ**
   - 既出 ([`solara_storage.dart`](../lib/utils/solara_storage.dart) 層 2b で議論)

5. **`/astro/events` 呼出は無料機能の差別化要素**
   - 月別天体イベントバーは商用占いアプリでも珍しい
   - Pro 化対象としては弱い、無料層の魅力強化に投資

6. **Galaxy 1,167 行のリファクタは Pro 公開前のクリーンアップ**
   - 緊急度低だが、Pro 機能追加時 (例: アルバム panel 追加) で衝突回避のため事前分割推奨

### 4d.9 機械抽出への参照

層 4d の機械抽出 raw: [`feature_inventory/04d_galaxy.md`](feature_inventory/04d_galaxy.md)

---

## 層 4e: Sanctuary 画面

### 4e.1 概要

`lib/screens/sanctuary/` 配下 + `lib/screens/sanctuary_screen.dart` の **8 ファイル / 計 4,702 行**。Solara の Sanctuary タブ = **アプリ設定 + プロフィール + 144 称号診断儀式 + Pro アップグレード UI**。

**機械分類の精度** (✅ オーバーライド不要): 8 ファイル全て Sanctuary 専用。`sanctuary_profile_editor.dart` は Horoscope (2 ファイル) から `Navigator.push` で遷移されるが、これは画面遷移であって cross-cutting widget ではない (= 層維持)。

Sanctuary の機能領域:

| 機能領域 | 概要 |
|---|---|
| プロフィール編集 | 名前・出生情報 (日時・座標・地名)・言語切替・場所検索 + reverse geocoding。※ プライバシーで誕生日・住所の値は一覧非表示 (「設定済み/未設定」のみ、行はタップで編集) |
| ホーム地点設定 | 現住所の座標 + 地名 (Map VP slot と同期) |
| クレジット残表示 | 最上段に Stella/タロット クレジット残を 1 行表示 (`ConsultationCredits.instance.status` を直接参照、自身では fetch しない)。非Pro=無料週次残+購入残、Pro=無制限 |
| Cosmic Pro 装飾 | Pro 契約時、最上段ヘッダーをアンティーク金二重枠で囲み、画面背景に神殿画像 (`assets/sanctuary-bg/pro.webp`) を薄く (opacity 0.20) 重ねる |
| 🔴 144 称号診断儀式 | 25 クラス × Light/Shadow 両面の診断、3 ラウンドカード選択 + Forging 演出 + Reveal |
| クラスカードシェア | 診断結果カードを画像生成して シェア (`_buildShareImage` + share_plus) |
| Orb 設定 | アスペクトオーブ (天体間角度の許容範囲) 8 種カスタマイズ |
| デイリーリセット時刻 | 「1日の開始時刻」= 日次タロット引き + 月相 overlay の論理日の基準 (時:分、1 分単位)。Horo 星読みは0時基準で対象外 |
| 🔴 Cosmic Pro アップグレード UI | **既に UI 実装済**: $9.99/月 + $49.99/年、訴求文「Aether shaders · Galaxy Archive · Advanced astrology」 |
| アプリ設定 | 言語切替、ハウスシステム選択 (Placidus/Whole Sign — `SolaraStorage.loadHouseSystem`/`saveHouseSystem` + 同期キャッシュ `currentHouseSystem` 経由で Horo・Map・Locations のチャート計算と Map relocation popup に反映)、利用規約等 |

### 4e.2 ファイル別 役割 + 呼出元 (8 本)

| # | ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|---|
| 1 | [`sanctuary_screen.dart`](../lib/screens/sanctuary_screen.dart) | 1,400 | `SanctuaryScreen` (Stateful)、`_SanctuaryScreenState`、`_SettingsGroup`、`_SettingsItem`、`_WidgetOpacity` extension | **🔴 Sanctuary 統合ハブ**。最上段にクレジット残行 (`_buildTopHeader`/`_buildCreditRow`)、Pro 時はアンティーク金枠 + 神殿背景 (`_proBgDecoration`)。Settings 構造: プロフィール / 称号診断 / **Cosmic Pro** / 占星術 / アプリ設定。`_buildCosmicProSection` が Pro 訴求 UI |
| 2 | [`sanctuary_title_diagnosis.dart`](../lib/screens/sanctuary/sanctuary_title_diagnosis.dart) | **1,385** | `SanctuaryTitleDiagnosisPage` (Stateful)、`_SanctuaryTitleDiagnosisPageState` | **🔴 144 称号診断儀式** (本層最大ファイル)。22 関数 (public 4 + private 18)。フェーズ: `_buildSummoning` → `_buildIntro` → `_buildRound` (3 ラウンド) → `_buildPartTrans` → `_buildForging` → `_buildReveal` (Light + Shadow 両面)。出生情報からの astro seed (`_pickByAstroSeed`) + ユーザー選択カードの組合せで 144 称号を確定 |
| 3 | [`sanctuary_profile_editor.dart`](../lib/screens/sanctuary/sanctuary_profile_editor.dart) | 585 | `SanctuaryProfileEditorPage` (Stateful)、`_SanctuaryProfileEditorPageState`、`DateSlashFormatter` (TextInputFormatter) | プロフィール編集ページ。Place search (`/search` 経由) + 言語切替ボタン + 出生情報 (日時 YYYY/MM/DD + HH:MM + 座標) + `_resolveTimezone` で `/tz` 呼出 + `LocationPickerMinimap` (3a) で座標微調整。Horo (horo_birth_panel, horo_transit_panel) から `Navigator.push` で遷移される |
| 4 | [`class_share_card.dart`](../lib/screens/sanctuary/class_share_card.dart) | 447 | `ClassShareCardPage` (Stateful)、`_ClassShareCardPageState` | クラスカードシェア用ページ。`_buildShareImage` で `RepaintBoundary` から画像生成 → `share_plus` で OS 共有シート。`ClassCard` widget (3a) を使ってカード表示 |
| 5 | [`sanctuary_orb_overlay.dart`](../lib/screens/sanctuary/sanctuary_orb_overlay.dart) | 266 | `SanctuaryOrbOverlay` (Stateful)、`_OrbSectionLabel` | アスペクトオーブ設定 overlay。8 アスペクト (合/衝/三/矩/六/Qx/SemiSx/SemiSq) × オーブ値 (0-3°)。+/- ボタンで 0.1° 単位調整、リセット可能 |
| 6 | [`sanctuary_home_editor.dart`](../lib/screens/sanctuary/sanctuary_home_editor.dart) | 227 | `SanctuaryHomeEditorPage` (Stateful)、`_SanctuaryHomeEditorPageState` | ホーム地点 (現住所) 編集ページ。`_search` (Worker `/search`) + `LocationPickerMinimap` (3a) で座標微調整 + 保存時 Map VP slot と同期 |
| 7 | [`title_how_it_works.dart`](../lib/screens/sanctuary/title_how_it_works.dart) | 201 | `TitleHowItWorksContent` (Stateless) | 称号システムの仕組み説明 popup の中身 (HTML移植)。`showInfoPopup` (3a) 経由で表示、25 クラス × Light/Shadow の概念説明 |
| 8 | [`sanctuary_reset_hour_picker.dart`](../lib/screens/sanctuary/sanctuary_reset_hour_picker.dart) | 190 | `SanctuaryResetHourPicker` (Stateful)、`_SanctuaryResetHourPickerState` | 時:分 ピッカー widget。時 dropdown + 分 dropdown (1 分単位、24h)。日次タロット引きの基準時刻設定 |

### 4e.3 🔴 Cosmic Pro UI 既存実装の発見 (sanctuary_screen.dart `_buildCosmicProSection`、L653-724)

**重要**: Sanctuary 設定画面に **Cosmic Pro アップグレード UI が既に実装済**。HTML mockup 移植由来。

```dart
// 訴求バナー
Text('Upgrade to Cosmic Pro')  // gradient gold
Text('Aether shaders · Galaxy Archive · Advanced astrology')  // 訴求 3 機能
Row(['$9.99', '/month'])       // 価格
Container('Unlock Cosmic Pro ✦')  // CTA ボタン
Text('$49.99/year · Cancel anytime')  // 年額 + キャンセル可
```

**確定済の Pro 訴求要素**:
- 価格: **$9.99/月** または **$49.99/年** (= 月換算 $4.16)
- キャンセル可
- 訴求 3 機能:
  1. **Aether shaders** — 演出強化系 (本層 3a/3c での painter テーマ拡張と整合)
  2. **Galaxy Archive** — 過去サイクルアルバム ([`project_galaxy_spec`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_galaxy_spec.md) + 層 4d.8 で提案した Pro 拡張 (a) と完全一致)
  3. **Advanced astrology** — アスペクトライン拡張 + ACG 4 frame (層 4a.17 で提案した Pro 候補 (a)(c) と完全一致)

**実装状態**: UI のみ実装、機能ゲート (`isPro` 判定 / RevenueCat 連携 / Apple In-App Purchase / Google Play Billing) は未実装。Pro 機能の本実装は [`project_solara_security_principles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_security_principles.md) + [`project_solara_launch_checklist`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_launch_checklist.md) で計画済。

**示唆**: 訴求文 3 機能が **本人手版インベントリで導出した Pro 候補と完全に一致** = 当初の設計意図と機能インベントリの方向性が整合している証拠。

### 4e.4 144 称号診断儀式 (`sanctuary_title_diagnosis.dart`、1,385 行)

本層の最大ファイル、Sanctuary の中核体験。

**儀式フェーズ** (sanctuary_screen `_startDiagnosis` 経由で起動):

| フェーズ | 関数 | 内容 |
|---|---|---|
| 召喚 | `_buildSummoning` | 出生情報から astro seed を生成 (`_pickByAstroSeed`)、神秘的演出 |
| 序章 | `_buildIntro` | 儀式の世界観説明 + 開始ボタン |
| 3 ラウンド | `_beginRounds` → `_buildRound` | ユーザーが 3 ラウンドで 1 枚ずつカード選択 (`_selectCard`) |
| 移行 | `_buildPartTrans` | ラウンド間の演出 |
| 鍛造 | `_buildForging` | 選んだカードと astro seed を組合せて称号を「鍛造」する演出 |
| Reveal | `_buildReveal` → `_buildRevealLightSide` / `_buildRevealShadowSide` | Light 面 + Shadow 面の両面表示、`_toggleShadowSide` で切替 |

**永続化**: `_finishDiagnosis` で `SolaraStorage` に保存。診断結果は再診断 (`_acceptPrevious` で前回結果比較可) もできる。

**設計思想**: 25 クラス × Light/Shadow (両面) = 25 × 2 = 50 の表示パターン + 144 称号 (12 太陽部位 × 12 月部位) ([`project_solara_title_system`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_title_system.md))。

### 4e.5 Worker / 外部呼出

| 経由 | endpoint | 用途 |
|---|---|---|
| `solara_api.dart` (2a) | `/tz` (GET) | 出生地のタイムゾーン解決 (`sanctuary_profile_editor._resolveTimezone`) |
| Worker `/search` (4a `map_search.dart` 経由ではなく直接) | `/search` (GET) | プロフィール編集 + ホーム編集の場所検索 (`_searchPlace` / `_search`) |
| `reverse_geocode.dart` (2a) | Nominatim 直叩き | (`location_picker_minimap` 3a 内部で使用) |

**Gemini 呼出 0** — Sanctuary は AI 解説を使わない設定画面。

### 4e.6 依存関係 (層を跨ぐ参照)

| 依存先 | 用途 |
|---|---|
| 1b 静的辞書 | `title_data.dart` (144 称号データ + 25 class + `getSunSign` / `getMoonSign`) |
| 2a API | `solara_api.dart` (`/tz`)、`solara_storage` 経由間接 |
| 2b 永続化 | `solara_storage.dart` (SolaraProfile + dailyResetHour/Minute + 称号結果 + Map style + Orb 設定) |
| 2a (準) | `app_locale.dart` (言語切替) |
| 3a 共通 widget | `class_card.dart` (144 称号カード)、`location_picker_minimap.dart` (座標選択)、`info_popup.dart` |

### 4e.7 機械分類の盲点 + 重要な実態

1. **8 ファイル全て Sanctuary-only = 機械分類が正しい状態**
   - `sanctuary_profile_editor` は Horo 2 ファイルから `Navigator.push` 遷移されるが、これは画面遷移であって widget 共有ではない
2. **`sanctuary_title_diagnosis.dart` 1,385 行は最大 HARD 違反** — pre-existing
   - 候補: フェーズごとに切り出し (`title_diagnosis_summoning.dart` / `_rounds.dart` / `_forging.dart` / `_reveal.dart`)
   - 緊急度低 (動作には影響なし)、リファクタは Pro 機能本実装と同時推奨
3. **`sanctuary_screen.dart` 1,034 行も HARD** — 5 セクション (`_buildStellarProfileSection` / `_buildTitleDiagnosisSection` / `_buildCosmicProSection` / `_buildAstrologySection` / `_buildAppSection`) を切り出すと 600 行台に減らせる
4. **`class_share_card.dart` 447 行は WARN 範囲** — `_buildShareImage` の `RepaintBoundary` + 画像保存は責任明確、許容範囲

### 4e.8 重要な仕様メモリへの参照

| メモリ | 内容 |
|---|---|
| [`project_solara_title_system`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_title_system.md) | **🔴 称号未実装タスク**: EN 版 144 称号 + 言語切替機能 (現状 JP のみ) |
| [`project_solara_launch_checklist`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_launch_checklist.md) | **🔴 Solara 公開前チェックリスト** (永続タスク管理、Phase 0 アカウント/法務 〜 Phase 6 段階リリース) |
| [`project_solara_security_principles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_security_principles.md) | **🔴 Solara Pro 公開時セキュリティ多層防御原則** (RevenueCat Trusted Entitlements + App Attest / Play Integrity + `/protected/*` 物理分離) |
| [`project_appstore_small_business`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_appstore_small_business.md) | **🔴 公開前必須**: Apple/Google Small Business Program 申請 (手数料 30→15%) |
| [`feedback_i18n_last`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_i18n_last.md) | i18n は公開直前まで保留 (EN 称号は保留中) |

### 4e.9 課金検討に直結する示唆

層 4e は **Pro 公開時の UI ハブ + 課金訴求の中央**。

1. **🔴 Cosmic Pro UI 既存実装 = 公開時の最大資産**
   - 価格 $9.99/月 + $49.99/年は既決定 (年額は月換算 $4.16 で 58% off = アンカリング有効)
   - 訴求 3 機能 (Aether shaders / Galaxy Archive / Advanced astrology) は他層で導出した Pro 候補と完全一致 = **設計意図と機能インベントリが整合**
   - **残作業**: RevenueCat 連携 + Apple/Google IAP 連携 + `isPro` 判定 + `/protected/*` ルート分離
   - 公開前チェックリスト ([`project_solara_launch_checklist`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_launch_checklist.md)) の Phase 3〜5 で実装

2. **🔴 144 称号診断儀式 = 無料機能の最大差別化**
   - 25 クラス × Light/Shadow + 144 細分化 = 「あなただけの結果」を作る独自体験
   - **Pro 化対象としては不適切** (これを Pro 化すると初期体験ができなくなる)
   - 代わりに **Pro 拡張案**: シェアカードの追加デザイン、月別称号変化追跡、図鑑/コレクション

3. **EN 版 144 称号未実装 = 海外展開のボトルネック**
   - 現状 JP のみ ([`project_solara_title_system`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_title_system.md))
   - i18n は公開直前まで保留 ([`feedback_i18n_last`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_i18n_last.md))
   - EN 称号を Pro 限定 / 無料の境界に置くかどうかは戦略判断 — **私の推奨は無料**(海外初期体験を阻害しないため)

4. **`class_share_card.dart` (シェア機能) = Pro 拡張に直結**
   - 現状はデフォルトカード 1 種のみ
   - Pro 拡張案: カードデザイン 5 種 + 背景パターン + フォント + Light/Shadow 切替
   - シェア時の「Solara」ブランド表示 = 無料機能としてのバイラル効果

5. **`sanctuary_orb_overlay.dart` (Orb 設定) = Advanced astrology の核**
   - 8 アスペクト × オーブ値カスタマイズは商用占いアプリでも珍しい
   - **Pro 限定機能**にする候補 (Advanced astrology 訴求の一部)
   - 現状全員アクセス可、Pro ゲート追加で差別化成立

6. **`sanctuary_profile_editor.dart` の言語切替 = i18n 連携**
   - `app_locale.dart` (2b 準) + `_langBtn` で JP/EN 切替
   - EN 版完成時に活用、現状は表示テキストの一部のみ EN 化

7. **App Store Small Business Program 申請** ([`project_appstore_small_business`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_appstore_small_business.md))
   - Apple/Google 両方 = 手数料 30%→15% (= 公開前必須)
   - $9.99/月 のうち実収益: 通常 $7.00 → SBP 適用後 $8.49 (= +$1.49/月/ユーザー)
   - 1,000 Pro ユーザーで月 $1,490 の差 = SBP 申請は必須

### 4e.10 機械抽出への参照

層 4e の機械抽出 raw: [`feature_inventory/04e_sanctuary.md`](feature_inventory/04e_sanctuary.md)

---

## 層 4f: サブ画面 (Forecast / Locations / Philosophy / Font Preview)

### 4f.1 概要

`lib/screens/` 配下の **7 ファイル / 計 2,930 行**。Map (4a) / Horoscope (4b) / Observe (4c) / Galaxy (4d) / Sanctuary (4e) のメインタブに属さない補助画面群。

**機械分類の精度** (✅ オーバーライド不要): 7 ファイル全てサブ画面専用、cross-cutting なし。

サブ画面 4 種:

| サブ画面 | ファイル数 | 役割 | 起動元 |
|---|---|---|---|
| **Forecast** (運勢予報) | 4 ファイル | **暦年 (1/1〜12/31) 基準**の予測ヒートマップ + 強運 Top5 + ◯◯期サイクル。開くと当年・今日の日付が選択された状態で表示 | Map `_openForecast` 経由 |
| **Locations** (拠点管理) | 2 / 1,128 行 | 登録拠点を 16 方位スコア付きで一覧管理 | Map `_openLocations` 経由 |
| **Philosophy** (設計思想) | 1 / 159 行 | Solara 設計思想ガイド (静的、章 0) | 🔴 導線なし (未配線・#5c 孤立ファイル — オーナー判断待ち) |
| **Font Preview** (開発用) | 1 / 138 行 | フォント候補 8 種の比較画面 | (開発者専用、ユーザー導線なし) |

### 4f.2 Forecast 群 (4 ファイル)

**🔴 Worker `/astro/forecast` (KV 月次クォータ 60 req/IP/month) を呼ぶ唯一の機能** = Pro 化の自然な境界。
**集計基準は暦年 (当年 1/1〜12/31)** — `forecast_cache.dart` が当年 1/1 起点で 1 年分を一括 fetch + 永続キャッシュ (キー prefix v2)。日付が進むと末尾が動くローリング窓ではないため Top5 は年内固定。全画面 1.33x の textScaler でフォント拡大。

| # | ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|---|
| 1 | [`forecast_screen.dart`](../lib/screens/forecast_screen.dart) | **1,084** | `ForecastScreen` (Stateful)、`_ForecastScreenState`、`_DayStepperButton` | **🔴 Forecast 統合画面**。暦年ヒートマップ (`_buildHeatmap`、開くと今日を選択) + 選択日詳細 + 強運 Top5 (子 widget・年を渡す) + ◯◯期 (子 widget) + year selector。`_setColorMode`/`_setHighColor` で配色切替 |
| 2 | [`forecast/forecast_top5.dart`](../lib/screens/forecast/forecast_top5.dart) | 244 | `ForecastTop5Section` (Stateless) | **強運 Top5 セクション**。当年 (1/1〜12/31) の上位 5 日を mode 別 (overall / 5 カテゴリ) で表示。見出し右に集計対象の西暦年を表示。`_modeSelector` でカテゴリ切替、`_row` で順位 + 日付 (1 行) + スコア |
| 3 | [`forecast/forecast_life_periods.dart`](../lib/screens/forecast/forecast_life_periods.dart) | 210 | `ForecastLifePeriodsSection` (Stateless) | **◯◯期セクション**。`detectLifePeriods` (2b `forecast_cache.dart`) で抽出された連続高スコア期 (恋愛期 / 仕事期 等) を表示。`_periodRow` で期間バー + 期間名 + 日数 (右揃え auto-fit) |
| 4 | [`forecast/forecast_section_header.dart`](../lib/screens/forecast/forecast_section_header.dart) | ~30 | `ForecastSectionHeader` (Stateless) | 各セクション共通の見出し (金色アクセントバー + ラベル + 任意 trailing/info)。旧「▸」マーカーを置換 |

**Forecast の課金との関係**:
- Worker 側の **KV 月次クォータ 60 req/IP/month** ([`worker/src/index.js:73`](../worker/src/index.js)) = 既に Free の上限が物理的に存在
- Pro は `checkKvForecastQuota` の bypass 条件追加だけで「無制限予報」差別化が成立
- 1 回の forecast 計算 = 1 年分 365 日のスコア時系列 = Worker 側の計算コスト最大

### 4f.3 Locations 群 (2 ファイル / 1,128 行)

| # | ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|---|
| 1 | [`locations_screen.dart`](../lib/screens/locations_screen.dart) | 737 | `LocationsScreen` (Stateful)、`_LocationsScreenState`、`_SlotStats` | **拠点一覧画面**。21 関数 (public 3 + private 18)。VP スロットを 16 方位スコア付きで管理、`map_astro.dart` (2a) の `fetchChart` + `scoreAll` を各拠点ごとに呼出。`_buildList` でスコア順 / 距離順表示、`_buildRefPointSelector` で基準点 (現在地 / 出生地) 切替、`_buildCategorySelector` で 5 カテゴリ絞込 |
| 2 | [`locations/locations_date_stepper.dart`](../lib/screens/locations/locations_date_stepper.dart) | 391 | `LocationsDateStepper`、`_DateNumberField` (Stateful)、`_HourNumberField` (Stateful) | **日付ステッパー widget**。年▲▼ / 月▲▼ / 日▲▼ / 時▲▼ + 「今日」リセット + 数値直接入力 (`_commit` で確定)。Locations 画面でスコア計算日時を変更する用 |

**Locations の課金との関係**:
- 拠点数 ≦ `SlotManager.slots` で制限 (Map VP slot と同期)
- Pro は無制限スロット (4a.17 で既出 Pro 候補 (b))
- 1 拠点ごとに `/astro/chart` 呼出 → Free の現状 KV 制限内で問題なし

### 4f.4 Philosophy 群 (1 ファイル / 159 行)

| # | ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|---|
| 1 | [`solara_philosophy_screen.dart`](../lib/screens/solara_philosophy_screen.dart) | 159 | `SolaraPhilosophyScreen` (Stateless)、`_Hero`、`_SectionCard`、`_Footer` | **🔴 Solara 設計思想ガイド** (章 0)。`solara_manifesto.dart` (1b) のテキスト 3 セクション (世界観 / 2 エネルギー / 委ねる宣言) を表示。**🔴 導線未配線** — 画面は完成しているが Sanctuary 等からの `Navigator.push` が存在せず #5c 孤立ファイル検出 (作成コミット `fd6ed2f` 時点から未配線、過去にも導線実績なし)。オーナー判断待ち (Sanctuary「✦ App」セクションへ導線追加 or 削除)。**「占い的吉凶判定をしない」を文章化** ([`project_solara_design_philosophy`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md)) |

### 4f.5 Font Preview 群 (1 ファイル / 138 行)

| # | ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|---|
| 1 | [`font_preview_screen.dart`](../lib/screens/font_preview_screen.dart) | 138 | `FontPreviewScreen` (Stateful)、`_FontPreviewScreenState`、`_FontOption` | **開発者用フォント比較画面**。候補フォント 8 種を Horo と同じコンテキストで並列表示。`_buildSample` で各フォントのサンプル描画。**ユーザー導線なし** (本番ではアクセス不可、開発ビルドのみ) |

### 4f.6 Worker / 外部呼出

| 経由 | endpoint | 用途 | 呼出元 |
|---|---|---|---|
| `forecast_cache.dart` (2b、API+永続化ハイブリッド) | `/astro/forecast` (POST) | 1 年予測時系列計算 (KV 月次クォータあり) | Forecast 群 3 ファイル |
| `map_astro.dart` (2a) `fetchChart` | `/astro/chart` (POST) | 各拠点の出生図計算 | Locations 画面 |
| `map_search.dart` (4a `screens/map/`) `searchPlace` | `/search` (GET) | 拠点追加時の場所検索 | Locations 画面 (Map との依存) |

**Gemini 呼出 0** — サブ画面は AI 解説を使わない (Forecast は数値スコアのみ、Locations は拠点リストのみ)。

### 4f.7 依存関係 (層を跨ぐ参照)

| 依存先 | 用途 |
|---|---|
| 1b 静的辞書 | `solara_manifesto.dart` (Philosophy) |
| 2a API | `map_astro.dart` (Locations が `/astro/chart` 共用)、`map_search.dart` (4a → Locations) |
| 2b 永続化 | `forecast_cache.dart` (Forecast `/astro/forecast` + 月次クォータ + `detectLifePeriods`)、`solara_storage.dart` (Locations VP slot + 設定) |
| 3a 共通 widget | `info_popup.dart` (5 popup 呼出)、`no_profile_guide.dart` (Forecast / Locations 共通)、`map_constants.dart` (3b、Locations + Forecast 両方が import) |
| 3b テーマ | `solara_colors.dart` (Philosophy)、`glass_panel.dart` (3a、Philosophy) |
| 4a (`screens/map/`) | `map_vp_panel.dart` (`VPSlot`、Locations 直接 import)、`map_search.dart` (Locations が拠点追加で使用) |

### 4f.8 機械分類の盲点 + 重要な実態

1. **7 ファイル全てサブ画面専用 = 機械分類が正しい状態**
   - `_classify_screen` で `screens/forecast/` / `screens/locations/` / `solara_philosophy_screen.dart` / `font_preview_screen.dart` を全て 4f に振り分け
2. **`forecast_screen.dart` 1,048 行は HARD 違反** — pre-existing
   - 候補: ヒートマップ描画 (`_buildHeatmap` / `_dayCell` / `_cellColor` 等 7 関数) を `forecast_heatmap.dart` へ
   - 候補: 選択日詳細 (`_buildSelectedDayDetail` / `_metric` / `_catBar` 3 関数) を `forecast_day_detail.dart` へ
3. **`locations_screen.dart` 737 行も HARD 違反** — pre-existing
   - 候補: 日付制御 (`_shiftDate` / `_setYmd` / `_setHour` 等 5 関数) を controller 化 (既に `locations_date_stepper.dart` 391 行があるが連携のみ)
4. **`font_preview_screen.dart` はユーザー導線なし** — 開発者専用。本番ビルドからの除外候補だが、影響範囲小なので残置許容
5. **Locations と Map の意外な結合** — `locations_screen.dart` が `screens/map/` から 3 ファイル直接 import (`map_astro` 2a override 済 / `map_constants` 3b override 済 / `map_search` 4a / `map_vp_panel` 4a)。Map と Locations は機能的に強く結合

### 4f.9 重要な仕様メモリへの参照

| メモリ | 内容 |
|---|---|
| [`feedback_forecast_map_separate`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_forecast_map_separate.md) | **🔴 FORECAST と Map のスコアは別計算で意図的に一致しない** (統合改修・Map ジャンプリンク追加しない) |
| [`project_solara_design_philosophy`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_design_philosophy.md) | 🔴 Solara 全機能上位ルール (Soft/Hard 独立、吉凶禁止) — Philosophy 画面で文章化 |
| [`project_solara_security_principles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_security_principles.md) | Pro 公開時セキュリティ (`/astro/forecast` を `/protected/*` に置くか `/public/*` のままにするかの判断材料) |

### 4f.10 課金検討に直結する示唆

層 4f は **既存の課金境界を持つ唯一の層 = `/astro/forecast` KV 月次クォータ**。Pro 化が技術的に最も容易。

1. **🔴 Pro 機能の最有力候補 (本層から導出)**
   - **(a) Forecast 無制限予報** — 現状 KV 月次クォータ 60 req/IP/month = 既に Free の物理上限が存在 ([`worker/src/index.js:73`](../worker/src/index.js))。Pro は `checkKvForecastQuota` の bypass 条件追加だけで実装可。**最も実装コストが低い Pro 機能**
   - **(b) Forecast 5 年予測** — 現状 1 年 (365 日) のみ、Pro で 5 年 (1,825 日) 拡張。Worker 側の `computeForecast` で `dayCount` 引数増やすだけ
   - **(c) ◯◯期サイクル過去 5 年一覧** — `detectLifePeriods` を過去 5 年分実行 + 集約。`forecast_life_periods.dart` 拡張で実装

2. **Locations 拠点数の Pro 化** (4a.17 で既出)
   - Free は home + 現在地 + 任意 3 = 5 拠点
   - Pro は無制限 (`SlotManager.slots` 上限解除)
   - Locations 画面 (`_addCurrent` / `_buildList`) で上限チェックを isPro 判定に置換

3. **`solara_philosophy_screen.dart` の世界観テキスト = マーケ素材**
   - 「占い的吉凶判定をしない、両面思想」= 既存占いアプリ群との差別化軸
   - ストア説明文 + ペイウォール訴求文 + 公式 LP に流用可 (= マーケ素材として価値)
   - Pro 化対象ではないが、本層の存在自体が **「Solara が何を提供しないか」を明示**する重要 UI

4. **`font_preview_screen.dart` (開発者用) は公開前に判断**
   - ユーザー導線なし = 本番ビルドからの除外候補
   - **影響範囲小** (138 行、import ゼロ from production code) のため残置許容
   - 公開時に `kReleaseMode` で除外する選択肢あり

5. **Locations + Forecast の併用が「拠点最適化体験」**
   - 「拠点 A は今月どの日に良いか」を計算する組合せ
   - Pro 拡張案: 「拠点 A × Forecast 1 年スコア」のマトリックス可視化 (= Locations 一覧 × 365 日ヒートマップ)
   - 現状未実装、Pro 訴求として強力

6. **Forecast と Map のスコア不一致** ([`feedback_forecast_map_separate`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_forecast_map_separate.md))
   - Forecast (出生情報のみ、場所/時刻非依存) vs Map (拠点 + 瞬時時刻、ASC/MC 含む)
   - 意図的な別計算 = 統合しない / Map ジャンプリンクも追加しない (2026-05-14 確定)
   - Forecast の ❓ popup で説明 (`_showForecastUsageGuide`)

### 4f.11 機械抽出への参照

層 4f の機械抽出 raw: [`feature_inventory/04f_subscreens.md`](feature_inventory/04f_subscreens.md)

---

## 層 5: 連携層 (main / PopScope / IndexedStack)

### 5.1 概要

`lib/main.dart` **1 ファイル / 149 行**。Solara アプリ全体の **起動・配線・タブ調停** だけに責務を絞った最小レイヤ。
画面 (4a〜4f)・状態 (1c)・データ (1a/1b)・サービス (2a〜2c)・テーマ (3b)・widget (3a/3c) を **「組み立てるだけ」**。

**機械分類の精度** (✅ オーバーライド不要): 1 ファイルのみ、cross-cutting なし、`screens/` 直下でないため誤分類リスクもなし。

**この層の特徴**:

| 観点 | 値 | 意味 |
|---|---|---|
| Navigator.push 等 | **0** | 画面遷移は持たない (IndexedStack で常駐) |
| Popup/Dialog 呼出 | **0** | UI ロジックなし |
| Worker URL リテラル | **0** | API 呼出なし、純配線 |
| AnimationController | **0** | アニメは下位に委譲 |
| クラス | 3 (`SolaraApp` / `SolaraHome` / `_SolaraHomeState`) | 最小 |
| 関数 | 5 (`main` / `build`×2 / `createState` / `_onTabTap`) | 最小 |

### 5.2 ファイル構成

| # | ファイル | 行 | 主要 export | 役割 |
|---|---|---|---|---|
| 1 | [`main.dart`](../lib/main.dart) | 149 | `main()`、`SolaraApp` (Stateless)、`SolaraHome` (Stateful)、`_SolaraHomeState` | アプリ起動 + ルート widget + 5 タブ調停 + Android back button 配線 |

### 5.3 `main()` ブートストラップ (L15-L28)

起動シーケンス **5 ステップ**:

| 順 | 処理 | 目的 |
|---|---|---|
| 1 | `WidgetsFlutterBinding.ensureInitialized()` | async 起動前提 |
| 2 | `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` | edge-to-edge レイアウト (Android 12+) |
| 3 | `SystemChrome.setSystemUIOverlayStyle(...)` | systemNav / statusBar 透明化 |
| 4 | **`await TarotData.initialize()`** | 1b → 2c. タロット 78 枚静的データロード ([utils/tarot_data.dart](../lib/utils/tarot_data.dart)) |
| 5 | **`await CelestialEvents.initialize()`** | 2a/2c. `/astro/events` から月別天体イベント取得 + キャッシュ ([utils/celestial_events.dart](../lib/utils/celestial_events.dart)) |
| 6 | **`await AppLocale.instance.load()`** | 2b/2c. SharedPreferences から言語 override 復元 ([utils/app_locale.dart](../lib/utils/app_locale.dart)) |
| 7 | `runApp(const SolaraApp())` | 起動 |

**重要**: ステップ 4〜6 は **直列 await**。`CelestialEvents.initialize()` は Worker 呼出を含むためネットワーク待ち発生 ([`celestial_events.dart`](../lib/utils/celestial_events.dart))。起動時間に直接影響する唯一のネットワーク I/O。

### 5.4 `SolaraApp` (StatelessWidget, L30-L64)

`MaterialApp` のラッパ。`AppLocale.instance.notifier` (`ValueNotifier<Locale?>`) を `ValueListenableBuilder` で購読し、言語切替時に **全画面再 build** をトリガ。

| 設定項目 | 値 | 備考 |
|---|---|---|
| `title` | `'Solara'` | OS タスク表示名 |
| `debugShowCheckedModeBanner` | `false` | デバッグバナー非表示 |
| `theme` | `SolaraTheme.dark` | 3b 層 |
| `locale` | `AppLocale.instance.notifier.value` | null=端末設定従、`ja`/`en` で強制 |
| `supportedLocales` | `[Locale('ja'), Locale('en')]` | 2 言語のみ |
| `localizationsDelegates` | Material/Widgets/Cupertino 3 種 | DatePicker 等 OS 言語化用 |
| `builder` | `MediaQuery.withClampedTextScaling(min: 1.0, max: 1.5, child)` | **🔴 端末フォントサイズ 200% 設定時のレイアウト崩壊対策** (L48-L59) |
| `home` | `SolaraHome()` | 5 タブのルート |

**🔴 textScaler クランプ 1.5x** (L55-L59) — 業界標準 1.2〜1.5 の上限値採用。`TextScaler.noScaling` (= 完全無効化) は Apple HIG 違反 + ストア審査リスクで禁止。スコアバー / 16方位 / 天頂マーカー等のタイトレイアウトを守りつつアクセシビリティ確保。Column 化済みのため 1.5 まで耐えられる ([`feedback_text_overflow`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_text_overflow.md))。

### 5.5 `SolaraHome` / `_SolaraHomeState` — 5 タブ調停 (L66-L149)

#### 5.5.1 タブ管理 (L73-L85)

| index | タブ名 | 画面 widget | GlobalKey | 層 |
|---|---|---|---|---|
| 0 | Map | `MapScreen` | `_mapKey: GlobalKey<MapScreenState>` | 4a |
| 1 | Horo | `HoroscopeScreen` | `_horoKey: GlobalKey<HoroscopeScreenState>` | 4b |
| 2 | Tarot | `ObserveScreen` | (key なし) | 4c |
| 3 | Galaxy | `GalaxyScreen` | `_galaxyKey: GlobalKey<GalaxyScreenState>` | 4d |
| 4 | Sanctuary | `SanctuaryScreen` | (key なし) | 4e |

**🔴 GlobalKey は 3 画面のみ** (Map / Horo / Galaxy) — タブ切替時にライフサイクル制御が必要な画面に限定。Tarot / Sanctuary は state リセット不要。

**Map / Horo の `onNavigateToSanctuary` コールバック** (L80-L81) — 「プロフィール未設定ガイド」から Sanctuary を開く動線を、画面遷移ではなく **同インスタンス内のタブ切替** (`_onTabTap(4)`) として実装。Navigator.push しない設計。

#### 5.5.2 `_onTabTap(int i)` — タブ切替時のライフサイクル調停 (L87-L107)

**🔴 Solara のパフォーマンス設計の中核**。タブ切替前後の状態差分を捕捉し、各 State にメソッド呼出してアニメ / Timer / プロフィール再読込を制御。

| 条件 | 呼出メソッド | 目的 |
|---|---|---|
| `i == 0` (Map 入室) | `_mapKey.currentState?.reloadProfile()` | Sanctuary で編集された profile を Map に反映 |
| `i == 1` (Horo 入室) | `_horoKey.currentState?.loadProfile()` + `wakeAnimations()` | profile 反映 + Horo アニメ起動 (30s 寿命タイマー fresh start) |
| `i == 3` & 前 ≠ 3 (Galaxy 入室) | `_galaxyKey.currentState?.regenerateBackground()` | 背景星空再生成 + motion fresh 40s lifecycle |
| `i != 3` & 前 == 3 (Galaxy 離脱) | `_galaxyKey.currentState?.pauseMotion()` | Galaxy motion Timer.periodic 明示停止 |
| `i != 1` & 前 == 1 (Horo 離脱) | `_horoKey.currentState?.pauseAnimations()` | Horo アニメ Timer 明示停止 |

**🔴 設計上の注意** (L97-L101 コメント): Horo の `wakeAnimations` は **`initState` ではなくここで呼ぶ**。IndexedStack は全画面の `initState` を app 起動時に走らせるため、裏タブでも `initState` が走り CPU 浪費 + 寿命タイマーが消化されてしまう (Solara で 2026-05-03 確定の設計)。

**`pauseMotion()` / `pauseAnimations()` を明示呼出する理由** (L104): `TickerMode.enabled=false` で `AnimationController.repeat()` は自動停止するが、`Timer.periodic` は `TickerMode` の対象外。明示停止しないと裏タブで Timer が動き続ける。

#### 5.5.3 `build()` — Scaffold + PopScope + IndexedStack (L109-L148)

##### PopScope (L116-L123) — Android back button 配線

| `_currentIndex` | `canPop` | 挙動 |
|---|---|---|
| 0 (Map) | `true` | OS 標準 root pop = `SystemNavigator.pop` = アプリ閉じる |
| 1〜4 | `false` | `_onTabTap(0)` で Map に戻す |

**🔴 PopScope の階層**: タブ内 overlay (Daily Transit dialog 等) は `map_screen.dart` の PopScope で先に消化される (Flutter は AND 評価で最下位の `canPop=false` を優先) ([L114-L115 コメント]、[`feedback_android_back_popscope`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_android_back_popscope.md))。

##### Scaffold (L124-L146)

| プロパティ | 値 | 備考 |
|---|---|---|
| `extendBody` | `true` | body を NavBar 背面まで延ばす (Map / Galaxy の没入用) |
| `resizeToAvoidBottomInset` | `_currentIndex != 0` | **🔴 Map タブのみ false** (L126-L131): 検索バーキーボード出現時に FlutterMap が縮んで地理中心がシフトする問題を回避 (2026-05-13 再適用、撤回禁止) |
| `body` | `IndexedStack(index, children: [TickerMode(enabled, child)]×5)` | 5 画面常駐 + 裏タブ AnimationController 停止 |
| `bottomNavigationBar` | `SolaraNavBar(currentIndex, onTap: _onTabTap)` | 3a / 3b widget (height 80 + systemNav inset 動的) |

##### IndexedStack + TickerMode (L132-L141) — Solara 性能の心臓

**🔴 2026-05-03 確定の設計** (L134-L136 コメント):

```dart
IndexedStack(
  index: _currentIndex,
  children: [
    for (int i = 0; i < _screens.length; i++)
      TickerMode(enabled: i == _currentIndex, child: _screens[i]),
  ],
)
```

- **IndexedStack**: 5 画面の state を保持したまま「表示する画面だけ切り替え」(= Navigator.push と違いタブ間の state リセットなし)
- **TickerMode(enabled: false)**: 裏タブの `AnimationController.repeat()` を停止 (Galaxy 星空回転 / Horoscope 円 / Tarot Altar 等が常時 tick すると SurfaceFlinger の release タイミングを乱して Map 画面の点滅を引き起こす問題への対処)
- **Timer.periodic は TickerMode 対象外** → `_onTabTap` の `pauseMotion` / `pauseAnimations` で明示停止

### 5.6 依存関係 (層を跨ぐ参照)

main.dart は **層 0 (Worker) と層 1c (モデル) 以外の全層** に依存する。Solara で唯一全層に触れるファイル。

| 依存先 | 用途 |
|---|---|
| **1a 純計算** | (直接依存なし、下位 widget が利用) |
| **1b 静的辞書** | `TarotData` (起動時 initialize) |
| **2a API** | `CelestialEvents` (起動時 initialize、`/astro/events` 呼出) |
| **2b 永続化** | `AppLocale` (起動時 load) |
| **2c グローバル singleton** | `TarotData.initialize` / `CelestialEvents.initialize` / `AppLocale.instance.load` |
| **3b テーマ** | `SolaraTheme.dark` (MaterialApp.theme) |
| **3a 共通 widget** | `SolaraNavBar` (bottomNavigationBar) |
| **4a Map 画面** | `MapScreen` + `MapScreenState` (tab 0, reloadProfile) |
| **4b Horo 画面** | `HoroscopeScreen` + `HoroscopeScreenState` (tab 1, loadProfile / wakeAnimations / pauseAnimations) |
| **4c Observe 画面** | `ObserveScreen` (tab 2、state 操作なし) |
| **4d Galaxy 画面** | `GalaxyScreen` + `GalaxyScreenState` (tab 3, regenerateBackground / pauseMotion) |
| **4e Sanctuary 画面** | `SanctuaryScreen` (tab 4、state 操作なし) |

### 5.7 機械分類の盲点 + 重要な実態

1. **1 ファイル / 149 行 = Solara で最も小さい責務単位の層** — `_onTabTap` ですら 21 行。配線以外を持たない設計が徹底
2. **`createState` の戻り値は `_SolaraHomeState`** — private クラスのため #1 漏れリスト (146 件) に含まれる (機械検出済、Doc 露出不要)
3. **`SolaraApp` も #1 漏れに含まれる** — 層 5 が未着手だったため。本層追記で本ドキュメントに登場 = 漏れ解消候補
4. **`AppLocale` も #1 漏れに含まれる** — 2b/2c で軽く触れたが本層の起動で本格使用、本層追記で重要度可視化
5. **Tarot / Sanctuary に GlobalKey がない** — タブ切替時の state 操作が不要 = 設計が綺麗。Pro 機能追加時に Sanctuary の state を触る必要が出たら GlobalKey 追加検討
6. **`MaterialApp.routes` / `Navigator.push` 不使用** — 全画面 IndexedStack 常駐。サブ画面 (4f Forecast / Locations / Philosophy) のみが各タブ内で Navigator.push される構造 (= 階層は浅い)

### 5.8 重要な仕様メモリへの参照

| メモリ | 内容 |
|---|---|
| [`feedback_android_back_popscope`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_android_back_popscope.md) | 🔴 Android 13+ で PopScope が動かない時の確認手順 (MainActivity の OnBackInvokedDispatcher override 撤回必須) |
| [`feedback_text_overflow`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_text_overflow.md) | 🔴 textScaler クランプ 1.5x の根拠 + Row/Column 内 Text の overflow 規約 |
| [`feedback_blast_warning_known_issue`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_blast_warning_known_issue.md) | BLAST Faking 警告 = Flutter Engine 既知問題 (アプリ側で消せない) |
| [`project_solara_a101fc_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_a101fc_fd_leak.md) | 🟢 解決 🟢 fd 枯渇 → Impeller ON で完全リーク 0 確認、最新 Flutter で sync_file leak 修正済 |
| [`feedback_http_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_http_fd_leak.md) | Flutter fd 枯渇対策は HttpOverrides で全 HttpClient 一括制御 (本層への将来追加候補) |

### 5.9 課金検討に直結する示唆

層 5 は **Pro 化の挿入点が物理的に集中する層**。コード量は小さいが Pro 公開時の改修ハブになる。

1. **🔴 Pro 化挿入点 (本層から導出)**

   - **(a) `main()` ブートストラップに RevenueCat 初期化追加**
     - `await Purchases.configure(...)` を `runApp` 前に挿入 ([`project_solara_security_principles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_security_principles.md))
     - Apple/Google 両方の SDK 初期化 + entitlement 取得 + isPro singleton 起動
     - 起動時間に 200〜500ms 追加見込 (network 待ち)
   - **(b) `main()` に Auth/Sign in チェック追加**
     - Sign in 必須化 ([`project_solara_security_principles`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_security_principles.md))
     - 未サインインなら Sanctuary タブ強制 = 本層の `_currentIndex = 0` を `_currentIndex = 4` に分岐
   - **(c) `SolaraApp` に initialRoute 分岐追加**
     - Pro/Free で起動画面を変える場合、`home` を条件分岐 (例: Pro は Galaxy Archive、Free は Map)
     - 現状は全員 Map スタートだが、Pro 訴求のためファーストビュー変更案あり
   - **(d) `_onTabTap` に Pro ゲートチェック挿入**
     - 例: Galaxy Archive (Pro 限定) を Tab に追加する場合、`if (i == n && !isPro) → showPaywall()` を本メソッドに 1 行追加
     - = Pro 化が最小コードで実装可能な設計になっている (= 既に Pro Ready)

2. **🔴 起動時間 = Free / Pro 共通の体験ボトルネック**

   - 現状 `CelestialEvents.initialize` は Worker 呼出を含む直列 await (= 初回起動時にネットワーク待ち)
   - キャッシュヒット時は SharedPreferences 即返却で問題なし
   - Pro 機能 (Aether shaders 等) をロード時 await すると更に遅くなる → Pro asset は **lazy load** 必須

3. **🔴 IndexedStack + TickerMode = Pro 機能追加時の重要制約**

   - 5 画面常駐前提で 8 ヶ月運用 = 「Pro 専用画面を 6 枚目として追加」は性能リスク (常時 5 画面でも GPU/CPU が攻める設計)
   - **推奨**: Pro 機能は既存 5 タブ内の overlay / dialog として実装 (= 既存 Tab を拡張するパターン)
   - 例外: Galaxy Archive を 6 枚目として追加するなら、IndexedStack ではなく Navigator.push で表示する設計に切替

4. **言語 (`AppLocale`) は **Pro/Free 共通**で残す**

   - i18n は公開直前まで保留 ([`feedback_i18n_last`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_i18n_last.md))
   - EN 切替を Pro 限定にする案は **却下推奨** — 海外初期体験を阻害する (4e.9 #3 と整合)
   - 言語切替は `AppLocale.instance.setOverride('en')` で完結 (本層は購読のみ)

5. **PopScope の階層設計 = Pro 機能追加時に再検討**

   - 現状 2 階層 (root SolaraHome + 各 Map/Horo 内 overlay)
   - Pro 専用 dialog (Paywall 等) を追加する場合、PopScope の優先度設計を確認
   - AND 評価で最下位 `canPop=false` 優先 = Paywall を一番下に置けば正しく back で閉じる

6. **`screens/` 直接 import が 5 個 = 画面追加時の change point が本層に集中**

   - L5-L9 の relative import = 画面追加時に本層も編集必須
   - **Pro 用画面追加時の安全策**: `screens/` を group import (`screens.dart` で re-export) する案 — ただし現状 5 画面で運用問題なし、Premature optimization

7. **本層に Worker / Gemini / Auth / IAP 呼出が 0 件 = Pro 公開時の最大の改修ターゲット**

   - 現状の純配線設計は良い (= ロジックが下位に隠蔽されている)
   - Pro 公開時に `main()` が ~~149 行~~ → 200〜250 行に増える見込
   - 増えるのは: ① RevenueCat 初期化、② FlutterError.onError (Sentry/Crashlytics)、③ HttpOverrides グローバル設定 ([`feedback_http_fd_leak`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/feedback_http_fd_leak.md))、④ Firebase initializeApp (Auth 用)

### 5.10 機械抽出への参照

層 5 の機械抽出 raw: [`feature_inventory/05_main.md`](feature_inventory/05_main.md)

---

## 🎉 全 17 層完成 (2026-05-14)

| 層 | 名称 | ファイル数 | 行数 | 状態 |
|---|---|---|---|---|
| 0 | Worker | 9 | (Worker JS) | ✅ |
| 1a | 純計算 | 5 | — | ✅ |
| 1b | 静的データ辞書 | 11 | — | ✅ |
| 1c | モデルクラス | 4 | — | ✅ |
| 2a | API ラッパ | 7 | — | ✅ |
| 2b | 永続化 | 3 | — | ✅ |
| 2c | グローバル singleton | 1 | — | ✅ |
| 3a | 共通ウィジェット (純粋) | 23 | — | ✅ |
| 3b | テーマ・装飾 | 3 | — | ✅ |
| 3c | 演出ウィジェット (animated) | 5 | — | ✅ |
| 4a | Map 画面 | 22 | 12,283 | ✅ |
| 4b | Horoscope 画面 | 22 | — | ✅ |
| 4c | Observe (Tarot) 画面 | 5 | — | ✅ |
| 4d | Galaxy 画面 | 5 | 1,857 | ✅ |
| 4e | Sanctuary 画面 | 8 | — | ✅ |
| 4f | サブ画面 | 7 | 2,930 | ✅ |
| 5 | 連携層 | 1 | 149 | ✅ |
| **計** | **Dart 132 + Worker 9 = 141** | — | — | **100%** |

**達成内容** (2026-05-14 オーナー指摘の構造的解決):

- 機械抽出スクリプト `extract.py` で **対整合チェック #1〜#4** 実装済
- `feature_inventory.md` (人手版) で全 17 層を **同一の章構造** (概要 / ファイル / 依存 / 機械分類盲点 / メモリ参照 / 課金示唆 / raw 参照) で記述
- 累計 9 件の PATH_OVERRIDES で機械分類の盲点を明示テーブル化 ([`extract.py:161-180`](../tools/feature_extractor/extract.py))
- Worker 死んだ endpoint (`/astro/predict` / `/astro/line-narrative`) 2 件を機械検出
- Cosmic Pro UI 既存実装 (Sanctuary L653-724: $9.99/月 + $49.99/年 + 3 訴求機能) を発見、Pro 候補と完全一致を確認

**残作業 (オプション、次セッション以降)**:

- 既存メモリ「廃止済」記述照合 ([`project_solara_horoscope_spec`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_horoscope_spec.md) / [`project_solara_geo_sector`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_geo_sector.md) 等を新インベントリと突合)
- 未実装対整合チェック実装: **#5 call graph** (誰が誰を呼ぶか、Pro 化影響範囲特定に必要) / **#6 ハッシュ stamp** (ファイル変更検知) / **#7 astro_glossary 用語辞書対整合**
- 機能インベントリ運用ガイド更新 (CLAUDE.md / メモリ)
- **#1 漏れ 146 件の選択的解消** (private state class は不要、`AppLocale` / `SolaraApp` 等の重要 public 識別子に絞って Doc 追記)

---

## 本セッション追加機能 (2026-05-30) — §0.2.22〜§0.2.28

> 層別の詳細反映は次セッションのタスク。ここでは概要・ファイル・§番号を記録する。詳細は session_log 2026-05-30。

- **§0.2.22 案Yパネル履歴バグ修正**: 相談結果画面 (`consultation_result_screen.dart`) で `_exhausted`(ボタン抑制) と案Yパネル表示が混線し履歴の全カードに枯渇パネルが出ていた → `_showExhaustionPanel` を分離 (出し直し由来の枯渇のみ表示)。
- **§0.2.23 Map検索詳細「Googleマップで見る」**: `map_search.dart` の `SearchFocusPopup` に🗺ボタン。`SearchHit.placeId` を追加し `googleMapsUrlForHit()` が `query_place_id` で店舗ページを直開き (Worker は既に placeId 返却・変更不要)。
- **§0.2.24 距離バンド + おでかけ20km**: `ConsultationScope.minKm` 追加。旅行/移住の半径を「以内」→ 距離帯バンド (50〜100/100〜300/300〜500km)。おでかけは [20,50,100,300]。worker `buildCandidatePool` に `inBand(minKm<=d<=radiusKm)` フィルタ。バンド下限ヘルパは `consultation_input_logic.dart`。
- **§0.2.25 区/地区 D1 投入**: GeoNames allCountries から ADM3+PPLX 31.9万件を `cities` テーブルに追記 (人口名目2000・JP は ja 名)。名古屋16区/上野/Le Marais 等が近傍候補に。seeder=`tools/seed_d1_subdivisions.py`。worker/app 変更不要 (bounding-box が自動で拾う)。D1 20→62MB。
- **§0.2.26 結果カード地図リンク**: 結果カード (`consultation_result_card.dart`) の場所名右に🗺。`utils/map_focus.dart` (MapFocus singleton + `mapFocusDate()` 純関数) でタブ越し遷移し、`MapScreenState.focusLocationAndDate` が視点(_center)を候補地へ移動+相談日付で表示。日付=おでかけ:指定日+時間帯/旅行:初日/移住:時期代表日。
- **§0.2.27 星読みトランジット接頭辞除去**: `fortune.js` プロンプトに呼称ルール(トランジット惑星は惑星名のみ・出生/プログレスはラベル) + `stripTransitLabel()` サニタイザ。Horo はアスペクト名を括弧併記 (トライン120°等)。
- **§0.2.28 占い文に「光源」文体**: `worker/src/style_voice.js` (`STYLE_VOICE_JP` 単一ソース) を相談/星読み/タロットの ja プロンプトに注入。オーナー文体サンプルから蒸留。既存ルール(名前/挨拶/前置き禁止)最優先。consultation にテーマ推測ガード追加。

---

## 画面復元 (Android プロセス死対策) — 2026-05-31 追加 (横断機能)

> **目的**: 低 RAM 端末 (A101FC 等) で外部アプリ (Google マップ / 共有シート等) へ離脱中に
> OS が Solara プロセスを kill → 復帰時にコールド再起動して初期画面に戻る問題の解決。
> 詳細仕様は memory [`project_solara_screen_restore.md`](../../../../C:/Users/cojif/.claude/projects/E--AppCreate/memory/project_solara_screen_restore.md)。

### 設計 (ハイブリッド)

Flutter 標準の状態復元 (`restorationScopeId` + `RestorableProperty`) は instance-state bundle に依存し、
攻撃的 OEM キラー端末で不達になりうる + 全 StatefulWidget の大改修が必要。よって**ディスク永続化**を主軸にした:

1. **基盤**: `MaterialApp.restorationScopeId = 'solara_root'` (Navigator/Restorable 対応の土台、無料)。
2. **スナップショット保存**: `SolaraHome.didChangeAppLifecycleState` の `paused` で、現在の画面状態を
   1 つの JSON に集約して `SolaraStorage.saveRestoreSnapshot()` でディスク保存 (まだ生存中に書くので確実)。
3. **コールド起動時復元**: `SolaraHome.initState → _restoreLastScreen()` がスナップショットを読み、新しければ
   (既定 6 時間以内) タブ + 各画面状態を復元し、消費後クリア。
4. **warm 復帰で破棄**: `resumed` で `clearRestoreSnapshot()`。= **プロセス死の時だけ復元**が走り、通常の
   アプリ切替では誤復元しない (残存スナップショット = kill されたことの証拠)。

### 2 つの復元サブ機構

| 機構 | 対象 | 実装 |
|---|---|---|
| **(A) タブ内 state** | 常駐タブ (IndexedStack) 内の状態 | 各 State に `captureRestore()`/`restoreXxx()` を生やし、`SolaraHome` が GlobalKey 経由で吸い上げ/適用。snapshot キー=`map`/`observe`/`galaxy`。SolaraHome は中身を透過で運ぶだけ (画面が所有) |
| **(B) 押下ルート** | `Navigator.push` された別ルート | `utils/consult_restore.dart` の `ConsultRestore` (登録スタック singleton)。各ルート画面が initState で `register(capture)` / dispose で `unregister`。`SolaraHome` が paused 時に `captureTop()` で最前面を取得し、復元時 `_restorePushedRoute()` で type 別に再 push |

### 復元カバレッジ

- **タブ位置**: 全 5 タブ (Map/Horo/Tarot/Galaxy/Sanctuary)。
- **Map** (機構 A, `MapScreenState.captureMapRestore/restoreMapState`): 検索結果一覧 + 検索結果詳細
  (`_searchHits`/`_searchFocus`、`SearchHit.toJson/fromJson`)、Daily/Fortune オーバーレイ、Locations/Forecast
  モーダルシート (`_openSheet` で追跡し復元時 `_openXxx()` 再呼出)。検索=onMapReady 後 / ポップアップ=chart 読込後に消化。
- **Tarot** (機構 A, `ObserveScreenState.captureRestore/restoreState`): HISTORY タブ + サブタブ (今の/過去サイクル)。
  サブタブ `_historyTab` は子 `ObserveHistoryPanel` から `_historyTabForChild` に持ち上げ。State を public 化
  (`ObserveScreenState`) し part 拡張も追従。
- **Galaxy** (機構 A, `GalaxyScreenState.captureRestore/restoreGalaxyState`): Star atlas 共有画面 2 種 =
  通常再生終了 (`_replayController.value=1.0` へジャンプ) / 形成演出終了 (`CatasterismFormationOverlay.startFinished`
  で 8 秒演出をスキップして最終フレーム直表示)。cycle は `GalaxyCycle.toJson` で丸ごと保存。
- **相談** (機構 B): 入力画面 (`ConsultationInputScreen.restoreForm` でフォーム全項目復元)、結果画面
  (**必ず履歴レコードから `fromRecord` で復元 = API 再実行/クレジット二重消費を構造的に防止**。未保存の live は復元対象外)。
- **Sanctuary** (機構 B): 相談履歴 (`initialFavOnly` でタブ復元)、称号変遷 (引数なし再 push)、称号共有
  (全引数 String なので丸ごと保存 + `initialShowShadow`)。

### 不変条件 (必守)

- 相談結果は **request(live) で復元しない** (= Gemini 再課金を防ぐ)。recordId 経由で履歴から `fromRecord` のみ。
- warm 復帰でスナップショット破棄 (通常起動で古い画面が勝手に出ない)。
- snapshot は全てプリミティブ JSON (SharedPreferences 保存可)。`SearchHit`/`GalaxyCycle` は toJson/fromJson 経由。

### 主要ファイル

- `lib/main.dart`: `SolaraHome` の保存/復元オーケストレーション (`_saveRestoreSnapshot`/`_restoreLastScreen`/`_restorePushedRoute`)、5 タブ GlobalKey。
- `lib/utils/solara_storage.dart`: `saveRestoreSnapshot`/`loadRestoreSnapshot`/`clearRestoreSnapshot`。
- `lib/utils/consult_restore.dart`: `ConsultRestore` 登録スタック (新規)。
- `lib/screens/map_screen.dart` / `observe_screen.dart` / `galaxy_screen.dart`: タブ内 capture/restore。
- 各押下ルート画面 (`consultation_input/result/history_screen`, `title_history_screen`, `class_share_card`): レジストリ登録 + 復元用コンストラクタ引数。
- `lib/widgets/catasterism_formation_overlay.dart`: `startFinished` 引数。
- テスト: `test/consult_restore_test.dart` (レジストリ単体)、`test/map_search_test.dart` (SearchHit 往復)。

### 検証法 (実機)

開発者向けオプション →「**アクティビティを保持しない**」を一時 ON にすると、アプリを離れて戻るたびに必ず
コールド再起動が起き、全復元ケースを毎回・確実にテストできる (= 通常はランダムなプロセス死を強制再現)。検証後は OFF に戻す。

---

## 本セッション追加機能 (2026-05-31 セッション2) — §0.2.29〜§0.2.35

> 30分デルタ Pro / Play Integrity TO 修正 / 免責注記 / Paywall・同意・相談入力 調整。詳細は session_log 2026-05-31。層別の詳細反映は次セッションのタスク。**worker (§0.2.29/§0.2.30) は本番未 deploy**。

- **§0.2.29 おでかけ相談 Pro 時刻指定 + 30分経過後を見る**: 相談入力 (おでかけ) に 1時間刻みドラム (`consultation_input_when_scope.dart` の `showConsultationHourPicker`/`_HourDrumSheet`、Pro)。`ConsultationWhen.atUtcMs` を worker へ送信。worker `consultation_engine.js` が `transitInstants` で指定時刻を尊重 + `computeTimeDelta()` が候補地ごと +30分後の CCG 線移動 (`{planet,angle,aspect,dir,fromKm,toKm}`) を算出 → `consultation_v2.js` が同一 Gemini 呼び出しに同梱して `candidate.deltaAfter={deltaMin,changes,narrative}` を返す (コスト中立)。結果カード `_DeltaAfterSection` (ボタン+reveal+iボタン+`_DeltaChip`)。
- **§0.2.30 再加入クレジット封じ込め (worker)**: `webhooks/revenuecat.js` の `INITIAL_PURCHASE`→週次クレジット全リセット呼び出しを削除。再加入では週次クレジットは復活しない (月曜 weekly reset のみ)。2026-05-29 の決定をオーナーが反転。**要 worker deploy**。
- **§0.2.31 Play Integrity 遅延 TO 修正**: `utils/app_attest_client.dart` に `_kAttestStepTimeout=8s` を challenge fetch + verify の各段 (iOS/Android) に適用。cold verify ~161s が 60s クライアント TO を超過し /protected が失敗 →「Stellaの声が届きませんでした」となっていた真因。失敗時は従来通り graceful degrade。
- **§0.2.32 AI 解釈の免責注記**: `widgets/ai_disclaimer_footer.dart` に `StellaInterpretationNote` を追加し、Horo (`horo_fortune_cards.dart`) / Tarot (`observe_screen.dart`) / 相談・30分デルタ (`consultation_result_card.dart`) の各結果で既存 `AiDisclaimerFooter` の上に表示。
- **§0.2.33 Paywall 修正 + 天頂帯/天底帯 Pro 化**: `paywall_comparison.dart`/`paywall_widgets.dart` — Free タロット文言「1日1回（カテゴリ指定はクレジット消費）」、時刻スライダー/保存拠点数を分離、Forecast 5年予測をアスペクトラインより上に移動+訴求、ACG 比較セル Pro=Free。`map_screen.dart` の `_proGatedAstroKeys` + `_isProGatedBandKey`(zenithBand/nadirBand) で天頂帯/天底帯を Pro ゲート + 比較表に行追加。
- **§0.2.34 時刻スライダー 10分グリッド統一**: `map/map_time_slider.dart` の `_stepMinute` を 10分グリッドスナップに書換え (off-grid △=ceil/▽=floor、10:33→△10:40/▽10:30)。1分刻み (Pro) の `_stepMinuteFine` + Pro ゲート + pro_status/pro_unlock_dialog import を撤廃。Paywall 記載も削除。daily transit サブタイトル →「天体から場所を読む」。
- **§0.2.35 同意画面 + 相談入力 文言**: `ai_consent_screen.dart` タイトル「✦ Solara ✦」(両側対称) + 「現役の占星術師である私が」。`consultation/consultation_input_screen.dart` にタイトル下 `_ConsultIntroNote` (簡単説明) + タイトル右 i ボタン → `showConsultAboutPopup`/`_ConsultAboutContent` (3部: 相談とは / 読み解くデータ=Free/Pro のデータ規模を具体数字で / Solara 開発者より)。

> 関連: デッドコード削除 (`galaxy_archive_filter.currentIsPro` / `observe_history_filter.observeHistoryIsPro`・`cardForId`) は機能ではないため §番号なし (commit `6ad477b`)。

---

## 本セッション追加機能 (2026-05-31 セッション3) — §0.2.36〜§0.2.37

> 称号 Shadow 面を「気付いた人だけの隠し要素」化 / Pro 称号再診断の使い方案内。クラス増減なし (stamp diff +0 -0 ~3)。詳細は session_log 2026-05-31。

- **§0.2.36 称号 Shadow 面を隠し要素化**: Shadow への誘導文言・案内をすべて撤去し、シャドーはカードタップでのみ現れる「え？」の隠し要素にした。① reveal 画面 (`sanctuary/sanctuary_title_diagnosis.dart`) — `_buildRevealLightSide`/`_buildRevealShadowSide` の「✦ タップしてシャドーを見る ✦」「◀ タップしてライトに戻る」ヒントを削除。フリップトリガを**画面全体タップ → `ClassCard.onTap` (カードのみ)** に変更 (外側 `GestureDetector`/`HitTestBehavior.opaque` 撤去)。余白を詰めて「これでいく」ボタンを 1 画面に収めた (カード幅 260 維持)。② Sanctuary 画面 (`sanctuary_screen.dart` `_buildTitleDiagnosisSection`) — 「tap to show SHADOW / LIGHT」表示を削除 (カードタップのトグルは維持)。③ 共有画面 (`sanctuary/class_share_card.dart`) — AppBar 右上「SHADOW 面 / LIGHT 面」トグルボタンを撤去し、プレビューカードを `GestureDetector(HitTestBehavior.opaque)` でタップ → `_showShadow` トグル (案内なし)。
- **§0.2.37 Pro 称号再診断の使い方案内**: `sanctuary_screen.dart` に `_showRediagnoseProGuide(BuildContext)` を追加。再診断ボタン onTap を `canRedo ? (isPro ? 案内ダイアログ : _startDiagnosis) : showProUnlockDialog` に分岐。Free の 1 回再診断は案内なしで直接診断、**Pro 機能として受け直す時のみ**「✦ 称号の受け直しについて」ダイアログ (金枠ダーク調、下部に [戻る]=キャンセル / [OK]=診断へ) を表示。内容: Pro は何度でも受け直せる / 太陽×月由来の「二つ名」は不変・変わるのは設問由来の「称号(クラス)」のみ / 内的外的変化時に受け直すと「称号 変遷」で成長を辿れる。`_kFreeRedoLimit=1` の既存ゲートは不変。

---

## 本セッション追加機能 (2026-05-31 セッション4) — §0.2.38

> Map 画面の操作系を親指リーチ重視で再配置 + 「✦ Stella に相談」ボタン新設 + 専用アイコン生成。stamp diff +0 -0 ~2 (クラス増減なし)。

- **§0.2.38 Map 操作系の再配置 + Stella 相談ボタン + 専用アイコン**:
  - **左サイド 3 ボタン (🔍/☰/📍) を下端チップバー直上の左寄せに移動** (`map/map_overlays.dart` `MapSideButtons`)。`top: topPad+152/200/248` → `SizedBox.expand` + `bottom: 176/128/80`。`topPad` フィールド/引数を撤去 (呼出側 `map_screen.dart` も更新)。右下ボタン列と左右対称・親指リーチ改善。空白領域は Stack 非 hit-test で地図ジェスチャ透過。
  - **右下に「✦ Stella に相談」ボタン新設 + 現在地ボタン微調整** (`map_screen.dart`)。現在地ボタン `right:12→16, bottom:80→92`。その上に Stella 相談ボタン (52px 円・金リング `0x66C9A84C`・微光) を `Column(crossAxisAlignment.end)` で縦積み。タップ → `_enterConsultationFromMapButton()` が `ConsultationInputScreen` (preset 無し) を push (Free も入力画面まで可)。`_noProfile` 時は Stella ボタン非表示。
  - **ACG バーガー (及び展開ピル) を少し上げる**: ACG 下部 Column `bottom: 1 → 14` (`map_screen.dart`)。NavBar 密着の窮屈感を解消。
  - **Stella 相談アイコンを新規生成** (`mockup/generate_consult_icons.py`、既存 `generate_menu_icons_v2.py` の BASE_STYLE 踏襲 + 円形αマスク)。3 案 (A 導きの星+環 / B 三日月+星 / C 水晶玉+星座) 生成 → **C 採用** (`assets/menu_icons/consult.webp`)。原 PNG 3 枚は `mockup/share-assets/menu-icons/v2/consult_*.png` に保護。

---

## 本セッション追加機能 (2026-05-31 セッション5) — §0.2.39

> ウェルカム特典: 出生地+現住所を初めて揃えた**新規完了者**へ恒久 (購入型・月曜リセットなし) クレジット 3 を 1 回付与 + Map バナー誘導。stamp diff +1 -0 ~5 (`map_welcome_banner.dart` 新規)。**要 worker deploy**。

- **§0.2.39 ウェルカム無料3クレジット + Map 誘導バナー**:
  - **Worker** (`worker/src/index.js`): 新 protected ルート `/protected/consultation/welcome-grant` → `consultationWelcomeGrant(env,request,body)`。既存冪等関数 `_consultationCreditGrant({appUserId,amount,eventId})` を `eventId='welcome:'+deviceKey` で再利用 (`consultation_purchased` 恒久プールへ +amount、スキーマ追加なし)。`consultationWelcomeAmount(env)` = `CONSULTATION_WELCOME_GRANT` (default 3)。端末固定ガード: `consultationDeviceKey` は iOS=App Attest keyId (リインストール耐性) / Android=usr:{appUserId} (匿名再 install で farming 可の既知の限界)。appUserId/deviceKey 無しは付与しない。`wrangler.toml` に `CONSULTATION_WELCOME_GRANT="3"`。テスト 6 件追加 (`test/consultation_credits.test.js`、計 339 green)。
  - **Flutter 付与**: `utils/consultation_api.dart` に `grantWelcomeCredits()` + `WelcomeGrantResult`、`utils/solara_api.dart` に `solaraConsultationWelcomeGrantUrl`。`utils/solara_storage.dart` に `WelcomeGiftFlags` + `ensureWelcomeBaseline(profileCompleteNow)` / `loadWelcomeFlags` / `setWelcomeGranted` / `setWelcomeConsultUsed` (SharedPreferences `solara_welcome_*_v1`)。**新規完了者のみ**: 本機能初回到達時に既に birth+home 揃いの既存ユーザーは eligible=false で対象外。
  - **Flutter Map** (`map_screen.dart`): `_loadProfileAndChart` 冒頭で `_evaluateWelcomeGift(hasBirth,hasHome)` を毎回評価 → eligible×birth×home×未付与で `grantWelcomeCredits()`→付与成功で `setWelcomeGranted`+credits refresh。バナー状態 `_welcomeBanner` (none/addHome=B/tryStella=C)。
  - **Flutter バナー** (`screens/map/map_welcome_banner.dart` 新規 `MapWelcomeBanner`/`WelcomeBannerMode`): 時刻スライダー直下に表示。B「現住所を登録すると無料クレジット3」→ CTA で `onNavigateToSanctuary` (自宅登録)。C「無料クレジット3をお贈りしました / 週でリセットされない相談チケット」→ CTA で `_enterConsultationFromMapButton`。C 表示中は Stella ボタンを強発光で誘導。✕ で B=セッション非表示 / C=consultUsed 永続クローズ。

---

## 本セッション追加機能 (2026-05-31 セッション6) — §0.2.40

> ウェルカム特典の拡張: ①初回サインインでも +3 (合計最大6) ②匿名→認証サインイン時の恒久クレジット移送 (取り残し/IAP消失バグの解消) ③device recall 計画文書。stamp diff +0 -0 ~5。**要 worker deploy**。

- **§0.2.40 サインイン付与 + 匿名→認証クレジット移送 (+ device recall 計画)**:
  - **付与の kind 化** (`worker/src/index.js` `consultationWelcomeGrant`): body `kind` で eventId を分岐。`profile` (既定) = `welcome_profile:{deviceKey}` (端末単位)、`signin` = `welcome_signin:{appUserId}` (アカウント単位・安定 ID で farming 不可)。profile/signin は独立 = 合計最大6 (各1回・冪等)。
  - **匿名→認証 移送** (新ルート `/protected/consultation/migrate-purchased` → `consultationMigratePurchased`; DO `_consultationPurchasedMigrate`): サインインで app_user_id が匿名→認証に変わると `consultation_purchased[匿名]` が取り残される問題を解消。from の残高を to へ加算し from を 0 化、eventId `migrate:{from}:{to}` で冪等。**セキュリティ**: from は `$RCAnonymousID:` のみ許可 (匿名IDは外部非露出で窃取不可)。これは匿名IAP購入クレジットがサインインで消える既存バグの修正でもある (TASK: TRANSFER webhook は entitlement のみ移送、purchased は対象外だった)。
  - **Flutter** (`utils/solara_auth.dart` `_commitAccount` → `_onSignedInCredits`): logIn 前の匿名IDを控え、logIn 後に「匿名残高移送 (匿名のみ) → `grantWelcomeCredits(kind:'signin')` → credits refresh」を best-effort (UI 非ブロック)。`utils/consultation_api.dart` に `migratePurchasedCredits()` + `grantWelcomeCredits(kind:)`、`utils/solara_api.dart` に migrate URL。map の profile 付与は既定 kind=profile のまま。
  - **device recall 計画** (`docs/device_recall_plan.md` 新規): Android 匿名再インストール farming の根本対策。**Google ベータ承認 + Play Console 有効化 (オーナー作業) が前提**のため実装は承認後。verdict 3ビットで「welcome 付与済」を端末単位に記録 (再インストール貫通)。当面は「匿名にも付与・farming は bounded で許容」(オーナー判断)。
  - テスト: worker +7 (signin/profile 独立6・移送/冪等/窃取防止) → 計 346 green。
