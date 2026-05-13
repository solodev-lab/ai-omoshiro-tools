# 層 3a: 共通ウィジェット (純粋)

> このファイルは `apps/solara/tools/feature_extractor/extract.py` が自動生成。
> 手で編集しても次の再生成で上書きされる。

## サマリ

- ファイル数: 22 / 総行数: 5612
- class/mixin/extension/enum: 65
- 関数 (top-level + method の素拾い): 140
- Navigator.push 等: 0
- Popup/Dialog 呼出: 3
- Worker URL リテラル: 0

## ファイル別

### `lib/widgets/astro_term_label.dart` (85 行)

**imports:** dart=0 / package=1 / relative=1

- relative: `../utils/astro_glossary.dart`

**型定義 (1):**

- L19 `class AstroTermLabel : StatelessWidget`
  - ============================================================

**関数 (1 public + 0 private):**

- L47 `build()`


### `lib/widgets/category_icon.dart` (80 行)

**ファイル先頭コメント:**

```
============================================================
CategoryIcon — Solara カテゴリアイコン

2026-05-10: ベクター CustomPaint (Style D) → アンティーク神秘画 (Gemini 生成
WebP) に置換。assets/menu_icons/{kind}.webp を Image.asset で表示。

7カテゴリ + 未開封 + 3メニュー (運勢方位/LOCATION/予報) で計 10 枚。
  - all          : 4芒星 + 12方位tick (純金、汎用 / トップ未確定時)
  - love (恋愛)   : ♀ Venus + 薔薇蔓 (dusty rose)
  - money (豊かさ): ♃ Jupiter + 月桂樹 (muted amber)
  - work (仕事)   : ♄ Saturn + 環 + masonic compass (slate-blue)
  - healing (癒し): ☽ Moon + 8月相 + 麦穂 (silver-blue)
  - communication : ☿ Mercury + 翼 + 蛇 (verdigris)

Daily 未開封チップは `unsealed.webp` を別アセット名で使う (kind 不要)。
旧 _CategoryIconPainter (CustomPaint ベクター描画) は git history で復元可能。
============================================================
```

**imports:** dart=0 / package=1 / relative=1

- relative: `dominant_fortune_overlay.dart`

**型定義 (4):**

- L22 `enum CategoryIconKind`
- L24 `extension DominantFortuneKindToCategoryIcon : DominantFortuneKind`
- L36 `extension _CategoryIconKindAsset : CategoryIconKind`
- L56 `class CategoryIcon : StatelessWidget`
  - カテゴリ別アンティークアイコン (Gemini 生成 WebP)。

**関数 (2 public + 0 private):**

- L25 `toCategoryIcon()`
- L71 `build()`


### `lib/widgets/celestial_event_bar.dart` (129 行)

**imports:** dart=0 / package=1 / relative=4

- relative: `../utils/celestial_events.dart`, `../utils/celestial_event_meanings.dart`, `../theme/solara_colors.dart`, `info_popup.dart`

**型定義 (1):**

- L9 `class CelestialEventBar : StatelessWidget`
  - Cycle画面下部に常時表示する天体イベント横スクロールバー

**関数 (1 public + 3 private):**

- L24 `build()`

  <details><summary>private 関数 3 件</summary>

  - L39 `_buildChip()`
  - L71 `_showMeaning()`
  - L118 `_typeLabel()`

  </details>

**Popup/Dialog 呼出 (1):**

- 集計: `showInfoPopup`×1


### `lib/widgets/class_card.dart` (306 行)

**imports:** dart=0 / package=1 / relative=1

- relative: `../utils/title_data.dart`

**型定義 (2):**

- L13 `class ClassCard : StatelessWidget`
  - Solara クラスカード表示ウィジェット
- L297 `enum ClassCardMode`
  - ClassCard のオーバーレイ表示モード

**関数 (1 public + 2 private):**

- L72 `build()`

  <details><summary>private 関数 2 件</summary>

  - L145 `_buildOverlay()`
  - L262 `_buildPlaceholder()`

  </details>


### `lib/widgets/constellation_painter.dart` (249 行)

**imports:** dart=2 / package=1 / relative=2

- relative: `../models/galaxy_cycle.dart`, `../utils/constellation_namer.dart`

**型定義 (2):**

- L14 `class ConstellationPainter : CustomPainter`
  - Full-size constellation painter for replay overlay (v2: anamorphic 3D).
- L168 `class MiniConstellationPainter : CustomPainter`
  - Small constellation painter for Star Atlas grid cards.

**関数 (4 public + 1 private):**

- L32 `paint()`
- L158 `shouldRepaint()`
- L176 `paint()`
- L247 `shouldRepaint()`

  <details><summary>private 関数 1 件</summary>

  - L152 `_depthScale()`

  </details>


