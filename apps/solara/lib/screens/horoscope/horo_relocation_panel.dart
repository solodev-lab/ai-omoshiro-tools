import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../i18n/strings.g.dart';
import '../../utils/fortune_api.dart'
    show RelocationAngleNarrative, fetchRelocationAngleNarrative;
import '../../utils/solara_i18n.dart' show currentLang;
import 'horo_constants.dart' show planetGlyphs, planetLabel;
import 'horo_relocation_angles.dart';

// ══════════════════════════════════════════════════
// Relocation Panel (アングル近接版 — 2026-06-02 A案再設計、feature_inventory §0.2.53)
//
// 各惑星が ASC/MC/DSC/IC 軸へ近づく/遠ざかるを「度数」で測る。ハウスが変わらなくても必ず変化が出る
// (「変化なし」消滅)。占星術の正統「アングルに近い惑星ほど強い」と一貫。幾何は horo_relocation_angles.dart。
//
// 解説本文は Worker /relocation (Gemini, thinkingBudget:0・全員無料) で動的生成。
//   取得失敗時は **素直に「失敗しました」+ 再試行** を出す (定型文で取り繕わない = オーナー方針 2026-06-03)。
//   10天体すべて + ASC/MC/DSC/IC の星座変化を表示する。
//
// 1重円モード + home有効 + houses取得済み (出生時刻判明) の時のみ Bottom Sheet「拠点」タブに表示。
// ══════════════════════════════════════════════════

class HoroRelocationPanel extends StatefulWidget {
  final Map<String, double> natalPlanets; // 惑星黄経 (relocate で変わらない)
  final List<double> natalHouses;          // 出生地ベースのハウスカスプ12個
  final List<double> relocateHouses;       // 現住所ベースのハウスカスプ12個
  final double natalAsc, natalMc;
  final double relocateAsc, relocateMc;
  final String? birthPlaceName;            // 出生地名 (任意・ヘッダ + プロンプト)
  final String? homeName;                  // 現住所名 (任意・ヘッダ + プロンプト)
  final String? userName;                  // 対象者名 (任意・プロンプト)

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
    this.userName,
  });

  @override
  State<HoroRelocationPanel> createState() => _HoroRelocationPanelState();
}

class _HoroRelocationPanelState extends State<HoroRelocationPanel> {
  List<RelocationAngleDelta> _deltas = const [];
  List<RelocationAngleSignChange> _angleChanges = const [];

  /// Worker から取得した動的解説。null = 未取得 / 失敗。
  RelocationAngleNarrative? _narrative;
  bool _loading = false;
  bool _failed = false;
  String? _lastFetchKey;

  bool get _hasCharts =>
      widget.natalHouses.length == 12 && widget.relocateHouses.length == 12;

  /// 出生地と現住所がほぼ同じ場所 (変化を語る意味がない)。
  bool get _isSamePlace {
    if (_deltas.isEmpty) return true;
    final maxAbs = _deltas
        .map((d) => d.deltaDeg.abs())
        .fold<double>(0, (a, b) => a > b ? a : b);
    return maxAbs < kSamePlaceMaxDeg &&
        _angleChanges.isEmpty &&
        !_deltas.any((d) => d.houseChanged);
  }

  bool get _willFetch => _hasCharts && _deltas.isNotEmpty && !_isSamePlace;

  @override
  void initState() {
    super.initState();
    _recompute();
    if (_willFetch) _loading = true;
    _maybeFetch();
  }

