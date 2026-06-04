// Galaxy Cycle 操作シート — C5 (柱 3)
//
// 設計: apps/solara/docs/pro_candidates.md §7.3 + §3 C5
//
// Star Atlas のカード長押しで表示される bottom sheet。
// メニュー項目:
//   - 通常再生 ※カードタップと同じだが UX 上ここにも置いておく
//   - 形成演出を再生
//   - エクスポート (テキストコピー)
//
// 2026-05-31: 「形成演出を再生」「テキストとしてコピー」を Free に戻した
// (オーナー指示)。全項目 Free。

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/strings.g.dart';
import '../../models/galaxy_cycle.dart';
import '../../models/lunar_intention.dart';
import '../../theme/solara_colors.dart';
import '../../utils/galaxy_cycle_export.dart';
import '../../utils/solara_i18n.dart';

/// [GalaxyCycle] に対する Pro メニューを bottom sheet で表示する。
///
/// [onReplay]: 通常 (line drawing) 再生を起動 (親側で onOpenReplay を呼ぶ)。
/// [onPlayFormation]: 8 秒の刻星化形成演出を再生する (Pro 限定)。
/// [intentionLoader]: そのサイクル ID に対する LunarIntention 読込関数 (省略可)。
Future<void> showGalaxyCycleActionsSheet({
  required BuildContext context,
  required GalaxyCycle cycle,
  required VoidCallback onReplay,
  required void Function(GalaxyCycle) onPlayFormation,
  Future<LunarIntention?> Function(String cycleId)? intentionLoader,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _CycleActionsSheet(
      cycle: cycle,
      onReplay: onReplay,
      onPlayFormation: onPlayFormation,
      intentionLoader: intentionLoader,
    ),
  );
}

class _CycleActionsSheet extends StatelessWidget {
  final GalaxyCycle cycle;
  final VoidCallback onReplay;
  final void Function(GalaxyCycle) onPlayFormation;
  final Future<LunarIntention?> Function(String cycleId)? intentionLoader;

  const _CycleActionsSheet({
    required this.cycle,
    required this.onReplay,
    required this.onPlayFormation,
    required this.intentionLoader,
  });

  Future<void> _exportText(BuildContext ctx) async {
    final intention = intentionLoader != null
        ? await intentionLoader!(cycle.id)
        : null;
    final md = formatGalaxyCycleAsMarkdown(
      cycle: cycle,
      intention: intention,
    );
    await Clipboard.setData(ClipboardData(text: md));
    if (!ctx.mounted) return;
    Navigator.of(ctx).pop();
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(t.galaxyActions.copied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 端末ロケールで星座名を選択 (en=英語名 / それ以外=日本語名)。
    // 既存データの "The " プレフィックスは表示時に除去 (後方互換)。
    final rawName = isEnLocale()
        ? cycle.nameEN
        : (cycle.nameJP.isNotEmpty ? cycle.nameJP : cycle.nameEN);
    final displayName =
        rawName.startsWith('The ') ? rawName.substring(4) : rawName;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xEE0C0C1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33F9D976)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: SolaraColors.solaraGoldLight,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: SolaraColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0x22F9D976), height: 18),
              _ActionTile(
                icon: Icons.play_circle_outline,
                label: t.galaxyActions.replayLabel,
                subtitle: t.galaxyActions.replaySub,
                isLocked: false,
                onTap: () {
                  Navigator.of(context).pop();
                  onReplay();
                },
              ),
              _ActionTile(
                icon: Icons.auto_fix_high,
                label: t.galaxyActions.formationLabel,
                subtitle: t.galaxyActions.formationSub,
                isLocked: false,
                onTap: () {
                  Navigator.of(context).pop();
                  onPlayFormation(cycle);
                },
              ),
              _ActionTile(
                icon: Icons.copy_outlined,
                label: t.galaxyActions.copyLabel,
                subtitle: t.galaxyActions.copySub,
                isLocked: false,
                onTap: () => _exportText(context),
              ),
              // 画像エクスポートは公開後 (1080px 専用カード新規実装が要る) — Phase 2 で
              // 検討する。テキスト版だけ先行で出す。
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isLocked;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isLocked
        ? const Color(0x99ACACAC)
        : SolaraColors.textPrimary;
    final iconColor = isLocked
        ? const Color(0x77F9D976)
        : SolaraColors.solaraGoldLight;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: fg,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.lock_outline,
                          size: 12,
                          color: Color(0x99F9D976),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
