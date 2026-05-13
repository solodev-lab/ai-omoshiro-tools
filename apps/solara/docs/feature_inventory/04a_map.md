# 層 4a: Map 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 25 / 総行数: 13926
- class/mixin/extension/enum: 87
- 関数 (top-level + method の素拾い): 283
- Navigator.push 等: 0
- Popup/Dialog 呼出: 18
- Worker URL リテラル: 5

## ファイル別

### `lib/screens/map/daily_transit_data.dart` (1013 行)

**ファイル先頭コメント:**

```
============================================================
Daily Transit 画面用 データ定義
元: map_daily_transit_screen.dart 内の private const 群
2026-04-30 セッション最終整理でファイル分割（約220行）

含むもの:
  - AngleFilter enum + ラベル/セット/意味マップ
  - CategoryFilterTips (5カテゴリ × 外向き/内向き各4tips)
  - planetAngleBaseText (10惑星 × 4アングル = 40パターン基本意味)
  - categoryAppendix (5カテゴリ × カテゴリ別補足文)
  - categoryPlanetSets (worker と同一の担当惑星セット)

Solara 設計思想: project_solara_design_philosophy.md
  両面思想・吉凶判定なし・ユーザーが読み取って判断
============================================================
```

**型定義 (1):**

- L23 `enum AngleFilter`
  - アングルフィルタ識別子。


### `lib/screens/map/map_aspect_chip.dart` (221 行)

**ファイル先頭コメント:**

```
============================================================
MapAspectChip — Daily Transit V2 用 1アスペクトチップ

元: map_daily_transit_screen.dart 内の _AspectChip
2026-04-29 セッション最終整理で独立ファイル化（行数肥大対策）。

表示:
  ☌ natal ♂火星 1.2°  のような compact な丸角チップ。
  色は Solara 設計思想に従い:
    - soft  = energySoft (銀月色)
    - hard  = energyHard (金陽色)
    - tense = energyHard (同上)
    - neutral = solaraGoldLight (金色)

タップ:
  showModalBottomSheet で Horo 相タブ相当の詳細解説を出す。
  buildAspectDescription(p1, p2, type) を流用しているため、
  表示内容は Horo 画面と完全に同じ。
============================================================
```

**imports:** dart=0 / package=1 / relative=5

- relative: `../../theme/solara_colors.dart`, `../../utils/daily_transits_api.dart`, `../../widgets/info_popup.dart`, `../horoscope/horo_aspect_description.dart`, `map_constants.dart`

**型定義 (1):**

- L28 `class MapAspectChip : StatelessWidget`

**関数 (1 public + 4 private):**

- L54 `build()`

  <details><summary>private 関数 4 件</summary>

  - L41 `_color()`
  - L103 `_showDetail()`
  - L191 `_descSection()`
  - L211 `_aspectSymbol()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/map/map_astro.dart` (508 行)

**imports:** dart=2 / package=1 / relative=4

- relative: `../../utils/astro_math.dart`, `../../utils/direction_energy.dart`, `../../utils/solara_api.dart`, `map_constants.dart`

**型定義 (2):**

- L20 `class ChartResult`
  - CF Worker /astro/chart のレスポンス
- L187 `class ScoreResult`

**関数 (8 public + 3 private):**

- L66 `fetchChart()` — CF Worker にチャートを要求
- L259 `scoreAll()` — ChartResult → Map画面用16方位スコア
- L288 `getAB()`
- L297 `addT()`
- L299 `addP()`
- L326 `isAngle()`
- L411 `addCT()`
- L413 `addCP()`

  <details><summary>private 関数 3 件</summary>

  - L121 `_cosFall()`
  - L162 `_emptyComp()`
  - L234 `_addAspectComp()`

  </details>

**Worker URL リテラル (1):**

- L17: `'$solaraWorkerBase/astro/chart'`


### `lib/screens/map/map_astro_carto.dart` (813 行)

**imports:** dart=0 / package=2 / relative=6

- relative: `../../utils/astro_glossary.dart`, `../../utils/astro_lines.dart`, `../../utils/astro_zenith_messages.dart`, `../../widgets/info_popup.dart`, `map_astro_lines.dart`, `map_constants.dart`

**型定義 (9):**

- L28 `class AstroCartoBanner : StatelessWidget`
  - Astro*Carto*Graphy モード中の上部バナー (タイトル + 閉じる×)。
