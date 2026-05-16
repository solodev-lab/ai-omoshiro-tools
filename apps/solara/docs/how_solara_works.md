# Solara はどう動くか — 機能・体験ガイド

> **このドキュメントの役割**: Solara が「ユーザーから見て何をするアプリか」「各機能が実際どう動くか」を
> 体験視点でまとめた、Claude (クラウさん) 用の理解ガイド。これを読めば Solara の全体像が即座に分かる。
>
> **[`feature_inventory.md`](feature_inventory.md) との違い**:
> - `feature_inventory.md` = アーキテクチャ視点（141 ファイルが 17 層にどう配置され、何を import するか）
> - 本ドキュメント = 体験視点（ユーザーが何をして、裏で何が起きるか）
>
> **出典**: `feature_inventory.md`（コード抽出 + 人手照合済み）+ 設計思想メモリ +
> `solara_manifesto.dart` + 主要画面コードの spot-verify（`observe_screen.dart` 等）。
> 2026-05-14 作成 (v1)。
>
> **⚠️ 限界**: 私（Claude）はこのアプリを**実機で動かして見ていない**。本ドキュメントは
> 「コードがそう書いてある」レベルの理解であり、UX の手触り・磨き込み度・粗さは含まない。

---

## 1. Solara とは何か

**Solara は「占星術をベースにした、判断しない自己理解ツール」。**

一般的な占い аппリが「あなたはラッキー/アンラッキー」「この方角は吉」と**判断を下す**のに対し、
Solara は **「いま、どこに、どんなエネルギーがどれだけ在るか」を事実として提示するだけ**で、
解釈と選択はユーザーに委ねる。これがアプリ全体を貫く設計思想であり、最大の差別化軸。

ユーザーは出生情報（生年月日時 + 出生地）を一度入力すれば、それを起点に:
- **方位**（Map）— 16 方位それぞれに在るエネルギーを地図上で読む
- **出生図**（Horoscope）— 自分のネイタルチャートと今日の運勢を見る
- **タロット**（Observe）— 1 日 1 枚カードを引いて AI 解説を読む
- **月相サイクル**（Galaxy）— 新月で意図を立て、満月で振り返り、サイクル完了で「星座」を結晶化する
- **称号診断**（Sanctuary）— 144 種の称号から自分の「クラス」を診断する

を行える。

---

## 2. 中核思想 — これがアプリの全機能を縛る

設計根拠: `project_solara_design_philosophy.md`（2026-04-29 オーナー確定、全機能の上位ルール）。
ユーザー向けの文章版が `solara_manifesto.dart`（Philosophy 画面で表示）。

### 2.1 ソフトとハードは「独立した 2 つのエネルギー」

- **1 軸の両端ではない。プラス/マイナスではない。**
- ソフト = 流れに乗る力（寛容・拡大・受容・安定）
- ハード = 摩擦と変化の力（挑戦・変容・対峙・成長）
- **両方が同時に高くなり得るし、両方が同時に低くなり得る。** それぞれ独立した「量」。
- ハード = 悪ではない。ソフト = 善ではない。両方とも美しいエネルギー。

→ データ構造は `DirectionEnergy { soft, hard }` の独立 2 フィールド（`utils/direction_energy.dart`）。

### 2.2 占い的吉凶判定をしない

- 「ラッキー」「アンラッキー」「ここが良い/悪い」を**出さない**。
- エネルギー量を**事実として伝えるのみ**。解釈・判断はユーザー。
- Gemini に占い文を生成させるときも「good/bad」「lucky/unlucky」を使わせない（プロンプトで担保）。
- ユーザー文言は「在る・効く・動く」を使い、「良い・悪い」を避ける。

### 2.3 実装上の絶対禁止事項

- ❌ `total = soft + hard` を最終出力する（合算は 1 次元化）
- ❌ `softRatio = soft / total` を出す
- ❌ ハード=赤 / ソフト=緑 の色分け（吉凶の視覚化）
- ❌ ★1〜★5 のレーティング表示

### 2.4 例外: Map の扇状セクターだけは「合算 + 1 色」

Map 画面の 16 方位扇状セクターのみ、視覚過密を避けるため:
- `activeCategory` の色 **1 色**で塗る（赤緑ではない、カテゴリ色）
- ソフト+ハードを**合算したスコア**で **alpha（濃さ）1 軸のみ**変化
- ソフト/ハードの色分け・リング構造はしない

詳細な 2 エネルギー並列表示は、スコアバー・方角タップ popup・FortuneSheet 等の**別 UI** で行う。

---

## 3. アプリの構造 — 5 タブ常駐

`main.dart` が `IndexedStack` で 5 画面を**常駐**させ、タブ切替で表示を差し替える
（`Navigator.push` ではない = タブ間で state がリセットされない）。

| index | タブ | 役割 |
|---|---|---|
| 0 | **Map** | 16 方位エネルギーを地図上で読む |
| 1 | **Horo** | 出生図 + 今日の運勢カード |
| 2 | **Tarot** (Observe) | 1 日 1 枚のタロット |
| 3 | **Galaxy** | 月相サイクル + 意図と振り返り |
| 4 | **Sanctuary** | 設定 + プロフィール + 144 称号診断 + Pro 課金 UI |

- 起動時に `TarotData`（78 枚デッキ）/ `CelestialEvents`（天体イベント）/ `AppLocale`（言語）を初期化。
- 裏タブのアニメは `TickerMode` で停止（バッテリー/GPU 対策）。タブ切替時に各画面の
  プロフィール再読込・アニメ再開/停止を `_onTabTap` が調停する。
- Android の戻るボタン: Map 以外のタブ → Map に戻す / Map タブ → アプリ終了。
- サブ画面（Forecast / Locations / Philosophy 等）は各タブ内から `Navigator.push` で開く。

---

## 4. データの源流 — `SolaraProfile`

