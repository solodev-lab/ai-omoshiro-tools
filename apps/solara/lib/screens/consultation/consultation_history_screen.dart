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

part 'consultation_history_widgets.dart';

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
  'point': '具体地点',
  'bearing': '方角',
  'radius': '自宅から半径',
  'region': '地域',
  'country': '自国内',
  'world': '世界全体',
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
        builder: (_) => ConsultationResultScreen.fromRecord(record: r),
      ),
    );
  }
}
