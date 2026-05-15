// Consultation Result Screen — Stage 4 サブウィジェット部
// (part of '../consultation_result_screen.dart')
//
// Stage 4 結果画面の内部ウィジェットを分離。consultation_result_screen.dart は
// orchestration + state management 専担、本ファイルは presentation を担当する。
// (Solara は horoscope_screen.dart と同じ part-of パターンを採用)

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
            'Stella が読み解いています…',
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
                child: const Text('もう一度試す'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 上下のブロック (intro/outro) ───────────────────────────

class _IntroBlock extends StatelessWidget {
  final String text;
  final bool fallback;
  const _IntroBlock({required this.text, required this.fallback});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fallback)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x33D6915C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SolaraColors.energyHardDark),
              ),
              child: Text(
                'Stella の声が届きませんでした (静的表示)',
                style: TextStyle(
                  color: SolaraColors.energyHardLight,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          Text(
            text,
            style: const TextStyle(
              color: SolaraColors.textPrimary,
              fontSize: 14,
              height: 1.7,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutroBlock extends StatelessWidget {
  final String text;
  const _OutroBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: SolaraColors.glassBorder, width: 1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: SolaraColors.textSecondary,
          fontSize: 12.5,
          height: 1.7,
          letterSpacing: 0.4,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
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
              color: active
                  ? SolaraColors.solaraGold
                  : SolaraColors.glassBorder,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

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
              : const Icon(Icons.refresh, size: 18),
          label: Text(loading ? '別の候補を探しています…' : 'もう一度候補を出す'),
        ),
      ),
    );
  }
}

// ── 候補カード ──────────────────────────────────────────

class _CandidateCard extends StatelessWidget {
  final CandidateLocation candidate;
  final ConsultationCandidateReading? reading;

  const _CandidateCard({
    required this.candidate,
    required this.reading,
  });

  /// 候補タイプ: 方角 (bearings) か 場所 (specific/region/world) か。
  bool get _isBearing => candidate.bearing != null;

  String get _subtitle {
    final parts = <String>[];
    if (candidate.region.isNotEmpty) parts.add(candidate.region);
    if (candidate.country.isNotEmpty && !_isBearing) {
      parts.add(candidate.country);
    }
    return parts.join(' · ');
  }

  /// 候補タイプを示すラベル (アイコン横に小さく表示)。
  String get _kindLabel => _isBearing ? '方角' : '場所';

  /// 方角コード (N/NE/E/...) → 大きく表示する記号。null なら場所候補。
  String? get _bearingBadgeText => candidate.bearing;

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final energyLabels = r?.energyLabels ?? const <String>[];
    final narrative = r?.narrative ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassPanel(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 候補タイプバッジ + 種別ラベル (方角 / 場所)
              Row(
                children: [
                  _CandidateKindBadge(
                    isBearing: _isBearing,
                    bearingText: _bearingBadgeText,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _kindLabel,
                    style: const TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                candidate.nameJP,
                style: const TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 22,
                  height: 1.3,
                  letterSpacing: 0.5,
                ),
              ),
              if (_subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  _subtitle,
                  style: TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 12,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
              if (energyLabels.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: energyLabels
                      .map((label) => _EnergyChip(label: label))
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                narrative.isNotEmpty ? narrative : '(narrative なし)',
                style: const TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 14,
                  height: 1.85,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnergyChip extends StatelessWidget {
  final String label;
  const _EnergyChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x1AF6BD60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x44F6BD60)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: SolaraColors.solaraGoldLight,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// 候補種別バッジ (方角 / 場所)。
/// - bearings: コンパスアイコン + 方位コード (N / NE / ...) を内側に
/// - place:    ピンアイコン (シンプル)
class _CandidateKindBadge extends StatelessWidget {
  final bool isBearing;
  final String? bearingText; // 'N' / 'NE' 等。null なら場所
  const _CandidateKindBadge({
    required this.isBearing,
    required this.bearingText,
  });

  @override
  Widget build(BuildContext context) {
    if (isBearing) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0x22F6BD60),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x66F6BD60), width: 1.2),
        ),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.explore_outlined,
              size: 28,
              color: SolaraColors.solaraGoldLight,
            ),
            if (bearingText != null && bearingText!.isNotEmpty)
              // 方位コードをアイコン上に小さくオーバーレイ
              Positioned(
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: SolaraColors.celestialBlueDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    bearingText!,
                    style: const TextStyle(
                      color: SolaraColors.solaraGoldLight,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0x22F6BD60),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x66F6BD60), width: 1.2),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.place,
        size: 24,
        color: SolaraColors.solaraGoldLight,
      ),
    );
  }
}
