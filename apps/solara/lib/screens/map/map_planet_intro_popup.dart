import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../i18n/strings.g.dart';
import '../../theme/solara_colors.dart';
import '../../utils/planet_intro.dart';
import '../../utils/solara_i18n.dart';
import '../../widgets/info_popup.dart';
import '../horoscope/horo_panel_shared.dart' show PlanetVectorIcon;
import 'map_constants.dart' show planetMeta, planetName;

// ============================================================
// Map 画面 惑星マーカータップ説明 popup (2026-05-07)
//
// PlanetSymbolsLayer のマーカーをタップすると本 popup が出る。
// frame ('natal' / 'transit' / 'progressed') によって本文を切替える。
// 未登録の惑星は「順次追加予定」プレースホルダ表示。
//
// 表示構成:
//   ヘッダ:    [惑星アイコン] 惑星名 (フレーム名バッジ)
//   セクション1: フレーム別 summary + detail
//   セクション2: 惑星のコア機能 (常時表示)
//
// 統一規約: showInfoPopup (widgets/info_popup.dart) を経由。
// ============================================================

const Map<String, Color> _frameColors = {
  'natal': Color(0xFFE9D29A),
  'transit': Color(0xFFFF8E5C),
  'progressed': Color(0xFF63D6A0),
};

String _frameLabel(String frame) => switch (frame) {
      'transit' => t.planetIntroPopup.frameTransit,
      'progressed' => t.planetIntroPopup.frameProgressed,
      _ => t.planetIntroPopup.frameNatal,
    };

Future<void> showPlanetIntroPopup({
  required BuildContext context,
  required String planetKey,
  required String frame,
}) {
  final intro = planetIntros[planetKey];
  final meta = planetMeta[planetKey];
  final frameColor = _frameColors[frame] ?? _frameColors['natal']!;
  final accent = meta?.color ?? SolaraColors.solaraGoldLight;

  return showInfoPopup(
    context: context,
    borderColor: accent.withAlpha(120),
    child: _PlanetIntroBody(
      planetKey: planetKey,
      planetJp: isEnLocale()
          ? planetName(planetKey)
          : (intro?.jp ?? meta?.jp ?? planetKey),
      planetColor: accent,
      frameLabel: _frameLabel(frame),
      frameColor: frameColor,
      intro: intro,
      frameKey: frame,
    ),
  );
}

class _PlanetIntroBody extends StatelessWidget {
  final String planetKey;
  final String planetJp;
  final Color planetColor;
  final String frameLabel;
  final Color frameColor;
  final PlanetIntro? intro;
  final String frameKey;

  const _PlanetIntroBody({
    required this.planetKey,
    required this.planetJp,
    required this.planetColor,
    required this.frameLabel,
    required this.frameColor,
    required this.intro,
    required this.frameKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(),
        const SizedBox(height: 14),
        if (intro == null)
          _placeholder()
        else ...[
          _frameSection(intro!.frameOf(frameKey)),
          const SizedBox(height: 18),
          _coreSection(intro!),
        ],
      ],
    );
  }

  Widget _header() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0A0A14),
          border: Border.all(color: planetColor.withAlpha(180), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: planetColor.withAlpha(80),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: PlanetVectorIcon(
            planetKey: planetKey,
            size: 22,
            color: planetColor,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planetJp,
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: planetColor,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: frameColor.withAlpha(150), width: 0.8),
                color: frameColor.withAlpha(28),
              ),
              child: Text(
                frameLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: frameColor,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _frameSection(PlanetIntroFrame frame) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        frame.summary,
        style: TextStyle(
          fontSize: 13,
          color: frameColor,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        frame.detail,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFFE0DCD0),
          height: 1.65,
        ),
      ),
    ]);
  }

  Widget _coreSection(PlanetIntro intro) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: planetColor.withAlpha(14),
        border: Border.all(color: planetColor.withAlpha(60), width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          t.planetIntroPopup.basics(
              name: isEnLocale() ? planetName(planetKey) : intro.jp),
          style: TextStyle(
            fontSize: 13,
            color: planetColor.withAlpha(220),
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          intro.coreSummary,
          style: TextStyle(
            fontSize: 13,
            color: planetColor,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          intro.coreDetail,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFCCC5B5),
            height: 1.6,
          ),
        ),
      ]),
    );
  }

  Widget _placeholder() {
    // 2026-05-07 全 10 惑星収録済み。本来 _placeholder は呼ばれないが、
    // 将来データキー欠落時の安全網として残しておく。
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x33FFFFFF), width: 0.8),
      ),
      child: Text(
        t.planetIntroPopup.preparing,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFFAAAAAA),
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
