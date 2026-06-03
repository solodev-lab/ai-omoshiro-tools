# 層 4a: Map 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 25 / 総行数: 14551
- class/mixin/extension/enum: 90
- 関数 (top-level + method の素拾い): 322
- Navigator.push 等: 0
- Popup/Dialog 呼出: 20
- Worker URL リテラル: 0

## ファイル別

### `lib/screens/map/consult_entry_popup.dart` (338 行)

**ファイル先頭コメント:**

```
Consult Entry Popup — Stella 相談の共通入口 popup

設計議論 2026-05-16 → 2026-05-17 簡素化:
  - 「Stella に相談」開始 popup として複数経路で共通利用:
    - 空地点タップ (ACG/非 ACG 共通、Pro ユーザーのみ): map_screen.onTap から
    - 線/天頂/天底 popup 内 CTA 「この地点で相談」: 直接 ConsultationInputScreen
      を push する経路で、この popup は経由しない

表示内容 (吉凶禁止原則を守るため Map の sector スコアは出さない):
  - 地名 (reverse geocode 結果、失敗時は「タップ地点」)
  - 座標 (lat°/lng°)
  - 最寄りの natal-frame conjunction line 3 本 (Stella 相談エンジンと同じ材料)
  - 「この場所で相談する」CTA

工数注: 最寄り線計算は呼出側で済ませて [nearestLines] として渡す。
```

**imports:** dart=0 / package=3 / relative=4

- relative: `../../theme/solara_colors.dart`, `../../utils/astro_lines.dart`, `../../utils/reverse_geocode.dart`, `map_constants.dart`

**型定義 (3):**

- L34 `class ConsultEntryPopup : StatefulWidget`
- L61 `class _ConsultEntryPopupState : State`
- L285 `class _NearestLineRow : StatelessWidget`

**関数 (4 public + 2 private):**

- L58 `createState()`
- L68 `initState()`
- L118 `build()`
- L290 `build()`

  <details><summary>private 関数 2 件</summary>

  - L73 `_resolveName()`
  - L105 `_copyCoords()`

  </details>


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


### `lib/screens/map/map_astro_carto.dart` (859 行)

**imports:** dart=0 / package=2 / relative=7

- relative: `../../i18n/strings.g.dart`, `../../utils/astro_glossary.dart`, `../../utils/astro_lines.dart`, `../../utils/astro_zenith_messages.dart`, `../../widgets/info_popup.dart`, `map_astro_lines.dart`, `map_constants.dart`

**型定義 (9):**

- L29 `class AstroCartoBanner : StatelessWidget`
  - Astro*Carto*Graphy モード中の上部バナー (タイトル + 閉じる×)。
- L233 `class AcgFrameDef`
- L284 `class AstroCartoFramePills : StatelessWidget`
  - 第1層: フレーム切替ピル (横並び 4 ピル + i)。
- L351 `class AstroCartoSubPills : StatelessWidget`
  - 第2層: active frame のサブトグル 4 つ (横並び)。
- L390 `class _FramePill : StatelessWidget`
  - 第1層の個別ピル (ラベル + i)。active 時はリング glow で強調。
- L459 `class _SubPill : StatelessWidget`
  - 第2層の個別小ピル (天頂 / 天底 / 天頂帯 / 天底帯)。
- L526 `class _ScrollableRowPanel : StatelessWidget`
  - ピル列の overflow 対策ラッパー。
- L561 `class AstroCartoCategoryPills : StatelessWidget`
  - Astro*Carto*Graphy モード中のカテゴリピル。
- L634 `class AstroZenithPopup : StatelessWidget`
  - 天頂・天底点タップ詳細 popup。

**関数 (8 public + 2 private):**

- L34 `build()`
- L297 `build()`
- L364 `build()`
- L407 `build()`
- L474 `build()`
- L537 `build()`
- L571 `build()`
- L657 `build()`

  <details><summary>private 関数 2 件</summary>

  - L99 `_showAcgUsageGuide()`
  - L275 `_subLabel()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/map/map_astro_lines.dart` (624 行)

