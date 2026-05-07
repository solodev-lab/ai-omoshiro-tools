// ============================================================
// Solara DirectionEnergyPopup — 方角ごとの2エネルギー詳細表示
//
// E4 (2026-04-29): 設計思想に基づく「両エネルギー事実提示」型ポップアップ。
//   - ソフト / ハード を独立した2バーで表示
//   - 主な寄与アスペクトを attribution 表示
//   - 「良い」「悪い」とは判定しない、事実だけを伝える
//
// 関連:
//   - lib/utils/direction_energy.dart (DirectionEnergy / AspectContribution)
//   - project_solara_design_philosophy.md
// ============================================================
import 'package:flutter/material.dart';

import '../../theme/solara_colors.dart';
import '../../utils/astro_glossary.dart';
import '../../utils/direction_energy.dart';
import '../../widgets/info_popup.dart';
// glass_panel: 旧 _PopupBody が直接使っていたが、showInfoPopup Shell に移譲したため不要。
import 'map_constants.dart';

/// 方角タップ詳細ポップアップを表示するヘルパー。
///
/// 2026-05-07: 統一 popup ヘルパー [showInfoPopup] 経由に移行。
/// 右上 × / 全文スクロール / 外タップ閉じが Shell 側で自動提供される。
void showDirectionEnergyPopup(
  BuildContext context, {
  required String direction,
  required DirectionEnergy energy,
  required List<AspectContribution> contributors,
  String? categoryLabel,
}) {
  showInfoPopup(
    context: context,
    maxWidth: 380,
    child: _PopupBody(
      direction: direction,
      energy: energy,
      contributors: contributors,
      categoryLabel: categoryLabel,
    ),
  );
}

class _PopupBody extends StatelessWidget {
  final String direction;
  final DirectionEnergy energy;
  final List<AspectContribution> contributors;
  final String? categoryLabel;