**すべては出生情報から始まる。** `SolaraProfile`（`utils/solara_storage.dart` 内に定義、ローカル永続化）が
中核データモデル: 名前 + 生年月日時 + 出生地（緯度経度）+ 称号診断結果 等。

- プロフィール未設定なら、各画面は占い系のオーバーレイを**全て非表示**にし、
  中央に「Sanctuary で設定する→」の誘導カードを出す（`_noProfile = true`）。
  これは Map / Horo / Forecast / Locations 共通の挙動。
- プロフィールは Sanctuary の `sanctuary_profile_editor.dart` または Horo の `horo_birth_panel.dart`
  で編集。地名検索（Worker `/search`）+ 逆ジオコーディング（Nominatim）+ タイムゾーン解決（Worker `/tz`）が連動。
- 編集すると、Map / Horo はタブ復帰時に `reloadProfile` / `loadProfile` で追従する。

---

## 5. 画面ごとの「何をするか・どう動くか」

### 5.1 Map 画面 — 方位エネルギーを地図で読む

**最大規模の画面**（22 ファイル / 12,283 行）。「地図を見る」だけでなく以下を内包する複合体。

**ユーザー体験**:
- 地図（OSM タイル、4 種スタイル切替）の上に、現在の基準地点を中心とした **16 方位の扇状セクター**が重なる。
  各方位の色の濃さ = その方角に在るエネルギー量。
- 左サイドに 3 ボタン（🔍 検索 / ☰ 表示メニュー / 📍 地点メニュー）。
- **下部に 4 チップ（Daily / Fortune / Locations / Forecast）** → それぞれが独立した重要機能（詳細は下記 5.1.1）。
- タイムスライダーで ±365 日 + 時分を動かせる。「LIVE」で今日に戻る。
- 方角をタップ → **方角詳細 popup**（Soft / Hard 独立 2 バー + 「どのアスペクトがどれだけ寄与したか」の attribution）。
- 惑星マーカーをタップ → 惑星の説明 popup。
- 任意地点をタップ → **引越し popup**（出生地 → その地点の ASC/MC + 12 ハウス + アスペクトラインの変化）。

**裏で何が起きるか**:
- 出生情報 + 基準地点 + 時刻を Worker `/astro/chart` に投げて出生図（natal + transit + progressed +
  ASC/MC/DSC/IC + 全アスペクト）を取得（`map_astro.dart` の `fetchChart`）。
- それを `scoreAll` が **16 方位 × 5 カテゴリ（全体/癒し/豊かさ/恋愛/仕事/対話）× Soft/Hard** のスコアに変換。
- 検索結果（Google Places 経由）には「現在中心からの方位スコア + 支配カテゴリ」を自動注入してから表示。
- **ACG（アストロカートグラフィー）モード**: 4 frame（natal/transit/progressed/solarArc）× アスペクトラインを
  世界地図上に描く。海外市場向けの売り。
- **Daily Transit（別画面）**: 今日の 10 惑星 × 4 アングル通過時刻のタイムライン。
- Map から **Worker への直接呼出は天体計算 + 検索 + タイルの 3 種のみ**（Gemini 呼出なし）。

#### 5.1.1 Map 下部 4 チップ — それぞれが独立した重要機能

下部チップバー（`map_menu_chips.dart`）は「利用頻度トップ」の 4 機能への入口。
左の **Daily** だけは状態を持つ特別なチップで、残り 3 つは静的なボタン。

##### ① Daily（Daily Transit）— 今日の惑星の動き

「今日、自分の頭上を惑星がいつ通過するか」を見る機能（F1-c）。**チップ自体が状態表示を兼ねる**:
- プロフィール未設定 → 🌱 アイコンで無効化
- その日まだ開いていない（未開封）→ アンティーク章アイコン + 金色の halo 発光
- 開封済み → その日のトップカテゴリのアイコンに変わる

**タップ時の挙動**:
- その日の **初回タップ** → トップカテゴリに応じた全画面演出（Dominant Fortune Overlay、約 4 秒）
  → 余韻 0.5 秒 → F1-c フル画面へフェードイン。
- **2 回目以降** → 演出をスキップして F1-c 画面に直行。

**F1-c フル画面の中身**:
- 最上部に「今日のトップカテゴリ」バナー（アイコン + ラベル + 一行解説）。
- メイン = **10 惑星 × 4 アングル（ASC/MC/DSC/IC）の通過時刻タイムライン**。各イベントに natal アスペクトの context 併記。
- VIEWPOINT ドロップダウンで観測点（出生地 / home / 登録地、最大 5 件）を切替。
- 各タイムライン行に 🗺 ジャンプ（その瞬時時刻を Map のタイムスライダーに送る）+ アスペクトチップ。
- フッターに「🌐 世界規模で見る」リンク（ACG モード起動の動線）。
- 裏で Worker `/astro/daily-transits` を叩く。

##### ② Fortune — 16 方位スコアの詳細グリッド（下部シート）

Map の扇状セクターが「合算 1 色」で大まかにしか見せないのに対し、Fortune シートは**詳細な数値**を見せる。
- 下から立ち上がる **下部シート**（ドラッグまたはハンドルタップで閉じる）。
- カテゴリスコアの **ソース（combined / transit / progressed）× 16 方位**のグリッド表示。
- 各方角の行をタップ → **2 エネルギー詳細 popup**（Soft / Hard 独立バー + どのアスペクトがどれだけ寄与したかの attribution）
  = 設計思想（2.1）の「2 エネルギー独立表示」を担う中核 UI。
- i ボタンから「Map の使い方 + カテゴリと関連惑星ペア」の説明 popup。
- プロフィール未設定時は無効。

##### ③ Locations — 登録拠点の方位スコア一覧（サブ画面）

