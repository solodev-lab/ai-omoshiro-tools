import 'package:flutter/material.dart';

import '../../utils/astro_glossary.dart';
import '../../widgets/glass_panel.dart';
import 'map_constants.dart';
import 'map_styles.dart';

/// Layer Panel — HTML: .layer-panel { width:100px; }
///
/// Phase M2 論点5 (3-A1改): 4流派 (16方位/惑星ライン/引越し/アスペクト線)
/// を ASTRO セクションに並列配置。CHART (natal/progressed/transit) は
/// 惑星ラインの詳細制御として残し、PLANET GROUP も従前通り。
class LayerPanel extends StatelessWidget {
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
    final showPlanetLineDetails = astroLayers['planetLines'] ?? true;
    return Container(
      width: 100,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEB0C0C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('LAYERS', style: TextStyle(fontSize: 9, color: Color(0xFF666666), letterSpacing: 1.5)),
          const SizedBox(height: 10),
          // ── ASTRO: 4流派並列 (Phase M2 論点5) ──
          _section('ASTRO', [
            _toggleWithGlossary('sectors', '16方位', 'sector_score_16',
                const Color(0xFFC9A84C), layers, onLayerToggle, context),
            _toggleWithGlossary('planetLines', '惑星ライン', 'planet_lines',
                const Color(0xFFFFD370), astroLayers, onAstroToggle, context),
            _toggleWithGlossary('relocate', '引越し', 'relocate_layer',
                const Color(0xFFFFB6C1), astroLayers, onAstroToggle, context),
            _toggleWithGlossary('aspect', 'アスペクト線', 'aspect_lines',
                const Color(0xFFB088FF), astroLayers, onAstroToggle, context),
            // aspect ON 時に「全惑星」サブトグル表示
            if (astroLayers['aspect'] == true)
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
          _section('MAP', [
            _toggle('compass', 'コンパス', const Color(0xFFE8E0D0), layers, onLayerToggle),
          ]),
          _section('MAPSTYLE', [
            for (final e in mapStyleConfigs.entries)
              _styleOption(e.key, e.value.label),
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
        ],
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
        GestureDetector(
          onTap: () => _showGlossaryPopup(context, termKey),
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.only(left: 2),
            child: Icon(Icons.info_outline, size: 9, color: Color(0x88888888)),
          ),
        ),
      ]),
    );
  }

  void _showGlossaryPopup(BuildContext context, String termKey) {
    final entry = astroGlossary[termKey];
    if (entry == null) return;
    showDialog<void>(
      context: context,
      barrierColor: const Color(0x99000000),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        child: GlassPanel(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(entry.title,
                        style: const TextStyle(
                          fontSize: 14, color: Color(0xFFC9A84C),
                          fontWeight: FontWeight.w600, letterSpacing: 0.4,
                        )),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: const Icon(Icons.close, size: 18, color: Color(0xFFAAAAAA)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(entry.summary,
                  style: const TextStyle(
                    fontSize: 11, color: Color(0xFFAAAAAA),
                    height: 1.5, letterSpacing: 0.3,
                  )),
                const Divider(color: Color(0x22FFFFFF), height: 18),
                Text(entry.detail,
                  style: const TextStyle(
                    fontSize: 12, color: Color(0xFFE8E0D0),
                    height: 1.7, letterSpacing: 0.2,
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
