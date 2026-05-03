import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../utils/solara_storage.dart';
import 'map_vp_panel.dart' show VPSlot;

// ══════════════════════════════════════════════════
// Map 登録地マーカー
//
// 表示対象:
//   - 出生地 (profile.birthLat/Lng) — 🌟 + 強グロー + 呼吸パルス、特別扱い
//   - VIEWPOINT slots (solara_vp_slots、最大5)  — 各 slot.icon の絵文字
//   - Locations slots (solara_locations、最大5) — 各 slot.icon の絵文字
//
// home は両 slot リスト先頭に同期されるため自動的に表示される (重複は許容)。
// 通常Map / Astro*Carto*Graphy モード共通で表示。
// VP Pin (中央の金色ドラッグピン) との重なりは何もしない方針 (オーナー判断)。
// ══════════════════════════════════════════════════

/// 出生地マーカー: 🌟 + 多層グロー + 2.4秒周期の呼吸パルス。
/// 「個性の源」を視覚的に印象付ける。
class BirthMarker extends StatefulWidget {
  const BirthMarker({super.key});

  @override
  State<BirthMarker> createState() => _BirthMarkerState();
}

class _BirthMarkerState extends State<BirthMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        // 0.6 〜 1.0 で呼吸 (常に最低 60% の発光を維持)
        final intensity = 0.6 + 0.4 * t;
        // Center で囲って flutter_map Marker の tight constraints (60x60) を解放。
        // これがないと Container の width/height が ignore され膨張する。
        return Center(
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // 外側ソフトグロー (拡散大、暖色)
                // 2026-05-03: blur/spread を固定化 (Critical fix)。
                // breathing は alpha のみで表現 = saveLayer 回避。
                BoxShadow(
                  color: const Color(0xFFFFD370)
                      .withAlpha((180 * intensity).round()),
                  blurRadius: 14,
                  spreadRadius: 1.8,
                ),
                // 中間グロー (やや明るく、クリーム色)
                BoxShadow(
                  color: const Color(0xFFFFE8A0)
                      .withAlpha((220 * intensity).round()),
                  blurRadius: 7,
                  spreadRadius: 0.6,
                ),
                // 芯のハイライト (白系、シャープ)
                BoxShadow(
                  color: const Color(0xFFFFFFFF)
                      .withAlpha((120 * intensity).round()),
                  blurRadius: 3,
                ),
              ],
            ),
            // FittedBox で emoji を円内一杯に自動拡大
            // (fontSize は単なる文字箱サイズで実描画は font padding 含むため小さく見える問題を解消)
            child: const FittedBox(
              fit: BoxFit.contain,
              child: Text('🌟', style: TextStyle(fontSize: 100, height: 1.0)),
            ),
          ),
        );
      },
    );
  }
}

/// 通常スロット (VP / Locations) マーカー。
/// dark badge + 金枠 + 中央に slot 自身の絵文字。
/// home (isHome=true) はやや太めの枠 + 弱いグロー。
class SlotMarker extends StatelessWidget {
  final String icon;
  final bool isHome;

  const SlotMarker({super.key, required this.icon, required this.isHome});

  @override
  Widget build(BuildContext context) {
    // Center で囲って flutter_map Marker の tight constraints (40x40) を解放。
    // これがないと Container の width/height が ignore され膨張する。
    return Center(
      child: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xCC0C0C1A),
          border: Border.all(
            color: isHome
                ? const Color(0xFFC9A84C)
                : const Color(0x99C9A84C),
            width: isHome ? 1.4 : 1.0,
          ),
          boxShadow: [
            if (isHome)
              const BoxShadow(
                color: Color(0x66C9A84C),
                blurRadius: 5,
                spreadRadius: 0.6,
              )
            else
              const BoxShadow(
                color: Color(0x44000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
          ],
        ),
        // FittedBox で emoji を円内一杯に自動拡大 (BirthMarker と同じ手法)
        // 内側 padding 1.5px で枠と emoji の間に少し余白を持たせる
        child: Padding(
          padding: const EdgeInsets.all(1.5),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(icon, style: const TextStyle(fontSize: 100, height: 1.0)),
          ),
        ),
      ),
    );
  }
}

