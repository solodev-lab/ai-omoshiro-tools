import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/astro_houses.dart';
import '../../widgets/astro_term_label.dart';
import '../horoscope/horo_constants.dart' show planetGlyphs, planetNamesJP, signNames;

// ══════════════════════════════════════════════════
// Map Relocation Popup — Phase M2 引越しレイヤー (タップ詳細)
//
// 引越しレイヤーON時、地図タップで表示される floating sheet。
// タップ地点で natal 惑星のハウス位置を再計算し、
// home (現住所) ベースのハウスとの差分を表示。
//
// 設計: project_solara_astrocartography_m2.md
//   論点11 (9-β改): home設定済み→現住所→引越し先比較
//                  home未設定→出生地→タップ地点比較
//   論点8 (6-D1): デフォルトOFF (LayerPanelで明示的にON)
//   論点10は別セッションで論点3完成後に統合ポップアップへ拡張
// ══════════════════════════════════════════════════

const _planetOrder = [
  'sun', 'moon', 'mercury', 'venus', 'mars',
  'jupiter', 'saturn', 'uranus', 'neptune', 'pluto',
];

const _personalPlanets = {'sun', 'moon', 'mercury', 'venus', 'mars'};

class MapRelocationPopup extends StatelessWidget {
  /// タップ地点
  final double tapLat;
  final double tapLng;

  /// 出生時刻ベースのチャート (Worker fetchChart の結果)
  final Map<String, double> natalPlanets; // 10惑星黄経 (relocateで不変)
  final double baselineMc;   // 比較ベース (home or birth) のMC
  final double baselineLng;  // 比較ベース (home or birth) のlng
  final List<double> baselineHouses; // 比較ベースのハウス12個

  /// 比較ベースが home(現住所) か birth(出生地) かのラベル用
  final String baselineLabel;

  final VoidCallback onClose;

