import 'package:flutter/material.dart';

import '../../utils/astro_glossary.dart';
import '../solara_philosophy_screen.dart';
import 'map_constants.dart';
import 'map_styles.dart';

/// LayerPanel ビュー種別。CCG で 4 frame 追加してパネルが画面外に伸びる問題を
/// 解決するためボタンを2系統に分割した (2026-04-29)。
/// - display: 表示系 (16方位/コンパス/MAPSTYLE)
/// - astro:   占星術系 (惑星ライン/引越し/CCG 4 frame/CHART/PLANET GROUP/FORTUNE)
enum LayerPanelView { display, astro }

/// Layer Panel — HTML: .layer-panel { width:100px; }
///
/// Phase M2 論点5 (3-A1改): 4流派 (16方位/惑星ライン/引越し/アスペクト線)
/// を ASTRO セクションに並列配置。CHART (natal/progressed/transit) は
/// 惑星ラインの詳細制御として残し、PLANET GROUP も従前通り。
/// 2026-04-29: CCG 4 frame 追加でパネル長過ぎる問題を解決すべく、
/// view パラメータで Display 系 / Astro 系の2ボタンに分割。
class LayerPanel extends StatelessWidget {
  final LayerPanelView view;
  final Map<String, bool> layers;
  final Map<String, bool> planetGroups;
  final Map<String, bool> astroLayers; // Phase M2: 16方位/惑星ライン/引越し/アスペクト
  final String activeCategory;
  final MapStyle mapStyle;
  final ValueChanged<String> onLayerToggle;
  final ValueChanged<String> onPlanetGroupToggle;
  final ValueChanged<String> onAstroToggle;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<MapStyle> onMapStyleChanged;

