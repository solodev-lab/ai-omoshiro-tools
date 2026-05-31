// Consultation Result — 候補カード (V2)
// (part of 'consultation_result_screen.dart')

part of 'consultation_result_screen.dart';

class _CandidateCard extends StatelessWidget {
  final ConsultationV2Reading reading;

  /// 場所名の右の🗺ボタン (Map 画面でこの候補地を見る)。null なら非表示。
  final VoidCallback? onOpenMap;

  /// Pro 時刻指定時の指定時刻 (0-23)。non-null なら時間帯行をバンド名でなく
  /// 「HH:00」で表示する (オーナー要望 2026-05-31)。null = 時刻未指定 → 従来のバンド表示。
  final int? specifiedHour;
  const _CandidateCard({required this.reading, this.onOpenMap, this.specifiedHour});

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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      ConsultationRecord.displayName(_c),
                      style: const TextStyle(
                        color: SolaraColors.textPrimary,
                        fontSize: 22,
                        height: 1.3,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (onOpenMap != null) ...[
                    const SizedBox(width: 8),
                    _MapLinkIcon(onTap: onOpenMap!),
                  ],
                ],
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
                _TimeWindowRow(timeWindow: tw, specifiedHour: specifiedHour),
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
              // 30 分後デルタ (Pro おでかけ時刻指定時のみ・narrative がある時)。
              // この候補地の星の流れが 30 分でどう移ろうかをタップで開く。
              if (_c.deltaAfter != null && _c.deltaAfter!.narrative.isNotEmpty)
                _DeltaAfterSection(delta: _c.deltaAfter!),
              // AI 出力ユーザー報告 (Google Gen AI Policy)。narrative がある時のみ表示。
              // 詳細: docs/store_compliance.md §3.1 / widgets/ai_report_button.dart
              if (_c.narrative.isNotEmpty) ...[
                AiReportButton(
                  feature: 'consultation',
                  outputText: _c.narrative,
                  padding: const EdgeInsets.only(top: 4),
                ),
                // 解釈は 1 つに過ぎない旨の注記 (エビデンスは上部に表示)。
                const StellaInterpretationNote(
                  text: '最上段相談の結果に本内容のエビデンスが表示されています。'
                      'Stellaが解釈の１つとして本内容を表示しています。内容に違和感が'
                      'ある場合はご自身で解釈を広げてみてください。あくまでここでの表示は'
                      '解釈の１つに過ぎません。',
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

/// 場所名の右の🗺リンク。Map 画面で候補地を (相談の日付で) 見る。
class _MapLinkIcon extends StatelessWidget {
  final VoidCallback onTap;
  const _MapLinkIcon({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: '地図で見る',
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0x1FC9A84C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x66C9A84C)),
          ),
          child: const Icon(
            Icons.map_outlined,
            size: 20,
            color: SolaraColors.solaraGoldLight,
          ),
        ),
      ),
    );
  }
}

/// 時間帯。通常は現地の時間帯バンド (朝/昼/夕方/夜/夜更け)。single=1 個 / rhythm=朝昼夜。
/// [specifiedHour] が non-null (Pro 時刻指定時) は、バンド名でなく「HH:00」で表示する。
class _TimeWindowRow extends StatelessWidget {
  final ConsultationTimeWindow timeWindow;
  final int? specifiedHour;
  const _TimeWindowRow({required this.timeWindow, this.specifiedHour});

