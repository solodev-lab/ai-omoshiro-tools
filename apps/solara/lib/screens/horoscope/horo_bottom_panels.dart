import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/solara_storage.dart';
import 'horo_constants.dart';
import 'horo_antique_icons.dart';
import 'horo_astro_glyphs.dart';
import 'horo_aspect_description.dart';

// ─── 星座画像のファイル名 ───
const List<String> _zodiacFiles = [
  'aries', 'taurus', 'gemini', 'cancer', 'leo', 'virgo',
  'libra', 'scorpio', 'sagittarius', 'capricorn', 'aquarius', 'pisces',
];

/// 惑星ベクターグリフ (チャートと同じデザイン)
/// angle(asc/mc/dsc/ic) のキーの場合はAntique記号で代用
class PlanetVectorIcon extends StatelessWidget {
  final String planetKey;
  final double size;
  final Color color;
  const PlanetVectorIcon({
    super.key, required this.planetKey,
    this.size = 18, this.color = const Color(0xFFFFD370),
  });
  @override
  Widget build(BuildContext context) {
    // Angle keys (asc/mc/dsc/ic) → 文字ラベルとして描画
    if (const {'asc','mc','dsc','ic'}.contains(planetKey)) {
      return SizedBox(
        width: size, height: size,
        child: Center(child: Text(
          planetKey.substring(0, 1).toUpperCase(),
          style: GoogleFonts.cinzel(
            fontSize: size * 0.75, fontWeight: FontWeight.w700,
            color: color, letterSpacing: 0.5),
        )),
      );
    }
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _PlanetGlyphPainter(planetKey, color)),
    );
  }
}

class _PlanetGlyphPainter extends CustomPainter {
  final String planetKey;
  final Color color;
  _PlanetGlyphPainter(this.planetKey, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    final matrix = Float64List.fromList([
      scale, 0, 0, 0,
      0, scale, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]);
    final path = planetGlyph(planetKey).transform(matrix);
    canvas.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }
  @override
  bool shouldRepaint(covariant _PlanetGlyphPainter old) =>
      old.planetKey != planetKey || old.color != color;
}

/// 星座画像シンボル (assets/zodiac-symbols/*.webp + 黒透過)
class ZodiacImageIcon extends StatelessWidget {
  final int signIdx;
  final double size;
  const ZodiacImageIcon({super.key, required this.signIdx, this.size = 18});
  @override
  Widget build(BuildContext context) {
    final i = signIdx.clamp(0, 11);
    return SizedBox(
      width: size, height: size,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          1.70, 5.72, 0.58, 0, 0, // 純黒のみ透明
        ]),
        child: Image.asset(
          'assets/zodiac-symbols/${_zodiacFiles[i]}.webp',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Helper: antique-style panel header row (icon + label).
Widget _antiqueHeader(AntiqueIcon icon, String label, {double iconSize = 18}) {
  return Row(children: [
    AntiqueGlyph(icon: icon, size: iconSize, color: const Color(0xFFF6BD60)),
    const SizedBox(width: 8),
    Text(label, style: GoogleFonts.cinzel(
      fontSize: 13, color: const Color(0xFFF6BD60),
      letterSpacing: 2.5, fontWeight: FontWeight.w600)),
  ]);
}

// ══════════════════════════════════════════════════
// Birth Section (BS tab)
// HTML: #bsBirth — profile info display
// ══════════════════════════════════════════════════

class HoroBirthPanel extends StatelessWidget {
  final SolaraProfile profile;
  /// 編集されているか (base と異なるか)
  final bool isEdited;
  /// 編集開始 (呼び出し側でエディタpush → 結果を_applyWorkingProfileに渡す)
  final VoidCallback? onEdit;
  /// base に戻す
  final VoidCallback? onReset;
  const HoroBirthPanel({
    super.key, required this.profile,
    this.isEdited = false, this.onEdit, this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final p = profile;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header row with edit notice (when edited)
      Row(children: [
        _antiqueHeader(AntiqueIcon.birth, 'BIRTH DATA'),
        const SizedBox(width: 8),
        if (isEdited) Expanded(child: Text(
          '※ Horo画面から離れるとBIRTH DATAは初期化されます',
          style: TextStyle(
            fontSize: 10,
            color: const Color(0xFFFF9E6B).withAlpha(220),
            fontStyle: FontStyle.italic,
          ),
          overflow: TextOverflow.visible,
          softWrap: true,
        )),
      ]),
      const SizedBox(height: 10),
      _bsInfoRow('氏名 NAME', p.name.isEmpty ? '未設定' : p.name),
      _bsInfoRow('生年月日 DATE', p.birthDate),
      _bsInfoRow('出生時刻 TIME', p.birthTimeUnknown ? '不明' : p.birthTime),
      _bsInfoRow('出生地 BIRTHPLACE', p.birthPlace.isEmpty ? '未設定' : p.birthPlace),
      if (p.birthLat != 0) ...[
        _bsInfoRow('緯度/経度', '${p.birthLat.toStringAsFixed(4)} / ${p.birthLng.toStringAsFixed(4)}'),
      ],
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: GestureDetector(
          onTap: onEdit,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFF6BD60), Color(0xFFE8A840)],
              ),
            ),
            child: const Center(child: Text('編集してホロスコープを試算', style: TextStyle(
              color: Color(0xFF0A0A14), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1))),
          ),
        )),
        if (isEdited) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onReset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x66F6BD60)),
              ),
              child: Text('リセット', style: GoogleFonts.cinzel(
                fontSize: 12, color: const Color(0xFFF6BD60),
                letterSpacing: 1.5, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ]),
    ]);
  }

  Widget _bsInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1)),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0))),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════