### `lib/widgets/cycle_spiral_painter.dart` (396 行)

**imports:** dart=2 / package=1 / relative=4

- relative: `../models/daily_reading.dart`, `../theme/solara_colors.dart`, `../utils/moon_phase.dart`, `../utils/tarot_data.dart`

**型定義 (5):**

- L14 `class CycleSpiralPainter : CustomPainter`
  - HTML: galaxy.html renderSpiral3D() — 3-layer spiral painter
- L368 `class _Vec3`
- L373 `class _SpiralDot`
- L379 `class _GADot`
- L386 `class _Mulberry32`
  - HTML: mulberry32 PRNG — deterministic seeded random for z-jitter

**関数 (4 public + 4 private):**

- L51 `paint()`
- L342 `hitTestDot()` — Hit-test for tap on spiral dots. Returns dayIndex or -1.
- L356 `shouldRepaint()`
- L389 `next()`

  <details><summary>private 関数 4 件</summary>

  - L128 `_drawBackgroundStars()`
  - L167 `_drawGhostPath()`
  - L200 `_drawGADot()`
  - L312 `_drawStellaCore()`

  </details>


### `lib/widgets/fortune_overlays/_common.dart` (40 行)

**imports:** dart=1 / package=1 / relative=0

**型定義 (1):**

- L5 `class FortunePainterBuilder`
  - 各演出の共通ビルダー。1度生成した粒子を使い回す。

**関数 (5 public + 0 private):**

- L6 `buildPainter()`
- L10 `easeOutCubic()` — イージング: 減速
- L16 `easeOutBack()` — イージング: バウンドつき出現
- L24 `easeInOutQuad()` — イージング: 二次イーズインアウト
- L30 `stageAlpha()` — 3段階αカーブ: fadeIn / hold / fadeOut


### `lib/widgets/fortune_overlays/communication_painter.dart` (642 行)

**imports:** dart=2 / package=1 / relative=1

- relative: `_common.dart`

**型定義 (7):**

- L9 `class CommunicationPainterBuilder : FortunePainterBuilder`
  - 話す（Solara風）: ルーン文字・占星術記号・ラテン語片が羊皮紙の上を
- L174 `class _NotePair`
- L199 `class _Note`
- L212 `class _Stream`
- L222 `class _Spark`
- L232 `class _Sparkle`
- L241 `class _CommunicationPainter : CustomPainter`

**関数 (3 public + 15 private):**

- L32 `buildPainter()`
- L270 `paint()`
- L641 `shouldRepaint()`

  <details><summary>private 関数 15 件</summary>

  - L37 `_buildPairs()`
  - L83 `_buildChaoticNotes()`
  - L120 `_buildStreams()`
  - L137 `_buildSparks()`
  - L156 `_buildSparkles()`
  - L261 `_hueColor()`
  - L304 `_drawPair()`
  - L338 `_drawOrbitTrail()`
  - L350 `_drawCollisionFlash()`
  - L420 `_drawPairNote()`
  - L427 `_drawChaoticNote()`
  - L445 `_paintNote()`
  - L517 `_drawStream()`
  - L576 `_drawSpark()`
  - L603 `_drawSparkle()`

  </details>


### `lib/widgets/fortune_overlays/healing_painter.dart` (498 行)

**imports:** dart=2 / package=1 / relative=1

- relative: `_common.dart`

**型定義 (6):**

- L8 `class HealingPainterBuilder : FortunePainterBuilder`
  - 癒し（Solara風）: 月桂樹とオリーブの葉が下から上へ螺旋で舞い上がり、
- L123 `class _PetalPalette`
- L131 `class _Petal`
- L152 `class _LightMote`
- L165 `class _Sparkle`
- L174 `class _HealingPainter : CustomPainter`

**関数 (3 public + 10 private):**

- L25 `buildPainter()`
- L203 `paint()`
- L497 `shouldRepaint()`

  <details><summary>private 関数 10 件</summary>

  - L29 `_buildPetals()`
  - L86 `_buildMotes()`
  - L106 `_buildSparkles()`
  - L193 `_greenHue()`
  - L234 `_drawAuroraBand()`
  - L264 `_spiralPos()`
  - L298 `_drawPetal()`
  - L412 `_buildPetalPath()`
  - L424 `_drawMote()`
  - L460 `_drawSparkle()`

  </details>


### `lib/widgets/fortune_overlays/love_painter.dart` (581 行)

**imports:** dart=2 / package=1 / relative=1

- relative: `_common.dart`

**型定義 (7):**

