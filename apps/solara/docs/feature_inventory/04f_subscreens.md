# 層 4f: サブ画面 (Forecast / Locations / Philosophy / Font Preview)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 25 / 総行数: 8555
- class/mixin/extension/enum: 82
- 関数 (top-level + method の素拾い): 230
- Navigator.push 等: 0
- Popup/Dialog 呼出: 7
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/consultation/consultation_credit_sheet.dart` (325 行)

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

**imports:** dart=1 / package=3 / relative=5

- relative: `../../theme/solara_colors.dart`, `../../utils/consultation_api.dart`, `../../utils/purchases_service.dart`, `../../utils/solara_auth.dart`, `../paywall_screen.dart`

**型定義 (2):**

- L40 `class _CreditSheet : StatefulWidget`
- L47 `class _CreditSheetState : State`

**関数 (4 public + 7 private):**

- L27 `showConsultationCreditSheet()` — クレジット購入シートを開く。
- L44 `createState()`
- L55 `initState()`
- L181 `build()`

  <details><summary>private 関数 7 件</summary>

  - L60 `_load()`
  - L72 `_ensureSignedIn()`
  - L123 `_buy()`
  - L158 `_pollUntilGranted()`
  - L170 `_openPaywall()`
  - L252 `_buildContent()`
  - L276 `_packageTile()`

  </details>


### `lib/screens/consultation/consultation_history_screen.dart` (519 行)

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

**imports:** dart=0 / package=1 / relative=5

- relative: `../../theme/solara_colors.dart`, `../../utils/consultation_record.dart`, `../../utils/solara_storage.dart`, `../../widgets/glass_panel.dart`, `consultation_result_screen.dart`

**型定義 (5):**

- L47 `class ConsultationHistoryScreen : StatefulWidget`
- L65 `class _ConsultationHistoryScreenState : State`
- L200 `class _EmptyState : StatelessWidget`
- L245 `class _HistoryCard : StatelessWidget`
- L496 `class _MetaChip : StatelessWidget`

**関数 (6 public + 5 private):**

- L61 `createState()`
- L70 `initState()`
- L137 `build()`
- L204 `build()`
- L343 `build()`
- L501 `build()`

  <details><summary>private 関数 5 件</summary>

  - L75 `_load()`
  - L87 `_delete()`
  - L96 `_confirmDeleteAll()`
  - L189 `_openDetail()`
  - L467 `_confirmDelete()`

  </details>


### `lib/screens/consultation/consultation_input_examples.dart` (111 行)

**ファイル先頭コメント:**

```
Consultation Input — だれと / 願い の記入例
(part of 'consultation_input_screen.dart')

自由記述 (⑤ だれと / ⑥ 願い) はタップで埋まる記入例を添えて誘導する。
願いは場面 (おでかけ/旅行/移住) で軽重を変える。
```

**型定義 (3):**

- L55 `class _ExampleChips : StatelessWidget`
  - タップで自由記述を埋める記入例チップ群。
- L94 `class _WhomExamples : StatelessWidget`
- L103 `class _WishExamples : StatelessWidget`

**関数 (3 public + 1 private):**

- L61 `build()`
- L99 `build()`
- L109 `build()`

  <details><summary>private 関数 1 件</summary>

  - L41 `_wishExamplesFor()`

  </details>


### `lib/screens/consultation/consultation_input_logic.dart` (126 行)

**ファイル先頭コメント:**

```
Consultation Input — リクエスト組み立て + 開始フロー (extension)
(part of 'consultation_input_screen.dart')

State 本体 (consultation_input_screen.dart) の HARD500 回避のため、
setState を呼ばない純ロジック (when/scope → ConsultationRequest、開始ポップアップ、
結果画面遷移) を extension に分離。
```

**型定義 (1):**

- L10 `extension _ConsultationInputLogic : _ConsultationInputScreenState`

**関数 (0 public + 3 private):**


  <details><summary>private 関数 3 件</summary>

  - L77 `_onStartPressed()`
  - L86 `_showStartPopup()`
  - L101 `_runConsultation()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/consultation/consultation_input_picker.dart` (484 行)

**ファイル先頭コメント:**

```
Consultation Input Screen — 具体地点ピッカー部品
(part of 'consultation_input_screen.dart')