**imports:** dart=0 / package=3 / relative=3

- relative: `../../theme/solara_colors.dart`, `../../utils/astro_lines.dart`, `map_constants.dart`

**型定義 (4):**

- L33 `class _AngleStyle`
- L59 `class AstroFrameStyle`
  - フレーム別の視覚プリセット。Tier A #5 で4フレーム同時描画する際の
- L422 `class AstroNadirMarker : StatelessWidget`
  - 装飾的な天底点マーカー (Lewis 理論: 裏側に在る天体)。
- L530 `class AstroZenithMarker : StatelessWidget`
  - 装飾的な天頂点マーカー (frame で見た目を切替):

**関数 (8 public + 3 private):**

- L133 `buildAstroPolylines()` — アストロラインを Polyline[] に変換。
- L223 `buildAstroLatitudeBandPolylines()` — 天頂帯・天底帯 (latitude bands) の緯度線を Polyline[] に変換する。
- L306 `buildAstroZenithMarkers()` — 各惑星の天頂点 (= AstroLine.zenith) に装飾マーカーを生成。
- L311 `Function()`
- L368 `buildAstroNadirMarkers()` — 各惑星の天底点 (= AstroLine.nadir) に装飾マーカーを生成。
- L373 `Function()`
- L443 `build()`
- L543 `build()`

  <details><summary>private 関数 3 件</summary>

  - L105 `_lerpColor()`
  - L119 `_aspectEnergyColor()`
  - L203 `_latitudePolylinePoints()`

  </details>


### `lib/screens/map/map_daily_transit_screen.dart` (2004 行)

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

- relative: `../../i18n/strings.g.dart`, `../../theme/solara_colors.dart`, `../../utils/astro_glossary.dart`, `../../utils/daily_transits_api.dart`, `../../widgets/category_icon.dart`, `../../widgets/dominant_fortune_overlay.dart`, `../../widgets/glass_panel.dart`, `../../widgets/info_popup.dart`, `daily_transit_data.dart`, `map_aspect_chip.dart`, `map_constants.dart`, `map_vp_panel.dart`

**型定義 (16):**

- L29 `class MapDailyTransitScreen : StatefulWidget`
- L82 `enum _DayTab`
  - タブ識別子。
- L86 `class _MapDailyTransitScreenState : State`
- L275 `class _FooterActions : StatelessWidget`
  - Daily Transit popup 下部の動線フッター。
- L333 `class _FooterButton : StatelessWidget`
  - フッター内の 1 つのアクションボタン (絵文字 + タイトル + サブタイトル)。
- L436 `class _DayTabBar : StatelessWidget`
- L653 `class _Header : StatefulWidget`
- L681 `class _HeaderState : State`
- L1005 `class _CategoryTipsBox : StatelessWidget`
- L1178 `class _LoadingBody : StatelessWidget`
- L1208 `class _FailedBody : StatelessWidget`
- L1253 `class _TimelineBody : StatelessWidget`
- L1353 `class _TimelineRow : StatelessWidget`
- L1575 `class _AltitudeBadge : StatelessWidget`
  - L3 Lewis 高度バッジ。
- L1628 `class _LatitudeBandBox : StatelessWidget`
  - L3 Lewis 緯度帯ボックス。
- L1680 `class _LatitudeBandRow : StatelessWidget`

**関数 (23 public + 20 private):**

