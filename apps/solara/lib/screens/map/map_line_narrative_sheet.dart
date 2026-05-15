// ══════════════════════════════════════════════════
// Map Line Narrative Sheet
// A*C*G ライン (natal / transit) のタップ詳細 popup。
//
// 構成:
//   ① ヘッダー: 惑星 glyph + 名前 + ANGLE/Frame chip + 距離
//   ② 静的セクション: 用語辞書 (aspect_lines / transit_acg) サマリ
//
// 設計思想: project_solara_design_philosophy.md (Soft/Hard 独立2エネルギー)
//
// 旧実装にあった Stella による線解説機能 (詳しく読むボタン → 動的生成) は
// 2026-05-11 撤去。静的辞書ベースの解説のみに統一。
//
// 関連:
//   - 呼び出し元: map_relocation_popup.dart の _buildLineRow タップ
//   - 静的辞書: utils/astro_glossary.dart (aspect_lines / transit_acg)
// ══════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/solara_colors.dart';
import '../../utils/astro_glossary.dart';
import '../../utils/astro_lines.dart';
import '../../widgets/info_popup.dart';
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

  /// 「この地点で相談する」CTA タップ時のハンドラ。
  /// 非 null のときシート内に CTA ボタンが表示される。caller (map_screen) が
  /// タップ座標を preset として `_launchConsultation` を呼ぶ。
  /// Phase: 2026-05-16 (A + B + C(ii) ハイブリッド)。
  final VoidCallback? onConsult;

  const MapLineNarrativeSheet({
    super.key,
    required this.nearby,
    required this.frame,
    required this.tappedLat,
    required this.tappedLng,
    this.onConsult,
  });

  @override
  State<MapLineNarrativeSheet> createState() => _MapLineNarrativeSheetState();
}

class _MapLineNarrativeSheetState extends State<MapLineNarrativeSheet> {
  String get _planet => widget.nearby.line.planet;
  String get _angle => widget.nearby.line.angle.toUpperCase();

  Color get _planetColor =>
      planetMeta[_planet]?.color ?? SolaraColors.solaraGoldLight;

  String get _glyph => planetGlyphs[_planet] ?? '';
  String get _planetJp => planetNamesJP[_planet] ?? _planet;

  /// 静的辞書のキー。
  /// アスペクト線 (B1: square/trine/sextile) は aspect 種別ごと、
  /// コンジャンクション本線は従来どおり frame 別 (natal/transit) に切り替え。
  String get _glossaryKey {
    switch (widget.nearby.line.aspect) {
      case 'square':
        return 'aspect_square';
      case 'trine':
        return 'aspect_trine';
      case 'sextile':
        return 'aspect_sextile';
      default:
        return widget.frame == 'transit' ? 'transit_acg' : 'aspect_lines';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 本文のみを返す。外側の枠 (ConstrainedBox + maxHeight 制限 +
    // SingleChildScrollView + 右上 × ボタン + 外タップで閉じる) は
    // showInfoPopup 側のシェル (_InfoPopupShell) が提供する。
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        // CTA はヘッダー直下に置く (静的解説の前)。
        // 旧仕様 (2026-05-16 修正前) では最下段に置いていたが、解説が長いと
        // スクロールが必要で発見しづらかった。Phase 2-3b の MapRelocationPopup
        // と同じ「ヘッダー直下 CTA」パターンに統一。
        if (widget.onConsult != null) ...[
          const SizedBox(height: 12),
          _buildConsultCta(),
        ],
        const SizedBox(height: 12),
        _buildStaticSection(),
      ],
    );
  }

  /// 「この地点で相談する」 CTA (B 経路、Phase 2026-05-16)。
  /// onConsult 非 null のときのみ表示。
  /// タップで sheet を pop してから onConsult を呼ぶ (sheet 残置を防ぐ)。
  Widget _buildConsultCta() {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        widget.onConsult?.call();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0x33F6BD60),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x88F6BD60)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome,
                size: 16, color: SolaraColors.solaraGoldLight),
            SizedBox(width: 8),
            Text(
              'この地点で相談する',
              style: TextStyle(
                color: SolaraColors.solaraGoldLight,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── ヘッダー: 2段構成で横幅 overflow を回避 ──
  // 1段目: 惑星 glyph + 名前 (× ボタンは showInfoPopup シェル側が右上に固定配置)
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
            Flexible(
              child: Text(_glyph,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: TextStyle(fontSize: 22, color: _planetColor)),
            ),
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
                  fontSize: 13,
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
                  fontSize: 13,
                  color: const Color(0xFFCCCCCC),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              distStr,
              style: GoogleFonts.notoSansJp(
                fontSize: 13,
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
                fontSize: 13,
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
                fontSize: 13,
                color: const Color(0xFFE8E0D0),
                height: 1.65,
                letterSpacing: 0.2,
              ),
            ),
        ],
      ),
    );
  }

}

/// 共通呼び出しヘルパー: タップから直接 説明 popup を表示。
/// Solara の説明 popup 統一仕様 (showInfoPopup) に乗せる
/// → 画面高さ - 120px で上限が切られ、長文は SingleChildScrollView で
///   下スクロール、右上 × で閉じる、外タップでも閉じる挙動になる。
Future<void> showLineNarrativeSheet(
  BuildContext context, {
  required NearbyAstroLine nearby,
  required String frame,
  required double tappedLat,
  required double tappedLng,
  VoidCallback? onConsult,
}) {
  return showInfoPopup(
    context: context,
    child: MapLineNarrativeSheet(
      nearby: nearby,
      frame: frame,
      tappedLat: tappedLat,
      tappedLng: tappedLng,
      onConsult: onConsult,
    ),
  );
}
