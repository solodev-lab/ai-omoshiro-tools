import 'package:flutter/material.dart';

import 'map_constants.dart';
import 'map_styles.dart';

/// 左サイド ☰表示ボタンタップで右に展開するメニュー (2026-05-09)。
///
/// 3 階層タブ構造:
///   L1 (主タブ): [Map] [惑星] [ACG]
///   L2 (副タブ): 主タブ別に異なる
///       Map → [Map][MapDark][運勢方位][コンパス]
///       惑星 → [CHART][PG][FORTUNE]    (各々が L3 開閉トリガー)
///       ACG → [Natal線][Transit線][Prog線][S.Arc線][引越し]
///   L3 (惑星の副タブ展開時のみ):
///       CHART → [Natal][Prog][Transit]
///       PG    → [個人][社会][世代]
///       FORTUNE → [総合][癒し][豊かさ][恋愛][仕事][話す]
///
/// 設計意図:
/// - 旧 BottomSheet 方式は「シートで地図が隠れて変化が見えない」問題があった。
///   横展開メニューで地図右半分が常時見えるため、トグル変化の視覚フィードバックが
///   保たれる。
/// - 行ごとに横スクロール可能。ボタン幅を内容に合わせて確保。
class MapDisplayMenu extends StatefulWidget {
  final Map<String, bool> layers;
  final Map<String, bool> planetGroups;
  final Map<String, bool> astroLayers;
  final String activeCategory;
  final MapStyle mapStyle;
  final ValueChanged<String> onLayerToggle;
  final ValueChanged<String> onPlanetGroupToggle;
  final ValueChanged<String> onAstroToggle;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<MapStyle> onMapStyleChanged;

  const MapDisplayMenu({
    super.key,
    required this.layers,
    required this.planetGroups,
    required this.astroLayers,
    required this.activeCategory,
    required this.mapStyle,
    required this.onLayerToggle,
    required this.onPlanetGroupToggle,
    required this.onAstroToggle,
    required this.onCategoryChanged,
    required this.onMapStyleChanged,
  });

  @override
  State<MapDisplayMenu> createState() => _MapDisplayMenuState();
}

enum _MainTab { map, planet, acg }
enum _PlanetSub { chart, pg, fortune }