- L78 `createState()`
- L131 `initState()`
- L144 `dispose()`
- L208 `build()`
- L285 `build()`
- L349 `build()`
- L454 `build()`
- L678 `createState()`
- L686 `initState()`
- L720 `dispose()`
- L726 `build()`
- L909 `labelFor()`
- L918 `iconFor()`
- L924 `itemRow()`
- L1015 `build()`
- L1181 `build()`
- L1212 `build()`
- L1268 `build()`
- L1370 `build()`
- L1581 `build()`
- L1633 `build()`
- L1687 `build()`
- L1916 `showDailyUsageGuidePopup()` — 「今日の動き」画面の使い方 popup。

  <details><summary>private 関数 20 件</summary>

  - L119 `_cacheKey()`
  - L125 `_resolveInitialVpIndex()`
  - L151 `_tabStartTime()`
  - L158 `_loadTab()`
  - L187 `_selectTab()`
  - L194 `_selectVp()`
  - L201 `_close()`
  - L531 `_tabBtn()`
  - L564 `_angleDropdown()`
  - L598 `_categoryDropdown()`
  - L639 `_filterPill()`
  - L877 `_tagline()`
  - L906 `_buildVpDropdownWithGuide()`
  - L1542 `_angleLabel()`
  - L1552 `_angleHint()`
  - L1562 `_azimuthToCompass()`
  - L1737 `_showEventDetailDialog()`
  - L1769 `_showCategoryTipsIntent()`
  - L1809 `_showAngleDetailPopup()`
  - L1845 `_showPlanetAngleDetail()`

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


### `lib/screens/map/map_display_menu.dart` (409 行)

**imports:** dart=0 / package=1 / relative=4

- relative: `../../i18n/strings.g.dart`, `../../widgets/info_popup.dart`, `map_constants.dart`, `map_styles.dart`

**型定義 (6):**

- L28 `class MapDisplayMenu : StatefulWidget`
  - 左サイド ☰表示ボタンタップで右に展開するメニュー (2026-05-09)。
- L62 `enum _MainTab`
- L63 `enum _PlanetSub`
- L65 `class _MapDisplayMenuState : State`
- L341 `class _MenuInfoRow : StatelessWidget`
  - 説明 popup 用の項目行 (見出し + 本文)。
- L368 `class _ChipButton : StatelessWidget`
  - 共通のチップ風ボタン (active 状態で塗りつぶし変化)。

**関数 (5 public + 10 private):**

- L59 `createState()`
- L70 `build()`
- L236 `planetsName()`
- L347 `build()`
- L383 `build()`

  <details><summary>private 関数 10 件</summary>

  - L99 `_l2Buttons()`
  - L148 `_l3Buttons()`
  - L181 `_toggleSub()`
  - L189 `_tabBtn()`
  - L201 `_tabBtnWithInfo()`
  - L219 `_showTabInfo()`
  - L294 `_subTabBtn()`
  - L304 `_toggleBtn()`
  - L314 `_radioBtn()`
  - L324 `_scrollRow()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/map/map_fortune_sheet.dart` (750 行)

**imports:** dart=0 / package=1 / relative=6

- relative: `../../i18n/strings.g.dart`, `../../utils/direction_energy.dart`, `../../utils/solara_i18n.dart`, `../../widgets/info_popup.dart`, `map_constants.dart`, `map_direction_popup.dart`

**型定義 (4):**

- L17 `class FortuneFilterLabel : StatelessWidget`
  - HTML: .ff-label { top:52px; left:16px; inline-flex row: ff-tag + ff-bars }
- L195 `class FortuneSheet : StatelessWidget`
  - Fortune Sheet — HTML: .fs { bottom:80px; border-radius:16px 16px 0 0; }
- L718 `class _FortuneRowsList : StatefulWidget`
  - `RawScrollbar` と `ListView` で同じ `ScrollController` を共有する。
- L726 `class _FortuneRowsListState : State`

**関数 (8 public + 4 private):**

- L11 `pctValue()` — pct() from HTML: 0-5 → 0-83.3%, 5-10 → 83.3-100%
- L34 `build()`
- L220 `build()`
- L498 `showCategoryInfoPopup()` — Map の使い方 + カテゴリと関連惑星ペアの説明 popup。
- L511 `pair()`
- L723 `createState()`
- L730 `dispose()`
- L736 `build()`

  <details><summary>private 関数 4 件</summary>

  - L275 `_buildSrcTabs()`
  - L314 `_buildCatTabs()`
  - L350 `_legendChip()`
  - L373 `_buildFortuneRows()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/map/map_line_narrative_sheet.dart` (298 行)

