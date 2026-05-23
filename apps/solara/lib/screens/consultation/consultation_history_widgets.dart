// Consultation History — サブウィジェット (part of consultation_history_screen.dart)
//
// 履歴画面の presentation 部品 (空状態 / 履歴カード / メタチップ) を分離 (HARD500 回避)。

part of 'consultation_history_screen.dart';

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_stories_outlined,
                color: SolaraColors.textSecondary,
                size: 36,
              ),
              const SizedBox(height: 12),
              const Text(
                'まだ相談履歴はありません',
                style: TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Map で地点をタップ、または Daily Transit から相談を始めると、\nここに保存されます。',
                style: TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 12,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ConsultationRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _HistoryCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  String get _dateLabel {
    final dt = record.savedAt.toLocal();
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y/$m/$d $hh:$mm';
  }

  String get _firstCandidateLabel => record.firstCandidateLabel;

  /// カード下部の抜粋: 願い → だれと の順で 1 行。
  String get _excerpt {
    if (record.wish.isNotEmpty) return record.wish;
    if (record.withWhom.isNotEmpty) return 'だれと: ${record.withWhom}';
    return '';
  }

  /// 履歴画面の compact 表示用。テーマラベルから「・」の前の部分のみ抽出。
  /// 例: 恋愛・関係 → 恋愛、豊かさ・お金 → 豊かさ。
  /// 結果画面ではフルラベルを使うので、この prefix 化は履歴画面ローカル。
  String get _themePrefix {
    final label = _themeLabel[record.theme] ?? record.theme;
    final idx = label.indexOf('・');
    return idx > 0 ? label.substring(0, idx) : label;
  }

  /// モード (移住/旅行/おでかけ) → アイコン (履歴画面のみ)。
  IconData get _modeIcon {
    switch (record.mode) {
      case 'migration':
        return Icons.maps_home_work_outlined; // 引越し
      case 'travel':
        return Icons.flight_outlined; // 旅行
      case 'daily':
        return Icons.directions_walk; // おでかけ
      default:
        return Icons.more_horiz;
    }
  }

  /// スコープ (具体地点/方角/半径/地域/自国内/世界) → アイコン (履歴画面のみ)。
  IconData get _scopeIcon {
    switch (record.scopeKind) {
      case 'point':
        return Icons.location_on_outlined;
      case 'region':
        return Icons.crop_din_outlined;
      case 'country':
        return Icons.flag_outlined;
      case 'radius':
        return Icons.radar;
      case 'world':
        return Icons.public;
      case 'bearing':
        return Icons.explore_outlined;
      default:
        return Icons.more_horiz;
    }
  }

  /// スコープアイコン横に表示する補足ラベル。
  /// - region: scopeDetail (大ブロック名、例 '日本' / '北米')
  /// - point: scopeDetail (地点名) or candidates[0] の region/country
  /// - world / bearing / radius / 不明: null (アイコンだけで十分)
  String? get _scopeLocationLabel {
    switch (record.scopeKind) {
      case 'region':
        final d = record.scopeDetail;
        return (d == null || d.isEmpty) ? null : d;
      case 'point':
        final d = record.scopeDetail;
        if (d != null && d.isNotEmpty) return d;
        if (record.candidates.isEmpty) return null;
        final c = record.candidates.first;
        final parts = <String>[
          if ((c.region ?? '').isNotEmpty) c.region!,
          if ((c.country ?? '').isNotEmpty) c.country!,
        ];
        return parts.isEmpty ? null : parts.join(' / ');
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeJp = _modeLabel[record.mode] ?? record.mode;
    final scopeJp = _scopeLabel[record.scopeKind] ?? record.scopeKind;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: 日付 (横スクロール safety) + 右端ゴミ箱アイコン
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(
                      _dateLabel,
                      style: const TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 14,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Color(0x99ACACAC),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tooltip: '削除',
                    onPressed: () => _confirmDelete(context),
                  ),
                ),
              ],
            ),
            // Row 2: テーマ prefix + モードアイコン + スコープアイコン (+ スコープ補足ラベル)
            // 全体を SingleChildScrollView でラップして、長い region 名や住所が
            // 入っても overflow せず右スワイプで全体を確認できるようにする。
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _MetaChip(label: _themePrefix),
                    const SizedBox(width: 14),
                    Tooltip(
                      message: modeJp,
                      child: Icon(
                        _modeIcon,
                        size: 22,
                        color: SolaraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Tooltip(
                      message: scopeJp,
                      child: Icon(
                        _scopeIcon,
                        size: 22,
                        color: SolaraColors.textSecondary,
                      ),
                    ),
                    if (_scopeLocationLabel != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        _scopeLocationLabel!,
                        style: const TextStyle(
                          color: SolaraColors.textSecondary,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(
                _firstCandidateLabel,
                style: const TextStyle(
                  color: SolaraColors.textPrimary,
                  fontSize: 15,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_excerpt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text(
                  _excerpt,
                  style: const TextStyle(
                    color: SolaraColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SolaraColors.celestialBlueLight,
        title: const Text(
          'この記録を削除しますか？',
          style: TextStyle(color: SolaraColors.textPrimary, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: SolaraColors.energyHardLight,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok == true) onDelete();
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x22F6BD60),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x44F6BD60)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: SolaraColors.solaraGoldLight,
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