  @override
  void didUpdateWidget(covariant HoroRelocationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.natalAsc != widget.natalAsc ||
        oldWidget.natalMc != widget.natalMc ||
        oldWidget.relocateAsc != widget.relocateAsc ||
        oldWidget.relocateMc != widget.relocateMc ||
        oldWidget.natalHouses.length != widget.natalHouses.length ||
        oldWidget.relocateHouses.length != widget.relocateHouses.length) {
      _recompute();
      _maybeFetch();
    }
  }

  void _recompute() {
    if (!_hasCharts || widget.natalPlanets.isEmpty) {
      _deltas = const [];
      _angleChanges = const [];
      return;
    }
    _deltas = computeRelocationAngleDeltas(
      natalPlanets: widget.natalPlanets,
      natalHouses: widget.natalHouses,
      relocateHouses: widget.relocateHouses,
      natalAsc: widget.natalAsc,
      natalMc: widget.natalMc,
      relocateAsc: widget.relocateAsc,
      relocateMc: widget.relocateMc,
    );
    _angleChanges = computeRelocationAngleSignChanges(
      natalAsc: widget.natalAsc,
      natalMc: widget.natalMc,
      relocateAsc: widget.relocateAsc,
      relocateMc: widget.relocateMc,
    );
  }

  String _buildFetchKey() =>
      '${widget.birthPlaceName}|${widget.homeName}|${widget.userName}'
      '|${widget.natalAsc.toStringAsFixed(2)}|${widget.natalMc.toStringAsFixed(2)}'
      '|${widget.relocateAsc.toStringAsFixed(2)}|${widget.relocateMc.toStringAsFixed(2)}';

  Future<void> _maybeFetch() async {
    if (!_willFetch) {
      if (_loading && mounted) setState(() => _loading = false);
      return;
    }
    final key = _buildFetchKey();
    // 取得成功済みで同条件なら再取得しない (コスト節約)。失敗時は再試行で _lastFetchKey をリセット。
    if (key == _lastFetchKey && _narrative != null) return;
    _lastFetchKey = key;
    if (mounted) {
      setState(() {
        _loading = true;
        _failed = false;
      });
    } else {
      _loading = true;
    }
    final n = await fetchRelocationAngleNarrative(
      planets: _deltas.map((d) => d.toPayload()).toList(),
      angles: _angleChanges.map((c) => c.toPayload()).toList(),
      birthPlaceName: widget.birthPlaceName,
      homeName: widget.homeName,
      userName: widget.userName,
      lang: currentLang(),
    );
    if (!mounted) return;
    setState(() {
      if (n != null && !n.isEmpty) {
        _narrative = n;
        _failed = false;
      } else {
        _narrative = null;
        _failed = true;
      }
      _loading = false;
    });
  }

  void _retry() {
    _lastFetchKey = null;
    _maybeFetch();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          if (!_hasCharts)
            _buildNeedChartHint()
          else if (_isSamePlace)
            _buildSamePlaceHint()
          else if (_loading)
            _buildLoadingBlock()
          else if (_failed || _narrative == null)
            _buildFailureBlock()
          else ...[
            if (_narrative!.summary.isNotEmpty) ...[
              _buildSummary(_narrative!.summary),
              const SizedBox(height: 14),
            ],
            if (_angleChanges.isNotEmpty) ...[
              _buildSectionTitle(t.relocPanel.secAngleSign),
              const SizedBox(height: 8),
              ..._angleChanges.map(_buildAngleChangeCard),
              const SizedBox(height: 14),
            ],
            _buildSectionTitle(t.relocPanel.secPlanetAngle),
            const SizedBox(height: 8),
            ..._deltas.map(_buildPlanetCard),
            const SizedBox(height: 10),
            _buildFootnote(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final from = (widget.birthPlaceName == null || widget.birthPlaceName!.isEmpty)
        ? t.profileEdit.birthPlace
        : widget.birthPlaceName!;
    final to = (widget.homeName == null || widget.homeName!.isEmpty)
        ? t.locations.currentAddress
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
          t.relocPanel.headerSub(from: from, to: to),
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

  Widget _buildSummary(String text) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0x14F6BD60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x33F6BD60)),
      ),
      child: Text(
        text,
        style: GoogleFonts.notoSansJp(
          fontSize: 12.5,
          color: const Color(0xFFE8E0D0),
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildLoadingBlock() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Color(0xFFF6BD60)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t.relocPanel.loading,
              style: GoogleFonts.notoSansJp(
                fontSize: 11.5,
                color: const Color(0xFFB8B2A6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureBlock() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.relocPanel.failTitle,
            style: GoogleFonts.notoSansJp(
              fontSize: 13,
              color: const Color(0xFFE8E0D0),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.relocPanel.failBody,
            style: GoogleFonts.notoSansJp(
              fontSize: 12,
              color: const Color(0xFFB8B2A6),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: _retry,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF6BD60),
                side: const BorderSide(color: Color(0x55F6BD60)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                t.common.tryAgain,
                style: GoogleFonts.notoSansJp(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// アングル星座変化 1枚 (ヘッドライン)。
  Widget _buildAngleChangeCard(RelocationAngleSignChange c) {
    final narrative = _narrative?.angleNarratives[c.angle] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0x14F6BD60),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33F6BD60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.relocPanel.angleHead(
                angle: c.angle.toUpperCase(),
                domain: relocationAngleDomainLabel(c.angle)),
            style: GoogleFonts.notoSansJp(
              fontSize: 13,
              color: const Color(0xFFE8E0D0),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (narrative.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              narrative,
              style: GoogleFonts.notoSansJp(
                fontSize: 12,
                color: const Color(0xFFD8D2C6),
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 惑星 1枚 (ハウス移動=金色強調 / 近=金色 / 遠=控えめ / ほぼ変化なし=灰)。
  Widget _buildPlanetCard(RelocationAngleDelta d) {
    final glyph = planetGlyphs[d.planet] ?? '';
    final planet = planetLabel(d.planet);
    final angle = d.nearestAngle.toUpperCase();
    final narrative = _narrative?.planetNarratives[d.planet] ?? '';

    final (String tag, Color accent, Color bg, Color border) = _styleFor(d);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Flexible(
              child: Text(
                d.houseChanged && d.reloHouse != null
                    ? '$glyph $planet · ${d.reloHouse}H'
                    : '$glyph $planet · ${t.relocPanel.axisLabel(angle: angle)}',
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
              tag,
              style: GoogleFonts.notoSansJp(
                fontSize: 11,
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ]),
          if (narrative.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              narrative,
              style: GoogleFonts.notoSansJp(
                fontSize: 12,
                color: const Color(0xFFD8D2C6),
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 状態に応じたタグ文言と配色。
  (String, Color, Color, Color) _styleFor(RelocationAngleDelta d) {
    if (d.houseChanged) {
      return (
        t.relocPanel.tagHouseShift,
        const Color(0xFFF6BD60),
        const Color(0x1FF6BD60),
        const Color(0x44F6BD60),
      );
    }
    switch (d.direction) {
      case 'closer':
        return (
          t.relocPanel.tagCloser,
          const Color(0xFFF6BD60),
          const Color(0x14F6BD60),
          const Color(0x33F6BD60),
        );
      case 'farther':
        return (
          t.relocPanel.tagFarther,
          const Color(0xFF9FB4C7),
          const Color(0x0AFFFFFF),
          const Color(0x1FFFFFFF),
        );
      default:
        return (
          t.relocPanel.tagSame,
          const Color(0xFF888888),
          const Color(0x08FFFFFF),
          const Color(0x14FFFFFF),
        );
    }
  }

  Widget _buildNeedChartHint() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Text(
        t.relocPanel.needChart,
        style: GoogleFonts.notoSansJp(
          fontSize: 12,
          color: const Color(0xFFB8B2A6),
          height: 1.6,
        ),
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
        t.relocPanel.samePlace,
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
      t.relocPanel.footnote,
      style: GoogleFonts.notoSansJp(
        fontSize: 10,
        color: const Color(0xFF888888),
        height: 1.5,
      ),
    );
  }
}
