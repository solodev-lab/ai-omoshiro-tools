import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/astro_houses.dart' show assignPlanetHouse;
import 'horo_constants.dart' show planetGlyphs, planetNamesJP;
import 'horo_relocation_lines.dart';

// ══════════════════════════════════════════════════
// Relocation Panel (ライン近接版 — 2026-06-02 再設計、feature_inventory §0.2.52)
//
// 旧版: 「出生地ハウス vs 現住所ハウス」の差分。近距離移動ではハウスが変わらず
//   「変化なし」だらけになり、Pro(Gemini)解説も生成されず "何に金払った?" 問題があった。
//
// 新版: 「どの惑星ラインに近づいた / 遠ざかったか」を主役に。緯度経度が違えば線距離は
//   必ず変わるので「変化なし」が原理的に消える。Solara の核心(マップの惑星ライン)と地続き。
//   全て静的 (Gemini 不使用 = ¥0)・全員無料。計算と意味文は horo_relocation_lines.dart。
//   ハウス変化は「実際に変わった惑星だけ」副次表示 + 静的コメント。
//
// 1重円モード + home有効 + houses取得済みの時のみ Bottom Sheet「拠点」タブに表示。
// ══════════════════════════════════════════════════

/// 上位何本のライン近接デルタを表示するか。
const int _kTopLines = 4;

/// 「ほぼ同じ場所」と見なすデルタ上限 (km)。これ未満しか無ければ移動なし扱い。
const double _kSamePlaceKm = 1.0;

class HoroRelocationPanel extends StatefulWidget {
  final Map<String, double> natalPlanets; // 惑星黄経 (relocate で変わらない)
  final List<double> natalHouses;          // 出生地ベースのハウスカスプ12個
  final List<double> relocateHouses;       // 現住所ベースのハウスカスプ12個
  final double natalAsc, natalMc;
  final double relocateAsc, relocateMc;
  final double birthLat, birthLng;         // 出生地座標 (ライン距離計算に必須)
  final double homeLat, homeLng;           // 現住所座標
  final String? birthPlaceName;            // 出生地名 (任意・ヘッダ表示)
  final String? homeName;                  // 現住所名 (任意・ヘッダ表示)

  const HoroRelocationPanel({
    super.key,
    required this.natalPlanets,
    required this.natalHouses,
    required this.relocateHouses,
    required this.natalAsc,
    required this.natalMc,
    required this.relocateAsc,
    required this.relocateMc,
    required this.birthLat,
    required this.birthLng,
    required this.homeLat,
    required this.homeLng,
    this.birthPlaceName,
    this.homeName,
  });

  @override
  State<HoroRelocationPanel> createState() => _HoroRelocationPanelState();
}

class _HoroRelocationPanelState extends State<HoroRelocationPanel> {
  /// ライン近接デルタ (|delta| 降順)。計算は座標が変わった時のみ。
  List<RelocationLineDelta> _deltas = const [];
  /// ハウスが実際に変わった惑星のみ (7惑星)。
  List<({String planet, int from, int to})> _houseChanges = const [];

  @override
  void initState() {
    super.initState();
    _recompute();
  }

