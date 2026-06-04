# 層 4f: サブ画面 (Forecast / Locations / Philosophy / Font Preview)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 32 / 総行数: 11055
- class/mixin/extension/enum: 100
- 関数 (top-level + method の素拾い): 286
- Navigator.push 等: 0
- Popup/Dialog 呼出: 9
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/ai_consent_screen.dart` (301 行)

**imports:** dart=0 / package=2 / relative=3

- relative: `../i18n/strings.g.dart`, `../utils/legal_urls.dart`, `../utils/solara_storage.dart`

**型定義 (4):**

- L24 `class AiConsentScreen : StatelessWidget`
  - AI 生成同意モーダル (Apple 5.1.2(i) / Google Generative AI Apps Policy)。
- L206 `class _Section : StatelessWidget`
- L243 `class _LegalLinks : StatelessWidget`
- L261 `class _LinkPill : StatelessWidget`

**関数 (4 public + 3 private):**

- L82 `build()`
- L213 `build()`
- L249 `build()`
- L267 `build()`

  <details><summary>private 関数 3 件</summary>

  - L29 `_handleAgree()`
  - L35 `_handleDecline()`
  - L63 `_openLegalUrl()`

  </details>


### `lib/screens/consultation/consultation_credit_sheet.dart` (355 行)

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

**imports:** dart=1 / package=3 / relative=7

- relative: `../../i18n/strings.g.dart`, `../../theme/solara_colors.dart`, `../../utils/consultation_api.dart`, `../../utils/consultation_credits.dart`, `../../utils/purchases_service.dart`, `../../utils/solara_auth.dart`, `../paywall_screen.dart`

**型定義 (2):**

- L42 `class _CreditSheet : StatefulWidget`
- L49 `class _CreditSheetState : State`

**関数 (5 public + 8 private):**

- L29 `showConsultationCreditSheet()` — クレジット購入シートを開く。
- L46 `createState()`
- L61 `initState()`
- L69 `dispose()`
- L204 `build()`

  <details><summary>private 関数 8 件</summary>

  - L74 `_onCreditsChanged()`
  - L78 `_load()`
  - L90 `_ensureSignedIn()`
  - L140 `_buy()`
  - L180 `_pollUntilGranted()`
  - L193 `_openPaywall()`
  - L281 `_buildContent()`
  - L305 `_packageTile()`

  </details>


### `lib/screens/consultation/consultation_history_screen.dart` (305 行)

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

**imports:** dart=0 / package=1 / relative=8

- relative: `../../i18n/strings.g.dart`, `../../theme/solara_colors.dart`, `../../utils/consult_restore.dart`, `../../utils/consultation_record.dart`, `../../utils/solara_storage.dart`, `../../widgets/glass_panel.dart`, `../map/map_constants.dart`, `consultation_result_screen.dart`

**型定義 (2):**

- L88 `class ConsultationHistoryScreen : StatefulWidget`
- L110 `class _ConsultationHistoryScreenState : State`

**関数 (4 public + 11 private):**

- L106 `createState()`
- L119 `initState()`
- L128 `dispose()`
- L208 `build()`

  <details><summary>private 関数 11 件</summary>

  - L30 `_themeLabel()`
  - L47 `_themeColor()`
  - L71 `_modeLabel()`
  - L78 `_scopeLabel()`
  - L133 `_load()`
  - L145 `_delete()`
  - L154 `_toggleFavorite()`
  - L165 `_confirmDeleteAll()`
  - L253 `_buildFilterBar()`
  - L274 `_buildList()`
  - L298 `_openDetail()`

  </details>


### `lib/screens/consultation/consultation_history_widgets.dart` (507 行)

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
- L479 `class _MetaChip : StatelessWidget`

**関数 (4 public + 1 private):**

- L13 `build()`
- L68 `build()`
- L261 `build()`
- L487 `build()`

  <details><summary>private 関数 1 件</summary>

  - L451 `_confirmDelete()`

  </details>


### `lib/screens/consultation/consultation_input_examples.dart` (102 行)

**ファイル先頭コメント:**

```
Consultation Input — だれと / 願い の記入例 (テーマ別)
(part of 'consultation_input_screen.dart')

