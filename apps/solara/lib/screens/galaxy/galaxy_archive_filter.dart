// Galaxy Archive フィルタ・検索 — C2 (Pro 機能、柱 3)
//
// 設計: apps/solara/docs/pro_candidates.md §7.3 + §3 C2
//
// 柱 3 原則: Free は自分の記録 (全完了サイクル) を永久に見られる。
// Pro が売るのは「記録を使う道具」= 検索・フィルタ・ソート・月別ハイライト。
//
// 役割:
//   - Star Atlas タブ上部に表示される操作バー
//   - Free: 検索/フィルタアイコンタップで showProUnlockDialog
//   - Pro: 検索バー + レアリティチップ + ソート選択を有効化
//   - 内部状態は `GalaxyArchiveFilter` クラスで保持し、外部 (atlas タブ) で適用
//
// 🔴 思想ガード (project_solara_design_philosophy):
//   - 「吉凶判定しない」→ レアリティ高=「良」のような色ランク表現は避ける。
//     チップ自体は静かなゴールド系のみ。

import 'package:flutter/material.dart';

import '../../models/galaxy_cycle.dart';
import '../../theme/solara_colors.dart';
import '../../widgets/pro_unlock_dialog.dart';

part 'galaxy_archive_filter_chips.dart';

/// Star Atlas のフィルタ状態。Atlas タブで保持 → カードリスト構築前に
/// [apply] を呼んで絞り込む。
class GalaxyArchiveFilter {
  /// 検索クエリ (空文字 = 無効)。星座名 (EN/JP) に対する大小文字無視部分一致。
  final String query;

  /// 表示する rarity の集合 (空 = 全件)。値は 1〜5。
  /// multi-select: 複数 rarity を同時に表示できる (例: `{3, 5}` で
  /// rarity 3 と 5 の両方を表示)。チップタップで個別に on/off。
  final Set<int> rarities;

  /// 並び順。
  final GalaxyArchiveSort sort;

  const GalaxyArchiveFilter({
    this.query = '',
    this.rarities = const {},
    this.sort = GalaxyArchiveSort.newestFirst,
  });

  GalaxyArchiveFilter copyWith({
    String? query,
    Set<int>? rarities,
    GalaxyArchiveSort? sort,
  }) =>
      GalaxyArchiveFilter(
        query: query ?? this.query,
        rarities: rarities ?? this.rarities,
        sort: sort ?? this.sort,
      );

  /// フィルタが何かしら有効か。
  bool get isActive =>
      query.trim().isNotEmpty ||
      rarities.isNotEmpty ||
      sort != GalaxyArchiveSort.newestFirst;

  /// `cycles` (新しい順を想定) に絞込 + 並べ替えを適用して返す。
  List<GalaxyCycle> apply(List<GalaxyCycle> cycles) {
    var filtered = cycles;
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      filtered = filtered.where((c) {
        final en = c.nameEN.toLowerCase();
        final jp = c.nameJP.toLowerCase();
        return en.contains(q) || jp.contains(q);
      }).toList();
    }
    if (rarities.isNotEmpty) {
      filtered = filtered.where((c) => rarities.contains(c.rarity)).toList();
    }
    final list = filtered.toList();
    // 🔴 (2026-05-19) ソート基準を cycleStart → effectiveFormedAt に変更。
    // cycleStart は「サイクルの開始日」であって「刻星化した日時」ではない。
    // debug で過去サイクルを後から作ったり、同月内に複数 cycle を並べると
    // cycleStart は順序を保証しない (オーナー報告)。effectiveFormedAt は
    // formedAt → id(ms) → cycleStart の優先で「刻星化された時刻」を返す。
    switch (sort) {
      case GalaxyArchiveSort.newestFirst:
        list.sort(
            (a, b) => b.effectiveFormedAt.compareTo(a.effectiveFormedAt));
        break;
      case GalaxyArchiveSort.oldestFirst:
        list.sort(
            (a, b) => a.effectiveFormedAt.compareTo(b.effectiveFormedAt));
        break;
      case GalaxyArchiveSort.rarityHighFirst:
        list.sort((a, b) => b.rarity.compareTo(a.rarity));
        break;
    }
    return list;
  }
}

enum GalaxyArchiveSort {
  newestFirst,
  oldestFirst,
  rarityHighFirst,
}

