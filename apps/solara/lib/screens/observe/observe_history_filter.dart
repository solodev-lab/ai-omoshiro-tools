// Natal Tarot 履歴フィルタ — C3 (Pro 機能、柱 3)
//
// 設計: apps/solara/docs/pro_candidates.md §7.3 + §3 C3
//
// 役割:
//   - ObserveHistoryPanel 上部に置く検索 + フィルタチップ
//   - Pro: キーワード検索 / アルカナ (Major/Minor) / エレメント / 正逆位置
//   - Free: バー自体は表示するが操作で showProUnlockDialog
//   - フィルタ適用ロジックは `ObserveHistoryFilter.apply` で集中管理

import 'package:flutter/material.dart';

import '../../models/daily_reading.dart';
import '../../utils/tarot_data.dart';
import '../../widgets/pro_unlock_dialog.dart';
import 'observe_constants.dart';

/// 履歴フィルタ状態 (immutable)。
class ObserveHistoryFilter {
  /// 検索クエリ (カード名 JP/EN・リーディング・シンクロニシティに対する部分一致)。
  final String query;

  /// 表示する arcana。null=全て、true=Major、false=Minor。
  final bool? onlyMajor;

  /// 表示する element 集合 (空=全て)。値は 'fire'/'water'/'air'/'earth'。
  final Set<String> elements;

  /// 表示する正逆位置。null=全て、true=逆位置のみ、false=正位置のみ。
  final bool? onlyReversed;

  const ObserveHistoryFilter({
    this.query = '',
    this.onlyMajor,
    this.elements = const {},
    this.onlyReversed,
  });

  ObserveHistoryFilter copyWith({
    String? query,
    Object? onlyMajor = _Sentinel.none,
    Set<String>? elements,
    Object? onlyReversed = _Sentinel.none,
  }) {
    return ObserveHistoryFilter(
      query: query ?? this.query,
      onlyMajor: identical(onlyMajor, _Sentinel.none)
          ? this.onlyMajor
          : onlyMajor as bool?,
      elements: elements ?? this.elements,
      onlyReversed: identical(onlyReversed, _Sentinel.none)
          ? this.onlyReversed
          : onlyReversed as bool?,
    );
  }

  bool get isActive =>
      query.trim().isNotEmpty ||
      onlyMajor != null ||
      elements.isNotEmpty ||
      onlyReversed != null;