  const _PopupBody({
    required this.direction,
    required this.energy,
    required this.contributors,
    this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dirJP = dir16JP[direction] ?? direction;
    final aggregated = aggregateContributions(contributors, topN: 6);

    // 2026-05-07: 外枠 (GlassPanel + 右上 × + maxWidth) は showInfoPopup Shell に移譲。
    // ここでは中身 (ヘッダ + エネルギーバー + ...) のみを返す。
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── ヘッダ ──
        Text(
          dirJP,
          style: const TextStyle(
            fontSize: 18,
            color: SolaraColors.solaraGoldLight,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
        ),
        Text(
          '$direction ${categoryLabel != null ? "・$categoryLabel" : ""}'.trim(),
          style: const TextStyle(
            fontSize: 10,
            color: SolaraColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 14),

        // ── エネルギーバー（2軸独立） ──
        _EnergyBar(
          symbol: '☯',
          label: 'ソフト',
          labelEn: 'Soft',
          value: energy.soft,
          color: SolaraColors.energySoft,
          termKey: 'soft_aspect',
        ),
        const SizedBox(height: 8),
        _EnergyBar(
          symbol: '☐',
          label: 'ハード',
          labelEn: 'Hard',
          value: energy.hard,
          color: SolaraColors.energyHard,
          termKey: 'hard_aspect',
        ),
        const SizedBox(height: 6),

        // ── 寄与アスペクト ──
        if (aggregated.isNotEmpty) ...[
          const Divider(color: Color(0x22FFFFFF), height: 22),
          const Text(
            '主な寄与アスペクト',
            style: TextStyle(
              fontSize: 11,
              color: SolaraColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          for (final a in aggregated) ...[
            _ContribRow(agg: a),
            const SizedBox(height: 4),
          ],
        ],

        // ── 設計思想ガイダンス ──
        const Divider(color: Color(0x22FFFFFF), height: 22),
        Text(
          _guidanceText(energy),
          style: const TextStyle(
            fontSize: 11.5,
            color: SolaraColors.textPrimary,
            height: 1.7,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => showAstroGlossaryDialog(context, 'two_energies'),
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Color(0xCCAAAAAA)),
                SizedBox(width: 5),
                Text(
                  '2つのエネルギーについて',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xCCCCCCCC),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// エネルギー量に応じた事実提示型のガイダンス文。
  /// 判定はしない、状態の言語化のみ。
  String _guidanceText(DirectionEnergy e) {
    // 閾値はやや感覚的（実データのレンジに合わせて将来調整）
    const threshold = 0.8;
    final softHigh = e.soft > threshold;
    final hardHigh = e.hard > threshold;

    if (softHigh && hardHigh) {
      return 'この方角には、両エネルギーが同時に在ります。\n'
          '流れと摩擦の両方が効く、深い体験の場。\n'
          'どちらに乗るか、両方を観察するか、選ぶのはあなた。';
    }
    if (softHigh) {
      return 'この方角は、ソフトエネルギーが優勢です。\n'
          '流れに乗りやすい場。\n'
          '受容的に進むのも、意識的に方向を選ぶのも、あなた次第。';
    }
    if (hardHigh) {
      return 'この方角は、ハードエネルギーが優勢です。\n'
          '摩擦と変容の場。\n'
          '見つめ直すか、対峙するか、距離を取るかは、あなたの選択。';
    }
    return 'この方角の両エネルギーは、いま静かです。\n'
        '特別な作用は感じにくい時間帯。\n'
        '無理に意味を見出さず、自然体でいられる場所。';
  }
}

class _EnergyBar extends StatelessWidget {
  final String symbol;
  final String label;
  final String labelEn;
  final double value;
  final Color color;
  final String termKey;

  const _EnergyBar({
    required this.symbol,
    required this.label,
    required this.labelEn,
    required this.value,
    required this.color,
    required this.termKey,
  });

  @override
  Widget build(BuildContext context) {
    // 値のレンジは実データ依存。とりあえず 0..5 を満タンとして見せる。
    // （実値も併記するので感覚的バーで十分）
    final barRatio = (value / 5.0).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => showAstroGlossaryDialog(context, termKey),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text(
                symbol,
                style: TextStyle(fontSize: 16, color: color, height: 1.0),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 56,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0x10FFFFFF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: barRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 38,
              child: Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: color,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContribRow extends StatelessWidget {
  final AggregatedAspect agg;
  const _ContribRow({required this.agg});

  @override
  Widget build(BuildContext context) {
    final isHard = agg.quality == 'hard' || agg.quality == 'tense';
    final isSoft = agg.quality == 'soft';
    final symbol = isHard ? '☐' : (isSoft ? '☯' : '◐');
    final color = isHard
        ? SolaraColors.energyHard
        : (isSoft ? SolaraColors.energySoft : SolaraColors.solaraGoldLight);

    final p1Label = _planetLabel(agg.p1);
    final p2Label = _planetLabel(agg.p2);
    final aspectLabel = _aspectLabel(agg.aspectType);
    final mag = agg.magnitude.toStringAsFixed(1);

    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            symbol,
            style: TextStyle(fontSize: 12, color: color, height: 1.0),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$p1Label × $p2Label  $aspectLabel',
            style: const TextStyle(
              fontSize: 11,
              color: SolaraColors.textPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Text(
          mag,
          style: TextStyle(
            fontSize: 10,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
      ],
    );
  }

  String _planetLabel(String key) {
    // 接頭辞除去（'N:venus' → 'venus'、'_asc' → 'asc'）
    final clean = key.replaceAll('N:', '').replaceAll('P:', '');
    if (clean.startsWith('_')) {
      return _angleJP[clean] ?? clean.substring(1).toUpperCase();
    }
    final meta = planetMeta[clean];
    return meta?.jp ?? clean;
  }

  static const _angleJP = <String, String>{
    '_asc': 'ASC',
    '_mc': 'MC',
    '_dsc': 'DSC',
    '_ic': 'IC',
  };

  String _aspectLabel(String type) {
    return _aspectJP[type] ?? type;
  }

  static const _aspectJP = <String, String>{
    'conjunction': '☌コンジャンクション',
    'sextile': '⚹セクスタイル',
    'square': '□スクエア',
    'trine': '△トライン',
    'quincunx': 'Qxクインカンクス',
    'opposition': '☍オポジション',
  };
}
