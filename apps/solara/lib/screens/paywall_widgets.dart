// Paywall Screen — プラン表示 / 機能リスト / 法的リンク のサブウィジェット
// (part of 'paywall_screen.dart')
//
// 役割:
//   - Stage 1 ペイウォール画面の表示パーツを分割保管
//   - 親 (`_PaywallScreenState`) のメソッドとしてアクセス可能 (part-of)
//
// 内訳:
//   - _buildHero                : ゴールドグラデのタイトル + 一文紹介
//   - _buildFeatureList         : Pro で開く 5 機能の icon + 説明
//   - _buildPlansSection        : Loading / 配信あり (月額/年額) / 配信無し
//   - _buildStoreUnavailable    : Offerings 未配信 / 取得失敗時の準備中バナー
//   - _buildPlanCard            : 単一プラン (年額 / 月額) のカード UI + 購入導線
//   - _periodLabel / _introPeriodLabel : PackageType / PeriodUnit → 日本語ラベル
//
// (Solara は consultation_input_screen.dart と同じ part-of パターンを採用)

part of 'paywall_screen.dart';

extension _PaywallWidgets on _PaywallScreenState {
  Widget _buildHero() {
    return Column(
      children: [
        Text(
          'Cosmic Pro',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
            foreground: Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  SolaraColors.solaraGoldLight,
                  SolaraColors.solaraGold,
                ],
              ).createShader(const Rect.fromLTWH(0, 0, 220, 32)),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Stella と深く対話し、星と地に重なる景色を読み解くための完全機能。',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SolaraColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureList() {
    const features = [
      (Icons.auto_fix_high_outlined, 'Stella 相談 が常に開く',
          '悩みから候補地を 3 つ読み解く。Map タップ起点 / 目的起点の両方で。'),
      (Icons.public_outlined, '星と地を重ねる 4 つの時間軸',
          'Natal / Transit / Progressed / Solar Arc の地相を切替えて 120 本の線を読む。'),
      (Icons.home_work_outlined, 'リロケーションが動き出す',
          '住み替え地点での星模様を Stella が動的に解釈する。'),
      (Icons.library_books_outlined, '記録庫を自由に使う',
          '相談履歴 / タロット履歴 / 称号変遷の検索・フィルタ・エクスポート。'),
      (Icons.access_time, '時刻スライダー 1 分刻み',
          'LOCATION 枠 10 件、Forecast 期間 5 年など、観測の解像度が上がる。'),
    ];
    return Column(
      children: [
        for (final f in features) _featureRow(f.$1, f.$2, f.$3),
      ],
    );
  }

  Widget _featureRow(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0x14F9D976),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x33F9D976)),
            ),
            child: Icon(icon, size: 18, color: SolaraColors.solaraGoldLight),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            color: SolaraColors.solaraGoldLight,
            strokeWidth: 2,
          ),
        ),
      );
    }
    final offering = _offerings?.current;
    final monthly = offering?.monthly;
    final annual = offering?.annual;

    if (offering == null || (monthly == null && annual == null)) {
      return _buildStoreUnavailable();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (annual != null) _buildPlanCard(annual, highlighted: true),
        if (monthly != null) ...[
          const SizedBox(height: 12),
          _buildPlanCard(monthly),
        ],
      ],
    );
  }

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

  Widget _buildPlanCard(Package package, {bool highlighted = false}) {
    final product = package.storeProduct;
    final isAnnual = package.packageType == PackageType.annual;
    final periodLabel = _periodLabel(package);
    final intro = product.introductoryPrice;
    final hasTrial = intro != null && intro.price == 0;

    return InkWell(
      onTap: _purchasing ? null : () => _purchase(package),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: highlighted
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0x33F9D976), Color(0x14F6BD60)],
                )
              : null,
          color: highlighted ? null : const Color(0x12FFFFFF),
          border: Border.all(
            color: highlighted
                ? const Color(0x77F9D976)
                : const Color(0x33FFFFFF),
            width: highlighted ? 1.4 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isAnnual ? '年額プラン' : '月額プラン',
                        style: const TextStyle(
                          color: SolaraColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (highlighted) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x33F9D976),
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: const Color(0x66F9D976)),
                          ),
                          child: const Text(
                            'おすすめ',
                            style: TextStyle(
                              color: SolaraColors.solaraGoldLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.priceString} / $periodLabel  (税込)',
                    style: const TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (hasTrial) ...[
                    const SizedBox(height: 4),
                    Text(
                      '無料トライアル ${_introPeriodLabel(intro)} → 終了後に自動課金',
                      style: const TextStyle(
                        color: SolaraColors.energyHardLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_purchasing)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: SolaraColors.solaraGoldLight,
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(
                Icons.chevron_right,
                color: SolaraColors.solaraGoldLight,
                size: 22,
              ),
          ],
        ),
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

  Widget _buildAutoRenewNotice() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'サブスクリプションは自動更新されます。期間終了の 24 時間以上前に解約しない限り、'
        '同じ価格で更新されます。料金は購入確定時に Apple ID / Google アカウントに請求され、'
        '購入後の払い戻しには対応していません。',
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