  /// DailyReading の list を絞り込む。順序は元の list の通り。
  List<DailyReading> apply(List<DailyReading> history) {
    if (!isActive) return history;
    final q = query.trim().toLowerCase();
    return history.where((r) {
      final card = TarotData.getCard(r.cardId);
      if (onlyMajor != null && card.isMajor != onlyMajor) return false;
      if (elements.isNotEmpty && !elements.contains(card.element)) return false;
      if (onlyReversed != null && r.reversed != onlyReversed) return false;
      if (q.isNotEmpty) {
        // パフォーマンス: 履歴上限 50 件 × 数百字の文字列連結 = 1 回 ~数十μs。
        // 検索は textChanged ごとに走るが、ListView の rebuild より遥かに軽い。
        final haystack = <String>[
          card.nameJP,
          card.nameEN,
          card.keyword,
          r.reading,
          r.synchronicity,
          r.question ?? '',
        ].map((s) => s.toLowerCase()).join(' / ');
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }
}

class _Sentinel {
  const _Sentinel._();
  static const Object none = _Sentinel._();
}

/// Natal Tarot 履歴フィルタバー。
///
/// Free 状態では操作で Pro 案内ダイアログを出す。
class ObserveHistoryFilterBar extends StatefulWidget {
  final ObserveHistoryFilter filter;
  final ValueChanged<ObserveHistoryFilter> onChanged;
  final bool isPro;

  const ObserveHistoryFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.isPro,
  });

  @override
  State<ObserveHistoryFilterBar> createState() =>
      _ObserveHistoryFilterBarState();
}

class _ObserveHistoryFilterBarState extends State<ObserveHistoryFilterBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.filter.query);
  }

  @override
  void didUpdateWidget(covariant ObserveHistoryFilterBar oldWidget) {
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
        featureLabel: '履歴の検索・フィルタ',
        description: '過去のカード履歴を、キーワード・アルカナ・エレメントで絞り込めます。\n'
            '気になる瞬間が、すぐに見つかります。',
      );

  void _setQuery(String v) => widget.onChanged(widget.filter.copyWith(query: v));

  void _toggleElement(String el) {
    final next = Set<String>.from(widget.filter.elements);
    if (!next.add(el)) next.remove(el);
    widget.onChanged(widget.filter.copyWith(elements: next));
  }

  void _toggleMajor(bool v) {
    widget.onChanged(
      widget.filter.copyWith(
        onlyMajor: widget.filter.onlyMajor == v ? null : v,
      ),
    );
  }

  void _toggleReversed(bool v) {
    widget.onChanged(
      widget.filter.copyWith(
        onlyReversed: widget.filter.onlyReversed == v ? null : v,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPro = widget.isPro;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 検索バー
        GestureDetector(
          onTap: isPro ? null : _proGuard,
          child: AbsorbPointer(
            absorbing: !isPro,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0x66000000),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isPro
                      ? const Color(0x33C9A84C)
                      : const Color(0x1FC9A84C),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 16,
                    color: isPro
                        ? const Color(0xFFC9A84C)
                        : const Color(0x55C9A84C),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      enabled: isPro,
                      onChanged: _setQuery,
                      style: const TextStyle(
                        color: Color(0xFFE8E0D0),
                        fontSize: 12,
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: isPro
                            ? 'カード名・読み・質問・シンクロを検索'
                            : '検索 — Cosmic Pro',
                        hintStyle: TextStyle(
                          color: isPro
                              ? const Color(0xFF666666)
                              : const Color(0xFF444444),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (isPro && _ctrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _ctrl.clear();
                        _setQuery('');
                      },
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Color(0xFF888888),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // フィルタチップ列
        SizedBox(
          height: 28,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ChipBtn(
                label: '大アルカナ',
                active: widget.filter.onlyMajor == true,
                isPro: isPro,
                onTap: () => isPro ? _toggleMajor(true) : _proGuard(),
              ),
              const SizedBox(width: 6),
              _ChipBtn(
                label: '小アルカナ',
                active: widget.filter.onlyMajor == false,
                isPro: isPro,
                onTap: () => isPro ? _toggleMajor(false) : _proGuard(),
              ),
              const SizedBox(width: 10),
              for (final el in const ['fire', 'water', 'air', 'earth']) ...[
                _ElementChipBtn(
                  element: el,
                  active: widget.filter.elements.contains(el),
                  isPro: isPro,
                  onTap: () => isPro ? _toggleElement(el) : _proGuard(),
                ),
                const SizedBox(width: 6),
              ],
              const SizedBox(width: 4),
              _ChipBtn(
                label: '正位置',
                active: widget.filter.onlyReversed == false,
                isPro: isPro,
                onTap: () => isPro ? _toggleReversed(false) : _proGuard(),
              ),
              const SizedBox(width: 6),
              _ChipBtn(
                label: '逆位置',
                active: widget.filter.onlyReversed == true,
                isPro: isPro,
                onTap: () => isPro ? _toggleReversed(true) : _proGuard(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChipBtn extends StatelessWidget {
  final String label;
  final bool active;
  final bool isPro;
  final VoidCallback onTap;
  const _ChipBtn({
    required this.label,
    required this.active,
    required this.isPro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isPro
        ? (active ? const Color(0xFF0F0F1E) : const Color(0xFFC9A84C))
        : const Color(0x77C9A84C);
    final bg = active ? const Color(0xFFC9A84C) : Colors.transparent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPro
                ? const Color(0x55C9A84C)
                : const Color(0x22C9A84C),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _ElementChipBtn extends StatelessWidget {
  final String element;
  final bool active;
  final bool isPro;
  final VoidCallback onTap;
  const _ElementChipBtn({
    required this.element,
    required this.active,
    required this.isPro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(elementColors[element] ?? 0xFFC9A84C);
    final emoji = elementEmojis[element] ?? '';
    final nameJP = elementNames[element] ?? element;
    final fg = isPro
        ? (active ? const Color(0xFF0F0F1E) : color)
        : color.withValues(alpha: 0.5);
    final bg = active ? color : Colors.transparent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPro
                ? color.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          '$emoji$nameJP',
          style: TextStyle(
            color: fg,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

