import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../utils/astro_glossary.dart';
import '../../utils/astro_lines.dart' show AstroFrame;
import '../../utils/astro_zenith_messages.dart';
import 'map_astro_lines.dart' show AstroZenithMarker, astroFrameStyles;
import 'map_constants.dart';

// ══════════════════════════════════════════════════
// Astro*Carto*Graphy モード専用UI
//
// モード状態の入退時に表示される:
//   - AstroCartoBanner       : 上部中央のタイトル + 閉じる×
//   - AstroCartoFramePills   : 4フレーム (Natal/Transit/Prog/SArc) 切替 (Tier A #5)
//   - AstroCartoCategoryPills: 下部中央のFORTUNEカテゴリ切替
//   - AstroZenithPopup       : 天頂点マーカータップ詳細
//
// マーカー本体 (AstroZenithMarker) と線/マーカービルド関数は
// map_astro_lines.dart に置く (rendering primitives は別レイヤー)。
// ══════════════════════════════════════════════════

/// Astro*Carto*Graphy モード中の上部バナー (タイトル + 閉じる×)。
/// モード状態を視覚的に示し、復帰経路を保証する。
class AstroCartoBanner extends StatelessWidget {
  final VoidCallback onClose;
  const AstroCartoBanner({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xE60C0C1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x80C9A84C)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌐', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          const Text(
            'ASTRO*CARTO*GRAPHY',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFFC9A84C),
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Icon(Icons.close, size: 14, color: Color(0xFFAAAAAA)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Astro*Carto*Graphy モード中の4フレーム切替ピル (Tier A #5 / CCG D2)。
/// Natal / Transit / Progressed / Solar Arc を独立にON/OFF可能。
/// 各ピルは frame の accent 色で塗られ、ON時は枠+塗り、OFF時は薄文字。
/// 入時の規定: Natal=ON、他=OFF (ユーザー直前選択を維持)。
class AstroCartoFramePills extends StatelessWidget {
  /// _astroLayers のキー → 表示状態。ON のフレームを accent 強調。
  final Map<String, bool> astroLayers;
  /// _astroLayers のキー名で trigger (例: 'aspect', 'aspectTransit')
  final ValueChanged<String> onToggle;

  const AstroCartoFramePills({
    super.key,
    required this.astroLayers,
    required this.onToggle,
  });

  static const List<({String layerKey, AstroFrame frame, String shortLabel, String termKey})> _entries = [
    (layerKey: 'aspect', frame: AstroFrame.natal, shortLabel: 'Natal', termKey: 'aspect_lines'),
    (layerKey: 'aspectTransit', frame: AstroFrame.transit, shortLabel: 'Transit', termKey: 'transit_acg'),
    (layerKey: 'aspectProgressed', frame: AstroFrame.progressed, shortLabel: 'Prog', termKey: 'progressed_acg'),
    (layerKey: 'aspectSolarArc', frame: AstroFrame.solarArc, shortLabel: 'S.Arc', termKey: 'solar_arc_acg'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xE60C0C1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _entries.map((e) {
          final on = astroLayers[e.layerKey] ?? false;
          final accent = astroFrameStyles[e.frame]!.accent;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: on ? accent : const Color(0x1FFFFFFF),
                width: on ? 1.2 : 0.8,
              ),
              color: on ? accent.withAlpha(30) : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => onToggle(e.layerKey),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(9, 4, 4, 4),
                    child: Text(
                      e.shortLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: on ? accent : const Color(0xFF888888),
                        letterSpacing: 0.3,
                        fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => showAstroGlossaryDialog(context, e.termKey),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 7, 4),
                    child: Icon(
                      Icons.info_outline,
                      size: 10,
                      color: on ? accent.withAlpha(180) : const Color(0x88888888),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Astro*Carto*Graphy モード中のカテゴリピル。
/// (LayerPanel の代わりにモード中のFORTUNEカテゴリ切替を担当)
class AstroCartoCategoryPills extends StatelessWidget {
  final String activeCategory;
  final ValueChanged<String> onChanged;
  const AstroCartoCategoryPills({
    super.key,
    required this.activeCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xE60C0C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: categoryColors.entries.map((e) {
          final active = activeCategory == e.key;
          // glossary キーは fortune_<categoryKey>
          final termKey = 'fortune_${e.key}';
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? e.value : const Color(0x1FFFFFFF),
              ),
              color: active ? e.value.withAlpha(36) : Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => onChanged(e.key),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(9, 4, 3, 4),
                    child: Text(
                      categoryLabels[e.key] ?? e.key,
                      style: TextStyle(
                        fontSize: 11,
                        color: active ? e.value : const Color(0xFF888888),
                        letterSpacing: 0.4,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => showAstroGlossaryDialog(context, termKey),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 4, 7, 4),
                    child: Icon(
                      Icons.info_outline,
                      size: 10,
                      color: active ? e.value.withAlpha(180) : const Color(0x88888888),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 天頂点タップ詳細 popup。
/// 画面下部に表示し、惑星固有のメッセージ + 座標 + タグを示す。
/// CCG: frame で見出し付加 (Transit/Progressed/Solar Arc は時間連動を明示)。
class AstroZenithPopup extends StatelessWidget {
  final String planetKey;        // 'sun', 'moon', ...
  final LatLng zenith;           // 表示用の座標 (lat=δ, lng=MC line)
  final AstroFrame frame;
  final VoidCallback onClose;

  const AstroZenithPopup({
    super.key,
    required this.planetKey,
    required this.zenith,
    required this.onClose,
    this.frame = AstroFrame.natal,
  });

  @override
  Widget build(BuildContext context) {
    final meta = planetMeta[planetKey];
    final msg = astroZenithMessages[planetKey];
    if (meta == null || msg == null) return const SizedBox.shrink();
    final frameStyle = astroFrameStyles[frame] ?? astroFrameStyles[AstroFrame.natal]!;
    final isNatal = frame == AstroFrame.natal;
    final frameLabel = isNatal
        ? null
        : (frame == AstroFrame.transit
            ? 'TRANSIT — 今この瞬間の天体位置'
            : frame == AstroFrame.progressed
                ? 'PROGRESSED — 2次進行 (1日=1年)'
                : 'SOLAR ARC — 太陽進行弧で全惑星シフト');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xEE0C0C1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(
          color: isNatal ? const Color(0x66C9A84C) : frameStyle.accent.withAlpha(140),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── frame ラベル (Natal以外) ──
            if (frameLabel != null) Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: frameStyle.accent, width: 0.8),
                  color: frameStyle.accent.withAlpha(28),
                ),
                child: Text(
                  frameLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: frameStyle.accent,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // ── ヘッダ: 装飾マーカー再現 + タイトル + × ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AstroZenithMarker(
                  planetSym: meta.sym,
                  planetColor: meta.color,
                  frame: frame,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        msg.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: meta.color,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        msg.summary,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC9A84C),
                          letterSpacing: 0.3,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.close, size: 18, color: Color(0xFFAAAAAA)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── 詳述 ──
            Text(
              msg.detail,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFE8E0D0),
                height: 1.7,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            // ── タグ + 座標 ──
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...msg.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: meta.color.withAlpha(120), width: 0.8),
                    color: meta.color.withAlpha(20),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      color: meta.color,
                      letterSpacing: 0.3,
                    ),
                  ),
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x33C9A84C), width: 0.8),
                  ),
                  child: Text(
                    '${zenith.latitude.toStringAsFixed(1)}°, ${zenith.longitude.toStringAsFixed(1)}°',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF888888),
                      fontFamily: 'monospace',
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