  @override
  Widget build(BuildContext context) {
    // 時刻指定時は「15:00」のみを出す (オーナー要望: 5 枠バンドではなく指定時刻)。
    final labels = specifiedHour != null
        ? ['${specifiedHour.toString().padLeft(2, '0')}:00']
        : timeWindow.kind == 'rhythm'
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

// ── 30 分後デルタ (Pro おでかけ時刻指定) ──────────────────────

const Map<String, String> _kPlanetJa = {
  'sun': '太陽', 'moon': '月', 'mercury': '水星', 'venus': '金星', 'mars': '火星',
  'jupiter': '木星', 'saturn': '土星', 'uranus': '天王星', 'neptune': '海王星',
  'pluto': '冥王星',
};
const Map<String, String> _kAngleJa = {
  'mc': 'MC', 'ic': 'IC', 'asc': 'ASC', 'dsc': 'DSC',
};

/// 候補カードの「30分経過後を見る」セクション。タップで開閉、i ボタンで説明。
/// CCG の角ラインが自転で動くため、この場所の流れが 30 分でどう移ろうかを示す。
class _DeltaAfterSection extends StatefulWidget {
  final ConsultationDeltaAfter delta;
  const _DeltaAfterSection({required this.delta});

  @override
  State<_DeltaAfterSection> createState() => _DeltaAfterSectionState();
}

class _DeltaAfterSectionState extends State<_DeltaAfterSection> {
  bool _open = false;

  void _showInfo() {
    final m = widget.delta.deltaMin;
    showInfoPopup(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '「30分経過後を見る」とは',
            style: TextStyle(
                color: SolaraColors.solaraGoldLight,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          Text(
            'アストロカートグラフィの星の線は、地球の自転で刻一刻と動いています。\n'
            '惑星が真上や地平線に来る「角ライン」は、$m分でおよそ 7.5°——'
            '中緯度で約 800km も西へ進みます。\n\n'
            'だから同じ場所でも、選んだ時刻と$m分後では「その場の主役」が'
            '静かに入れ替わることがあります。火星の線が離れていく、'
            '金星の線が近づいてくる——その移ろいを先に知っておくと、'
            '「核心は前半に」「後半にかけて温まる」のように、'
            'その場での時間の使い方が見えてきます。\n\n'
            '吉凶ではなく、エネルギーの“質の移り変わり”として読んでいます。'
            'Cosmic Pro・おでかけで時刻を指定したときに見られます。',
            style: const TextStyle(
                color: SolaraColors.textPrimary, fontSize: 13, height: 1.75),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.delta;
    final moved =
        d.changes.where((c) => c.dir != 'steady').toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _open = !_open),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0x22F6BD60),
                      border: Border.all(color: const Color(0x66F6BD60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.update,
                            size: 18, color: SolaraColors.solaraGoldLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _open
                                ? '${d.deltaMin}分後の変化を閉じる'
                                : '${d.deltaMin}分経過後を見る',
                            style: const TextStyle(
                              color: SolaraColors.solaraGoldLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        Icon(_open ? Icons.expand_less : Icons.expand_more,
                            size: 18, color: SolaraColors.solaraGoldLight),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _showInfo,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.help_outline,
                      size: 18, color: Color(0xCCAAAAAA)),
                ),
              ),
            ],
          ),
          if (_open) ...[
            const SizedBox(height: 12),
            if (moved.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    moved.map((c) => _DeltaChip(change: c)).toList(growable: false),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              d.narrative,
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 13.5,
                height: 1.8,
                letterSpacing: 0.3,
              ),
            ),
            // 30分後の変化にも、報告ボタン + 解釈注記 + AI 免責を付ける。
            // エビデンス (線の動き) は上のチップとして表示済み。
            AiReportButton(
              feature: 'consultation',
              outputText: d.narrative,
              padding: const EdgeInsets.only(top: 6),
            ),
            const StellaInterpretationNote(
              text: 'この30分後の変化は、上に示した線の動きをエビデンスとして、'
                  'Stellaが解釈の１つとして表示しています。内容に違和感がある場合は'
                  'ご自身で解釈を広げてみてください。'
                  'あくまでここでの表示は解釈の１つに過ぎません。',
            ),
            const AiDisclaimerFooter(padding: EdgeInsets.zero),
          ],
        ],
      ),
    );
  }
}

/// 30 分後の 1 変化チップ (例: 「火星 MC ↘ 離れる」)。
/// 近づく/差す = 緑系、離れる/外れる = 琥珀系 (吉凶ではなく方向の色分け)。
class _DeltaChip extends StatelessWidget {
  final ConsultationDeltaChange change;
  const _DeltaChip({required this.change});

  @override
  Widget build(BuildContext context) {
    final planet = _kPlanetJa[change.planet] ?? change.planet;
    final angle = _kAngleJa[change.angle] ?? change.angle;
    final (IconData icon, String label, Color color) = switch (change.dir) {
      'approaching' => (Icons.trending_down, '近づく', const Color(0xFF8FD3B0)),
      'entering' => (Icons.add_circle_outline, '差してくる', const Color(0xFF8FD3B0)),
      'receding' => (Icons.trending_up, '離れる', const Color(0xFFE0A878)),
      'leaving' => (Icons.remove_circle_outline, '外れる', const Color(0xFFE0A878)),
      _ => (Icons.remove, '安定', SolaraColors.textSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            '$planet $angle・$label',
            style: TextStyle(color: color, fontSize: 11, letterSpacing: 0.3),
          ),
        ],
      ),
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