- L250 `class AcgFrameDef`
- L293 `class AstroCartoFramePills : StatelessWidget`
  - 第1層: フレーム切替ピル (横並び 4 ピル + i)。
- L346 `class AstroCartoSubPills : StatelessWidget`
  - 第2層: active frame のサブトグル 4 つ (横並び)。
- L385 `class _FramePill : StatelessWidget`
  - 第1層の個別ピル (ラベル + i)。active 時はリング glow で強調。
- L454 `class _SubPill : StatelessWidget`
  - 第2層の個別小ピル (天頂 / 天底 / 天頂帯 / 天底帯)。
- L521 `class _ScrollableRowPanel : StatelessWidget`
  - ピル列の overflow 対策ラッパー。
- L556 `class AstroCartoCategoryPills : StatelessWidget`
  - Astro*Carto*Graphy モード中のカテゴリピル。
- L629 `class AstroZenithPopup : StatelessWidget`
  - 天頂・天底点タップ詳細 popup。

**関数 (8 public + 1 private):**

- L33 `build()`
- L306 `build()`
- L359 `build()`
- L402 `build()`
- L469 `build()`
- L532 `build()`
- L566 `build()`
- L646 `build()`

  <details><summary>private 関数 1 件</summary>

  - L94 `_showAcgUsageGuide()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/map/map_astro_lines.dart` (588 行)

**imports:** dart=0 / package=3 / relative=2

- relative: `../../utils/astro_lines.dart`, `map_constants.dart`

**型定義 (4):**

- L32 `class _AngleStyle`
- L58 `class AstroFrameStyle`
  - フレーム別の視覚プリセット。Tier A #5 で4フレーム同時描画する際の
- L386 `class AstroNadirMarker : StatelessWidget`
  - 装飾的な天底点マーカー (Lewis 理論: 裏側に在る天体)。
- L494 `class AstroZenithMarker : StatelessWidget`
  - 装飾的な天頂点マーカー (frame で見た目を切替):

**関数 (8 public + 2 private):**

- L119 `buildAstroPolylines()` — アスペクトラインを Polyline[] に変換。
- L193 `buildAstroLatitudeBandPolylines()` — 天頂帯・天底帯 (latitude bands) の緯度線を Polyline[] に変換する。
- L270 `buildAstroZenithMarkers()` — 各惑星の天頂点 (= AstroLine.zenith) に装飾マーカーを生成。
- L275 `Function()`
- L332 `buildAstroNadirMarkers()` — 各惑星の天底点 (= AstroLine.nadir) に装飾マーカーを生成。
- L337 `Function()`
- L407 `build()`
- L507 `build()`

  <details><summary>private 関数 2 件</summary>

  - L104 `_lerpColor()`
  - L175 `_latitudePolylinePoints()`

  </details>


### `lib/screens/map/map_constants.dart` (122 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (2):**

- L50 `class ChartLineStyle`
  - HTML: CHART_STYLE — natal/progressed/transit の線スタイル
- L85 `class PlanetMeta`
  - HTML: TAROT.planets — 惑星シンボルと色


### `lib/screens/map/map_daily_transit_screen.dart` (1799 行)

**ファイル先頭コメント:**

```
============================================================
MapDailyTransitScreen — F1-c フル UI

F1-c (2026-04-29 オーナー設計):
  最上部: 今日のトップカテゴリバナー（カテゴリアイコン + ラベル + 一行解説）
  メイン: 10惑星 × 4アングル(ASC/MC/DSC/IC) のタイムライン
  閉じるボタン: 右上 → 親で onClose() 経由で右上バッジ位置にフェード復帰

データ:
  /astro/daily-transits を fetchDailyTransits() で取得
  観測点は親から渡される LatLng (現状 _center、将来は home 優先で改善予定)
============================================================
```

**imports:** dart=0 / package=2 / relative=12

- relative: `../../theme/solara_colors.dart`, `../../utils/astro_glossary.dart`, `../../utils/daily_transits_api.dart`, `../../utils/solara_storage.dart`, `../../widgets/category_icon.dart`, `../../widgets/dominant_fortune_overlay.dart`, `../../widgets/glass_panel.dart`, `../../widgets/info_popup.dart`, `daily_transit_data.dart`, `map_aspect_chip.dart`, `map_constants.dart`, `map_vp_panel.dart`

**型定義 (14):**

- L29 `class MapDailyTransitScreen : StatefulWidget`
- L70 `enum _DayTab`
  - タブ識別子。
