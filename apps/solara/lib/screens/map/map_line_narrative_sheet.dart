// ══════════════════════════════════════════════════
// Map Line Narrative Sheet — Tier S #2
// A*C*G ライン (natal / transit) のタップ詳細 BottomSheet。
//
// 構成:
//   ① 静的セクション: タイトル + 用語辞書 (aspect_lines / transit_acg) サマリ
//   ② 「詳しく読む (AI解釈)」ボタン → Gemini API 呼び出し
//   ③ 結果を Soft/Hard に分けて表示
//   ④ 失敗時は静的セクションのままフォールバック (詳細生成失敗の旨を提示)
//
// 設計思想: project_solara_design_philosophy.md (Soft/Hard 独立2エネルギー)
//
// 関連:
//   - 呼び出し元: map_relocation_popup.dart の _buildLineRow タップ
//   - API: utils/line_narrative_api.dart
//   - 静的辞書: utils/astro_glossary.dart (aspect_lines / transit_acg)
// ══════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/solara_colors.dart';
import '../../utils/astro_glossary.dart';
import '../../utils/astro_lines.dart';
import '../../utils/line_narrative_api.dart';
import '../horoscope/horo_constants.dart' show planetGlyphs, planetNamesJP;
import 'map_constants.dart' show planetMeta;

class MapLineNarrativeSheet extends StatefulWidget {
  /// タップされたライン
  final NearbyAstroLine nearby;

  /// 'natal' or 'transit'（natal アスペクト線レイヤー = natal、CCG = 該当フレーム）
  final String frame;

  /// タップ点
  final double tappedLat;
  final double tappedLng;

  /// natal 文脈（Gemini プロンプトに渡す任意ヒント）
  final Map<String, int>? natalSummary;

  /// frame=='transit' 時の時刻（ISO8601）
  final String? transitDate;

  /// 表示用の地点名（任意・null なら緯度経度）
  final String? tappedPlaceName;

  /// 言語
  final String lang;

  /// ユーザー名（任意・narrative の語りかけに使う）
  final String? userName;

  const MapLineNarrativeSheet({
    super.key,
    required this.nearby,
    required this.frame,
    required this.tappedLat,
    required this.tappedLng,
    this.natalSummary,
    this.transitDate,
    this.tappedPlaceName,
    this.lang = 'ja',
    this.userName,
  });

  @override
  State<MapLineNarrativeSheet> createState() => _MapLineNarrativeSheetState();
}

class _MapLineNarrativeSheetState extends State<MapLineNarrativeSheet> {
  bool _loading = false;
  bool _failed = false;
  LineNarrative? _narrative;

  String get _planet => widget.nearby.line.planet;
  String get _angle => widget.nearby.line.angle.toUpperCase();

  Color get _planetColor =>
      planetMeta[_planet]?.color ?? SolaraColors.solaraGoldLight;

  String get _glyph => planetGlyphs[_planet] ?? '';
  String get _planetJp => planetNamesJP[_planet] ?? _planet;

  /// 静的辞書のキー (frame 別に切り替え)
  String get _glossaryKey =>
      widget.frame == 'transit' ? 'transit_acg' : 'aspect_lines';

