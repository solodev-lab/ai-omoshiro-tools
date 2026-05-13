// ============================================================
// MapAspectChip — Daily Transit V2 用 1アスペクトチップ
//
// 元: map_daily_transit_screen.dart 内の _AspectChip
// 2026-04-29 セッション最終整理で独立ファイル化（行数肥大対策）。
//
// 表示:
//   ☌ natal ♂火星 1.2°  のような compact な丸角チップ。
//   色は Solara 設計思想に従い:
//     - soft  = energySoft (銀月色)
//     - hard  = energyHard (金陽色)
//     - tense = energyHard (同上)
//     - neutral = solaraGoldLight (金色)
//
// タップ:
//   showModalBottomSheet で Horo 相タブ相当の詳細解説を出す。
//   buildAspectDescription(p1, p2, type) を流用しているため、
//   表示内容は Horo 画面と完全に同じ。
// ============================================================
import 'package:flutter/material.dart';

import '../../theme/solara_colors.dart';
import '../../utils/daily_transits_api.dart';
import '../../widgets/info_popup.dart';
import '../horoscope/horo_aspect_description.dart';
import 'map_constants.dart';

class MapAspectChip extends StatelessWidget {
  /// 通過しているトランジット惑星キー（例: 'venus'）。
  final String transitPlanet;

  /// アスペクト本体（natal惑星 / type / quality / orb）。
  final TransitAspect aspect;

  const MapAspectChip({
    super.key,
    required this.transitPlanet,
    required this.aspect,
  });

  Color _color() {
    switch (aspect.quality) {
      case 'soft':
        return SolaraColors.energySoft;
      case 'hard':
      case 'tense':
        return SolaraColors.energyHard;
      default:
        return SolaraColors.solaraGoldLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    final symbol = _aspectSymbol(aspect.type);
    final natalSym = planetMeta[aspect.natalPlanet]?.sym ?? '';
    final natalJP = planetMeta[aspect.natalPlanet]?.jp ?? aspect.natalPlanet;

    return GestureDetector(
      onTap: () => _showDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          color: color.withValues(alpha: 0.08),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              symbol,
              style: TextStyle(fontSize: 13, color: color, height: 1.0),
            ),
            const SizedBox(width: 4),
            Text(
              'natal $natalSym$natalJP',
              style: TextStyle(
                fontSize: 13,
                color: color,
                letterSpacing: 0.3,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${aspect.orb.toStringAsFixed(1)}°',
              style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: 0.7),
                fontFamily: 'monospace',
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final color = _color();
    // Horo 相タブと同じ buildAspectDescription を流用（planet × planet × aspect）
    final desc = buildAspectDescription(
      transitPlanet,
      aspect.natalPlanet,
      aspect.type,
    );
    final transitMeta = planetMeta[transitPlanet];
    final natalMeta = planetMeta[aspect.natalPlanet];

    // 2026-05-07: 統一 popup ヘルパー [showInfoPopup] へ移行。
    // 右上 × / 全文スクロール / 外タップ閉じが Shell 側で自動提供される。
    // borderColor で aspect quality 色の枠を維持。
    showInfoPopup(
      context: context,
      borderColor: color.withValues(alpha: 0.45),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(transitMeta?.sym ?? '✦',
                style: TextStyle(fontSize: 20, color: transitMeta?.color)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(transitMeta?.jp ?? transitPlanet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16,
                      color: SolaraColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 4),
            const Text('(T)',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
            const SizedBox(width: 10),
            Text('×',
                style: TextStyle(
                    fontSize: 16, color: color.withValues(alpha: 0.8))),
            const SizedBox(width: 10),
            Text(natalMeta?.sym ?? '✦',
                style: TextStyle(fontSize: 20, color: natalMeta?.color)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(natalMeta?.jp ?? aspect.natalPlanet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16,
                      color: SolaraColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 4),
            const Text('(N)',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Text(desc['aspect'] ?? '',
                style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
          Text('オーブ ${aspect.orb.toStringAsFixed(2)}°',
              style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          const SizedBox(height: 18),
          _descSection('性質', desc['summary'] ?? '', color),
          const SizedBox(height: 14),
          _descSection(
              'テーマ', desc['theme'] ?? '', SolaraColors.solaraGoldLight),
          const SizedBox(height: 14),
          _descSection(
              '読み解き', desc['reading'] ?? '', SolaraColors.solaraGoldLight),
          const SizedBox(height: 18),
          // 「Map のスコアバー (16 方位 Fortune) と同じ方角の数字では？」と
          // 誤解されないよう、Daily Transit の方位概念を popup 末尾で明示。
          // 天空方位 = ASC/MC/DSC/IC など、今いる場所の空での惑星位置。
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: const Text(
              '※ ここで示す「方角」は天空方位 — 今いる場所の空で惑星が通る位置 '
              '(ASC=東の地平 / MC=南中 / DSC=西の地平 / IC=北底など) を表します。\n'
              'Map のスコアバーが示す 16 方位 Fortune (アスペクト合算スコア) '
              'とは別の指標です。',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF999999),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _descSection(String label, String body, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: accent.withValues(alpha: 0.85),
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(body,
            style: const TextStyle(
                fontSize: 14,
                color: SolaraColors.textPrimary,
                height: 1.65)),
      ],
    );
  }

  String _aspectSymbol(String type) {
    switch (type) {
      case 'conjunction': return '☌';
      case 'sextile':     return '⚹';
      case 'square':      return '☐';
      case 'trine':       return '△';
      case 'opposition':  return '☍';
      default:            return type;
    }
  }
}
