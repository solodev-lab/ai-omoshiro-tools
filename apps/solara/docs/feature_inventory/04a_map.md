# 層 4a: Map 画面

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 23 / 総行数: 13293
- class/mixin/extension/enum: 86
- 関数 (top-level + method の素拾い): 288
- Navigator.push 等: 0
- Popup/Dialog 呼出: 18
- Worker URL リテラル: 4

## ファイル別

### `lib/screens/map/consult_entry_popup.dart` (292 行)

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

**imports:** dart=0 / package=2 / relative=4

- relative: `../../theme/solara_colors.dart`, `../../utils/astro_lines.dart`, `../../utils/reverse_geocode.dart`, `map_constants.dart`

**型定義 (3):**

- L33 `class ConsultEntryPopup : StatefulWidget`
- L60 `class _ConsultEntryPopupState : State`
- L239 `class _NearestLineRow : StatelessWidget`

**関数 (4 public + 1 private):**

- L57 `createState()`
- L67 `initState()`
- L103 `build()`
- L244 `build()`

  <details><summary>private 関数 1 件</summary>

  - L72 `_resolveName()`

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


### `lib/screens/map/map_astro_carto.dart` (868 行)

**imports:** dart=0 / package=2 / relative=6

- relative: `../../utils/astro_glossary.dart`, `../../utils/astro_lines.dart`, `../../utils/astro_zenith_messages.dart`, `../../widgets/info_popup.dart`, `map_astro_lines.dart`, `map_constants.dart`

**型定義 (9):**

- L28 `class AstroCartoBanner : StatelessWidget`
  - Astro*Carto*Graphy モード中の上部バナー (タイトル + 閉じる×)。
- L250 `class AcgFrameDef`
- L293 `class AstroCartoFramePills : StatelessWidget`
  - 第1層: フレーム切替ピル (横並び 4 ピル + i)。
- L360 `class AstroCartoSubPills : StatelessWidget`
  - 第2層: active frame のサブトグル 4 つ (横並び)。
- L399 `class _FramePill : StatelessWidget`
  - 第1層の個別ピル (ラベル + i)。active 時はリング glow で強調。
- L468 `class _SubPill : StatelessWidget`
  - 第2層の個別小ピル (天頂 / 天底 / 天頂帯 / 天底帯)。
- L535 `class _ScrollableRowPanel : StatelessWidget`
  - ピル列の overflow 対策ラッパー。
- L570 `class AstroCartoCategoryPills : StatelessWidget`
  - Astro*Carto*Graphy モード中のカテゴリピル。
- L643 `class AstroZenithPopup : StatelessWidget`
  - 天頂・天底点タップ詳細 popup。

**関数 (8 public + 1 private):**

- L33 `build()`
- L306 `build()`
- L373 `build()`
- L416 `build()`
- L483 `build()`
- L546 `build()`
- L580 `build()`
- L666 `build()`

  <details><summary>private 関数 1 件</summary>

  - L94 `_showAcgUsageGuide()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/screens/map/map_astro_lines.dart` (616 行)

**imports:** dart=0 / package=3 / relative=3

- relative: `../../theme/solara_colors.dart`, `../../utils/astro_lines.dart`, `map_constants.dart`

**型定義 (4):**

- L33 `class _AngleStyle`
- L59 `class AstroFrameStyle`
  - フレーム別の視覚プリセット。Tier A #5 で4フレーム同時描画する際の
- L414 `class AstroNadirMarker : StatelessWidget`
  - 装飾的な天底点マーカー (Lewis 理論: 裏側に在る天体)。
- L522 `class AstroZenithMarker : StatelessWidget`
  - 装飾的な天頂点マーカー (frame で見た目を切替):

**関数 (8 public + 3 private):**

- L133 `buildAstroPolylines()` — アストロラインを Polyline[] に変換。
- L221 `buildAstroLatitudeBandPolylines()` — 天頂帯・天底帯 (latitude bands) の緯度線を Polyline[] に変換する。
- L298 `buildAstroZenithMarkers()` — 各惑星の天頂点 (= AstroLine.zenith) に装飾マーカーを生成。
- L303 `Function()`
- L360 `buildAstroNadirMarkers()` — 各惑星の天底点 (= AstroLine.nadir) に装飾マーカーを生成。
- L365 `Function()`
- L435 `build()`
- L535 `build()`

  <details><summary>private 関数 3 件</summary>

  - L105 `_lerpColor()`
  - L119 `_aspectEnergyColor()`
  - L203 `_latitudePolylinePoints()`

  </details>