自由記述 (⑤ だれと / ⑥ 願い) はタップで埋まる記入例を添えて誘導する。
候補は選択中のテーマ (恋愛/豊かさ/仕事/対話/癒し/変化) に沿ったものだけを出す。
```

**型定義 (3):**

- L35 `class _ExampleChips : StatelessWidget`
  - タップで自由記述を埋める記入例チップ群。
- L84 `class _WhomExamples : StatelessWidget`
- L94 `class _WishExamples : StatelessWidget`

**関数 (3 public + 2 private):**

- L41 `build()`
- L90 `build()`
- L100 `build()`

  <details><summary>private 関数 2 件</summary>

  - L12 `_whomExamplesFor()`
  - L23 `_wishExamplesFor()`

  </details>


### `lib/screens/consultation/consultation_input_logic.dart` (206 行)

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
  - L141 `_onStartPressed()`
  - L153 `_handleBuyFromPopup()`
  - L160 `_showStartPopup()`
  - L180 `_runConsultation()`

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


### `lib/screens/consultation/consultation_input_screen.dart` (639 行)

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

**imports:** dart=1 / package=3 / relative=16

- relative: `../../i18n/strings.g.dart`, `../../theme/solara_colors.dart`, `../../utils/consult_restore.dart`, `../../utils/solara_i18n.dart`, `../../utils/consultation_credits.dart`, `../../utils/consultation_v2_api.dart`, `../../utils/pro_status.dart`, `../../utils/solara_storage.dart`, `../../widgets/info_popup.dart`, `../../widgets/pro_unlock_dialog.dart`, `../../widgets/tap_to_unfocus.dart`, `../map/map_search.dart`, `../map/map_vp_panel.dart`, `consultation_credit_sheet.dart`, `consultation_place_picker_screen.dart`, `consultation_result_screen.dart`

**型定義 (3):**

- L56 `class ConsultationPresetTarget`
  - Map から「📍この場所で相談」で起動した時の preset (point scope 用)。
- L81 `class ConsultationInputScreen : StatefulWidget`
- L104 `class _ConsultationInputScreenState : State`

**関数 (4 public + 12 private):**

- L100 `createState()`
- L143 `initState()`
- L250 `dispose()`
- L426 `build()`

  <details><summary>private 関数 12 件</summary>

  - L209 `_applyRestoreForm()`
  - L238 `_loadPrefsAndProfile()`
  - L258 `_onModeChanged()`
  - L288 `_onWhenKindTap()`
  - L317 `_pickHour()`
  - L326 `_pickSingleDate()`
  - L338 `_pickDateRange()`
  - L350 `_ymd()`
  - L354 `_onScopeKindTap()`
  - L364 `_openMapPicker()`
  - L414 `_refreshCreditsFresh()`
  - L419 `_setStartPopupHidden()`

  </details>


### `lib/screens/consultation/consultation_input_when_scope.dart` (363 行)

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
- L236 `class _TimeHourRow : StatelessWidget`
  - Pro 時刻指定の行。未選択=「時刻を指定（1時間刻み）」/ 選択中=「15:00 を指定中」+×。
- L330 `class _RadiusChips : StatelessWidget`
  - 自宅から半径の距離選択 (場面別 km 候補)。

**関数 (9 public + 2 private):**

- L56 `build()`
- L110 `build()`
- L126 `bandFromHour()` — 時刻 (0〜23) → 現地太陽時バケット。worker consultation_engine.timeOfDayBucket と一致。
- L136 `showConsultationHourPicker()` — Pro 時刻ドラム (1 時間刻み)。0〜23 時のホイールを bottom sheet で出し、決定で hour を返す。
- L151 `createState()`
- L160 `dispose()`
- L166 `build()`
- L251 `build()`
- L350 `build()`

  <details><summary>private 関数 2 件</summary>

  - L31 `_whenChoicesFor()`
  - L342 `_label()`

  </details>


### `lib/screens/consultation/consultation_input_widgets.dart` (529 行)

**ファイル先頭コメント:**

```
Consultation Input — 基本サブウィジェット + 選択肢定数
(part of 'consultation_input_screen.dart')
```

**型定義 (15):**

- L78 `class _ThemeChoice`
- L84 `class _ModeChoice`
- L90 `class _ScopeChoice`
- L99 `class _PillChip : StatelessWidget`
  - 単一選択の pill チップ (Wrap 用)。
- L139 `class _Section : StatelessWidget`
- L167 `class _ThemeGrid : StatelessWidget`
- L188 `class _ModeRow : StatelessWidget`
- L243 `class _ScopeWrap : StatelessWidget`
  - ④ どこで のスコープ選択 (Wrap、場面で 3〜5 個)。
- L269 `class _RegionPicker : StatelessWidget`
- L290 `class _FreeTextField : StatelessWidget`
- L346 `class _NoHomeNote : StatelessWidget`
  - 自宅未設定で 方角/半径/自国内 が使えないときの注記。
- L373 `class _PresetLocationCard : StatelessWidget`
- L412 `class _SubmitBar : StatelessWidget`
- L457 `class _ConsultIntroNote : StatelessWidget`
  - タイトル直下に常時表示する短い説明 (グレー小文字)。
- L482 `class _ConsultAboutContent : StatelessWidget`

**関数 (13 public + 2 private):**

- L110 `build()`
- L145 `build()`
- L173 `build()`
- L194 `build()`
- L254 `build()`
- L275 `build()`
- L303 `build()`
- L350 `build()`
- L378 `build()`
- L418 `build()`
- L461 `build()`
- L478 `showConsultAboutPopup()` — i ボタンの詳細ポップアップ (導入 → 読み解くデータ → 開発者より)。
- L486 `build()`

  <details><summary>private 関数 2 件</summary>

  - L46 `_scopeChoicesFor()`
  - L63 `_regionLabel()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/consultation/consultation_place_picker_screen.dart` (357 行)

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

**imports:** dart=1 / package=3 / relative=7

- relative: `../../i18n/strings.g.dart`, `../../theme/solara_colors.dart`, `../../utils/reverse_geocode.dart`, `../../widgets/tap_to_unfocus.dart`, `../map/map_search.dart`, `../map/map_styles.dart`, `consultation_input_screen.dart`

**型定義 (1):**

- L54 `class ConsultationPlacePickerScreen : StatefulWidget`
  - 地点選択画面 (B、フルスクリーン)。

**関数 (3 public + 8 private):**

- L68 `createState()`
- L99 `dispose()`
- L235 `build()`

  <details><summary>private 関数 8 件</summary>

  - L108 `_onSearchChanged()`
  - L121 `_runSearch()`
  - L144 `_onHitTap()`
  - L158 `_shortName()`
  - L168 `_selectPoint()`
  - L200 `_onMapTap()`
  - L205 `_clearSelection()`
  - L216 `_confirm()`

  </details>


### `lib/screens/consultation/consultation_place_picker_widgets.dart` (413 行)

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


### `lib/screens/consultation/consultation_result_card.dart` (581 行)

**ファイル先頭コメント:**

```
Consultation Result — 候補カード (V2)
(part of 'consultation_result_screen.dart')
```

**型定義 (8):**

- L6 `class _CandidateCard : StatelessWidget`
- L219 `class _EnergyChip : StatelessWidget`
- L245 `class _MapLinkIcon : StatelessWidget`
  - 場所名の右の🗺リンク。Map 画面で候補地を (相談の日付で) 見る。
- L276 `class _TimeWindowRow : StatelessWidget`
  - 時間帯。通常は現地の時間帯バンド (朝/昼/夕方/夜/夜更け)。single=1 個 / rhythm=朝昼夜。
- L318 `class _DeltaAfterSection : StatefulWidget`
  - 候補カードの「30分経過後を見る」セクション。タップで開閉、i ボタンで説明。
- L326 `class _DeltaAfterSectionState : State`
- L457 `class _DeltaChip : StatelessWidget`
  - 30 分後の 1 変化チップ (例: 「火星 MC ↘ 離れる」)。
- L511 `class _CandidateKindBadge : StatelessWidget`
  - 候補種別バッジ (方角 / 場所)。

**関数 (8 public + 1 private):**

- L43 `build()`
- L224 `build()`
- L250 `build()`
- L282 `build()`
- L323 `createState()`
- L357 `build()`
- L462 `build()`
- L520 `build()`

  <details><summary>private 関数 1 件</summary>

  - L329 `_showInfo()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/consultation/consultation_result_credit_widgets.dart` (150 行)

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


### `lib/screens/consultation/consultation_result_screen.dart` (582 行)

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

**imports:** dart=0 / package=3 / relative=20

- relative: `../../i18n/strings.g.dart`, `../../theme/solara_colors.dart`, `../../utils/consultation_api.dart`, `../../utils/consultation_credits.dart`, `../../utils/consult_restore.dart`, `../../utils/map_focus.dart`, `../../utils/consultation_return.dart`, `../../utils/consultation_record.dart`, `../../utils/consultation_share.dart`, `../../utils/consultation_v2_api.dart`, `../../utils/pro_status.dart`, `../../utils/solara_i18n.dart`, `../../utils/solara_storage.dart`, `../map/map_constants.dart`, `../../widgets/ai_disclaimer_footer.dart`, `../../widgets/ai_report_button.dart`, `../../widgets/glass_panel.dart`, `../../widgets/info_popup.dart`, `../../widgets/pro_unlock_dialog.dart`, `consultation_credit_sheet.dart`

**型定義 (2):**

- L49 `class ConsultationResultScreen : StatefulWidget`
- L99 `class _ConsultationResultScreenState : State`

**関数 (4 public + 12 private):**

- L95 `createState()`
- L164 `initState()`
- L196 `dispose()`
- L458 `build()`

  <details><summary>private 関数 12 件</summary>

  - L135 `_pushShownToAvoid()`
  - L155 `_setSharing()`
  - L218 `_runFetch()`
  - L223 `_fetch()`
  - L273 `_loadNext()`
  - L339 `_snack()`
  - L351 `_onBuyCredits()`
  - L357 `_showConsultationPaywall()`
  - L378 `_showAboutReading()`
  - L393 `_persist()`
  - L421 `_openCandidateOnMap()`
  - L529 `_buildBody()`

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


### `lib/screens/consultation/consultation_result_widgets.dart` (432 行)

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
- L235 `class _PageIndicator : StatelessWidget`
- L266 `class _SparseHint : StatelessWidget`
  - 近くの実在の町が乏しい (Phase B sparse) ときの控えめなヒント。
- L308 `class _ExhaustionPanel : StatelessWidget`
  - 候補を出し尽くした (案Y)。正直に止めた理由 + 条件変更の代替提案を出す。
- L394 `class _RefreshButton : StatelessWidget`
  - 「別の候補地を見る」(1 クレジット消費で次の distinct 候補を 1 つ取得)。

**関数 (8 public + 1 private):**

- L15 `build()`
- L45 `build()`
- L89 `build()`
- L132 `build()`
- L241 `build()`
- L271 `build()`
- L328 `build()`
- L400 `build()`

  <details><summary>private 関数 1 件</summary>

  - L313 `_reasonText()`

  </details>


### `lib/screens/consultation/consultation_return_chip.dart` (95 行)

**imports:** dart=0 / package=1 / relative=4

- relative: `../../i18n/strings.g.dart`, `../../theme/solara_colors.dart`, `../../utils/consultation_return.dart`, `consultation_result_screen.dart`

**型定義 (1):**

- L14 `class ConsultationReturnChip : StatelessWidget`
  - Map 下部 (4 チップバー = MapMenuChips の直上) に出す「← 相談結果に戻る」チップ。

**関数 (1 public + 1 private):**

- L35 `build()`

  <details><summary>private 関数 1 件</summary>

  - L17 `_onReturn()`

  </details>


### `lib/screens/consultation/consultation_start_popup.dart` (300 行)

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


### `lib/screens/forecast/forecast_life_periods.dart` (200 行)

**imports:** dart=0 / package=1 / relative=6

- relative: `../../i18n/strings.g.dart`, `../../utils/forecast_cache.dart`, `../../utils/solara_i18n.dart`, `../../widgets/info_popup.dart`, `../map/map_constants.dart`, `forecast_section_header.dart`

**型定義 (1):**

- L32 `class ForecastLifePeriodsSection : StatelessWidget`
  - 「◯◯期」セクション — 永続保存された運勢サイクルを表示

**関数 (1 public + 2 private):**

- L42 `build()`

  <details><summary>private 関数 2 件</summary>

  - L77 `_periodRow()`
  - L134 `_showLifePeriodsInfo()`

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


### `lib/screens/forecast/forecast_top5.dart` (237 行)

**imports:** dart=0 / package=1 / relative=6

- relative: `../../i18n/strings.g.dart`, `../../utils/forecast_cache.dart`, `../../utils/solara_i18n.dart`, `../../widgets/info_popup.dart`, `../map/map_constants.dart`, `forecast_section_header.dart`

**型定義 (1):**

- L11 `class ForecastTop5Section : StatelessWidget`
  - 強運Top5 セクション — 永続保存された Top5 を mode 別に表示

**関数 (1 public + 4 private):**

- L37 `build()`

  <details><summary>private 関数 4 件</summary>

  - L60 `_modeSelector()`
  - L78 `_seg()`
  - L103 `_row()`
  - L141 `_showTop5Info()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/forecast_screen.dart` (1057 行)

**imports:** dart=0 / package=1 / relative=11

- relative: `../i18n/strings.g.dart`, `../utils/forecast_cache.dart`, `../utils/pro_status.dart`, `../utils/solara_storage.dart`, `../widgets/info_popup.dart`, `../widgets/no_profile_guide.dart`, `../widgets/pro_unlock_dialog.dart`, `forecast/forecast_life_periods.dart`, `forecast/forecast_section_header.dart`, `forecast/forecast_top5.dart`, `map/map_constants.dart`

**型定義 (3):**

- L17 `class ForecastScreen : StatefulWidget`
  - Forecast 画面 — 1年予測（ヒートマップ + 選択日詳細 + 強運Top5）
- L35 `class _ForecastScreenState : State`
- L1028 `class _DayStepperButton : StatelessWidget`
  - 選択日詳細パネルの △ ボタン (左右で 1 日前後に動かす)。

**関数 (4 public + 30 private):**

- L32 `createState()`
- L67 `initState()`
- L164 `build()`
- L1039 `build()`

  <details><summary>private 関数 30 件</summary>

  - L72 `_initialize()`
  - L78 `_loadSettings()`
  - L92 `_setColorMode()`
  - L97 `_setHighColor()`
  - L102 `_load()`
  - L145 `_setYearOffset()`
  - L215 `_buildBody()`
  - L273 `_buildBasisCard()`
  - L328 `_fmt()`
  - L331 `_buildBestChip()`
  - L369 `_yearSeg()`
  - L395 `_buildHeatmap()`
  - L461 `_buildColorModeToggle()`
  - L504 `_rankSeg()`
  - L534 `_segment()`
  - L555 `_buildLegend()`
  - L595 `_catColorChips()`
  - L609 `_monthRow()`
  - L638 `_dayCell()`
  - L669 `_cellColor()`
  - L686 `_gradientColor()`
  - L697 `_categoryColor()`
  - L713 `_canShiftSelectedDay()`
  - L724 `_shiftSelectedDay()`
  - L731 `_buildSelectedDayDetail()`
  - L796 `_metric()`
  - L804 `_catBar()`
  - L841 `_buildFetchInfo()`
  - L855 `_showForecastUsageGuide()`
  - L958 `_showHeatmapInfo()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showInfoPopup`×2


### `lib/screens/locations/locations_date_stepper.dart` (357 行)

**imports:** dart=0 / package=2 / relative=1

- relative: `../../i18n/strings.g.dart`

**型定義 (3):**

- L11 `class LocationsDateStepper : StatelessWidget`
  - Locations 画面の日付ステッパー（年▲▼ 月▲▼ 日▲▼ + 「今日」リセット）。
- L263 `class _DateNumberField : StatefulWidget`
  - 数値を直接タイプして編集できるフィールド（年/月/日 共通）。
- L280 `class _DateNumberFieldState : State`

**関数 (6 public + 7 private):**

- L55 `build()`
- L277 `createState()`
- L285 `initState()`
- L293 `didUpdateWidget()`
- L317 `dispose()`
- L325 `build()`

  <details><summary>private 関数 7 件</summary>

  - L135 `_hourStepperBlock()`
  - L162 `_editHour()`
  - L198 `_pickerBlock()`
  - L229 `_dayArrowBlock()`
  - L244 `_arrowBtn()`
  - L301 `_onFocusChange()`
  - L305 `_commit()`

  </details>


### `lib/screens/locations_screen.dart` (744 行)

**imports:** dart=1 / package=2 / relative=10

- relative: `../i18n/strings.g.dart`, `../utils/solara_storage.dart`, `../widgets/info_popup.dart`, `../widgets/no_profile_guide.dart`, `../widgets/tap_to_unfocus.dart`, `locations/locations_date_stepper.dart`, `map/map_astro.dart`, `map/map_constants.dart`, `map/map_search.dart`, `map/map_vp_panel.dart`

**型定義 (3):**

- L17 `class LocationsScreen : StatefulWidget`
  - Locations 一覧画面 — 登録済み拠点を16方位スコア付きで管理。
- L40 `class _LocationsScreenState : State`
- L650 `class _SlotStats`

**関数 (3 public + 18 private):**

- L37 `createState()`
- L68 `initState()`
- L286 `build()`

  <details><summary>private 関数 18 件</summary>

  - L73 `_load()`
  - L133 `_shiftDate()`
  - L153 `_setYmd()`
  - L172 `_setHour()`
  - L180 `_shiftHour()`
  - L187 `_resetToday()`
  - L197 `_setDate()`
  - L230 `_addCurrent()`
  - L242 `_delete()`
  - L247 `_rename()`
  - L360 `_buildRefPointSelector()`
  - L440 `_buildCategorySelector()`
  - L484 `_emptyState()`
  - L509 `_buildList()`
  - L518 `_buildRow()`
  - L608 `_scoreBar()`
  - L644 `_fmtKm()`
  - L660 `_showLocationsUsageGuide()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/paywall_comparison.dart` (281 行)

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
  - L84 `_comparisonHeader()`
  - L132 `_comparisonSection()`
  - L160 `_comparisonRow()`
  - L207 `_buildFaqSection()`
  - L235 `_faqItem()`

  </details>


### `lib/screens/paywall_legal_links.dart` (195 行)

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
  - L142 `_buildLegalLinks()`
  - L159 `_legalLink()`
  - L174 `_buildRestoreButton()`

  </details>


### `lib/screens/paywall_screen.dart` (311 行)

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

**imports:** dart=1 / package=4 / relative=6

- relative: `../i18n/strings.g.dart`, `../theme/solara_colors.dart`, `../utils/legal_urls.dart`, `../utils/pro_status.dart`, `../utils/purchases_service.dart`, `../utils/solara_auth.dart`

**型定義 (3):**

- L38 `enum BillingCycle`
  - 課金サイクル選択トグル用。デフォルトは Annual (SAVE 50% 訴求)。
- L40 `class PaywallScreen : StatefulWidget`
- L47 `class _PaywallScreenState : State`

**関数 (4 public + 9 private):**

- L44 `createState()`
- L65 `initState()`
- L72 `dispose()`
- L257 `build()`

  <details><summary>private 関数 9 件</summary>

  - L59 `_setBilling()`
  - L77 `_onProStatusChanged()`
  - L84 `_loadOfferings()`
  - L103 `_ensureSignedInForPro()`
  - L163 `_purchase()`
  - L197 `_restore()`
  - L224 `_showSnack()`
  - L234 `_openUrl()`
  - L242 `_openCancelGuide()`

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
  - L99 `_toggleSegment()`
  - L162 `_buildFreeCard()`
  - L210 `_buildProCard()`
  - L315 `_buildProCta()`
  - L371 `_cardBadge()`
  - L395 `_planBullet()`

  </details>


### `lib/screens/solara_philosophy_screen.dart` (160 行)

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

**imports:** dart=0 / package=1 / relative=4

- relative: `../i18n/strings.g.dart`, `../theme/solara_colors.dart`, `../utils/solara_manifesto.dart`, `../widgets/glass_panel.dart`

**型定義 (4):**

- L18 `class SolaraPhilosophyScreen : StatelessWidget`
- L62 `class _Hero : StatelessWidget`
- L103 `class _SectionCard : StatelessWidget`
- L144 `class _Footer : StatelessWidget`

**関数 (4 public + 0 private):**

- L22 `build()`
- L66 `build()`
- L108 `build()`
- L148 `build()`