複数の拠点（自宅・職場・旅行先など）を**横並びで比較**する管理画面（サブ画面、`locations_screen.dart`）。
- 登録拠点（VP スロット）を **16 方位スコア付きで一覧表示**。
- 各拠点ごとに Worker `/astro/chart` + `scoreAll` を呼んでスコアを計算。
- スコア順 / 距離順の並べ替え、基準点（現在地 / 出生地）切替、5 カテゴリ絞込。
- 日付ステッパーでスコア計算の日時を変更可能。
- Map で検索中なら、その検索地を「現在地」として引き継いで開く。
- 拠点数は `SlotManager` で制限（= Pro で「無制限拠点」化の候補）。

##### ④ Forecast — 1 年間の運勢予報（サブ画面）

時間軸での運勢の波を見る画面（サブ画面、`forecast_screen.dart`、高さ 92% で開く）。
- **1 年予測ヒートマップ** + 選択日の詳細 + **強運 Top5** + **「◯◯期」サイクル検出**
  （恋愛期・仕事期など、連続して高スコアな期間を `detectLifePeriods` で自動抽出）。
- year selector（現在年 + 過去 4 年）、ヒートマップの色モード切替。
- 裏で Worker `/astro/forecast`。**この endpoint だけ KV 月次クォータ（60 req/IP/月）を持つ**
  = Solara で唯一、既に課金境界が物理的に存在する機能。
- 🔴 **Forecast のスコアと Map のスコアは意図的に別計算**（一致しない）。Forecast は出生情報のみ、
  Map は拠点 + 瞬時時刻 + ASC/MC を含むため。混同を避けるため両画面間のジャンプリンクは廃止済み（2026-05-14）。

### 5.2 Horoscope 画面 — 出生図 + 今日の運勢

**ユーザー体験**:
- 自分のネイタルチャート（12 星座輪 + 10 惑星 + 4 アングル + アスペクト線）を描画。横スクロール + ピンチズーム可。
- 下部シートに 4 タブ: **Aspect**（アスペクト一覧、タップで解説）/ **Pattern**（Grand Trine・T-Square・Yod の
  検出 + 未来予測）/ **Transit**（今の星位を natal に重ねる）/ **Relocate**（リロケーション）。
- **占いカード**: 5 カテゴリ（恋愛/豊かさ/仕事/対話/全体）の占い文を表示。生成中は skeleton loading。
- 出生情報をインラインフォームで直接編集できる。

**裏で何が起きるか**:
- Map と**同じ** `/astro/chart`（`map_astro.dart` の `fetchChart`）でチャート取得 = Map と Horo は計算基盤を共用。
- 占いカードは Worker `/fortune`（Gemini）を 5 カテゴリ並列で呼んで生成（`horoscope_screen.dart` L530 `fetchFortune`）。
  2026-04-15 接続済み。
- リロケーションは Phase A（Dart 完結の静的テンプレ）+ Phase B（Worker `/relocation` = Gemini 動的解説）の二段構え。
- **Gemini 呼出 2 系統（`/fortune` + `/relocation`）が Horoscope に集中** = 課金で守るべき中央。

### 5.3 Observe（Tarot）画面 — 1 日 1 枚

**ユーザー体験**（`observe_screen.dart` で実コード検証済み）:
- 内部タブ 2 つ: 🃏 TAROT DRAW / 📜 HISTORY。
- カードをタップ → 78 枚から 1 枚ランダム抽選（正逆位置 50%）→ 3D フリップ演出（Y 軸回転 800ms）。
- フリップ完了後、Worker `/tarot`（Gemini）で解説文を生成。生成中は 4 種のメッセージが 4 秒ごとに切り替わる
  ローディング演出。解説はタイプライター演出（25ms/文字）で表示。
- **1 日 1 回固定**: 既に今日引いていれば再抽選不可（`_alreadyDrawnToday`）。引いたカードは `DailyReading` として永続化、
  翌日まで同じカードが表示される。
- Gemini 失敗時は要素別（火/水/風/地）の静的テンプレ文で fallback（「⚠ オフラインモード」表示）。
- HISTORY タブで過去に引いたカードの一覧を見られる。
  - **C3 履歴 Pro フィルタ** (2026-05-17): キーワード検索 / 大小アルカナ /
    エレメント 4 種 (火水風地) / 正逆位置の絞込チップ。Free 操作で Pro Unlock
    dialog、Pro は実フィルタ。
  - **A3 Pro 質問欄の保存** (2026-05-17): Pro 引き時の質問入力 (200 字 cap)
    は `DailyReading.question` に永続化。HISTORY 検索の対象にも含まれる。
    詳細展開時に「QUESTION」セクションで表示。
  - 詳細展開トグル (下三角アイコン) は 28px / 32×32 タップ領域 / ゴールド色
    で視認性確保 (2026-05-17 改善)。
- 背景は「占卓シーン」（5 惑星の楕円配置 + 流れ星 + 太陽光の演出）。
- ⚠️ コードに `_resetTodayReading`（[DEV] ボタン）あり = 本番リリース時に削除予定。

### 5.4 Galaxy 画面 — 月相サイクルと自己対話

**Solara の最大差別化体験。「占いをしない、節目で自己と対話する」場。**

**ユーザー体験 — 1 サイクル（新月→満月→刻星化）の流れ**:
1. **新月**: `NewMoonOverlay` が起動。物語テキスト → 4 択から「今サイクルの意図」を選ぶ → 詩的リビール。
   選んだ意図は `LunarIntention` として永続化。
2. **満月**: `FullMoonOverlay` が起動。新月で立てた意図の中間チェック（🌊 まだ取り組み中 / ✨ 進展あり /
   🌟 軽くなった の 3 段階）→ `MidpointCheck` 永続化。
3. **刻星化（新月前日 = サイクル終端）**: `CatasterismOverlay` が起動。「手放せた / まだ途中」の 2 択 →
   `CatasterismResult` 永続化 → 続けて **8 秒の星座形成演出**（`CatasterismFormationOverlay`、
   12 星座シンボルが集まり連結して 1 つの星座になる 4 ステージ演出）。