  const MapRelocationPopup({
    super.key,
    required this.tapLat,
    required this.tapLng,
    required this.natalPlanets,
    required this.baselineMc,
    required this.baselineLng,
    required this.baselineHouses,
    required this.baselineLabel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final relocated = calcHousesRelocate(
      natalMc: baselineMc,
      natalLng: baselineLng,
      tapLat: tapLat,
      tapLng: tapLng,
    );

    final ascSignFrom = _signOf(_recoverBaselineAsc());
    final ascSignTo = _signOf(relocated.asc);
    final mcSignFrom = _signOf(baselineMc);
    final mcSignTo = _signOf(relocated.mc);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xEE0C0C1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: const Color(0x33C9A84C)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildAngleRow('ASC', ascSignFrom, ascSignTo),
          const SizedBox(height: 4),
          _buildAngleRow('MC', mcSignFrom, mcSignTo),
          const Divider(color: Color(0x22FFFFFF), height: 18),
          _buildPlanetGrid(relocated.houses),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.place, size: 14, color: Colors.pink.shade200),
        const SizedBox(width: 6),
        Expanded(
          child: AstroTermLabel(
            termKey: 'relocate_layer',
            iconSize: 12,
            iconColor: const Color(0xAACCCCCC),
            child: Text(
              '引越しレイヤー — ${_fmtCoord(tapLat, tapLng)}',
              style: GoogleFonts.notoSansJp(
                fontSize: 11,
                color: const Color(0xFFE8E0D0),
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
        Text(
          '$baselineLabel → タップ地点',
          style: GoogleFonts.notoSansJp(
            fontSize: 9,
            color: const Color(0xFF888888),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onClose,
          child: const Icon(Icons.close, size: 16, color: Color(0xFF888888)),
        ),
      ],
    );
  }

  Widget _buildAngleRow(String label, int signFrom, int signTo) {
    final changed = signFrom != signTo;
    final termKey = label.toLowerCase(); // 'asc' or 'mc'
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: AstroTermLabel(
            termKey: termKey,
            iconSize: 10,
            spacing: 2,
            child: Text(
              label,
              style: GoogleFonts.notoSansJp(
                fontSize: 11,
                color: const Color(0xFFC9A84C),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        Text(
          '${signNames[signFrom]}座',
          style: GoogleFonts.notoSansJp(
            fontSize: 11,
            color: const Color(0xFFAAAAAA),
          ),
        ),
        const SizedBox(width: 6),
        Icon(
          Icons.arrow_forward,
          size: 11,
          color: changed
              ? const Color(0xFFFFB6C1)
              : const Color(0xFF555555),
        ),
        const SizedBox(width: 6),
        Text(
          '${signNames[signTo]}座',
          style: GoogleFonts.notoSansJp(
            fontSize: 11,
            color: changed
                ? const Color(0xFFFFD370)
                : const Color(0xFFAAAAAA),
            fontWeight: changed ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        const Spacer(),
        if (!changed)
          Text(
            '変化なし',
            style: GoogleFonts.notoSansJp(
              fontSize: 9,
              color: const Color(0xFF555555),
            ),
          ),
      ],
    );
  }

  Widget _buildPlanetGrid(List<double> tapHouses) {
    return Column(
      children: [
        for (final planet in _planetOrder)
          _buildPlanetRow(planet, tapHouses),
      ],
    );
  }

  Widget _buildPlanetRow(String planet, List<double> tapHouses) {
    final lon = natalPlanets[planet];
    if (lon == null) return const SizedBox.shrink();
    final fromHouse = assignPlanetHouse(lon, baselineHouses);
    final toHouse = assignPlanetHouse(lon, tapHouses);
    final changed = fromHouse != null && toHouse != null && fromHouse != toHouse;
    final isPersonal = _personalPlanets.contains(planet);

    final dimColor = changed
        ? Colors.white.withAlpha(230)
        : Colors.white.withAlpha(110);
    final accentColor = changed
        ? (isPersonal ? const Color(0xFFFFD370) : const Color(0xFFFFB6C1))
        : const Color(0xFF888888);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text(
              planetGlyphs[planet] ?? '',
              style: TextStyle(fontSize: 14, color: dimColor),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 50,
            child: Text(
              planetNamesJP[planet] ?? planet,
              style: GoogleFonts.notoSansJp(fontSize: 11, color: dimColor),
            ),
          ),
          Text(
            fromHouse != null ? '${fromHouse}H' : '—',
            style: GoogleFonts.notoSansJp(
              fontSize: 11,
              color: const Color(0xFFAAAAAA),
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward, size: 11, color: accentColor),
          const SizedBox(width: 6),
          Text(
            toHouse != null ? '${toHouse}H' : '—',
            style: GoogleFonts.notoSansJp(
              fontSize: 11,
              color: accentColor,
              fontWeight: changed ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          const Spacer(),
          if (changed && isPersonal)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x55FFD370)),
              ),
              child: Text(
                '個人天体',
                style: GoogleFonts.notoSansJp(
                  fontSize: 8,
                  color: const Color(0xFFFFD370),
                ),
              ),
            )
          else if (!changed)
            Text(
              '変化なし',
              style: GoogleFonts.notoSansJp(
                fontSize: 9,
                color: const Color(0xFF555555),
              ),
            ),
        ],
      ),
    );
  }

  /// baselineMc を起点に baselineHouses[0]=ASC を取得 (Placidus定義より houses[0]=asc)
  double _recoverBaselineAsc() {
    if (baselineHouses.length == 12) return baselineHouses[0];
    return baselineMc; // フォールバック (本来到達しない)
  }

  int _signOf(double lon) {
    final n = (lon % 360 + 360) % 360;
    return (n / 30).floor() % 12;
  }

  String _fmtCoord(double lat, double lng) {
    final latStr = lat >= 0 ? '${lat.toStringAsFixed(2)}°N' : '${(-lat).toStringAsFixed(2)}°S';
    final lngStr = lng >= 0 ? '${lng.toStringAsFixed(2)}°E' : '${(-lng).toStringAsFixed(2)}°W';
    return '$latStr  $lngStr';
  }
}
