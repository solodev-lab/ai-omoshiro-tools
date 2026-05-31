# 層 4f: サブ画面 (Forecast / Locations / Philosophy / Font Preview)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 31 / 総行数: 10834
- class/mixin/extension/enum: 97
- 関数 (top-level + method の素拾い): 276
- Navigator.push 等: 0
- Popup/Dialog 呼出: 8
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/ai_consent_screen.dart` (353 行)

**imports:** dart=0 / package=2 / relative=2

- relative: `../utils/legal_urls.dart`, `../utils/solara_storage.dart`

**型定義 (4):**

- L23 `class AiConsentScreen : StatelessWidget`
  - AI 生成同意モーダル (Apple 5.1.2(i) / Google Generative AI Apps Policy)。
- L258 `class _Section : StatelessWidget`
- L295 `class _LegalLinks : StatelessWidget`
- L313 `class _LinkPill : StatelessWidget`

**関数 (4 public + 3 private):**

- L84 `build()`
- L265 `build()`
- L301 `build()`
- L319 `build()`

  <details><summary>private 関数 3 件</summary>

  - L28 `_handleAgree()`
  - L34 `_handleDecline()`
  - L65 `_openLegalUrl()`

  </details>


### `lib/screens/consultation/consultation_credit_sheet.dart` (348 行)

**ファイル先頭コメント:**

```
Stella 相談 追加クレジット購入シート (消費型 IAP、設計 B 案)

設計: project_solara_stella_free_credits.md
  - 無料週次クレジットを使い切った非 Pro ユーザーが、追加クレジットを購入する導線
  - 価格は「Pro へ寄せた割高設定」(数回買うなら Pro の方が得 → 転換装置)
  - 「Cosmic Pro なら無制限」CTA を併置して Pro へ誘導
  - 購入はサインイン必須 (残高はアカウント appUserId に紐づく、機種変で失わない)
  - 付与はサーバー側 (RC Webhook → DO 残高加算)。購入後に状況を再取得して反映

🔴 RevenueCat に creditsOfferingId ('credits') Offering + 消費型 Package を
   作成しておく必要がある。未配信時は「準備中」表示。
```

**imports:** dart=1 / package=3 / relative=6

- relative: `../../theme/solara_colors.dart`, `../../utils/consultation_api.dart`, `../../utils/consultation_credits.dart`, `../../utils/purchases_service.dart`, `../../utils/solara_auth.dart`, `../paywall_screen.dart`

**型定義 (2):**

- L41 `class _CreditSheet : StatefulWidget`
- L48 `class _CreditSheetState : State`

**関数 (5 public + 8 private):**

- L28 `showConsultationCreditSheet()` — クレジット購入シートを開く。
- L45 `createState()`
- L60 `initState()`
- L68 `dispose()`
- L204 `build()`

  <details><summary>private 関数 8 件</summary>

  - L73 `_onCreditsChanged()`
  - L77 `_load()`
  - L89 `_ensureSignedIn()`
  - L140 `_buy()`
  - L180 `_pollUntilGranted()`
  - L193 `_openPaywall()`
  - L275 `_buildContent()`
  - L299 `_packageTile()`

  </details>


### `lib/screens/consultation/consultation_history_screen.dart` (297 行)

**ファイル先頭コメント:**

```
Consultation History Screen — Phase 2-4

設計: apps/solara/docs/pro_candidates.md §7.2 Stage 4 + §7.3 柱3

レイアウト:
  - AppBar (戻る / すべて削除)
  - ListView (新しい順、savedAt 降順)
  - 各行: 保存日時 + テーマ + モード + scope + 最初の候補名 + 自由記述抜粋
  - 行タップ → ConsultationResultScreen を読込み専用 (initialReading) で開く

柱 3 の原則:
  - Free でも全件閲覧できる (件数上限 200 は技術的フェイルセーフ)
  - 検索・フィルタは Pro 機能 (本画面では UI のみプレースホルダ、ゲートは課金後)
```

**imports:** dart=0 / package=1 / relative=7

- relative: `../../theme/solara_colors.dart`, `../../utils/consult_restore.dart`, `../../utils/consultation_record.dart`, `../../utils/solara_storage.dart`, `../../widgets/glass_panel.dart`, `../map/map_constants.dart`, `consultation_result_screen.dart`

**型定義 (2):**

- L80 `class ConsultationHistoryScreen : StatefulWidget`
- L102 `class _ConsultationHistoryScreenState : State`

**関数 (4 public + 8 private):**

- L98 `createState()`
- L111 `initState()`
- L120 `dispose()`
- L200 `build()`

  <details><summary>private 関数 8 件</summary>

  - L43 `_themeColor()`
  - L125 `_load()`
  - L137 `_delete()`
  - L146 `_toggleFavorite()`
  - L157 `_confirmDeleteAll()`
  - L245 `_buildFilterBar()`
  - L266 `_buildList()`
  - L290 `_openDetail()`

  </details>


### `lib/screens/consultation/consultation_history_widgets.dart` (488 行)

**ファイル先頭コメント:**

```
Consultation History — サブウィジェット (part of consultation_history_screen.dart)