4. サイクル中の日々のタロット履歴 + 月相 + 名詞辞書から **MST（最小全域木）+ 形容詞×名詞**で
   その人だけの星座名・形が生成される（`constellation_namer.dart`）。
- 通常画面（Cycle タブ）は 3 層スパイラルでサイクル全日数を可視化 + 月相連動の Stella 詩的メッセージ。
- **Star Atlas タブ**: 過去に刻星化した星座のコレクション（最大 61 種の図鑑）。
  - **C2 Galaxy Archive Pro フィルタ** (2026-05-17): タブ上部に検索バー +
    レアリティチップ (multi-select) + ソートメニュー。Free は AbsorbPointer
    + Pro Unlock dialog 誘導、Pro は実フィルタ。レアリティ星は Icon ベース
    (textScaler 不変) で必ず 5 つ並ぶ。
  - **C5 形成演出再生 + エクスポート** (2026-05-17): カード長押し or
    右上 ⋯ メニューで bottom sheet (通常再生 Free / 形成演出 Pro /
    Markdown コピー Pro)。形成演出は既存 `CatasterismFormationOverlay`
    再利用。
- 画面下部に天体イベントバー（ingress / retrograde / eclipse を横スクロール表示）。
- Replay overlay で過去サイクルの星座を再生表示。タップでアニメスキップ、
  Android 戻るキーで Star Atlas に戻る (PopScope で消化、Map には飛ばない)。
- **刻星化 formation 完了時の共有ボタン** (Free、2026-05-17、柱 3):
  `CatasterismFormationOverlay` の View ボタン横に小さい円形シェアボタン →
  `ConstellationShareCardPage` を push (Sanctuary 称号カードと同じ
  1080×1920 9:16 設計、`ConstellationPainter(progress=1.0)` で完成星座描画)。

**裏で何が起きるか**:
- 月相計算は `moon_phase.dart`（Jean Meeus アルゴリズム、±2-3 分精度）。Worker 不要。
- 天体イベントバーのみ Worker `/astro/events` を使う。**Gemini 呼出は 0** = 純粋な可視化 + 自己対話。
- 永続化対象（`LunarIntention` / `MidpointCheck` / `CatasterismResult` / `GalaxyCycle`）は
  ユーザー最大の体験ログ = 機種変更時の引き継ぎ需要が高い。

### 5.5 Sanctuary 画面 — 設定 + 称号 + Pro 課金 UI

**ユーザー体験** — 設定画面が 5 セクション構成:
1. **プロフィール**: 名前・出生情報・言語切替・場所検索（→ `sanctuary_profile_editor.dart`）。
   ホーム地点（現住所）の設定もここ（Map の VP slot と同期）。
2. **🔴 144 称号診断儀式**（`sanctuary_title_diagnosis.dart`、1,385 行 = 本層最大）:
   召喚 → 序章 → カード選択（PART1 日常 + PART2 運命 = 計 28 問、PART3 コートカード 4 問）→ 鍛造演出
   → Reveal（Light 面 + Shadow 面の両面表示）。仕組み（アプリ内「称号の仕組み」i ボタン popup の開示内容）:
   - **生年月日 → 一言の称号**: 太陽星座 × 月星座 = 144 通りの固有の称号（診断で変わらない）
   - **28 問 → 5 軸スコア**（パワー/マインド/スピリット/シャドー/ハート）→ 最高得点軸 = 「気質」
   - **コートカード 4 問 → コート（役職）**: page/knight/queen/king、2 回以上選んだもの（バラバラなら mixed）
   - **5 軸 × 5 コート = 25 クラス**（騎士・賢者・占星術師・忍者…）
   - 同点時は **占星術シード**（太陽 × 月星座 144 通り）で 1 つに決定
   - Light 面 = 長所 / Shadow 面 = ユーモア混じりの「あるある」、結果画面タップで切替
   診断結果はカード画像にして OS シェア可能。いつでも再診断できる。
3. **🟢 Cosmic Pro アップグレード**（Phase 2-6b 配線完了、2026-05-16）:
   Cosmic Pro バナータップで `PaywallScreen` (fullscreenDialog) を push。
   ペイウォールでは Stella 相談 / ACG 4 フレーム / リロケーション / 記録庫 / 時刻スライダーの 5 機能を
   icon + 説明で提示し、`Offerings.current` の年額・月額パッケージをカード表示。タップで
   `Purchases.purchase(PurchaseParams.package(...))` を呼び、購入完了は `CustomerInfo` listener が
   `ProStatus.setPro(true)` で全画面に伝播。Offerings 未配信 / API キー未設定時は「ストアの準備中です」
   バナーで graceful degrade。法的書類 (利用規約 / プライバシーポリシー / 特定商取引法 / 解約方法 deeplink)
   と「購入を復元」ボタンを内蔵 (B5 公開ブロッカー 11 項目をすべて満たす)。
   - **API キー注入**: `--dart-define=SOLARA_RC_IOS_KEY=appl_xxx --dart-define=SOLARA_RC_ANDROID_KEY=goog_xxx`
   - **検証**: `EntitlementVerificationMode.informational` で SDK 検証を有効化し、`VerificationResult.failed`
     を Free に倒すロジックで security_principles 原則 1 を担保。
   - **Sanctuary**: Pro 加入時はバナーを「Cosmic Pro 加入中」表示に切替え、復元ボタン + 「プラン・規約」ボタン
     (ペイウォール再表示) も提示。DEV ビルドでは `kDebugMode` 限定の Pro トグルが並走。
4. **🟢 Records セクション**（柱 3、2026-05-17）:
   - **相談履歴** → `ConsultationHistoryScreen` (Phase 2-4 で実装、Free 全件閲覧可)
   - **称号 変遷** → `TitleHistoryScreen` (C4、Free 閲覧可、Pro が「クラスを取り直して履歴を増やす」道具)
