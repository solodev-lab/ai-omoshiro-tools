import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/astro_houses.dart';
import '../../utils/astro_lines.dart';
import '../../widgets/astro_term_label.dart';
import '../horoscope/horo_constants.dart' show planetGlyphs, planetNamesJP, signNames;
import 'map_constants.dart' show planetMeta;

// ══════════════════════════════════════════════════
// Map Relocation Popup — Phase M2 引越しレイヤー (タップ詳細)
//
// 設計: project_solara_astrocartography_m2.md
//   論点11 (9-β改): home設定済み→現住所→引越し先比較
//                  home未設定→出生地→タップ地点比較
//   論点8 (6-D1): デフォルトOFF (LayerPanelで明示的にON)
//   論点10 (8-β):  1タップで線情報+12ハウス情報を統合表示
//                 ・aspect レイヤーON & 線が近い  → 線セクション表示
//                 ・relocate レイヤーON         → ASC/MC + ハウスセクション表示
//                 ・両方ON                      → 全部表示 (統合 popup)
// ══════════════════════════════════════════════════

const _planetOrder = [
  'sun', 'moon', 'mercury', 'venus', 'mars',
  'jupiter', 'saturn', 'uranus', 'neptune', 'pluto',
];

const _personalPlanets = {'sun', 'moon', 'mercury', 'venus', 'mars'};

// アングル別の短い添字 (popup の線セクション用)
const _angleShortJp = {
  'asc': '自我・第一印象',
  'mc': 'キャリア・社会',
  'dsc': '対人・パートナー',
  'ic': '家庭・心の拠り所',
};

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

  /// 引越しレイヤー (ASC/MC + 12ハウス) を表示するか
  /// (relocate トグルがONなら true)
  final bool showHouses;

  /// 近接アスペクト線 (空 or null なら線セクション非表示)
  final List<NearbyAstroLine>? nearbyLines;

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
    this.showHouses = true,
    this.nearbyLines,
  });

  @override
  Widget build(BuildContext context) {
    final hasLines = (nearbyLines != null && nearbyLines!.isNotEmpty);

    // showHouses 時のみ ASC/MC/houses を再計算 (重い処理を回避)
    HousesResult? relocated;
    int ascSignFrom = 0, ascSignTo = 0, mcSignFrom = 0, mcSignTo = 0;
    if (showHouses) {
      relocated = calcHousesRelocate(
        natalMc: baselineMc,
        natalLng: baselineLng,
        tapLat: tapLat,
        tapLng: tapLng,
      );
      ascSignFrom = _signOf(_recoverBaselineAsc());
      ascSignTo = _signOf(relocated.asc);
      mcSignFrom = _signOf(baselineMc);
      mcSignTo = _signOf(relocated.mc);
    }

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
          _buildHeader(showHouses: showHouses, hasLines: hasLines),
          if (hasLines) ...[
            const SizedBox(height: 10),
            _buildLinesSection(nearbyLines!),
          ],
          if (showHouses && relocated != null) ...[
            if (hasLines)
              const Divider(color: Color(0x22FFFFFF), height: 18)
            else
              const SizedBox(height: 10),
            _buildAngleRow('ASC', ascSignFrom, ascSignTo),
            const SizedBox(height: 4),
            _buildAngleRow('MC', mcSignFrom, mcSignTo),
            const Divider(color: Color(0x22FFFFFF), height: 18),
            _buildPlanetGrid(relocated.houses),
          ],
        ],
      ),
    );
  }

  // ── 論点10: 線情報セクション ──
  Widget _buildLinesSection(List<NearbyAstroLine> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timeline, size: 12, color: Color(0xFFB088FF)),
            const SizedBox(width: 6),
            AstroTermLabel(
              termKey: 'aspect_lines',
              iconSize: 10,
              spacing: 2,
              child: Text(
                'ライン上の地点 (近接${lines.length}本)',
                style: GoogleFonts.notoSansJp(
                  fontSize: 11,
                  color: const Color(0xFFB088FF),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 近い順に最大5本表示 (それ以上は省略)
        for (final n in lines.take(5)) _buildLineRow(n),
        if (lines.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 18),
            child: Text(
              '他${lines.length - 5}本',
              style: GoogleFonts.notoSansJp(
                fontSize: 9,
                color: const Color(0xFF666666),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLineRow(NearbyAstroLine n) {
    final meta = planetMeta[n.line.planet];
    final glyph = planetGlyphs[n.line.planet] ?? '';
    final pName = planetNamesJP[n.line.planet] ?? n.line.planet;
    final aLabel = n.line.angle.toUpperCase();
    final shortJp = _angleShortJp[n.line.angle] ?? '';
    final color = meta?.color ?? const Color(0xFFE8E0D0);
    final dist = n.distanceKm;
    final distStr = dist < 10
        ? '${dist.toStringAsFixed(1)}km'
        : '${dist.round()}km';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: Text(glyph, style: TextStyle(fontSize: 13, color: color)),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 50,
            child: Text(
              pName,
              style: GoogleFonts.notoSansJp(
                fontSize: 11, color: color, fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withAlpha(120)),
            ),
            child: Text(
              aLabel,
              style: GoogleFonts.notoSansJp(
                fontSize: 9, color: color, letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              shortJp,
              style: GoogleFonts.notoSansJp(
                fontSize: 10, color: const Color(0xFFAAAAAA),
              ),
            ),
          ),
          Text(
            distStr,
            style: GoogleFonts.notoSansJp(
              fontSize: 9, color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({required bool showHouses, required bool hasLines}) {
    // タイトルは状況に応じて変える
    final String title;
    final String? termKey;
    if (showHouses && hasLines) {
      title = '統合 — ${_fmtCoord(tapLat, tapLng)}';
      termKey = null; // 統合表示は専用辞書なし
    } else if (showHouses) {
      title = '引越しレイヤー — ${_fmtCoord(tapLat, tapLng)}';
      termKey = 'relocate_layer';
    } else {
      title = 'タップ地点 — ${_fmtCoord(tapLat, tapLng)}';
      termKey = 'aspect_lines';
    }

    Widget titleWidget = Text(
      title,
      style: GoogleFonts.notoSansJp(
        fontSize: 11,
        color: const Color(0xFFE8E0D0),
        letterSpacing: 0.6,
      ),
    );
    if (termKey != null) {
      titleWidget = AstroTermLabel(
        termKey: termKey,
        iconSize: 12,
        iconColor: const Color(0xAACCCCCC),
        child: titleWidget,
      );
    }

    return Row(
      children: [
        Icon(Icons.place, size: 14, color: Colors.pink.shade200),
        const SizedBox(width: 6),
        Expanded(child: titleWidget),
        if (showHouses)
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