- L8 `class LovePainterBuilder : FortunePainterBuilder`
  - 恋愛（Solara風）: 中心に金の魔法陣が開き、そこから薔薇の花弁が放射状に舞い散る。
- L140 `class _PetalPalette`
- L148 `class _RosePetal`
- L162 `class _Sparkle`
- L171 `class _Ray`
- L176 `class _Vine`
- L187 `class _LovePainter : CustomPainter`

**関数 (3 public + 10 private):**

- L28 `buildPainter()`
- L204 `paint()`
- L580 `shouldRepaint()`

  <details><summary>private 関数 10 件</summary>

  - L32 `_buildPetals()`
  - L94 `_buildSparkles()`
  - L111 `_buildRays()`
  - L123 `_buildVines()`
  - L236 `_drawGodRays()`
  - L261 `_drawSigil()`
  - L345 `_drawVine()`
  - L416 `_drawRosePetal()`
  - L525 `_buildPetalPath()`
  - L538 `_drawSparkle()`

  </details>


### `lib/widgets/fortune_overlays/money_painter.dart` (693 行)

**imports:** dart=2 / package=1 / relative=1

- relative: `_common.dart`

**型定義 (6):**

- L8 `class MoneyPainterBuilder : FortunePainterBuilder`
  - 金運: 金貨・金箔が上から降ってきて画面下に積み上がる（落ち物ゲーム風）。
- L165 `class _GoldPalette`
- L173 `class _GoldPiece`
- L198 `class _GoldDust`
- L209 `class _Sparkle`
- L217 `class _MoneyPainter : CustomPainter`

**関数 (3 public + 10 private):**

- L26 `buildPainter()`
- L230 `paint()`
- L692 `shouldRepaint()`

  <details><summary>private 関数 10 件</summary>

  - L30 `_buildPieces()`
  - L130 `_buildDust()`
  - L149 `_buildSparkles()`
  - L282 `_pileGlowIntensity()`
  - L287 `_drawPiece()`
  - L386 `_drawCoin()`
  - L542 `_drawFlake()`
  - L617 `_drawDust()`
  - L652 `_drawSparkle()`
  - L688 `_easeInQuart()`

  </details>


### `lib/widgets/fortune_overlays/work_painter.dart` (758 行)

**imports:** dart=2 / package=1 / relative=1

- relative: `_common.dart`

**型定義 (7):**

- L9 `class WorkPainterBuilder : FortunePainterBuilder`
  - 仕事（Solara風）: 金の勲章 medallion が次々と画面に現れ、軽やかに回転し漂う。
- L152 `class _MedalPalette`
- L161 `class _Medallion`
- L178 `class _Gear`
- L188 `class _GoldDust`
- L203 `class _Sparkle`
- L212 `class _WorkPainter : CustomPainter`

**関数 (3 public + 11 private):**

- L29 `buildPainter()`
- L236 `paint()`
- L757 `shouldRepaint()`

  <details><summary>private 関数 11 件</summary>

  - L33 `_buildMedallions()`
  - L96 `_buildGears()`
  - L115 `_buildDust()`
  - L135 `_buildSparkles()`
  - L272 `_drawGear()`
  - L341 `_drawFinalMoment()`
  - L467 `_drawMedallion()`
  - L522 `_paintMedalBody()`
  - L672 `_octagonPath()`
  - L690 `_drawDust()`
  - L719 `_drawSparkle()`

  </details>


### `lib/widgets/glass_panel.dart` (31 行)

**imports:** dart=0 / package=1 / relative=1

- relative: `../theme/solara_colors.dart`

**型定義 (1):**

- L6 `class GlassPanel : StatelessWidget`
  - 2026-05-03: BackdropFilter 撤去 (Adreno saveLayer leak)。blur なしの半透明

**関数 (1 public + 0 private):**

- L19 `build()`


### `lib/widgets/info_popup.dart` (113 行)

**imports:** dart=0 / package=1 / relative=1

- relative: `../theme/solara_colors.dart`

**型定義 (1):**

- L66 `class _InfoPopupShell : StatelessWidget`

**関数 (2 public + 0 private):**

- L36 `showInfoPopup()` — 説明ポップアップを表示する共通ヘルパー。
- L72 `build()`

**Popup/Dialog 呼出 (2):**

- 集計: `showInfoPopup`×2


### `lib/widgets/location_picker_minimap.dart` (141 行)

**ファイル先頭コメント:**

```
============================================================
LocationPickerMinimap — 中央固定ピン + マップパンで座標選択

用途: Sanctuary 出生地 / 現住所入力で、検索後に微調整するためのミニマップ。
操作: マップを指で動かす → 中央のピンが指す座標を onChanged で通知。
       (ピン自体はドラッグしない、IgnorePointer で gesture を Map に通す)
============================================================
```