5. **占星術設定**: **ホロスコープのオーブ**設定（アスペクト 8 種 + パターン 5 種の角度許容範囲を
   0.1° 単位でカスタマイズ。**Horoscope 画面専用** — Map・Daily Transit には影響しない）、ハウスシステム選択。
6. **アプリ設定**: 言語切替、利用規約等。

**🔴 C4 称号 (クラス) 変遷ギャラリー** (2026-05-17):
- 二つ名 (太陽 × 月 144 通り) = 出生固定・永久不変・取り直し不可
- クラス (25 種) = 「今の自分」クイズで取り直し可能。Free は 1 回、**Pro は無制限**
- `_startDiagnosis` 完了時に `SolaraStorage.addTitleHistoryEntry` で履歴自動追記
  (連続同一 axis+court は skip、上限 60 件 = 5 年分)
- Records から `TitleHistoryScreen` で NOW バッジ + 時系列 chain で変遷を可視化

### 5.6 サブ画面（各タブ内から push で開く）

| サブ画面 | 何をする | 裏で |
|---|---|---|
| **Forecast**（運勢予報） | 1 年予測ヒートマップ + 強運 Top5 + 「◯◯期」サイクル検出 | Worker `/astro/forecast`。**唯一 KV 月次クォータ（60 req/IP/月）を持つ** = 課金境界に最適 |
| **Locations**（拠点管理） | 登録拠点を 16 方位スコア付きで一覧管理 | 各拠点ごとに `/astro/chart` を呼ぶ。拠点数は `SlotManager` で制限 |
| **Philosophy**（設計思想） | `solara_manifesto.dart` の 3 セクションを表示 | 現在この画面への導線はない（#5c で孤立ファイル検出 → オーナー判断で**保留決定**: 削除も導線追加もしない、再提案不要） |
| **Daily Transit** | 今日の惑星 × アングル通過タイムライン | Worker `/astro/daily-transits` |
| **Font Preview** | フォント比較（開発者用、ユーザー導線なし） | — |

### 5.7 Stella 相談（Consultation）— 悩み起点の ACG/CCG 解釈

**Pro 看板機能のひとつ。Map の「16 方位スコア」が「**俯瞰**」なら、こちらは「**特定の悩みに対する解釈**」を返す。**

**ユーザー体験**（`screens/consultation/` に実装、part-of パターンで 7 ファイル構成）:
- 入口は 2 つ（2026-05-17 簡素化、ACG/非 ACG 共通ルールに統合）:
  1. **タップ起点**: Map 上の任意地点タップで Pro ユーザーは `ConsultEntryPopup`（近接 3 conjunction line 表示）→「📍 この場所で相談する」CTA（specific scope 固定）。線にヒットしたタップは `MapRelocationPopup` / `MapLineNarrativeSheet` ヘッダ直下 CTA、天頂/天底マーカータップは `AstroZenithPopup` CTA から zenith 座標 preset で起動。空地点タップは ACG/非 ACG どちらでも、relocate ピル OFF + 線非ヒットなら Pro に popup（Free は何も起きない）。旧 ACG 専用「🔮 相談ピル」（Phase 2026-05-16）は撤去
  2. **目的起点**: Daily Transit popup の「🔮 Stella に相談する」CTA（scope は入力で選ぶ、Phase 2-3c 予定）
- Stage 1（入力フォーム、`consultation_input_screen.dart` + 3 つの part ファイル）:
  - **テーマ 6 択**（恋愛・お金・仕事・対話学び・癒し・新たな出発）
  - **モード 3 択**（移住 / 旅行 / おでかけ）— 使う AstroLine フレームを決定（natal/transit/progressed/solarArc）
  - **スコープ 3 択**（モード別に変化、おでかけのみ specific/bearings/region、他は specific/region/world）
  - **具体地点ピッカー**: inline 検索（`_SpecificPicker` 内、Google Places / Nominatim 両対応、bias center = 現在地） + 「🗺 地図で選ぶ」(`ConsultationPlacePickerScreen`) の A+B ハイブリッド
  - 自由記述（任意 200 字、テーマ×モード×スコープ で **54 例文** から 3 つを提示 → タップで反映）
- Stage 2（候補生成、`consultation_engine.dart`）:
  - テーマ→関係惑星マッピング（love→venus/mars/moon 等、`FORTUNE_CATEGORIES` 流用）
  - 関係惑星に該当する `AstroLine` を抽出 → 4 種の生成関数で候補地点を出す:
    `candidateForSpecific` / `candidatesForRegion` / `candidatesForWorld` / `candidatesForDaily`
  - 候補は近接線リスト + アングル + オーブ + bearing 情報を伴って返る（**世界を「検索」しない、計算済の線から「最寄り」を返す**）
- Stage 3（Stella 解釈、Worker `/astro/consultation`）:
  - Gemini 2.5 Flash に「候補構造 + テーマ + 自由記述」を渡す。**プロンプトに 9 項目の強制制約**:
    吉凶禁止 / 店舗名禁止 / 無いものを在ると言わない / awareness を開く outro / 文体ハイブリッド（観察=だである / 寄り添い=ですます）等
  - 返却: `{ intro, candidates[].narrative, candidates[].energyLabels, outro }`
  - Gemini 失敗時は静的 fallback（候補位置 + 近接線の客観情報）+ リトライ
- Stage 4（結果表示、`consultation_result_screen.dart` + `consultation_result_widgets.dart`）:
  - `PageView` 1 個・最大 3 枚カードを横スワイプ（`HapticFeedback.selectionClick` 触覚）
  - 各カード = 候補名 + energyLabels チップ + narrative（縦スクロール対応）
  - intro/outro は固定上下、ページャは `_PageIndicator`、refresh は `_RefreshButton`（既出除外で再生成）
  - シェアボタン（AppBar `Icons.ios_share`）= テキスト / PNG 画像 1080px 選択（RepaintBoundary capture）
