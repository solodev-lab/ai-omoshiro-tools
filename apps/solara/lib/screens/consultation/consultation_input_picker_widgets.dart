// Consultation Input Screen — 具体地点ピッカーの presentational 部品
// (part of 'consultation_input_screen.dart')
//
// consultation_input_picker.dart の HARD500 回避のため、検索結果行・保存地点チップ・
// 選択中カードの 3 widget を切り出し (2026-05-25)。ロジックは持たず描画のみ。

part of 'consultation_input_screen.dart';

/// 検索結果 1 行 (番号バッジ + 場所名 + 住所サブ行)。
class _SearchHitRow extends StatelessWidget {
  final int index;
  final map_search.SearchHit hit;
  final VoidCallback onTap;
  const _SearchHitRow(
      {required this.index, required this.hit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 場所名 + 住所行を組み立てる。
    // Google Places 経路: hit.name = 短い場所名 (例 'Tokyo Tower')、hit.address に formattedAddress
    // Nominatim 経路: hit.name = 'A, B, C, D, ...' の display_name、hit.address は null
    final String short;
    final String sub;
    if (hit.address != null && hit.address!.isNotEmpty) {
      short = hit.name;
      sub = hit.address!;
    } else {
      final parts = hit.name.split(',').map((s) => s.trim()).toList();
      short = parts.isNotEmpty ? parts.first : hit.name;
      sub = parts.length > 1 ? parts.skip(1).join(', ') : '';
    }
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: SolaraColors.solaraGold,
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: const TextStyle(
                  fontSize: 12,
                  color: SolaraColors.celestialBlueDark,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    short,
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 保存地点 (ViewPoint / Locations) のチップ。アイコン + 登録名。
///
/// 2026-05-29: home (slot.isHome=true) のときは slot.name (= profile.homeName =
/// ユーザー入力住所、例「東京都渋谷区」) を出さず、固定文言「現住所」に置換する。
/// home 以外の slot は登録名 (例「お気に入りの公園」) をそのまま表示する。
class _LocationChip extends StatelessWidget {
  final VPSlot slot;
  final VoidCallback onTap;
  const _LocationChip({required this.slot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final displayName = slot.isHome ? t.locations.currentAddress : slot.name;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0x10FFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: SolaraColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(slot.icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              displayName,
              style: const TextStyle(
                color: SolaraColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 選択中の具体地点カード (場所名 + 住所 + 解除ボタン)。
class _SelectedSpecificCard extends StatelessWidget {
  final _PickedSpecific picked;
  final VoidCallback onClear;
  const _SelectedSpecificCard({required this.picked, required this.onClear});

  String? _addressLine() {
    final parts = <String>[
      if (picked.region.isNotEmpty) picked.region,
      if (picked.country.isNotEmpty) picked.country,
    ];
    return parts.isEmpty ? null : parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: const Color(0x14F6BD60),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x66F6BD60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 18, color: SolaraColors.solaraGold),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    picked.name,
                    style: const TextStyle(
                      color: SolaraColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_addressLine() != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '(${_addressLine()})',
                      style: const TextStyle(
                        color: SolaraColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close,
                size: 14, color: SolaraColors.textSecondary),
            onPressed: onClear,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: t.consultInput.picker.clearSelection,
          ),
        ],
      ),
    );
  }
}
