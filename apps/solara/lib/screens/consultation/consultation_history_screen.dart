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

import '../../i18n/strings.g.dart' hide AppLocale;
import '../../theme/solara_colors.dart';
import '../../utils/consult_restore.dart';
import '../../utils/consultation_record.dart';
import '../../utils/solara_i18n.dart' show isEnLocale;
import '../../utils/solara_storage.dart';
import '../../widgets/glass_panel.dart';
import '../map/map_constants.dart' show categoryColors;
import 'consultation_result_screen.dart';

part 'consultation_history_widgets.dart';

// テーマ/時間帯/ホライズン/スコープのラベルは consultInput と完全一致のため
// i18n を再利用 (重複定義しない)。mode の daily のみ履歴は中黒インライン表記。
String _themeLabel(String theme) => switch (theme) {
      'love' => t.consultInput.theme.love,
      'money' => t.consultInput.theme.money,
      'work' => t.consultInput.theme.work,
      'communication' => t.consultInput.theme.communication,
      'healing' => t.consultInput.theme.healing,
      'newStart' => t.consultInput.theme.newStart,
      _ => theme,
    };

// 2026-05-29: テーマチップを Map 画面と同じカテゴリ色で着色する。
// 5 テーマ (love/money/work/communication/healing) は map_constants の
// categoryColors を流用 (扇・スコアバーと完全同色)。
// 'newStart' は Map 側に存在しないため、相談履歴ローカルで「夜明けオレンジ」
// を独自定義する (既存 5 色と差別化、変化・変容のイメージ)。
const _newStartColor = Color(0xFFFFB07C);

Color _themeColor(String theme) =>
    categoryColors[theme] ?? (theme == 'newStart' ? _newStartColor : SolaraColors.solaraGoldLight);

// 時間帯 key → ラベル (consultInput.timeBand を再利用)。
String? _timeBandLabel(String key) => switch (key) {
      'morning' => t.consultInput.timeBand.morning,
      'midday' => t.consultInput.timeBand.midday,
      'evening' => t.consultInput.timeBand.evening,
      'night' => t.consultInput.timeBand.night,
      'lateNight' => t.consultInput.timeBand.lateNight,
      _ => null,
    };

// 移住ホライズン key → ラベル (consultInput.when を再利用)。
String? _horizonLabel(String key) => switch (key) {
      'within6mo' => t.consultInput.when.within6mo,
      'within1yr' => t.consultInput.when.within1yr,
      'in3yr' => t.consultInput.when.in3yr,
      'in5yrPlus' => t.consultInput.when.in5yrPlus,
      _ => null,
    };

// mode → ラベル。travel/migration は consultInput を再利用、daily は履歴用に
// 中黒インライン (consultHistory.modeDaily)。
String _modeLabel(String mode) => switch (mode) {
      'migration' => t.consultInput.mode.migration,
      'travel' => t.consultInput.mode.travel,
      'daily' => t.consultHistory.modeDaily,
      _ => mode,
    };

String _scopeLabel(String kind) => switch (kind) {
      'point' => t.consultInput.scope.point,
      'bearing' => t.consultInput.scope.bearing,
      'radius' => t.consultInput.scope.radius,
      'region' => t.consultInput.scope.region,
      'country' => t.consultInput.scope.country,
      'world' => t.consultInput.scope.world,
      _ => kind,
    };

class ConsultationHistoryScreen extends StatefulWidget {
  /// テスト用 hook (デフォルト null で SolaraStorage を読む)。
  final Future<List<ConsultationRecord>> Function()? loadOverride;

  /// テスト用 hook (デフォルト null で SolaraStorage を呼ぶ)。
  final Future<void> Function(String id)? deleteOverride;

  /// 画面復元 (Android プロセス死対策): 復元時に「お気に入り」タブで開く。
  final bool initialFavOnly;

  const ConsultationHistoryScreen({
    super.key,
    this.loadOverride,
    this.deleteOverride,
    this.initialFavOnly = false,
  });

  @override
  State<ConsultationHistoryScreen> createState() =>
      _ConsultationHistoryScreenState();
}

class _ConsultationHistoryScreenState extends State<ConsultationHistoryScreen> {
  bool _loading = true;
  late bool _favOnly = widget.initialFavOnly;
  List<ConsultationRecord> _records = const [];

  /// 画面復元 (Android プロセス死対策) レジストリ登録トークン。
  late final Object _restoreToken;

  @override
  void initState() {
    super.initState();
    _restoreToken = ConsultRestore.instance.register(
      () => {'type': 'consultationHistory', 'favOnly': _favOnly},
    );
    _load();
  }

  @override
  void dispose() {
    ConsultRestore.instance.unregister(_restoreToken);
    super.dispose();
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
        title: Text(
          t.consultHistory.deleteAllTitle,
          style: const TextStyle(color: SolaraColors.textPrimary, fontSize: 16),
        ),
        content: Text(
          t.consultHistory.deleteAllBody,
          style: const TextStyle(color: SolaraColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.locations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: SolaraColors.energyHardLight,
            ),
            child: Text(t.consultHistory.delete),
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
        title: Text(
          t.consultHistory.title,
          style: const TextStyle(
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
              tooltip: t.consultHistory.deleteAll,
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
            label: t.consultHistory.filterAll,
            selected: !_favOnly,
            onTap: () => setState(() => _favOnly = false),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: t.consultHistory.filterFav,
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