// Transit Section (BS tab)
// HTML: #bsTransit — transit date/time/location
// ══════════════════════════════════════════════════

class HoroTransitPanel extends StatelessWidget {
  final String chartMode;
  const HoroTransitPanel({super.key, required this.chartMode});

  @override
  Widget build(BuildContext context) {
    final label = chartMode == 'np' ? 'プログレス更新' : 'トランジット更新';
    final btnColor = chartMode == 'np' ? const Color(0xFFB088FF) : const Color(0xFF6BB5FF);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _antiqueHeader(
        chartMode == 'np' ? AntiqueIcon.progressed : AntiqueIcon.transit,
        chartMode == 'np' ? 'PROGRESSED DATA' : 'TRANSIT DATA'),
      const SizedBox(height: 10),
      _bsInfoRow('日付 DATE', DateTime.now().toString().split(' ')[0]),
      _bsInfoRow('時刻 TIME', '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [btnColor, btnColor.withAlpha(200)],
          ),
        ),
        child: Center(child: Text(label, style: const TextStyle(
          color: Color(0xFF0A0A14), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1))),
      ),
    ]);
  }

  Widget _bsInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888), letterSpacing: 1)),
        const SizedBox(height: 3),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFFE8E0D0))),
        ),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════
// Planet Table
// HTML: .planet-row
// ══════════════════════════════════════════════════

class HoroPlanetTable extends StatelessWidget {
  final Map<String, double> natalPlanets;
  final double asc, mc;
  final bool birthTimeUnknown;
  /// 2重円モード用: トランジット or プログレスの惑星位置
  final Map<String, double>? secondaryPlanets;
  /// 2重円モード用: トランジット or プログレスの ASC/MC (省略可)
  final double? secondaryAsc, secondaryMc;
  /// 'nt' → 'TRANSIT', 'np' → 'PROGRESSED', それ以外 null
  final String? chartMode;
  const HoroPlanetTable({
    super.key,
    required this.natalPlanets,
    required this.asc, required this.mc,
    required this.birthTimeUnknown,
    this.secondaryPlanets, this.secondaryAsc, this.secondaryMc,
    this.chartMode,
  });

  bool get _hasSecondary =>
      (chartMode == 'nt' || chartMode == 'np') &&
      secondaryPlanets != null && secondaryPlanets!.isNotEmpty;

