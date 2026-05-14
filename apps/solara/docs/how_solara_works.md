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
- 画面下部に天体イベントバー（ingress / retrograde / eclipse を横スクロール表示）。
- Replay overlay で過去サイクルの星座を再生表示。

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
   召喚 → 序章 → 3 ラウンドのカード選択 → 鍛造演出 → Reveal（Light 面 + Shadow 面の両面表示）。
   出生情報からの astro seed + ユーザーが選んだカードの組合せで **144 称号**（12 太陽部位 × 12 月部位）を確定。
   25 クラス × Light/Shadow。診断結果はカード画像にして OS シェア可能。
3. **🔴 Cosmic Pro アップグレード UI**（既に実装済、`_buildCosmicProSection` L653-724）:
   $9.99/月 または $49.99/年、訴求 3 機能「Aether shaders · Galaxy Archive · Advanced astrology」。
   ※ UI のみ実装、機能ゲート（`isPro` 判定 / RevenueCat / IAP）は未実装。
4. **占星術設定**: Orb 設定（8 アスペクトの角度許容範囲を 0.1° 単位でカスタマイズ）、ハウスシステム選択。
5. **アプリ設定**: 言語切替、利用規約等。

### 5.6 サブ画面（各タブ内から push で開く）

| サブ画面 | 何をする | 裏で |
|---|---|---|
| **Forecast**（運勢予報） | 1 年予測ヒートマップ + 強運 Top5 + 「◯◯期」サイクル検出 | Worker `/astro/forecast`。**唯一 KV 月次クォータ（60 req/IP/月）を持つ** = 課金境界に最適 |
| **Locations**（拠点管理） | 登録拠点を 16 方位スコア付きで一覧管理 | 各拠点ごとに `/astro/chart` を呼ぶ。拠点数は `SlotManager` で制限 |
| **Philosophy**（設計思想） | `solara_manifesto.dart` の 3 セクションを表示 | 現在この画面への導線はない（#5c で孤立ファイル検出 → オーナー判断で**保留決定**: 削除も導線追加もしない、再提案不要） |
| **Daily Transit** | 今日の惑星 × アングル通過タイムライン | Worker `/astro/daily-transits` |
| **Font Preview** | フォント比較（開発者用、ユーザー導線なし） | — |

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
- ソフト系アスペクト（トライン 120°・セクスタイル 60° 等）→ soft フィールドに加算。
  ハード系アスペクト（スクエア 90°・オポジション 180° 等）→ hard フィールドに加算。
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

## 7. データの流れ（全体像）

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

## 8. まだ「動かして見ていない」こと（正直な限界）

本ドキュメントは**コードと機能インベントリからの理解**であり、以下は含まない:
- 実機での UX の手触り（アニメの滑らかさ、操作の直感性、待ち時間の体感）
- どの機能が磨き込まれていて、どこが粗いか
- ユーザーが実際に何に価値を感じ、何で離脱するか
- 競合アプリと並べたときの相対的な強み/弱み

→ Pro 機能を**確定**するには、この「体験の手触り」と「市場検証」が別途必要。
本ドキュメントは「Solara が機能として何をするか」を押さえるための土台。

---

## 9. 関連ドキュメント

- [`feature_inventory.md`](feature_inventory.md) — アーキテクチャ視点の全 17 層インベントリ + 対整合チェック #1〜#7
- `architecture.md` — 技術アーキテクチャ詳細（計算式等）
- メモリ `project_solara_design_philosophy.md` — 設計思想の上位ルール（全機能を縛る）
- メモリ `project_solara_launch_checklist.md` — Pro 公開までの全タスク段階管理
- メモリ `project_solara_feature_extractor.md` — 機能インベントリ構築方針 + extract.py