**ファイル先頭コメント:**

```
══════════════════════════════════════════════════
Map Line Narrative Sheet
A*C*G ライン (natal / transit) のタップ詳細 popup。

構成:
  ① ヘッダー: 惑星 glyph + 名前 + ANGLE/Frame chip + 距離
  ② 静的セクション: 用語辞書 (aspect_lines / transit_acg) サマリ

設計思想: project_solara_design_philosophy.md (Soft/Hard 独立2エネルギー)

旧実装にあった Stella による線解説機能 (詳しく読むボタン → 動的生成) は
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
- L58 `class _MapLineNarrativeSheetState : State`

**関数 (3 public + 3 private):**

- L55 `createState()`
- L85 `build()`
- L280 `showLineNarrativeSheet()` — 共通呼び出しヘルパー: タップから直接 説明 popup を表示。

  <details><summary>private 関数 3 件</summary>

  - L111 `_buildConsultCta()`
  - L149 `_buildHeader()`
  - L233 `_buildStaticSection()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showLineNarrativeSheet`×1, `showInfoPopup`×1


### `lib/screens/map/map_location_markers.dart` (304 行)

**imports:** dart=0 / package=4 / relative=2

- relative: `../../utils/solara_storage.dart`, `map_vp_panel.dart`

**型定義 (3):**

- L25 `class BirthMarker : StatelessWidget`
  - 出生地マーカー: 🌟 + 多層グロー (静止)。
- L69 `class SlotMarker : StatelessWidget`
  - 通常スロット (VP / Locations) マーカー。
- L199 `class LocationMarkerPopup : StatelessWidget`
  - マーカータップ詳細 popup (画面下部の bottom sheet)。

**関数 (6 public + 1 private):**

- L29 `build()`
- L76 `build()`
- L132 `buildLocationMarkers()` — 登録地マーカー群を構築。
- L139 `Function()` — null 指定でタップを完全に透過する (排他モード用)。
- L143 `slotMarker()`
- L214 `build()`

  <details><summary>private 関数 1 件</summary>

  - L295 `_fmtCoord()`

  </details>


### `lib/screens/map/map_menu_chips.dart` (298 行)

**imports:** dart=0 / package=1 / relative=3

- relative: `../../theme/solara_colors.dart`, `../../widgets/category_icon.dart`, `../../widgets/dominant_fortune_overlay.dart`

**型定義 (6):**

- L12 `class MapMenuChips : StatelessWidget`
  - 下部チップバー (NavBar 直上、4 個: Daily / Fortune / Locations / Forecast)。
- L86 `class _ChipBody : StatelessWidget`
  - 全チップ共通の Container 外形 (高さ・border・gradient)。
- L114 `class _ChipColumn : StatelessWidget`
  - 全チップ共通の中身 (アイコン + ラベル縦並び)。
- L149 `class _StaticChip : StatelessWidget`
  - Daily 以外の通常チップ (Fortune / Locations / Forecast)。
- L187 `class _DailyTransitChip : StatelessWidget`
  - Daily Transit 専用チップ。
- L272 `class _ChipHalo : StatelessWidget`
  - チップの周囲に静的に描画する halo。

**関数 (6 public + 1 private):**

- L32 `build()`
- L98 `build()`
- L126 `build()`
- L157 `build()`
- L214 `build()`
- L276 `build()`

  <details><summary>private 関数 1 件</summary>

  - L197 `_buildIcon()`

  </details>


### `lib/screens/map/map_moon_notice.dart` (86 行)

**imports:** dart=0 / package=1 / relative=2

- relative: `../../theme/solara_colors.dart`, `../../utils/moon_event_status.dart`

**型定義 (1):**

- L11 `class MapMoonNotice : StatelessWidget`
  - Map 上部 (時刻スライダー直下) に出す月イベント案内バナー。

**関数 (1 public + 0 private):**

- L40 `build()`


### `lib/screens/map/map_overlays.dart` (487 行)

**imports:** dart=0 / package=3 / relative=2

- relative: `map_vp_panel.dart`, `map_widgets.dart`

**型定義 (9):**

- L48 `class MapSideButtons : StatelessWidget`
  - 左サイド縦並び 3 ボタン: 🔍 検索 / ☰ 表示 / 📍 地点 (2026-05-09 第二弾)。
- L125 `class SearchBarOverlay : StatefulWidget`
  - 検索バー（_searchOpen 時に最上部に表示）
- L141 `class _SearchBarOverlayState : State`
- L203 `class SearchVpChipRow : StatelessWidget`
  - 検索バー直上に出す VIEWPOINT (16方位基準) 選択チップ列。
- L282 `class _Chip : StatelessWidget`
- L326 `class SelectedDateBadge : StatelessWidget`
  - 選択日バッジ（地図左上に常時表示）
- L375 `class StatusBadge : StatelessWidget`
  - 右上のステータスバッジ（計算中・検索中）
- L402 `class VpPinVisual : StatelessWidget`
  - VP Pin (ドラッグ可能な中央の金色ピン) — 見た目のみ。
- L426 `class RestOverlay : StatelessWidget`
  - 休息オーバーレイ（🌙 + テキスト）

**関数 (13 public + 1 private):**

- L9 `buildVpPinMarker()` — VP Pin (ドラッグ可能な中央の金色ピン) の Marker を生成する。
- L67 `build()`
- L138 `createState()`
- L145 `initState()`
- L153 `dispose()`
- L159 `build()`
- L227 `build()`
- L289 `build()`
- L338 `build()`
- L380 `build()`
- L406 `build()`
- L432 `build()`
- L461 `showSolaraDatePicker()` — Solara テーマ適用の DatePicker を開く。選択されたら DateTime を返す（正午固定はしない）。

  <details><summary>private 関数 1 件</summary>

  - L220 `_isActive()`

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


### `lib/screens/map/map_relocation_popup.dart` (711 行)

**imports:** dart=0 / package=3 / relative=9

- relative: `../../utils/astro_glossary.dart`, `../../utils/astro_houses.dart`, `../../utils/astro_lines.dart`, `../../utils/solara_storage.dart`, `../../widgets/astro_term_label.dart`, `../horoscope/horo_constants.dart`, `../horoscope/horo_relocation_lines.dart`, `map_constants.dart`, `map_line_narrative_sheet.dart`

**型定義 (1):**

- L44 `class MapRelocationPopup : StatelessWidget`

**関数 (1 public + 14 private):**

- L109 `build()`

  <details><summary>private 関数 14 件</summary>

  - L188 `_buildConsultCta()`
  - L227 `_buildLineDeltaSection()`
  - L265 `_buildLinesSection()`
  - L308 `_buildLineRow()`
  - L382 `_openLineSheet()`
  - L399 `_buildTitleArea()`
  - L432 `_buildHeader()`
  - L526 `_buildAngleRow()`
  - L588 `_buildPlanetGrid()`
  - L597 `_buildPlanetRow()`
  - L685 `_recoverBaselineAsc()`
  - L690 `_signOf()`
  - L695 `_fmtCoord()`
  - L703 `_copyCoords()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showLineNarrativeSheet`×1


### `lib/screens/map/map_search.dart` (811 行)

**imports:** dart=2 / package=4 / relative=5

- relative: `../../utils/solara_api.dart`, `../../widgets/info_popup.dart`, `map_astro.dart`, `map_constants.dart`, `map_fortune_sheet.dart`

**型定義 (5):**

- L16 `class SearchHit`
  - 検索結果1件分
- L183 `class SearchResultList : StatelessWidget`
  - 検索結果リスト（スコア付き）ポップアップ
- L470 `class SearchFocusPopup : StatelessWidget`
  - 検索候補から1件選ばれたあとの詳細ポップアップ。
- L722 `class _CatChip : StatelessWidget`
- L747 `class _ActionTile : StatelessWidget`

**関数 (9 public + 8 private):**

- L52 `toJson()` — 画面復元 (Android プロセス死対策) 用シリアライズ。
- L81 `directionFrom()` — 中心座標から見たこの地点の方位（16方位名）
- L86 `distanceKmFrom()` — 中心から km 距離
- L159 `annotateHitsWithScores()` — 検索結果に、現在中心からの方位スコアと支配カテゴリを注入する
- L215 `build()`
- L512 `build()`
- L728 `build()`
- L753 `build()`
- L779 `googleMapsUrlForHit()` — 検索結果を Google マップで開く URL を組み立てる。

  <details><summary>private 関数 8 件</summary>

  - L91 `_bearingDeg()`
  - L100 `_azimuthToDir16()`
  - L106 `_haversineKm()`
  - L269 `_rankToggle()`
  - L290 `_rankSeg()`
  - L320 `_showRankHelp()`
  - L364 `_hitRow()`
  - L797 `_openInGoogleMaps()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


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


