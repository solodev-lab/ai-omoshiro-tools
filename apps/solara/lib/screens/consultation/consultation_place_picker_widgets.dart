// Consultation Place Picker — サブウィジェット
// (part of 'consultation_place_picker_screen.dart')
//
// flutter_map ベースの地点選択画面のサブウィジェット群:
//   - _SearchBar: 検索ボックス + サジェスト一覧 (番号バッジ付き)
//   - _NumberedPin: 検索結果の地図上ピン
//   - _SelectionCard: 画面下の選択中カード ＋ キャンセル / 確定ボタン
//
// 親 consultation_place_picker_screen.dart は orchestration + State + map 配置のみ
// 担う (ファイル肥大化対策、2026-05-16 分割)。

part of 'consultation_place_picker_screen.dart';

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final bool searching;
  final List<SearchHit> hits;
  final void Function(SearchHit) onHitTap;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.searching,
    required this.hits,
    required this.onHitTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xF20F0F1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x33C9A84C)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              const Icon(Icons.search,
                  size: 18, color: SolaraColors.solaraGold),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  style: const TextStyle(
                    color: SolaraColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                    hintText: '住所 / 店名で検索',
                    hintStyle: TextStyle(
                      color: SolaraColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              if (controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 16, color: SolaraColors.textSecondary),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tooltip: 'クリア',
                ),
              if (searching)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: SolaraColors.solaraGold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hits.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: const Color(0xF20F0F1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x33C9A84C)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: hits.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: Color(0x11FFFFFF)),
              itemBuilder: (ctx, i) {
                final h = hits[i];
                // Google Places (hit.address あり) と Nominatim (display_name comma 連結) を
                // 両対応。a と同じ振り分けロジック (consultation_input_widgets._SearchHitRow)。
                final String short;
                final String sub;
                if (h.address != null && h.address!.isNotEmpty) {
                  short = h.name;
                  sub = h.address!;
                } else {
                  final parts = h.name.split(',');
                  short = parts.isNotEmpty ? parts.first.trim() : h.name;
                  sub = parts.length > 1
                      ? parts.skip(1).map((s) => s.trim()).join(', ')
                      : '';
                }
                return InkWell(
                  onTap: () => onHitTap(h),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: SolaraColors.solaraGold,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 13,
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
                                  fontSize: 13,
                                  color: SolaraColors.textPrimary,
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
                                    fontSize: 11,
                                    color: SolaraColors.textSecondary,
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
              },
            ),
          ),
      ],
    );
  }
}

class _NumberedPin extends StatelessWidget {
  final int index;
  const _NumberedPin({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: SolaraColors.solaraGold,
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: const TextStyle(
          fontSize: 13,
          color: SolaraColors.celestialBlueDark,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final LatLng? picked;
  final String? name;
  final String? region;
  final String? countryCode;
  /// 検索結果リストでの順位 (1〜)。マップタップ起点なら null。
  /// 非 null のときは選択カード行頭に同じ番号バッジを出す
  /// (リストの番号・地図ピンの番号と同期させる視覚連動)。
  final int? hitIndex;
  final bool resolving;
  final VoidCallback onClear;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _SelectionCard({
    required this.picked,
    required this.name,
    required this.region,
    required this.countryCode,
    required this.hitIndex,
    required this.resolving,
    required this.onClear,
    required this.onConfirm,
    required this.onCancel,
  });

  String _coordLabel(LatLng p) {
    final lat = p.latitude;
    final lng = p.longitude;
    final latStr = '${lat.abs().toStringAsFixed(3)}°${lat >= 0 ? 'N' : 'S'}';
    final lngStr = '${lng.abs().toStringAsFixed(3)}°${lng >= 0 ? 'E' : 'W'}';
    return '$latStr, $lngStr';
  }

  String? _addressLine() {
    final parts = <String>[
      if (region != null && region!.isNotEmpty) region!,
      if (countryCode != null && countryCode!.isNotEmpty) countryCode!,
    ];
    return parts.isEmpty ? null : parts.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final p = picked;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xF20F0F1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x44F6BD60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (p == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'タップ または 検索 で地点を選んでください',
                style: TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else ...[
            Row(
              children: [
                // 番号バッジ (検索結果から選んだ時のみ) / なければ 📍 アイコン
                if (hitIndex != null)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: SolaraColors.solaraGold,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$hitIndex',
                      style: const TextStyle(
                        fontSize: 13,
                        color: SolaraColors.celestialBlueDark,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.place,
                      size: 18, color: SolaraColors.solaraGold),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          name?.isNotEmpty == true
                              ? name!
                              : (resolving ? '読み込み中…' : '選択地点'),
                          style: const TextStyle(
                            color: SolaraColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_addressLine() != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '(${_addressLine()})',
                            style: const TextStyle(
                              color: SolaraColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 16, color: SolaraColors.textSecondary),
                  onPressed: onClear,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: '選択を解除',
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 2, bottom: 6),
              child: Text(
                _coordLabel(p),
                style: const TextStyle(
                  color: SolaraColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: SolaraColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('キャンセル'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: p == null ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SolaraColors.solaraGold,
                    foregroundColor: SolaraColors.celestialBlueDark,
                    disabledBackgroundColor: SolaraColors.glassBorder,
                    disabledForegroundColor: SolaraColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'この地点で相談',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