  Future<void> _loadNarrative() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final result = await fetchLineNarrative(
      frame: widget.frame,
      planet: _planet,
      angle: _angle,
      tappedLat: widget.tappedLat,
      tappedLng: widget.tappedLng,
      tappedPlaceName: widget.tappedPlaceName,
      natalSummary: widget.natalSummary,
      transitDate: widget.transitDate,
      userName: widget.userName,
      lang: widget.lang,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result == null || result.isEmpty) {
        _failed = true;
      } else {
        _narrative = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildStaticSection(),
            const SizedBox(height: 18),
            if (_narrative != null) ...[
              _buildNarrativeSection(),
            ] else ...[
              _buildLoadButton(),
              if (_failed) ...[
                const SizedBox(height: 8),
                _buildFailedNote(),
              ],
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── ヘッダー: 2段構成で横幅 overflow を回避 ──
  // 1段目: 惑星 glyph + 名前 + 閉じる×（タイトル行）
  // 2段目: ANGLE chip + Frame chip + 距離（メタ行、左右余れば均等配置）
  Widget _buildHeader() {
    final dist = widget.nearby.distanceKm;
    final distStr = dist < 10
        ? '${dist.toStringAsFixed(1)}km'
        : '${dist.round()}km';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_glyph,
                style: TextStyle(fontSize: 22, color: _planetColor)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _planetJp,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansJp(
                  fontSize: 16,
                  color: SolaraColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close,
                    size: 18, color: Color(0xFFC9A84C)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border:
                    Border.all(color: _planetColor.withAlpha(140)),
              ),
              child: Text(
                _angle,
                style: GoogleFonts.notoSansJp(
                  fontSize: 10,
                  color: _planetColor,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: const Color(0x22FFFFFF),
              ),
              child: Text(
                widget.frame == 'transit' ? 'Transit' : 'Natal',
                style: GoogleFonts.notoSansJp(
                  fontSize: 10,
                  color: const Color(0xFFCCCCCC),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              distStr,
              style: GoogleFonts.notoSansJp(
                fontSize: 11,
                color: const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 静的辞書セクション (用語辞書から取得) ──
  Widget _buildStaticSection() {
    final entry = astroGlossary[_glossaryKey];
    final summary = entry?.summary ?? '';
    final detail = entry?.detail ?? '';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFFFFF)),
        color: const Color(0x14FFFFFF),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary.isNotEmpty)
            Text(
              summary,
              style: GoogleFonts.notoSansJp(
                fontSize: 11,
                color: const Color(0xFFAAAAAA),
                height: 1.5,
                letterSpacing: 0.3,
              ),
            ),
          if (summary.isNotEmpty && detail.isNotEmpty)
            const Divider(color: Color(0x22FFFFFF), height: 14),
          if (detail.isNotEmpty)
            Text(
              detail,
              style: GoogleFonts.notoSansJp(
                fontSize: 12,
                color: const Color(0xFFE8E0D0),
                height: 1.65,
                letterSpacing: 0.2,
              ),
            ),
        ],
      ),
    );
  }

  // ── 詳しく読むボタン ──
  Widget _buildLoadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _loadNarrative,
        icon: _loading
            ? const SizedBox(
                width: 14, height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      SolaraColors.solaraGold),
                ),
              )
            : const Icon(Icons.auto_awesome, size: 16),
        label: Text(
          _loading
              ? (widget.lang == 'en' ? 'Reading…' : '解釈中…')
              : (widget.lang == 'en'
                  ? 'Read with AI'
                  : '詳しく読む (AI解釈)'),
          style: GoogleFonts.notoSansJp(
            fontSize: 13,
            color: SolaraColors.solaraGold,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0x22C9A84C),
          foregroundColor: SolaraColors.solaraGold,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: SolaraColors.solaraGold.withAlpha(120)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
      ),
    );
  }

  // ── 失敗時の注記 (静的セクションは表示済みなので軽く済ませる) ──
  Widget _buildFailedNote() {
    return Row(
      children: [
        const Icon(Icons.cloud_off,
            size: 14, color: Color(0xFF888888)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.lang == 'en'
                ? 'Could not load AI narrative. Static reading is shown above.'
                : 'AI解釈を取得できませんでした。上の静的解説が表示されています。',
            style: GoogleFonts.notoSansJp(
              fontSize: 10,
              color: const Color(0xFF888888),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ── 動的 narrative セクション ──
  Widget _buildNarrativeSection() {
    final n = _narrative!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (n.title.isNotEmpty) ...[
          Text(
            n.title,
            style: GoogleFonts.notoSansJp(
              fontSize: 13,
              color: SolaraColors.solaraGoldLight,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (n.narrative.isNotEmpty)
          Text(
            n.narrative,
            style: GoogleFonts.notoSansJp(
              fontSize: 13,
              color: SolaraColors.textPrimary,
              height: 1.75,
              letterSpacing: 0.2,
            ),
          ),
        if (n.softNote.isNotEmpty) ...[
          const SizedBox(height: 14),
          _buildEnergyNote(
            label: widget.lang == 'en' ? 'Soft' : 'ソフト',
            symbol: '☯',
            body: n.softNote,
            color: SolaraColors.energySoft,
          ),
        ],
        if (n.hardNote.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildEnergyNote(
            label: widget.lang == 'en' ? 'Hard' : 'ハード',
            symbol: '☐',
            body: n.hardNote,
            color: SolaraColors.energyHard,
          ),
        ],
      ],
    );
  }

  Widget _buildEnergyNote({
    required String label,
    required String symbol,
    required String body,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(110)),
        color: color.withAlpha(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(symbol, style: TextStyle(fontSize: 14, color: color)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.notoSansJp(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.notoSansJp(
              fontSize: 12,
              color: SolaraColors.textPrimary,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 共通呼び出しヘルパー: タップから直接 BottomSheet を表示
Future<void> showLineNarrativeSheet(
  BuildContext context, {
  required NearbyAstroLine nearby,
  required String frame,
  required double tappedLat,
  required double tappedLng,
  Map<String, int>? natalSummary,
  String? transitDate,
  String? tappedPlaceName,
  String lang = 'ja',
  String? userName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xF00C0C16),
    barrierColor: Colors.black54,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => MapLineNarrativeSheet(
      nearby: nearby,
      frame: frame,
      tappedLat: tappedLat,
      tappedLng: tappedLng,
      natalSummary: natalSummary,
      transitDate: transitDate,
      tappedPlaceName: tappedPlaceName,
      lang: lang,
      userName: userName,
    ),
  );
}
