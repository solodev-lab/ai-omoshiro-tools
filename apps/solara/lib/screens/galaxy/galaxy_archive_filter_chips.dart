// Galaxy Archive フィルタバーのサブウィジェット — C2 (柱 3)
//
// 親: galaxy_archive_filter.dart (part-of 親で import するパッケージは
// すべて親側で宣言済み)。本ファイルは widget 定義のみで、import は親に委譲する。
//
// 含まれる widget:
//   - _SelectedRarityBanner: 「選択中: ★5 ★3 ... クリア」表示
//   - _RarityChip: ★N チップ (multi-select、HitTestBehavior.opaque)
//   - _SortChip: 並び順メニューチップ (Free 時 Pro Unlock dialog)

part of 'galaxy_archive_filter.dart';

class _SelectedRarityBanner extends StatelessWidget {
  final Set<int> rarities;
  final VoidCallback onClear;
  const _SelectedRarityBanner({
    required this.rarities,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = rarities.toList()..sort((a, b) => b.compareTo(a));
    return Row(
      children: [
        Text(
          t.galaxyArchive.selectedLabel,
          style: const TextStyle(
            color: SolaraColors.textSecondary,
            fontSize: 11,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          sorted.map((r) => '★$r').join(' '),
          style: const TextStyle(
            color: SolaraColors.solaraGoldLight,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onClear,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              t.galaxyArchive.clear,
              style: const TextStyle(
                color: SolaraColors.textSecondary,
                fontSize: 11,
                letterSpacing: 0.4,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RarityChip extends StatelessWidget {
  final int rarity;
  final bool selected;
  final bool isPro;
  final VoidCallback onTap;
  const _RarityChip({
    super.key,
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
    // 🔴 HitTestBehavior.opaque + 透明 fill (0x01FFFFFF) でチップ余白も
    // 確実にヒットさせる。報告事象: 「★5 をタップしたつもりが反応しない
    // → フィルタ空のまま全件表示 → rarity 3 が紛れて見える」を回避。
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        // 最小タップ領域 (Material 推奨 48dp 弱だが、横並び制約で 32 高さ
        // を確保。横幅は内容に応じて伸びる)。
        constraints: const BoxConstraints(minWidth: 44, minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg == Colors.transparent ? const Color(0x01FFFFFF) : bg,
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
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
        tooltip: t.galaxyArchive.sortTooltip,
        offset: const Offset(0, 36),
        color: SolaraColors.celestialBlueLight,
        onSelected: onSelect,
        itemBuilder: (ctx) => [
          for (final s in GalaxyArchiveSort.values)
            PopupMenuItem(
              value: s,
              child: Text(
                s.label,
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
                current.label,
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