- L74 `class _MapDailyTransitScreenState : State`
- L265 `class _AcgEntryFooter : StatelessWidget`
  - Daily Transit popup 下部に表示する「🌐 世界規模で見る (ACG)」リンク行。
- L304 `class _DayTabBar : StatelessWidget`
- L521 `class _Header : StatelessWidget`
- L774 `class _CategoryTipsBox : StatelessWidget`
- L947 `class _LoadingBody : StatelessWidget`
- L977 `class _FailedBody : StatelessWidget`
- L1022 `class _TimelineBody : StatelessWidget`
- L1122 `class _TimelineRow : StatelessWidget`
- L1349 `class _AltitudeBadge : StatelessWidget`
  - L3 Lewis 高度バッジ。
- L1400 `class _LatitudeBandBox : StatelessWidget`
  - L3 Lewis 緯度帯ボックス。
- L1450 `class _LatitudeBandRow : StatelessWidget`

**関数 (19 public + 21 private):**

- L66 `createState()`
- L122 `initState()`
- L139 `dispose()`
- L204 `build()`
- L270 `build()`
- L322 `build()`
- L541 `build()`
- L681 `labelFor()`
- L690 `iconFor()`
- L696 `itemRow()`
- L784 `build()`
- L950 `build()`
- L981 `build()`
- L1037 `build()`
- L1139 `build()`
- L1355 `build()`
- L1405 `build()`
- L1457 `build()`
- L1686 `showDailyUsageGuidePopup()` — 「今日の動き」画面の使い方 popup。

  <details><summary>private 関数 21 件</summary>

  - L110 `_cacheKey()`
  - L116 `_resolveInitialVpIndex()`
  - L132 `_loadOrbsAndStart()`
  - L146 `_tabStartTime()`
  - L153 `_loadTab()`
  - L183 `_selectTab()`
  - L190 `_selectVp()`
  - L197 `_close()`
  - L399 `_tabBtn()`
  - L432 `_angleDropdown()`
  - L466 `_categoryDropdown()`
  - L507 `_filterPill()`
  - L650 `_tagline()`
  - L679 `_buildVpDropdownWithGuide()`
  - L1310 `_angleLabel()`
  - L1320 `_angleHint()`
  - L1330 `_azimuthToCompass()`
  - L1507 `_showEventDetailDialog()`
  - L1539 `_showCategoryTipsIntent()`
  - L1579 `_showAngleDetailPopup()`
  - L1615 `_showPlanetAngleDetail()`

  </details>

**Popup/Dialog 呼出 (4):**

- 集計: `showInfoPopup`×4


### `lib/screens/map/map_direction_popup.dart` (374 行)

**ファイル先頭コメント:**

```
============================================================
Solara DirectionEnergyPopup — 方角ごとの2エネルギー詳細表示

E4 (2026-04-29): 設計思想に基づく「両エネルギー事実提示」型ポップアップ。
  - ソフト / ハード を独立した2バーで表示
  - 主な寄与アスペクトを attribution 表示
  - 「良い」「悪い」とは判定しない、事実だけを伝える

関連:
  - lib/utils/direction_energy.dart (DirectionEnergy / AspectContribution)
  - project_solara_design_philosophy.md
============================================================
```

**imports:** dart=0 / package=1 / relative=5

- relative: `../../theme/solara_colors.dart`, `../../utils/astro_glossary.dart`, `../../utils/direction_energy.dart`, `../../widgets/info_popup.dart`, `map_constants.dart`

**型定義 (3):**

- L45 `class _PopupBody : StatelessWidget`
- L200 `class _EnergyBar : StatelessWidget`
- L295 `class _ContribRow : StatelessWidget`

**関数 (4 public + 3 private):**

- L26 `showDirectionEnergyPopup()` — 方角タップ詳細ポップアップを表示するヘルパー。
- L59 `build()`
- L218 `build()`
- L300 `build()`

  <details><summary>private 関数 3 件</summary>

  - L173 `_guidanceText()`
  - L345 `_planetLabel()`
  - L362 `_aspectLabel()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/map/map_display_menu.dart` (410 行)

**imports:** dart=0 / package=1 / relative=3

- relative: `../../widgets/info_popup.dart`, `map_constants.dart`, `map_styles.dart`

**型定義 (6):**

- L27 `class MapDisplayMenu : StatefulWidget`
  - 左サイド ☰表示ボタンタップで右に展開するメニュー (2026-05-09)。