  @override
  void didUpdateWidget(covariant HoroRelocationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.birthLat != widget.birthLat ||
        oldWidget.birthLng != widget.birthLng ||
        oldWidget.homeLat != widget.homeLat ||
        oldWidget.homeLng != widget.homeLng ||
        oldWidget.natalMc != widget.natalMc) {
      _recompute();
    }
  }

  void _recompute() {
    if (widget.natalPlanets.isEmpty) {
      _deltas = const [];
      _houseChanges = const [];
      return;
    }
    _deltas = computeRelocationLineDeltas(
      natalPlanets: widget.natalPlanets,
      natalMc: widget.natalMc,
      birthLat: widget.birthLat,
      birthLng: widget.birthLng,
      homeLat: widget.homeLat,
      homeLng: widget.homeLng,
    );
    // ハウス変化 (7惑星・変化したものだけ)
    final changes = <({String planet, int from, int to})>[];
    if (widget.natalHouses.length == 12 && widget.relocateHouses.length == 12) {
      for (final planet in relocationLinePlanets) {
        final lon = widget.natalPlanets[planet];
        if (lon == null) continue;
        final from = assignPlanetHouse(lon, widget.natalHouses);
        final to = assignPlanetHouse(lon, widget.relocateHouses);
        if (from == null || to == null || from == to) continue;
        changes.add((planet: planet, from: from, to: to));
      }
    }
    _houseChanges = changes;
  }

  @override
  Widget build(BuildContext context) {
    final top = _deltas.take(_kTopLines).toList();
    final maxAbs = _deltas.isEmpty ? 0.0 : _deltas.first.deltaKm.abs();
    final samePlace = maxAbs < _kSamePlaceKm;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          if (samePlace)
            _buildSamePlaceHint()
          else ...[
            _buildSectionTitle('この移動で変わる星のライン'),
            const SizedBox(height: 8),
            ...top.map(_buildLineDeltaCard),
            if (_houseChanges.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildSectionTitle('ハウスの移り変わり'),
              const SizedBox(height: 8),
              ..._houseChanges.map(_buildHouseChangeCard),
            ],
            const SizedBox(height: 10),
            _buildFootnote(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final from = (widget.birthPlaceName == null || widget.birthPlaceName!.isEmpty)
        ? '出生地'
        : widget.birthPlaceName!;
    final to = (widget.homeName == null || widget.homeName!.isEmpty)
        ? '現住所'
        : widget.homeName!;
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
          '$from → $to で、近づく星・遠ざかる星',
          style: GoogleFonts.notoSansJp(
            fontSize: 11,
            color: const Color(0xCCCCCCCC),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: GoogleFonts.notoSansJp(
        fontSize: 12,
        color: const Color(0xFFF6BD60),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  /// ライン近接デルタ 1 枚 (近=金色 / 遠=控えめ)。
  Widget _buildLineDeltaCard(RelocationLineDelta d) {
    final glyph = planetGlyphs[d.planet] ?? '';
    final planet = planetNamesJP[d.planet] ?? d.planet;
    final angle = d.angle.toUpperCase();
    final adv = relocationMagnitudeAdverb(d.deltaKm.abs());
    final closer = d.closer;
    final accent = closer ? const Color(0xFFF6BD60) : const Color(0xFF9FB4C7);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: closer ? const Color(0x14F6BD60) : const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: closer ? const Color(0x33F6BD60) : const Color(0x1FFFFFFF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Flexible(
              child: Text(
                '$glyph $planet の$angleライン',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansJp(
                  fontSize: 13,
                  color: const Color(0xFFE8E0D0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              closer ? '▲ $adv近づく' : '▽ $adv遠ざかる',
              style: GoogleFonts.notoSansJp(
                fontSize: 11,
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            relocationLineDeltaSentence(d),
            style: GoogleFonts.notoSansJp(
              fontSize: 12,
              color: const Color(0xFFD8D2C6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// ハウス変化 1 枚 (変化した惑星のみ)。
  Widget _buildHouseChangeCard(({String planet, int from, int to}) c) {
    final glyph = planetGlyphs[c.planet] ?? '';
    final planet = planetNamesJP[c.planet] ?? c.planet;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(
              '$glyph $planet',
              style: GoogleFonts.notoSansJp(
                fontSize: 13,
                color: const Color(0xFFE8E0D0),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${c.from}H → ${c.to}H',
              style: const TextStyle(
                color: Color(0xFFAAAAAA),
                fontFamily: 'Courier New',
                fontSize: 12,
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            relocationHouseChangeComment(c.planet, c.from, c.to),
            style: GoogleFonts.notoSansJp(
              fontSize: 12,
              color: const Color(0xFFD8D2C6),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSamePlaceHint() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Text(
        '出生地と現住所がほぼ同じ場所です。遠くへ移るほど、星のラインとの距離がはっきり変わります。',
        style: GoogleFonts.notoSansJp(
          fontSize: 12,
          color: const Color(0xFFB8B2A6),
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildFootnote() {
    return Text(
      '※ ラインに近いほど、その星のテーマがその土地で前に出ます。吉凶ではなく「強まる／やわらぐ」の傾きです。',
      style: GoogleFonts.notoSansJp(
        fontSize: 10,
        color: const Color(0xFF888888),
        height: 1.5,
      ),
    );
  }
}