  String get _secondaryLabel => chartMode == 'np' ? 'PROGRESSED' : 'TRANSIT';
  Color get _secondaryColor => chartMode == 'np'
      ? const Color(0xFFB088FF) : const Color(0xFF6BB5FF);
  AntiqueIcon get _secondaryIcon =>
      chartMode == 'np' ? AntiqueIcon.progressed : AntiqueIcon.transit;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (_hasSecondary) ...[
        // ── Top: Transit/Progressed ──
        Align(
          alignment: Alignment.centerLeft,
          child: Row(children: [
            AntiqueGlyph(icon: _secondaryIcon, size: 18, color: _secondaryColor),
            const SizedBox(width: 8),
            Text('$_secondaryLabel POSITIONS', style: GoogleFonts.cinzel(
              fontSize: 13, color: _secondaryColor,
              letterSpacing: 2.5, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 10),
        if (secondaryAsc != null && secondaryMc != null) ...[
          _planetRow('ASC', 'asc', secondaryAsc!, color: _secondaryColor),
          _planetRow('MC',  'mc',  secondaryMc!,  color: _secondaryColor),
          _planetRow('DSC', 'dsc', (secondaryAsc! + 180) % 360, color: _secondaryColor),
          _planetRow('IC',  'ic',  (secondaryMc!  + 180) % 360, color: _secondaryColor),
          Container(height: 1, color: const Color(0x0AFFFFFF), margin: const EdgeInsets.symmetric(vertical: 4)),
        ],
        ...secondaryPlanets!.entries.map((e) => _planetRow(
          planetNamesJP[e.key] ?? e.key,
          e.key,
          e.value,
          color: _secondaryColor,
        )),
        const SizedBox(height: 16),
      ],
      // ── Bottom: Natal ──
      Align(
        alignment: Alignment.centerLeft,
        child: Row(children: [
          const AntiqueGlyph(icon: AntiqueIcon.planets, size: 18,
            color: Color(0xFFF6BD60)),
          const SizedBox(width: 8),
          Text(_hasSecondary ? 'NATAL POSITIONS' : 'PLANET POSITIONS',
            style: GoogleFonts.cinzel(
              fontSize: 13, color: const Color(0xFFF6BD60),
              letterSpacing: 2.5, fontWeight: FontWeight.w600)),
        ]),
      ),
      const SizedBox(height: 10),
      if (!birthTimeUnknown) ...[
        _planetRow('ASC', 'asc', asc),
        _planetRow('MC', 'mc', mc),
        _planetRow('DSC', 'dsc', (asc + 180) % 360),
        _planetRow('IC', 'ic', (mc + 180) % 360),
        Container(height: 1, color: const Color(0x0AFFFFFF), margin: const EdgeInsets.symmetric(vertical: 4)),
      ],
      ...natalPlanets.entries.map((e) => _planetRow(
        planetNamesJP[e.key] ?? e.key,
        e.key,
        e.value)),
    ]);
  }

  Widget _planetRow(String name, String planetKey, double lon, {Color? color}) {
    final signIdx = (lon / 30).floor() % 12;
    final deg = lon % 30;
    final iconColor = color ?? const Color(0xFFFFD370);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0AFFFFFF))),
      ),
      child: Row(children: [
        SizedBox(width: 24, child: Center(
          child: PlanetVectorIcon(planetKey: planetKey, size: 18, color: iconColor),
        )),
        SizedBox(width: 60, child: Text(name, style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13))),
        ZodiacImageIcon(signIdx: signIdx, size: 18),
        const SizedBox(width: 4),
        Text('${deg.toStringAsFixed(1)}°', style: const TextStyle(
          color: Color(0xFFE8E0D0), fontFamily: 'Courier New', fontSize: 13)),
        const SizedBox(width: 4),
        Text(signNames[signIdx], style: TextStyle(
          color: Color(signColors[signIdx]).withAlpha(180), fontSize: 13)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════
// Filter Panel
// HTML: .filter-section, .filter-chips, .filter-chip
// ══════════════════════════════════════════════════

class HoroFilterPanel extends StatelessWidget {
  final Map<String, bool> qualityFilters;
  final Map<String, bool> pgroupFilters;
  final String? fortuneFilter;
  final VoidCallback onReset;
  final void Function(String key, bool value) onQualityChanged;
  final void Function(String key, bool value) onPgroupChanged;
  final ValueChanged<String?> onFortuneChanged;

  const HoroFilterPanel({
    super.key,
    required this.qualityFilters,
    required this.pgroupFilters,
    required this.fortuneFilter,
    required this.onReset,
    required this.onQualityChanged,
    required this.onPgroupChanged,
    required this.onFortuneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _antiqueHeader(AntiqueIcon.filter, 'ASPECT FILTER'),
        GestureDetector(
          onTap: onReset,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0x1AFFFFFF)),
            ),
            child: Text('RESET', style: GoogleFonts.cinzel(
              fontSize: 11, color: const Color(0xFF888888),
              letterSpacing: 2.0, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
      const SizedBox(height: 10),

      // A: Aspect Quality
      _filterSection('A', 'アスペクト性質', [
        _filterChip('ソフト（調和）', 'soft', const Color(0xFFC9A84C), qualityFilters['soft']!, (v) => onQualityChanged('soft', v)),
        _filterChip('ハード（緊張）', 'hard', const Color(0xFF6B5CE7), qualityFilters['hard']!, (v) => onQualityChanged('hard', v)),
        _filterChip('中立', 'neutral', const Color(0xFF26D0CE), qualityFilters['neutral']!, (v) => onQualityChanged('neutral', v)),
      ]),

      // B: Fortune Category
      _filterSection('B', '運勢カテゴリ', [
        _exclusiveChip('癒し', 'healing', const Color(0xFF26D0CE)),
        _exclusiveChip('金運', 'money', const Color(0xFFFFD370)),
        _exclusiveChip('恋愛運', 'love', const Color(0xFFFF6B9D)),
        _exclusiveChip('仕事運', 'career', const Color(0xFFFF8C42)),
        _exclusiveChip('コミュニケーション', 'communication', const Color(0xFF6BB5FF)),
      ]),

      // C: Planet Group
      _filterSection('C', '惑星グループ', [
        _filterChip('個人天体', 'personal', const Color(0xFFFFD370), pgroupFilters['personal']!, (v) => onPgroupChanged('personal', v)),
        _filterChip('社会天体', 'social', const Color(0xFF6BB5FF), pgroupFilters['social']!, (v) => onPgroupChanged('social', v)),
        _filterChip('世代天体', 'generational', const Color(0xFFB088FF), pgroupFilters['generational']!, (v) => onPgroupChanged('generational', v)),
      ]),
    ]);
  }

  Widget _filterSection(String badge, String title, List<Widget> chips) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x0DFFFFFF))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(badge, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFAAAAAA))),
          ),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF888888), letterSpacing: 1.5)),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 4, runSpacing: 4, children: chips),
      ]),
    );
  }

  Widget _filterChip(String label, String key, Color color, bool active, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? color : const Color(0x1AFFFFFF)),
          color: active ? color.withAlpha(20) : const Color(0x08FFFFFF),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: active ? color : const Color(0xFF888888))),
      ),
    );
  }

  Widget _exclusiveChip(String label, String key, Color color) {
    final active = fortuneFilter == key;
    return GestureDetector(
      onTap: () => onFortuneChanged(active ? null : key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? color : const Color(0x1AFFFFFF)),
          color: active ? color.withAlpha(20) : const Color(0x08FFFFFF),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: active ? color : const Color(0xFF888888))),
      ),
    );
  }
}