- L61 `enum _MainTab`
- L62 `enum _PlanetSub`
- L64 `class _MapDisplayMenuState : State`
- L342 `class _MenuInfoRow : StatelessWidget`
  - 説明 popup 用の項目行 (見出し + 本文)。
- L369 `class _ChipButton : StatelessWidget`
  - 共通のチップ風ボタン (active 状態で塗りつぶし変化)。

**関数 (5 public + 10 private):**

- L58 `createState()`
- L69 `build()`
- L232 `planetsJp()`
- L348 `build()`
- L384 `build()`

  <details><summary>private 関数 10 件</summary>

  - L98 `_l2Buttons()`
  - L144 `_l3Buttons()`
  - L177 `_toggleSub()`
  - L185 `_tabBtn()`
  - L197 `_tabBtnWithInfo()`
  - L215 `_showTabInfo()`
  - L295 `_subTabBtn()`
  - L305 `_toggleBtn()`
  - L315 `_radioBtn()`
  - L325 `_scrollRow()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/map/map_fortune_sheet.dart` (775 行)

**imports:** dart=0 / package=1 / relative=5

- relative: `../../utils/direction_energy.dart`, `../../widgets/info_popup.dart`, `map_constants.dart`, `map_direction_popup.dart`, `map_widgets.dart`

**型定義 (4):**

- L16 `class FortuneFilterLabel : StatelessWidget`
  - HTML: .ff-label { top:52px; left:16px; inline-flex row: ff-tag + ff-bars }
- L191 `class FortuneSheet : StatelessWidget`
  - Fortune Sheet — HTML: .fs { bottom:80px; border-radius:16px 16px 0 0; }
- L743 `class _FortuneRowsList : StatefulWidget`
  - `RawScrollbar` と `ListView` で同じ `ScrollController` を共有する。
- L751 `class _FortuneRowsListState : State`

**関数 (7 public + 3 private):**

- L10 `pctValue()` — pct() from HTML: 0-5 → 0-83.3%, 5-10 → 83.3-100%
- L33 `build()`
- L216 `build()`
- L466 `showCategoryInfoPopup()` — Map の使い方 + カテゴリと関連惑星ペアの説明 popup。
- L748 `createState()`
- L755 `dispose()`
- L761 `build()`

  <details><summary>private 関数 3 件</summary>

  - L280 `_buildSrcTabs()`
  - L312 `_buildCatTabs()`
  - L341 `_buildFortuneRows()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/map/map_line_narrative_sheet.dart` (232 行)

**ファイル先頭コメント:**

```
══════════════════════════════════════════════════
Map Line Narrative Sheet
A*C*G ライン (natal / transit) のタップ詳細 popup。

構成:
  ① ヘッダー: 惑星 glyph + 名前 + ANGLE/Frame chip + 距離
  ② 静的セクション: 用語辞書 (aspect_lines / transit_acg) サマリ

設計思想: project_solara_design_philosophy.md (Soft/Hard 独立2エネルギー)

旧実装にあった Gemini AI 解説機能 (詳しく読むボタン → 動的生成) は
2026-05-11 撤去。静的辞書ベースの解説のみに統一。

関連:
  - 呼び出し元: map_relocation_popup.dart の _buildLineRow タップ
  - 静的辞書: utils/astro_glossary.dart (aspect_lines / transit_acg)
══════════════════════════════════════════════════
```

**imports:** dart=0 / package=2 / relative=6

- relative: `../../theme/solara_colors.dart`, `../../utils/astro_glossary.dart`, `../../utils/astro_lines.dart`, `../../widgets/info_popup.dart`, `../horoscope/horo_constants.dart`, `map_constants.dart`

**型定義 (2):**

- L29 `class MapLineNarrativeSheet : StatefulWidget`
- L52 `class _MapLineNarrativeSheetState : State`

**関数 (3 public + 2 private):**

- L49 `createState()`
- L67 `build()`
- L216 `showLineNarrativeSheet()` — 共通呼び出しヘルパー: タップから直接 説明 popup を表示。

  <details><summary>private 関数 2 件</summary>

  - L85 `_buildHeader()`
  - L169 `_buildStaticSection()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showLineNarrativeSheet`×1, `showInfoPopup`×1


### `lib/screens/map/map_location_markers.dart` (295 行)

**imports:** dart=0 / package=4 / relative=2

- relative: `../../utils/solara_storage.dart`, `map_vp_panel.dart`