scope='specific' 専用の inline 地点ピッカー (A) を提供する。
検索 + LOCATION quick-pick + 「地図で選ぶ」(B) を 1 ユニットに集約。
元 consultation_input_widgets.dart から L11-23 (_PickedSpecific) と
L836-1295 (_SpecificPicker 系) を切り出し (ファイル肥大化対策、2026-05-16)。
```

**型定義 (6):**

- L12 `class _PickedSpecific`
  - _SpecificPicker からの選択結果を持ち回す軽量レコード。
- L29 `class _SpecificPicker : StatefulWidget`
  - inline 地点ピッカー (A)。検索 + LOCATION quick-pick + 「地図で選ぶ」(B) を集約。
- L52 `class _SpecificPickerState : State`
- L298 `class _SearchHitRow : StatelessWidget`
- L382 `class _LocationChip : StatelessWidget`
- L417 `class _SelectedSpecificCard : StatelessWidget`

**関数 (7 public + 6 private):**

- L49 `createState()`
- L65 `initState()`
- L71 `dispose()`
- L143 `build()`
- L306 `build()`
- L388 `build()`
- L431 `build()`

  <details><summary>private 関数 6 件</summary>

  - L77 `_loadSlots()`
  - L86 `_onSearchChanged()`
  - L99 `_runSearch()`
  - L113 `_onHitTap()`
  - L128 `_onSlotTap()`
  - L135 `_openMapPicker()`

  </details>


### `lib/screens/consultation/consultation_input_screen.dart` (468 行)

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

**imports:** dart=1 / package=3 / relative=12

- relative: `../../theme/solara_colors.dart`, `../../utils/consultation_api.dart`, `../../utils/consultation_v2_api.dart`, `../../utils/pro_status.dart`, `../../utils/solara_storage.dart`, `../../widgets/info_popup.dart`, `../../widgets/tap_to_unfocus.dart`, `../map/map_search.dart`, `../map/map_vp_panel.dart`, `consultation_credit_sheet.dart`, `consultation_place_picker_screen.dart`, `consultation_result_screen.dart`

**型定義 (3):**

- L52 `class ConsultationPresetTarget`
  - Map から「📍この場所で相談」で起動した時の preset (point scope 用)。
- L72 `class ConsultationInputScreen : StatefulWidget`
- L90 `class _ConsultationInputScreenState : State`

**関数 (4 public + 10 private):**

- L86 `createState()`
- L127 `initState()`
- L153 `dispose()`
- L314 `build()`

  <details><summary>private 関数 10 件</summary>

  - L136 `_loadPrefsAndProfile()`
  - L160 `_onModeChanged()`
  - L188 `_onWhenKindTap()`
  - L213 `_pickSingleDate()`
  - L225 `_pickDateRange()`
  - L237 `_ymd()`
  - L241 `_onScopeKindTap()`
  - L251 `_openMapPicker()`
  - L297 `_handleBuyFromPopup()`
  - L307 `_setStartPopupHidden()`

  </details>


### `lib/screens/consultation/consultation_input_when_scope.dart` (119 行)

**ファイル先頭コメント:**

```
Consultation Input — ③ いつ / 半径 セレクタ
(part of 'consultation_input_screen.dart')
```

**型定義 (3):**

- L6 `class _WhenChoice`
- L43 `class _WhenSelector : StatelessWidget`
  - ③ いつ。場面別の選択肢を Wrap で出し、date/range は選んだ日付を下に表示する。
- L95 `class _RadiusChips : StatelessWidget`
  - 自宅から半径の距離選択 (場面別 km 候補)。

**関数 (2 public + 1 private):**

- L56 `build()`
- L106 `build()`

  <details><summary>private 関数 1 件</summary>

  - L31 `_whenChoicesFor()`

  </details>


### `lib/screens/consultation/consultation_input_widgets.dart` (435 行)

**ファイル先頭コメント:**

```
Consultation Input — 基本サブウィジェット + 選択肢定数
(part of 'consultation_input_screen.dart')
```

**型定義 (13):**

- L55 `class _ThemeChoice`
- L61 `class _ModeChoice`
- L68 `class _ScopeChoice`
- L77 `class _PillChip : StatelessWidget`
  - 単一選択の pill チップ (Wrap 用)。
- L117 `class _Section : StatelessWidget`
- L145 `class _ThemeGrid : StatelessWidget`
- L166 `class _ModeRow : StatelessWidget`
- L231 `class _ScopeWrap : StatelessWidget`
  - ④ どこで のスコープ選択 (Wrap、場面で 3〜5 個)。
- L257 `class _RegionPicker : StatelessWidget`
- L278 `class _FreeTextField : StatelessWidget`
- L333 `class _NoHomeNote : StatelessWidget`
  - 自宅未設定で 方角/半径/自国内 が使えないときの注記。
- L360 `class _PresetLocationCard : StatelessWidget`
- L397 `class _SubmitBar : StatelessWidget`

**関数 (10 public + 1 private):**

- L88 `build()`
- L123 `build()`
- L151 `build()`
- L172 `build()`
- L242 `build()`
- L263 `build()`
- L291 `build()`
- L337 `build()`
- L365 `build()`
- L403 `build()`

  <details><summary>private 関数 1 件</summary>

  - L40 `_scopeChoicesFor()`

  </details>


### `lib/screens/consultation/consultation_place_picker_screen.dart` (353 行)

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


### `lib/screens/consultation/consultation_result_card.dart` (252 行)

**ファイル先頭コメント:**

```
Consultation Result — 候補カード (V2)
(part of 'consultation_result_screen.dart')
```

**型定義 (4):**

- L6 `class _CandidateCard : StatelessWidget`
- L125 `class _EnergyChip : StatelessWidget`
- L151 `class _TimeWindowRow : StatelessWidget`
  - 時間帯 (現地の時間帯のみ・時計表示なし)。single=1 個 / rhythm=朝昼夜。
- L182 `class _CandidateKindBadge : StatelessWidget`
  - 候補種別バッジ (方角 / 場所)。

**関数 (4 public + 0 private):**

- L21 `build()`
- L130 `build()`
- L156 `build()`
- L191 `build()`


### `lib/screens/consultation/consultation_result_credit_widgets.dart` (188 行)

**ファイル先頭コメント:**

```
Consultation Result — クレジット関連サブウィジェット (part of consultation_result_screen.dart)

