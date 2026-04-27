import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../utils/astro_zenith_messages.dart';
import 'map_astro_lines.dart' show AstroZenithMarker;
import 'map_constants.dart';

// ══════════════════════════════════════════════════
// Astro*Carto*Graphy モード専用UI
//
// モード状態の入退時に表示される:
//   - AstroCartoBanner       : 上部中央のタイトル + 閉じる×
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xE60C0C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: categoryColors.entries.map((e) {
          final active = activeCategory == e.key;
          return GestureDetector(
            onTap: () => onChanged(e.key),
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active ? e.value : const Color(0x1FFFFFFF),
                ),
                color: active ? e.value.withAlpha(36) : Colors.transparent,
              ),
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
          );
        }).toList(),
      ),
    );
  }
}

/// 天頂点タップ詳細 popup。
/// 画面下部に表示し、惑星固有のメッセージ + 座標 + タグを示す。
class AstroZenithPopup extends StatelessWidget {
  final String planetKey;        // 'sun', 'moon', ...
  final LatLng zenith;           // 表示用の座標 (lat=δ, lng=MC line)
  final VoidCallback onClose;

  const AstroZenithPopup({
    super.key,
    required this.planetKey,
    required this.zenith,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final meta = planetMeta[planetKey];
    final msg = astroZenithMessages[planetKey];
    if (meta == null || msg == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xEE0C0C1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: const Color(0x66C9A84C)),
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
            // ── ヘッダ: 装飾マーカー再現 + タイトル + × ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AstroZenithMarker(
                  planetSym: meta.sym,
                  planetColor: meta.color,
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
