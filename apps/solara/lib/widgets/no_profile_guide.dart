import 'package:flutter/material.dart';

import '../i18n/strings.g.dart';
import '../screens/horoscope/horo_antique_icons.dart';

/// プロフィール未設定時の案内カード (Forecast / Locations 共通)。
///
/// 「設定する」タップ:
///   1. `Navigator.of(context).maybePop()` で囲んでいるシート/ダイアログを閉じる
///   2. [onNavigateToSanctuary] callback で Sanctuary タブへ遷移
///
/// 2026-05-04: forecast_screen.dart / locations_screen.dart で完全に同じ
/// 1195 char の `_buildNoProfileGuide()` がコピペされていたものを集約。
/// (map_screen / horo_backdrop は装飾やメッセージが微妙に違うため別実装)
class NoProfileGuide extends StatelessWidget {
  final VoidCallback? onNavigateToSanctuary;

  const NoProfileGuide({super.key, this.onNavigateToSanctuary});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x14F9D976),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x40F9D976)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const AntiqueGlyph(icon: AntiqueIcon.reading, size: 32,
            color: Color(0xFFF6BD60)),
          const SizedBox(height: 8),
          Text(t.mapScreen.creditBannerTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFFF6D98A),
              fontWeight: FontWeight.w700, height: 1.4)),
          const SizedBox(height: 6),
          Text(t.mapScreen.creditBannerSub,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFFF6BD60))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Navigator.of(context).maybePop();
              onNavigateToSanctuary?.call();
            },
            child: Text(t.mapScreen.setupCta,
              style: const TextStyle(fontSize: 12, color: Color(0xFFF9D976),
                decoration: TextDecoration.underline)),
          ),
        ]),
      ),
    )));
  }
}
