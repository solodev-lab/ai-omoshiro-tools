// Paywall Screen — 法務必須項目 + 補助ウィジェット + 期間ラベル変換
// (part of 'paywall_screen.dart')
//
// 法務必須 (B5 公開ブロッカー、🛡 文言・リンク先を絶対に変更しない):
//   - _buildAutoRenewNotice : Apple 3.1.2(a) 必須開示 3 項目 + 3.1.1 禁止文言回避
//   - _buildLegalLinks      : 解約方法 / 利用規約 / プライバシー / 特商法
//   - _buildRestoreButton   : 購入を復元
//
// 補助ウィジェット / ユーティリティ (paywall_widgets.dart の行数 HARD 回避で集約):
//   - _buildStoreUnavailable  : Offerings 未配信時バナー
//   - _buildErrorPanel        : 購入エラー表示
//   - _periodLabel            : PackageType → 日本語期間ラベル
//   - _introPeriodLabel       : IntroductoryPrice → 日本語期間ラベル

part of 'paywall_screen.dart';

extension _PaywallLegalLinks on _PaywallScreenState {
  Widget _buildStoreUnavailable() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0x14F9D976),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33F9D976)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_top_outlined,
              color: SolaraColors.solaraGoldLight, size: 24),
          const SizedBox(height: 8),
          Text(
            t.paywall.store.preparingTitle,
            style: const TextStyle(
              color: SolaraColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.paywall.store.preparingBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SolaraColors.textSecondary,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loadOfferings,
            style: TextButton.styleFrom(
              foregroundColor: SolaraColors.solaraGoldLight,
            ),
            child: Text(t.paywall.store.recheck),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPanel(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x14D6915C),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x44D6915C)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline,
              color: SolaraColors.energyHardLight, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: SolaraColors.energyHardLight,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _periodLabel(Package package) {
    switch (package.packageType) {
      case PackageType.annual:
        return t.paywall.period.year;
      case PackageType.sixMonth:
        return t.paywall.period.sixMonth;
      case PackageType.threeMonth:
        return t.paywall.period.threeMonth;
      case PackageType.twoMonth:
        return t.paywall.period.twoMonth;
      case PackageType.monthly:
        return t.paywall.period.month;
      case PackageType.weekly:
        return t.paywall.period.week;
      case PackageType.lifetime:
        return t.paywall.period.lifetime;
      default:
        return t.paywall.period.generic;
    }
  }

  String _introPeriodLabel(IntroductoryPrice intro) {
    final n = intro.periodNumberOfUnits;
    switch (intro.periodUnit) {
      case PeriodUnit.day:
        return t.paywall.introPeriod.days(n: n);
      case PeriodUnit.week:
        return t.paywall.introPeriod.weeks(n: n);
      case PeriodUnit.month:
        return t.paywall.introPeriod.months(n: n);
      case PeriodUnit.year:
        return t.paywall.introPeriod.years(n: n);
      case PeriodUnit.unknown:
        return t.paywall.introPeriod.unknown(n: n);
    }
  }

  Widget _buildAutoRenewNotice() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        t.paywall.autoRenewNotice,
        style: const TextStyle(
          color: SolaraColors.textSecondary,
          fontSize: 11,
          height: 1.7,
        ),
      ),
    );
  }

  Widget _buildLegalLinks() {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _legalLink(t.paywall.legal.cancelMethod, _openCancelGuide),
        _legalLink(t.paywall.legal.terms,
            () => _openUrl(LegalUrls.termsOfService)),
        _legalLink(t.paywall.legal.privacy,
            () => _openUrl(LegalUrls.privacyPolicy)),
        _legalLink(t.paywall.legal.sctaNotice,
            () => _openUrl(LegalUrls.specifiedCommercialTransactions)),
      ],
    );
  }

  Widget _legalLink(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: SolaraColors.solaraGoldLight,
          fontSize: 11,
          decoration: TextDecoration.underline,
          decorationColor: SolaraColors.solaraGoldLight,
        ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _restoring ? null : _restore,
        icon: _restoring
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  color: SolaraColors.textSecondary,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.restore, size: 16),
        label: Text(t.paywall.restore),
        style: TextButton.styleFrom(
          foregroundColor: SolaraColors.textSecondary,
        ),
      ),
    );
  }
}