### `lib/screens/map/map_styles.dart` (190 行)

**imports:** dart=0 / package=4 / relative=2

- relative: `../../utils/solara_api.dart`, `../../utils/tile_http_client.dart`

**型定義 (2):**

- L16 `enum MapStyle`
  - マップスタイルの種類。LayerPanel から切替可。
- L33 `class MapStyleConfig`

**関数 (5 public + 0 private):**

- L80 `mapStyleFromId()` — id 文字列から MapStyle を復元。
- L99 `buildStyledTileLayer()` — 選択スタイルに応じた TileLayer を返す。
- L102 `Function()`
- L164 `buildOsmAttribution()` — 標準サイズの attribution (Map メイン画面・候補地ピッカー用)。
- L182 `buildOsmAttributionCompact()` — minimap (出生地入力等の小さい埋め込み地図) 用の常時表示版。


### `lib/screens/map/map_time_slider.dart` (495 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (2):**

- L17 `class MapTimeSlider : StatefulWidget`
  - ============================================================
- L39 `class MapTimeSliderState : State`
  - public State: GlobalKey 経由で map_screen.dart の PopScope から

**関数 (3 public + 20 private):**

- L34 `createState()`
- L45 `closeTimeRow()` — 時刻行が開いていれば閉じる。 開いていなければ何もしない。
- L235 `build()`

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
  - L196 `_stepMinute()`
  - L223 `_fmtDate()`
  - L230 `_fmtTime()`
  - L279 `_buildDayRow()`
  - L398 `_buildHourRow()`
  - L456 `_sliderTheme()`
  - L470 `_stepperBtn()`

  </details>


