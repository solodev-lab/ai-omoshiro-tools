// Paywall Screen — Free vs Pro 比較テーブル / FAQ アコーディオン
// (part of 'paywall_screen.dart')
//
// 役割:
//   - Suno 風レイアウトの下半分
//   - 比較テーブル: カテゴリ別 (相談・占い / 機能 / 計算) で Free vs Pro を行ごとに ✓ × / 値
//   - FAQ: 5 問のアコーディオン (memory project_solara_paywall_suno_redesign ドラフトに準拠)
//
// 行数管理:
//   - paywall_widgets.dart が大きくなりすぎないようここに分離。
//   - HARD 上限 600 行を意識し、本ファイル単体は 300 行未満を維持。

part of 'paywall_screen.dart';

extension _PaywallComparison on _PaywallScreenState {
  Widget _buildComparisonTable() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.paywall.comparison.title,
            style: const TextStyle(
              color: SolaraColors.solaraGoldLight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 12),
          _comparisonHeader(),
          _comparisonSection(t.paywall.comparison.secConsult),
          _comparisonRow(
              t.paywall.comparison.stellaConsult.label,
              t.paywall.comparison.stellaConsult.free,
              t.paywall.comparison.stellaConsult.pro),
          _comparisonRow(
            t.paywall.comparison.tarot.label,
            t.paywall.comparison.tarot.free,
            t.paywall.comparison.tarot.pro,
          ),
          _comparisonRow(t.paywall.comparison.starReading.label,
              t.paywall.comparison.starReading.free,
              t.paywall.comparison.starReading.pro),
          _comparisonRow(t.paywall.comparison.relocationLine.label, '✓', '✓'),
          _comparisonRow(t.paywall.comparison.outingTime.label, '—',
              t.paywall.comparison.outingTime.pro),
          _comparisonSection(t.paywall.comparison.secMap),
          _comparisonRow(t.paywall.comparison.acgFrames.label,
              t.paywall.comparison.acgFrames.value,
              t.paywall.comparison.acgFrames.value),
          _comparisonRow(t.paywall.comparison.zenithNadirPoints.label, '✓', '✓'),
          _comparisonRow(t.paywall.comparison.zenithNadirBands.label, '—', '✓'),
          _comparisonRow(t.paywall.comparison.aspectLines.label,
              t.paywall.comparison.aspectLines.free,
              t.paywall.comparison.aspectLines.pro),
          _comparisonRow(t.paywall.comparison.relocationSim.label, '—', '✓'),
          _comparisonRow(t.paywall.comparison.locationSlots.label,
              t.paywall.comparison.locationSlots.free,
              t.paywall.comparison.locationSlots.pro),
          _comparisonSection(t.paywall.comparison.secRecords),
          _comparisonRow(t.paywall.comparison.recordsSave.label, '✓', '✓'),
          _comparisonRow(t.paywall.comparison.archiveSearch.label, '✓', '✓'),
          _comparisonRow(t.paywall.comparison.replayExport.label, '✓', '✓'),
          _comparisonRow(t.paywall.comparison.titleRediagnosis.label,
              t.paywall.comparison.titleRediagnosis.free,
              t.paywall.comparison.titleRediagnosis.pro),
          _comparisonSection(t.paywall.comparison.secForecast),
          _comparisonRow(t.paywall.comparison.forecastPeriod.label,
              t.paywall.comparison.forecastPeriod.free,
              t.paywall.comparison.forecastPeriod.pro),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _comparisonHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              t.paywall.comparison.colFeature,
              style: const TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Expanded(
            flex: 3,
            child: Text(
              'Free',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const Expanded(
            flex: 3,
            child: Text(
              'Pro',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SolaraColors.solaraGoldLight,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonSection(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: SolaraColors.solaraGoldLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          // ラベルは Expanded で折返す (英語の長いセクション名が大きいフォント倍率で
          // 横にはみ出す overflow を防ぐ)。
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _comparisonRow(String label, String freeValue, String proValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              freeValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              proValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SolaraColors.solaraGoldLight,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            t.paywall.faq.title,
            style: const TextStyle(
              color: SolaraColors.solaraGoldLight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),
        _faqItem(t.paywall.faq.diff.q, t.paywall.faq.diff.a),
        _faqItem(t.paywall.faq.weeklyCap.q, t.paywall.faq.weeklyCap.a),
        _faqItem(t.paywall.faq.proTarot.q, t.paywall.faq.proTarot.a),
        _faqItem(t.paywall.faq.outing30min.q, t.paywall.faq.outing30min.a),
        _faqItem(
            t.paywall.faq.upgradeDowngrade.q, t.paywall.faq.upgradeDowngrade.a),
        _faqItem(t.paywall.faq.afterCancel.q, t.paywall.faq.afterCancel.a),
        _faqItem(t.paywall.faq.resubscribe.q, t.paywall.faq.resubscribe.a),
      ],
    );
  }

  Widget _faqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Theme(
        // ExpansionTile は divider を強制するため transparent に上書き。
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: SolaraColors.solaraGoldLight,
          collapsedIconColor: SolaraColors.textSecondary,
          title: Text(
            question,
            style: const TextStyle(
              color: SolaraColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: const TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 12,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