履歴画面の presentation 部品 (空状態 / 履歴カード / メタチップ) を分離 (HARD500 回避)。
```

**型定義 (4):**

- L7 `class _EmptyState : StatelessWidget`
- L57 `class _FilterChip : StatelessWidget`
  - 履歴フィルタ用のトグルチップ (すべて / お気に入り)。
- L96 `class _HistoryCard : StatelessWidget`
- L460 `class _MetaChip : StatelessWidget`

**関数 (4 public + 1 private):**

- L13 `build()`
- L68 `build()`
- L243 `build()`
- L468 `build()`

  <details><summary>private 関数 1 件</summary>

  - L432 `_confirmDelete()`

  </details>


### `lib/screens/consultation/consultation_input_examples.dart` (106 行)

**ファイル先頭コメント:**

```
Consultation Input — だれと / 願い の記入例 (テーマ別)
(part of 'consultation_input_screen.dart')

自由記述 (⑤ だれと / ⑥ 願い) はタップで埋まる記入例を添えて誘導する。
候補は選択中のテーマ (恋愛/豊かさ/仕事/対話/癒し/変化) に沿ったものだけを出す。
```

**型定義 (3):**

- L39 `class _ExampleChips : StatelessWidget`
  - タップで自由記述を埋める記入例チップ群。
- L88 `class _WhomExamples : StatelessWidget`
- L98 `class _WishExamples : StatelessWidget`

**関数 (3 public + 2 private):**

- L45 `build()`
- L94 `build()`
- L104 `build()`

  <details><summary>private 関数 2 件</summary>

  - L20 `_whomExamplesFor()`
  - L34 `_wishExamplesFor()`

  </details>


### `lib/screens/consultation/consultation_input_logic.dart` (199 行)

**ファイル先頭コメント:**

```
Consultation Input — リクエスト組み立て + 開始フロー (extension)
(part of 'consultation_input_screen.dart')

State 本体 (consultation_input_screen.dart) の HARD500 回避のため、
setState を呼ばない純ロジック (when/scope → ConsultationRequest、開始ポップアップ、
結果画面遷移) を extension に分離。
```

**型定義 (1):**

- L25 `extension _ConsultationInputLogic : _ConsultationInputScreenState`

**関数 (0 public + 6 private):**


  <details><summary>private 関数 6 件</summary>

  - L12 `_travelBandMin()`
  - L33 `_atUtcMsForSelectedHour()`
  - L135 `_onStartPressed()`
  - L147 `_handleBuyFromPopup()`
  - L154 `_showStartPopup()`
  - L174 `_runConsultation()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/consultation/consultation_input_picker.dart` (345 行)

**ファイル先頭コメント:**

```
Consultation Input Screen — 具体地点ピッカー部品
(part of 'consultation_input_screen.dart')

scope='specific' 専用の inline 地点ピッカー (A) を提供する。
検索 + LOCATION quick-pick + 「地図で選ぶ」(B) を 1 ユニットに集約。
元 consultation_input_widgets.dart から L11-23 (_PickedSpecific) と
L836-1295 (_SpecificPicker 系) を切り出し (ファイル肥大化対策、2026-05-16)。
```

**型定義 (3):**

- L12 `class _PickedSpecific`
  - _SpecificPicker からの選択結果を持ち回す軽量レコード。
- L34 `class _SpecificPicker : StatefulWidget`
  - inline 地点ピッカー (A)。検索 + LOCATION quick-pick + 「地図で選ぶ」(B) を集約。
- L57 `class _SpecificPickerState : State`

**関数 (4 public + 6 private):**

- L54 `createState()`
- L73 `initState()`
- L79 `dispose()`
- L161 `build()`

  <details><summary>private 関数 6 件</summary>

  - L85 `_loadSlots()`
  - L96 `_onSearchChanged()`
  - L109 `_runSearch()`
  - L123 `_onHitTap()`
  - L138 `_onSlotTap()`
  - L153 `_openMapPicker()`

  </details>


### `lib/screens/consultation/consultation_input_picker_widgets.dart` (203 行)

**ファイル先頭コメント:**

```
Consultation Input Screen — 具体地点ピッカーの presentational 部品
(part of 'consultation_input_screen.dart')

consultation_input_picker.dart の HARD500 回避のため、検索結果行・保存地点チップ・
選択中カードの 3 widget を切り出し (2026-05-25)。ロジックは持たず描画のみ。
```

**型定義 (3):**

- L10 `class _SearchHitRow : StatelessWidget`
  - 検索結果 1 行 (番号バッジ + 場所名 + 住所サブ行)。
- L99 `class _LocationChip : StatelessWidget`
  - 保存地点 (ViewPoint / Locations) のチップ。アイコン + 登録名。
- L136 `class _SelectedSpecificCard : StatelessWidget`
  - 選択中の具体地点カード (場所名 + 住所 + 解除ボタン)。

**関数 (3 public + 0 private):**

- L18 `build()`
- L105 `build()`
- L150 `build()`


### `lib/screens/consultation/consultation_input_screen.dart` (620 行)

**ファイル先頭コメント:**

```
Consultation Input Screen — 5問モデル (V2: 全要素統合)

設計: project_solara_consultation_full_integration.md

