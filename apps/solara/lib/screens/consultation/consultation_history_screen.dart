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
import '../map/map_constants.dart' show categoryColors;
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

// 2026-05-29: テーマチップを Map 画面と同じカテゴリ色で着色する。
// 5 テーマ (love/money/work/communication/healing) は map_constants の
// categoryColors を流用 (扇・スコアバーと完全同色)。
// 'newStart' は Map 側に存在しないため、相談履歴ローカルで「夜明けオレンジ」
// を独自定義する (既存 5 色と差別化、変化・変容のイメージ)。
const _newStartColor = Color(0xFFFFB07C);

Color _themeColor(String theme) =>
    categoryColors[theme] ?? (theme == 'newStart' ? _newStartColor : SolaraColors.solaraGoldLight);

// 時間帯 key → 日本語ラベル (consultation_input_when_scope の _timeBandChoices と一致)。
const _timeBandLabel = <String, String>{
  'morning': '朝',
  'midday': '昼',
  'evening': '夕方',
  'night': '夜',
  'lateNight': '夜更け',
};

// 移住ホライズン key → 日本語ラベル (consultation_input_when_scope の _horizonChoices と一致)。
const _horizonLabel = <String, String>{
  'within6mo': '半年以内',
  'within1yr': '1年以内',
  'in3yr': '3年後くらい',
  'in5yrPlus': '5年以上先',
};

// 2026-05-29: 'daily' のラベルを入力タイル ('おでかけ\nイベント') と概念統一。
// 履歴カードは 1 行表示なので中黒区切り 'おでかけ・イベント' に。
const _modeLabel = <String, String>{
  'migration': '移住',
  'travel': '旅行',
  'daily': 'おでかけ・イベント',
};

const _scopeLabel = <String, String>{
  'point': '具体地点',
  'bearing': '方角',
  'radius': '現住所から半径',
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
  bool _favOnly = false;
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

  Future<void> _toggleFavorite(ConsultationRecord r) async {
    final newFav = !r.favorite;
    // 楽観更新 (即時反映、再読込なし)。
    setState(() {
      _records = _records
          .map((x) => x.id == r.id ? x.copyWith(favorite: newFav) : x)
          .toList(growable: false);
    });
    await SolaraStorage.setConsultationFavorite(r.id, newFav);
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
      // 履歴全消去なら無連続 avoid-window もリセット (次の相談を真っさらから)。
      await SolaraStorage.clearConsultationAvoid();
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
                : Column(
                    children: [
                      _buildFilterBar(),
                      Expanded(child: _buildList()),
                    ],
                  ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          _FilterChip(
            label: 'すべて',
            selected: !_favOnly,
            onTap: () => setState(() => _favOnly = false),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '★ お気に入り',
            selected: _favOnly,
            onTap: () => setState(() => _favOnly = true),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final shown = _favOnly
        ? _records.where((r) => r.favorite).toList(growable: false)
        : _records;
    if (shown.isEmpty) {
      return const _EmptyState(favOnly: true);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: shown.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final r = shown[i];
        return _HistoryCard(
          record: r,
          isFavorite: r.favorite,
          onTap: () => _openDetail(r),
          onDelete: () => _delete(r.id),
          onToggleFavorite: () => _toggleFavorite(r),
        );
      },
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