// ══════════════════════════════════════════════════
// Aspect List
// HTML: aspect-lists-row in analysis-body
// ══════════════════════════════════════════════════

class HoroAspectList extends StatelessWidget {
  final List<Map<String, dynamic>> filteredAspects;
  final Set<String> hiddenAspects;
  final ValueChanged<String> onToggleAspect;
  const HoroAspectList({super.key, required this.filteredAspects, required this.hiddenAspects, required this.onToggleAspect});

  // Handle both planet keys and angle keys (asc/mc/dsc/ic)
  String _nameFor(String key) => planetNamesJP[key] ?? angleNamesJP[key] ?? key.toUpperCase();

  void _showAspectDescription(BuildContext context, Map<String, dynamic> a) {
    final p1 = a['p1'] as String;
    final p2 = a['p2'] as String;
    final type = a['type'] as String;
    final color = a['color'] as Color;
    final diff = a['diff'] as double;
    final desc = buildAspectDescription(p1, p2, type);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xF00C0C16),
      barrierColor: Colors.black54,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 16,
          bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close button (top right)
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CustomPaint(
                      painter: _CloseXPainter(
                        color: const Color(0xFFC9A84C).withAlpha(220)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Title row: planet × planet with icons
            Row(children: [
              PlanetVectorIcon(planetKey: p1, size: 22),
              const SizedBox(width: 6),
              Text(_nameFor(p1), style: GoogleFonts.cinzel(
                fontSize: 17, color: const Color(0xFFE8E0D0),
                fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Text('×', style: TextStyle(fontSize: 17,
                color: color.withAlpha(200))),
              const SizedBox(width: 10),
              PlanetVectorIcon(planetKey: p2, size: 22),
              const SizedBox(width: 6),
              Text(_nameFor(p2), style: GoogleFonts.cinzel(
                fontSize: 17, color: const Color(0xFFE8E0D0),
                fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 14),
            // Aspect badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withAlpha(90)),
              ),
              child: Text(desc['aspect'] ?? '',
                style: TextStyle(fontSize: 14, color: color,
                  fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Text('オーブ ${diff.toStringAsFixed(2)}°',
              style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
            const SizedBox(height: 18),
            // Quality summary
            _descSection('性質', desc['summary'] ?? '', color),
            const SizedBox(height: 14),
            // Theme
            _descSection('テーマ', desc['theme'] ?? '', const Color(0xFFF6BD60)),
            const SizedBox(height: 14),
            // Reading
            _descSection('読み解き', desc['reading'] ?? '', const Color(0xFFF6BD60)),
          ]),
      ),
    );
  }

  Widget _descSection(String label, String body, Color accent) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.cinzel(
        fontSize: 12, color: accent.withAlpha(220),
        letterSpacing: 2.0, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(body, style: const TextStyle(
        fontSize: 15, color: Color(0xE6E8E0D0), height: 1.7)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (filteredAspects.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('アスペクトなし', style: TextStyle(color: Color(0xFF888888), fontSize: 13)),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _antiqueHeader(AntiqueIcon.aspects, 'ASPECTS (${filteredAspects.length})'),
      const Padding(
        padding: EdgeInsets.only(top: 2, bottom: 6),
        child: Text('左チェック＝ON/OFF切替 ／ 右ラベル＝解説を開く',
          style: TextStyle(fontSize: 11, color: Color(0x80888888), fontStyle: FontStyle.italic)),
      ),
      ...filteredAspects.take(15).map((a) {
        final key = '${a['type']}_${a['p1']}_${a['p2']}';
        final isHidden = hiddenAspects.contains(key);
        final isDimmed = a['dimmed'] as bool? ?? false;
        final isOff = isHidden || isDimmed;
        final aspColor = a['color'] as Color;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0x08FFFFFF))),
          ),
          child: Row(children: [
            // Antique checkmark toggle (tap = ON/OFF)
            GestureDetector(
              onTap: () => onToggleAspect(key),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: _AspectCheckmark(active: !isOff, color: aspColor),
              ),
            ),
            const SizedBox(width: 4),
            // Row body (dimmed when off) — NOT tappable; only badge is.
            Expanded(child: Opacity(
              opacity: isOff ? 0.25 : 1.0,
              child: Row(children: [
                PlanetVectorIcon(planetKey: a['p1'] as String, size: 16),
                const SizedBox(width: 3),
                Text(_nameFor(a['p1'] as String),
                  style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 13)),
                Text(' — ', style: TextStyle(color: aspColor.withAlpha(180), fontSize: 13)),
                PlanetVectorIcon(planetKey: a['p2'] as String, size: 16),
                const SizedBox(width: 3),
                Text(_nameFor(a['p2'] as String),
                  style: const TextStyle(color: Color(0xFFE8E0D0), fontSize: 13)),
                const Spacer(),
                Text('${(a['diff'] as double).toStringAsFixed(1)}°',
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 13)),
                const SizedBox(width: 4),
                // Aspect badge (tap = show description)
                GestureDetector(
                  onTap: () => _showAspectDescription(context, a),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: aspColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: aspColor.withAlpha(80)),
                    ),
                    child: Text(
                      '${aspectSymbol[a['type']] ?? ''} ${aspectNameJP[a['type']] ?? a['type']}${(a['aspectAngle'] as double?)?.toInt() ?? 0}°',
                      style: TextStyle(color: aspColor, fontSize: 11)),
                  ),
                ),
              ]),
            )),
          ]),
        );
      }),
      if (filteredAspects.length > 15)
        Padding(padding: const EdgeInsets.only(top: 4),
          child: Text('... 他${filteredAspects.length - 15}件',
            style: const TextStyle(color: Color(0x99888888), fontSize: 13))),
    ]);
  }
}

