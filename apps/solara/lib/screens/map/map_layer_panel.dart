import 'package:flutter/material.dart';
import 'map_constants.dart';
import 'map_styles.dart';

/// Layer Panel — HTML: .layer-panel { width:100px; }
class LayerPanel extends StatelessWidget {
  final Map<String, bool> layers;
  final Map<String, bool> planetGroups;
  final String activeCategory;
  final MapStyle mapStyle;
  final String mapLang; // 'ja' | 'en' 等（Jawg スタイル時のみ有効）
  final ValueChanged<String> onLayerToggle;
  final ValueChanged<String> onPlanetGroupToggle;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<MapStyle> onMapStyleChanged;
  final ValueChanged<String> onMapLanguageChanged;

  const LayerPanel({
    super.key,
    required this.layers,
    required this.planetGroups,
    required this.activeCategory,
    required this.mapStyle,
    required this.mapLang,
    required this.onLayerToggle,
    required this.onPlanetGroupToggle,
    required this.onCategoryChanged,
    required this.onMapStyleChanged,
    required this.onMapLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          _section('MAP', [
            _toggle('sectors', '方位EN', const Color(0xFFC9A84C), layers, onLayerToggle),
            _toggle('compass', 'コンパス', const Color(0xFFE8E0D0), layers, onLayerToggle),
          ]),
          _section('STYLE', [
            for (final e in mapStyleConfigs.entries)
              _styleOption(e.key, e.value.label),
          ]),
          if (mapStyleConfigs[mapStyle]!.supportsLanguage)
            _section('LANG', [
              _langOption('ja', '日本語'),
              _langOption('en', 'English'),
            ]),
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

  Widget _langOption(String code, String label) {
    final active = mapLang == code;
    const activeColor = Color(0xFFC9A84C);
    return GestureDetector(
      onTap: () => onMapLanguageChanged(code),
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
}