設問順: ② 場面 → ③ いつ → ④ どこで → ① テーマ → ⑤ だれと → ⑥ 願い
  - ② 場面 (必須): おでかけ / 旅行 / 移住 — ③④をプリセット
  - ③ いつ (場面別): おでかけ=今日/日付 ・旅行=特定日/期間 ・移住=未定/日付/ホライズン
  - ④ どこで (場面別): おでかけ=具体地点/方角/半径 ・旅行移住=具体地点/地域/自国内/半径/世界
  - ① テーマ (必須)
  - ⑤ だれと (任意・自由記述・Stella レンズ)
  - ⑥ どうなりたい/願い (任意だが核・自由記述・Stella レンズ)

最小入力 (誕生+自宅+5問+preset) を ConsultationRequest にまとめ、結果画面が
/protected/astro/consultation2 を叩く。client 候補生成は廃止 (Worker が全計算)。

ファイル分割 (part-of パターン):
  consultation_input_screen.dart      ← 本ファイル: orchestration + state
  consultation_input_widgets.dart     ← 基本ウィジェット + 選択肢定数
  consultation_input_when_scope.dart  ← いつ / 半径 セレクタ
  consultation_input_examples.dart    ← だれと / 願い の記入例
  consultation_input_picker.dart      ← 具体地点ピッカー (_SpecificPicker)
  consultation_start_popup.dart       ← 開始ポップアップ (Free 残数)
```

**imports:** dart=1 / package=3 / relative=14

- relative: `../../theme/solara_colors.dart`, `../../utils/consult_restore.dart`, `../../utils/consultation_credits.dart`, `../../utils/consultation_v2_api.dart`, `../../utils/pro_status.dart`, `../../utils/solara_storage.dart`, `../../widgets/info_popup.dart`, `../../widgets/pro_unlock_dialog.dart`, `../../widgets/tap_to_unfocus.dart`, `../map/map_search.dart`, `../map/map_vp_panel.dart`, `consultation_credit_sheet.dart`, `consultation_place_picker_screen.dart`, `consultation_result_screen.dart`

**型定義 (3):**

- L54 `class ConsultationPresetTarget`
  - Map から「📍この場所で相談」で起動した時の preset (point scope 用)。
- L79 `class ConsultationInputScreen : StatefulWidget`
- L102 `class _ConsultationInputScreenState : State`

**関数 (4 public + 12 private):**

- L98 `createState()`
- L141 `initState()`
- L248 `dispose()`
- L422 `build()`

  <details><summary>private 関数 12 件</summary>

  - L207 `_applyRestoreForm()`
  - L236 `_loadPrefsAndProfile()`
  - L256 `_onModeChanged()`
  - L286 `_onWhenKindTap()`
  - L313 `_pickHour()`
  - L322 `_pickSingleDate()`
  - L334 `_pickDateRange()`
  - L346 `_ymd()`
  - L350 `_onScopeKindTap()`
  - L360 `_openMapPicker()`
  - L410 `_refreshCreditsFresh()`
  - L415 `_setStartPopupHidden()`

  </details>


### `lib/screens/consultation/consultation_input_when_scope.dart` (359 行)

**ファイル先頭コメント:**

```
Consultation Input — ③ いつ / 半径 セレクタ
(part of 'consultation_input_screen.dart')
```

**型定義 (7):**

- L6 `class _WhenChoice`
- L43 `class _WhenSelector : StatelessWidget`
  - ③ いつ。場面別の選択肢を Wrap で出し、date/range は選んだ日付を下に表示する。
- L104 `class _TimeBandSelector : StatelessWidget`
- L147 `class _HourDrumSheet : StatefulWidget`
- L154 `class _HourDrumSheetState : State`
- L235 `class _TimeHourRow : StatelessWidget`
  - Pro 時刻指定の行。未選択=「時刻を指定（1時間刻み）」/ 選択中=「15:00 を指定中」+×。
- L328 `class _RadiusChips : StatelessWidget`
  - 自宅から半径の距離選択 (場面別 km 候補)。

**関数 (9 public + 2 private):**

- L56 `build()`
- L110 `build()`
- L126 `bandFromHour()` — 時刻 (0〜23) → 現地太陽時バケット。worker consultation_engine.timeOfDayBucket と一致。
- L136 `showConsultationHourPicker()` — Pro 時刻ドラム (1 時間刻み)。0〜23 時のホイールを bottom sheet で出し、決定で hour を返す。
- L151 `createState()`
- L160 `dispose()`
- L166 `build()`
- L250 `build()`
- L346 `build()`

  <details><summary>private 関数 2 件</summary>

  - L31 `_whenChoicesFor()`
  - L340 `_label()`

  </details>


### `lib/screens/consultation/consultation_input_widgets.dart` (430 行)

**ファイル先頭コメント:**

```
Consultation Input — 基本サブウィジェット + 選択肢定数
(part of 'consultation_input_screen.dart')
```

**型定義 (13):**

- L60 `class _ThemeChoice`
- L66 `class _ModeChoice`
- L72 `class _ScopeChoice`
- L81 `class _PillChip : StatelessWidget`
  - 単一選択の pill チップ (Wrap 用)。
- L121 `class _Section : StatelessWidget`
- L149 `class _ThemeGrid : StatelessWidget`
- L170 `class _ModeRow : StatelessWidget`
- L225 `class _ScopeWrap : StatelessWidget`
  - ④ どこで のスコープ選択 (Wrap、場面で 3〜5 個)。
- L251 `class _RegionPicker : StatelessWidget`
- L272 `class _FreeTextField : StatelessWidget`
- L328 `class _NoHomeNote : StatelessWidget`
  - 自宅未設定で 方角/半径/自国内 が使えないときの注記。
- L355 `class _PresetLocationCard : StatelessWidget`
- L392 `class _SubmitBar : StatelessWidget`

**関数 (10 public + 1 private):**

- L92 `build()`
- L127 `build()`
- L155 `build()`
- L176 `build()`
- L236 `build()`
- L257 `build()`
- L285 `build()`
- L332 `build()`
- L360 `build()`
- L398 `build()`

  <details><summary>private 関数 1 件</summary>

  - L45 `_scopeChoicesFor()`

  </details>


### `lib/screens/consultation/consultation_place_picker_screen.dart` (354 行)

**ファイル先頭コメント:**

```
Consultation Place Picker Screen — Stage 1 「地図で選ぶ」 (Hybrid B)

