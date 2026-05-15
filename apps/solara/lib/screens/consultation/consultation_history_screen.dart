// Consultation History Screen — Phase 2-4
//
// 設計: apps/solara/docs/pro_candidates.md §7.2 Stage 4 + §7.3 柱3
//
// レイアウト:
//   - AppBar (戻る / すべて削除)
//   - ListView (新しい順、savedAt 降順)
//   - 各行: 保存日時 + テーマ + モード + scope + 最初の候補名 + 自由記述抜粋
//   - 行タップ → ConsultationResultScreen を読込み専用 (initialReading) で開く
//
// 柱 3 の原則:
//   - Free でも全件閲覧できる (件数上限 200 は技術的フェイルセーフ)
//   - 検索・フィルタは Pro 機能 (本画面では UI のみプレースホルダ、ゲートは課金後)

import 'package:flutter/material.dart';

import '../../theme/solara_colors.dart';
import '../../utils/consultation_record.dart';
import '../../utils/solara_storage.dart';
import '../../widgets/glass_panel.dart';
import 'consultation_result_screen.dart';

const _themeLabel = <String, String>{
  'love': '恋愛・関係',
  'money': '豊かさ・お金',
  'work': '仕事・キャリア',
  'communication': '対話・学び',
  'healing': '癒し・休息',
  'newStart': '変化・新たな出発',
};

const _modeLabel = <String, String>{
  'migration': '移住',
  'travel': '旅行',
  'daily': 'おでかけ',
};

const _scopeLabel = <String, String>{
  'specific': '具体地点',
  'region': '範囲指定',
  'world': '世界全体',
  'bearings': '方角別',
};

class ConsultationHistoryScreen extends StatefulWidget {
  /// テスト用 hook (デフォルト null で SolaraStorage を読む)。
  final Future<List<ConsultationRecord>> Function()? loadOverride;

  /// テスト用 hook (デフォルト null で SolaraStorage を呼ぶ)。
  final Future<void> Function(String id)? deleteOverride;

  const ConsultationHistoryScreen({
    super.key,
    this.loadOverride,
    this.deleteOverride,
  });

  @override
  State<ConsultationHistoryScreen> createState() =>
      _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState extends State<ConsultationHistoryScreen> {
  bool _loading = true;
  List<ConsultationRecord> _records = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = widget.loadOverride != null
        ? await widget.loadOverride!()
        : await SolaraStorage.loadConsultationHistory();
    if (!mounted) return;
    setState(() {
      _records = list;
      _loading = false;
    });
  }

  Future<void> _delete(String id) async {
    if (widget.deleteOverride != null) {
      await widget.deleteOverride!(id);
    } else {
      await SolaraStorage.deleteConsultationRecord(id);
    }
    await _load();
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SolaraColors.celestialBlueLight,
        title: const Text(
          'すべて削除しますか？',
          style: TextStyle(color: SolaraColors.textPrimary, fontSize: 16),
        ),
        content: const Text(
          '保存された全ての相談記録が消えます。元に戻せません。',
          style: TextStyle(color: SolaraColors.textSecondary, fontSize: 13),
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
    if (ok != true) return;
    if (widget.deleteOverride != null) {
      // テスト/モック時は 1 件ずつ呼ぶ
      for (final r in _records) {
        await widget.deleteOverride!(r.id);
      }
    } else {
      await SolaraStorage.clearConsultationHistory();
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SolaraColors.celestialBlueDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '相談履歴',
          style: TextStyle(
            color: SolaraColors.textPrimary,
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: SolaraColors.textPrimary),
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'すべて削除',
              onPressed: _confirmDeleteAll,
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: SolaraColors.solaraGold,
                  strokeWidth: 2,
                ),
              )
            : _records.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final r = _records[i];
                      return _HistoryCard(
                        record: r,
                        onTap: () => _openDetail(r),
                        onDelete: () => _delete(r.id),
                      );
                    },
                  ),
      ),
    );
  }

  Future<void> _openDetail(ConsultationRecord r) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConsultationResultScreen(
          theme: r.theme,
          mode: r.mode,
          scope: r.scope,
          freeText: r.freeText,
          initialCandidates: r.candidates,
          initialReading: r.reading,
          autoSave: false,
        ),
      ),
    );
  }
}

// ── サブウィジェット ───────────────────────────────────────

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

  String get _firstCandidateLabel {
    if (record.candidates.isEmpty) return '—';
    final first = record.candidates.first;
    if (record.candidates.length == 1) return first.nameJP;
    return '${first.nameJP} ほか ${record.candidates.length - 1} 件';
  }

  @override
  Widget build(BuildContext context) {
    final themeJp = _themeLabel[record.theme] ?? record.theme;
    final modeJp = _modeLabel[record.mode] ?? record.mode;
    final scopeJp = _scopeLabel[record.scope] ?? record.scope;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _dateLabel,
                        style: TextStyle(
                          color: SolaraColors.textSecondary,
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _MetaChip(label: themeJp),
                      const SizedBox(width: 4),
                      _MetaChip(label: modeJp, dim: true),
                      const SizedBox(width: 4),
                      _MetaChip(label: scopeJp, dim: true),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
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
                  if (record.freeText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.freeText,
                      style: TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Color(0x99ACACAC),
              ),
              tooltip: '削除',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: SolaraColors.celestialBlueLight,
                    title: const Text(
                      'この記録を削除しますか？',
                      style: TextStyle(
                          color: SolaraColors.textPrimary, fontSize: 15),
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
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final bool dim;
  const _MetaChip({required this.label, this.dim = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: dim ? const Color(0x12FFFFFF) : const Color(0x22F6BD60),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: dim
              ? SolaraColors.glassBorder
              : const Color(0x44F6BD60),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dim
              ? SolaraColors.textSecondary
              : SolaraColors.solaraGoldLight,
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