**型定義 (3):**

- L25 `class BirthMarker : StatelessWidget`
  - 出生地マーカー: 🌟 + 多層グロー (静止)。
- L69 `class SlotMarker : StatelessWidget`
  - 通常スロット (VP / Locations) マーカー。
- L190 `class LocationMarkerPopup : StatelessWidget`
  - マーカータップ詳細 popup (画面下部の bottom sheet)。

**関数 (5 public + 1 private):**

- L29 `build()`
- L76 `build()`
- L132 `buildLocationMarkers()` — 登録地マーカー群を構築。
- L140 `slotMarker()`
- L205 `build()`

  <details><summary>private 関数 1 件</summary>

  - L286 `_fmtCoord()`

  </details>


### `lib/screens/map/map_menu_chips.dart` (307 行)

**imports:** dart=0 / package=1 / relative=3

- relative: `../../theme/solara_colors.dart`, `../../widgets/category_icon.dart`, `../../widgets/dominant_fortune_overlay.dart`

**型定義 (6):**

- L12 `class MapMenuChips : StatelessWidget`
  - 下部チップバー (NavBar 直上、4 個: Daily / Fortune / Locations / Forecast)。
- L89 `class _ChipBody : StatelessWidget`
  - 全チップ共通の Container 外形 (高さ・border・gradient)。
- L117 `class _ChipColumn : StatelessWidget`
  - 全チップ共通の中身 (アイコン + ラベル縦並び)。
- L152 `class _StaticChip : StatelessWidget`
  - Daily 以外の通常チップ (Fortune / Locations / Forecast)。
- L191 `class _DailyTransitChip : StatelessWidget`
  - Daily Transit 専用チップ。
- L281 `class _ChipHalo : StatelessWidget`
  - チップの周囲に静的に描画する halo。

**関数 (6 public + 1 private):**

- L34 `build()`
- L101 `build()`
- L129 `build()`
- L160 `build()`
- L223 `build()`
- L285 `build()`

  <details><summary>private 関数 1 件</summary>

  - L203 `_buildIcon()`

  </details>


### `lib/screens/map/map_overlays.dart` (481 行)

**imports:** dart=0 / package=3 / relative=2

- relative: `map_vp_panel.dart`, `map_widgets.dart`

**型定義 (9):**

- L48 `class MapSideButtons : StatelessWidget`
  - 左サイド縦並び 3 ボタン: 🔍 検索 / ☰ 表示 / 📍 地点 (2026-05-09 第二弾)。
- L119 `class SearchBarOverlay : StatefulWidget`
  - 検索バー（_searchOpen 時に最上部に表示）
- L135 `class _SearchBarOverlayState : State`
- L197 `class SearchVpChipRow : StatelessWidget`
  - 検索バー直上に出す VIEWPOINT (16方位基準) 選択チップ列。
- L276 `class _Chip : StatelessWidget`
- L320 `class SelectedDateBadge : StatelessWidget`
  - 選択日バッジ（地図左上に常時表示）
- L369 `class StatusBadge : StatelessWidget`
  - 右上のステータスバッジ（計算中・検索中）
- L396 `class VpPinVisual : StatelessWidget`
  - VP Pin (ドラッグ可能な中央の金色ピン) — 見た目のみ。
- L420 `class RestOverlay : StatelessWidget`
  - 休息オーバーレイ（🌙 + テキスト）

**関数 (13 public + 1 private):**

- L9 `buildVpPinMarker()` — VP Pin (ドラッグ可能な中央の金色ピン) の Marker を生成する。
- L69 `build()`
- L132 `createState()`
- L139 `initState()`
- L147 `dispose()`
- L153 `build()`
- L221 `build()`
- L283 `build()`
- L332 `build()`
- L374 `build()`
- L400 `build()`
- L426 `build()`
- L455 `showSolaraDatePicker()` — Solara テーマ適用の DatePicker を開く。選択されたら DateTime を返す（正午固定はしない）。

  <details><summary>private 関数 1 件</summary>

  - L214 `_isActive()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showSolaraDatePicker`×1


### `lib/screens/map/map_planet_intro_popup.dart` (239 行)

**imports:** dart=0 / package=2 / relative=5

- relative: `../../theme/solara_colors.dart`, `../../utils/planet_intro.dart`, `../../widgets/info_popup.dart`, `../horoscope/horo_panel_shared.dart`, `map_constants.dart`