  const LayerPanel({
    super.key,
    this.view = LayerPanelView.display,
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
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEB0C0C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: view == LayerPanelView.display
            ? _displaySections(context)
            : _astroSections(context),
      ),
    );
  }

  // ── DISPLAY ビュー: 表示系のみ ──
  List<Widget> _displaySections(BuildContext context) {
    return [
      const Text('DISPLAY', style: TextStyle(fontSize: 9, color: Color(0xFF666666), letterSpacing: 1.5)),
      const SizedBox(height: 10),
      _section('ASTRO', [
        _toggleWithGlossary('sectors', '16方位', 'sector_score_16',
            const Color(0xFFC9A84C), layers, onLayerToggle, context),
      ]),
      _section('MAP', [
        _toggle('compass', 'コンパス', const Color(0xFFE8E0D0), layers, onLayerToggle),
      ]),
      _section('MAPSTYLE', [
        for (final e in mapStyleConfigs.entries)
          _styleOption(e.key, e.value.label),
      ]),
      _philosophyLink(context),
    ];
  }

  // ── ASTRO ビュー: 占星術系の全部 ──
  List<Widget> _astroSections(BuildContext context) {
    final showPlanetLineDetails = astroLayers['planetLines'] ?? true;
    final anyAspectOn = astroLayers['aspect'] == true ||
        astroLayers['aspectTransit'] == true ||
        astroLayers['aspectProgressed'] == true ||
        astroLayers['aspectSolarArc'] == true;
    return [
      const Text('ASTRO', style: TextStyle(fontSize: 9, color: Color(0xFF666666), letterSpacing: 1.5)),
      const SizedBox(height: 10),
      // ── 線レイヤー ──
      _section('LINES', [
        _toggleWithGlossary('planetLines', '惑星ライン', 'planet_lines',
            const Color(0xFFFFD370), astroLayers, onAstroToggle, context),
        _toggleWithGlossary('relocate', '引越し', 'relocate_layer',
            const Color(0xFFFFB6C1), astroLayers, onAstroToggle, context),
      ]),
      // ── A*C*G / CCG 4 frame ──
      _section('A*C*G', [
        _toggleWithGlossary('aspect', 'Natal線', 'aspect_lines',
            const Color(0xFFE9D29A), astroLayers, onAstroToggle, context),
        _toggleWithGlossary('aspectTransit', 'Transit線', 'transit_acg',
            const Color(0xFFFF8E5C), astroLayers, onAstroToggle, context),
        _toggleWithGlossary('aspectProgressed', 'Prog線', 'progressed_acg',
            const Color(0xFF63D6A0), astroLayers, onAstroToggle, context),
        _toggleWithGlossary('aspectSolarArc', 'S.Arc線', 'solar_arc_acg',
            const Color(0xFFB07CFF), astroLayers, onAstroToggle, context),
        if (anyAspectOn)
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: _toggle('aspectAll', '全惑星', const Color(0xFFE8E0D0),
                astroLayers, onAstroToggle),
          ),
      ]),
      // ── CHART: 惑星ラインの詳細 (planetLines ON 時のみ表示) ──
      if (showPlanetLineDetails)
        _section('CHART', [
          _toggle('natal', 'Natal', const Color(0xFFE8E0D0), layers, onLayerToggle),
          _toggle('progressed', 'Progressed', const Color(0xFFC9A84C), layers, onLayerToggle),
          _toggle('transit', 'Transit', const Color(0xFF00D4FF), layers, onLayerToggle),
        ]),
      _section('PLANET GROUP', [
        _toggle('personal', '個人天体', const Color(0xFFFFD370), planetGroups, onPlanetGroupToggle),
        _toggle('social', '社会天体', const Color(0xFF6BB5FF), planetGroups, onPlanetGroupToggle),
        _toggle('generational', '世代天体', const Color(0xFFB088FF), planetGroups, onPlanetGroupToggle),
      ]),
      _section('FORTUNE', [
        ...categoryColors.entries.map((e) {
          final active = activeCategory == e.key;
          return GestureDetector(
            onTap: () => onCategoryChanged(e.key),
            child: Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? e.value : const Color(0x1FFFFFFF)),
                color: active ? e.value.withAlpha(26) : Colors.transparent,
              ),
              child: Text(categoryLabels[e.key] ?? e.key,
                style: TextStyle(fontSize: 10, color: active ? e.value : const Color(0xFF555555), letterSpacing: 0.3)),
            ),
          );
        }),
      ]),
      _philosophyLink(context),
    ];
  }

  /// 設計思想ガイドへのリンク（パネル最下部・両ビュー共通）。
  /// ソフト/ハード独立2エネルギーの考え方を伝える章0画面へ遷移する。
  Widget _philosophyLink(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SolaraPhilosophyScreen(),
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('☯', style: TextStyle(fontSize: 11, color: Color(0xFFC9A84C))),
            SizedBox(width: 5),
            Flexible(
              child: Text('設計思想',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFC9A84C),
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String label, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF555555), letterSpacing: 1)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _styleOption(MapStyle style, String label) {
    final active = mapStyle == style;
    const activeColor = Color(0xFFC9A84C);
    return GestureDetector(
      onTap: () => onMapStyleChanged(style),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: active ? activeColor : const Color(0x33FFFFFF), width: 1.5),
              color: active ? activeColor.withAlpha(60) : Colors.transparent,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label,
              style: TextStyle(fontSize: 10, color: active ? const Color(0xFFBBBBBB) : const Color(0xFF666666)),
              overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }

  Widget _toggle(String key, String label, Color color, Map<String, bool> map, ValueChanged<String> onToggle) {
    final on = map[key] ?? false;
    return GestureDetector(
      onTap: () => onToggle(key),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: on ? color : const Color(0x33FFFFFF), width: 1.5),
              color: on ? color.withAlpha(26) : Colors.transparent,
            ),
            child: on ? Center(child: Text('✓', style: TextStyle(fontSize: 9, color: color))) : null,
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(label, style: TextStyle(fontSize: 11, color: on ? const Color(0xFFBBBBBB) : const Color(0xFF666666)), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }

  /// _toggle に i アイコン付き (論点4 連動)。
  /// チェックボックス本体タップで切替、i アイコンタップで用語解説 popup。
  Widget _toggleWithGlossary(
    String key,
    String label,
    String termKey,
    Color color,
    Map<String, bool> map,
    ValueChanged<String> onToggle,
    BuildContext context,
  ) {
    final on = map[key] ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        GestureDetector(
          onTap: () => onToggle(key),
          child: Container(
            width: 14, height: 14,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: on ? color : const Color(0x33FFFFFF), width: 1.5),
              color: on ? color.withAlpha(26) : Colors.transparent,
            ),
            child: on ? Center(child: Text('✓', style: TextStyle(fontSize: 9, color: color))) : null,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: GestureDetector(
            onTap: () => onToggle(key),
            child: Text(label,
              style: TextStyle(fontSize: 11, color: on ? const Color(0xFFBBBBBB) : const Color(0xFF666666)),
              overflow: TextOverflow.ellipsis),
          ),
        ),
        // i アイコン (用語解説 popup 起動)
        // 2026-04-29: 9px → 16px。EdgeInsets.all(8) でタップ領域 32×32px 確保。
        GestureDetector(
          onTap: () => showAstroGlossaryDialog(context, termKey),
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.info_outline, size: 16, color: Color(0xCCAAAAAA)),
          ),
        ),
      ]),
    );
  }
}