extension GalaxyArchiveSortLabel on GalaxyArchiveSort {
  String get jp {
    switch (this) {
      case GalaxyArchiveSort.newestFirst:
        return '新しい順';
      case GalaxyArchiveSort.oldestFirst:
        return '古い順';
      case GalaxyArchiveSort.rarityHighFirst:
        return 'レア度順';
    }
  }
}

/// Star Atlas タブ上部に置く検索・フィルタバー。
///
/// `isPro=false` のときは UI は表示するが操作で Pro ダイアログを出す。
/// 検索 TextField は Pro のみ有効化、Free はタップで Pro 誘導。
class GalaxyArchiveFilterBar extends StatefulWidget {
  final GalaxyArchiveFilter filter;
  final ValueChanged<GalaxyArchiveFilter> onChanged;
  final bool isPro;

  const GalaxyArchiveFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.isPro,
  });

  @override
  State<GalaxyArchiveFilterBar> createState() => _GalaxyArchiveFilterBarState();
}

class _GalaxyArchiveFilterBarState extends State<GalaxyArchiveFilterBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.filter.query);
  }

  @override
  void didUpdateWidget(covariant GalaxyArchiveFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.query != widget.filter.query &&
        _ctrl.text != widget.filter.query) {
      _ctrl.text = widget.filter.query;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _proGuard() => showProUnlockDialog(
        context,
        featureLabel: 'アーカイブの検索・フィルタ',
        description:
            '完成したサイクルを名前・レア度・並び順で絞り込めます。\n'
            '記録が積み上がるほど、振り返りやすくなります。',
      );

  void _onQueryChanged(String v) {
    widget.onChanged(widget.filter.copyWith(query: v));
  }

  /// レアリティチップを multi-select で切替える (オーナー指定 2026-05-17)。
  /// 既に選択されていれば外す、未選択なら追加する。
  ///
  /// 過去履歴:
  ///   - 一時的に single-select 化したが、オーナー要望で multi-select 復帰。
  ///   - 「★5 だけタップしたのに ★3 が表示される」事象が報告されたが
  ///     widget test + closure capture test では再現せず。直接の Set 操作
  ///     ロジックは元から正しい。視覚的に分かりにくかった可能性に絞り、
  ///     選択中チップは `Selected:` バナーで明示するように UI を強化する。
  void _toggleRarity(int r) {
    final next = Set<int>.from(widget.filter.rarities);
    if (!next.add(r)) {
      next.remove(r);
    }
    widget.onChanged(widget.filter.copyWith(rarities: next));
  }

  void _setSort(GalaxyArchiveSort s) {
    widget.onChanged(widget.filter.copyWith(sort: s));
  }

  @override
  Widget build(BuildContext context) {
    final isPro = widget.isPro;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 検索バー (Pro)
          GestureDetector(
            onTap: isPro ? null : _proGuard,
            child: AbsorbPointer(
              absorbing: !isPro,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0x66000000),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPro
                        ? const Color(0x44F9D976)
                        : const Color(0x22F9D976),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 18,
                      color: isPro
                          ? SolaraColors.solaraGoldLight
                          : const Color(0x66F9D976),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        enabled: isPro,
                        onChanged: _onQueryChanged,
                        style: const TextStyle(
                          color: SolaraColors.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: isPro
                              ? '星座名で検索 (例: 翼 / Dragon)'
                              : '検索 — Cosmic Pro',
                          hintStyle: TextStyle(
                            color: isPro
                                ? const Color(0x99ACACAC)
                                : const Color(0x66ACACAC),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    if (isPro && _ctrl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          _onQueryChanged('');
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0x99ACACAC),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // レアリティチップ + ソートメニュー
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _SortChip(
                  current: widget.filter.sort,
                  isPro: isPro,
                  onSelect: _setSort,
                  onLockedTap: _proGuard,
                ),
                const SizedBox(width: 8),
                for (int r = 5; r >= 1; r--) ...[
                  _RarityChip(
                    key: ValueKey('rarity-chip-$r'),
                    rarity: r,
                    selected: widget.filter.rarities.contains(r),
                    isPro: isPro,
                    onTap: () => isPro ? _toggleRarity(r) : _proGuard(),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          // 選択中の rarity を明示するバナー (タップ事象の不可視化対策)。
          if (widget.filter.rarities.isNotEmpty) ...[
            const SizedBox(height: 6),
            _SelectedRarityBanner(
              rarities: widget.filter.rarities,
              onClear: () => widget.onChanged(
                widget.filter.copyWith(rarities: const <int>{}),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