Stella 相談 クレジット制 (設計 project_solara_stella_free_credits.md) の結果画面向け
表示部品を分離: 402 ブロックボックス + 残量バナー。
本体 (consultation_result_widgets.dart) が 500 行 (HARD) を超えたため切り出した。
```

**型定義 (2):**

- L11 `class _ConsultationBlockedBox : StatelessWidget`
  - Free 試食ゲートで 402 ブロックされた時のペイウォール誘導ボックス。
- L125 `class _FreeCreditsBanner : StatelessWidget`
  - Free ユーザー向け「今週あと N回 (+購入残高)」バナー (intro 直下)。

**関数 (2 public + 0 private):**

- L22 `build()`
- L138 `build()`


### `lib/screens/consultation/consultation_result_screen.dart` (414 行)

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

**imports:** dart=0 / package=2 / relative=11

- relative: `../../theme/solara_colors.dart`, `../../utils/consultation_api.dart`, `../../utils/consultation_record.dart`, `../../utils/consultation_share.dart`, `../../utils/consultation_v2_api.dart`, `../../utils/pro_status.dart`, `../../utils/solara_storage.dart`, `../../widgets/glass_panel.dart`, `../../widgets/info_popup.dart`, `../../widgets/pro_unlock_dialog.dart`, `consultation_credit_sheet.dart`

**型定義 (2):**

- L39 `class ConsultationResultScreen : StatefulWidget`
- L74 `class _ConsultationResultScreenState : State`

**関数 (4 public + 10 private):**

- L70 `createState()`
- L105 `initState()`
- L118 `dispose()`
- L300 `build()`

  <details><summary>private 関数 10 件</summary>

  - L99 `_setSharing()`
  - L123 `_runFetch()`
  - L128 `_fetch()`
  - L167 `_loadNext()`
  - L224 `_snack()`
  - L236 `_onBuyCredits()`
  - L242 `_showConsultationPaywall()`
  - L262 `_showAboutReading()`
  - L277 `_persist()`
  - L365 `_buildBody()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/consultation/consultation_result_share.dart` (135 行)

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
  - L91 `_copyText()`
  - L115 `_shareImage()`

  </details>


### `lib/screens/consultation/consultation_result_widgets.dart` (336 行)

**ファイル先頭コメント:**

```
Consultation Result — 状態/バナー/ページャ ウィジェット (V2)
(part of 'consultation_result_screen.dart')
```

**型定義 (8):**

- L7 `enum _ShareChoice`
  - シェアシートで選ばれた選択肢。
- L11 `class _LoadingSkeleton : StatelessWidget`
- L39 `class _ErrorBox : StatelessWidget`
- L85 `class _FallbackChip : StatelessWidget`
  - 静的フォールバック時の注意チップ (Stella 応答が届かず静的表示になったことを示す)。
- L114 `class _InnerSeasonBanner : StatelessWidget`
  - 内的季節の一文 (3 候補共通の前提・上部に常設)。
- L153 `class _AboutReadingContent : StatelessWidget`
  - AppBar タイトルタップで開く「この読み解きについて」ポップアップの中身。
- L268 `class _PageIndicator : StatelessWidget`
- L299 `class _RefreshButton : StatelessWidget`
  - 「別の候補地を見る」(1 クレジット消費で次の distinct 候補を 1 つ取得)。

**関数 (7 public + 0 private):**

- L15 `build()`
- L45 `build()`
- L89 `build()`
- L119 `build()`
- L166 `build()`
- L274 `build()`
- L305 `build()`


### `lib/screens/consultation/consultation_start_popup.dart` (194 行)

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
- L38 `class _StartConsultPopupState : State`

**関数 (2 public + 0 private):**

- L35 `createState()`
- L42 `build()`


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


### `lib/screens/forecast/forecast_life_periods.dart` (219 行)

**imports:** dart=0 / package=1 / relative=3

- relative: `../../utils/forecast_cache.dart`, `../../widgets/info_popup.dart`, `../map/map_constants.dart`

**型定義 (1):**

- L28 `class ForecastLifePeriodsSection : StatelessWidget`
  - 「◯◯期」セクション — 永続保存された運勢サイクルを表示

**関数 (1 public + 2 private):**

- L38 `build()`

  <details><summary>private 関数 2 件</summary>

  - L88 `_periodRow()`
  - L140 `_showLifePeriodsInfo()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/forecast/forecast_top5.dart` (238 行)

**imports:** dart=0 / package=1 / relative=3

- relative: `../../utils/forecast_cache.dart`, `../../widgets/info_popup.dart`, `../map/map_constants.dart`

**型定義 (1):**

- L8 `class ForecastTop5Section : StatelessWidget`
  - 強運Top5 セクション — 永続保存された Top5 を mode 別に表示

**関数 (1 public + 4 private):**

- L30 `build()`

  <details><summary>private 関数 4 件</summary>

  - L57 `_modeSelector()`
  - L75 `_seg()`
  - L100 `_row()`
  - L134 `_showTop5Info()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/forecast_screen.dart` (1067 行)

**imports:** dart=0 / package=1 / relative=9

- relative: `../utils/forecast_cache.dart`, `../utils/pro_status.dart`, `../utils/solara_storage.dart`, `../widgets/info_popup.dart`, `../widgets/no_profile_guide.dart`, `../widgets/pro_unlock_dialog.dart`, `forecast/forecast_life_periods.dart`, `forecast/forecast_top5.dart`, `map/map_constants.dart`

**型定義 (3):**

- L15 `class ForecastScreen : StatefulWidget`
  - Forecast 画面 — 1年予測（ヒートマップ + 選択日詳細 + 強運Top5）
- L33 `class _ForecastScreenState : State`
- L1038 `class _DayStepperButton : StatelessWidget`
  - 選択日詳細パネルの △ ボタン (左右で 1 日前後に動かす)。

**関数 (4 public + 30 private):**

- L30 `createState()`
- L65 `initState()`
- L150 `build()`
- L1049 `build()`

  <details><summary>private 関数 30 件</summary>

  - L70 `_initialize()`
  - L76 `_loadSettings()`
  - L90 `_setColorMode()`
  - L95 `_setHighColor()`
  - L100 `_load()`
  - L130 `_setYearOffset()`
  - L192 `_buildBody()`
  - L246 `_buildBasisCard()`
  - L297 `_fmt()`
  - L300 `_buildBestChip()`
  - L334 `_yearSeg()`
  - L358 `_buildHeatmap()`
  - L434 `_buildColorModeToggle()`
  - L475 `_rankSeg()`
  - L505 `_segment()`
  - L526 `_buildLegend()`
  - L553 `_catColorChips()`
  - L567 `_monthRow()`
  - L596 `_dayCell()`
  - L627 `_cellColor()`
  - L644 `_gradientColor()`
  - L655 `_categoryColor()`
  - L671 `_canShiftSelectedDay()`
  - L682 `_shiftSelectedDay()`
  - L689 `_buildSelectedDayDetail()`
  - L752 `_metric()`
  - L760 `_catBar()`
  - L797 `_buildFetchInfo()`
  - L811 `_showForecastUsageGuide()`
  - L937 `_showHeatmapInfo()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showInfoPopup`×2


### `lib/screens/locations/locations_date_stepper.dart` (391 行)

**imports:** dart=0 / package=2 / relative=0

**型定義 (5):**

- L9 `class LocationsDateStepper : StatelessWidget`
  - Locations 画面の日付ステッパー（年▲▼ 月▲▼ 日▲▼ + 「今日」リセット）。
- L206 `class _DateNumberField : StatefulWidget`
  - 数値を直接タイプして編集できるフィールド（年/月/日 共通）。
- L223 `class _DateNumberFieldState : State`
- L304 `class _HourNumberField : StatefulWidget`
  - 時 (hour) を直接タイプして編集できるフィールド。
- L314 `class _HourNumberFieldState : State`

**関数 (11 public + 7 private):**

- L53 `build()`
- L220 `createState()`
- L228 `initState()`
- L236 `didUpdateWidget()`
- L260 `dispose()`
- L268 `build()`
- L311 `createState()`
- L319 `initState()`
- L328 `didUpdateWidget()`
- L353 `dispose()`
- L361 `build()`

  <details><summary>private 関数 7 件</summary>

  - L129 `_hourStepperBlock()`
  - L159 `_stepperBlock()`
  - L189 `_stepBtn()`
  - L244 `_onFocusChange()`
  - L248 `_commit()`
  - L336 `_onFocusChange()`
  - L340 `_commit()`

  </details>


### `lib/screens/locations_screen.dart` (735 行)

**imports:** dart=1 / package=2 / relative=9

- relative: `../utils/solara_storage.dart`, `../widgets/info_popup.dart`, `../widgets/no_profile_guide.dart`, `../widgets/tap_to_unfocus.dart`, `locations/locations_date_stepper.dart`, `map/map_astro.dart`, `map/map_constants.dart`, `map/map_search.dart`, `map/map_vp_panel.dart`

**型定義 (3):**

- L16 `class LocationsScreen : StatefulWidget`
  - Locations 一覧画面 — 登録済み拠点を16方位スコア付きで管理。
- L39 `class _LocationsScreenState : State`
- L622 `class _SlotStats`

**関数 (3 public + 18 private):**

- L36 `createState()`
- L67 `initState()`
- L275 `build()`

  <details><summary>private 関数 18 件</summary>

  - L72 `_load()`
  - L132 `_shiftDate()`
  - L142 `_setYmd()`
  - L161 `_setHour()`
  - L169 `_shiftHour()`
  - L176 `_resetToday()`
  - L186 `_setDate()`
  - L219 `_addCurrent()`
  - L231 `_delete()`
  - L236 `_rename()`
  - L342 `_buildRefPointSelector()`
  - L422 `_buildCategorySelector()`
  - L466 `_emptyState()`
  - L491 `_buildList()`
  - L500 `_buildRow()`
  - L580 `_scoreBar()`
  - L616 `_fmtKm()`
  - L632 `_showLocationsUsageGuide()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/paywall_screen.dart` (295 行)

**ファイル先頭コメント:**

```
Solara ペイウォール画面 — Phase 2-6b