設計: apps/solara/docs/pro_candidates.md §7.2 Stage 1
       + chat 議論 (2026-05-16) 「A + B ハイブリッド」案

役割:
  - Consultation Input 画面の inline picker (A) から「🗺 地図で選ぶ」で push
  - flutter_map で全画面の地図を表示し、検索 / マップタップで地点選択
  - 決定で ConsultationPresetTarget を返す (Navigator.pop の引数)
  - キャンセル / 戻る で null を返す

map_screen との関係:
  - map_screen.dart (~2700 行) は触らない (独立画面)
  - flutter_map package を直接使い、Solara の地図テーマ (osmHotDark) と
    共通の TileLayer ビルダ (buildStyledTileLayer) のみ流用
  - 検索は map_search.dart の searchPlaces / SearchHit を流用
  - 逆ジオコーディングは reverse_geocode.dart の reverseGeocodeDetail を使う

UI 構造:
  ┌─ AppBar (戻る / タイトル) ────────────────────┐
  │  [検索 ____________________]  ✕              │
  │  [候補1] [候補2] [候補3]                      │  ← suggestions overlay
  ├──────────────────────────────────────────────┤
  │                                              │
  │     flutter_map (全画面、osmHotDark)         │
  │       タップで点選択 → ピン                   │
  │       検索結果は番号付きピン                  │
  │                                              │
  ├──────────────────────────────────────────────┤
  │  ✓ 京都 (京都府 / JP)                        │  ← 選択中カード
  │  35.011°N, 135.768°E                         │
  │  [ キャンセル ]   [ ✓ この地点で相談 ]       │
  └──────────────────────────────────────────────┘
```

**imports:** dart=1 / package=3 / relative=6

- relative: `../../theme/solara_colors.dart`, `../../utils/reverse_geocode.dart`, `../../widgets/tap_to_unfocus.dart`, `../map/map_search.dart`, `../map/map_styles.dart`, `consultation_input_screen.dart`

**型定義 (1):**

- L53 `class ConsultationPlacePickerScreen : StatefulWidget`
  - 地点選択画面 (B、フルスクリーン)。

**関数 (3 public + 8 private):**

- L67 `createState()`
- L98 `dispose()`
- L232 `build()`

  <details><summary>private 関数 8 件</summary>

  - L107 `_onSearchChanged()`
  - L120 `_runSearch()`
  - L143 `_onHitTap()`
  - L157 `_shortName()`
  - L167 `_selectPoint()`
  - L199 `_onMapTap()`
  - L204 `_clearSelection()`
  - L215 `_confirm()`

  </details>


### `lib/screens/consultation/consultation_place_picker_widgets.dart` (411 行)

**ファイル先頭コメント:**

```
Consultation Place Picker — サブウィジェット
(part of 'consultation_place_picker_screen.dart')

flutter_map ベースの地点選択画面のサブウィジェット群:
  - _SearchBar: 検索ボックス + サジェスト一覧 (番号バッジ付き)
  - _NumberedPin: 検索結果の地図上ピン
  - _SelectionCard: 画面下の選択中カード ＋ キャンセル / 確定ボタン

親 consultation_place_picker_screen.dart は orchestration + State + map 配置のみ
担う (ファイル肥大化対策、2026-05-16 分割)。
```

**型定義 (3):**

- L14 `class _SearchBar : StatelessWidget`
- L196 `class _NumberedPin : StatelessWidget`
- L221 `class _SelectionCard : StatelessWidget`

**関数 (3 public + 1 private):**

- L32 `build()`
- L201 `build()`
- L264 `build()`

  <details><summary>private 関数 1 件</summary>

  - L247 `_coordLabel()`

  </details>


### `lib/screens/consultation/consultation_result_card.dart` (553 行)

**ファイル先頭コメント:**

```
Consultation Result — 候補カード (V2)
(part of 'consultation_result_screen.dart')
```

**型定義 (8):**

- L6 `class _CandidateCard : StatelessWidget`
- L195 `class _EnergyChip : StatelessWidget`
- L221 `class _MapLinkIcon : StatelessWidget`
  - 場所名の右の🗺リンク。Map 画面で候補地を (相談の日付で) 見る。
- L251 `class _TimeWindowRow : StatelessWidget`
  - 時間帯 (現地の時間帯のみ・時計表示なし)。single=1 個 / rhythm=朝昼夜。
- L294 `class _DeltaAfterSection : StatefulWidget`
  - 候補カードの「30分経過後を見る」セクション。タップで開閉、i ボタンで説明。
- L302 `class _DeltaAfterSectionState : State`
- L445 `class _DeltaChip : StatelessWidget`
  - 30 分後の 1 変化チップ (例: 「火星 MC ↘ 離れる」)。
- L483 `class _CandidateKindBadge : StatelessWidget`
  - 候補種別バッジ (方角 / 場所)。

**関数 (8 public + 1 private):**

- L37 `build()`
- L200 `build()`
- L226 `build()`
- L256 `build()`
- L299 `createState()`
- L342 `build()`
- L450 `build()`
- L492 `build()`

  <details><summary>private 関数 1 件</summary>

  - L305 `_showInfo()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/consultation/consultation_result_credit_widgets.dart` (153 行)

**ファイル先頭コメント:**

```
Consultation Result — クレジット関連サブウィジェット (part of consultation_result_screen.dart)

