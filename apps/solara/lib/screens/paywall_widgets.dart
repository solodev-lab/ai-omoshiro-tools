// Paywall Screen — Hero / 課金トグル / Free・Pro 2 カード (Suno 風 core)
// (part of 'paywall_screen.dart')
// 比較テーブル + FAQ → paywall_comparison.dart
// 法務必須項目 (B5) + 補助 (ストア準備中 / エラーパネル / 期間ラベル) → paywall_legal_links.dart

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
        Text(
          t.paywall.hero.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: SolaraColors.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
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
        if (monthly != null && annual != null) ...[
          _buildBillingToggle(),
          const SizedBox(height: 16),
        ],
        _buildFreeCard(),
        const SizedBox(height: 12),
        _buildProCard(annual: annual, monthly: monthly),
      ],
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
              child: _toggleSegment(
                  BillingCycle.monthly, t.paywall.billing.monthly, null)),
          Expanded(
              child: _toggleSegment(
                  BillingCycle.annual, t.paywall.billing.annual, 'SAVE 50%')),
        ],
      ),
    );
  }

  Widget _toggleSegment(BillingCycle cycle, String label, String? badge) {
    final selected = _selectedBilling == cycle;
    return GestureDetector(
      onTap: () => _setBilling(cycle),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    SolaraColors.solaraGoldLight,
                    SolaraColors.solaraGold,
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? SolaraColors.celestialBlueDark
                    : SolaraColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? SolaraColors.celestialBlueDark
                      : const Color(0x33F9D976),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: selected
                        ? SolaraColors.solaraGoldLight
                        : SolaraColors.solaraGoldLight,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFreeCard() {
    final isFreeUser = !ProStatus.instance.isPro;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0x10FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Free',
                style: TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (isFreeUser) _cardBadge(t.paywall.plans.currentPlan, muted: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            t.paywall.plans.freePrice,
            style: const TextStyle(
              color: SolaraColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          _planBullet(t.paywall.plans.free.stella),
          _planBullet(t.paywall.plans.free.tarot),
          _planBullet(t.paywall.plans.free.starReading),
          _planBullet(t.paywall.plans.free.aspectLines),
          _planBullet(t.paywall.plans.free.acgFrames),
          _planBullet(t.paywall.plans.free.archiveSearch),
          _planBullet(t.paywall.plans.free.replayExport),
          _planBullet(t.paywall.plans.free.save),
        ],
      ),
    );
  }

  Widget _buildProCard({Package? annual, Package? monthly}) {
    final isPro = ProStatus.instance.isPro;
    final wantAnnual = _selectedBilling == BillingCycle.annual;
    // Annual を選択していて annual が存在すればそれ、それ以外は monthly fallback。
    final selectedPackage =
        (wantAnnual ? annual : monthly) ?? annual ?? monthly;
    final isAnnual = selectedPackage?.packageType == PackageType.annual;

    final product = selectedPackage?.storeProduct;
    final priceLine = product == null
        ? t.paywall.plans.priceLoading
        : '${product.priceString} / ${_periodLabel(selectedPackage!)}  ${t.paywall.plans.taxIncl}';

    final intro = product?.introductoryPrice;
    final hasTrial = intro != null && intro.price == 0;

    // 年額時の月換算ヒント (¥9,000 / 12 ≈ ¥750 のような構造を product から自前で算出)。
    String? monthlyEquivalent;
    if (isAnnual && product != null) {
      final perMonth = product.price / 12;
      // 通貨記号は priceString に倣う: ¥ 始まり / 末尾 currency の両方を考慮しないので
      // 簡易に「¥{価格}」形式で出す (ja-JP 想定。i18n 解禁時に再考)。
      final yen = perMonth.round();
      monthlyEquivalent = t.paywall.plans.monthlyEquivalent(yen: yen);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x33F9D976), Color(0x14F6BD60)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x99F9D976), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Cosmic Pro',
                style: TextStyle(
                  color: SolaraColors.solaraGoldLight,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              _cardBadge(isPro
                  ? t.paywall.plans.badgeSubscribed
                  : t.paywall.plans.badgePopular),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            priceLine,
            style: const TextStyle(
              color: SolaraColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (monthlyEquivalent != null) ...[
            const SizedBox(height: 2),
            Text(
              monthlyEquivalent,
              style: const TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
          if (hasTrial) ...[
            const SizedBox(height: 6),
            Text(
              t.paywall.plans.trialLine(period: _introPeriodLabel(intro)),
              style: const TextStyle(
                color: SolaraColors.energyHardLight,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _planBullet(t.paywall.plans.pro.stella),
          _planBullet(t.paywall.plans.pro.outing),
          _planBullet(t.paywall.plans.pro.tarot),
          _planBullet(t.paywall.plans.pro.starReading),
          _planBullet(t.paywall.plans.pro.forecast),
          _planBullet(t.paywall.plans.pro.aspectLines),
          _planBullet(t.paywall.plans.pro.zenithBands),
          _planBullet(t.paywall.plans.pro.relocationSim),
          _planBullet(t.paywall.plans.pro.slots),
          _planBullet(t.paywall.plans.pro.rediagnosis),
          const SizedBox(height: 16),
          _buildProCta(selectedPackage, isPro: isPro),
        ],
      ),
    );
  }

  Widget _buildProCta(Package? package, {required bool isPro}) {
    if (isPro) {
      // 加入中 → 定期購入管理 (解約方法と同じ deep link を再利用)
      return SizedBox(
        width: double.infinity,
        height: 46,
        child: OutlinedButton.icon(
          onPressed: _openCancelGuide,
          icon: const Icon(Icons.settings_outlined, size: 16),
          label: Text(t.paywall.cta.manageSubscription),
          style: OutlinedButton.styleFrom(
            foregroundColor: SolaraColors.solaraGoldLight,
            side: const BorderSide(color: Color(0x77F9D976)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );
    }
    if (package == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton(
        onPressed: _purchasing ? null : () => _purchase(package),
        style: FilledButton.styleFrom(
          backgroundColor: SolaraColors.solaraGoldLight,
          foregroundColor: SolaraColors.celestialBlueDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        child: _purchasing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: SolaraColors.celestialBlueDark,
                  strokeWidth: 2,
                ),
              )
            : Text(package.packageType == PackageType.annual
                ? t.paywall.cta.startAnnual
                : t.paywall.cta.startMonthly),
      ),
    );
  }

  Widget _cardBadge(String text, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted ? const Color(0x22FFFFFF) : const Color(0x33F9D976),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: muted ? const Color(0x44FFFFFF) : const Color(0x66F9D976),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: muted
              ? SolaraColors.textSecondary
              : SolaraColors.solaraGoldLight,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _planBullet(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 8),
            child: Icon(Icons.check_circle_outline,
                size: 14, color: SolaraColors.solaraGoldLight),
          ),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 12,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // _buildStoreUnavailable / _buildErrorPanel / _periodLabel / _introPeriodLabel
  // と 法務必須項目 (_buildAutoRenewNotice / _buildLegalLinks / _buildRestoreButton)
  // は paywall_legal_links.dart (part) に分離。
}
