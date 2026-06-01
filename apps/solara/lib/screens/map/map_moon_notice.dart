import 'package:flutter/material.dart';

import '../../theme/solara_colors.dart';
import '../../utils/moon_event_status.dart';

/// Map 上部 (時刻スライダー直下) に出す月イベント案内バナー。
///
/// 「Galaxy 画面を見てね」という案内のみ。タップで閉じるだけで、Galaxy へは
/// 遷移しない (オーナー指定)。pending 判定・ディスミス管理は map_screen が行い、
/// ここは渡された [kind] を描画してタップを [onDismiss] に流すだけ。
class MapMoonNotice extends StatelessWidget {
  final MoonEventKind kind;
  final VoidCallback onDismiss;

  const MapMoonNotice({
    super.key,
    required this.kind,
    required this.onDismiss,
  });

  ({String emoji, String ja, String en}) get _copy => switch (kind) {
        MoonEventKind.newMoon => (
            emoji: '\u{1F311}', // 🌑
            ja: '新月 — Galaxy で意図を選べます',
            en: 'New moon — set your intention in Galaxy',
          ),
        MoonEventKind.fullMoon => (
            emoji: '\u{1F315}', // 🌕
            ja: '満月 — Galaxy で振り返りを',
            en: 'Full moon — reflect in Galaxy',
          ),
        MoonEventKind.catasterism => (
            emoji: '\u{2728}', // ✨
            ja: '月の節目 — Galaxy で締めくくりを',
            en: "Cycle's end — close it in Galaxy",
          ),
      };

  @override
  Widget build(BuildContext context) {
    final isJA = Localizations.localeOf(context).toString().startsWith('ja');
    final c = _copy;
    final text = '${c.emoji} ${isJA ? c.ja : c.en}';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDismiss,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
            decoration: BoxDecoration(
              color: const Color(0xF20A0A19),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x66C9A84C)),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x55000000),
                    blurRadius: 14,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.close, size: 15, color: Color(0x99FFFFFF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