### `lib/screens/map/map_daily_transit_screen.dart` (1923 行)

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

**imports:** dart=0 / package=2 / relative=11

- relative: `../../theme/solara_colors.dart`, `../../utils/astro_glossary.dart`, `../../utils/daily_transits_api.dart`, `../../widgets/category_icon.dart`, `../../widgets/dominant_fortune_overlay.dart`, `../../widgets/glass_panel.dart`, `../../widgets/info_popup.dart`, `daily_transit_data.dart`, `map_aspect_chip.dart`, `map_constants.dart`, `map_vp_panel.dart`

**型定義 (15):**

- L28 `class MapDailyTransitScreen : StatefulWidget`
- L75 `enum _DayTab`
  - タブ識別子。
- L79 `class _MapDailyTransitScreenState : State`
- L267 `class _FooterActions : StatelessWidget`
  - Daily Transit popup 下部の動線フッター。
- L325 `class _FooterButton : StatelessWidget`
  - フッター内の 1 つのアクションボタン (絵文字 + タイトル + サブタイトル)。
- L428 `class _DayTabBar : StatelessWidget`
- L645 `class _Header : StatelessWidget`
- L898 `class _CategoryTipsBox : StatelessWidget`
- L1071 `class _LoadingBody : StatelessWidget`
- L1101 `class _FailedBody : StatelessWidget`
- L1146 `class _TimelineBody : StatelessWidget`
- L1246 `class _TimelineRow : StatelessWidget`
- L1473 `class _AltitudeBadge : StatelessWidget`
  - L3 Lewis 高度バッジ。
- L1524 `class _LatitudeBandBox : StatelessWidget`
  - L3 Lewis 緯度帯ボックス。
- L1574 `class _LatitudeBandRow : StatelessWidget`

**関数 (20 public + 20 private):**

- L71 `createState()`
- L124 `initState()`
- L137 `dispose()`
- L201 `build()`
- L277 `build()`
- L341 `build()`
- L446 `build()`
- L665 `build()`
- L805 `labelFor()`
- L814 `iconFor()`
- L820 `itemRow()`
- L908 `build()`
- L1074 `build()`
- L1105 `build()`
- L1161 `build()`
- L1263 `build()`
- L1479 `build()`
- L1529 `build()`
- L1581 `build()`
- L1810 `showDailyUsageGuidePopup()` — 「今日の動き」画面の使い方 popup。

  <details><summary>private 関数 20 件</summary>

  - L112 `_cacheKey()`
  - L118 `_resolveInitialVpIndex()`
  - L144 `_tabStartTime()`
  - L151 `_loadTab()`
  - L180 `_selectTab()`
  - L187 `_selectVp()`
  - L194 `_close()`
  - L523 `_tabBtn()`
  - L556 `_angleDropdown()`
  - L590 `_categoryDropdown()`
  - L631 `_filterPill()`
  - L774 `_tagline()`
  - L803 `_buildVpDropdownWithGuide()`
  - L1434 `_angleLabel()`
  - L1444 `_angleHint()`
  - L1454 `_azimuthToCompass()`
  - L1631 `_showEventDetailDialog()`
  - L1663 `_showCategoryTipsIntent()`
  - L1703 `_showAngleDetailPopup()`
  - L1739 `_showPlanetAngleDetail()`

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


### `lib/screens/map/map_display_menu.dart` (413 行)

**imports:** dart=0 / package=1 / relative=3

- relative: `../../widgets/info_popup.dart`, `map_constants.dart`, `map_styles.dart`

**型定義 (6):**

- L27 `class MapDisplayMenu : StatefulWidget`
  - 左サイド ☰表示ボタンタップで右に展開するメニュー (2026-05-09)。