設計:
  - launch_checklist Phase 2「ペイウォール UI 🚨 公開ブロッカー B5 (3.1.2 全項目 + 特商法 5 項目必須)」
  - project_solara_security_principles 原則 4「公開前必須の法務 3 点セット」
  - feedback_i18n_last: 当面 ja-JP のみ。EN 版はストアアップ前最終工程

必須項目 (B5):
  ✦ サブスクタイトル ✦ 期間 (月額/年額) ✦ 価格 (税込) ✦ コンテンツ概要
  ✦ 自動更新明記 ✦ 解約方法リンク ✦ EULA ✦ プライバシーポリシー
  ✦ Free Trial 明記 ✦ 購入を復元

振舞:
  - Offerings 取得成功 → 月額 / 年額の 2 カード、タップで購入
  - Offerings 取得失敗 (API キー未設定 / 未配信 / オフライン) → 「ストア準備中」案内
  - 購入完了 → entitlement listener が ProStatus 更新 → pop で前画面に戻る
```

**imports:** dart=1 / package=4 / relative=5

- relative: `../theme/solara_colors.dart`, `../utils/legal_urls.dart`, `../utils/pro_status.dart`, `../utils/purchases_service.dart`, `../utils/solara_auth.dart`

**型定義 (2):**

- L33 `class PaywallScreen : StatefulWidget`
- L40 `class _PaywallScreenState : State`

**関数 (4 public + 8 private):**

- L37 `createState()`
- L48 `initState()`
- L55 `dispose()`
- L243 `build()`

  <details><summary>private 関数 8 件</summary>

  - L60 `_onProStatusChanged()`
  - L67 `_loadOfferings()`
  - L86 `_ensureSignedInForPro()`
  - L148 `_purchase()`
  - L183 `_restore()`
  - L210 `_showSnack()`
  - L220 `_openUrl()`
  - L228 `_openCancelGuide()`

  </details>


### `lib/screens/paywall_widgets.dart` (443 行)

**ファイル先頭コメント:**

```
Paywall Screen — プラン表示 / 機能リスト / 法的リンク のサブウィジェット
(part of 'paywall_screen.dart')

