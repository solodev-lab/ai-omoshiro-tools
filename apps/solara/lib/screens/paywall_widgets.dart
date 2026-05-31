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
          Expanded(child: _toggleSegment(BillingCycle.monthly, '月額', null)),
          Expanded(
              child:
                  _toggleSegment(BillingCycle.annual, '年額', 'SAVE 50%')),
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
              if (isFreeUser) _cardBadge('現在のプラン', muted: true),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '¥0  /  ずっと',
            style: TextStyle(
              color: SolaraColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          _planBullet('Stella 相談  週 3 回 (月曜リセット) + 購入クレジット'),
          _planBullet('タロット  1 日 1 回 (全体運は無料)'),
          _planBullet('星読み  「全体運」カテゴリのみ'),
          _planBullet('アスペクトライン  40 本'),
          _planBullet('ACG / CCG  4 フレームすべて (natal / transit / prog / solar arc)'),
          _planBullet('星座アーカイブ・タロット履歴の検索・フィルタ'),
          _planBullet('形成演出の再生・テキスト書き出し'),
          _planBullet('占い結果の永久保存とシェア'),
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
        ? '価格を取得中…'
        : '${product.priceString} / ${_periodLabel(selectedPackage!)}  (税込)';

    final intro = product?.introductoryPrice;
    final hasTrial = intro != null && intro.price == 0;

    // 年額時の月換算ヒント (¥9,000 / 12 ≈ ¥750 のような構造を product から自前で算出)。
    String? monthlyEquivalent;
    if (isAnnual && product != null) {
      final perMonth = product.price / 12;
      // 通貨記号は priceString に倣う: ¥ 始まり / 末尾 currency の両方を考慮しないので
      // 簡易に「¥{価格}」形式で出す (ja-JP 想定。i18n 解禁時に再考)。
      final yen = perMonth.round();
      monthlyEquivalent = '月あたり ¥$yen 相当';
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
              _cardBadge(isPro ? 'ご加入中' : '人気'),
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
              '🎁 ${_introPeriodLabel(intro)}の無料トライアル → 終了後に自動課金',
              style: const TextStyle(
                color: SolaraColors.energyHardLight,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _planBullet('Stella 相談  週 100 回 (月曜リセット)'),
          _planBullet('タロット  7 カテゴリ (全体運・恋愛・豊かさ・仕事・対話・癒し・変化) を'
              'クレジット消費なしで指定 + 質問入力欄'),
          _planBullet('星読み  全 5 カテゴリ (全体・恋愛・豊かさ・仕事・対話) + 深い読み'),
          _planBullet('アスペクトライン  全 120 本 (合・スクエア・トライン・セクスタイル)'),
          _planBullet('引越しシミュレーション  地点タップで ASC / MC / 12 ハウスを再計算'),
          _planBullet('リロケーション  Stella による動的解説'),
          _planBullet('時刻スライダー 1 分刻み ・ 拠点枠 10 ・ Forecast 5 年予測'),
          _planBullet('称号 (クラス) の再診断  無制限'),
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
          label: const Text('定期購入を管理'),
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
                ? '年額プランを始める'
                : '月額プランを始める'),
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
