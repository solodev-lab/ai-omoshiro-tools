// ============================================================
// Solara Philosophy Screen — 設計思想ガイド（章0）
//
// E5: 流派ガイドページの最初の章として、Solaraの設計思想
// （ソフト/ハード独立2エネルギー、占い的吉凶判定をしない、
//   両面思想）をユーザーに伝える。
//
// データソース: lib/utils/solara_manifesto.dart
// 設計根拠: project_solara_design_philosophy.md
// ============================================================
import 'package:flutter/material.dart';

import '../theme/solara_colors.dart';
import '../utils/solara_manifesto.dart';
import '../widgets/glass_panel.dart';

class SolaraPhilosophyScreen extends StatelessWidget {
  const SolaraPhilosophyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final sections = SolaraManifesto.getSections(locale);

    return Scaffold(
      backgroundColor: SolaraColors.celestialBlueDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: SolaraColors.solaraGoldLight),
        title: const Text(
          'Solara',
          style: TextStyle(
            color: SolaraColors.solaraGoldLight,
            fontSize: 16,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            const _Hero(),
            const SizedBox(height: 28),
            for (int i = 0; i < sections.length; i++) ...[
              _SectionCard(section: sections[i]),
              if (i < sections.length - 1) const SizedBox(height: 20),
            ],
            const SizedBox(height: 32),
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '☯',
          style: TextStyle(
            fontSize: 56,
            color: SolaraColors.solaraGold.withValues(alpha: 0.85),
            height: 1.0,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '設計思想',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SolaraColors.solaraGoldLight,
            fontSize: 18,
            letterSpacing: 6.0,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'The Worldview of Solara',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SolaraColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 11,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final SolaraManifestoSection section;
  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: const TextStyle(
              color: SolaraColors.solaraGoldLight,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < section.paragraphs.length; i++) ...[
            Text(
              section.paragraphs[i],
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 13,
                height: 1.85,
                letterSpacing: 0.4,
              ),
            ),
            if (i < section.paragraphs.length - 1)
              const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '— Solara —',
        style: TextStyle(
          color: SolaraColors.textSecondary.withValues(alpha: 0.5),
          fontSize: 11,
          letterSpacing: 4.0,
        ),
      ),
    );
  }
}
