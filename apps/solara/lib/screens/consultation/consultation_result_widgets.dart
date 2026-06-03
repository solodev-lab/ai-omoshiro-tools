// Consultation Result — 状態/バナー/ページャ ウィジェット (V2)
// (part of 'consultation_result_screen.dart')

part of 'consultation_result_screen.dart';

/// シェアシートで選ばれた選択肢。
enum _ShareChoice { text, image }

// ── 状態別パネル ───────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: SolaraColors.solaraGold,
            strokeWidth: 2,
          ),
          const SizedBox(height: 20),
          Text(
            t.consultResult.loading,
            style: TextStyle(
              color: SolaraColors.textSecondary,
              fontSize: 14,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: SolaraColors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: SolaraColors.solaraGold,
                ),
                child: Text(t.consultResult.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 静的フォールバック時の注意チップ (Stella 応答が届かず静的表示になったことを示す)。
class _FallbackChip extends StatelessWidget {
  const _FallbackChip();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x33D6915C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SolaraColors.energyHardDark),
        ),
        child: Text(
          t.consultResult.voiceUnavailable,
          style: TextStyle(
            color: SolaraColors.energyHardLight,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

// 2026-05-26: _InnerSeasonBanner 撤去（結果画面上部の「内的季節」常設バナー）。
// 内的季節の文章自体は AppBar タイトルタップの「この読み解きについて」popup
// （_AboutReadingContent）に残るので、初回のみ要覧したい人はそこで参照できる。

/// AppBar タイトルタップで開く「この読み解きについて」ポップアップの中身。
/// 内的季節 + 前置き + 注記 + 現在候補のエビデンス (占星術ファクター)。
class _AboutReadingContent extends StatelessWidget {
  final String innerSeason;
  final String intro;
  final String outro;
  final ConsultationEvidence evidence;
  const _AboutReadingContent({
    required this.innerSeason,
    required this.intro,
    required this.outro,
    required this.evidence,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t.consultResult.aboutReading,
            style: const TextStyle(
              color: SolaraColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          if (innerSeason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(innerSeason, style: _bodyStyle),
          ],
          if (intro.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(intro, style: _bodyStyle),
          ],
          if (evidence.factors.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: SolaraColors.glassBorder),
            const SizedBox(height: 12),
            Text(
              t.consultResult.factorsTitle,
              style: TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 11.5,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            ...evidence.factors.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('· $f', style: _factorStyle),
              ),
            ),
            if (evidence.km.isNotEmpty) ...[
              const SizedBox(height: 6),
              ...evidence.km.map(
                (k) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                      t.consultResult.kmFactor(factor: k.factor, km: k.km),
                      style: _kmStyle),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.consultResult.distanceNote,
                style: _kmStyle,
              ),
            ],
            if (evidence.note != null && evidence.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(evidence.note!, style: _kmStyle),
            ],
          ],
          if (outro.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: SolaraColors.glassBorder),
            const SizedBox(height: 12),
            Text(
              outro,
              style: TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 12.5,
                height: 1.7,
                letterSpacing: 0.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static const _bodyStyle = TextStyle(
    color: SolaraColors.textPrimary,
    fontSize: 14,
    height: 1.7,
    letterSpacing: 0.3,
  );
  static const _factorStyle = TextStyle(
    color: SolaraColors.solaraGoldLight,
    fontSize: 12.5,
    height: 1.5,
  );
  static final _kmStyle = TextStyle(
    color: SolaraColors.textSecondary,
    fontSize: 11.5,
    height: 1.5,
  );
}

// ── ページャ ─────────────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  final int count;
  final int index;
  const _PageIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? SolaraColors.solaraGold : SolaraColors.glassBorder,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

/// 近くの実在の町が乏しい (Phase B sparse) ときの控えめなヒント。
class _SparseHint extends StatelessWidget {
  final int? nearbyCount;
  const _SparseHint({this.nearbyCount});

  @override
  Widget build(BuildContext context) {
    final n = nearbyCount;
    final countText =
        (n != null && n > 0) ? t.consultResult.nearbyCount(n: n) : '';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x14F6BD60),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x33F6BD60)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                size: 15, color: SolaraColors.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.consultResult.sparseHint(countText: countText),
                style: const TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 候補を出し尽くした (案Y)。正直に止めた理由 + 条件変更の代替提案を出す。
/// 「無理に候補を作らない」設計なので、ここでは**クレジットを消費していない**ことを明示する。
class _ExhaustionPanel extends StatelessWidget {
  final String? reason;
  final List<String> suggestions;
  const _ExhaustionPanel({this.reason, this.suggestions = const []});

  static String _reasonText(String? reason) => switch (reason) {
        'allQuiet' => t.consultResult.exhaust.allQuiet,
        'noFresh' => t.consultResult.exhaust.noFresh,
        'emptyPool' => t.consultResult.exhaust.emptyPool,
        _ => t.consultResult.exhaust.fallback,
      };
  static String? _suggestLabel(String key) => switch (key) {
        'widenRadius' => t.consultResult.suggest.widenRadius,
        'bearing' => t.consultResult.suggest.bearing,
        'point' => t.consultResult.suggest.point,
        'world' => t.consultResult.suggest.world,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final headline = _reasonText(reason);
    final tips = suggestions
        .map((c) => _suggestLabel(c))
        .whereType<String>()
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.spa_outlined,
                    size: 16, color: SolaraColors.solaraGoldLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headline,
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            if (tips.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                t.consultResult.exhaust.tipsLead,
                style: TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 11.5,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    tips.map((t) => _EnergyChip(label: t)).toList(growable: false),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              t.consultResult.exhaust.noCredit,
              style: TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 「別の候補地を見る」(1 クレジット消費で次の distinct 候補を 1 つ取得)。
class _RefreshButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _RefreshButton({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0x1AFFFFFF),
            foregroundColor: SolaraColors.solaraGold,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: SolaraColors.glassBorder),
            ),
          ),
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: SolaraColors.solaraGold,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.travel_explore, size: 18),
          label: Text(
              loading ? t.consultResult.refreshLoading : t.consultResult.refresh),
        ),
      ),
    );
  }
}