Stella 相談 クレジット制 (設計 project_solara_stella_free_credits.md) の結果画面向け
表示部品を分離: 402 ブロックボックス + 残量バナー。
本体 (consultation_result_widgets.dart) が 500 行 (HARD) を超えたため切り出した。
```

**型定義 (1):**

- L11 `class _ConsultationBlockedBox : StatelessWidget`
  - Free 試食ゲートで 402 ブロックされた時のペイウォール誘導ボックス。

**関数 (1 public + 0 private):**

- L22 `build()`


### `lib/screens/consultation/consultation_result_screen.dart` (518 行)

**ファイル先頭コメント:**

```
Consultation Result Screen — V2 (全要素統合)

設計: project_solara_consultation_full_integration.md

レイアウト:
  - AppBar (戻る / タイトル「相談の結果 ⌄」=この読み解きについて / share)
  - 内的季節バナー (初回・常設)
  - PageView × 蓄積候補 (横スワイプ)。候補カード: 特徴見出し + 時間帯 +
    energyLabels + narrative
  - 「別の候補地を見る」(excluded を足して次候補を 1 つ取得・1 クレジット消費)

1 クレジット = 1 候補。最初の取得で見出し候補、「別の候補地」で 1 枚ずつ最大 5 枚。
Pro = 無制限。live モード = ConsultationRequest で fetch / 履歴モード =
ConsultationRecord を読み込み専用表示 (fetch なし・autosave なし・別候補なし)。
```

**imports:** dart=0 / package=3 / relative=16

- relative: `../../theme/solara_colors.dart`, `../../utils/consultation_api.dart`, `../../utils/consultation_credits.dart`, `../../utils/consult_restore.dart`, `../../utils/map_focus.dart`, `../../utils/consultation_record.dart`, `../../utils/consultation_share.dart`, `../../utils/consultation_v2_api.dart`, `../../utils/pro_status.dart`, `../../utils/solara_storage.dart`, `../../widgets/ai_disclaimer_footer.dart`, `../../widgets/ai_report_button.dart`, `../../widgets/glass_panel.dart`, `../../widgets/info_popup.dart`, `../../widgets/pro_unlock_dialog.dart`, `consultation_credit_sheet.dart`

**型定義 (2):**

- L45 `class ConsultationResultScreen : StatefulWidget`
- L80 `class _ConsultationResultScreenState : State`

**関数 (4 public + 12 private):**

- L76 `createState()`
- L145 `initState()`
- L160 `dispose()`
- L401 `build()`

  <details><summary>private 関数 12 件</summary>

  - L116 `_pushShownToAvoid()`
  - L136 `_setSharing()`
  - L182 `_runFetch()`
  - L187 `_fetch()`
  - L237 `_loadNext()`
  - L303 `_snack()`
  - L315 `_onBuyCredits()`
  - L321 `_showConsultationPaywall()`
  - L342 `_showAboutReading()`
  - L357 `_persist()`
  - L385 `_openCandidateOnMap()`
  - L466 `_buildBody()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/consultation/consultation_result_share.dart` (127 行)

**ファイル先頭コメント:**

```
Consultation Result — シェア機能 (part of consultation_result_screen.dart)

シェアエクスポート (テキスト / 画像) を本体から分離。Pro 限定。
```

**型定義 (1):**

- L7 `extension _ConsultationResultShare : _ConsultationResultScreenState`

**関数 (0 public + 3 private):**


  <details><summary>private 関数 3 件</summary>

  - L21 `_openShareSheet()`
  - L83 `_copyText()`
  - L107 `_shareImage()`

  </details>


### `lib/screens/consultation/consultation_result_widgets.dart` (427 行)

**ファイル先頭コメント:**

```
Consultation Result — 状態/バナー/ページャ ウィジェット (V2)
(part of 'consultation_result_screen.dart')
```

**型定義 (9):**

- L7 `enum _ShareChoice`
  - シェアシートで選ばれた選択肢。
- L11 `class _LoadingSkeleton : StatelessWidget`
- L39 `class _ErrorBox : StatelessWidget`
- L85 `class _FallbackChip : StatelessWidget`
  - 静的フォールバック時の注意チップ (Stella 応答が届かず静的表示になったことを示す)。
- L119 `class _AboutReadingContent : StatelessWidget`
  - AppBar タイトルタップで開く「この読み解きについて」ポップアップの中身。
- L234 `class _PageIndicator : StatelessWidget`
- L265 `class _SparseHint : StatelessWidget`
  - 近くの実在の町が乏しい (Phase B sparse) ときの控えめなヒント。
- L306 `class _ExhaustionPanel : StatelessWidget`
  - 候補を出し尽くした (案Y)。正直に止めた理由 + 条件変更の代替提案を出す。
- L390 `class _RefreshButton : StatelessWidget`
  - 「別の候補地を見る」(1 クレジット消費で次の distinct 候補を 1 つ取得)。

**関数 (8 public + 0 private):**

- L15 `build()`
- L45 `build()`
- L89 `build()`
- L132 `build()`
- L240 `build()`
- L270 `build()`
- L324 `build()`
- L396 `build()`


### `lib/screens/consultation/consultation_start_popup.dart` (292 行)

**ファイル先頭コメント:**

```
Consultation 開始確認ポップアップ (Free ユーザー向け)
(part of 'consultation_input_screen.dart')

