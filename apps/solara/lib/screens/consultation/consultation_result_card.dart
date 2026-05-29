// Consultation Result — 候補カード (V2)
// (part of 'consultation_result_screen.dart')

part of 'consultation_result_screen.dart';

class _CandidateCard extends StatelessWidget {
  final ConsultationV2Reading reading;
  const _CandidateCard({required this.reading});

  ConsultationV2Candidate get _c => reading.candidate;
  bool get _isBearing => _c.bearing != null && _c.bearing!.isNotEmpty;

  /// 字幕: 県名/国名 + (実在の町なら) 方角・距離。生の国コード「JP」は出さない。
  String get _subtitle {
    final parts = <String>[];
    if ((_c.region ?? '').isNotEmpty) {
      // JP は県名を出し、冗長な国コードは出さない。
      parts.add(_c.region!);
    } else if (!_isBearing) {
      // 海外で region が無い場合のみ、国コードを日本語国名に変換して出す (未知コードは出さない)。
      final cj = _countryJa(_c.country);
      if (cj != null) parts.add(cj);
    }
    // 実在の町 (Phase B D1 局所) は home からの方角・距離を添える。
    final dir = _c.directionFromHome;
    if (dir != null && dir.isNotEmpty) {
      final dist = _c.distanceKm;
      parts.add(dist != null && dist > 0 ? '$dir 約${dist}km' : dir);
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final tw = _c.timeWindow;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassPanel(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CandidateKindBadge(
                    isBearing: _isBearing,
                    bearingText: _c.bearing,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isBearing ? '方角' : '場所',
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
                ConsultationRecord.displayName(_c),
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
              if (_c.characterHeadline.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('◆ ',
                        style: TextStyle(
                            color: SolaraColors.solaraGold, fontSize: 14)),
                    Expanded(
                      child: Text(
                        _c.characterHeadline,
                        style: const TextStyle(
                          color: SolaraColors.solaraGoldLight,
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (tw != null) ...[
                const SizedBox(height: 12),
                _TimeWindowRow(timeWindow: tw),
              ],
              if (_c.energyLabels.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _c.energyLabels
                      .map((label) => _EnergyChip(label: label))
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 18),
              Text(
                _c.narrative.isNotEmpty ? _c.narrative : '(narrative なし)',
                style: const TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 14,
                  height: 1.85,
                  letterSpacing: 0.4,
                ),
              ),
              // AI 出力ユーザー報告 (Google Gen AI Policy)。narrative がある時のみ表示。
              // 詳細: docs/store_compliance.md §3.1 / widgets/ai_report_button.dart
              if (_c.narrative.isNotEmpty) ...[
                AiReportButton(
                  feature: 'consultation',
                  outputText: _c.narrative,
                  padding: const EdgeInsets.only(top: 4),
                ),
                // disclaimer footer — 報告ボタンの直下に常時。
                const AiDisclaimerFooter(padding: EdgeInsets.zero),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// 国コード(ISO2) → 日本語国名 (字幕用、よく出る国のみ。未知は null=非表示)。
/// 生の「JP」「FR」等を字幕に出さないための変換表。
const Map<String, String> _kCountryJa = {
  'JP': '日本', 'US': 'アメリカ', 'CA': 'カナダ', 'MX': 'メキシコ',
  'GB': 'イギリス', 'FR': 'フランス', 'DE': 'ドイツ', 'IT': 'イタリア',
  'ES': 'スペイン', 'PT': 'ポルトガル', 'NL': 'オランダ', 'BE': 'ベルギー',
  'CH': 'スイス', 'AT': 'オーストリア', 'IE': 'アイルランド', 'SE': 'スウェーデン',
  'NO': 'ノルウェー', 'DK': 'デンマーク', 'FI': 'フィンランド', 'GR': 'ギリシャ',
  'PL': 'ポーランド', 'CZ': 'チェコ', 'RU': 'ロシア', 'TR': 'トルコ',
  'CN': '中国', 'KR': '韓国', 'TW': '台湾', 'HK': '香港',
  'TH': 'タイ', 'VN': 'ベトナム', 'SG': 'シンガポール', 'MY': 'マレーシア',
  'ID': 'インドネシア', 'PH': 'フィリピン', 'IN': 'インド', 'AE': 'アラブ首長国連邦',
  'AU': 'オーストラリア', 'NZ': 'ニュージーランド', 'BR': 'ブラジル', 'AR': 'アルゼンチン',
  'EG': 'エジプト', 'ZA': '南アフリカ',
};

String? _countryJa(String? code) {
  if (code == null || code.isEmpty) return null;
  return _kCountryJa[code.toUpperCase()];
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

/// 時間帯 (現地の時間帯のみ・時計表示なし)。single=1 個 / rhythm=朝昼夜。
class _TimeWindowRow extends StatelessWidget {
  final ConsultationTimeWindow timeWindow;
  const _TimeWindowRow({required this.timeWindow});

  @override
  Widget build(BuildContext context) {
    final labels = timeWindow.kind == 'rhythm'
        ? timeWindow.items.map((e) => e.label).where((s) => s.isNotEmpty).toList()
        : [if ((timeWindow.label ?? '').isNotEmpty) timeWindow.label!];
    if (labels.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.schedule,
            size: 14, color: SolaraColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            labels.join(' · '),
            style: const TextStyle(
              color: SolaraColors.textSecondary,
              fontSize: 12.5,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// 候補種別バッジ (方角 / 場所)。
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
              Positioned(
                bottom: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