// ══════════════════════════════════════════════════
// Pattern Detection & 60-Day Prediction Panel
// HTML: detectPatterns() + predictPatternCompletions() + renderPredictions()
// ══════════════════════════════════════════════════

/// HTML: detectPatterns(aspects, natal, secondary)
/// Detect Grand Trine / T-Square / Yod from natal + optional secondary pool.
/// Each planet entry carries source ('N' or 'T'/'P') for display.
/// [chartMode]: 'single' = natal only, 'nt' = natal+transit, 'np' = natal+progressed
Map<String, List<Map<String, dynamic>>> detectPatterns(
  Map<String, double> natal, {
  Map<String, double>? secondary,
  String chartMode = 'single',
}) {
  final patterns = <String, List<Map<String, dynamic>>>{'grandtrine': [], 'tsquare': [], 'yod': []};
  final personalKeys = {'sun', 'moon', 'mercury', 'venus', 'mars'};

  // Build pool: each entry = {key, lon, source}
  final pool = <Map<String, dynamic>>[];
  for (final e in natal.entries) {
    pool.add({'key': e.key, 'lon': e.value, 'source': 'N'});
  }
  if (secondary != null && chartMode != 'single') {
    final src = chartMode == 'np' ? 'P' : 'T';
    for (final e in secondary.entries) {
      pool.add({'key': e.key, 'lon': e.value, 'source': src});
    }
  }

  double angDist(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }
  bool hasPersonal(List<Map<String, dynamic>> trio) =>
    trio.any((p) => personalKeys.contains(p['key']));
  // HTML: countNatal >= 2
  bool enoughNatal(List<Map<String, dynamic>> trio) =>
    trio.where((p) => p['source'] == 'N').length >= 2;
  String triKey(List<Map<String, dynamic>> trio) {
    final keys = trio.map((p) => '${p['source']}${p['key']}').toList()..sort();
    return keys.join(',');
  }

  final po = patternOrbSettings;
  final seen = <String>{};

  for (int i = 0; i < pool.length; i++) {
    for (int j = i + 1; j < pool.length; j++) {
      final dij = angDist(pool[i]['lon'] as double, pool[j]['lon'] as double);

      // Grand Trine: 120° between each pair
      if ((dij - 120).abs() <= po['grandtrine']!) {
        for (int k = j + 1; k < pool.length; k++) {
          if ((angDist(pool[i]['lon'] as double, pool[k]['lon'] as double) - 120).abs() > po['grandtrine']!) continue;
          if ((angDist(pool[j]['lon'] as double, pool[k]['lon'] as double) - 120).abs() > po['grandtrine']!) continue;
          final trio = [pool[i], pool[j], pool[k]];
          if (!hasPersonal(trio) || !enoughNatal(trio)) continue;
          final tk = triKey(trio);
          if (seen.contains(tk)) continue;
          seen.add(tk);
          patterns['grandtrine']!.add({
            'planets': trio.map((p) => p['key'] as String).toList(),
            'sources': trio.map((p) => p['source'] as String).toList(),
          });
        }
      }

      // T-Square: 180° opp + 2×90° sq
      if ((dij - 180).abs() <= po['tsquare_opp']!) {
        for (int k = 0; k < pool.length; k++) {
          if (k == i || k == j) continue;
          if ((angDist(pool[i]['lon'] as double, pool[k]['lon'] as double) - 90).abs() > po['tsquare_sq']!) continue;
          if ((angDist(pool[j]['lon'] as double, pool[k]['lon'] as double) - 90).abs() > po['tsquare_sq']!) continue;
          final trio = [pool[i], pool[j], pool[k]];
          if (!hasPersonal(trio) || !enoughNatal(trio)) continue;
          final tk = triKey(trio);
          if (seen.contains(tk)) continue;
          seen.add(tk);
          patterns['tsquare']!.add({
            'planets': trio.map((p) => p['key'] as String).toList(),
            'sources': trio.map((p) => p['source'] as String).toList(),
            'apex': pool[k]['key'],
          });
        }
      }

      // Yod: 60° sextile + 2×150° quincunx
      if ((dij - 60).abs() <= po['yod_sextile']!) {
        for (int k = 0; k < pool.length; k++) {
          if (k == i || k == j) continue;
          if ((angDist(pool[i]['lon'] as double, pool[k]['lon'] as double) - 150).abs() > po['yod_quincunx']!) continue;
          if ((angDist(pool[j]['lon'] as double, pool[k]['lon'] as double) - 150).abs() > po['yod_quincunx']!) continue;
          final trio = [pool[i], pool[j], pool[k]];
          if (!hasPersonal(trio) || !enoughNatal(trio)) continue;
          final tk = triKey(trio);
          if (seen.contains(tk)) continue;
          seen.add(tk);
          patterns['yod']!.add({
            'planets': trio.map((p) => p['key'] as String).toList(),
            'sources': trio.map((p) => p['source'] as String).toList(),
            'apex': pool[k]['key'],
          });
        }
      }
    }
  }

  return patterns;
}