「相談を始める」を押したとき、Free ユーザーに無料クレジットの残数・補充タイミング・
追加購入導線を案内するポップアップ。Pro はスキップ、「次回以降表示しない」で抑制可能。
showInfoPopup 経由で表示する (widgets/info_popup.dart、popup 統一規約に準拠)。
```

**型定義 (2):**

- L10 `class _StartConsultPopup : StatefulWidget`
- L34 `class _StartConsultPopupState : State`

**関数 (4 public + 1 private):**

- L31 `createState()`
- L38 `initState()`
- L45 `dispose()`
- L55 `build()`

  <details><summary>private 関数 1 件</summary>

  - L50 `_onCreditsChanged()`

  </details>


### `lib/screens/font_preview_screen.dart` (138 行)

**imports:** dart=0 / package=2 / relative=0

**型定義 (3):**

- L6 `class FontPreviewScreen : StatefulWidget`
  - フォント比較画面 — 候補フォント8種を Horo と同じコンテキストで並べて比較
- L12 `class _FontPreviewScreenState : State`
- L134 `class _FontOption`

**関数 (2 public + 1 private):**

- L9 `createState()`
- L32 `build()`

  <details><summary>private 関数 1 件</summary>

  - L48 `_buildSample()`

  </details>


### `lib/screens/forecast/forecast_life_periods.dart` (209 行)

**imports:** dart=0 / package=1 / relative=4

- relative: `../../utils/forecast_cache.dart`, `../../widgets/info_popup.dart`, `../map/map_constants.dart`, `forecast_section_header.dart`

**型定義 (1):**

- L29 `class ForecastLifePeriodsSection : StatelessWidget`
  - 「◯◯期」セクション — 永続保存された運勢サイクルを表示

**関数 (1 public + 2 private):**

- L39 `build()`

  <details><summary>private 関数 2 件</summary>

  - L74 `_periodRow()`
  - L130 `_showLifePeriodsInfo()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/forecast/forecast_section_header.dart` (59 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (1):**

- L6 `class ForecastSectionHeader : StatelessWidget`
  - Forecast 画面のモダンなセクション見出し。

**関数 (1 public + 0 private):**

- L19 `build()`


### `lib/screens/forecast/forecast_top5.dart` (243 行)

**imports:** dart=0 / package=1 / relative=4

- relative: `../../utils/forecast_cache.dart`, `../../widgets/info_popup.dart`, `../map/map_constants.dart`, `forecast_section_header.dart`

**型定義 (1):**

- L9 `class ForecastTop5Section : StatelessWidget`
  - 強運Top5 セクション — 永続保存された Top5 を mode 別に表示

**関数 (1 public + 4 private):**

- L35 `build()`

  <details><summary>private 関数 4 件</summary>

  - L58 `_modeSelector()`
  - L76 `_seg()`
  - L101 `_row()`
  - L139 `_showTop5Info()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/forecast_screen.dart` (1084 行)

**imports:** dart=0 / package=1 / relative=10

- relative: `../utils/forecast_cache.dart`, `../utils/pro_status.dart`, `../utils/solara_storage.dart`, `../widgets/info_popup.dart`, `../widgets/no_profile_guide.dart`, `../widgets/pro_unlock_dialog.dart`, `forecast/forecast_life_periods.dart`, `forecast/forecast_section_header.dart`, `forecast/forecast_top5.dart`, `map/map_constants.dart`

**型定義 (3):**

- L16 `class ForecastScreen : StatefulWidget`
  - Forecast 画面 — 1年予測（ヒートマップ + 選択日詳細 + 強運Top5）
- L34 `class _ForecastScreenState : State`
- L1055 `class _DayStepperButton : StatelessWidget`
  - 選択日詳細パネルの △ ボタン (左右で 1 日前後に動かす)。

**関数 (4 public + 30 private):**

- L31 `createState()`
- L66 `initState()`
- L164 `build()`
- L1066 `build()`

  <details><summary>private 関数 30 件</summary>

  - L71 `_initialize()`
  - L77 `_loadSettings()`
  - L91 `_setColorMode()`
  - L96 `_setHighColor()`
  - L101 `_load()`
  - L144 `_setYearOffset()`
  - L215 `_buildBody()`
  - L270 `_buildBasisCard()`
  - L325 `_fmt()`
  - L328 `_buildBestChip()`
  - L362 `_yearSeg()`
  - L386 `_buildHeatmap()`
  - L451 `_buildColorModeToggle()`
  - L492 `_rankSeg()`
  - L522 `_segment()`
  - L543 `_buildLegend()`
  - L570 `_catColorChips()`
  - L584 `_monthRow()`
  - L613 `_dayCell()`
  - L644 `_cellColor()`
  - L661 `_gradientColor()`
  - L672 `_categoryColor()`
  - L688 `_canShiftSelectedDay()`
  - L699 `_shiftSelectedDay()`
  - L706 `_buildSelectedDayDetail()`
  - L769 `_metric()`
  - L777 `_catBar()`
  - L814 `_buildFetchInfo()`
  - L828 `_showForecastUsageGuide()`
  - L954 `_showHeatmapInfo()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showInfoPopup`×2


### `lib/screens/locations/locations_date_stepper.dart` (355 行)

**imports:** dart=0 / package=2 / relative=0

**型定義 (3):**

- L9 `class LocationsDateStepper : StatelessWidget`
  - Locations 画面の日付ステッパー（年▲▼ 月▲▼ 日▲▼ + 「今日」リセット）。
- L261 `class _DateNumberField : StatefulWidget`
  - 数値を直接タイプして編集できるフィールド（年/月/日 共通）。
- L278 `class _DateNumberFieldState : State`

**関数 (6 public + 7 private):**

- L53 `build()`
- L275 `createState()`
- L283 `initState()`
- L291 `didUpdateWidget()`
- L315 `dispose()`
- L323 `build()`

  <details><summary>private 関数 7 件</summary>

  - L133 `_hourStepperBlock()`
  - L160 `_editHour()`
  - L196 `_pickerBlock()`
  - L227 `_dayArrowBlock()`
  - L242 `_arrowBtn()`
  - L299 `_onFocusChange()`
  - L303 `_commit()`

  </details>


### `lib/screens/locations_screen.dart` (759 行)

**imports:** dart=1 / package=2 / relative=9

- relative: `../utils/solara_storage.dart`, `../widgets/info_popup.dart`, `../widgets/no_profile_guide.dart`, `../widgets/tap_to_unfocus.dart`, `locations/locations_date_stepper.dart`, `map/map_astro.dart`, `map/map_constants.dart`, `map/map_search.dart`, `map/map_vp_panel.dart`

**型定義 (3):**

- L16 `class LocationsScreen : StatefulWidget`
  - Locations 一覧画面 — 登録済み拠点を16方位スコア付きで管理。
- L39 `class _LocationsScreenState : State`
- L646 `class _SlotStats`

**関数 (3 public + 18 private):**

- L36 `createState()`
- L67 `initState()`
- L285 `build()`

  <details><summary>private 関数 18 件</summary>

  - L72 `_load()`
  - L132 `_shiftDate()`
  - L152 `_setYmd()`
  - L171 `_setHour()`
  - L179 `_shiftHour()`
  - L186 `_resetToday()`
  - L196 `_setDate()`
  - L229 `_addCurrent()`
  - L241 `_delete()`
  - L246 `_rename()`
  - L359 `_buildRefPointSelector()`
  - L439 `_buildCategorySelector()`
  - L483 `_emptyState()`
  - L508 `_buildList()`
  - L517 `_buildRow()`
  - L604 `_scoreBar()`
  - L640 `_fmtKm()`
  - L656 `_showLocationsUsageGuide()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/paywall_comparison.dart` (311 行)

**ファイル先頭コメント:**

```
Paywall Screen — Free vs Pro 比較テーブル / FAQ アコーディオン
(part of 'paywall_screen.dart')