**型定義 (1):**

- L56 `class _PlanetIntroBody : StatelessWidget`

**関数 (2 public + 4 private):**

- L31 `showPlanetIntroPopup()`
- L76 `build()`

  <details><summary>private 関数 4 件</summary>

  - L94 `_header()`
  - L155 `_frameSection()`
  - L178 `_coreSection()`
  - L219 `_placeholder()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showInfoPopup`×2


### `lib/screens/map/map_planet_lines.dart` (285 行)

**imports:** dart=0 / package=3 / relative=4

- relative: `../../widgets/solara_nav_bar.dart`, `../horoscope/horo_panel_shared.dart`, `map_constants.dart`, `map_astro.dart`

**型定義 (2):**

- L32 `class PlanetLineData`
  - 1惑星分のライン情報
- L132 `class PlanetSymbolsLayer : StatelessWidget`
  - 惑星シンボルレイヤー（HTML: updateSymPos の edge tracking を再現）

**関数 (3 public + 1 private):**

- L50 `buildPlanetLineData()` — ChartResult から全天体ラインデータを生成
- L86 `buildPlanetPolylines()` — PlanetLineData → flutter_map Polyline に変換
- L152 `build()`

  <details><summary>private 関数 1 件</summary>

  - L13 `_geodesicLine()`

  </details>


### `lib/screens/map/map_relocation_popup.dart` (564 行)

**imports:** dart=0 / package=2 / relative=7

- relative: `../../utils/astro_glossary.dart`, `../../utils/astro_houses.dart`, `../../utils/astro_lines.dart`, `../../widgets/astro_term_label.dart`, `../horoscope/horo_constants.dart`, `map_constants.dart`, `map_line_narrative_sheet.dart`

**型定義 (1):**

- L40 `class MapRelocationPopup : StatelessWidget`

**関数 (1 public + 11 private):**

- L92 `build()`

  <details><summary>private 関数 11 件</summary>

  - L155 `_buildLinesSection()`
  - L198 `_buildLineRow()`
  - L272 `_openLineSheet()`
  - L286 `_buildTitleArea()`
  - L319 `_buildHeader()`
  - L390 `_buildAngleRow()`
  - L452 `_buildPlanetGrid()`
  - L461 `_buildPlanetRow()`
  - L549 `_recoverBaselineAsc()`
  - L554 `_signOf()`
  - L559 `_fmtCoord()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showLineNarrativeSheet`×1


### `lib/screens/map/map_search.dart` (590 行)

**imports:** dart=2 / package=3 / relative=4

- relative: `../../utils/solara_api.dart`, `map_astro.dart`, `map_constants.dart`, `map_fortune_sheet.dart`

**型定義 (5):**

- L14 `class SearchHit`
  - 検索結果1件分
- L138 `class SearchResultList : StatelessWidget`
  - 検索結果リスト（スコア付き）ポップアップ
- L316 `class SearchFocusPopup : StatelessWidget`
  - 検索候補から1件選ばれたあとの詳細ポップアップ。
- L542 `class _CatChip : StatelessWidget`
- L567 `class _ActionTile : StatelessWidget`

**関数 (7 public + 4 private):**

- L43 `directionFrom()` — 中心座標から見たこの地点の方位（16方位名）
- L48 `distanceKmFrom()` — 中心から km 距離
- L114 `annotateHitsWithScores()` — 検索結果に、現在中心からの方位スコアと支配カテゴリを注入する
- L162 `build()`
- L352 `build()`
- L548 `build()`
- L573 `build()`

  <details><summary>private 関数 4 件</summary>

  - L53 `_bearingDeg()`
  - L62 `_azimuthToDir16()`
  - L68 `_haversineKm()`
  - L210 `_hitRow()`

  </details>

**Worker URL リテラル (1):**

- L11: `'$solaraWorkerBase/search'`


### `lib/screens/map/map_sectors.dart` (173 行)

**imports:** dart=0 / package=3 / relative=1

- relative: `map_constants.dart`

**関数 (3 public + 1 private):**

- L19 `buildSectors()` — 16方位扇状セクター — `activeCategory` のカテゴリ色 1色 + alpha のみ可変。
- L123 `buildCompass()` — 8方向のコンパスライン — gold dashed、扇状とは独立。
- L144 `buildDirLabels()` — 方位ラベルマーカー（N,NE,E... を3距離に表示）。

  <details><summary>private 関数 1 件</summary>

  - L94 `_fanPoints()`

  </details>