**imports:** dart=0 / package=3 / relative=1

- relative: `../screens/map/map_styles.dart`

**型定義 (2):**

- L14 `class LocationPickerMinimap : StatefulWidget`
- L42 `class _LocationPickerMinimapState : State`

**関数 (4 public + 0 private):**

- L39 `createState()`
- L46 `initState()`
- L52 `didUpdateWidget()`
- L66 `build()`


### `lib/widgets/moon_overlay.dart` (4 行)

**ファイル先頭コメント:**

```
Re-export split overlay files for backward compatibility
```


### `lib/widgets/moon_overlay_shared.dart` (262 行)

**imports:** dart=0 / package=2 / relative=1

- relative: `../theme/solara_colors.dart`

**型定義 (2):**

- L142 `class MoonScrollingStory : StatefulWidget`
  - 縦スクロールするストーリーテキスト (新月/満月/刻星化 共通)
- L163 `class _MoonScrollingStoryState : State`

**関数 (8 public + 2 private):**

- L17 `revealPoeticMessage()` — 選択後フェードインで表示する詩的メッセージ。
- L39 `moonOverlaySelectableCard()` — 月オーバーレイの選択可能カードの共通枠 (full_moon の評価カード /
- L68 `moonOverlayPageStructure()` — 月オーバーレイの共通ページ構造 (full_moon / new_moon の build() 共通枠)。
- L122 `mysticalMoonBackdrop()` — 神秘的な月/刻星化背景 — 黒ベース + 画像レイヤー + 子widget
- L160 `createState()`
- L168 `initState()`
- L197 `dispose()`
- L203 `build()`

  <details><summary>private 関数 2 件</summary>

  - L174 `_startAutoScroll()`
  - L187 `_onScroll()`

  </details>


### `lib/widgets/nav_icons.dart` (218 行)

**imports:** dart=1 / package=1 / relative=0

**型定義 (6):**

- L7 `class SolaraNavIcons`
- L32 `class _MapIconPainter : CustomPainter`
- L68 `class _HoroIconPainter : CustomPainter`
- L93 `class _TarotIconPainter : CustomPainter`
- L129 `class _GalaxyIconPainter : CustomPainter`
- L188 `class _SanctuaryIconPainter : CustomPainter`

**関数 (15 public + 0 private):**

- L11 `map()` — Map icon: circle + cross-hairs + diamond center
- L15 `horo()` — Horo icon: concentric circles + cross lines + center dot
- L19 `tarot()` — Tarot icon: card rectangle + star
- L23 `galaxy()` — Galaxy icon: elliptical orbits + spiral arms + center dot + small stars
- L27 `sanctuary()` — Sanctuary icon: temple/house shape + door + circle
- L37 `paint()`
- L64 `shouldRepaint()`
- L73 `paint()`
- L89 `shouldRepaint()`
- L98 `paint()`
- L125 `shouldRepaint()`
- L134 `paint()`
- L184 `shouldRepaint()`
- L193 `paint()`
- L217 `shouldRepaint()`


### `lib/widgets/no_profile_guide.dart` (51 行)

**imports:** dart=0 / package=1 / relative=1

- relative: `../screens/horoscope/horo_antique_icons.dart`

**型定義 (1):**

- L14 `class NoProfileGuide : StatelessWidget`
  - プロフィール未設定時の案内カード (Forecast / Locations 共通)。

**関数 (1 public + 0 private):**

- L20 `build()`


### `lib/widgets/solara_nav_bar.dart` (163 行)

**imports:** dart=0 / package=1 / relative=1

- relative: `nav_icons.dart`

**型定義 (1):**

- L23 `class SolaraNavBar : StatelessWidget`
  - Custom bottom navigation bar matching HTML shared/styles.css exactly.

**関数 (3 public + 2 private):**

- L35 `totalHeight()` — systemNav 込みの NavBar 全体の高さ。
- L47 `systemNavInset()`
- L60 `build()`

  <details><summary>private 関数 2 件</summary>

  - L90 `_buildItem()`
  - L153 `_iconForIndex()`

  </details>


### `lib/widgets/solara_safe_text.dart` (81 行)

**imports:** dart=0 / package=1 / relative=0

**型定義 (1):**

- L24 `class SolaraSafeText : StatelessWidget`

**関数 (1 public + 0 private):**

- L63 `build()`


### `lib/widgets/spiral_painter.dart` (91 行)

**imports:** dart=1 / package=1 / relative=1

- relative: `../theme/solara_colors.dart`

**型定義 (1):**

- L5 `class SpiralPainter : CustomPainter`

**関数 (2 public + 0 private):**

- L15 `paint()`
- L88 `shouldRepaint()`