- L61 `enum _MainTab`
- L62 `enum _PlanetSub`
- L64 `class _MapDisplayMenuState : State`
- L345 `class _MenuInfoRow : StatelessWidget`
  - 説明 popup 用の項目行 (見出し + 本文)。
- L372 `class _ChipButton : StatelessWidget`
  - 共通のチップ風ボタン (active 状態で塗りつぶし変化)。

**関数 (5 public + 10 private):**

- L58 `createState()`
- L69 `build()`
- L235 `planetsJp()`
- L351 `build()`
- L387 `build()`

  <details><summary>private 関数 10 件</summary>

  - L98 `_l2Buttons()`
  - L147 `_l3Buttons()`
  - L180 `_toggleSub()`
  - L188 `_tabBtn()`
  - L200 `_tabBtnWithInfo()`
  - L218 `_showTabInfo()`
  - L298 `_subTabBtn()`
  - L308 `_toggleBtn()`
  - L318 `_radioBtn()`
  - L328 `_scrollRow()`

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


### `lib/screens/map/map_relocation_popup.dart` (617 行)

**imports:** dart=0 / package=2 / relative=7

- relative: `../../utils/astro_glossary.dart`, `../../utils/astro_houses.dart`, `../../utils/astro_lines.dart`, `../../widgets/astro_term_label.dart`, `../horoscope/horo_constants.dart`, `map_constants.dart`, `map_line_narrative_sheet.dart`

**型定義 (1):**

- L40 `class MapRelocationPopup : StatelessWidget`

**関数 (1 public + 12 private):**

- L99 `build()`

  <details><summary>private 関数 12 件</summary>

  - L168 `_buildConsultCta()`
  - L205 `_buildLinesSection()`
  - L248 `_buildLineRow()`
  - L322 `_openLineSheet()`
  - L339 `_buildTitleArea()`
  - L372 `_buildHeader()`
  - L443 `_buildAngleRow()`
  - L505 `_buildPlanetGrid()`
  - L514 `_buildPlanetRow()`
  - L602 `_recoverBaselineAsc()`
  - L607 `_signOf()`
  - L612 `_fmtCoord()`

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


### `lib/screens/map/map_time_slider.dart` (508 行)

**imports:** dart=0 / package=1 / relative=2

- relative: `../../utils/pro_status.dart`, `../../widgets/pro_unlock_dialog.dart`

**型定義 (2):**

- L20 `class MapTimeSlider : StatefulWidget`
  - ============================================================
- L42 `class MapTimeSliderState : State`
  - public State: GlobalKey 経由で map_screen.dart の PopScope から

**関数 (3 public + 21 private):**

- L37 `createState()`
- L48 `closeTimeRow()` — 時刻行が開いていれば閉じる。 開いていなければ何もしない。
- L229 `build()`

  <details><summary>private 関数 21 件</summary>

  - L55 `_setTimeRowExpanded()`
  - L73 `_committedDays()`
  - L84 `_committedHourJst()`
  - L92 `_committedMinuteJst()`
  - L103 `_displayMinuteJst()`
  - L111 `_previewDateJst()`
  - L122 `_commitDays()`
  - L141 `_commitHour()`
  - L151 `_commitDayShiftAndTime()`
  - L161 `_isLive()`
  - L164 `_isLiveHour()`
  - L171 `_stepDay()`
  - L178 `_stepHour()`
  - L194 `_stepMinute()`
  - L217 `_fmtDate()`
  - L224 `_fmtTime()`
  - L273 `_buildDayRow()`
  - L392 `_buildHourRow()`
  - L456 `_stepMinuteFine()`
  - L469 `_sliderTheme()`
  - L483 `_stepperBtn()`

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


### `lib/screens/map_screen.dart` (3020 行)

**imports:** dart=2 / package=6 / relative=35

