import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'horo_constants.dart' show planetNamesJP, signNames;
import 'horo_relocation_templates.dart';

// ══════════════════════════════════════════════════
// Relocation Panel
// 出生地ハウス vs 現住所ハウス の差分を比較形式で解説する。
// 1重円モード + home有効 + houses取得済みの時のみ表示 (Bottom Sheet 拠点タブ)。
// ══════════════════════════════════════════════════

class HouseShift {
  final String planet;     // 'sun' 等
  final int fromHouse;     // 1-12 (出生地ハウス)
  final int toHouse;       // 1-12 (現住所ハウス)
  const HouseShift({required this.planet, required this.fromHouse, required this.toHouse});
}

class HoroRelocationPanel extends StatelessWidget {
  final Map<String, double> natalPlanets;  // 惑星黄経 (relocateで変わらない)
  final List<double> natalHouses;          // 出生地ベースのハウスカスプ12個
  final List<double> relocateHouses;       // 現住所ベースのハウスカスプ12個
  final double natalAsc, natalMc;
  final double relocateAsc, relocateMc;
  final String? birthPlaceName;            // 出生地名 (任意)
  final String? homeName;                  // 現住所名 (任意)

  const HoroRelocationPanel({
    super.key,
    required this.natalPlanets,
    required this.natalHouses,
    required this.relocateHouses,
    required this.natalAsc,
    required this.natalMc,
    required this.relocateAsc,
    required this.relocateMc,
    this.birthPlaceName,
    this.homeName,
  });

  /// 黄経からハウス番号(1-12)を算出
  static int? _houseOf(double lon, List<double> houses) {
    if (houses.length != 12) return null;
    lon = lon % 360;
    for (int i = 0; i < 12; i++) {
      final cusp = houses[i] % 360;
      final next = houses[(i + 1) % 12] % 360;
      final inHouse = (cusp <= next)
          ? (lon >= cusp && lon < next)
          : (lon >= cusp || lon < next);
      if (inHouse) return i + 1;
    }
    return null;
  }

  /// natal惑星のハウス位置を全て抽出 (変化なし含む、重要度順ソート済み)
  List<HouseShift> _computeAllPositions() {
    final shifts = <HouseShift>[];
    for (final planetKey in planetPriority) {
      final lon = natalPlanets[planetKey];
      if (lon == null) continue;
      final from = _houseOf(lon, natalHouses);
      final to = _houseOf(lon, relocateHouses);
      if (from == null || to == null) continue;
      shifts.add(HouseShift(planet: planetKey, fromHouse: from, toHouse: to));
    }
    return shifts;
  }

  @override
  Widget build(BuildContext context) {
    if (natalHouses.length != 12 || relocateHouses.length != 12) {
      return const SizedBox.shrink();
    }

    final positions = _computeAllPositions();
    final ascFromIdx = (natalAsc / 30).floor() % 12;
    final ascToIdx = (relocateAsc / 30).floor() % 12;
    final mcFromIdx = (natalMc / 30).floor() % 12;
    final mcToIdx = (relocateMc / 30).floor() % 12;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          // ASC/MC: 変化有無問わず常時表示
          _buildAngleBlock('ASC', ascFromIdx, ascToIdx, ascInSignDescriptions),
          _buildAngleBlock('MC', mcFromIdx, mcToIdx, mcInSignDescriptions),
          // 全惑星 (変化なし含む)
          ...positions.map(_buildShiftBlock),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final from = (birthPlaceName == null || birthPlaceName!.isEmpty) ? '出生地' : birthPlaceName!;
    final to = (homeName == null || homeName!.isEmpty) ? '現住所' : homeName!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RELOCATION',
          style: GoogleFonts.cinzel(
            fontSize: 13,
            color: const Color(0xFFF6BD60),
            letterSpacing: 2.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$from → $to の比較',
          style: GoogleFonts.notoSansJp(
            fontSize: 11,
            color: const Color(0xCCCCCCCC),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// ASC/MC ブロック (星座変化の比較、変化なしも表示)
  Widget _buildAngleBlock(
    String label, int fromIdx, int toIdx, Map<int, String> descriptions,
  ) {
    final changed = fromIdx != toIdx;
    return Opacity(
      opacity: changed ? 1.0 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: changed ? const Color(0x1AF6BD60) : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: changed ? const Color(0x33F6BD60) : const Color(0x22FFFFFF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー: ASC: 山羊座 → 乙女座 / または ASC: 山羊座 → 変化なし
            Row(children: [
              Text(
                '$label  ',
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  color: const Color(0xFFF6BD60),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                changed
                    ? '${signNames[fromIdx]}座 → ${signNames[toIdx]}座'
                    : '${signNames[fromIdx]}座 → 変化なし',
                style: GoogleFonts.notoSansJp(
                  fontSize: 12,
                  color: const Color(0xFFE8E0D0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ]),
            const SizedBox(height: 6),
            _buildCompareRow('出生地', descriptions[fromIdx] ?? '', false),
            const SizedBox(height: 3),
            _buildCompareRow('現住所', changed ? (descriptions[toIdx] ?? '') : '変化なし', true),
          ],
        ),
      ),
    );
  }

  /// 惑星 shift ブロック (ハウス変化の比較、変化なしも表示)
  Widget _buildShiftBlock(HouseShift shift) {
    final changed = shift.fromHouse != shift.toHouse;
    final name = planetNamesJP[shift.planet] ?? shift.planet;
    final fromMsg = planetInHouseMessages[shift.planet]?[shift.fromHouse] ?? '';
    final toMsg = planetInHouseMessages[shift.planet]?[shift.toHouse] ?? '';
    final isPersonal = personalPlanets.contains(shift.planet);
    final headerColor = isPersonal
        ? const Color(0xFFF6BD60)
        : const Color(0xCCDDDDDD);

    // 変化なしのものは透明度を下げて目立たなくする
    return Opacity(
      opacity: changed ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: changed
              ? (isPersonal ? const Color(0x14F6BD60) : const Color(0x0AFFFFFF))
              : const Color(0x06FFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: changed
                ? (isPersonal ? const Color(0x33F6BD60) : const Color(0x22FFFFFF))
                : const Color(0x14FFFFFF),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(
                name,
                style: GoogleFonts.notoSansJp(
                  fontSize: 13,
                  color: headerColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                changed
                    ? '${shift.fromHouse}H → ${shift.toHouse}H'
                    : '${shift.fromHouse}H → 変化なし',
                style: const TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontFamily: 'Courier New',
                  fontSize: 12,
                ),
              ),
            ]),
            const SizedBox(height: 6),
            _buildCompareRow('出生地', fromMsg, false),
            const SizedBox(height: 3),
            _buildCompareRow('現住所', changed ? toMsg : '変化なし', true),
          ],
        ),
      ),
    );
  }

  /// 「出生地: ○○」「現住所: ○○」の1行
  Widget _buildCompareRow(String label, String text, bool emphasized) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 44,
        child: Text(
          label,
          style: GoogleFonts.notoSansJp(
            fontSize: 10,
            color: emphasized ? const Color(0xFFF6BD60) : const Color(0xFF888888),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.notoSansJp(
            fontSize: 12,
            color: emphasized ? const Color(0xFFE8E0D0) : const Color(0xCCBBBBBB),
            height: 1.5,
          ),
        ),
      ),
    ]);
  }
}