役割:
  - Suno 風レイアウトの下半分
  - 比較テーブル: カテゴリ別 (相談・占い / 機能 / 計算) で Free vs Pro を行ごとに ✓ × / 値
  - FAQ: 5 問のアコーディオン (memory project_solara_paywall_suno_redesign ドラフトに準拠)

行数管理:
  - paywall_widgets.dart が大きくなりすぎないようここに分離。
  - HARD 上限 600 行を意識し、本ファイル単体は 300 行未満を維持。
```

**型定義 (1):**

- L15 `extension _PaywallComparison : _PaywallScreenState`

**関数 (0 public + 6 private):**


  <details><summary>private 関数 6 件</summary>

  - L16 `_buildComparisonTable()`
  - L71 `_comparisonHeader()`
  - L119 `_comparisonSection()`
  - L147 `_comparisonRow()`
  - L194 `_buildFaqSection()`
  - L265 `_faqItem()`

  </details>


### `lib/screens/paywall_legal_links.dart` (197 行)

**ファイル先頭コメント:**

```
Paywall Screen — 法務必須項目 + 補助ウィジェット + 期間ラベル変換
(part of 'paywall_screen.dart')

法務必須 (B5 公開ブロッカー、🛡 文言・リンク先を絶対に変更しない):
  - _buildAutoRenewNotice : Apple 3.1.2(a) 必須開示 3 項目 + 3.1.1 禁止文言回避
  - _buildLegalLinks      : 解約方法 / 利用規約 / プライバシー / 特商法
  - _buildRestoreButton   : 購入を復元