### `lib/screens/map/map_styles.dart` (152 行)

**imports:** dart=0 / package=3 / relative=2

- relative: `../../utils/solara_api.dart`, `../../utils/tile_http_client.dart`

**型定義 (2):**

- L15 `enum MapStyle`
  - マップスタイルの種類。LayerPanel から切替可。
- L32 `class MapStyleConfig`

**関数 (3 public + 0 private):**

- L79 `mapStyleFromId()` — id 文字列から MapStyle を復元。
- L98 `buildStyledTileLayer()` — 選択スタイルに応じた TileLayer を返す。
- L101 `Function()`

**Worker URL リテラル (2):**

- L60: `'$solaraWorkerBase/tiles/osm/hot/{z}/{x}/{y}.png'`
- L69: `'$solaraWorkerBase/tiles/osm/hot/{z}/{x}/{y}.png'`


### `lib/screens/map/map_time_slider.dart` (473 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (2):**

- L17 `class MapTimeSlider : StatefulWidget`
  - ============================================================
- L39 `class MapTimeSliderState : State`
  - public State: GlobalKey 経由で map_screen.dart の PopScope から

**関数 (3 public + 20 private):**

- L34 `createState()`
- L45 `closeTimeRow()` — 時刻行が開いていれば閉じる。 開いていなければ何もしない。
- L226 `build()`

  <details><summary>private 関数 20 件</summary>

  - L52 `_setTimeRowExpanded()`
  - L70 `_committedDays()`
  - L81 `_committedHourJst()`
  - L89 `_committedMinuteJst()`
  - L100 `_displayMinuteJst()`
  - L108 `_previewDateJst()`
  - L119 `_commitDays()`
  - L138 `_commitHour()`
  - L148 `_commitDayShiftAndTime()`
  - L158 `_isLive()`
  - L161 `_isLiveHour()`
  - L168 `_stepDay()`
  - L175 `_stepHour()`
  - L191 `_stepMinute()`
  - L214 `_fmtDate()`
  - L221 `_fmtTime()`
  - L270 `_buildDayRow()`
  - L389 `_buildHourRow()`
  - L439 `_sliderTheme()`
  - L453 `_stepperBtn()`

  </details>


### `lib/screens/map/map_viewpoint_menu.dart` (646 行)

**imports:** dart=0 / package=2 / relative=3

- relative: `../../utils/solara_storage.dart`, `../../widgets/info_popup.dart`, `map_vp_panel.dart`

**型定義 (2):**

- L151 `class MapViewpointMenu : StatefulWidget`
  - 📍 地点ボタンタップで画面上部に展開するパネル (2026-05-09 第三弾)。
- L182 `class _MapViewpointMenuState : State`

**関数 (3 public + 12 private):**

- L172 `createState()`
- L198 `initState()`
- L245 `build()`

  <details><summary>private 関数 12 件</summary>

  - L10 `_showViewpointHelpPopup()`
  - L203 `_loadAll()`
  - L218 `_reload()`
  - L232 `_saveCurrent()`
  - L352 `_tabBtn()`
  - L389 `_actionBtn()`
  - L421 `_buildSlotList()`
  - L439 `_buildSlotRow()`
  - L493 `_buildSubMenu()`
  - L523 `_subItem()`
  - L556 `_showIconPickerDialog()`
  - L606 `_showRenameDialog()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/map/map_vp_panel.dart` (120 行)

**imports:** dart=1 / package=2 / relative=2

- relative: `../../utils/reverse_geocode.dart`, `../../utils/solara_storage.dart`

**型定義 (2):**

- L17 `class VPSlot`
  - スロット1件分のデータ
- L35 `class SlotManager`
  - HTML: SlotManager — SharedPreferencesでスロットを永続化

**関数 (8 public + 0 private):**

- L26 `toJson()`
- L50 `save()`
- L56 `syncHome()` — HTML: syncHome — プロフィールのホーム地点を先頭スロットに同期
- L73 `saveCurrentLocation()` — HTML: saveCurrentLocation — reverse geocodingで地名取得して保存
- L91 `moveSlot()`
- L100 `renameSlot()`
- L107 `deleteSlot()`
- L114 `changeIcon()`


### `lib/screens/map/map_widgets.dart` (51 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (2):**

- L6 `class MapBtn : StatelessWidget`
  - Map circle button — HTML: .search-trigger, .layer-btn, .vp-btn