- **永続化と Pro ゲート**:
  - 全相談は `SolaraStorage` に自動保存（200 件キャップ）→ 別画面（`consultation_history_screen.dart`）で履歴閲覧
  - Free でも履歴は永久保持（柱3 の核原則）
  - シェアは Pro ゲート（Free タップ → `showProUnlockDialog`、DEV では Sanctuary トグルで Pro 切替可）

**裏で何が起きるか**:
- ① テーマ→関係惑星 / ② モード→フレーム / ③ theme 線抽出 / ④ 候補生成 — の **①〜④ は全部 Flutter クライアント**で完結
- Worker は Stella 呼出（Gemini）のみ。クライアントから渡るのは候補構造 + テーマ + 自由記述のみで、**ユーザー名・誕生日・現在地座標は Stella に渡らない**（自由記述の中身はユーザー本人が書いたものなので別）
- ファイル分割（2026-05-15 → 2026-05-16 で再分割）: HARD threshold (500 行) を全消化するため、入力 = 4 ファイル (`screen` / `widgets` / `examples` / `picker`)、結果 = 2 ファイル (`screen` / `widgets`)、B picker = 2 ファイル (`screen` / `widgets`) の **計 8 ファイル**を part-of で連結（`horoscope_screen.dart` 同様）

**設計根拠**: `docs/pro_candidates.md §7.2 (ii)`。

---

## 6. 横断的な仕組み

### 6.1 バックエンド = Cloudflare Worker

本番 URL: `https://solara-api.solodev-lab.com`（`solaraWorkerBase` 定数経由、ハードコード禁止）。
役割は 4 種:

| 役割 | endpoint | 特徴 |
|---|---|---|
| **天体計算（純数学）** | `/astro/chart` `/astro/forecast` `/astro/daily-transits` `/astro/events` `/tz` | `astronomy-engine` npm 依存。一部は Dart にも移植済み |
| **AI narrative 仲介（Gemini）** | `/fortune` `/tarot` `/relocation` | Gemini API key 秘匿のため Worker 必須。**1 リクエスト = Gemini コスト発生 = 課金で守る最大対象** |
| **検索プロキシ** | `/search` | Google Places（主）+ Nominatim（フォールバック） |
| **地図タイル中継** | `/tiles/osm/*` | OSM を Worker UA で取得、edge cache 24h |

- **死んだ endpoint 2 件**: `/astro/predict`（旧 60 日予測、未接続）/ `/astro/line-narrative`
  （AI 解説、2026-05-11 撤去済みだが Worker 側に残骸）。
- Gemini を呼ぶのは Horoscope（`/fortune` + `/relocation`）と Observe（`/tarot`）のみ。
  Map と Galaxy は Gemini を一切使わない。

### 6.2 スコアエンジン — Soft/Hard 2 エネルギー

- 出生図のアスペクト（惑星間の角度関係）から、各方位・各カテゴリの Soft/Hard エネルギー量を集計。
- 各アスペクトは `quality`（性質）で 3 分類され、`_qSplit` 関数で重みを Soft/Hard に振り分ける:
  - **soft**（トライン 120°・セクスタイル 60°・セミセクスタイル 30°）→ 全額 Soft フィールドへ。
  - **hard / tense**（スクエア 90°・オポジション 180°・セミスクエア 45°・クインカンクス 150°）→ 全額 Hard フィールドへ。
  - **🔴 neutral（コンジャンクション 0°）→ Soft と Hard に半々（`w/2, w/2`）で分配**。
- **コンジャンクション（合・0°）の扱い** — 重要:
  - コンジャンクションは soft でも hard でもなく **`neutral`** に分類される（`aspectTypes` / `_mapAspects` の `quality` フィールド）。
  - neutral なので、その重みは **Soft と Hard の両方に等分**で加算される（`direction_energy.dart` の設計コメント:
    「neutral aspect (conjunction) は両方非0」）。
  - これは設計思想（§2）に忠実: コンジャンクション = 2 惑星が重なって溶け合う配置で、流れ（Soft）にも
    摩擦（Hard）にも転びうる。「どちらか」を判定せず、両エネルギーが同時に在る状態として記録する。
  - Map の 16 方位スコア計算ではコンジャンクションの **orb は 6.0°**（opposition と並んで最も広い）、
    weight は 0.6（トライン/スクエアの 1.0 より控えめ）。2026-05-14 に 8.0°→6.0° に調整 — 8° は
    neutral 配分（soft/hard 半々）で全方位を底上げしすぎ、方位コントラストを弱めていたため。
  - 方角タップ popup の attribution でも、コンジャンクション由来の寄与は Soft 欄・Hard 欄の両方に現れる。
- **オーブ値の出どころ（2026-05-14 整理）**:
  - **Map / Forecast の 16 方位スコア**: `map_astro.dart` の `_mapAspects`（および Worker `astro.js` の
    `MAP_ASPECTS` — 2 箇所コピー）にハードコード。合 6° / 矩 5° / トライン 5° / 六分 4° / 補 3° / 衝 6°。
  - **Daily Transit**: Worker `daily_transits.js` の自前デフォルト（合 4° 等）。
  - **Horoscope**: Sanctuary の「ホロスコープのオーブ」設定（`solara_orb_settings`）が**反映される**。
    ユーザーがオーブを変えると Horoscope のアスペクト線とパターン検出（Grand Trine / T-Square / Yod）が
    再計算される。Map・Daily Transit には影響しない（Horoscope 専用設定）。
- `direction_energy.dart` の `aggregateContributions` が「どのアスペクトがどれだけ寄与したか」を保持
  → 方角タップ popup の attribution 表示に使う。