補助ウィジェット / ユーティリティ (paywall_widgets.dart の行数 HARD 回避で集約):
  - _buildStoreUnavailable  : Offerings 未配信時バナー
  - _buildErrorPanel        : 購入エラー表示
  - _periodLabel            : PackageType → 日本語期間ラベル
  - _introPeriodLabel       : IntroductoryPrice → 日本語期間ラベル
```

**型定義 (1):**

- L17 `extension _PaywallLegalLinks : _PaywallScreenState`

**関数 (0 public + 8 private):**


  <details><summary>private 関数 8 件</summary>

  - L18 `_buildStoreUnavailable()`
  - L62 `_buildErrorPanel()`
  - L91 `_periodLabel()`
  - L112 `_introPeriodLabel()`
  - L128 `_buildAutoRenewNotice()`
  - L145 `_buildLegalLinks()`
  - L161 `_legalLink()`
  - L176 `_buildRestoreButton()`

  </details>


### `lib/screens/paywall_screen.dart` (313 行)

**ファイル先頭コメント:**

```
Solara ペイウォール画面 — Phase 2-6b + Suno 風リデザイン (2026-05-28)

設計:
  - launch_checklist Phase 2「ペイウォール UI 🚨 公開ブロッカー B5 (3.1.2 全項目 + 特商法 5 項目必須)」
  - project_solara_security_principles 原則 4「公開前必須の法務 3 点セット」
  - feedback_i18n_last: 当面 ja-JP のみ。EN 版はストアアップ前最終工程
  - project_solara_paywall_suno_redesign: Suno 風 UI (Monthly/Annual トグル / Free・Pro 2 カード / 比較テーブル / FAQ)

必須項目 (B5、削除厳禁):
  ✦ サブスクタイトル ✦ 期間 (月額/年額) ✦ 価格 (税込) ✦ コンテンツ概要
  ✦ 自動更新明記 ✦ 解約方法リンク ✦ EULA ✦ プライバシーポリシー
  ✦ Free Trial 明記 ✦ 購入を復元

振舞:
  - Offerings 取得成功 → Free / Pro 2 カード、Pro 側に CTA、タップで購入
  - Offerings 取得失敗 (API キー未設定 / 未配信 / オフライン) → 「ストア準備中」案内
  - 購入完了 → entitlement listener が ProStatus 更新 → pop で前画面に戻る
```

**imports:** dart=1 / package=4 / relative=5

- relative: `../theme/solara_colors.dart`, `../utils/legal_urls.dart`, `../utils/pro_status.dart`, `../utils/purchases_service.dart`, `../utils/solara_auth.dart`

**型定義 (3):**

- L37 `enum BillingCycle`
  - 課金サイクル選択トグル用。デフォルトは Annual (SAVE 50% 訴求)。
- L39 `class PaywallScreen : StatefulWidget`
- L46 `class _PaywallScreenState : State`

**関数 (4 public + 9 private):**

- L43 `createState()`
- L64 `initState()`
- L71 `dispose()`
- L259 `build()`

  <details><summary>private 関数 9 件</summary>

  - L58 `_setBilling()`
  - L76 `_onProStatusChanged()`
  - L83 `_loadOfferings()`
  - L102 `_ensureSignedInForPro()`
  - L164 `_purchase()`
  - L199 `_restore()`
  - L226 `_showSnack()`
  - L236 `_openUrl()`
  - L244 `_openCancelGuide()`

  </details>


### `lib/screens/paywall_widgets.dart` (424 行)

**ファイル先頭コメント:**

```
Paywall Screen — Hero / 課金トグル / Free・Pro 2 カード (Suno 風 core)
(part of 'paywall_screen.dart')
比較テーブル + FAQ → paywall_comparison.dart
法務必須項目 (B5) + 補助 (ストア準備中 / エラーパネル / 期間ラベル) → paywall_legal_links.dart
```

**型定義 (1):**

- L8 `extension _PaywallWidgets : _PaywallScreenState`

**関数 (0 public + 9 private):**


  <details><summary>private 関数 9 件</summary>

  - L9 `_buildHero()`
  - L44 `_buildPlansSection()`
  - L78 `_buildBillingToggle()`
  - L97 `_toggleSegment()`
  - L160 `_buildFreeCard()`
  - L208 `_buildProCard()`
  - L315 `_buildProCta()`
  - L371 `_cardBadge()`
  - L395 `_planBullet()`

  </details>


### `lib/screens/solara_philosophy_screen.dart` (159 行)

**ファイル先頭コメント:**

```
============================================================
Solara Philosophy Screen — 設計思想ガイド（章0）

E5: 流派ガイドページの最初の章として、Solaraの設計思想
（ソフト/ハード独立2エネルギー、占い的吉凶判定をしない、
  両面思想）をユーザーに伝える。

データソース: lib/utils/solara_manifesto.dart
設計根拠: project_solara_design_philosophy.md
============================================================
```

**imports:** dart=0 / package=1 / relative=3

- relative: `../theme/solara_colors.dart`, `../utils/solara_manifesto.dart`, `../widgets/glass_panel.dart`

**型定義 (4):**

- L17 `class SolaraPhilosophyScreen : StatelessWidget`
- L61 `class _Hero : StatelessWidget`
- L102 `class _SectionCard : StatelessWidget`
- L143 `class _Footer : StatelessWidget`

**関数 (4 public + 0 private):**

- L21 `build()`
- L65 `build()`
- L107 `build()`
- L147 `build()`