- L34 `class LegendDot : StatelessWidget`
  - Legend dot — HTML: .fs-legend { font-size:9px; color:#888; }

**関数 (2 public + 0 private):**

- L13 `build()`
- L40 `build()`


### `lib/screens/map_screen.dart` (2695 行)

**imports:** dart=2 / package=6 / relative=30

- relative: `../utils/solara_api.dart`, `../utils/solara_storage.dart`, `../utils/tile_http_client.dart`, `../widgets/dominant_fortune_overlay.dart`, `../widgets/info_popup.dart`, `map/map_daily_transit_screen.dart`, `map/map_constants.dart`, `map/map_styles.dart`, `map/map_sectors.dart`, `map/map_fortune_sheet.dart`, `map/map_vp_panel.dart`, `map/map_menu_chips.dart`, `map/map_display_menu.dart`, `map/map_viewpoint_menu.dart`, `map/map_astro.dart`, `map/map_astro_carto.dart`, `map/map_astro_lines.dart`, `map/map_location_markers.dart`, `map/map_planet_intro_popup.dart`, `map/map_planet_lines.dart`, `map/map_relocation_popup.dart`, `map/map_search.dart`, `map/map_overlays.dart`, `map/map_time_slider.dart`, `map/map_widgets.dart`, `../utils/astro_lines.dart`, `../utils/direction_energy.dart`, `forecast_screen.dart`, `horoscope/horo_antique_icons.dart`, `locations_screen.dart`

**型定義 (2):**

- L69 `class MapScreen : StatefulWidget`
- L79 `class MapScreenState : State`

**関数 (8 public + 48 private):**

- L76 `createState()`
- L317 `initState()`
- L348 `dispose()`
- L456 `reloadProfile()` — 外部（main.dart のタブ切替）から呼ばれる公開リロード。
- L1262 `snack()`
- L1425 `snack()`
- L1471 `build()`
- L2455 `signOf()`

  <details><summary>private 関数 48 件</summary>

  - L326 `_bootstrap()`
  - L362 `_warmupTileConnection()`
  - L397 `_onTileError()`
  - L424 `_checkDailyBadgeState()`
  - L442 `_loadMapStyle()`
  - L448 `_onMapStyleChanged()`
  - L463 `_moveToInitialCenter()`
  - L471 `_loadProfileAndChart()`
  - L641 `_cycleActiveCategory()`
  - L668 `_reannotateSearchResults()`
  - L700 `_showSheet()`
  - L720 `_openLocations()`
  - L737 `_openForecast()`
  - L756 `_onDisplayMenuTap()`
  - L766 `_onViewpointMenuTap()`
  - L780 `_onSearchTap()`
  - L794 `_clearAllSearch()`
  - L811 `_onDailyBadgeTap()`
  - L858 `_onOverlayComplete()`
  - L868 `_onDailyTransitClose()`
  - L880 `_doSearch()`
  - L941 `_frameSearchArea()`
  - L967 `_restoreSearchListView()`
  - L977 `_selectSearchHit()`
  - L1007 `_buildFocusedHitMarker()`
  - L1049 `_buildSearchHitMarkers()`
  - L1122 `_displayScores()`
  - L1183 `_sectorRankAlphaMul()`
  - L1201 `_rebuild()`
  - L1235 `_kickPaintInvalidation()`
  - L1249 `_setVpOnly()`
  - L1261 `_setVpToCurrentLocationOnly()`
  - L1307 `_enterAstroCartoMode()`
  - L1377 `_exitAstroCartoMode()`
  - L1424 `_geolocate()`
  - L1534 `_buildBody()`
  - L2422 `_buildZenithPopup()`
  - L2435 `_buildRelocationPopup()`
  - L2488 `_reloadLocationSlots()`
  - L2506 `_findNearbyAstroLines()`
  - L2524 `_zenithMarkerFrames()`
  - L2525 `_nadirMarkerFrames()`
  - L2526 `_zenithBandFrames()`
  - L2527 `_nadirBandFrames()`
  - L2531 `_filteredFrames()`
  - L2544 `_visibleAstroLines()`
  - L2567 `_buildNoProfileGuide()`
  - L2601 `_showSearchVpHelpPopup()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showLineNarrativeSheet`×1, `showInfoPopup`×1

**Worker URL リテラル (1):**

- L368: `'$solaraWorkerBase/tiles/osm/hot/0/0/0.png'`