### `lib/screens/map/map_viewpoint_menu.dart` (623 行)

**imports:** dart=0 / package=2 / relative=4

- relative: `../../i18n/strings.g.dart`, `../../utils/solara_storage.dart`, `../../widgets/info_popup.dart`, `map_vp_panel.dart`

**型定義 (2):**

- L126 `class MapViewpointMenu : StatefulWidget`
  - 📍 地点ボタンタップで画面上部に展開するパネル (2026-05-09 第三弾)。
- L157 `class _MapViewpointMenuState : State`

**関数 (3 public + 12 private):**

- L147 `createState()`
- L173 `initState()`
- L220 `build()`

  <details><summary>private 関数 12 件</summary>

  - L11 `_showViewpointHelpPopup()`
  - L178 `_loadAll()`
  - L193 `_reload()`
  - L207 `_saveCurrent()`
  - L327 `_tabBtn()`
  - L364 `_actionBtn()`
  - L396 `_buildSlotList()`
  - L414 `_buildSlotRow()`
  - L468 `_buildSubMenu()`
  - L498 `_subItem()`
  - L531 `_showIconPickerDialog()`
  - L583 `_showRenameDialog()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/map/map_vp_panel.dart` (140 行)

**imports:** dart=1 / package=2 / relative=3

- relative: `../../utils/pro_status.dart`, `../../utils/reverse_geocode.dart`, `../../utils/solara_storage.dart`