- スコアソースは `combined`（合計）/ `transit`（TR）/ `progressed`（PR）の 3 種。
- コンポーネント色は `tSoft`/`tHard`/`pSoft`/`pHard` の **4 色**（Soft/Hard 独立 × Transit/Progressed）。
- ⚠️ **Forecast のスコアと Map のスコアは意図的に別計算**（一致しない）。Forecast は出生情報のみ、
  Map は拠点 + 瞬時時刻 + ASC/MC を含む。統合しないことが確定事項。

### 6.3 AI narrative（Gemini 占い文）

- `fortune_api.dart`（層 2a）が `/fortune` `/tarot` `/relocation` の 3 系統を一手に引き受ける。
- `/fortune` = gemini-2.5-flash、`/tarot` = `TAROT_MODEL_PRIMARY` env var（Gemini 2.5 Pro）。
- 設計思想に従い、プロンプトで「good/bad」「lucky/unlucky」を使わせず「事実提示型」に縛る。
- 失敗時は各画面が静的テンプレで fallback（Observe = 要素別テンプレ等）。

### 6.4 永続化 — 全てローカル

- `solara_storage.dart`（層 2b）が `SharedPreferences` ベースで**アプリ状態の全てを握る中央集権ファイル**
  （32 の load/save 関数）: `SolaraProfile` / タロット履歴 / 月相意図 / 拠点スロット / Orb 設定 /
  デイリーリセット時刻 / Map スタイル / overlay 状態 等。
- 現状クラウド同期はなし = 機種変更で全消失。クラウドバックアップは Pro 機能の有力候補。

### 6.5 演出システム — overlay

- **Map fortune 演出**: 1 日の最初のタップで、その日の最高スコアカテゴリに応じた 4 秒の全画面演出。
- **Galaxy moon 演出 4 種**: 新月/満月/刻星化/形成。3 系（new/full/catasterism）は同じフェーズ構造
  （物語 → 選択 → リビール）を共有部品で組んでいて保守性が高い。
- これらは「節目にだけ被さる」演出で、Solara の体験の質を担う重要部分。

---

## 7. アプリ内ヘルプ — i / ? ボタンが説明すること

Solara は画面の至る所に **i ボタン**（用語の説明）と **? ボタン**（画面の使い方）を持つ。
説明 popup は全て `showInfoPopup`（`widgets/info_popup.dart`）に統一されている。
**これらの中身を読むと「Solara が自分自身をどう説明しているか」が分かる** = アプリの自己定義。

### 7.1 画面まるごとの「使い方ガイド」7 種

各画面の見出し横の ? ボタンから開く。それぞれが画面の存在意義を一段落で語っている。

| ガイド | 開く場所 | 何を教えるか（要点） |
|---|---|---|
| **Map の使い方** | Map スコアバー左ラベル下の i | 16 方位エネルギーは「進む方向」だけでなく、**意識を向ける・声をかける向き・物の置き場所・出発時の方角・座る席の向き・深呼吸する方角**など自由に使える「読み取りツール」。スコアバータップでカテゴリ循環（総合→癒し→豊かさ→恋愛→仕事→話す）。+ カテゴリと関連惑星ペア + ペア重みの仕組み + 「総合」との関係 |
| **今日の動きの読み方**（Daily Transit） | Daily 画面ヘッダの ❓ | 🔴 **Map 画面とは別物**: Map = 「地表方位」（どの土地に行くか）、この画面 = 「天空方位」（惑星が空の ASC/MC/DSC/IC をいつ通るか）。同じ「東」でも Map は「東の土地」、ここは「東の地平線（惑星が昇る位置）」。両方を組み合わせて「方角 × 時間」を算出 |
| **ASTRO\*CARTO\*GRAPHY の使い方** | ACG モードの ? | 1970 年代 Jim Lewis が体系化した「地球上の天体地図」。Solara は伝統的 ACG に**時間軸**（Natal/Transit/Prog/Solar Arc の 4 フレーム + 時刻スライダー）を重ねた。天頂マーカー = 惑星エネルギーが頭上から降る「シャワー直下」地点。線タップで引越し効果 |
| **LOCATIONS の使い方** | Locations 画面の ? | VIEWPOINT（視点の中心点）から見た登録地点（LOCATION）のエネルギー一覧。「今日この公園は癒しスコアが高い／このカフェは恋愛スコアが高い」を一目で見る便利機能。日付・時刻変更で再計算、カテゴリで再ランク |
| **FORECAST の使い方** | Forecast 画面の ? | 今後 1 年（365 日）の運勢予測。1 年ヒートマップ + 選択日詳細 + 運勢サイクル（モテ期/豊かさ期/癒し期…）+ 強運 Top5。🔴 **Map の数字と一致しない理由**を明示（Forecast = 出生情報のみ・場所時刻不問 / Map = 今いる地点 + 今この瞬間・ASC は 15°/時間で動く）。「別の角度から同じあなたを読む 2 つのレンズ」 |
| **Galaxy 画面とは** | Galaxy 画面の i（今日の月相も併記） | 月のサイクル（約 29.5 日）に合わせて日々のタロットリーディングが「星」として記録され、1 サイクル = 1 つの星座が完成する画面。「内面のリズムが星座という形で残る」 |
| **称号の仕組み** | Sanctuary 称号診断の i | 6 ステップで 144 称号の決定ロジックを開示（§5.5 に詳細）。「気質はその日の気分で動くもの、いまの自分を映す鏡として楽しんで」 |

### 7.2 占星術用語の i ボタン — 内蔵用語辞書 42 語

`astroGlossary`（`utils/astro_glossary.dart`）に **42 の専門用語**が「正式名 + 1 行サマリ + 詳細解説」で定義され、
用語の横の i ボタン（`AstroTermLabel`）からグラスモーフィズム popup で表示される。カテゴリ:

