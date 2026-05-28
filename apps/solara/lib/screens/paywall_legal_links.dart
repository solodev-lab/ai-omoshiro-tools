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
          const Text(
            'ストアの準備中です',
            style: TextStyle(
              color: SolaraColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '購入手続きは公開後にご利用いただけます。\n少し時間を空けてもう一度お試しください。',
            textAlign: TextAlign.center,
            style: TextStyle(
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
            child: const Text('もう一度確認する'),
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
        return '年';
      case PackageType.sixMonth:
        return '6 か月';
      case PackageType.threeMonth:
        return '3 か月';
      case PackageType.twoMonth:
        return '2 か月';
      case PackageType.monthly:
        return '月';
      case PackageType.weekly:
        return '週';
      case PackageType.lifetime:
        return '買い切り';
      default:
        return '期間';
    }
  }

  String _introPeriodLabel(IntroductoryPrice intro) {
    final n = intro.periodNumberOfUnits;
    switch (intro.periodUnit) {
      case PeriodUnit.day:
        return '$n 日間';
      case PeriodUnit.week:
        return '$n 週間';
      case PeriodUnit.month:
        return '$n か月';
      case PeriodUnit.year:
        return '$n 年';
      case PeriodUnit.unknown:
        return '$n';
    }
  }

  Widget _buildAutoRenewNotice() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'サブスクリプションは自動更新されます。期間終了の 24 時間以上前に自動更新を解約'
        'しない限り、同じ価格で次の期間に更新されます。料金は期間終了の 24 時間以内に '
        'Apple ID / Google アカウントへ請求されます。自動更新の管理や解約は、ご利用ストア'
        'のアカウント設定からいつでも行えます。',
        style: TextStyle(
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
        _legalLink('解約方法', _openCancelGuide),
        _legalLink('利用規約', () => _openUrl(LegalUrls.termsOfService)),
        _legalLink(
            'プライバシーポリシー', () => _openUrl(LegalUrls.privacyPolicy)),
        _legalLink('特定商取引法に基づく表記',
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
        label: const Text('購入を復元'),
        style: TextButton.styleFrom(
          foregroundColor: SolaraColors.textSecondary,
        ),
      ),
    );
  }
}
