import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/astro_houses.dart' show assignPlanetHouse;
import '../../utils/fortune_api.dart' show RelocationNarrative, fetchRelocationNarrative;
import '../../utils/pro_status.dart';
import '../../widgets/pro_unlock_dialog.dart';
import 'horo_constants.dart' show planetNamesJP, signNames;
import 'horo_relocation_templates.dart';

// A2 (2026-05-17): Free 向け Pro 誘導 CTA は part-of で分離 (HARD 500 行回避)。
part 'horo_relocation_pro_teaser.dart';

// ══════════════════════════════════════════════════
// Relocation Panel
// 出生地ハウス vs 現住所ハウス の差分を比較形式で解説する。
// 1重円モード + home有効 + houses取得済みの時のみ表示 (Bottom Sheet 拠点タブ)。
//
// Phase A (Free): 静的テンプレート (horo_relocation_templates) のみ表示。
//   Gemini を呼ばないのでコスト 0。
// Phase B (Pro): Stella の動的解説 (/relocation 経由) を取得し、静的テンプレを上書き。
//   - 取得成功 → narrative.planetNarratives[planet] を「現住所」行に表示
//   - 取得中/失敗 → 静的テンプレ (planetInHouseMessages 等) にフォールバック
//   - 「変化なし」項目は API に投げず、静的テンプレが残る（情報量維持）
//
// A2 ゲート (2026-05-17): Pro じゃなければ `_fetchNarrative` を呼ばない
// (Gemini 0 回呼出)。Free には Phase A テンプレ + Pro 誘導 CTA を表示。
// ProStatus listener で Free→Pro に切り替わると即時に Phase B を取得。
// ══════════════════════════════════════════════════

class HouseShift {
  final String planet;     // 'sun' 等
  final int fromHouse;     // 1-12 (出生地ハウス)
  final int toHouse;       // 1-12 (現住所ハウス)
  const HouseShift({required this.planet, required this.fromHouse, required this.toHouse});
}

class HoroRelocationPanel extends StatefulWidget {
  final Map<String, double> natalPlanets;  // 惑星黄経 (relocateで変わらない)
  final List<double> natalHouses;          // 出生地ベースのハウスカスプ12個
  final List<double> relocateHouses;       // 現住所ベースのハウスカスプ12個
  final double natalAsc, natalMc;
  final double relocateAsc, relocateMc;
  final String? birthPlaceName;            // 出生地名 (任意)
  final String? homeName;                  // 現住所名 (任意)
  final String? userName;                  // 対象者名 (Stella プロンプトに渡す)

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
  RelocationNarrative? _narrative;
  bool _loading = false;
  // パネルの「再fetch識別キー」: 引数が変わったら再fetchするためのハッシュ
  String? _lastFetchKey;

  @override
  void initState() {
    super.initState();
    ProStatus.instance.addListener(_onProStatusChanged);
    _maybeFetch();
  }

  @override
  void dispose() {
    ProStatus.instance.removeListener(_onProStatusChanged);
    super.dispose();
  }