/// Mock 60-day prediction — find when transit/progressed planets complete patterns
/// [chartMode]: 'nt' = transit speeds, 'np' = progressed speeds (1day=1year → very slow)
List<Map<String, dynamic>> predictPatternCompletions(Map<String, double> natal, {int daysAhead = 60, String chartMode = 'nt'}) {
  final predictions = <Map<String, dynamic>>[];
  final keys = natal.keys.toList();
  final personalKeys = {'sun', 'moon', 'mercury', 'venus', 'mars'};
  final now = DateTime.now();
  final sourceLabel = chartMode == 'np' ? 'P' : 'T';

  double angDist(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }
  double norm360(double v) => ((v % 360) + 360) % 360;

  // Transit: approximate daily motion
  // Progressed (1day=1year): divide transit speed by 365.25
  double mockLon(int bodyIdx, int dayOffset) {
    const transitSpeeds = [1.0, 13.2, 1.2, 1.0, 0.5, 0.08, 0.03, 0.01, 0.006, 0.004];
    final factor = chartMode == 'np' ? 1.0 / 365.25 : 1.0;
    final speed = transitSpeeds[bodyIdx % 10] * factor;
    final baseLon = natal.values.elementAt(bodyIdx % natal.length);
    return norm360(baseLon + speed * dayOffset + dayOffset * 0.1 * factor);
  }

  for (int i = 0; i < keys.length; i++) {
    for (int j = i + 1; j < keys.length; j++) {
      if (!personalKeys.contains(keys[i]) && !personalKeys.contains(keys[j])) continue;
      final dij = angDist(natal[keys[i]]!, natal[keys[j]]!);

      // Grand Trine completion
      if ((dij - 120).abs() <= 3) {
        final target = norm360(natal[keys[i]]! + 120);
        for (int body = 0; body < 10; body++) {
          for (int day = 1; day <= daysAhead; day++) {
            final tLon = mockLon(body, day);
            if (angDist(tLon, target) <= 3) {
              predictions.add({
                'type': 'grandtrine', 'natalPair': [keys[i], keys[j]],
                'transitBody': keys.length > body ? keys[body] : 'sun', 'source': sourceLabel,
                'daysUntil': day,
                'dateEstimate': now.add(Duration(days: day)),
              });
              break;
            }
          }
        }
      }

      // T-Square completion
      if ((dij - 180).abs() <= 3) {
        final target = norm360((natal[keys[i]]! + natal[keys[j]]!) / 2);
        for (int body = 0; body < 10; body++) {
          for (int day = 1; day <= daysAhead; day++) {
            final tLon = mockLon(body, day);
            if (angDist(tLon, target) <= 3 || angDist(tLon, norm360(target + 180)) <= 3) {
              predictions.add({
                'type': 'tsquare', 'natalPair': [keys[i], keys[j]],
                'transitBody': keys.length > body ? keys[body] : 'sun', 'source': sourceLabel,
                'daysUntil': day,
                'dateEstimate': now.add(Duration(days: day)),
              });
              break;
            }
          }
        }
      }

      // Yod completion
      if ((dij - 60).abs() <= 2.5) {
        final target = norm360(natal[keys[i]]! + 150);
        for (int body = 0; body < 10; body++) {
          for (int day = 1; day <= daysAhead; day++) {
            final tLon = mockLon(body, day);
            if (angDist(tLon, target) <= 2.5) {
              predictions.add({
                'type': 'yod', 'natalPair': [keys[i], keys[j]],
                'transitBody': keys.length > body ? keys[body] : 'sun', 'source': sourceLabel,
                'daysUntil': day,
                'dateEstimate': now.add(Duration(days: day)),
              });
              break;
            }
          }
        }
      }
    }
  }

  predictions.sort((a, b) => (a['daysUntil'] as int).compareTo(b['daysUntil'] as int));
  return predictions.take(5).toList();
}

