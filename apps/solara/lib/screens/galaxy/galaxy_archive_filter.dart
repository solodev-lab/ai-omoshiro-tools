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
import '../../utils/pro_status.dart';
import '../../widgets/pro_unlock_dialog.dart';

/// Star Atlas のフィルタ状態。Atlas タブで保持 → カードリスト構築前に
/// [apply] を呼んで絞り込む。
class GalaxyArchiveFilter {
  /// 検索クエリ (空文字 = 無効)。星座名 (EN/JP) に対する大小文字無視部分一致。
  final String query;

  /// 表示する rarity の集合 (空 = 全件)。値は 1〜5。
  ///
  /// **UI 上は単一選択**: チップは 1 つしか同時選択できない設計
  /// (2026-05-17 multi-select 廃止)。Set 型を維持しているのは
  /// `apply` の絞込ロジックと将来の multi 復活に備えた API 互換のため。
  /// 初期化時に複数値を入れた場合は `apply` が正しく動作する
  /// (テスト用途で利用可能)。
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
    switch (sort) {
      case GalaxyArchiveSort.newestFirst:
        list.sort((a, b) => b.cycleStart.compareTo(a.cycleStart));
        break;
      case GalaxyArchiveSort.oldestFirst:
        list.sort((a, b) => a.cycleStart.compareTo(b.cycleStart));
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
        return 'レアリティ順';
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
            '完成したサイクルを名前・レアリティ・並び順で絞り込めます。\n'
            '記録が積み上がるほど、振り返りやすくなります。',
      );

  void _onQueryChanged(String v) {
    widget.onChanged(widget.filter.copyWith(query: v));
  }

  /// レアリティチップを単一選択で切替える。
  ///
  /// 仕様 (2026-05-17 multi-select 廃止):
  ///   - 何も選ばれていない → タップで `{r}` を選択
  ///   - 同じ rarity が選ばれている → タップで `{}` にクリア
  ///   - 違う rarity が選ばれている → タップで `{r}` に切替
  ///
  /// 旧 multi-select だと「★5 をタップしたのに ★3 のサイクルが出る」
  /// (= 直前タップの ★3 が残っている) という UX 混乱があった。
  void _toggleRarity(int r) {
    final current = widget.filter.rarities;
    final next = (current.length == 1 && current.contains(r))
        ? <int>{}
        : <int>{r};
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
            height: 32,
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
        ],
      ),
    );
  }
}

class _RarityChip extends StatelessWidget {
  final int rarity;
  final bool selected;
  final bool isPro;
  final VoidCallback onTap;
  const _RarityChip({
    required this.rarity,
    required this.selected,
    required this.isPro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isPro
        ? (selected
            ? SolaraColors.celestialBlueDark
            : SolaraColors.solaraGoldLight)
        : const Color(0x77F9D976);
    final bg = selected
        ? SolaraColors.solaraGoldLight
        : Colors.transparent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPro
                ? const Color(0x66F9D976)
                : const Color(0x22F9D976),
          ),
        ),
        child: Text(
          '★$rarity',
          style: TextStyle(
            color: fg,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final GalaxyArchiveSort current;
  final bool isPro;
  final ValueChanged<GalaxyArchiveSort> onSelect;
  final VoidCallback onLockedTap;
  const _SortChip({
    required this.current,
    required this.isPro,
    required this.onSelect,
    required this.onLockedTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPro ? null : onLockedTap,
      child: PopupMenuButton<GalaxyArchiveSort>(
        enabled: isPro,
        tooltip: '並び順',
        offset: const Offset(0, 36),
        color: SolaraColors.celestialBlueLight,
        onSelected: onSelect,
        itemBuilder: (ctx) => [
          for (final s in GalaxyArchiveSort.values)
            PopupMenuItem(
              value: s,
              child: Text(
                s.jp,
                style: TextStyle(
                  color: s == current
                      ? SolaraColors.solaraGoldLight
                      : SolaraColors.textPrimary,
                  fontSize: 13,
                ),
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPro
                  ? const Color(0x66F9D976)
                  : const Color(0x22F9D976),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort,
                size: 14,
                color: isPro
                    ? SolaraColors.solaraGoldLight
                    : const Color(0x77F9D976),
              ),
              const SizedBox(width: 4),
              Text(
                current.jp,
                style: TextStyle(
                  color: isPro
                      ? SolaraColors.solaraGoldLight
                      : const Color(0x77F9D976),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 外部ヘルパー: ProStatus を参照するシンプル版。状態管理を持たないので
/// AnimatedBuilder でラップして使うか、画面側で listen する。
bool currentIsPro() => ProStatus.instance.isPro;