  /// Pro 状態変化に追従。Free→Pro で動的解説を取得、Pro→Free で破棄。
  void _onProStatusChanged() {
    if (!mounted) return;
    if (ProStatus.instance.isPro) {
      // Free→Pro: 動的解説を取りに行く。`_lastFetchKey` を null にして
      // `_maybeFetch` が必ず動くようにする。
      _lastFetchKey = null;
      _maybeFetch();
    } else {
      // Pro→Free: 動的解説を破棄。静的テンプレ表示に戻る。
      setState(() {
        _narrative = null;
        _loading = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant HoroRelocationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeFetch();
  }

  /// 入力パラメータからキーを生成し、変化していれば再fetch。
  /// 出生地名/現住所名/houses が変わると別の解説が必要なため。
  String _buildFetchKey() {
    final natalH = widget.natalHouses.map((h) => h.toStringAsFixed(2)).join(',');
    final reloH = widget.relocateHouses.map((h) => h.toStringAsFixed(2)).join(',');
    return '${widget.birthPlaceName}|${widget.homeName}|${widget.userName}'
        '|${widget.natalAsc.toStringAsFixed(2)}|${widget.natalMc.toStringAsFixed(2)}'
        '|${widget.relocateAsc.toStringAsFixed(2)}|${widget.relocateMc.toStringAsFixed(2)}'
        '|N:$natalH|R:$reloH';
  }

  void _maybeFetch() {
    if (widget.natalHouses.length != 12 || widget.relocateHouses.length != 12) return;
    // A2 ゲート: Free ユーザーは Phase B (Gemini) を呼ばない。Phase A 静的テンプレで表示。
    if (!ProStatus.instance.isPro) return;
    final key = _buildFetchKey();
    if (key == _lastFetchKey) return; // 同じパラメータなら再fetch不要
    _lastFetchKey = key;
    _fetchNarrative();
  }

  /// 全惑星の natal vs relocate ハウス位置を抽出 (変化なし含む)
  List<HouseShift> _computeAllPositions() {
    final shifts = <HouseShift>[];
    for (final planetKey in planetPriority) {
      final lon = widget.natalPlanets[planetKey];
      if (lon == null) continue;
      final from = assignPlanetHouse(lon, widget.natalHouses);
      final to = assignPlanetHouse(lon, widget.relocateHouses);
      if (from == null || to == null) continue;
      shifts.add(HouseShift(planet: planetKey, fromHouse: from, toHouse: to));
    }
    return shifts;
  }

  /// ASC/MC の星座変化を {fromSign, toSign} で返す。変化なしなら null。
  Map<String, int>? _angleSignChange(double natalLon, double relocateLon) {
    final fromIdx = (natalLon / 30).floor() % 12;
    final toIdx = (relocateLon / 30).floor() % 12;
    if (fromIdx == toIdx) return null;
    return {'fromSign': fromIdx, 'toSign': toIdx};
  }

  Future<void> _fetchNarrative() async {
    final positions = _computeAllPositions();
    final shiftsPayload = positions.map((s) => {
      'planet': s.planet,
      'fromHouse': s.fromHouse,
      'toHouse': s.toHouse,
    }).toList();

    final ascChange = _angleSignChange(widget.natalAsc, widget.relocateAsc);
    final mcChange = _angleSignChange(widget.natalMc, widget.relocateMc);

    if (mounted) setState(() => _loading = true);
    final n = await fetchRelocationNarrative(
      shifts: shiftsPayload,
      ascChange: ascChange,
      mcChange: mcChange,
      birthPlaceName: widget.birthPlaceName,
      homeName: widget.homeName,
      userName: widget.userName,
    );
    if (!mounted) return;
    setState(() {
      // isEmpty (変化なし) も null と同等扱い
      _narrative = (n != null && !n.isEmpty) ? n : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.natalHouses.length != 12 || widget.relocateHouses.length != 12) {
      return const SizedBox.shrink();
    }

    final positions = _computeAllPositions();
    final ascFromIdx = (widget.natalAsc / 30).floor() % 12;
    final ascToIdx = (widget.relocateAsc / 30).floor() % 12;
    final mcFromIdx = (widget.natalMc / 30).floor() % 12;
    final mcToIdx = (widget.relocateMc / 30).floor() % 12;

    final isPro = ProStatus.instance.isPro;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          // A2: Free ユーザーには Pro 誘導 CTA を最上部に表示。
          // 「Phase A 静的解説でも十分使える + Pro でパーソナル解説に化ける」を示す。
          // 実装は part-of `horo_relocation_pro_teaser.dart` の extension。
          if (!isPro) ...[
            buildProTeaser(),
            const SizedBox(height: 14),
          ],
          // 動的サマリーがあれば最上部に表示 (Pro のみ)
          if (_narrative != null && _narrative!.summary.isNotEmpty) ...[
            _buildSummaryBlock(_narrative!.summary),
            const SizedBox(height: 14),
          ],
          if (_loading) ...[
            _buildLoadingHint(),
            const SizedBox(height: 8),
          ],
          // ASC/MC: 変化有無問わず常時表示
          _buildAngleBlock('ASC', ascFromIdx, ascToIdx, ascInSignDescriptions, _narrative?.ascNarrative),
          _buildAngleBlock('MC', mcFromIdx, mcToIdx, mcInSignDescriptions, _narrative?.mcNarrative),
          // 全惑星 (変化なし含む)
          ...positions.map(_buildShiftBlock),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final from = (widget.birthPlaceName == null || widget.birthPlaceName!.isEmpty) ? '出生地' : widget.birthPlaceName!;
    final to = (widget.homeName == null || widget.homeName!.isEmpty) ? '現住所' : widget.homeName!;
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

  /// 動的サマリー（Stella が生成した1〜2文）
  Widget _buildSummaryBlock(String summary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x33F6BD60), Color(0x14F6BD60)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x44F6BD60)),
      ),
      child: Text(
        summary,
        style: GoogleFonts.notoSansJp(
          fontSize: 12.5,
          color: const Color(0xFFE8E0D0),
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// API fetch 中の控えめな表示（既存テンプレ表示と並行）
  Widget _buildLoadingHint() {
    return Row(
      children: [
        const SizedBox(
          width: 12, height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.2,
            valueColor: AlwaysStoppedAnimation(Color(0xFFC9A84C)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'パーソナル解説を生成中…',
          style: GoogleFonts.notoSansJp(
            fontSize: 10,
            color: const Color(0xFF888888),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// ASC/MC ブロック (星座変化の比較、変化なしも表示)
  /// dynamicNarrative が空でなければ「現住所」行を上書き表示。
  Widget _buildAngleBlock(
    String label, int fromIdx, int toIdx, Map<int, String> descriptions,
    String? dynamicNarrative,
  ) {
    final changed = fromIdx != toIdx;
    final hasDynamic = dynamicNarrative != null && dynamicNarrative.isNotEmpty;
    final toText = changed
        ? (hasDynamic ? dynamicNarrative : (descriptions[toIdx] ?? ''))
        : '変化なし';
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cinzel(
                  fontSize: 12,
                  color: const Color(0xFFF6BD60),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Flexible(
                child: Text(
                  changed
                      ? '${signNames[fromIdx]}座 → ${signNames[toIdx]}座'
                      : '${signNames[fromIdx]}座 → 変化なし',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansJp(
                    fontSize: 12,
                    color: const Color(0xFFE8E0D0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            _buildCompareRow('出生地', descriptions[fromIdx] ?? '', false),
            const SizedBox(height: 3),
            _buildCompareRow('現住所', toText, true),
          ],
        ),
      ),
    );
  }

  /// 惑星 shift ブロック (ハウス変化の比較、変化なしも表示)
  /// 動的narrativeがあれば「現住所」行を上書き表示。
  Widget _buildShiftBlock(HouseShift shift) {
    final changed = shift.fromHouse != shift.toHouse;
    final name = planetNamesJP[shift.planet] ?? shift.planet;
    final fromMsg = planetInHouseMessages[shift.planet]?[shift.fromHouse] ?? '';
    final staticToMsg = planetInHouseMessages[shift.planet]?[shift.toHouse] ?? '';
    final dynamicMsg = _narrative?.planetNarratives[shift.planet];
    final hasDynamic = dynamicMsg != null && dynamicMsg.isNotEmpty;
    final toMsg = changed
        ? (hasDynamic ? dynamicMsg : staticToMsg)
        : '変化なし';
    final isPersonal = personalPlanets.contains(shift.planet);
    final headerColor = isPersonal
        ? const Color(0xFFF6BD60)
        : const Color(0xCCDDDDDD);

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
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansJp(
                    fontSize: 13,
                    color: headerColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  changed
                      ? '${shift.fromHouse}H → ${shift.toHouse}H'
                      : '${shift.fromHouse}H → 変化なし',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontFamily: 'Courier New',
                    fontSize: 12,
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            _buildCompareRow('出生地', fromMsg, false),
            const SizedBox(height: 3),
            _buildCompareRow('現住所', toMsg, true),
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