/// Prediction panel widget
class HoroPredictionPanel extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> activePatterns;
  final List<Map<String, dynamic>> predictions;
  final Map<String, bool> patternVisible;
  final void Function(String type, bool value) onPatternToggle;
  const HoroPredictionPanel({
    super.key,
    required this.activePatterns,
    required this.predictions,
    required this.patternVisible,
    required this.onPatternToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasActive = activePatterns.values.any((l) => l.isNotEmpty);
    if (!hasActive && predictions.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _antiqueHeader(AntiqueIcon.pattern, 'PATTERN PREDICTIONS'),
      const Padding(
        padding: EdgeInsets.only(top: 2, bottom: 6),
        child: Text('左チェック＝ON/OFF切替 ／ 右ラベル＝解説を開く',
          style: TextStyle(fontSize: 11, color: Color(0x80888888), fontStyle: FontStyle.italic)),
      ),

      // Active patterns
      for (final type in ['grandtrine', 'tsquare', 'yod'])
        for (final p in activePatterns[type] ?? [])
          _activeItem(context, type, p),

      // Upcoming predictions
      for (final pred in predictions)
        _predictionItem(context, pred),
    ]);
  }

  void _showPatternDescription(BuildContext context, String type, Color color) {
    final data = patternDescriptions[type];
    if (data == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xF00C0C16),
      barrierColor: Colors.black54,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 4,
          bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: SizedBox(
                    width: 22, height: 22,
                    child: CustomPaint(
                      painter: _CloseXPainter(
                        color: const Color(0xFFC9A84C).withAlpha(220)),
                    ),
                  ),
                ),
              ),
            ),
            // Title
            Row(children: [
              AntiqueGlyph(icon: AntiqueIcon.pattern, size: 22, color: color),
              const SizedBox(width: 8),
              Text(data['title'] ?? type, style: GoogleFonts.cinzel(
                fontSize: 18, color: const Color(0xFFE8E0D0),
                fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            // Quality badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withAlpha(90)),
              ),
              child: Text(data['quality'] ?? '',
                style: TextStyle(fontSize: 14, color: color,
                  fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 18),
            _patternDescSection('配置の特徴', data['summary'] ?? '', color),
            const SizedBox(height: 14),
            _patternDescSection('ネイタル成立時 (N)', data['N'] ?? '',
              const Color(0xFFFFD370)),
            const SizedBox(height: 14),
            _patternDescSection('トランジット活性時 (T)', data['T'] ?? '',
              const Color(0xFF6BB5FF)),
            const SizedBox(height: 14),
            _patternDescSection('プログレス成立時 (P)', data['P'] ?? '',
              const Color(0xFFB088FF)),
          ]),
      ),
    );
  }

  Widget _patternDescSection(String label, String body, Color accent) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.cinzel(
        fontSize: 12, color: accent.withAlpha(220),
        letterSpacing: 2.0, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(body, style: const TextStyle(
        fontSize: 15, color: Color(0xE6E8E0D0), height: 1.7)),
    ]);
  }

  Widget _activeItem(BuildContext context, String type, Map<String, dynamic> pattern) {
    final style = patternStyles[type]!;
    final color = Color(style['color'] as int);
    final pKeys = pattern['planets'] as List<String>;
    final sources = pattern['sources'] as List<String>? ?? List.filled(pKeys.length, 'N');
    final visible = patternVisible[type] ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x08FFFFFF)))),
      child: Row(children: [
        // Checkmark toggle
        GestureDetector(
          onTap: () => onPatternToggle(type, !visible),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: _AspectCheckmark(active: visible, color: color),
          ),
        ),
        const SizedBox(width: 4),
        // Body (dimmed when off)
        Expanded(child: Opacity(
          opacity: visible ? 1.0 : 0.25,
          child: Row(children: [
            // Planets with source prefix
            ...List.generate(pKeys.length, (i) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(sources[i], style: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
                PlanetVectorIcon(planetKey: pKeys[i], size: 16),
              ]),
            )),
            const Spacer(),
            // Pattern name badge (tap = modal)
            GestureDetector(
              onTap: () => _showPatternDescription(context, type, color),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Text(style['labelJP'] as String,
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 4),
            const Text('成立中', style: TextStyle(fontSize: 11, color: Color(0xFFC9A84C))),
          ]),
        )),
      ]),
    );
  }

  Widget _predictionItem(BuildContext context, Map<String, dynamic> pred) {
    final type = pred['type'] as String;
    final style = patternStyles[type]!;
    final color = Color(style['color'] as int);
    final days = pred['daysUntil'] as int;
    final date = (pred['dateEstimate'] as DateTime).toLocal();
    final timeLabel = days < 1 ? 'まもなく' : '${days}日後';
    final dateStr = '${date.month}/${date.day}';
    final p1 = pred['natalPair'][0] as String;
    final p2 = pred['natalPair'][1] as String;
    final tBody = pred['transitBody'] as String;
    final src = pred['source'] as String? ?? 'T';
    final visible = patternVisible[type] ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0x08FFFFFF)))),
      child: Row(children: [
        // Checkmark toggle
        GestureDetector(
          onTap: () => onPatternToggle(type, !visible),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: _AspectCheckmark(active: visible, color: color),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(child: Opacity(
          opacity: visible ? 1.0 : 0.25,
          child: Row(children: [
            // N p1 - N p2 + src tBody
            const Text('N', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
            PlanetVectorIcon(planetKey: p1, size: 14),
            const Text('-N', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
            PlanetVectorIcon(planetKey: p2, size: 14),
            const Text(' + ', style: TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
            Text(src, style: const TextStyle(fontSize: 12, color: Color(0xFFCCCCCC))),
            PlanetVectorIcon(planetKey: tBody, size: 14),
            const Spacer(),
            // Pattern name badge (tap = modal)
            GestureDetector(
              onTap: () => _showPatternDescription(context, type, color),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: color.withAlpha(80)),
                ),
                child: Text(style['labelJP'] as String,
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 4),
            // Predicted date / countdown
            Column(crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min, children: [
              Text(timeLabel, style: const TextStyle(fontSize: 12, color: Color(0xFFF6BD60))),
              Text(dateStr, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
            ]),
          ]),
        )),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// Antique checkmark (for aspect list ON/OFF toggle)
// Active: 金の円輪 + 中にチェックマーク (グロー付き)
// Off:    薄い円輪のみ
// ══════════════════════════════════════════════════════════════
class _AspectCheckmark extends StatelessWidget {
  final bool active;
  final Color color;
  const _AspectCheckmark({required this.active, required this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20, height: 20,
      child: CustomPaint(painter: _CheckmarkPainter(active: active, color: color)),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final bool active;
  final Color color;
  _CheckmarkPainter({required this.active, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;
    final c = Offset(cx, cy);
    final ringColor = active ? color : const Color(0xFF555555);

    // Outer ring (double hairline for antique feel)
    if (active) {
      canvas.drawCircle(c, r, Paint()
        ..color = color.withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5));
    }
    canvas.drawCircle(c, r, Paint()
      ..color = ringColor.withAlpha(active ? 220 : 120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0);
    canvas.drawCircle(c, r - 2, Paint()
      ..color = ringColor.withAlpha(active ? 110 : 50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5);

    // Checkmark stroke (only when active) — elegant serif flick
    if (active) {
      final path = Path()
        ..moveTo(cx - r * 0.45, cy - r * 0.02)
        ..lineTo(cx - r * 0.10, cy + r * 0.35)
        ..lineTo(cx + r * 0.55, cy - r * 0.45);
      // glow
      canvas.drawPath(path, Paint()
        ..color = color.withAlpha(150)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0));
      // main stroke
      canvas.drawPath(path, Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter old) =>
      old.active != active || old.color != color;
}

// ══════════════════════════════════════════════════════════════
// Close (×) painter — antique thin strokes with subtle glow
// ══════════════════════════════════════════════════════════════
class _CloseXPainter extends CustomPainter {
  final Color color;
  _CloseXPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final inset = w * 0.2;
    final p1a = Offset(inset, inset);
    final p1b = Offset(w - inset, w - inset);
    final p2a = Offset(w - inset, inset);
    final p2b = Offset(inset, w - inset);

    final glow = Paint()
      ..color = color.withAlpha(100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(p1a, p1b, glow);
    canvas.drawLine(p2a, p2b, glow);
    canvas.drawLine(p1a, p1b, stroke);
    canvas.drawLine(p2a, p2b, stroke);
  }

  @override
  bool shouldRepaint(covariant _CloseXPainter old) => old.color != color;
}