- relative: `../utils/solara_api.dart`, `../utils/solara_storage.dart`, `../utils/tile_http_client.dart`, `../widgets/dominant_fortune_overlay.dart`, `../widgets/info_popup.dart`, `map/map_daily_transit_screen.dart`, `map/consult_entry_popup.dart`, `map/map_constants.dart`, `map/map_styles.dart`, `map/map_sectors.dart`, `map/map_fortune_sheet.dart`, `map/map_vp_panel.dart`, `map/map_menu_chips.dart`, `map/map_display_menu.dart`, `map/map_viewpoint_menu.dart`, `map/map_astro.dart`, `map/map_astro_carto.dart`, `map/map_astro_lines.dart`, `map/map_location_markers.dart`, `map/map_planet_intro_popup.dart`, `map/map_planet_lines.dart`, `map/map_relocation_popup.dart`, `map/map_search.dart`, `map/map_overlays.dart`, `map/map_time_slider.dart`, `map/map_widgets.dart`, `../utils/astro_lines.dart`, `../utils/direction_energy.dart`, `../utils/pro_status.dart`, `../utils/reverse_geocode.dart`, `../widgets/pro_unlock_dialog.dart`, `consultation/consultation_input_screen.dart`, `forecast_screen.dart`, `horoscope/horo_antique_icons.dart`, `locations_screen.dart`

**型定義 (2):**

- L74 `class MapScreen : StatefulWidget`
- L84 `class MapScreenState : State`

**関数 (8 public + 54 private):**

- L81 `createState()`
- L333 `initState()`
- L371 `dispose()`
- L479 `reloadProfile()` — 外部（main.dart のタブ切替）から呼ばれる公開リロード。
- L1292 `snack()`
- L1464 `snack()`
- L1510 `build()`
- L2552 `signOf()`

  <details><summary>private 関数 54 件</summary>

  - L342 `_bootstrap()`
  - L385 `_warmupTileConnection()`
  - L420 `_onTileError()`
  - L447 `_checkDailyBadgeState()`
  - L465 `_loadMapStyle()`
  - L471 `_onMapStyleChanged()`
  - L486 `_moveToInitialCenter()`
  - L494 `_loadProfileAndChart()`
  - L671 `_cycleActiveCategory()`
  - L698 `_reannotateSearchResults()`
  - L730 `_showSheet()`
  - L750 `_openLocations()`
  - L767 `_openForecast()`
  - L786 `_onDisplayMenuTap()`
  - L796 `_onViewpointMenuTap()`
  - L810 `_onSearchTap()`
  - L824 `_clearAllSearch()`
  - L841 `_onDailyBadgeTap()`
  - L888 `_onOverlayComplete()`
  - L898 `_onDailyTransitClose()`
  - L910 `_doSearch()`
  - L971 `_frameSearchArea()`
  - L997 `_restoreSearchListView()`
  - L1007 `_selectSearchHit()`
  - L1037 `_buildFocusedHitMarker()`
  - L1079 `_buildSearchHitMarkers()`
  - L1152 `_displayScores()`
  - L1213 `_sectorRankAlphaMul()`
  - L1231 `_rebuild()`
  - L1265 `_kickPaintInvalidation()`
  - L1279 `_setVpOnly()`
  - L1291 `_setVpToCurrentLocationOnly()`
  - L1337 `_enterAstroCartoMode()`
  - L1415 `_exitAstroCartoMode()`
  - L1463 `_geolocate()`
  - L1575 `_buildBody()`
  - L2513 `_buildZenithPopup()`
  - L2532 `_buildRelocationPopup()`
  - L2597 `_proLabelForAstroKey()`
  - L2615 `_proDescForAstroKey()`
  - L2641 `_onAstroToggle()`
  - L2670 `_enterConsultationFromDaily()`
  - L2717 `_launchConsultation()`
  - L2781 `_reloadLocationSlots()`
  - L2805 `_nearestNatalConjunctions()`
  - L2826 `_findNearbyAstroLines()`
  - L2844 `_zenithMarkerFrames()`
  - L2845 `_nadirMarkerFrames()`
  - L2846 `_zenithBandFrames()`
  - L2847 `_nadirBandFrames()`
  - L2851 `_filteredFrames()`
  - L2864 `_visibleAstroLines()`
  - L2892 `_buildNoProfileGuide()`
  - L2926 `_showSearchVpHelpPopup()`

  </details>

**Popup/Dialog 呼出 (2):**

- 集計: `showLineNarrativeSheet`×1, `showInfoPopup`×1

**Worker URL リテラル (1):**

- L391: `'$solaraWorkerBase/tiles/osm/hot/0/0/0.png'`