**型定義 (2):**

- L18 `class VPSlot`
  - スロット1件分のデータ
- L41 `class SlotManager`
  - HTML: SlotManager — SharedPreferencesでスロットを永続化

**関数 (8 public + 0 private):**

- L27 `toJson()`
- L62 `save()`
- L68 `syncHome()` — HTML: syncHome — プロフィールのホーム地点を先頭スロットに同期
- L88 `saveCurrentLocation()` — HTML: saveCurrentLocation — reverse geocodingで地名取得して保存
- L111 `moveSlot()`
- L120 `renameSlot()`
- L127 `deleteSlot()`
- L134 `changeIcon()`


### `lib/screens/map/map_welcome_banner.dart` (156 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (2):**

- L4 `enum WelcomeBannerMode`
  - Map 画面のウェルカム特典バナーの種類。
- L23 `class MapWelcomeBanner : StatelessWidget`
  - Map 上部に出すウェルカム特典バナー (B/C 共通)。

**関数 (1 public + 0 private):**

- L36 `build()`


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


### `lib/screens/map_screen.dart` (3625 行)

**imports:** dart=2 / package=6 / relative=45

- relative: `../i18n/strings.g.dart`, `../utils/solara_api.dart`, `../utils/solara_storage.dart`, `../utils/tile_http_client.dart`, `../widgets/dominant_fortune_overlay.dart`, `../widgets/info_popup.dart`, `../widgets/tap_to_unfocus.dart`, `map/map_daily_transit_screen.dart`, `map/consult_entry_popup.dart`, `map/map_constants.dart`, `map/map_styles.dart`, `map/map_sectors.dart`, `map/map_fortune_sheet.dart`, `map/map_vp_panel.dart`, `map/map_menu_chips.dart`, `map/map_display_menu.dart`, `map/map_viewpoint_menu.dart`, `map/map_astro.dart`, `map/map_astro_carto.dart`, `map/map_astro_lines.dart`, `map/map_location_markers.dart`, `map/map_planet_intro_popup.dart`, `map/map_planet_lines.dart`, `map/map_relocation_popup.dart`, `map/map_search.dart`, `horoscope/horo_relocation_lines.dart`, `map/map_overlays.dart`, `map/map_time_slider.dart`, `map/map_widgets.dart`, `map/map_welcome_banner.dart`, `map/map_moon_notice.dart`, `../utils/astro_lines.dart`, `../utils/moon_event_status.dart`, `../utils/consultation_api.dart`, `../utils/consultation_credits.dart`, `../utils/direction_energy.dart`, `../utils/pro_status.dart`, `../utils/reverse_geocode.dart`, `../utils/solara_auth.dart`, `../widgets/pro_unlock_dialog.dart`, `consultation/consultation_input_screen.dart`, `consultation/consultation_return_chip.dart`, `forecast_screen.dart`, `horoscope/horo_antique_icons.dart`, `locations_screen.dart`

**型定義 (2):**

- L84 `class MapScreen : StatefulWidget`
- L94 `class MapScreenState : State`

**関数 (11 public + 67 private):**

