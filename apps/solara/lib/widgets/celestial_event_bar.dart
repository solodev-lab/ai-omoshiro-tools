import 'package:flutter/material.dart';
import '../utils/celestial_events.dart';
import '../utils/celestial_event_meanings.dart';
import '../theme/solara_colors.dart';
import 'info_popup.dart';

/// Cycle画面下部に常時表示する天体イベント横スクロールバー
/// タップでボトムシートに占星術的意味を表示
class CelestialEventBar extends StatelessWidget {
  final List<CelestialEvent> events;

  const CelestialEventBar({super.key, required this.events});

  static const _typeIcons = {
    'ingress': '➜',
    'retrograde': '℞',
    'retrograde_end': '↻',
    'eclipse': '◑',
    'conjunction': '☌',
    'node_shift': '☊',
  };

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _buildChip(context, events[i]),
      ),
    );
  }

  Widget _buildChip(BuildContext context, CelestialEvent event) {
    final icon = _typeIcons[event.type] ?? '★';
    final label = event.localDescJP;

    return GestureDetector(
      onTap: () => _showMeaning(context, event),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x15FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x25FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 14,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMeaning(BuildContext context, CelestialEvent event) {
    final meaning = getEventMeaningJP(event.type, event.planet);
    if (meaning.isEmpty) return;

    // 2026-05-07: showModalBottomSheet → showInfoPopup へ統一移行。
    // 右上 × / 全文スクロール / 外タップ閉じが Shell 側で自動提供される。
    // 旧ドラッグハンドル方式の close は Shell の Icons.close に置換。
    showInfoPopup(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // イベント名
          Text(
            event.localDescJP,
            style: const TextStyle(
              color: SolaraColors.solaraGold,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          // タイプラベル
          Text(
            _typeLabel(event.type),
            style: const TextStyle(
              color: SolaraColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),
          // 意味の解説
          Text(
            meaning,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 14,
              fontWeight: FontWeight.w300,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'ingress': return '惑星移行';
      case 'retrograde': return '逆行';
      case 'retrograde_end': return '順行';
      case 'eclipse': return '食';
      case 'conjunction': return '合';
      case 'node_shift': return 'ノード移動';
      default: return '';
    }
  }
}