class _MapDisplayMenuState extends State<MapDisplayMenu> {
  _MainTab _tab = _MainTab.map;
  _PlanetSub? _planetSub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xEB0A0A19),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _scrollRow([
            _tabBtn('Map', _tab == _MainTab.map, () => setState(() => _tab = _MainTab.map)),
            _tabBtn('惑星', _tab == _MainTab.planet, () => setState(() => _tab = _MainTab.planet)),
            _tabBtn('ACG', _tab == _MainTab.acg, () => setState(() => _tab = _MainTab.acg)),
          ]),
          const SizedBox(height: 6),
          _scrollRow(_l2Buttons()),
          if (_tab == _MainTab.planet && _planetSub != null) ...[
            const SizedBox(height: 6),
            _scrollRow(_l3Buttons()),
          ],
        ],
      ),
    );
  }

  // ── L2 (主タブ別の副タブ) ────────────────────────────────────
  List<Widget> _l2Buttons() {
    switch (_tab) {
      case _MainTab.map:
        return [
          _radioBtn('Map', widget.mapStyle == MapStyle.osmHotLight,
              () => widget.onMapStyleChanged(MapStyle.osmHotLight)),
          _radioBtn('MapDark', widget.mapStyle == MapStyle.osmHotDark,
              () => widget.onMapStyleChanged(MapStyle.osmHotDark)),
          _toggleBtn('運勢方位', widget.layers['sectors'] ?? false,
              () => widget.onLayerToggle('sectors')),
          _toggleBtn('コンパス', widget.layers['compass'] ?? false,
              () => widget.onLayerToggle('compass')),
        ];
      case _MainTab.planet:
        return [
          _subTabBtn('CHART', _planetSub == _PlanetSub.chart, () => _toggleSub(_PlanetSub.chart)),
          _subTabBtn('PG', _planetSub == _PlanetSub.pg, () => _toggleSub(_PlanetSub.pg)),
          _subTabBtn('FORTUNE', _planetSub == _PlanetSub.fortune, () => _toggleSub(_PlanetSub.fortune)),
        ];
      case _MainTab.acg:
        return [
          _toggleBtn('Natal線', widget.astroLayers['aspect'] ?? false,
              () => widget.onAstroToggle('aspect')),
          _toggleBtn('Transit線', widget.astroLayers['aspectTransit'] ?? false,
              () => widget.onAstroToggle('aspectTransit')),
          _toggleBtn('Prog線', widget.astroLayers['aspectProgressed'] ?? false,
              () => widget.onAstroToggle('aspectProgressed')),
          _toggleBtn('S.Arc線', widget.astroLayers['aspectSolarArc'] ?? false,
              () => widget.onAstroToggle('aspectSolarArc')),
          _toggleBtn('引越し', widget.astroLayers['relocate'] ?? false,
              () => widget.onAstroToggle('relocate')),
        ];
    }
  }

  // ── L3 (惑星の副タブ展開時のみ) ────────────────────────────────
  List<Widget> _l3Buttons() {
    switch (_planetSub!) {
      case _PlanetSub.chart:
        return [
          _toggleBtn('Natal', widget.layers['natal'] ?? false,
              () => widget.onLayerToggle('natal')),
          _toggleBtn('Prog', widget.layers['progressed'] ?? false,
              () => widget.onLayerToggle('progressed')),
          _toggleBtn('Transit', widget.layers['transit'] ?? false,
              () => widget.onLayerToggle('transit')),
        ];
      case _PlanetSub.pg:
        return [
          _toggleBtn('個人', widget.planetGroups['personal'] ?? false,
              () => widget.onPlanetGroupToggle('personal')),
          _toggleBtn('社会', widget.planetGroups['social'] ?? false,
              () => widget.onPlanetGroupToggle('social')),
          _toggleBtn('世代', widget.planetGroups['generational'] ?? false,
              () => widget.onPlanetGroupToggle('generational')),
        ];
      case _PlanetSub.fortune:
        return [
          for (final e in categoryColors.entries)
            _radioBtn(
              categoryLabels[e.key] ?? e.key,
              widget.activeCategory == e.key,
              () => widget.onCategoryChanged(e.key),
              tintColor: e.value,
            ),
        ];
    }
  }

  void _toggleSub(_PlanetSub sub) {
    setState(() {
      _planetSub = (_planetSub == sub) ? null : sub;
    });
  }

  // ── ボタンビルダー ────────────────────────────────────────
  /// L1 主タブ (3 個。常に 1 個だけ active)
  Widget _tabBtn(String label, bool active, VoidCallback onTap) {
    return _ChipButton(
      label: label,
      active: active,
      tintColor: const Color(0xFFC9A84C),
      onTap: onTap,
      bold: true,
    );
  }

  /// L2 副タブ (惑星専用、開閉トリガー)
  Widget _subTabBtn(String label, bool open, VoidCallback onTap) {
    return _ChipButton(
      label: label,
      active: open,
      tintColor: const Color(0xFFFFD370),
      onTap: onTap,
    );
  }

  /// 通常トグル (ON/OFF)
  Widget _toggleBtn(String label, bool on, VoidCallback onTap) {
    return _ChipButton(
      label: label,
      active: on,
      tintColor: const Color(0xFFC9A84C),
      onTap: onTap,
    );
  }

  /// ラジオ (排他選択)
  Widget _radioBtn(String label, bool selected, VoidCallback onTap, {Color? tintColor}) {
    return _ChipButton(
      label: label,
      active: selected,
      tintColor: tintColor ?? const Color(0xFFC9A84C),
      onTap: onTap,
    );
  }

  /// 横スクロール可能な行 (ボタン数が多い場合の overflow 対策)
  Widget _scrollRow(List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 共通のチップ風ボタン (active 状態で塗りつぶし変化)。
class _ChipButton extends StatelessWidget {
  final String label;
  final bool active;
  final Color tintColor;
  final VoidCallback onTap;
  final bool bold;
  const _ChipButton({
    required this.label,
    required this.active,
    required this.tintColor,
    required this.onTap,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? tintColor : tintColor.withAlpha(0x44),
            width: active ? 1.4 : 1,
          ),
          color: active ? tintColor.withAlpha(0x33) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? tintColor : const Color(0xFF888888),
            letterSpacing: 0.4,
            fontWeight: bold || active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