- L91 `createState()`
- L399 `initState()`
- L437 `dispose()`
- L621 `reloadProfile()` — 外部（main.dart のタブ切替）から呼ばれる公開リロード。
- L655 `restoreMapState()` — captureMapRestore のスナップショットを復元する (コールド起動時)。
- L722 `focusLocationAndDate()` — 相談結果カードの🗺ボタンから呼ばれる: 視点 (VIEWPOINT/_center) を [pos] へ移動
- L1636 `snack()`
- L1804 `snack()`
- L1849 `build()`
- L3057 `signOf()`
- L3280 `showMoonNotice()` — C: main.dart から月イベント保留状態を受け取る (GlobalKey 命令呼び出し)。

  <details><summary>private 関数 67 件</summary>

  - L408 `_bootstrap()`
  - L452 `_warmupTileConnection()`
  - L487 `_onTileError()`
  - L514 `_checkDailyBadgeState()`
  - L544 `_recomputeDailyChipCategoryIfNeeded()`
  - L607 `_loadMapStyle()`
  - L613 `_onMapStyleChanged()`
  - L662 `_applySearchPartFromPending()`
  - L672 `_applyUiRestoreFromPending()`
  - L695 `_applySearchRestore()`
  - L743 `_scheduleLoadChart()`
  - L755 `_moveToInitialCenter()`
  - L763 `_loadProfileAndChart()`
  - L952 `_cycleActiveCategory()`
  - L979 `_reannotateSearchResults()`
  - L1011 `_showSheet()`
  - L1031 `_openLocations()`
  - L1054 `_openForecast()`
  - L1077 `_onDisplayMenuTap()`
  - L1087 `_onViewpointMenuTap()`
  - L1101 `_onSearchTap()`
  - L1115 `_clearAllSearch()`
  - L1132 `_onDailyBadgeTap()`
  - L1181 `_onOverlayComplete()`
  - L1203 `_onDailyTransitClose()`
  - L1217 `_doSearch()`
  - L1276 `_changeSearchRank()`
  - L1315 `_frameSearchArea()`
  - L1341 `_restoreSearchListView()`
  - L1351 `_selectSearchHit()`
  - L1381 `_buildFocusedHitMarker()`
  - L1423 `_buildSearchHitMarkers()`
  - L1496 `_displayScores()`
  - L1557 `_sectorRankAlphaMul()`
  - L1575 `_rebuild()`
  - L1609 `_kickPaintInvalidation()`
  - L1623 `_setVpOnly()`
  - L1635 `_setVpToCurrentLocationOnly()`
  - L1680 `_enterAstroCartoMode()`
  - L1755 `_exitAstroCartoMode()`
  - L1803 `_geolocate()`
  - L1921 `_buildBody()`
  - L3005 `_buildZenithPopup()`
  - L3024 `_buildRelocationPopup()`
  - L3105 `_isProGatedBandKey()`
  - L3109 `_proLabelForAstroKey()`
  - L3122 `_proDescForAstroKey()`
  - L3140 `_onAstroToggle()`
  - L3169 `_enterConsultationFromDaily()`
  - L3197 `_enterConsultationFromMapButton()`
  - L3216 `_evaluateWelcomeGift()`
  - L3252 `_onWelcomeCta()`
  - L3269 `_onWelcomeDismiss()`
  - L3297 `_dismissMoonNotice()`
  - L3312 `_launchConsultation()`
  - L3360 `_launchConsultationFromSearch()`
  - L3394 `_reloadLocationSlots()`
  - L3418 `_nearestNatalConjunctions()`
  - L3439 `_findNearbyAstroLines()`
  - L3457 `_zenithMarkerFrames()`
  - L3458 `_nadirMarkerFrames()`
  - L3459 `_zenithBandFrames()`
  - L3460 `_nadirBandFrames()`
  - L3464 `_filteredFrames()`
  - L3477 `_visibleAstroLines()`
  - L3505 `_buildNoProfileGuide()`
  - L3544 `_showSearchVpHelpPopup()`

  </details>

**Popup/Dialog 呼出 (3):**

- 集計: `showModalBottomSheet`×1, `showLineNarrativeSheet`×1, `showInfoPopup`×1