/// 登録地マーカー群を構築。
/// [onTap] にはマーカータップ時のコールバックを渡す
/// (引数: name, point, isBirth)。
///
/// レイヤー順 (上から下、重なったときの優先度):
///   1. 出生地 🌟 (最上位 — 必ず見える)
///   2. VP slots (リスト上位ほど上)
///   3. Locations slots (リスト上位ほど上、最下位 = 最も下のレイヤー)
///
/// flutter_map の MarkerLayer は list 順に描画 (先頭=下、末尾=上) のため
/// list には bottom-first で積む: Locations 逆順 → VP 逆順 → Birth。
List<Marker> buildLocationMarkers({
  required SolaraProfile? profile,
  required List<VPSlot> vpSlots,
  required List<VPSlot> locationSlots,
  required void Function(String name, LatLng point, bool isBirth) onTap,
}) {
  final markers = <Marker>[];

  Marker slotMarker(VPSlot slot) {
    final point = LatLng(slot.lat, slot.lng);
    return Marker(
      point: point,
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(slot.name, point, false),
        child: SlotMarker(icon: slot.icon, isHome: slot.isHome),
      ),
    );
  }

  // 1. Locations を逆順で積む (最下位 slot が最も下のレイヤー)
  for (final slot in locationSlots.reversed) {
    markers.add(slotMarker(slot));
  }

  // 2. VP を逆順で積む (Locations の上、リスト最上位が一番上)
  for (final slot in vpSlots.reversed) {
    markers.add(slotMarker(slot));
  }

  // 3. 出生地を最後に積む = 最上位レイヤー (必ず見える)
  if (profile != null &&
      !(profile.birthLat == 0 && profile.birthLng == 0)) {
    final point = LatLng(profile.birthLat, profile.birthLng);
    final name = profile.birthPlace.isNotEmpty
        ? profile.birthPlace
        : '出生地';
    markers.add(Marker(
      point: point,
      width: 60,
      height: 60,
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(name, point, true),
        child: const BirthMarker(),
      ),
    ));
  }

  return markers;
}

/// マーカータップ詳細 popup (画面下部の bottom sheet)。
/// 名前 + 緯度経度を表示するコンパクトなカード。
class LocationMarkerPopup extends StatelessWidget {
  final String name;
  final LatLng point;
  final bool isBirth;
  final VoidCallback onClose;

  const LocationMarkerPopup({
    super.key,
    required this.name,
    required this.point,
    required this.isBirth,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isBirth
        ? const Color(0xFFFFE8A0)
        : const Color(0xFFC9A84C);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xEE0C0C1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: accent.withAlpha(80)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isBirth ? Icons.star_rounded : Icons.place,
              size: 22,
              color: accent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBirth)
                    Text(
                      '出生地',
                      style: GoogleFonts.notoSansJp(
                        fontSize: 9,
                        color: accent,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    name,
                    style: GoogleFonts.notoSansJp(
                      fontSize: 14,
                      color: const Color(0xFFE8E0D0),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtCoord(point.latitude, point.longitude),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF888888),
                      fontFamily: 'monospace',
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Icon(Icons.close, size: 18, color: Color(0xFFAAAAAA)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtCoord(double lat, double lng) {
    final latStr = lat >= 0
        ? '${lat.toStringAsFixed(4)}°N'
        : '${(-lat).toStringAsFixed(4)}°S';
    final lngStr = lng >= 0
        ? '${lng.toStringAsFixed(4)}°E'
        : '${(-lng).toStringAsFixed(4)}°W';
    return '$latStr  $lngStr';
  }
}