| カテゴリ | 用語数 | 例 |
|---|---|---|
| 4 アングル | 4 | ASC（上昇宮）/ MC（天頂）/ DSC（下降宮）/ IC（天底） |
| 12 ハウス | 12 | 第1ハウス（アセンダント）〜 第12ハウス（秘密のハウス） |
| Phase M2 機能用語 | 14 | リロケーション / 引越しレイヤー / アスペクト線（ACG）/ Transit 線（CCG）/ Progressed 線 / Solar Arc 線 / 天頂点 / 天底点 / 高度 / 緯度帯 / 16 方位エネルギー / 惑星方位ライン / Placidus |
| FORTUNE カテゴリ | 6 | 総合 / 恋愛 / 豊かさ / 仕事 / 話す / 癒し（各カテゴリの占星術的定義）|
| 設計思想キーワード | 3 | **2 つの独立したエネルギー（ソフト・ハード）** / ソフトアスペクト / ハードアスペクト |
| Daily Transit ロジック | 3 | 「今日の TOP」の選び方 / 4 アングル通過の意味 / おすすめ行動の例の使い方 |

→ **`two_energies` 用語が i ボタンとして方角詳細 popup 等から参照されている** = 設計思想（§2）をユーザーが
その場で確認できる導線がアプリに組み込まれている。

### 7.3 機能別の i ボタン（granular）

上記以外にも、各機能の細部に i ボタンがある（実装は全て `showInfoPopup` 経由）:
- **アスペクトチップ詳細**（Daily Transit / Horoscope）— タップしたアスペクトの占星術的解説
- **惑星マーカー詳細**（Map）— 惑星 × フレーム（natal/transit/progressed）の説明テキスト
- **パターン予測詳細**（Horoscope）— Grand Trine / T-Square / Yod の解説
- **天体イベント詳細**（Galaxy イベントバー）— ingress / retrograde / eclipse 等の意味
- **惑星 × アングル詳細**（Daily Transit）— 10 惑星 × 4 アングル = 40 パターンの基本意味 + カテゴリ別 appendix
- **カテゴリ別おすすめ行動**（Daily Transit）— カテゴリ × アングルフィルタごとの行動 tips

### 7.4 ヘルプから読み取れる「Solara の自己定義」

i / ? ボタンの中身を通読すると、アプリが自分をどう位置づけているかが見える:

1. **「読み取りツールであって、選択ガイドではない」** — Map の使い方が明言。方角は「進む」以外にも
   意識・発話・配置・呼吸など多様に使える。
2. **「地表方位」と「天空方位」は明確に別概念** — Map（土地の方向）と Daily Transit（空の惑星位置）を
   混同しないよう、Daily ガイドが警告色で区別を強調。
3. **複数の数値が「一致しない」のは仕様** — Forecast ≠ Map、カテゴリ別合算 ≠ 総合。
   「どちらが正しいではなく、別の角度から同じあなたを読むレンズ」という説明を繰り返す。
4. **占星術の伝統への敬意 + 独自の上乗せ** — ACG ガイドは Jim Lewis への礼を述べ、その上に
   「時間軸 + 16 方位スコア」という Solara 独自の重ね合わせを位置づける。
5. **設計思想がヘルプに組み込まれている** — `two_energies` 用語辞書が方角 popup から参照可能 =
   「2 エネルギー独立・吉凶判定なし」をユーザーがいつでも確認できる。

---

## 8. データの流れ（全体像）

```
[ユーザーが出生情報を入力]
        │
        ▼
  SolaraProfile（ローカル永続化）
        │
        ├──→ Worker /astro/chart ──→ 出生図（natal+transit+progressed+アングル+アスペクト）
        │         │
        │         ├──→ scoreAll ──→ 16方位×5カテゴリ×Soft/Hard スコア ──→ Map 扇状セクター / 方角popup
        │         └──→ Horoscope チャート描画
        │
        ├──→ Worker /fortune（Gemini）──→ 5カテゴリ占い文 ──→ Horoscope 占いカード
        ├──→ Worker /tarot（Gemini）──→ カード解説 ──→ Observe（+ DailyReading 永続化）
        ├──→ Worker /relocation（Gemini）──→ 引越し解説 ──→ Horoscope Relocate タブ
        ├──→ Worker /astro/forecast ──→ 1年スコア時系列 ──→ Forecast ヒートマップ
        ├──→ Worker /astro/daily-transits ──→ 通過タイムライン ──→ Daily Transit 画面
        └──→ Worker /astro/events ──→ 天体イベント ──→ Galaxy イベントバー

[月相（Dart ローカル計算、Worker 不要）]
        │
        └──→ Galaxy: 新月→意図 / 満月→中間チェック / 刻星化→星座結晶化
                     （LunarIntention / MidpointCheck / CatasterismResult を永続化）
```

---

## 9. まだ「動かして見ていない」こと（正直な限界）

本ドキュメントは**コードと機能インベントリからの理解**であり、以下は含まない:
- 実機での UX の手触り（アニメの滑らかさ、操作の直感性、待ち時間の体感）
- どの機能が磨き込まれていて、どこが粗いか
- ユーザーが実際に何に価値を感じ、何で離脱するか
- 競合アプリと並べたときの相対的な強み/弱み

→ Pro 機能を**確定**するには、この「体験の手触り」と「市場検証」が別途必要。
本ドキュメントは「Solara が機能として何をするか」を押さえるための土台。

---

## 10. 関連ドキュメント

- [`feature_inventory.md`](feature_inventory.md) — アーキテクチャ視点の全 17 層インベントリ + 対整合チェック #1〜#7
- `architecture.md` — 技術アーキテクチャ詳細（計算式等）
- メモリ `project_solara_design_philosophy.md` — 設計思想の上位ルール（全機能を縛る）
- メモリ `project_solara_launch_checklist.md` — Pro 公開までの全タスク段階管理
- メモリ `project_solara_feature_extractor.md` — 機能インベントリ構築方針 + extract.py