役割:
  - Stage 1 ペイウォール画面の表示パーツを分割保管
  - 親 (`_PaywallScreenState`) のメソッドとしてアクセス可能 (part-of)

内訳:
  - _buildHero                : ゴールドグラデのタイトル + 一文紹介
  - _buildFeatureList         : Pro で開く 5 機能の icon + 説明
  - _buildPlansSection        : Loading / 配信あり (月額/年額) / 配信無し
  - _buildStoreUnavailable    : Offerings 未配信 / 取得失敗時の準備中バナー
  - _buildPlanCard            : 単一プラン (年額 / 月額) のカード UI + 購入導線
  - _periodLabel / _introPeriodLabel : PackageType / PeriodUnit → 日本語ラベル

(Solara は consultation_input_screen.dart と同じ part-of パターンを採用)
```

**型定義 (1):**

- L20 `extension _PaywallWidgets : _PaywallScreenState`

**関数 (0 public + 13 private):**


  <details><summary>private 関数 13 件</summary>

  - L21 `_buildHero()`
  - L56 `_buildFeatureList()`
  - L76 `_featureRow()`
  - L122 `_buildPlansSection()`
  - L154 `_buildStoreUnavailable()`
  - L198 `_buildPlanCard()`
  - L309 `_periodLabel()`
  - L330 `_introPeriodLabel()`
  - L346 `_buildErrorPanel()`
  - L375 `_buildAutoRenewNotice()`
  - L391 `_buildLegalLinks()`
  - L407 `_legalLink()`
  - L422 `_buildRestoreButton()`

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

